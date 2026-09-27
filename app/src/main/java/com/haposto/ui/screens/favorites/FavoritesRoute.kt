package com.haposto.ui.screens.favorites

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.haposto.data.favorites.FavoritesStore
import com.haposto.data.location.LocationSession
import com.haposto.data.repository.RestaurantRepository
import com.haposto.domain.model.Restaurant
import com.haposto.domain.usecase.RestaurantDistance
import com.haposto.ui.components.AppStatePanel
import com.haposto.ui.components.RestaurantCard
import java.time.Instant
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.catch

/**
 * Preferiti salvati sul telefono (gratis, senza account), con lo stato live aggiornato.
 * Gli avvisi "c'è posto" sui preferiti sono la funzione di punta di HAPOSTO Plus.
 */
@Composable
fun FavoritesRoute(
    repository: RestaurantRepository,
    locationSession: LocationSession,
    favorites: FavoritesStore,
    onRestaurantClick: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    val favoriteIds by favorites.ids.collectAsStateWithLifecycle()
    val directoryFlow = remember(repository) {
        repository.observeRestaurants().catch { emit(emptyList()) }
    }
    val directory by directoryFlow.collectAsStateWithLifecycle(initialValue = emptyList())
    val origin by locationSession.origin.collectAsStateWithLifecycle()
    val now by produceState(initialValue = Instant.now()) {
        while (true) {
            value = Instant.now()
            delay(15_000)
        }
    }

    val saved = RestaurantDistance.attach(directory.filter { it.id in favoriteIds }, origin.point)
        .sortedBy { it.distanceKm ?: Double.MAX_VALUE }

    FavoritesScreen(
        favorites = saved,
        notInAreaCount = (favoriteIds.size - saved.size).coerceAtLeast(0),
        now = now,
        onRestaurantClick = onRestaurantClick,
        modifier = modifier,
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FavoritesScreen(
    favorites: List<Restaurant>,
    notInAreaCount: Int,
    now: Instant,
    onRestaurantClick: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    Scaffold(
        modifier = modifier,
        topBar = {
            TopAppBar(title = { Text("Preferiti", fontWeight = FontWeight.Bold) })
        },
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            if (favorites.isEmpty()) {
                item {
                    AppStatePanel(
                        title = "Nessun preferito ancora",
                        body = "Apri un locale e tocca «☆ Salva nei preferiti»: lo ritrovi qui con il suo stato live.",
                    )
                }
            } else {
                items(items = favorites, key = { it.id }) { restaurant ->
                    RestaurantCard(
                        restaurant = restaurant,
                        now = now,
                        onClick = { onRestaurantClick(restaurant.id) },
                    )
                }
            }

            if (notInAreaCount > 0) {
                item {
                    Text(
                        text = if (notInAreaCount == 1) {
                            "1 preferito è fuori dalla zona che stai guardando."
                        } else {
                            "$notInAreaCount preferiti sono fuori dalla zona che stai guardando."
                        },
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }

            item { PlusTeaser() }
        }
    }
}

@Composable
private fun PlusTeaser() {
    Surface(
        color = MaterialTheme.colorScheme.secondaryContainer,
        contentColor = MaterialTheme.colorScheme.onSecondaryContainer,
        shape = MaterialTheme.shapes.large,
        modifier = Modifier.fillMaxWidth(),
    ) {
        Column(
            modifier = Modifier.padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Text("HAPOSTO Plus · in arrivo", style = MaterialTheme.typography.labelLarge, fontWeight = FontWeight.Bold)
            Text(
                "Avvisami quando si libera un tavolo: ricevi una notifica appena un tuo preferito segna “C'è posto”.",
                style = MaterialTheme.typography.bodyMedium,
            )
            Text(
                "I preferiti sul telefono restano gratis, senza account.",
                style = MaterialTheme.typography.bodySmall,
            )
        }
    }
}
