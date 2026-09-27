package com.haposto.domain

import com.haposto.domain.model.GeoPoint
import com.haposto.domain.model.PartnershipStatus
import com.haposto.domain.model.Restaurant
import com.haposto.domain.usecase.RestaurantDistance
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Test

class RestaurantDistanceTest {

    @Test
    fun attach_computes_distance_without_mutating_location() {
        val restaurant = Restaurant(
            id = "x",
            name = "Test",
            category = "Cucina",
            address = "Via Test 1",
            city = "Pesaro",
            location = GeoPoint(43.9125, 12.9138),
            partnershipStatus = PartnershipStatus.DIRECTORY_ONLY,
        )

        val located = RestaurantDistance.attach(
            restaurant = restaurant,
            origin = GeoPoint(43.9125, 12.9138),
        )

        assertNotNull(located.distanceKm)
        assertEquals(0.0, located.distanceKm ?: -1.0, 0.000001)
        assertEquals(restaurant.location, located.location)
    }
}
