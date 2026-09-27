package com.haposto.ui.screens.detail

import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.haposto.data.favorites.FavoritesStore
import com.haposto.data.location.LocationSession
import com.haposto.data.repository.RestaurantDataSource
import com.haposto.data.repository.RestaurantRepository
import com.haposto.data.repository.RestaurantRepositoryMetadata
import com.haposto.domain.usecase.RestaurantDistance
import kotlinx.coroutines.flow.catch

@Composable
fun RestaurantDetailRoute(
    restaurantId: String,
    repository: RestaurantRepository,
    locationSession: LocationSession,
    favorites: FavoritesStore,
    onBack: () -> Unit,
) {
    // Observe the repository so a manager update remains consistent everywhere in the app.
    // The flow is remembered: a new instance on every recomposition would restart the collection
    // (and, with Supabase, a new RPC call). A backend error falls back to the last known record.
    val restaurantsFlow = remember(repository, restaurantId) {
        repository.observeRestaurants()
            .catch { emit(listOfNotNull(repository.findById(restaurantId))) }
    }
    val restaurants = restaurantsFlow
        .collectAsStateWithLifecycle(
            initialValue = repository.findById(restaurantId)?.let(::listOf) ?: emptyList(),
        )
        .value
    val restaurant = restaurants.firstOrNull { it.id == restaurantId }
    val origin = locationSession.origin.collectAsStateWithLifecycle().value
    val favoriteIds = favorites.ids.collectAsStateWithLifecycle().value

    if (restaurant == null) {
        RestaurantNotFoundScreen(onBack = onBack)
    } else {
        RestaurantDetailScreen(
            restaurant = RestaurantDistance.attach(restaurant, origin.point),
            distanceOrigin = origin,
            isSupabaseBacked = (repository as? RestaurantRepositoryMetadata)?.dataSource == RestaurantDataSource.SUPABASE,
            isFavorite = restaurant.id in favoriteIds,
            onToggleFavorite = { favorites.toggle(restaurant.id) },
            onBack = onBack,
        )
    }
}
