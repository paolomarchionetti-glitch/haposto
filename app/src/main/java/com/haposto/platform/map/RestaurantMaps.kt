package com.haposto.platform.map

import android.graphics.Color
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.viewinterop.AndroidView
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import com.haposto.domain.model.AvailabilityStatus
import com.haposto.domain.model.GeoPoint
import com.haposto.domain.model.Restaurant
import com.haposto.domain.usecase.AvailabilityResolver
import java.time.Instant
import kotlinx.serialization.json.add
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlinx.serialization.json.putJsonArray
import kotlinx.serialization.json.putJsonObject
import org.maplibre.android.MapLibre
import org.maplibre.android.camera.CameraUpdateFactory
import org.maplibre.android.geometry.LatLng
import org.maplibre.android.maps.MapLibreMap
import org.maplibre.android.maps.MapView
import org.maplibre.android.style.expressions.Expression
import org.maplibre.android.style.layers.CircleLayer
import org.maplibre.android.style.layers.PropertyFactory
import org.maplibre.android.style.sources.GeoJsonSource

/**
 * Mappe gratuite: MapLibre (libreria open source) + stile "Liberty" di OpenFreeMap (tile gratuite,
 * senza chiave e senza limiti, dati © OpenStreetMap contributors; l'attribuzione è nel tasto "i").
 */
object FreeMaps {
    const val STYLE_URL = "https://tiles.openfreemap.org/styles/liberty"

    fun colorFor(status: AvailabilityStatus): String = when (status) {
        AvailabilityStatus.AVAILABLE -> "#12A867"
        AvailabilityStatus.LIMITED -> "#E0A100"
        AvailabilityStatus.FULL -> "#C0392B"
        AvailabilityStatus.STALE -> "#8A969A"
        AvailabilityStatus.NOT_CONNECTED -> "#C4CCCA"
    }
}

/** Crea e ricorda una MapView legata al ciclo di vita della schermata. */
@Composable
private fun rememberMapView(): MapView {
    val context = LocalContext.current
    val mapView = remember {
        MapLibre.getInstance(context)
        MapView(context).apply { onCreate(null) }
    }
    val lifecycle = LocalLifecycleOwner.current.lifecycle
    DisposableEffect(lifecycle, mapView) {
        val observer = LifecycleEventObserver { _, event ->
            when (event) {
                Lifecycle.Event.ON_START -> mapView.onStart()
                Lifecycle.Event.ON_RESUME -> mapView.onResume()
                Lifecycle.Event.ON_PAUSE -> mapView.onPause()
                Lifecycle.Event.ON_STOP -> mapView.onStop()
                else -> Unit
            }
        }
        lifecycle.addObserver(observer)
        if (lifecycle.currentState.isAtLeast(Lifecycle.State.STARTED)) mapView.onStart()
        if (lifecycle.currentState.isAtLeast(Lifecycle.State.RESUMED)) mapView.onResume()
        onDispose {
            lifecycle.removeObserver(observer)
            mapView.onPause()
            mapView.onStop()
            mapView.onDestroy()
        }
    }
    return mapView
}

private fun MapLibreMap.simplify() {
    uiSettings.setRotateGesturesEnabled(false)
    uiSettings.setTiltGesturesEnabled(false)
    uiSettings.setCompassEnabled(false)
    uiSettings.setLogoEnabled(false)
    uiSettings.setAttributionEnabled(true)
}

