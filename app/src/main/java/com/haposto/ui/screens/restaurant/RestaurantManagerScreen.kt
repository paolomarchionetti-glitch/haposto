package com.haposto.ui.screens.restaurant

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.haposto.domain.model.AvailabilityStatus
import com.haposto.domain.usecase.AvailabilityResolver
import com.haposto.ui.components.AdaptiveScrollableContent
import com.haposto.ui.components.AvailabilityBadge
import com.haposto.ui.components.InfoDisclosure
import com.haposto.ui.components.OfflineBanner
import com.haposto.ui.components.statusPresentation
import java.time.Duration

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RestaurantManagerScreen(
    uiState: RestaurantManagerUiState,
    isOnline: Boolean = true,
    onBack: () -> Unit,
    onStatusSelected: (AvailabilityStatus) -> Unit,
    onDecrementTables: () -> Unit,
    onIncrementTables: () -> Unit,
    onWaitSelected: (Int?) -> Unit,
    onNoteChange: (String) -> Unit,
    onRefreshCurrentStatus: () -> Unit,
    onPhonePublicChange: (Boolean) -> Unit,
    onOpenReservations: () -> Unit = {},
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Area ristoratore", fontWeight = FontWeight.Bold) },
                navigationIcon = { TextButton(onClick = onBack) { Text("Indietro") } },
            )
        },
    ) { innerPadding ->
        val restaurant = uiState.restaurant
        if (restaurant == null) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding)
                    .padding(24.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                Text("Ristorante non disponibile", style = MaterialTheme.typography.headlineSmall)
                Text("Il record assegnato alla dashboard non è presente.")
            }
            return@Scaffold
        }

        AdaptiveScrollableContent(
            innerPadding = innerPadding,
            horizontalPadding = 18.dp,
            verticalPadding = 12.dp,
        ) {
            // Intestazione minimale
            Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text(
                    text = restaurant.name,
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Black,
                )
                Text(
                    text = restaurant.address,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }

            if (!isOnline) OfflineBanner()

            // Stato attuale (compatto)
            CurrentStatusCard(uiState)

            // AZIONE PRINCIPALE: tre tasti grandi
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text(
                    text = "Come siete messi?",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                )
                BigStatusButton(AvailabilityStatus.AVAILABLE, !uiState.isSaving) { onStatusSelected(AvailabilityStatus.AVAILABLE) }
                BigStatusButton(AvailabilityStatus.LIMITED, !uiState.isSaving) { onStatusSelected(AvailabilityStatus.LIMITED) }
                BigStatusButton(AvailabilityStatus.FULL, !uiState.isSaving) { onStatusSelected(AvailabilityStatus.FULL) }
                InfoDisclosure(
                    label = "Come funziona",
                    text = "Un tap pubblica subito lo stato. Resta valido 30 minuti: dopo, se non lo confermi, torna \u201Cda aggiornare\u201D.",
                )
            }

            uiState.message?.let { message ->
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    color = MaterialTheme.colorScheme.secondaryContainer,
                    shape = MaterialTheme.shapes.medium,
                ) {
                    Text(
                        text = message,
                        modifier = Modifier.padding(14.dp),
                        style = MaterialTheme.typography.bodyMedium,
                    )
                }
            }

            // DETTAGLI FACOLTATIVI: chiusi di default
            OptionalDetailsCard(
                uiState = uiState,
                onDecrementTables = onDecrementTables,
                onIncrementTables = onIncrementTables,
                onWaitSelected = onWaitSelected,
                onNoteChange = onNoteChange,
                onRefreshCurrentStatus = onRefreshCurrentStatus,
            )

            // INFO LOCALE: sempre visibile ma ordinata
            RestaurantInfoCard(
                category = restaurant.category,
                city = restaurant.city,
                address = restaurant.address,
                phoneNumber = restaurant.phoneNumber,
                phonePublic = restaurant.phonePublic,
                onPhonePublicChange = onPhonePublicChange,
            )

            // PRENOTAZIONI DI SALA: ingresso discreto e facoltativo
            Surface(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable(onClick = onOpenReservations),
                color = MaterialTheme.colorScheme.surface,
                shape = MaterialTheme.shapes.large,
                border = BorderStroke(1.dp, MaterialTheme.colorScheme.outline),
            ) {
                Row(
                    modifier = Modifier.padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Column(Modifier.weight(1f)) {
                        Text("📋 Prenotazioni di sala", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                        Text(
                            "Blocco note privato, facoltativo",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                    Text("Apri", style = MaterialTheme.typography.labelLarge, fontWeight = FontWeight.SemiBold, color = MaterialTheme.colorScheme.primary)
                }
            }

            Spacer(Modifier.height(18.dp))
        }
    }
}

@Composable
private fun CurrentStatusCard(uiState: RestaurantManagerUiState) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        color = MaterialTheme.colorScheme.surface,
        shape = MaterialTheme.shapes.large,
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outline),
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Text(
                text = "Ora sei",
                style = MaterialTheme.typography.labelLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            AvailabilityBadge(status = uiState.effectiveAvailability.status)
            Text(
                text = AvailabilityResolver.relativeUpdateLabel(
                    effective = uiState.effectiveAvailability,
                    now = uiState.now,
                ),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            uiState.effectiveAvailability.validUntil?.let { validUntil ->
                if (uiState.effectiveAvailability.status in LIVE) {
                    val remaining = (Duration.between(uiState.now, validUntil).seconds.coerceAtLeast(0) + 59) / 60
                    Text(
                        text = if (remaining == 1L) "Valido ancora ~1 min" else "Valido ancora ~$remaining min",
                        style = MaterialTheme.typography.bodySmall,
                        fontWeight = FontWeight.SemiBold,
                    )
                }
            }
        }
    }
}

