package com.haposto.domain

import com.haposto.domain.model.GeoPoint
import com.haposto.domain.usecase.GeoDistance
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class GeoDistanceTest {

    @Test
    fun same_point_has_zero_distance() {
        val point = GeoPoint(43.9125, 12.9138)
        assertEquals(0.0, GeoDistance.kilometersBetween(point, point), 0.000001)
    }

    @Test
    fun one_degree_of_longitude_at_equator_is_about_111_2_km() {
        val a = GeoPoint(0.0, 0.0)
        val b = GeoPoint(0.0, 1.0)

        val distance = GeoDistance.kilometersBetween(a, b)

        assertEquals(111.2, distance, 0.2)
    }

    @Test
    fun distance_is_symmetric() {
        val a = GeoPoint(43.9125, 12.9138)
        val b = GeoPoint(43.8421, 13.0164)

        val ab = GeoDistance.kilometersBetween(a, b)
        val ba = GeoDistance.kilometersBetween(b, a)

        assertEquals(ab, ba, 0.000001)
        assertTrue(ab > 5.0)
    }
}
