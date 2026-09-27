package com.haposto.acceptance

import com.haposto.data.fake.FakeRestaurantAccessRepository
import com.haposto.data.fake.FakeRestaurantRepository
import com.haposto.domain.model.AvailabilityRules
import com.haposto.domain.model.AvailabilityStatus
import com.haposto.domain.model.RestaurantClaimStatus
import java.time.Clock
import java.time.Instant
import java.time.ZoneOffset
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * STEP 6 pre-backend acceptance loop.
 *
 * It exercises the same repository instances used by consumer and manager flows, proving that the
 * prototype is one connected demo rather than independent screen mockups.
 */
class PreBackendDemoAcceptanceTest {

    private val instant = Instant.parse("2026-08-24T18:30:00Z")
    private val clock = Clock.fixed(instant, ZoneOffset.UTC)

    @Test
    fun fullLocalLoop_claimApprovalManagerPublishAndConsumerRead_areConsistent() = runBlocking {
        val restaurantRepository = FakeRestaurantRepository(clock)
        val accessRepository = FakeRestaurantAccessRepository(
            restaurantRepository = restaurantRepository,
            clock = clock,
        )
        val restaurantId = "levante-demo"

        // Consumer can read the directory without any account.
        val before = restaurantRepository.findById(restaurantId)
        assertNotNull(before)
        assertEquals(AvailabilityStatus.AVAILABLE, before?.liveAvailability?.status)
        assertFalse(accessRepository.currentState().isSignedIn)

        // Restaurant identity is separate from the public consumer flow.
        accessRepository.signInWithDemoGoogle()
        assertTrue(accessRepository.currentState().isSignedIn)
        assertFalse(accessRepository.currentState().canManage(restaurantId))

        // Claim starts PENDING and does not unlock the dashboard.
        assertTrue(
            accessRepository.submitClaim(
                restaurantId = restaurantId,
                contactInfo = "+39 0721 000001",
            ),
        )
        assertEquals(
            RestaurantClaimStatus.PENDING,
            accessRepository.currentState().claim?.status,
        )
        assertFalse(accessRepository.currentState().canManage(restaurantId))

        // Only the demo-admin action changes the claim to APPROVED.
        assertTrue(accessRepository.approvePendingClaimForDemo())
        assertEquals(
            RestaurantClaimStatus.APPROVED,
            accessRepository.currentState().claim?.status,
        )
        assertTrue(accessRepository.currentState().canManage(restaurantId))

        // Manager publishes FULL through the shared repository.
        assertTrue(
            restaurantRepository.publishAvailability(
                restaurantId = restaurantId,
                status = AvailabilityStatus.FULL,
                availableTables = 4, // must be normalized away by the repository contract.
                estimatedWaitMinutes = 20,
                note = "Sala completa, possibile attesa",
            ),
        )

        // Consumer sees exactly the same mutation from the same source of truth.
        val after = restaurantRepository.findById(restaurantId)
        assertEquals(AvailabilityStatus.FULL, after?.liveAvailability?.status)
        assertEquals(instant, after?.liveAvailability?.updatedAt)
        assertEquals(
            instant.plusSeconds(AvailabilityRules.LIVE_TTL_MINUTES * 60),
            after?.liveAvailability?.validUntil,
        )
        assertNull(after?.liveAvailability?.availableTables)
        assertEquals(20, after?.liveAvailability?.estimatedWaitMinutes)

        // Public-phone mutation is independent from LIVE freshness.
        val liveTimestamp = after?.liveAvailability?.updatedAt
        assertTrue(restaurantRepository.setPhonePublic(restaurantId, false))
        val phoneHidden = restaurantRepository.findById(restaurantId)
        assertFalse(phoneHidden?.phonePublic ?: true)
        assertEquals(liveTimestamp, phoneHidden?.liveAvailability?.updatedAt)

        // Logout revokes the client-side manager gate; signing back in restores the RAM claim.
        accessRepository.signOut()
        assertFalse(accessRepository.currentState().canManage(restaurantId))
        accessRepository.signInWithDemoGoogle()
        assertTrue(accessRepository.currentState().canManage(restaurantId))
    }

    @Test
    fun directoryOnlyVenue_cannotPublishOrBeClaimedInCurrentDemoShell() = runBlocking {
        val restaurantRepository = FakeRestaurantRepository(clock)
        val accessRepository = FakeRestaurantAccessRepository(restaurantRepository, clock)

        assertFalse(
            restaurantRepository.publishAvailability(
                restaurantId = "riva-demo",
                status = AvailabilityStatus.AVAILABLE,
            ),
        )

        accessRepository.signInWithDemoGoogle()
        assertFalse(
            accessRepository.submitClaim(
                restaurantId = "riva-demo",
                contactInfo = "demo@example.invalid",
            ),
        )
    }
}
