package com.haposto.ui.navigation

object AppDestination {
    const val HOME = "home"
    const val FAVORITES = "favorites"
    const val ACCOUNT = "account"
    const val RESTAURANT_DETAIL = "restaurant/{restaurantId}"

    /** Solo versione DEMO: accesso ristoratore simulato. */
    const val RESTAURANT_ACCESS = "restaurant-access"

    /** Versioni DEV/PROD: area ristoratore con account vero. */
    const val RESTAURANT_AREA = "restaurant-area"
    const val RESTAURANT_MANAGER = "restaurant-manager/{restaurantId}"
    const val RESTAURANT_SETTINGS = "restaurant-settings/{restaurantId}"
    const val REGISTER_RESTAURANT = "register-restaurant"
    const val RESERVATIONS = "reservations/{restaurantId}"
    const val MFA = "mfa"
    const val LEGAL = "legal/{document}"
    const val PLUS = "plus"
    const val ADMIN = "admin"
    const val ADMIN_RESTAURANT = "admin-restaurant/{restaurantId}"
    const val ADMIN_USER = "admin-user/{userId}"

    /** Destinazioni che mostrano la barra inferiore. */
    val TOP_LEVEL = setOf(HOME, FAVORITES, ACCOUNT, RESTAURANT_AREA, RESTAURANT_ACCESS)

    fun isTopLevel(route: String?): Boolean = route in TOP_LEVEL

    fun restaurantDetail(restaurantId: String): String = "restaurant/$restaurantId"
    fun restaurantManager(restaurantId: String): String = "restaurant-manager/$restaurantId"
    fun restaurantSettings(restaurantId: String): String = "restaurant-settings/$restaurantId"
    fun reservations(restaurantId: String): String = "reservations/$restaurantId"
    fun legal(document: String): String = "legal/$document"
    fun adminRestaurant(restaurantId: String): String = "admin-restaurant/$restaurantId"
    fun adminUser(userId: String): String = "admin-user/$userId"
}
