package com.haposto.ui.screens.home

import androidx.compose.foundation.background
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.runtime.saveable.rememberSaveable
import com.haposto.R
import com.haposto.config.AppConfig
import com.haposto.platform.map.RestaurantMap
import com.haposto.domain.model.AvailabilityStatus
import com.haposto.domain.model.DistanceOrigin
import com.haposto.domain.model.DistanceOriginType
import com.haposto.domain.model.ManualArea
import com.haposto.domain.model.RestaurantFilter
import com.haposto.domain.usecase.AvailabilityResolver
import com.haposto.ui.components.AppStatePanel
import com.haposto.ui.components.BigActionButton
import com.haposto.ui.components.InfoDisclosure
import com.haposto.ui.components.OfflineBanner
import com.haposto.ui.components.RestaurantCard
import com.haposto.ui.theme.BrandInk
import com.haposto.ui.theme.BrandInkDark
import com.haposto.ui.theme.WarmSurface
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    uiState: HomeUiState,
    onSearchQueryChange: (String) -> Unit,
    onFilterSelected: (RestaurantFilter) -> Unit,
    onManualAreaSelected: (ManualArea) -> Unit,
    onUseDeviceLocation: () -> Unit,
    onConfirmLocationRationale: () -> Unit,
    onOpenAppSettings: () -> Unit,
    onRetry: () -> Unit = {},
    onRestaurantClick: (String) -> Unit,
    onRestaurantAreaClick: () -> Unit,
) {
    var showMap by rememberSaveable { mutableStateOf(false) }
    Scaffold { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding),
        ) {
            HomeHeroHeader(isSupabaseBacked = uiState.isSupabaseBacked)

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                FilterChip(selected = !showMap, onClick = { showMap = false }, label = { Text("☰  Lista") })
                FilterChip(selected = showMap, onClick = { showMap = true }, label = { Text("🗺  Mappa") })
            }

            if (showMap) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .weight(1f),
                ) {
                    RestaurantMap(
                        restaurants = uiState.restaurants,
                        now = uiState.now,
                        center = uiState.distanceOrigin.point,
                        onRestaurantClick = onRestaurantClick,
                        modifier = Modifier
                            .fillMaxWidth()
                            .weight(1f),
                    )
                    Text(
                        text = "● verde c'è posto · ● ambra pochi posti · ● rosso completo · ● grigio da aggiornare. Tocca un pallino per aprire il locale.",
                        style = MaterialTheme.typography.bodySmall,
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                    )
                }
                return@Column
            }

            BoxWithConstraints(
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f),
                contentAlignment = Alignment.TopCenter,
            ) {
            val contentMaxWidth = if (maxWidth >= 840.dp) 960.dp else maxWidth

            LazyColumn(
                modifier = Modifier
                    .widthIn(max = contentMaxWidth)
                    .fillMaxSize(),
                state = rememberLazyListState(),
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 12.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                item {
                    HomeControls(
                        uiState = uiState,
                        onSearchQueryChange = onSearchQueryChange,
                        onFilterSelected = onFilterSelected,
                        onManualAreaSelected = onManualAreaSelected,
                        onUseDeviceLocation = onUseDeviceLocation,
                        onConfirmLocationRationale = onConfirmLocationRationale,
                        onOpenAppSettings = onOpenAppSettings,
                    )
                }

                if (!uiState.isOnline) {
                    item { OfflineBanner() }
                }

                when {
                    uiState.isInitialLoading && uiState.restaurants.isEmpty() -> {
                        item {
                            AppStatePanel(
                                title = "Caricamento ristoranti",
                                body = "Preparo la directory locale e gli stati di disponibilità.",
                                showProgress = true,
                            )
                        }
                    }
                    uiState.errorMessage != null && uiState.restaurants.isEmpty() -> {
                        item {
                            AppStatePanel(
                                title = "Non riesco a caricare i ristoranti",
                                body = uiState.errorMessage,
                                actionLabel = "Riprova",
                                onAction = onRetry,
                                isError = true,
                            )
                        }
                    }
                    !uiState.hasResults -> {
                        item { EmptyResults(uiState.emptyReason) }
                    }
                    else -> {
                        items(items = uiState.restaurants, key = { it.id }) { restaurant ->
                            RestaurantCard(
                                restaurant = restaurant,
                                now = uiState.now,
                                onClick = { onRestaurantClick(restaurant.id) },
                            )
                        }
                    }
                }

                item {
                    Spacer(Modifier.height(4.dp))
                    InfoDisclosure(
                        label = "Come funziona HAPOSTO",
                        text = "Gli stati sono dichiarati dai locali e scadono dopo 30 minuti: non è una prenotazione, la disponibilità può cambiare. " +
                            when {
                                !uiState.isSupabaseBacked -> "Dati dimostrativi locali."
                                AppConfig.environment.badge != null -> "Versione DEV: locali di prova con dati fittizi."
                                else -> "Elenco dei locali: dati dei locali e © OpenStreetMap contributors."
                            },
                    )
                    Spacer(Modifier.height(8.dp))
                }
            }
            }
        }
    }
}

