package com.haposto.data.fake

import com.haposto.domain.model.RestaurantClaimStatus
import java.time.Clock
import java.time.Instant
import java.time.ZoneOffset
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class FakeRestaurantAccessRepositoryTest {
    private val fixedClock = Clock.fixed(
        Instant.parse("2026-08-24T18:00:00Z"),
        ZoneOffset.UTC,
    )

    @Test
    fun startsSignedOutWithoutClaim() = runBlocking {
        val repository = FakeRestaurantAccessRepository(
            restaurantRepository = FakeRestaurantRepository(clock = fixedClock),
            clock = fixedClock,
        )

        val state = repository.observeState().first()
        assertNull(state.account)
        assertNull(state.claim)
    }

    @Test
    fun claimCannotBeSubmittedBeforeDemoSignIn() = runBlocking {
        val repository = FakeRestaurantAccessRepository(
            restaurantRepository = FakeRestaurantRepository(clock = fixedClock),
            clock = fixedClock,
        )

        assertFalse(repository.submitClaim("levante-demo", "+390721000001"))
    }

    @Test
    fun pendingClaimDoesNotAuthorizeManagerUntilDemoApproval() = runBlocking {
        val repository = FakeRestaurantAccessRepository(
            restaurantRepository = FakeRestaurantRepository(clock = fixedClock),
            clock = fixedClock,
        )

        repository.signInWithDemoGoogle()
        assertTrue(repository.submitClaim("levante-demo", "+390721000001"))

        val pending = repository.observeState().first()
        assertEquals(RestaurantClaimStatus.PENDING, pending.claim?.status)
        assertFalse(pending.canManage("levante-demo"))

        assertTrue(repository.approvePendingClaimForDemo())
        val approved = repository.observeState().first()
        assertEquals(RestaurantClaimStatus.APPROVED, approved.claim?.status)
        assertTrue(approved.canManage("levante-demo"))
        assertFalse(approved.canManage("porto-46-demo"))
    }

    @Test
    fun directoryOnlyRestaurantIsNotClaimableInStep4Shell() = runBlocking {
        val repository = FakeRestaurantAccessRepository(
            restaurantRepository = FakeRestaurantRepository(clock = fixedClock),
            clock = fixedClock,
        )

        repository.signInWithDemoGoogle()
        assertFalse(repository.submitClaim("riva-demo", "+390721000099"))
    }

    @Test
    fun signOutBlocksManagerButClaimCanBeRecoveredBySameDemoIdentity() = runBlocking {
        val repository = FakeRestaurantAccessRepository(
            restaurantRepository = FakeRestaurantRepository(clock = fixedClock),
            clock = fixedClock,
        )

        repository.signInWithDemoGoogle()
        repository.submitClaim("levante-demo", "+390721000001")
        repository.approvePendingClaimForDemo()
        repository.signOut()

        val signedOut = repository.observeState().first()
        assertFalse(signedOut.canManage("levante-demo"))
        assertEquals(RestaurantClaimStatus.APPROVED, signedOut.claim?.status)

        repository.signInWithDemoGoogle()
        assertTrue(repository.observeState().first().canManage("levante-demo"))
    }

    @Test
    fun resetDemoClearsAccountAndClaim() = runBlocking {
        val repository = FakeRestaurantAccessRepository(
            restaurantRepository = FakeRestaurantRepository(clock = fixedClock),
            clock = fixedClock,
        )

        repository.signInWithDemoGoogle()
        repository.submitClaim("levante-demo", "+390721000001")
        repository.resetDemo()

        val state = repository.observeState().first()
        assertNull(state.account)
        assertNull(state.claim)
    }
}
