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
import com.haposto.domain.model.LiveAvailability
import com.haposto.domain.model.PartnershipStatus
import com.haposto.domain.model.Restaurant
import java.time.Clock
import java.time.Duration
import java.util.concurrent.ConcurrentHashMap
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.FlowPreview
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.debounce
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.mapLatest
import kotlinx.coroutines.flow.onEach

/**
 * STEP 7 repository.
 *
 * READ path: real Supabase RPC + PostGIS using the current foreground/manual origin.
 * WRITE path: intentionally RAM-only overlay until real Auth/RPC writes arrive in STEP 9.
 * This preserves the complete pre-backend demo without pretending that fake identity is authorized
 * to write production data.
 */
@OptIn(ExperimentalCoroutinesApi::class, FlowPreview::class)
class SupabaseRestaurantRepository(
    private val client: SupabaseClient,
    private val locationSession: LocationSession,
    private val clock: Clock = Clock.systemUTC(),
    private val radiusMeters: Int = DEFAULT_RADIUS_METERS,
) : RestaurantRepository, RestaurantRepositoryMetadata {

    override val dataSource: RestaurantDataSource = RestaurantDataSource.SUPABASE

    private val localManagerOverrides = MutableStateFlow<Map<String, Restaurant>>(emptyMap())
    private val latestSnapshot = ConcurrentHashMap<String, Restaurant>()

    override fun observeRestaurants(): Flow<List<Restaurant>> {
        val remote = locationSession.origin
            .debounce(150)
            .distinctUntilChanged()
            .mapLatest { origin ->
                fetchNearby(
                    DirectoryRequest(
                        latitude = origin.point.latitude,
                        longitude = origin.point.longitude,
                    ),
                )
            }

        return combine(remote, localManagerOverrides) { backendRows, overrides ->
            backendRows.map { backend ->
                // Only the fields the manager can edit come from the RAM overlay; distance, name,
                // address and partnership keep following the latest backend row.
                overrides[backend.id]?.let { local ->
                    backend.copy(
                        liveAvailability = local.liveAvailability,
                        phonePublic = local.phonePublic && !backend.phoneNumber.isNullOrBlank(),
                    )
                } ?: backend
            }
        }.onEach(::cache)
    }

    override fun findById(id: String): Restaurant? = latestSnapshot[id]

    /**
     * STEP 7 keeps manager writes local on purpose. STEP 9 replaces this body with the authenticated
     * set_restaurant_live_status RPC while keeping the same repository contract.
     */
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
        val updated = current.copy(
            liveAvailability = LiveAvailability(
                status = status,
                updatedAt = now,
                validUntil = now.plus(Duration.ofMinutes(AvailabilityRules.LIVE_TTL_MINUTES)),
                availableTables = if (status == AvailabilityStatus.FULL) null else availableTables,
                estimatedWaitMinutes = estimatedWaitMinutes,
                note = note?.trim()?.takeIf(String::isNotEmpty),
            ),
        )
        putOverride(updated)
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

        putOverride(current.copy(phonePublic = isPublic))
        return true
    }

    private suspend fun fetchNearby(request: DirectoryRequest): List<Restaurant> {
        // supabase-kt in questa versione accetta i parametri RPC come JsonObject.
        // Le chiavi corrispondono esattamente agli argomenti della funzione SQL
        // nearby_restaurants(lat, long, radius_meters, search_text).
        val params = buildJsonObject {
            put("lat", request.latitude)
            put("long", request.longitude)
            put("radius_meters", radiusMeters)
            // search_text omesso: la funzione SQL usa il default (null).
        }

        return client.postgrest
            .rpc("nearby_restaurants", params)
            .decodeList<NearbyRestaurantDto>()
            .map(NearbyRestaurantDto::toDomain)
    }

    private fun putOverride(restaurant: Restaurant) {
        localManagerOverrides.value = localManagerOverrides.value + (restaurant.id to restaurant)
        latestSnapshot[restaurant.id] = restaurant
    }

    private fun cache(restaurants: List<Restaurant>) {
        latestSnapshot.clear()
        restaurants.forEach { latestSnapshot[it.id] = it }
    }

    private data class DirectoryRequest(
        val latitude: Double,
        val longitude: Double,
    )

    private companion object {
        const val DEFAULT_RADIUS_METERS = 60_000
        val PUBLISHABLE_STATUSES = setOf(
            AvailabilityStatus.AVAILABLE,
            AvailabilityStatus.LIMITED,
            AvailabilityStatus.FULL,
        )
    }
}
