package com.haposto.ui.screens.reservations

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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.TextRange
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.haposto.data.reservations.Reservation
import com.haposto.data.reservations.ReservationList
import com.haposto.domain.model.OpeningHours
import com.haposto.domain.reservations.ReservationTimes
import com.haposto.domain.voice.ReservationDictation
import com.haposto.ui.components.BigActionButton
import com.haposto.ui.components.InfoDisclosure
import com.haposto.ui.components.rememberSpeechInput
import java.time.Instant
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ReservationsScreen(
    items: List<Reservation>,
    onAddOrUpdate: (
        editingId: String?,
        name: String,
        time: String,
        partySize: Int,
        table: String?,
        date: LocalDate,
    ) -> Unit,
    onRemove: (String) -> Unit,
    onBack: () -> Unit,
    today: LocalDate = LocalDate.now(),
    /** Orari del locale: decidono gli orari proposti a un tocco (null = pranzo e cena standard). */
    openingHours: OpeningHours? = null,
) {
    // Saveable: a rotation or a trip to the voice-recognition activity must not wipe the form.
    var selectedDayEpoch by rememberSaveable { mutableLongStateOf(today.toEpochDay()) }
    val selectedDay = LocalDate.ofEpochDay(selectedDayEpoch).let { if (it.isBefore(today)) today else it }
    var editingId by rememberSaveable { mutableStateOf<String?>(null) }
    var name by rememberSaveable { mutableStateOf("") }
    var time by rememberSaveable(stateSaver = TextFieldValue.Saver) { mutableStateOf(TextFieldValue("")) }
    var party by rememberSaveable { mutableIntStateOf(2) }
    var table by rememberSaveable { mutableStateOf("") }
    var voiceMessage by remember { mutableStateOf<String?>(null) }
    var showDatePicker by remember { mutableStateOf(false) }

    fun setTime(text: String) {
        time = TextFieldValue(text, TextRange(text.length))
    }

    fun resetForm() {
        editingId = null; name = ""; setTime(""); party = 2; table = ""
    }

    val dictate = rememberSpeechInput(
        prompt = "Es. «Rossi, quattro, alle venti e trenta, tavolo dodici»",
        onText = { spoken ->
            val draft = ReservationDictation.parse(spoken, today, openingHours, selectedDay)
            if (draft.isEmpty) {
                voiceMessage = "Non ho capito: riprova o scrivi a mano."
            } else {
                draft.name?.let { name = it }
                draft.time?.let { setTime(ReservationTimes.format(it)) }
                draft.partySize?.let { party = it.coerceIn(1, ReservationsViewModel.MAX_PARTY_SIZE) }
                draft.table?.let { table = it }
                draft.date?.let { if (!it.isBefore(today)) selectedDayEpoch = it.toEpochDay() }
                voiceMessage = "Controlla i dati e premi Aggiungi."
            }
        },
        onUnavailable = { voiceMessage = "Dettatura non disponibile su questo telefono: scrivi a mano." },
    )

    val slots = remember(selectedDay, openingHours) {
        ReservationTimes.slots(openingHours, selectedDay, now = LocalDateTime.now()).map(ReservationTimes::format)
    }
    val dayItems = ReservationList.forDay(items, selectedDay)

    if (showDatePicker) {
        val pickerState = rememberDatePickerState(
            initialSelectedDateMillis = selectedDay.atStartOfDay(ZoneOffset.UTC).toInstant().toEpochMilli(),
        )
        DatePickerDialog(
            onDismissRequest = { showDatePicker = false },
            confirmButton = {
                TextButton(
                    onClick = {
                        pickerState.selectedDateMillis?.let { millis ->
                            val picked = Instant.ofEpochMilli(millis).atZone(ZoneOffset.UTC).toLocalDate()
                            selectedDayEpoch = (if (picked.isBefore(today)) today else picked).toEpochDay()
                        }
                        showDatePicker = false
                    },
                ) { Text("Scegli") }
            },
            dismissButton = { TextButton(onClick = { showDatePicker = false }) { Text("Annulla") } },
        ) {
            DatePicker(state = pickerState)
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Prenotazioni di sala", fontWeight = FontWeight.Bold) },
                navigationIcon = { TextButton(onClick = onBack) { Text("Indietro") } },
            )
        },
    ) { innerPadding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            item {
                Spacer(Modifier.height(4.dp))
                InfoDisclosure(
                    label = "A cosa serve",
                    text = "Un blocco note privato per le prenotazioni extra (telefono, walk-in, fuori da altri sistemi). Resta solo su questo dispositivo; i giorni passati si cancellano da soli. Facoltativo: usalo come e quando vuoi.",
                )
            }

            // Giorno: oggi, domani o un altro.
            item {
                val tomorrow = today.plusDays(1)
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    FilterChip(
                        selected = selectedDay == today,
                        onClick = { selectedDayEpoch = today.toEpochDay() },
                        label = { Text("Oggi") },
                    )
                    FilterChip(
                        selected = selectedDay == tomorrow,
                        onClick = { selectedDayEpoch = tomorrow.toEpochDay() },
                        label = { Text("Domani") },
                    )
                    val otherDay = selectedDay != today && selectedDay != tomorrow
                    FilterChip(
                        selected = otherDay,
                        onClick = { showDatePicker = true },
                        label = { Text(if (otherDay) "📅 ${dayLabel(selectedDay)}" else "📅 Altro giorno") },
                    )
                }
            }

            // Form aggiungi / modifica
            item {
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    color = MaterialTheme.colorScheme.surface,
                    shape = MaterialTheme.shapes.large,
                    border = BorderStroke(1.dp, MaterialTheme.colorScheme.outline),
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp),
                    ) {
                        Text(
                            text = if (editingId == null) {
                                "Aggiungi prenotazione · ${dayTitle(selectedDay, today)}"
                            } else {
                                "Modifica prenotazione"
                            },
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                        )

                        OutlinedButton(
                            onClick = dictate,
                            modifier = Modifier
                                .fillMaxWidth()
                                .heightIn(min = 52.dp),
                        ) {
                            Text("🎙  Detta la prenotazione", fontWeight = FontWeight.Bold)
                        }
                        Text(
                            text = voiceMessage ?: "Es. «Rossi, quattro, alle venti e trenta, tavolo dodici». Oppure scrivi qui sotto.",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )

                        OutlinedTextField(
                            value = name,
                            onValueChange = { name = it },
                            modifier = Modifier.fillMaxWidth(),
                            singleLine = true,
                            label = { Text("Nome") },
                            placeholder = { Text("Es. Mario Rossi") },
                        )

                        if (slots.isNotEmpty()) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .horizontalScroll(rememberScrollState()),
                                horizontalArrangement = Arrangement.spacedBy(8.dp),
                            ) {
                                val current = ReservationTimes.normalize(time.text)
                                slots.forEach { slot ->
                                    FilterChip(
                                        selected = current == slot,
                                        onClick = { setTime(slot) },
                                        label = { Text(slot) },
                                    )
                                }
                            }
                        }

                        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                            OutlinedTextField(
                                value = time,
                                onValueChange = { typed -> setTime(ReservationTimes.formatTyped(typed.text)) },
                                modifier = Modifier.weight(1f),
                                singleLine = true,
                                label = { Text("Orario") },
                                placeholder = { Text("2030") },
                                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                            )
                            OutlinedTextField(
                                value = table,
                                onValueChange = { table = it },
                                modifier = Modifier.weight(1f),
                                singleLine = true,
                                label = { Text("Tavolo (opz.)") },
                                placeholder = { Text("12") },
                            )
                        }

                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text("Persone", modifier = Modifier.weight(1f), style = MaterialTheme.typography.bodyLarge)
                            OutlinedButton(onClick = { if (party > 1) party-- }, modifier = Modifier.heightIn(min = 48.dp)) { Text("−") }
                            Text(
                                text = party.toString(),
                                modifier = Modifier.width(48.dp),
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold,
                                textAlign = TextAlign.Center,
                            )
                            OutlinedButton(
                                onClick = { if (party < ReservationsViewModel.MAX_PARTY_SIZE) party++ },
                                modifier = Modifier.heightIn(min = 48.dp),
                            ) { Text("+") }
                        }

                        BigActionButton(
                            text = if (editingId == null) "Aggiungi" else "Salva modifica",
                            onClick = {
                                val cleanTime = ReservationTimes.normalize(time.text) ?: time.text.trim()
                                onAddOrUpdate(editingId, name, cleanTime, party, table, selectedDay)
                                resetForm()
                                voiceMessage = null
                            },
                            enabled = name.isNotBlank(),
                        )
                        if (editingId != null) {
                            TextButton(onClick = { resetForm() }, modifier = Modifier.fillMaxWidth()) {
                                Text("Annulla modifica")
                            }
                        }
                    }
                }
            }

            if (dayItems.isEmpty()) {
                item {
                    Text(
                        text = "Nessuna prenotazione per ${dayTitle(selectedDay, today).lowercase()}. Aggiungine una qui sopra.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(vertical = 8.dp),
                    )
                }
            } else {
                item {
                    val people = dayItems.sumOf { it.partySize }
                    Text(
                        text = "${dayTitle(selectedDay, today)}: ${dayItems.size} " +
                            (if (dayItems.size == 1) "prenotazione" else "prenotazioni") +
                            " · $people " + (if (people == 1) "persona" else "persone"),
                        style = MaterialTheme.typography.labelLarge,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
                items(items = dayItems, key = { it.id }) { r ->
                    ReservationRow(
                        reservation = r,
                        onEdit = {
                            editingId = r.id
                            name = r.name
                            setTime(r.time)
                            party = r.partySize
                            table = r.table ?: ""
                            r.localDate?.let { selectedDayEpoch = it.toEpochDay() }
                        },
                        onRemove = { onRemove(r.id) },
                    )
                }
            }

            item { Spacer(Modifier.height(24.dp)) }
        }
    }
}

