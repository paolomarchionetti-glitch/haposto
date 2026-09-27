package com.haposto.domain.usecase

import com.haposto.domain.model.GeoPoint
import com.haposto.domain.model.Restaurant

object RestaurantDistance {
    fun attach(
        restaurant: Restaurant,
        origin: GeoPoint,
    ): Restaurant = restaurant.copy(
        distanceKm = GeoDistance.kilometersBetween(origin, restaurant.location),
    )

    fun attach(
        restaurants: List<Restaurant>,
        origin: GeoPoint,
    ): List<Restaurant> = restaurants.map { attach(it, origin) }
}
