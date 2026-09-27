package com.haposto.data.remote.supabase

import com.haposto.domain.model.AvailabilityStatus
import com.haposto.domain.model.GeoPoint
import com.haposto.domain.model.LiveAvailability
import com.haposto.domain.model.PartnershipStatus
import com.haposto.domain.model.Restaurant
import java.time.Instant
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
internal data class NearbyRestaurantsParams(
    val lat: Double,
    val long: Double,
    @SerialName("radius_meters") val radiusMeters: Int,
    @SerialName("search_text") val searchText: String? = null,
)

@Serializable
internal data class NearbyRestaurantDto(
    val id: String,
    val name: String,
    val category: String = "Ristorante",
    val address: String,
    val city: String,
    val province: String,
    @SerialName("phone_number") val phoneNumber: String? = null,
    @SerialName("phone_public") val phonePublic: Boolean,
    @SerialName("partnership_status") val partnershipStatus: String,
    @SerialName("live_status") val liveStatus: String? = null,
    @SerialName("live_updated_at") val liveUpdatedAt: String? = null,
    @SerialName("live_valid_until") val liveValidUntil: String? = null,
    @SerialName("available_tables") val availableTables: Int? = null,
    @SerialName("estimated_wait_minutes") val estimatedWaitMinutes: Int? = null,
    val note: String? = null,
    val latitude: Double,
    val longitude: Double,
    @SerialName("distance_meters") val distanceMeters: Double,
)

internal fun NearbyRestaurantDto.toDomain(): Restaurant {
    val partnership = if (partnershipStatus == "ACTIVE_PARTNER") {
        PartnershipStatus.ACTIVE_PARTNER
    } else {
        PartnershipStatus.DIRECTORY_ONLY
    }

    val live = if (
        partnership == PartnershipStatus.ACTIVE_PARTNER &&
        liveStatus != null &&
        liveUpdatedAt != null &&
        liveValidUntil != null
    ) {
        LiveAvailability(
            status = AvailabilityStatus.valueOf(liveStatus),
            updatedAt = Instant.parse(liveUpdatedAt),
            validUntil = Instant.parse(liveValidUntil),
            availableTables = if (liveStatus == "FULL") null else availableTables,
            estimatedWaitMinutes = estimatedWaitMinutes,
            note = note,
        )
    } else {
        null
    }

    return Restaurant(
        id = id,
        name = name,
        category = category,
        address = address,
        city = city,
        location = GeoPoint(latitude = latitude, longitude = longitude),
        distanceKm = distanceMeters.coerceAtLeast(0.0) / 1000.0,
        partnershipStatus = partnership,
        liveAvailability = live,
        phoneNumber = phoneNumber,
        phonePublic = phonePublic && !phoneNumber.isNullOrBlank(),
    )
}
