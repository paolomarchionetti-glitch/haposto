package com.haposto.data.location

import com.haposto.domain.model.DistanceOrigin
import com.haposto.domain.model.GeoPoint
import com.haposto.domain.model.ManualArea
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Process-memory only. Device coordinates are never persisted.
 * In STEP 7, when Supabase is configured, the current point is sent only as an RPC parameter
 * for the nearby search and is not inserted into HAPOSTO tables.
 */
class LocationSession {
    private val _origin = MutableStateFlow(DistanceOrigin.manual(ManualArea.PESARO))
    val origin: StateFlow<DistanceOrigin> = _origin.asStateFlow()

    fun useManualArea(area: ManualArea) {
        _origin.value = DistanceOrigin.manual(area)
    }

    fun useDeviceLocation(
        point: GeoPoint,
        accuracyMeters: Float?,
        isPrecise: Boolean,
    ) {
        _origin.value = DistanceOrigin.device(
            point = point,
            accuracyMeters = accuracyMeters,
            isPrecise = isPrecise,
        )
    }
}
