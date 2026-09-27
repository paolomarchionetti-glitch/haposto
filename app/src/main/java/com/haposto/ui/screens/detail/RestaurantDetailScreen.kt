package com.haposto.ui.screens.detail

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.haposto.domain.model.AvailabilityStatus
import com.haposto.domain.model.DistanceOrigin
import com.haposto.domain.model.DistanceOriginType
import com.haposto.domain.model.Restaurant
import com.haposto.domain.usecase.AvailabilityResolver
import com.haposto.ui.components.AdaptiveScrollableContent
import com.haposto.ui.components.AvailabilityBadge
import com.haposto.ui.components.formatDistance
import com.haposto.ui.util.ExternalActions
import java.time.Instant
import kotlinx.coroutines.delay

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RestaurantDetailScreen(
    restaurant: Restaurant,
    distanceOrigin: DistanceOrigin,
    isSupabaseBacked: Boolean = false,
    onBack: () -> Unit,
) {
    val context = LocalContext.current
    val now by produceState(initialValue = Instant.now(), key1 = restaurant.id) {
        while (true) {
            value = Instant.now()
            delay(15_000)
        }
    }
    val effective = AvailabilityResolver.resolve(restaurant, now)
    var actionError by rememberSaveable(restaurant.id) { mutableStateOf<String?>(null) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Dettaglio") },
                navigationIcon = {
                    TextButton(onClick = onBack) {
                        Text("Indietro")
                    }
                },
            )
        },
    ) { innerPadding ->
        AdaptiveScrollableContent(
            innerPadding = innerPadding,
            verticalPadding = 12.dp,
            verticalArrangement = Arrangement.spacedBy(18.dp),
        ) {
            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(
                    text = restaurant.name,
                    style = MaterialTheme.typography.headlineMedium,
                    fontWeight = FontWeight.Black,
                )
                Text(
                    text = restaurant.category,
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }

            Surface(
                modifier = Modifier.fillMaxWidth(),
                color = MaterialTheme.colorScheme.surface,
                shape = MaterialTheme.shapes.large,
                border = androidx.compose.foundation.BorderStroke(
                    width = 1.dp,
                    color = MaterialTheme.colorScheme.outline,
                ),
            ) {
                Column(
                    modifier = Modifier.padding(20.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    Text(
                        text = "Disponibilità adesso",
                        style = MaterialTheme.typography.labelLarge,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                    AvailabilityBadge(status = effective.status)
                    Text(
                        text = AvailabilityResolver.relativeUpdateLabel(effective, now),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )

                    if (effective.status in setOf(
                            AvailabilityStatus.AVAILABLE,
                            AvailabilityStatus.LIMITED,
                            AvailabilityStatus.FULL,
                        )
                    ) {
                        effective.availableTables?.let { tables ->
                            Text(
                                text = if (tables == 1) "1 tavolo indicato libero" else "$tables tavoli indicati liberi",
                                style = MaterialTheme.typography.bodyMedium,
                            )
                        }
                        effective.estimatedWaitMinutes?.let { wait ->
                            Text(
                                text = "Attesa indicativa: $wait min",
                                style = MaterialTheme.typography.bodyMedium,
                            )
                        }
                        effective.note?.takeIf(String::isNotBlank)?.let { note ->
                            Text(
                                text = note,
                                style = MaterialTheme.typography.bodyMedium,
                                fontWeight = FontWeight.Medium,
                            )
                        }

                        HorizontalDivider()
                        Text(
                            text = "Lo stato è un'indicazione recente comunicata dal locale e non costituisce una prenotazione.",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                }
            }

            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text(
                    text = "Dove si trova",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                )
                Text(
                    text = restaurant.address,
                    style = MaterialTheme.typography.bodyLarge,
                )
                Text(
                    text = distanceDescription(restaurant.distanceKm, distanceOrigin),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }

            Button(
                onClick = {
                    actionError = if (ExternalActions.openDirections(context, restaurant)) null
                    else "Nessuna app disponibile per aprire le indicazioni."
                },
                modifier = Modifier.fillMaxWidth(),
            ) {
                Text("INDICAZIONI")
            }

            val publicPhone = restaurant.phoneNumber?.takeIf { restaurant.phonePublic && it.isNotBlank() }
            if (publicPhone != null) {
                OutlinedButton(
                    onClick = {
                        actionError = if (ExternalActions.openDialer(context, publicPhone)) null
                        else "Nessuna app disponibile per aprire il dialer."
                    },
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Text("CHIAMA")
                }
            }

            actionError?.let { message ->
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    color = MaterialTheme.colorScheme.errorContainer,
                    contentColor = MaterialTheme.colorScheme.onErrorContainer,
                    shape = MaterialTheme.shapes.medium,
                ) {
                    Text(
                        text = message,
                        modifier = Modifier.padding(14.dp),
                        style = MaterialTheme.typography.bodyMedium,
                    )
                }
            }

            Text(
                text = if (isSupabaseBacked) {
                    "Scheda letta dal backend Supabase DEV. Il seed incluso contiene esclusivamente attività fittizie di test."
                } else {
                    "Scheda dimostrativa locale. Attività, indirizzi, coordinate e disponibilità sono dati fittizi."
                },
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Spacer(Modifier.height(12.dp))
        }
    }
}


private fun distanceDescription(
    distanceKm: Double?,
    origin: DistanceOrigin,
): String {
    val prefix = formatDistance(distanceKm)
    return when (origin.type) {
        DistanceOriginType.DEVICE -> {
            val precision = if (origin.isPrecise == true) "posizione dispositivo" else "posizione approssimativa"
            "$prefix dalla $precision"
        }
        DistanceOriginType.MANUAL_AREA -> "$prefix da ${origin.label}"
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RestaurantNotFoundScreen(onBack: () -> Unit) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Ristorante") },
                navigationIcon = {
                    TextButton(onClick = onBack) { Text("Indietro") }
                },
            )
        },
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(24.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Text(
                text = "Ristorante non trovato",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
            )
            Text(
                text = "Il record demo non è disponibile.",
                style = MaterialTheme.typography.bodyLarge,
            )
        }
    }
}
