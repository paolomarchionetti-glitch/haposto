package com.haposto.domain.usecase

import com.haposto.domain.model.GeoPoint
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.sqrt

/** Pure Kotlin Haversine distance. No map/location SDK dependency. */
object GeoDistance {
    private const val EARTH_RADIUS_KM = 6371.0088

    fun kilometersBetween(a: GeoPoint, b: GeoPoint): Double {
        val lat1 = Math.toRadians(a.latitude)
        val lat2 = Math.toRadians(b.latitude)
        val deltaLat = Math.toRadians(b.latitude - a.latitude)
        val deltaLon = Math.toRadians(b.longitude - a.longitude)

        val haversine = sin(deltaLat / 2) * sin(deltaLat / 2) +
            cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2)

        val angularDistance = 2 * atan2(
            sqrt(haversine),
            sqrt(1 - haversine),
        )
        return EARTH_RADIUS_KM * angularDistance
    }
}
