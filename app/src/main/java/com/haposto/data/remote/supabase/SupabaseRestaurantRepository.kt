package com.haposto.data.remote.supabase

import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.postgrest.postgrest
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import com.haposto.data.location.LocationSession
import com.haposto.data.repository.RestaurantDataSource
import com.haposto.data.repository.RestaurantRepository
import com.haposto.data.repository.RestaurantRepositoryMetadata
import com.haposto.domain.model.AvailabilityRules
import com.haposto.domain.model.AvailabilityStatus
import com.haposto.domain.model.DistanceOrigin
import com.haposto.domain.model.LiveAvailability
import com.haposto.domain.model.PartnershipStatus
import com.haposto.domain.model.Restaurant
import java.time.Clock
import java.time.Duration
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicLong
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.FlowPreview
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.debounce
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.withTimeoutOrNull

/**
 * Backend calls used by [SupabaseRestaurantRepository]; an interface so the refresh/overlay logic
 * can be unit-tested without a network.
 */
internal interface DirectoryApi {
    suspend fun nearby(latitude: Double, longitude: Double, radiusMeters: Int): List<Restaurant>

    /**
     * DEV projects only (supabase/dev/dev_tools.sql): publishes the status of a test venue so other
     * phones see it. Throws when the function is missing, disabled or the venue is not a test one.
     */
    suspend fun devPublishLiveStatus(
        restaurantId: String,
        status: AvailabilityStatus,
        availableTables: Int?,
        estimatedWaitMinutes: Int?,
        note: String?,
    )
}

internal class SupabaseDirectoryApi(private val client: SupabaseClient) : DirectoryApi {

    override suspend fun nearby(latitude: Double, longitude: Double, radiusMeters: Int): List<Restaurant> {
        // Keys match the SQL function nearby_restaurants(lat, long, radius_meters, search_text);
        // search_text is omitted so the SQL default (null) applies.
        val params = buildJsonObject {
            put("lat", latitude)
            put("long", longitude)
            put("radius_meters", radiusMeters)
        }
        return client.postgrest
            .rpc("nearby_restaurants", params)
            .decodeList<NearbyRestaurantDto>()
            .map(NearbyRestaurantDto::toDomain)
    }

    override suspend fun devPublishLiveStatus(
        restaurantId: String,
        status: AvailabilityStatus,
        availableTables: Int?,
        estimatedWaitMinutes: Int?,
        note: String?,
    ) {
        val params = buildJsonObject {
            put("p_restaurant_id", restaurantId)
            put("p_status", status.name)
            put("p_available_tables", availableTables)
            put("p_estimated_wait_minutes", estimatedWaitMinutes)
            put("p_note", note)
        }
        client.postgrest.rpc("dev_publish_live_status", params)
    }
}

/**
 * STEP 7 repository.
 *
 * READ path: real Supabase RPC + PostGIS using the current foreground/manual origin, refreshed
 * every [refreshIntervalMillis] while someone is observing (Realtime arrives in STEP 10).
 * WRITE path: on a DEV project with supabase/dev/dev_tools.sql, test venues are written to the
 * database so every phone sees the change; otherwise the change stays a RAM-only overlay until
 * real authenticated writes arrive in STEP 9.
 */
