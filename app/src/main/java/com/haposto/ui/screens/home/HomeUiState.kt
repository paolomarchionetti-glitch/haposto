package com.haposto.ui.screens.home

import com.haposto.domain.model.DistanceOrigin
import com.haposto.domain.model.ManualArea
import com.haposto.domain.model.Restaurant
import com.haposto.domain.model.RestaurantFilter
import java.time.Instant

enum class LocationNotice {
    RATIONALE_REQUIRED,
    PERMISSION_DENIED,
    PERMISSION_DENIED_PERMANENT,
    SERVICES_DISABLED,
    UNAVAILABLE,
}

enum class HomeEmptyReason {
    DIRECTORY_EMPTY,
    NO_MATCHES,
}

data class HomeUiState(
    val searchQuery: String = "",
    val selectedFilter: RestaurantFilter = RestaurantFilter.ALL,
    val restaurants: List<Restaurant> = emptyList(),
    val totalRestaurantCount: Int = 0,
    val now: Instant = Instant.EPOCH,
    val distanceOrigin: DistanceOrigin = DistanceOrigin.manual(ManualArea.PESARO),
    val isLocating: Boolean = false,
    val locationNotice: LocationNotice? = null,
    val isInitialLoading: Boolean = true,
    val errorMessage: String? = null,
    val isOnline: Boolean = true,
    val isDemoData: Boolean = true,
    val isSupabaseBacked: Boolean = false,
) {
    val hasResults: Boolean get() = restaurants.isNotEmpty()

    val emptyReason: HomeEmptyReason?
        get() = when {
            hasResults -> null
            searchQuery.isNotBlank() || selectedFilter != RestaurantFilter.ALL -> HomeEmptyReason.NO_MATCHES
            totalRestaurantCount == 0 -> HomeEmptyReason.DIRECTORY_EMPTY
            else -> HomeEmptyReason.NO_MATCHES
        }
}
