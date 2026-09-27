package com.haposto.data.remote.supabase

import com.haposto.domain.model.AvailabilityStatus
import com.haposto.domain.model.PartnershipStatus
import java.time.Instant
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class NearbyRestaurantDtoTest {

    @Test
    fun activePartnerMapsLiveAvailabilityAndDistance() {
        val restaurant = NearbyRestaurantDto(
            id = "10000000-0000-0000-0000-000000000001",
            name = "Osteria Demo",
            category = "Cucina italiana",
            address = "Via Demo 1",
            city = "Pesaro",
            province = "PU",
            phoneNumber = "+390721000001",
            phonePublic = true,
            partnershipStatus = "ACTIVE_PARTNER",
            liveStatus = "AVAILABLE",
            liveUpdatedAt = "2026-08-24T10:00:00Z",
            liveValidUntil = "2026-08-24T10:30:00Z",
            availableTables = 4,
            estimatedWaitMinutes = 10,
            note = "Demo",
            latitude = 43.91,
            longitude = 12.91,
            distanceMeters = 1250.0,
        ).toDomain()

        assertEquals(PartnershipStatus.ACTIVE_PARTNER, restaurant.partnershipStatus)
        assertEquals(AvailabilityStatus.AVAILABLE, restaurant.liveAvailability?.status)
        assertEquals(4, restaurant.liveAvailability?.availableTables)
        assertTrue(kotlin.math.abs((restaurant.distanceKm ?: 0.0) - 1.25) < 0.0001)
        assertTrue(restaurant.phonePublic)
    }

    @Test
    fun fullNeverExposesAvailableTablesEvenIfBackendPayloadIsBad() {
        val restaurant = NearbyRestaurantDto(
            id = "10000000-0000-0000-0000-000000000003",
            name = "Full Demo",
            category = "Ristorante",
            address = "Via Demo 3",
            city = "Pesaro",
            province = "PU",
            phonePublic = false,
            partnershipStatus = "ACTIVE_PARTNER",
            liveStatus = "FULL",
            liveUpdatedAt = "2026-08-24T10:00:00Z",
            liveValidUntil = "2026-08-24T10:30:00Z",
            availableTables = 9,
            latitude = 43.91,
            longitude = 12.91,
            distanceMeters = 10.0,
        ).toDomain()

        assertEquals(AvailabilityStatus.FULL, restaurant.liveAvailability?.status)
        assertNull(restaurant.liveAvailability?.availableTables)
    }

    @Test
    fun pausedOrPendingBackendStatusMapsToDirectoryOnlyForConsumer() {
        val restaurant = NearbyRestaurantDto(
            id = "10000000-0000-0000-0000-000000000009",
            name = "Paused Demo",
            category = "Ristorante",
            address = "Via Demo 9",
            city = "Pesaro",
            province = "PU",
            phonePublic = false,
            partnershipStatus = "PAUSED",
            latitude = 43.91,
            longitude = 12.91,
            distanceMeters = 50.0,
        ).toDomain()

        assertEquals(PartnershipStatus.DIRECTORY_ONLY, restaurant.partnershipStatus)
        assertNull(restaurant.liveAvailability)
    }

    @Test
    fun postgrestTimestampsWithOffsetAndMicrosecondsAreParsed() {
        val restaurant = partnerDto(
            liveStatus = "LIMITED",
            liveUpdatedAt = "2026-08-24T10:00:00.123456+00:00",
            liveValidUntil = "2026-08-24T12:30:00.123456+02:00",
        ).toDomain()

        val live = restaurant.liveAvailability
        assertEquals(AvailabilityStatus.LIMITED, live?.status)
        assertEquals(Instant.parse("2026-08-24T10:00:00.123456Z"), live?.updatedAt)
        assertEquals(Instant.parse("2026-08-24T10:30:00.123456Z"), live?.validUntil)
    }

    @Test
    fun unknownLiveStatusKeepsRestaurantWithoutLiveState() {
        val restaurant = partnerDto(liveStatus = "SOMETHING_NEW").toDomain()

        assertEquals(PartnershipStatus.ACTIVE_PARTNER, restaurant.partnershipStatus)
        assertNull(restaurant.liveAvailability)
    }

    @Test
    fun malformedTimestampKeepsRestaurantWithoutLiveState() {
        val restaurant = partnerDto(liveUpdatedAt = "not-a-date").toDomain()

        assertNull(restaurant.liveAvailability)
    }

    private fun partnerDto(
        liveStatus: String = "AVAILABLE",
        liveUpdatedAt: String = "2026-08-24T10:00:00Z",
        liveValidUntil: String = "2026-08-24T10:30:00Z",
    ) = NearbyRestaurantDto(
        id = "10000000-0000-0000-0000-000000000010",
        name = "Partner Demo",
        category = "Ristorante",
        address = "Via Demo 10",
        city = "Pesaro",
        province = "PU",
        phonePublic = false,
        partnershipStatus = "ACTIVE_PARTNER",
        liveStatus = liveStatus,
        liveUpdatedAt = liveUpdatedAt,
        liveValidUntil = liveValidUntil,
        latitude = 43.91,
        longitude = 12.91,
        distanceMeters = 100.0,
    )
}
