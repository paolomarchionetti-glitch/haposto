package com.haposto.data.location

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.os.CancellationSignal
import androidx.core.content.ContextCompat
import androidx.core.location.LocationManagerCompat
import com.haposto.domain.model.GeoPoint
import kotlin.coroutines.resume
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withTimeoutOrNull

/**
 * Foreground, one-shot device location using Android platform services only.
 * No Google Maps SDK, no Fused Location dependency and no background tracking.
 */
class AndroidDeviceLocationProvider(
    private val context: Context,
) : DeviceLocationProvider {

    private val locationManager: LocationManager by lazy {
        context.getSystemService(LocationManager::class.java)
    }

    override suspend fun currentLocation(): DeviceLocationResult {
        if (!hasAnyLocationPermission()) {
            return DeviceLocationResult.PermissionMissing
        }
        if (!LocationManagerCompat.isLocationEnabled(locationManager)) {
            return DeviceLocationResult.ServicesDisabled
        }

        val enabledProviders = listOf(
            LocationManager.NETWORK_PROVIDER,
            LocationManager.GPS_PROVIDER,
        ).filter { provider ->
            LocationManagerCompat.hasProvider(locationManager, provider) &&
                runCatching { locationManager.isProviderEnabled(provider) }.getOrDefault(false)
        }

        if (enabledProviders.isEmpty()) {
            return DeviceLocationResult.ServicesDisabled
        }

        for (provider in enabledProviders) {
            val location = withTimeoutOrNull(6_000) {
                requestSingleLocation(provider)
            }
            if (location != null) {
                return DeviceLocationResult.Success(
                    point = GeoPoint(
                        latitude = location.latitude,
                        longitude = location.longitude,
                    ),
                    accuracyMeters = location.accuracy.takeIf { location.hasAccuracy() },
                )
            }
        }

        return DeviceLocationResult.Unavailable
    }

    private fun hasAnyLocationPermission(): Boolean {
        val fine = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION,
        ) == PackageManager.PERMISSION_GRANTED
        val coarse = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_COARSE_LOCATION,
        ) == PackageManager.PERMISSION_GRANTED
        return fine || coarse
    }

    @SuppressLint("MissingPermission")
    private suspend fun requestSingleLocation(provider: String): Location? =
        suspendCancellableCoroutine { continuation ->
            val cancellationSignal = CancellationSignal()
            continuation.invokeOnCancellation { cancellationSignal.cancel() }

            LocationManagerCompat.getCurrentLocation(
                locationManager,
                provider,
                cancellationSignal,
                ContextCompat.getMainExecutor(context),
            ) { location ->
                if (continuation.isActive) {
                    continuation.resume(location)
                }
            }
        }
}