private val DAY_FORMAT: DateTimeFormatter = DateTimeFormatter.ofPattern("EEE d MMM", Locale.ITALIAN)

private fun dayLabel(day: LocalDate): String = DAY_FORMAT.format(day)

private fun dayTitle(day: LocalDate, today: LocalDate): String = when (day) {
    today -> "Oggi"
    today.plusDays(1) -> "Domani"
    else -> dayLabel(day).replaceFirstChar { it.titlecase(Locale.ITALIAN) }
}

@Composable
private fun ReservationRow(
    reservation: Reservation,
    onEdit: () -> Unit,
    onRemove: () -> Unit,
) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onEdit),
        color = MaterialTheme.colorScheme.surface,
        shape = MaterialTheme.shapes.large,
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outline),
    ) {
        Row(
            modifier = Modifier.padding(14.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Text(
                text = reservation.time.ifBlank { "—" },
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Black,
                modifier = Modifier.width(64.dp),
            )
            Column(Modifier.weight(1f)) {
                Text(reservation.name, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                Text(
                    text = buildString {
                        append(reservation.partySize)
                        append(if (reservation.partySize == 1) " persona" else " persone")
                        reservation.table?.let { append(" · tavolo "); append(it) }
                    },
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            TextButton(onClick = onRemove) { Text("Rimuovi") }
        }
    }
}
