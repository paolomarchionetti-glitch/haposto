package com.haposto.domain.model

enum class DistanceOriginType {
    DEVICE,
    MANUAL_AREA,
}

data class DistanceOrigin(
    val point: GeoPoint,
    val label: String,
    val type: DistanceOriginType,
    val accuracyMeters: Float? = null,
    val isPrecise: Boolean? = null,
) {
    companion object {
        fun manual(area: ManualArea): DistanceOrigin = DistanceOrigin(
            point = area.center,
            label = area.label,
            type = DistanceOriginType.MANUAL_AREA,
        )

        fun device(
            point: GeoPoint,
            accuracyMeters: Float?,
            isPrecise: Boolean,
        ): DistanceOrigin = DistanceOrigin(
            point = point,
            label = "La tua posizione",
            type = DistanceOriginType.DEVICE,
            accuracyMeters = accuracyMeters,
            isPrecise = isPrecise,
        )
    }
}
