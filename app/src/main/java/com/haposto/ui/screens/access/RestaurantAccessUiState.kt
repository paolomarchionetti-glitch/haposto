package com.haposto.ui.screens.access

import com.haposto.domain.model.Restaurant
import com.haposto.domain.model.RestaurantClaim
import com.haposto.domain.model.RestaurantDemoAccount

enum class RestaurantAccessPhase {
    SIGNED_OUT,
    SEARCH,
    CLAIM_FORM,
    PENDING,
    APPROVED,
}

data class RestaurantAccessUiState(
    val phase: RestaurantAccessPhase = RestaurantAccessPhase.SIGNED_OUT,
    val account: RestaurantDemoAccount? = null,
    val claim: RestaurantClaim? = null,
    val claimRestaurant: Restaurant? = null,
    val searchQuery: String = "",
    val candidates: List<Restaurant> = emptyList(),
    val selectedRestaurant: Restaurant? = null,
    val contactInfo: String = "",
    val isBusy: Boolean = false,
    val message: String? = null,
)
