package com.haposto.domain

import com.haposto.domain.model.AvailabilityStatus
import com.haposto.domain.model.GeoPoint
import com.haposto.domain.model.LiveAvailability
import com.haposto.domain.model.PartnershipStatus
import com.haposto.domain.model.Restaurant
import com.haposto.domain.usecase.AvailabilityResolver
import java.time.Instant
import org.junit.Assert.assertEquals
import org.junit.Test

class AvailabilityResolverTest {

    private val now = Instant.parse("2026-08-24T18:00:00Z")

    @Test
    fun fresh_partner_status_remains_available() {
        val restaurant = partner(
            live = LiveAvailability(
                status = AvailabilityStatus.AVAILABLE,
                updatedAt = Instant.parse("2026-08-24T17:50:00Z"),
                validUntil = Instant.parse("2026-08-24T18:20:00Z"),
            )
        )

        assertEquals(
            AvailabilityStatus.AVAILABLE,
            AvailabilityResolver.resolve(restaurant, now).status,
        )
    }

    @Test
    fun offer_isShownOnlyWhileTheStatusIsValid() {
        fun withOffer(validUntil: String) = partner(
            live = LiveAvailability(
                status = AvailabilityStatus.AVAILABLE,
                updatedAt = Instant.parse("2026-08-24T17:40:00Z"),
                validUntil = Instant.parse(validUntil),
                offer = "Dolce offerto",
            ),
        )
        assertEquals("Dolce offerto", AvailabilityResolver.resolve(withOffer("2026-08-24T18:10:00Z"), now).offer)
        assertEquals(null, AvailabilityResolver.resolve(withOffer("2026-08-24T17:55:00Z"), now).offer)
    }

    @Test
    fun expired_partner_status_becomes_stale() {
        val restaurant = partner(
            live = LiveAvailability(
                status = AvailabilityStatus.AVAILABLE,
                updatedAt = Instant.parse("2026-08-24T17:20:00Z"),
                validUntil = Instant.parse("2026-08-24T17:50:00Z"),
            )
        )

        assertEquals(
            AvailabilityStatus.STALE,
            AvailabilityResolver.resolve(restaurant, now).status,
        )
    }

    @Test
    fun status_is_stale_exactly_at_expiry() {
        val restaurant = partner(
            live = LiveAvailability(
                status = AvailabilityStatus.LIMITED,
                updatedAt = Instant.parse("2026-08-24T17:30:00Z"),
                validUntil = now,
            )
        )

        assertEquals(
            AvailabilityStatus.STALE,
            AvailabilityResolver.resolve(restaurant, now).status,
        )
    }

    @Test
    fun directory_only_is_not_connected() {
        val restaurant = baseRestaurant(
            partnershipStatus = PartnershipStatus.DIRECTORY_ONLY,
            live = null,
        )

        assertEquals(
            AvailabilityStatus.NOT_CONNECTED,
            AvailabilityResolver.resolve(restaurant, now).status,
        )
    }

    private fun partner(live: LiveAvailability) = baseRestaurant(
        partnershipStatus = PartnershipStatus.ACTIVE_PARTNER,
        live = live,
    )

    private fun baseRestaurant(
        partnershipStatus: PartnershipStatus,
        live: LiveAvailability?,
    ) = Restaurant(
        id = "test",
        name = "Test",
        category = "Test",
        address = "Via Test 1",
        city = "Pesaro",
        location = GeoPoint(43.91, 12.91),
        distanceKm = 1.0,
        partnershipStatus = partnershipStatus,
        liveAvailability = live,
    )
}
