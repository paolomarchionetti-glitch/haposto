package com.haposto.data.repository

import com.haposto.domain.model.RestaurantAccessState
import com.haposto.domain.model.RestaurantDemoAccount
import kotlinx.coroutines.flow.Flow

/**
 * Boundary for restaurant identity + claim state.
 *
 * STEP 6 freezes this as the V1 pre-backend access contract. The RAM-only fake implementation is
 * the reference UX behavior; STEP 7/8 will map it to Supabase Auth, restaurant_claims and
 * restaurant_users without changing the Compose flow.
 */
interface RestaurantAccessRepository {
    fun observeState(): Flow<RestaurantAccessState>
    fun currentState(): RestaurantAccessState

    /** Clearly simulated local identity. No provider SDK and no network request are involved. */
    suspend fun signInWithDemoGoogle(): RestaurantDemoAccount

    suspend fun submitClaim(
        restaurantId: String,
        contactInfo: String,
    ): Boolean

    /** Local demo admin simulation (STEP 4–6). This method must never become a production client power. */
    suspend fun approvePendingClaimForDemo(): Boolean

    suspend fun signOut()

    /** Clears account + claim so the full onboarding can be replayed during prototype testing. */
    suspend fun resetDemo()
}
