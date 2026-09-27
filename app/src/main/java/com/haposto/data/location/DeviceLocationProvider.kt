package com.haposto.data.location

import com.haposto.domain.model.GeoPoint

interface DeviceLocationProvider {
    suspend fun currentLocation(): DeviceLocationResult
}

sealed interface DeviceLocationResult {
    data class Success(
        val point: GeoPoint,
        val accuracyMeters: Float?,
    ) : DeviceLocationResult

    data object PermissionMissing : DeviceLocationResult
    data object ServicesDisabled : DeviceLocationResult
    data object Unavailable : DeviceLocationResult
}
