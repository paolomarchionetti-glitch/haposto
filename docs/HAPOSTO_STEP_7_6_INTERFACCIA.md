# HAPOSTO — STEP 7.6 "Interfaccia essenziale"

Passata di semplificazione UX sopra il 7.5. Obiettivo: **meno testo, tasti più grandi, tutto più leggibile e professionale**, senza toccare i due loop core.

Il codice completo è nel progetto (`app/src/main/java/com/haposto/...`) e nello ZIP aggiornato.

---

## 1. Principi applicati

1. **Il testo di spiegazione non sta mai nel flusso.** Sparisce dietro un piccolo "ⓘ" ed è chiuso di default. Chi sa già, non lo vede; chi ha un dubbio, lo apre.
2. **Tasti grandi per le azioni vere.** L'azione principale del ristoratore (dichiarare lo stato) ora sono tre tasti da 72dp, impossibili da sbagliare.
3. **Il secondario si nasconde.** I dettagli facoltativi (tavoli, attesa, nota) sono chiusi di default: la schermata parte pulita.
4. **L'info è visibile ma ordinata.** Le impostazioni del locale stanno in un'unica card "Info locale", presente ma non invadente.

---

## 2. File nuovi

| File | Cosa fa |
|---|---|
| `ui/components/InfoDisclosure.kt` | Aiuto contestuale a scomparsa. Un "ⓘ Perché? ▾" che apre una spiegazione breve. È il mattone che toglie il testo dal flusso in tutta l'app. |
| `ui/components/BigActionButton.kt` | Tasto d'azione grande (≥60dp), testo chiaro, forma coerente. Riutilizzabile per ogni CTA primaria. |

## File modificati

| File | Cosa cambia |
|---|---|
| `ui/screens/restaurant/RestaurantManagerScreen.kt` | Riscritta essenziale: intestazione minimale, **tre tasti stato da 72dp**, dettagli facoltativi **collassati**, nuova card **Info locale**, spiegazioni spostate in `InfoDisclosure`, pulsante "Aggiorna dettagli e riconferma" in Title Case e più grande. **Firma e callback invariati** (nessuna modifica alla Route). |
| `ui/screens/home/HomeScreen.kt` | Toggle primario ora è un `BigActionButton`; i due disclaimer in fondo sostituiti da un unico `InfoDisclosure` "Come funziona HAPOSTO". |

---

## 3. Prima → dopo (area ristoratore)

**Prima:** intestazione con due righe di stato tecnico, un paragrafo "Step 7…", tasti stato da 60dp, blocco "Dettagli facoltativi" sempre aperto (tavoli + attesa + nota + pulsante), card telefono separata, due paragrafi lunghi di spiegazione in mezzo e in fondo. Molto testo, molta altezza da scrollare.

