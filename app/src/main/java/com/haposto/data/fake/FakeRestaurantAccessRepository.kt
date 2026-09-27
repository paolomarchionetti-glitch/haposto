package com.haposto.data.fake

import com.haposto.data.repository.RestaurantAccessRepository
import com.haposto.data.repository.RestaurantRepository
import com.haposto.domain.model.PartnershipStatus
import com.haposto.domain.model.RestaurantAccessState
import com.haposto.domain.model.RestaurantClaim
import com.haposto.domain.model.RestaurantClaimStatus
import com.haposto.domain.model.RestaurantDemoAccount
import java.time.Clock
import java.util.UUID
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow

/**
 * RAM-only access/claim state introduced in STEP 4 and frozen as the local reference behavior in STEP 6.
 *
 * It intentionally does NOT authenticate anybody. It only lets us validate the future owner UX.
 */
class FakeRestaurantAccessRepository(
    private val restaurantRepository: RestaurantRepository,
    private val clock: Clock = Clock.systemUTC(),
) : RestaurantAccessRepository {

    private val state = MutableStateFlow(RestaurantAccessState())

    override fun observeState(): Flow<RestaurantAccessState> = state
    override fun currentState(): RestaurantAccessState = state.value

    override suspend fun signInWithDemoGoogle(): RestaurantDemoAccount {
        val account = RestaurantDemoAccount(
            id = DEMO_ACCOUNT_ID,
            displayName = "Titolare Demo",
            email = "titolare.demo@haposto.invalid",
        )
        state.value = state.value.copy(account = account)
        return account
    }

    override suspend fun submitClaim(
        restaurantId: String,
        contactInfo: String,
    ): Boolean {
        val account = state.value.account ?: return false
        if (state.value.claim != null) return false

        val restaurant = restaurantRepository.findById(restaurantId) ?: return false
        // In the local claim demo, search is intentionally limited to already-connected demo partners.
        // A real backend will support onboarding a DIRECTORY_ONLY venue and activate it after review.
        if (restaurant.partnershipStatus != PartnershipStatus.ACTIVE_PARTNER) return false

        val normalizedContact = contactInfo.trim()
        if (normalizedContact.length !in 3..120) return false

        state.value = state.value.copy(
            claim = RestaurantClaim(
                id = UUID.randomUUID().toString(),
                restaurantId = restaurantId,
                accountId = account.id,
                status = RestaurantClaimStatus.PENDING,
                contactInfo = normalizedContact,
                createdAt = clock.instant(),
            ),
        )
        return true
    }

    override suspend fun approvePendingClaimForDemo(): Boolean {
        val current = state.value
        val account = current.account ?: return false
        val claim = current.claim ?: return false
        if (claim.accountId != account.id || claim.status != RestaurantClaimStatus.PENDING) return false

        state.value = current.copy(
            claim = claim.copy(
                status = RestaurantClaimStatus.APPROVED,
                reviewedAt = clock.instant(),
            ),
        )
        return true
    }

    override suspend fun signOut() {
        // Keep the server-equivalent claim in RAM so signing back in with the same demo identity
        // demonstrates session restoration semantics. resetDemo() clears everything.
        state.value = state.value.copy(account = null)
    }

    override suspend fun resetDemo() {
        state.value = RestaurantAccessState()
    }

    private companion object {
        const val DEMO_ACCOUNT_ID = "google-demo-owner"
    }
}
