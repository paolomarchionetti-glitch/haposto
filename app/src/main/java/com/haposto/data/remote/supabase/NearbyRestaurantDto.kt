package com.haposto.data.remote.supabase

import com.haposto.domain.model.AvailabilityStatus
import com.haposto.domain.model.GeoPoint
import com.haposto.domain.model.LiveAvailability
import com.haposto.domain.model.PartnershipStatus
import com.haposto.domain.model.Restaurant
import java.time.Instant
import java.time.OffsetDateTime
import java.time.format.DateTimeParseException
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

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

    val live = if (partnership == PartnershipStatus.ACTIVE_PARTNER) toLiveAvailability() else null

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

/**
 * A malformed or unknown live row must not break the whole directory: the restaurant is still
 * shown, simply without a LIVE state (the resolver then reports it as "da aggiornare").
 */
private fun NearbyRestaurantDto.toLiveAvailability(): LiveAvailability? {
    val status = PUBLISHED_LIVE_STATUSES.firstOrNull { it.name == liveStatus } ?: return null
    val updatedAt = liveUpdatedAt?.let(::parseTimestamp) ?: return null
    val validUntil = liveValidUntil?.let(::parseTimestamp) ?: return null
    return runCatching {
        LiveAvailability(
            status = status,
            updatedAt = updatedAt,
            validUntil = validUntil,
            availableTables = if (status == AvailabilityStatus.FULL) null else availableTables,
            estimatedWaitMinutes = estimatedWaitMinutes,
            note = note?.trim()?.takeIf(String::isNotEmpty),
        )
    }.getOrNull()
}

private val PUBLISHED_LIVE_STATUSES = listOf(
    AvailabilityStatus.AVAILABLE,
    AvailabilityStatus.LIMITED,
    AvailabilityStatus.FULL,
)

/**
 * PostgREST serializes `timestamptz` with an explicit offset ("2026-08-24T10:00:00.123456+00:00").
 * `Instant.parse` accepts only the "Z" form on Android 8–13 (java.time based on OpenJDK 8), so the
 * value is parsed as an ISO offset date-time, which accepts both forms on every API level.
 */
internal fun parseTimestamp(value: String): Instant? = try {
    OffsetDateTime.parse(value.trim()).toInstant()
} catch (_: DateTimeParseException) {
    null
}