@OptIn(ExperimentalCoroutinesApi::class, FlowPreview::class)
class SupabaseRestaurantRepository internal constructor(
    private val api: DirectoryApi,
    private val locationSession: LocationSession,
    private val clock: Clock = Clock.systemUTC(),
    private val radiusMeters: Int = DEFAULT_RADIUS_METERS,
    private val refreshIntervalMillis: Long = DEFAULT_REFRESH_INTERVAL_MILLIS,
) : RestaurantRepository, RestaurantRepositoryMetadata {

    constructor(
        client: SupabaseClient,
        locationSession: LocationSession,
    ) : this(api = SupabaseDirectoryApi(client), locationSession = locationSession)

    override val dataSource: RestaurantDataSource = RestaurantDataSource.SUPABASE

    /** A manager change shown locally; [serverWriteSeq] is set when the backend also stored it. */
    private data class LocalOverride(val restaurant: Restaurant, val serverWriteSeq: Long?)

    private val localManagerOverrides = MutableStateFlow<Map<String, LocalOverride>>(emptyMap())
    private val latestSnapshot = ConcurrentHashMap<String, Restaurant>()
    private val writeSequence = AtomicLong(0)
    private val refreshTicket = MutableStateFlow(0L)

    @Volatile
    private var devWritesAvailable = true

    override fun observeRestaurants(): Flow<List<Restaurant>> {
        val remote = locationSession.origin
            .debounce(150)
            .distinctUntilChanged()
            .flatMapLatest(::pollDirectory)

        return combine(remote, localManagerOverrides) { backendRows, overrides ->
            backendRows.map { backend ->
                // Only the fields the manager can edit come from the RAM overlay; distance, name,
                // address and partnership keep following the latest backend row.
                overrides[backend.id]?.restaurant?.let { local ->
                    backend.copy(
                        liveAvailability = local.liveAvailability,
                        phonePublic = local.phonePublic && !backend.phoneNumber.isNullOrBlank(),
                    )
                } ?: backend
            }
        }.onEach(::cache)
    }

    override fun findById(id: String): Restaurant? = latestSnapshot[id]

    override suspend fun publishAvailability(
        restaurantId: String,
        status: AvailabilityStatus,
        availableTables: Int?,
        estimatedWaitMinutes: Int?,
        note: String?,
    ): Boolean {
        require(status in PUBLISHABLE_STATUSES)
        require(availableTables == null || availableTables in 0..AvailabilityRules.MAX_AVAILABLE_TABLES)
        require(estimatedWaitMinutes == null || estimatedWaitMinutes in 0..AvailabilityRules.MAX_ESTIMATED_WAIT_MINUTES)
        require(note == null || note.length <= AvailabilityRules.MAX_NOTE_LENGTH)

        val current = findById(restaurantId) ?: return false
        if (current.partnershipStatus != PartnershipStatus.ACTIVE_PARTNER) return false

        val now = clock.instant()
        val cleanNote = note?.trim()?.takeIf(String::isNotEmpty)
        val tables = if (status == AvailabilityStatus.FULL) null else availableTables
        val updated = current.copy(
            liveAvailability = LiveAvailability(
                status = status,
                updatedAt = now,
                validUntil = now.plus(Duration.ofMinutes(AvailabilityRules.LIVE_TTL_MINUTES)),
                availableTables = tables,
                estimatedWaitMinutes = estimatedWaitMinutes,
                note = cleanNote,
            ),
        )

        val storedOnServer = tryDevPublish(restaurantId, status, tables, estimatedWaitMinutes, cleanNote)
        putOverride(updated, serverWriteSeq = if (storedOnServer) writeSequence.incrementAndGet() else null)
        if (storedOnServer) requestRefresh()
        return true
    }

    /** STEP 7 local manager overlay. Real authenticated DB write is introduced in STEP 9. */
    override suspend fun setPhonePublic(
        restaurantId: String,
        isPublic: Boolean,
    ): Boolean {
        val current = findById(restaurantId) ?: return false
        if (current.partnershipStatus != PartnershipStatus.ACTIVE_PARTNER) return false
        if (isPublic && current.phoneNumber.isNullOrBlank()) return false

        putOverride(current.copy(phonePublic = isPublic), serverWriteSeq = null)
        return true
    }

    /**
     * Loads the directory for [origin], then again every [refreshIntervalMillis] or as soon as a
     * refresh is requested. Only the first load may fail the flow (Home shows the error and retry);
     * a later failure keeps the last list on screen and simply tries again at the next tick.
     */
    private fun pollDirectory(origin: DistanceOrigin): Flow<List<Restaurant>> = flow {
        var loadedOnce = false
        while (true) {
            val ticket = refreshTicket.value
            val confirmedWrites = writeSequence.get()
            val rows = try {
                api.nearby(origin.point.latitude, origin.point.longitude, radiusMeters)
            } catch (cancellation: CancellationException) {
                throw cancellation
            } catch (error: Exception) {
                if (!loadedOnce) throw error
                null
            }
            if (rows != null) {
                loadedOnce = true
                emit(rows)
                // Writes completed before this fetch started are now in the backend rows: the local
                // copy can go (dropped after emitting, so the screen never flashes the old status).
                dropServerConfirmedOverrides(upToWriteSeq = confirmedWrites)
            }
            withTimeoutOrNull(refreshIntervalMillis) {
                refreshTicket.first { it != ticket }
            }
        }
    }

    private suspend fun tryDevPublish(
        restaurantId: String,
        status: AvailabilityStatus,
        availableTables: Int?,
        estimatedWaitMinutes: Int?,
        note: String?,
    ): Boolean {
        if (!devWritesAvailable) return false
        return try {
            api.devPublishLiveStatus(restaurantId, status, availableTables, estimatedWaitMinutes, note)
            true
        } catch (cancellation: CancellationException) {
            throw cancellation
        } catch (error: Exception) {
            // Production (no dev tools) or dev tools switched off: stop trying for this session.
            // Any other failure (a real venue, a network hiccup) only falls back for this change.
            val message = error.message.orEmpty()
            if (DEV_TOOLS_MISSING_MARKERS.any(message::contains)) devWritesAvailable = false
            false
        }
    }

    private fun requestRefresh() {
        refreshTicket.update { it + 1 }
    }

    private fun putOverride(restaurant: Restaurant, serverWriteSeq: Long?) {
        localManagerOverrides.update { it + (restaurant.id to LocalOverride(restaurant, serverWriteSeq)) }
        latestSnapshot[restaurant.id] = restaurant
    }

    private fun dropServerConfirmedOverrides(upToWriteSeq: Long) {
        localManagerOverrides.update { overrides ->
            overrides.filterValues { override ->
                val seq = override.serverWriteSeq
                seq == null || seq > upToWriteSeq
            }
        }
    }

    private fun cache(restaurants: List<Restaurant>) {
        latestSnapshot.clear()
        restaurants.forEach { latestSnapshot[it.id] = it }
    }

    internal companion object {
        const val DEFAULT_RADIUS_METERS = 60_000
        const val DEFAULT_REFRESH_INTERVAL_MILLIS = 60_000L
        private val PUBLISHABLE_STATUSES = setOf(
            AvailabilityStatus.AVAILABLE,
            AvailabilityStatus.LIMITED,
            AvailabilityStatus.FULL,
        )
        private val DEV_TOOLS_MISSING_MARKERS = listOf(
            "PGRST202",
            "Could not find the function",
            "DEV_TOOLS_DISABLED",
            "permission denied for function dev_publish_live_status",
        )
    }
}
