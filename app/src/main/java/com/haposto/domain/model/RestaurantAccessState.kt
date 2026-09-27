package com.haposto.domain.model

import java.time.Instant

data class RestaurantDemoAccount(
    val id: String,
    val displayName: String,
    val email: String,
)

enum class RestaurantClaimStatus {
    PENDING,
    APPROVED,
}

data class RestaurantClaim(
    val id: String,
    val restaurantId: String,
    val accountId: String,
    val status: RestaurantClaimStatus,
    val contactInfo: String,
    val createdAt: Instant,
    val reviewedAt: Instant? = null,
)

data class RestaurantAccessState(
    val account: RestaurantDemoAccount? = null,
    val claim: RestaurantClaim? = null,
) {
    val isSignedIn: Boolean
        get() = account != null

    fun canManage(restaurantId: String): Boolean =
        account != null &&
            claim?.restaurantId == restaurantId &&
            claim.status == RestaurantClaimStatus.APPROVED
}