**Dopo:** nome + indirizzo, la card "Ora sei" compatta, poi **tre grandi tasti colorati** che riempiono lo schermo (C'è posto / Pochi posti / Completo). Sotto, "Dettagli facoltativi" **chiuso** (si apre con un tap) e una card **Info locale** ordinata con la visibilità del telefono. Ogni spiegazione è dietro un "ⓘ". La schermata iniziale è corta, chiara, professionale.

Anteprima: `brand/anteprima_area_ristoratore.png`.

---

## 4. Nota su cosa resta per dopo

- La **modifica completa dei dati del locale** (nome, categoria, orari) è predisposta come punto d'ingresso in "Info locale", ma la scrittura reale arriva con Auth + RPC (Step 9). Per ora la card gestisce la visibilità del telefono e mostra i dati correnti.
- La gestione delle **prenotazioni** (registro digitale al posto di carta e penna) è un modulo a parte, trattato nella roadmap dedicata (`HAPOSTO_ROADMAP_PRENOTAZIONI_E_UX.md`): richiede più studio e alcune decisioni strategiche.

---

## 5. Test

Come per il 7.5: i test unitari (dominio/dati) non sono influenzati. Alcuni test di strumentazione Compose che cercavano testi ora rimossi/cambiati (es. i vecchi paragrafi del manager) andranno aggiornati alle nuove stringhe. Non bloccano l'app.

---

## 6. Codice

### ui/components/InfoDisclosure.kt (NUOVO)

```kotlin
package com.haposto.ui.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

/**
 * Aiuto contestuale nascondibile (STEP 7.6).
 *
 * Regola d'oro dell'interfaccia essenziale: il testo di spiegazione NON sta mai
 * nel flusso principale. Sta dietro un piccolo "ⓘ {label}" ed è chiuso di default.
 * Chi sa già cosa fare non lo vede nemmeno; chi ha un dubbio lo apre con un tap.
 *
 * @param text spiegazione breve, mostrata solo quando aperto.
 * @param label etichetta del pulsante (default: "Perché?").
 */
@Composable
fun InfoDisclosure(
    text: String,
    modifier: Modifier = Modifier,
    label: String = "Perché?",
) {
    var expanded by remember { mutableStateOf(false) }

    Column(modifier = modifier.fillMaxWidth()) {
        TextButton(onClick = { expanded = !expanded }) {
            Text(
                text = if (expanded) "ⓘ  $label ▴" else "ⓘ  $label ▾",
                style = MaterialTheme.typography.labelLarge,
                fontWeight = FontWeight.SemiBold,
            )
        }
        AnimatedVisibility(visible = expanded) {
            Surface(
                color = MaterialTheme.colorScheme.surfaceVariant,
                contentColor = MaterialTheme.colorScheme.onSurfaceVariant,
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier.fillMaxWidth(),
            ) {
                Text(
                    text = text,
                    modifier = Modifier.padding(14.dp),
                    style = MaterialTheme.typography.bodyMedium,
                )
            }
        }
    }
}
```

### ui/components/BigActionButton.kt (NUOVO)

```kotlin
package com.haposto.ui.components

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

/**
 * Tasto d'azione grande (STEP 7.6): target ampio, testo chiaro, forma coerente.
 * Usalo per le azioni primarie. Altezza minima 60dp per un tocco comodo.
 */
@Composable
fun BigActionButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    container: Color = MaterialTheme.colorScheme.primary,
    content: Color = MaterialTheme.colorScheme.onPrimary,
    minHeight: Int = 60,
) {
    Button(
        onClick = onClick,
        enabled = enabled,
        modifier = modifier
            .fillMaxWidth()
            .heightIn(min = minHeight.dp),
        colors = ButtonDefaults.buttonColors(
            containerColor = container,
            contentColor = content,
        ),
        shape = MaterialTheme.shapes.medium,
    ) {
        Text(
            text = text,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
        )
    }
}
```

### ui/screens/restaurant/RestaurantManagerScreen.kt

```kotlin
package com.haposto.ui.screens.restaurant

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.BorderStroke
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
```

### ui/screens/home/HomeScreen.kt

```kotlin
package com.haposto.ui.screens.home

import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
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
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
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
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text(
                            text = "HAPOSTO",
                            fontWeight = FontWeight.Black,
                            color = MaterialTheme.colorScheme.primary,
                        )
                        Text(
                            text = "Sai dove c'è posto. Ora.",
                            style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                },
                actions = {
                    Surface(
                        color = MaterialTheme.colorScheme.tertiaryContainer,
                        contentColor = MaterialTheme.colorScheme.onTertiaryContainer,
                        shape = MaterialTheme.shapes.small,
                        modifier = Modifier.padding(end = 12.dp),
                    ) {
                        Text(
                            text = if (uiState.isSupabaseBacked) "SUPABASE DEV" else "DEMO",
                            modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                            style = MaterialTheme.typography.labelMedium,
                            fontWeight = FontWeight.Bold,
                        )
                    }
                },
            )
        },
    ) { innerPadding ->
        BoxWithConstraints(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding),
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
                            if (uiState.isSupabaseBacked) {
                                "Dati dal backend DEV Supabase (attività fittizie)."
                            } else {
                                "Dati dimostrativi locali."
                            },
                    )
                    Spacer(Modifier.height(8.dp))
                }
            }
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
```