@Composable
private fun HomeHeroHeader(isSupabaseBacked: Boolean) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(bottomStart = 24.dp, bottomEnd = 24.dp))
            .background(Brush.verticalGradient(listOf(BrandInk, BrandInkDark)))
            .padding(horizontal = 20.dp, vertical = 22.dp),
    ) {
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = "HAPOSTO",
                    style = MaterialTheme.typography.headlineMedium,
                    fontWeight = FontWeight.Black,
                    color = WarmSurface,
                    modifier = Modifier.weight(1f),
                )
                // DEMO e DEV hanno un'etichetta ben visibile; la versione PROD nessuna.
                val badge = AppConfig.environment.badge ?: if (!isSupabaseBacked) "DEMO" else null
                if (badge != null) {
                    Surface(
                        color = WarmSurface.copy(alpha = 0.16f),
                        contentColor = WarmSurface,
                        shape = MaterialTheme.shapes.small,
                    ) {
                        Text(
                            text = badge,
                            modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                            style = MaterialTheme.typography.labelMedium,
                            fontWeight = FontWeight.Bold,
                        )
                    }
                }
            }
            Text(
                text = stringResource(R.string.app_tagline),
                style = MaterialTheme.typography.labelLarge,
                color = WarmSurface.copy(alpha = 0.78f),
            )
        }
    }
}

@Composable
private fun HomeControls(
    uiState: HomeUiState,
    onSearchQueryChange: (String) -> Unit,
    onFilterSelected: (RestaurantFilter) -> Unit,
    onManualAreaSelected: (ManualArea) -> Unit,
    onUseDeviceLocation: () -> Unit,
    onConfirmLocationRationale: () -> Unit,
    onOpenAppSettings: () -> Unit,
) {
    var locationExpanded by remember { mutableStateOf(false) }

    val liveCount = remember(uiState.restaurants, uiState.now) {
        uiState.restaurants.count {
            AvailabilityResolver.resolve(it, uiState.now).status in
                setOf(AvailabilityStatus.AVAILABLE, AvailabilityStatus.LIMITED)
        }
    }

    Column(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text(
            text = "Dove vuoi mangiare?",
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.semantics { heading() },
        )

        // Riga di sintesi "in crescita"
        val summary = if (uiState.hasResults) {
            "$liveCount con posto ora · ${uiState.restaurants.size} nella zona"
        } else {
            "Nessun locale in questa zona per ora"
        }
        Text(
            text = summary,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.secondary,
            fontWeight = FontWeight.SemiBold,
        )

        // Toggle rapido "Solo con posto" — tasto grande
        val onlyAvailable = uiState.selectedFilter == RestaurantFilter.AVAILABLE
        BigActionButton(
            text = if (onlyAvailable) "Mostro solo dove c'è posto ✓" else "Mostra solo dove c'è posto",
            onClick = {
                onFilterSelected(if (onlyAvailable) RestaurantFilter.ALL else RestaurantFilter.AVAILABLE)
            },
            container = if (onlyAvailable) MaterialTheme.colorScheme.secondary else MaterialTheme.colorScheme.primary,
            content = if (onlyAvailable) MaterialTheme.colorScheme.onSecondary else MaterialTheme.colorScheme.onPrimary,
        )

        // Posizione compatta e collassabile
        Surface(
            modifier = Modifier.fillMaxWidth(),
            color = MaterialTheme.colorScheme.surfaceVariant,
            shape = MaterialTheme.shapes.medium,
        ) {
            Column(Modifier.padding(horizontal = 14.dp, vertical = 10.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = "📍 ${uiState.distanceOrigin.label}",
                        style = MaterialTheme.typography.labelLarge,
                        fontWeight = FontWeight.SemiBold,
                        modifier = Modifier.weight(1f),
                    )
                    TextButton(onClick = { locationExpanded = !locationExpanded }) {
                        Text(if (locationExpanded) "Chiudi" else "Cambia")
                    }
                }
                if (locationExpanded) {
                    LocationPanel(
                        origin = uiState.distanceOrigin,
                        isLocating = uiState.isLocating,
                        notice = uiState.locationNotice,
                        onUseDeviceLocation = onUseDeviceLocation,
                        onConfirmLocationRationale = onConfirmLocationRationale,
                        onOpenAppSettings = onOpenAppSettings,
                        onManualAreaSelected = onManualAreaSelected,
                        isSupabaseBacked = uiState.isSupabaseBacked,
                    )
                }
            }
        }

        OutlinedTextField(
            value = uiState.searchQuery,
            onValueChange = onSearchQueryChange,
            modifier = Modifier.fillMaxWidth(),
            singleLine = true,
            label = { Text("Cerca ristorante o cucina") },
            placeholder = { Text("Es. pizza") },
        )

        Row(
            modifier = Modifier
                .fillMaxWidth()
                .horizontalScroll(rememberScrollState()),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            RestaurantFilter.entries.forEach { filter ->
                FilterChip(
                    selected = uiState.selectedFilter == filter,
                    onClick = { onFilterSelected(filter) },
                    label = { Text(filter.label) },
                )
            }
        }
    }
}

