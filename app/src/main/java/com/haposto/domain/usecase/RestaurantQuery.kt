package com.haposto.domain.usecase

import com.haposto.domain.model.AvailabilityStatus
import com.haposto.domain.model.Restaurant
import com.haposto.domain.model.RestaurantFilter
import java.time.Instant

object RestaurantQuery {

    fun apply(
        restaurants: List<Restaurant>,
        query: String,
        filter: RestaurantFilter,
        now: Instant,
    ): List<Restaurant> {
        val normalizedQuery = query.trim().lowercase()

        return restaurants
            .asSequence()
            .filter { restaurant ->
                normalizedQuery.isBlank() ||
                    restaurant.name.lowercase().contains(normalizedQuery) ||
                    restaurant.category.lowercase().contains(normalizedQuery) ||
                    restaurant.address.lowercase().contains(normalizedQuery) ||
                    restaurant.city.lowercase().contains(normalizedQuery)
            }
            .filter { restaurant ->
                val status = AvailabilityResolver.resolve(restaurant, now).status
                when (filter) {
                    RestaurantFilter.ALL -> true
                    RestaurantFilter.AVAILABLE -> status == AvailabilityStatus.AVAILABLE
                    RestaurantFilter.LIMITED -> status == AvailabilityStatus.LIMITED
                    RestaurantFilter.LIVE -> status in setOf(
                        AvailabilityStatus.AVAILABLE,
                        AvailabilityStatus.LIMITED,
                        AvailabilityStatus.FULL,
                    )
                }
            }
            .sortedBy { it.distanceKm ?: Double.MAX_VALUE }
            .toList()
    }
}