@Composable
private fun BigStatusButton(
    status: AvailabilityStatus,
    enabled: Boolean,
    onClick: () -> Unit,
) {
    val presentation = statusPresentation(status)
    Button(
        onClick = onClick,
        enabled = enabled,
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = 72.dp)
            .semantics { contentDescription = "Imposta stato ${presentation.label}" },
        colors = ButtonDefaults.buttonColors(
            containerColor = presentation.container,
            contentColor = presentation.foreground,
        ),
        shape = MaterialTheme.shapes.large,
    ) {
        Text(
            text = presentation.label,
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Black,
        )
    }
}

@Composable
private fun OptionalDetailsCard(
    uiState: RestaurantManagerUiState,
    onDecrementTables: () -> Unit,
    onIncrementTables: () -> Unit,
    onWaitSelected: (Int?) -> Unit,
    onNoteChange: (String) -> Unit,
    onRefreshCurrentStatus: () -> Unit,
) {
    var expanded by remember { mutableStateOf(false) }

    Surface(
        modifier = Modifier.fillMaxWidth(),
        color = MaterialTheme.colorScheme.surface,
        shape = MaterialTheme.shapes.large,
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outline),
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Column(Modifier.weight(1f)) {
                    Text("Dettagli facoltativi", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                    Text(
                        "Tavoli, attesa, nota — puoi ignorarli",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
                TextButton(onClick = { expanded = !expanded }) {
                    Text(if (expanded) "Chiudi" else "Apri")
                }
            }

            AnimatedVisibility(visible = expanded) {
                Column(
                    modifier = Modifier.padding(top = 12.dp),
                    verticalArrangement = Arrangement.spacedBy(14.dp),
                ) {
                    Text("Tavoli liberi indicativi", style = MaterialTheme.typography.labelLarge)
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                    ) {
                        OutlinedButton(onClick = onDecrementTables, modifier = Modifier.heightIn(min = 48.dp)) { Text("−") }
                        Text(
                            text = uiState.availableTables?.toString() ?: "Non indicato",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                        )
                        OutlinedButton(onClick = onIncrementTables, modifier = Modifier.heightIn(min = 48.dp)) { Text("+") }
                    }

                    Text("Attesa indicativa", style = MaterialTheme.typography.labelLarge)
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .horizontalScroll(rememberScrollState()),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        listOf<Int?>(null, 0, 10, 20, 30).forEach { minutes ->
                            val label = when (minutes) {
                                null -> "Non indicata"
                                0 -> "Nessuna"
                                30 -> "30+ min"
                                else -> "$minutes min"
                            }
                            FilterChip(
                                selected = uiState.estimatedWaitMinutes == minutes,
                                onClick = { onWaitSelected(minutes) },
                                label = { Text(label) },
                            )
                        }
                    }

                    OutlinedTextField(
                        value = uiState.note,
                        onValueChange = onNoteChange,
                        modifier = Modifier.fillMaxWidth(),
                        label = { Text("Nota breve") },
                        placeholder = { Text("Es. Solo tavoli esterni") },
                        supportingText = { Text("${uiState.noteRemaining} caratteri disponibili") },
                        minLines = 2,
                        maxLines = 3,
                    )

                    HorizontalDivider()
                    OutlinedButton(
                        onClick = onRefreshCurrentStatus,
                        enabled = uiState.effectiveAvailability.status in LIVE && !uiState.isSaving,
                        modifier = Modifier
                            .fillMaxWidth()
                            .heightIn(min = 52.dp),
                    ) {
                        Text("Aggiorna dettagli e riconferma", fontWeight = FontWeight.Bold)
                    }
                    InfoDisclosure(
                        text = "Riconfermare aggiorna anche orario e scadenza: equivale a dire che lo stato attuale è ancora valido.",
                    )
                }
            }
        }
    }
}

@Composable
private fun RestaurantInfoCard(
    category: String,
    city: String,
    address: String,
    phoneNumber: String?,
    phonePublic: Boolean,
    onPhonePublicChange: (Boolean) -> Unit,
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        color = MaterialTheme.colorScheme.surface,
        shape = MaterialTheme.shapes.large,
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outline),
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Text("Info locale", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)

            Text(
                text = buildString {
                    append(category)
                    if (city.isNotBlank()) { append(" · "); append(city) }
                },
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Text(address, style = MaterialTheme.typography.bodyMedium)

            HorizontalDivider()

            Row(
                horizontalArrangement = Arrangement.spacedBy(14.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Column(Modifier.weight(1f)) {
                    Text("Mostra il numero e il tasto Chiama", style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
                    Text(
                        text = phoneNumber ?: "Nessun numero configurato",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
                Switch(
                    checked = phonePublic,
                    enabled = !phoneNumber.isNullOrBlank(),
                    onCheckedChange = onPhonePublicChange,
                )
            }

            InfoDisclosure(
                label = "Modificare nome, categoria, orari?",
                text = "La modifica completa dei dati del locale arriverà con il salvataggio reale (Step 9). Per ora qui puoi gestire la visibilità del telefono; nome e indirizzo arrivano dalla scheda del locale.",
            )
        }
    }
}

private val LIVE = setOf(
    AvailabilityStatus.AVAILABLE,
    AvailabilityStatus.LIMITED,
    AvailabilityStatus.FULL,
)
