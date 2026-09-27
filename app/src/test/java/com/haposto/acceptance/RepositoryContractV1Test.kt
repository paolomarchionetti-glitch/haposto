package com.haposto.acceptance

import com.haposto.data.fake.FakeRestaurantAccessRepository
import com.haposto.data.fake.FakeRestaurantRepository
import com.haposto.data.repository.RestaurantAccessRepository
import com.haposto.data.repository.RestaurantRepository
import com.haposto.domain.model.AvailabilityStatus
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** Compile-time contract smoke test for the interfaces frozen at STEP 6. */
class RepositoryContractV1Test {

    @Test
    fun fakeImplementations_satisfyFrozenV1Boundaries() = runBlocking {
        val restaurants: RestaurantRepository = FakeRestaurantRepository()
        val access: RestaurantAccessRepository = FakeRestaurantAccessRepository(restaurants)

        assertTrue(restaurants.findById("levante-demo") != null)
        assertTrue(
            restaurants.publishAvailability(
                restaurantId = "levante-demo",
                status = AvailabilityStatus.LIMITED,
            ),
        )
        assertTrue(restaurants.setPhonePublic("levante-demo", false))

        access.signInWithDemoGoogle()
        assertTrue(access.submitClaim("levante-demo", "demo-contact"))
        assertTrue(access.approvePendingClaimForDemo())
        assertTrue(access.currentState().canManage("levante-demo"))
        access.signOut()
        assertFalse(access.currentState().canManage("levante-demo"))
        access.resetDemo()
        assertFalse(access.currentState().isSignedIn)
    }
}
