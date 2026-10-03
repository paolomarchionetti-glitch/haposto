package com.haposto.data.remote.supabase

import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.postgrest.postgrest
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import com.haposto.data.ErrorMessages
import com.haposto.data.Outcome
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
     * Protected publication (set_restaurant_live_status): only the owner or the staff of the
     * restaurant, signed in with 2FA. The reason of a refusal comes back in the [Outcome].
     */
    suspend fun publishLiveStatus(
        restaurantId: String,
        status: AvailabilityStatus,
        availableTables: Int?,
        estimatedWaitMinutes: Int?,
        note: String?,
        offer: String?,
    ): Outcome<Unit>
}

internal class SupabaseDirectoryApi(private val client: SupabaseClient) : DirectoryApi {

    private val management = SupabaseManagementRepository(client)

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

    override suspend fun publishLiveStatus(
        restaurantId: String,
        status: AvailabilityStatus,
        availableTables: Int?,
        estimatedWaitMinutes: Int?,
        note: String?,
        offer: String?,
    ): Outcome<Unit> = management.publish(restaurantId, status, availableTables, estimatedWaitMinutes, note, offer)
}

/**
 * Directory from Supabase (versions DEV and PROD).
 *
 * READ path: RPC + PostGIS around the current foreground/manual origin, refreshed every
 * [refreshIntervalMillis] while someone is observing, immediately after a publication and when
 * Realtime reports a change ([requestRefresh]).
 * WRITE path: set_restaurant_live_status, protected by account + role + 2FA in the database; the
 * new status is shown at once and then follows the server.
 */
@OptIn(ExperimentalCoroutinesApi::class, FlowPreview::class)
class SupabaseRestaurantRepository internal constructor(
    private val api: DirectoryApi,
    private val locationSession: LocationSession,
    private val clock: Clock = Clock.systemUTC(),
    radiusMeters: Int = DEFAULT_RADIUS_METERS,
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
    private val searchRadiusMeters = MutableStateFlow(radiusMeters)

    /** HAPOSTO Plus cerca più lontano (search_radius_km del piano). */
    fun setSearchRadiusKm(km: Int) {
        searchRadiusMeters.value = (km.coerceIn(5, 100)) * 1_000
    }

    override fun observeRestaurants(): Flow<List<Restaurant>> {
        val remote = combine(locationSession.origin.debounce(150), searchRadiusMeters) { origin, radius -> origin to radius }
            .distinctUntilChanged()
            .flatMapLatest { (origin, radius) -> pollDirectory(origin, radius) }

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
    ): Boolean = publishAvailabilityResult(restaurantId, status, availableTables, estimatedWaitMinutes, note).isSuccess

    override suspend fun publishAvailabilityResult(
        restaurantId: String,
        status: AvailabilityStatus,
        availableTables: Int?,
        estimatedWaitMinutes: Int?,
        note: String?,
        offer: String?,
    ): Outcome<Unit> {
        require(status in PUBLISHABLE_STATUSES)
        require(availableTables == null || availableTables in 0..AvailabilityRules.MAX_AVAILABLE_TABLES)
        require(estimatedWaitMinutes == null || estimatedWaitMinutes in 0..AvailabilityRules.MAX_ESTIMATED_WAIT_MINUTES)
        require(note == null || note.length <= AvailabilityRules.MAX_NOTE_LENGTH)

        val current = findById(restaurantId) ?: return ErrorMessages.failure("RESTAURANT_NOT_FOUND")
        if (current.partnershipStatus != PartnershipStatus.ACTIVE_PARTNER) {
            return ErrorMessages.failure("not an active partner")
        }

        val cleanNote = note?.trim()?.takeIf(String::isNotEmpty)
        val tables = if (status == AvailabilityStatus.FULL) null else availableTables
        val cleanOffer = if (status == AvailabilityStatus.FULL) {
            null
        } else {
            offer?.trim()?.takeIf(String::isNotEmpty)?.take(AvailabilityRules.MAX_OFFER_LENGTH)
        }
        val result = api.publishLiveStatus(restaurantId, status, tables, estimatedWaitMinutes, cleanNote, cleanOffer)
        if (result is Outcome.Success) {
            // Shown at once; the next refresh (requested now) brings the server's own values.
            val now = clock.instant()
            val updated = current.copy(
                liveAvailability = LiveAvailability(
                    status = status,
                    updatedAt = now,
                    validUntil = now.plus(Duration.ofMinutes(AvailabilityRules.LIVE_TTL_MINUTES)),
                    availableTables = tables,
                    estimatedWaitMinutes = estimatedWaitMinutes,
                    note = cleanNote,
                    offer = cleanOffer,
                ),
            )
            putOverride(updated, serverWriteSeq = writeSequence.incrementAndGet())
            requestRefresh()
        }
        return result
    }

    /** Only on this phone: the real change is made from "Gestisci il locale" (update_restaurant_profile). */
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
    private fun pollDirectory(origin: DistanceOrigin, radiusMeters: Int): Flow<List<Restaurant>> = flow {
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

    override fun requestRefresh() {
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
    }
}
