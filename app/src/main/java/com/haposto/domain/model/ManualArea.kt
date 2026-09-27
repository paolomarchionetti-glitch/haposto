package com.haposto.domain.model

enum class ManualArea(
    val label: String,
    val center: GeoPoint,
) {
    PESARO(
        label = "Pesaro centro",
        center = GeoPoint(latitude = 43.9125, longitude = 12.9138),
    ),
    FANO(
        label = "Fano centro",
        center = GeoPoint(latitude = 43.8421, longitude = 13.0164),
    ),
    URBINO(
        label = "Urbino centro",
        center = GeoPoint(latitude = 43.7252, longitude = 12.6373),
    ),
    GABICCE_MARE(
        label = "Gabicce Mare",
        center = GeoPoint(latitude = 43.9662, longitude = 12.7566),
    ),
}
