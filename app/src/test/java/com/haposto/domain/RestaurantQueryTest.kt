package com.haposto.domain

import com.haposto.domain.model.AvailabilityStatus
import com.haposto.domain.model.GeoPoint
import com.haposto.domain.model.LiveAvailability
import com.haposto.domain.model.PartnershipStatus
import com.haposto.domain.model.Restaurant
import com.haposto.domain.model.RestaurantFilter
import com.haposto.domain.usecase.RestaurantQuery
import java.time.Instant
import org.junit.Assert.assertEquals
import org.junit.Test

class RestaurantQueryTest {

    private val now = Instant.parse("2026-08-24T18:00:00Z")

    @Test
    fun available_filter_excludes_full_stale_and_not_connected() {
        val restaurants = listOf(
            restaurant("a", 2.0, AvailabilityStatus.AVAILABLE),
            restaurant("b", 1.0, AvailabilityStatus.FULL),
            directoryRestaurant("c", 0.5),
        )

        val result = RestaurantQuery.apply(
            restaurants = restaurants,
            query = "",
            filter = RestaurantFilter.AVAILABLE,
            now = now,
        )

        assertEquals(listOf("a"), result.map { it.id })
    }

    @Test
    fun all_results_are_sorted_by_distance() {
        val restaurants = listOf(
            restaurant("far", 5.0, AvailabilityStatus.AVAILABLE),
            restaurant("near", 0.3, AvailabilityStatus.FULL),
        )

        val result = RestaurantQuery.apply(
            restaurants = restaurants,
            query = "",
            filter = RestaurantFilter.ALL,
            now = now,
        )

        assertEquals(listOf("near", "far"), result.map { it.id })
    }

    @Test
    fun search_matches_category_case_insensitively() {
        val restaurants = listOf(
            restaurant("pizza", 1.0, AvailabilityStatus.AVAILABLE, category = "Pizza"),
            restaurant("fish", 2.0, AvailabilityStatus.AVAILABLE, category = "Pesce"),
        )

        val result = RestaurantQuery.apply(
            restaurants = restaurants,
            query = "PIZZA",
            filter = RestaurantFilter.ALL,
            now = now,
        )

        assertEquals(listOf("pizza"), result.map { it.id })
    }

    @Test
    fun search_also_matches_city() {
        val restaurants = listOf(
            restaurant("pesaro", 1.0, AvailabilityStatus.AVAILABLE, city = "Pesaro"),
            restaurant("fano", 2.0, AvailabilityStatus.AVAILABLE, city = "Fano"),
        )

        val result = RestaurantQuery.apply(
            restaurants = restaurants,
            query = "fano",
            filter = RestaurantFilter.ALL,
            now = now,
        )

        assertEquals(listOf("fano"), result.map { it.id })
    }

    private fun restaurant(
        id: String,
        distanceKm: Double,
        status: AvailabilityStatus,
        category: String = "Cucina",
        city: String = "Pesaro",
    ) = Restaurant(
        id = id,
        name = "Ristorante $id",
        category = category,
        address = "Via Test 1",
        city = city,
        location = GeoPoint(43.91, 12.91),
        distanceKm = distanceKm,
        partnershipStatus = PartnershipStatus.ACTIVE_PARTNER,
        liveAvailability = LiveAvailability(
            status = status,
            updatedAt = Instant.parse("2026-08-24T17:50:00Z"),
            validUntil = Instant.parse("2026-08-24T18:20:00Z"),
        ),
    )

    private fun directoryRestaurant(id: String, distanceKm: Double) = Restaurant(
        id = id,
        name = "Ristorante $id",
        category = "Cucina",
        address = "Via Test 1",
        city = "Pesaro",
        location = GeoPoint(43.91, 12.91),
        distanceKm = distanceKm,
        partnershipStatus = PartnershipStatus.DIRECTORY_ONLY,
    )
}
