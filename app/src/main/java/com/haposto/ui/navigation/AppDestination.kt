package com.haposto.ui.navigation

object AppDestination {
    const val HOME = "home"
    const val FAVORITES = "favorites"
    const val RESTAURANT_DETAIL = "restaurant/{restaurantId}"
    const val RESTAURANT_ACCESS = "restaurant-access"
    const val RESTAURANT_MANAGER = "restaurant-manager/{restaurantId}"
    const val RESERVATIONS = "reservations/{restaurantId}"

    /** Destinazioni che mostrano la barra inferiore. */
    val TOP_LEVEL = setOf(HOME, FAVORITES)

    fun isTopLevel(route: String?): Boolean = route in TOP_LEVEL

    fun restaurantDetail(restaurantId: String): String = "restaurant/$restaurantId"
    fun restaurantManager(restaurantId: String): String = "restaurant-manager/$restaurantId"
    fun reservations(restaurantId: String): String = "reservations/$restaurantId"
}
