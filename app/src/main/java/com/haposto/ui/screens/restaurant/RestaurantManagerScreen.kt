package com.haposto.ui.screens.restaurant

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SuggestionChip
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
import androidx.compose.ui.draw.clip
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.haposto.data.restaurant.RestaurantExtras
import com.haposto.domain.model.AvailabilityRules
import com.haposto.domain.model.AvailabilityStatus
import com.haposto.domain.usecase.AvailabilityResolver
import com.haposto.ui.components.AdaptiveScrollableContent
import com.haposto.ui.components.BigActionButton
import com.haposto.ui.components.InfoDisclosure
import com.haposto.ui.components.OfflineBanner
import com.haposto.ui.components.StatusSymbol
import com.haposto.ui.components.rememberSpeechInput
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
    /** Versioni DEV/PROD: account vero, 2FA, gestione completa del locale. */
    onOpenSettings: (() -> Unit)? = null,
    mfaMissing: Boolean = false,
    onOpenMfa: () -> Unit = {},
    /** Frase dettata per i dettagli facoltativi (tavoli, attesa, nota, offerta). */
    onDictateDetails: (String) -> Unit = {},
    onOfferChange: (String) -> Unit = {},
    /** L'avviso sulla responsabilità dell'offerta è già stato confermato su questo telefono. */
    offerTermsAccepted: Boolean = true,
    onAcceptOfferTerms: () -> Unit = {},
    /** Note pronte del locale (versioni DEV/PROD), condivise con lo staff. */
    quickNotes: List<String> = emptyList(),
    canSaveQuickNotes: Boolean = false,
    onSaveQuickNote: (String) -> Unit = {},
) {
    val realMode = onOpenSettings != null
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

            if (mfaMissing) {
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    color = MaterialTheme.colorScheme.errorContainer,
                    contentColor = MaterialTheme.colorScheme.onErrorContainer,
                    shape = MaterialTheme.shapes.large,
                ) {
                    Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        Text(
                            "Per pubblicare serve il codice della verifica in due passaggi.",
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.Bold,
                        )
                        BigActionButton(text = "Inserisci il codice", onClick = onOpenMfa)
                    }
                }
            }

            // Cosa vedono i clienti adesso, con il tasto "è ancora così".
            StatusHeroCard(
                uiState = uiState,
                onConfirmCurrentStatus = onRefreshCurrentStatus,
            )

            // AZIONE PRINCIPALE: tre tasti grandi a semaforo
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text(
                    text = "Come siete messi adesso?",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                )
                STATUS_CHOICES.forEach { choice ->
                    BigStatusButton(
                        status = choice.status,
                        hint = choice.hint,
                        isCurrent = uiState.effectiveAvailability.status == choice.status,
                        enabled = !uiState.isSaving,
                        onClick = { onStatusSelected(choice.status) },
                    )
                }
                InfoDisclosure(
                    label = "Come funziona",
                    text = "Un tap pubblica subito lo stato. Resta valido 30 minuti: dopo, se non lo confermi, i clienti vedono \u201Cda aggiornare\u201D.",
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

            if (onOpenSettings != null) {
                OutlinedButton(
                    onClick = onOpenSettings,
                    modifier = Modifier
                        .fillMaxWidth()
                        .heightIn(min = 56.dp),
                ) {
                    Text("⚙  Gestisci il locale · dati, orari, QR, staff, statistiche", fontWeight = FontWeight.SemiBold)
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
                onDictate = onDictateDetails,
                onOfferChange = onOfferChange,
                offerTermsAccepted = offerTermsAccepted,
                onAcceptOfferTerms = onAcceptOfferTerms,
                quickNotes = quickNotes,
                canSaveQuickNotes = canSaveQuickNotes,
                onSaveQuickNote = onSaveQuickNote,
            )

            // INFO LOCALE: sempre visibile ma ordinata
            if (!realMode) {
                RestaurantInfoCard(
                    category = restaurant.category,
                    city = restaurant.city,
                    address = restaurant.address,
                    phoneNumber = restaurant.phoneNumber,
                    phonePublic = restaurant.phonePublic,
                    onPhonePublicChange = onPhonePublicChange,
                )
            }

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
private fun StatusHeroCard(
    uiState: RestaurantManagerUiState,
    onConfirmCurrentStatus: () -> Unit,
) {
    val effective = uiState.effectiveAvailability
    val presentation = statusPresentation(effective.status)
    val isLive = effective.status in LIVE
    val remainingSeconds = effective.validUntil
        ?.let { Duration.between(uiState.now, it).seconds.coerceAtLeast(0) }
    val remainingMinutes = remainingSeconds?.let { (it + 59) / 60 }
    val haptics = LocalHapticFeedback.current

    Surface(
        modifier = Modifier.fillMaxWidth(),
        color = presentation.container,
        contentColor = presentation.foreground,
        shape = MaterialTheme.shapes.large,
    ) {
        Column(
            modifier = Modifier.padding(18.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Text(
                text = "I clienti adesso vedono",
                style = MaterialTheme.typography.labelLarge,
            )
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                StatusSymbol(presentation = presentation, diameter = 40.dp)
                Text(
                    text = presentation.label,
                    style = MaterialTheme.typography.headlineMedium,
                    fontWeight = FontWeight.Black,
                )
            }
            Text(
                text = AvailabilityResolver.relativeUpdateLabel(effective, uiState.now),
                style = MaterialTheme.typography.bodyMedium,
            )

            if (isLive && remainingSeconds != null && remainingMinutes != null) {
                val total = AvailabilityRules.LIVE_TTL_MINUTES * 60f
                LinearProgressIndicator(
                    progress = { (remainingSeconds / total).coerceIn(0f, 1f) },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(8.dp)
                        .clip(MaterialTheme.shapes.small),
                    color = presentation.strong,
                    trackColor = presentation.strong.copy(alpha = 0.2f),
                )
                Text(
                    text = if (remainingMinutes == 1L) "Valido ancora ~1 minuto" else "Valido ancora ~$remainingMinutes minuti",
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold,
                )
                Button(
                    onClick = {
                        haptics.performHapticFeedback(HapticFeedbackType.Confirm)
                        onConfirmCurrentStatus()
                    },
                    enabled = !uiState.isSaving,
                    modifier = Modifier
                        .fillMaxWidth()
                        .heightIn(min = 56.dp)
                        .semantics { contentDescription = "Conferma lo stato attuale" },
                    colors = ButtonDefaults.buttonColors(
                        containerColor = presentation.strong,
                        contentColor = presentation.onStrong,
                    ),
                    shape = MaterialTheme.shapes.medium,
                ) {
                    Text(
                        text = "✓  È ancora così: confermo",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                    )
                }
            } else {
                Text(
                    text = if (effective.status == AvailabilityStatus.STALE) {
                        "Il tuo stato è scaduto. Tocca qui sotto come siete messi: un tap e i clienti lo vedono subito."
                    } else {
                        "Non hai ancora pubblicato uno stato. Tocca qui sotto come siete messi."
                    },
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold,
                )
            }
        }
    }
}

private data class StatusChoice(val status: AvailabilityStatus, val hint: String)

private val STATUS_CHOICES = listOf(
    StatusChoice(AvailabilityStatus.AVAILABLE, "Ci sono tavoli liberi adesso"),
    StatusChoice(AvailabilityStatus.LIMITED, "Ultimi tavoli o breve attesa"),
    StatusChoice(AvailabilityStatus.FULL, "Niente posto in questo momento"),
)

@Composable
private fun BigStatusButton(
    status: AvailabilityStatus,
    hint: String,
    isCurrent: Boolean,
    enabled: Boolean,
    onClick: () -> Unit,
) {
    val presentation = statusPresentation(status)
    val haptics = LocalHapticFeedback.current
    Button(
        onClick = {
            haptics.performHapticFeedback(HapticFeedbackType.Confirm)
            onClick()
        },
        enabled = enabled,
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = 76.dp)
            .semantics { contentDescription = "Imposta stato ${presentation.label}" },
        colors = ButtonDefaults.buttonColors(
            containerColor = presentation.strong,
            contentColor = presentation.onStrong,
        ),
        border = if (isCurrent) BorderStroke(4.dp, MaterialTheme.colorScheme.onSurface) else null,
        shape = MaterialTheme.shapes.large,
        contentPadding = PaddingValues(horizontal = 18.dp, vertical = 12.dp),
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            StatusSymbol(presentation = presentation, diameter = 36.dp, inverted = true)
            Column(Modifier.weight(1f)) {
                Text(
                    text = presentation.label,
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Black,
                )
                Text(
                    text = if (isCurrent) "Stato attuale · $hint" else hint,
                    style = MaterialTheme.typography.bodyMedium,
                )
            }
        }
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
    onDictate: (String) -> Unit,
    onOfferChange: (String) -> Unit,
    offerTermsAccepted: Boolean,
    onAcceptOfferTerms: () -> Unit,
    quickNotes: List<String>,
    canSaveQuickNotes: Boolean,
    onSaveQuickNote: (String) -> Unit,
) {
    var expanded by remember { mutableStateOf(false) }
    var voiceUnavailable by remember { mutableStateOf(false) }
    // Prima offerta su questo telefono: si conferma l'avviso, poi l'azione rimasta in sospeso.
    var pendingOffer by remember { mutableStateOf<String?>(null) }
    fun changeOffer(value: String) {
        if (offerTermsAccepted || value.isBlank()) onOfferChange(value) else pendingOffer = value
    }
    pendingOffer?.let { value ->
        AlertDialog(
            onDismissRequest = { pendingOffer = null },
            title = { Text("Offerta della serata") },
            text = {
                Text(
                    "L'offerta è un tuo impegno verso i clienti: dev'essere vera e rispettata finché lo stato è " +
                        "valido (30 minuti, poi scade da sola). HAPOSTO la mostra così come la scrivi, sotto la tua " +
                        "responsabilità.",
                )
            },
            confirmButton = {
                TextButton(onClick = {
                    onAcceptOfferTerms()
                    onOfferChange(value)
                    pendingOffer = null
                }) { Text("Ho capito") }
            },
            dismissButton = { TextButton(onClick = { pendingOffer = null }) { Text("Annulla") } },
        )
    }
    val dictate = rememberSpeechInput(
        prompt = "Es. «tre tavoli, dieci minuti, solo tavoli fuori»",
        onText = { voiceUnavailable = false; onDictate(it) },
        onUnavailable = { voiceUnavailable = true },
    )

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
                        "Tavoli, attesa, nota, offerta — puoi ignorarli",
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
                    OutlinedButton(
                        onClick = dictate,
                        modifier = Modifier
                            .fillMaxWidth()
                            .heightIn(min = 52.dp),
                    ) {
                        Text("🎙  Detta i dettagli", fontWeight = FontWeight.Bold)
                    }
                    Text(
                        text = if (voiceUnavailable) {
                            "Dettatura non disponibile su questo telefono: scrivi a mano."
                        } else {
                            "Es. «tre tavoli, dieci minuti, solo tavoli fuori». Controlla prima di pubblicare."
                        },
                        style = MaterialTheme.typography.bodySmall,
                        color = if (voiceUnavailable) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.onSurfaceVariant,
                    )

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
                    if (quickNotes.isNotEmpty()) {
                        Text("Note pronte", style = MaterialTheme.typography.labelLarge)
                        NoteChips(quickNotes, onNoteChange)
                    }
                    val currentNote = uiState.note.trim()
                    if (canSaveQuickNotes && currentNote.isNotEmpty() &&
                        quickNotes.none { it.equals(currentNote, ignoreCase = true) } &&
                        quickNotes.size < RestaurantExtras.MAX_QUICK_NOTES
                    ) {
                        TextButton(onClick = { onSaveQuickNote(currentNote) }) {
                            Text("＋ Salva questa nota tra le note pronte")
                        }
                    }
                    val recent = uiState.recentNotes.filter { note -> quickNotes.none { it.equals(note, ignoreCase = true) } }
                    if (recent.isNotEmpty()) {
                        Text("Ultime note (un tocco per riusarle)", style = MaterialTheme.typography.labelLarge)
                        NoteChips(recent, onNoteChange)
                    }

                    Text("Offerta della serata (facoltativa)", style = MaterialTheme.typography.labelLarge)
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .horizontalScroll(rememberScrollState()),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        OFFER_CHOICES.forEach { choice ->
                            FilterChip(
                                selected = uiState.offer == choice,
                                onClick = { changeOffer(if (uiState.offer == choice) "" else choice) },
                                label = { Text(choice) },
                            )
                        }
                    }
                    OutlinedTextField(
                        value = uiState.offer,
                        onValueChange = { changeOffer(it) },
                        modifier = Modifier.fillMaxWidth(),
                        label = { Text("Offerta") },
                        placeholder = { Text("Es. Dolce offerto a chi arriva entro le 21") },
                        supportingText = {
                            Text("${uiState.offerRemaining} caratteri · solo con C'è posto o Pochi posti · scade con lo stato")
                        },
                        singleLine = true,
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
                text = "Nella versione demo qui gestisci solo la visibilità del telefono. Con l'account vero nome, telefono e orari si cambiano da «Gestisci il locale».",
            )
        }
    }
}

private val LIVE = setOf(
    AvailabilityStatus.AVAILABLE,
    AvailabilityStatus.LIMITED,
    AvailabilityStatus.FULL,
)

/** Offerte pronte a un tocco (si possono sempre scrivere o dettare). */
private val OFFER_CHOICES = listOf("−10%", "−20%", "Dolce offerto", "Calice offerto")

@Composable
private fun NoteChips(notes: List<String>, onPick: (String) -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .horizontalScroll(rememberScrollState()),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        notes.forEach { note ->
            SuggestionChip(
                onClick = { onPick(note) },
                label = { Text(note, maxLines = 1, overflow = TextOverflow.Ellipsis) },
            )
        }
    }
}
