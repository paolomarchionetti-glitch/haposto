package com.haposto.ui.screens.detail

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.haposto.config.AppConfig
import com.haposto.data.Outcome
import com.haposto.data.auth.AuthRepository
import com.haposto.data.auth.AuthState
import com.haposto.data.consumer.ConsumerEntitlements
import com.haposto.data.consumer.ConsumerRepository
import com.haposto.data.consumer.PatternCell
import com.haposto.data.consumer.PublicDetails
import com.haposto.data.consumer.RestaurantEvent
import com.haposto.data.favorites.FavoritesStore
import com.haposto.data.location.LocationSession
import com.haposto.data.repository.RestaurantDataSource
import com.haposto.data.repository.RestaurantRepository
import com.haposto.data.repository.RestaurantRepositoryMetadata
import com.haposto.domain.usecase.RestaurantDistance
import com.haposto.platform.notifications.HaPostoNotifications
import java.time.LocalDate
import java.time.ZoneId
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.launch

@Composable
fun RestaurantDetailRoute(
    restaurantId: String,
    repository: RestaurantRepository,
    locationSession: LocationSession,
    favorites: FavoritesStore,
    onBack: () -> Unit,
    consumer: ConsumerRepository? = null,
    auth: AuthRepository? = null,
    onOpenPlus: () -> Unit = {},
    onOpenAccount: () -> Unit = {},
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

    val extras = if (consumer != null && auth != null && consumer.isAvailable) {
        rememberDetailExtras(restaurantId, consumer, auth, onOpenPlus, onOpenAccount)
    } else {
        null
    }

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
            extras = extras,
        )
    }
}

@Composable
private fun rememberDetailExtras(
    restaurantId: String,
    consumer: ConsumerRepository,
    auth: AuthRepository,
    onOpenPlus: () -> Unit,
    onOpenAccount: () -> Unit,
): DetailExtras {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val authState = auth.state.collectAsStateWithLifecycle().value
    val userId = (authState as? AuthState.SignedIn)?.user?.id

    LaunchedEffect(restaurantId) { consumer.trackEvent(restaurantId, RestaurantEvent.DETAIL_VIEW) }

    val details by produceState(PublicDetails(null, null), restaurantId) {
        value = consumer.publicDetails(restaurantId).valueOrNull ?: PublicDetails(null, null)
    }
    val entitlements by produceState(ConsumerEntitlements.FREE, userId) {
        value = consumer.entitlements().valueOrNull ?: ConsumerEntitlements.FREE
    }
    var alertActive by remember(restaurantId, userId) { mutableStateOf(false) }
    var busy by remember { mutableStateOf(false) }
    var message by remember(restaurantId) { mutableStateOf<String?>(null) }
    LaunchedEffect(restaurantId, userId) {
        alertActive = userId != null && restaurantId in consumer.activeAlerts().valueOrNull.orEmpty()
    }
    val pattern by produceState(emptyList<PatternCell>(), restaurantId, entitlements.isPlus) {
        value = if (entitlements.has("AVAILABILITY_HISTORY")) consumer.availabilityPattern(restaurantId).valueOrNull.orEmpty() else emptyList()
    }

    return DetailExtras(
        openingHours = details.openingHours,
        shareUrl = details.slug?.let(AppConfig::publicRestaurantUrl),
        isPlus = entitlements.isPlus,
        alertActive = alertActive,
        alertBusy = busy,
        onAlertToggle = {
            when {
                userId == null -> onOpenAccount()
                !entitlements.has("AVAILABILITY_ALERTS") -> onOpenPlus()
                else -> scope.launch {
                    busy = true
                    val result = if (alertActive) consumer.cancelAlert(restaurantId) else consumer.createAlert(restaurantId, includeLimited = false)
                    busy = false
                    when (result) {
                        is Outcome.Success -> {
                            alertActive = !alertActive
                            message = if (alertActive) {
                                if (HaPostoNotifications.canPost(context)) {
                                    "✓ Ti avvisiamo appena segnala posti liberi (per le prossime 6 ore)."
                                } else {
                                    "Avviso attivo, ma le notifiche sono spente: attivale in Account → Notifiche."
                                }
                            } else {
                                "Avviso annullato."
                            }
                        }
                        is Outcome.Failure -> message = result.message
                    }
                }
            }
        },
        patternLines = patternForToday(pattern),
        message = message,
        onTrack = { event -> scope.launch { consumer.trackEvent(restaurantId, event) } },
        websiteUrl = details.websiteUrl,
        menuUrl = details.menuUrl,
        fileUrl = details.fileUrl,
        fileLabel = when {
            details.fileTodayOnly -> "📄 Menù del giorno"
            details.fileIsPdf -> "📄 Menù (PDF)"
            else -> "🖼 Foto del menù"
        },
    )
}

/** "20:00 · spesso completo" per le ore di oggi con abbastanza dati. */
private fun patternForToday(cells: List<PatternCell>): List<String> {
    val today = LocalDate.now(ZoneId.of("Europe/Rome")).dayOfWeek.value
    return cells.filter { it.weekday == today && it.hour in 11..23 }
        .sortedBy { it.hour }
        .map { cell ->
            val label = when {
                cell.fullShare >= 0.5 -> "✕ spesso completo"
                cell.fullShare + cell.limitedShare >= 0.5 -> "! spesso pochi posti"
                else -> "✓ di solito c'è posto"
            }
            "%02d:00 · %s".format(cell.hour, label)
        }
}