@Composable
private fun LocationPanel(
    origin: DistanceOrigin,
    isLocating: Boolean,
    notice: LocationNotice?,
    onUseDeviceLocation: () -> Unit,
    onConfirmLocationRationale: () -> Unit,
    onOpenAppSettings: () -> Unit,
    onManualAreaSelected: (ManualArea) -> Unit,
    isSupabaseBacked: Boolean,
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 10.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        if (origin.type == DistanceOriginType.DEVICE) {
            val precisionText = if (origin.isPrecise == true) {
                "posizione precisa consentita"
            } else {
                "posizione approssimativa consentita"
            }
            val accuracyText = origin.accuracyMeters?.let {
                " · accuratezza ~${formatAccuracy(it)}"
            }.orEmpty()
            Text(
                text = precisionText + accuracyText,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        } else {
            Text(
                text = "Riferimento manuale: nessun dato di posizione personale viene usato.",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }

        if (isLocating) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(10.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                CircularProgressIndicator()
                Text("Cerco la posizione del dispositivo…")
            }
        } else {
            Button(onClick = onUseDeviceLocation, modifier = Modifier.fillMaxWidth()) {
                Text(
                    if (origin.type == DistanceOriginType.DEVICE) "Aggiorna la mia posizione"
                    else "Usa la mia posizione",
                )
            }
        }

        LocationNoticeContent(
            notice = notice,
            onConfirmLocationRationale = onConfirmLocationRationale,
            onOpenAppSettings = onOpenAppSettings,
        )

        Text(
            text = "Oppure scegli un'area",
            style = MaterialTheme.typography.labelLarge,
            fontWeight = FontWeight.SemiBold,
        )
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .horizontalScroll(rememberScrollState()),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            ManualArea.entries.forEach { area ->
                val selected = origin.type == DistanceOriginType.MANUAL_AREA &&
                    origin.label == area.label
                FilterChip(
                    selected = selected,
                    onClick = { onManualAreaSelected(area) },
                    label = { Text(area.label.substringBefore(" centro")) },
                )
            }
        }

        Text(
            text = if (isSupabaseBacked) {
                "La posizione resta sul telefono; viene inviata solo alla funzione geo Supabase per questa ricerca e non salvata nelle tabelle HAPOSTO."
            } else {
                "La posizione resta solo in memoria: non viene salvata o ripristinata dopo la chiusura."
            },
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

@Composable
private fun LocationNoticeContent(
    notice: LocationNotice?,
    onConfirmLocationRationale: () -> Unit,
    onOpenAppSettings: () -> Unit,
) {
    when (notice) {
        LocationNotice.RATIONALE_REQUIRED -> AppStatePanel(
            title = "Perché chiediamo la posizione",
            body = "Serve solo per ordinare i ristoranti per distanza. Puoi concedere anche la posizione approssimativa e puoi continuare scegliendo una città manualmente.",
            actionLabel = "Continua",
            onAction = onConfirmLocationRationale,
        )
        LocationNotice.PERMISSION_DENIED -> Text(
            text = "Permesso non concesso. Puoi continuare usando una delle aree manuali.",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.error,
        )
        LocationNotice.PERMISSION_DENIED_PERMANENT -> AppStatePanel(
            title = "Posizione non autorizzata",
            body = "Android non può mostrare di nuovo automaticamente la richiesta. Puoi abilitarla dalle impostazioni dell'app oppure continuare con una città manuale.",
            actionLabel = "Apri impostazioni app",
            onAction = onOpenAppSettings,
            isError = true,
        )
        LocationNotice.SERVICES_DISABLED -> Text(
            text = "Servizi di localizzazione disattivati. Resta attivo il riferimento manuale.",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.error,
        )
        LocationNotice.UNAVAILABLE -> Text(
            text = "Non è stato possibile ottenere una posizione recente. Resta attivo il riferimento manuale.",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.error,
        )
        null -> Unit
    }
}

private fun formatAccuracy(accuracyMeters: Float): String = when {
    accuracyMeters < 1000f -> "${accuracyMeters.toInt()} m"
    else -> String.format(Locale.ITALY, "%.1f km", accuracyMeters / 1000f)
}

@Composable
private fun EmptyResults(reason: HomeEmptyReason?) {
    val title: String
    val body: String
    when (reason) {
        HomeEmptyReason.DIRECTORY_EMPTY -> {
            title = "Directory ancora vuota"
            body = "Non ci sono ristoranti nella sorgente corrente. Durante il pilot mostreremo quanti locali sono LIVE e quanti solo in directory."
        }
        HomeEmptyReason.NO_MATCHES, null -> {
            title = "Nessun risultato"
            body = "Prova a cambiare ricerca, filtro oppure area di riferimento."
        }
    }
    AppStatePanel(title = title, body = body)
}
