package com.haposto.ui.screens.detail

import androidx.compose.runtime.Composable
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.haposto.data.location.LocationSession
import com.haposto.data.repository.RestaurantDataSource
import com.haposto.data.repository.RestaurantRepository
import com.haposto.data.repository.RestaurantRepositoryMetadata
import com.haposto.domain.usecase.RestaurantDistance

@Composable
fun RestaurantDetailRoute(
    restaurantId: String,
    repository: RestaurantRepository,
    locationSession: LocationSession,
    onBack: () -> Unit,
) {
    // Observe the repository so a manager update remains consistent everywhere in the app.
    val restaurants = repository.observeRestaurants()
        .collectAsStateWithLifecycle(
            initialValue = repository.findById(restaurantId)?.let(::listOf) ?: emptyList(),
        )
        .value
    val restaurant = restaurants.firstOrNull { it.id == restaurantId }
    val origin = locationSession.origin.collectAsStateWithLifecycle().value

    if (restaurant == null) {
        RestaurantNotFoundScreen(onBack = onBack)
    } else {
        RestaurantDetailScreen(
            restaurant = RestaurantDistance.attach(restaurant, origin.point),
            distanceOrigin = origin,
            isSupabaseBacked = (repository as? RestaurantRepositoryMetadata)?.dataSource == RestaurantDataSource.SUPABASE,
            onBack = onBack,
        )
    }
}