/** Mappa dei locali: pallini colorati come i badge (✓ verde, ! ambra, ✕ rosso, grigio). */
@Composable
fun RestaurantMap(
    restaurants: List<Restaurant>,
    now: Instant,
    center: GeoPoint,
    onRestaurantClick: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    val mapView = rememberMapView()
    val onClick by rememberUpdatedState(onRestaurantClick)
    var map by remember { mutableStateOf<MapLibreMap?>(null) }

    AndroidView(
        factory = {
            mapView.also { view ->
                view.getMapAsync { mapLibreMap ->
                    mapLibreMap.simplify()
                    mapLibreMap.moveCamera(
                        CameraUpdateFactory.newLatLngZoom(LatLng(center.latitude, center.longitude), 12.5),
                    )
                    mapLibreMap.setStyle(FreeMaps.STYLE_URL) { style ->
                        style.addSource(GeoJsonSource(SOURCE_ID, geoJson(restaurants, now)))
                        style.addLayer(
                            CircleLayer(LAYER_ID, SOURCE_ID).withProperties(
                                PropertyFactory.circleColor(Expression.get("color")),
                                PropertyFactory.circleRadius(Expression.get("radius")),
                                PropertyFactory.circleStrokeWidth(2.5f),
                                PropertyFactory.circleStrokeColor(Color.WHITE),
                            ),
                        )
                        mapLibreMap.addOnMapClickListener { latLng ->
                            val point = mapLibreMap.projection.toScreenLocation(latLng)
                            val id = mapLibreMap.queryRenderedFeatures(point, LAYER_ID)
                                .firstOrNull()
                                ?.getStringProperty("id")
                            if (id != null) onClick(id)
                            id != null
                        }
                        map = mapLibreMap
                    }
                }
            }
        },
        modifier = modifier,
    )

    LaunchedEffect(map, restaurants, now) {
        map?.style?.getSourceAs<GeoJsonSource>(SOURCE_ID)?.setGeoJson(geoJson(restaurants, now))
    }
    LaunchedEffect(map, center) {
        map?.animateCamera(CameraUpdateFactory.newLatLngZoom(LatLng(center.latitude, center.longitude), 12.5))
    }
}

/**
 * Scelta della posizione di un locale nuovo: si sposta la mappa finché il segnaposto al centro è
 * sopra il locale. [onCenterChanged] riceve la posizione quando la mappa si ferma.
 */
@Composable
fun LocationPickerMap(
    initial: GeoPoint,
    onCenterChanged: (GeoPoint) -> Unit,
    modifier: Modifier = Modifier,
) {
    val mapView = rememberMapView()
    val onChanged by rememberUpdatedState(onCenterChanged)
    Box(modifier = modifier) {
        AndroidView(
            factory = {
                mapView.also { view ->
                    view.getMapAsync { mapLibreMap ->
                        mapLibreMap.simplify()
                        mapLibreMap.moveCamera(
                            CameraUpdateFactory.newLatLngZoom(LatLng(initial.latitude, initial.longitude), 16.0),
                        )
                        mapLibreMap.setStyle(FreeMaps.STYLE_URL)
                        mapLibreMap.addOnCameraIdleListener {
                            mapLibreMap.cameraPosition.target?.let { target ->
                                onChanged(GeoPoint(latitude = target.latitude, longitude = target.longitude))
                            }
                        }
                    }
                }
            },
            modifier = Modifier.fillMaxSize(),
        )
        Text(
            text = "📍",
            style = MaterialTheme.typography.headlineLarge,
            modifier = Modifier.align(Alignment.Center),
        )
    }
}

private const val SOURCE_ID = "haposto-restaurants"
private const val LAYER_ID = "haposto-restaurants-dots"

private fun geoJson(restaurants: List<Restaurant>, now: Instant): String = buildJsonObject {
    put("type", "FeatureCollection")
    putJsonArray("features") {
        restaurants.forEach { restaurant ->
            val status = AvailabilityResolver.resolve(restaurant, now).status
            add(
                buildJsonObject {
                    put("type", "Feature")
                    putJsonObject("geometry") {
                        put("type", "Point")
                        put(
                            "coordinates",
                            buildJsonArray {
                                add(restaurant.location.longitude)
                                add(restaurant.location.latitude)
                            },
                        )
                    }
                    putJsonObject("properties") {
                        put("id", restaurant.id)
                        put("color", FreeMaps.colorFor(status))
                        // I locali con posto sono più grandi: si vedono anche senza distinguere i colori.
                        put(
                            "radius",
                            when (status) {
                                AvailabilityStatus.AVAILABLE -> 11
                                AvailabilityStatus.LIMITED -> 9
                                AvailabilityStatus.FULL -> 8
                                else -> 6
                            },
                        )
                    }
                },
            )
        }
    }
}.toString()
