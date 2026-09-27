package com.haposto.data.fake

import com.haposto.domain.model.AvailabilityStatus
import com.haposto.domain.usecase.AvailabilityResolver
import java.time.Clock
import java.time.Duration
import java.time.Instant
import java.time.ZoneOffset
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

class FakeRestaurantRepositoryTest {

    private val now = Instant.parse("2026-08-24T18:30:00Z")
    private val clock = Clock.fixed(now, ZoneOffset.UTC)

    @Test
    fun publishAvailability_updatesSharedRestaurantAndCreatesThirtyMinuteTtl() = runBlocking {
        val repository = FakeRestaurantRepository(clock)

        val success = repository.publishAvailability(
            restaurantId = "levante-demo",
            status = AvailabilityStatus.FULL,
            availableTables = 0,
            estimatedWaitMinutes = 30,
            note = "Test locale",
        )

        assertTrue(success)
        val updated = repository.observeRestaurants().first().first { it.id == "levante-demo" }
        val live = updated.liveAvailability
        assertNotNull(live)
        assertEquals(AvailabilityStatus.FULL, live?.status)
        assertEquals(now, live?.updatedAt)
        assertEquals(now.plus(Duration.ofMinutes(AvailabilityResolver.DEFAULT_TTL_MINUTES)), live?.validUntil)
        assertEquals(null, live?.availableTables)
        assertEquals(30, live?.estimatedWaitMinutes)
        assertEquals("Test locale", live?.note)
    }

    @Test
    fun directoryOnlyRestaurant_cannotPublishLiveState() = runBlocking {
        val repository = FakeRestaurantRepository(clock)

        val success = repository.publishAvailability(
            restaurantId = "riva-demo",
            status = AvailabilityStatus.AVAILABLE,
        )

        assertFalse(success)
        val restaurant = repository.observeRestaurants().first().first { it.id == "riva-demo" }
        assertEquals(null, restaurant.liveAvailability)
    }

    @Test
    fun phoneVisibility_isSharedAndDoesNotChangeAvailabilityTimestamp() = runBlocking {
        val repository = FakeRestaurantRepository(clock)
        val before = repository.findById("levante-demo")?.liveAvailability?.updatedAt

        val success = repository.setPhonePublic("levante-demo", false)

        assertTrue(success)
        val updated = repository.observeRestaurants().first().first { it.id == "levante-demo" }
        assertFalse(updated.phonePublic)
        assertEquals(before, updated.liveAvailability?.updatedAt)
    }
}
