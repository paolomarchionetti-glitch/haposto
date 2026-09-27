package com.haposto.ui.screens.reservations

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.speech.RecognizerIntent
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.haposto.data.reservations.Reservation
import com.haposto.ui.components.BigActionButton
import com.haposto.ui.components.InfoDisclosure

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ReservationsScreen(
    items: List<Reservation>,
    onAddOrUpdate: (editingId: String?, name: String, time: String, partySize: Int, table: String?) -> Unit,
    onRemove: (String) -> Unit,
    onBack: () -> Unit,
) {
    // Saveable: a rotation or a trip to the voice-recognition activity must not wipe the form.
    var editingId by rememberSaveable { mutableStateOf<String?>(null) }
    var name by rememberSaveable { mutableStateOf("") }
    var time by rememberSaveable { mutableStateOf("") }
    var party by rememberSaveable { mutableIntStateOf(2) }
    var table by rememberSaveable { mutableStateOf("") }
    var voiceError by remember { mutableStateOf<String?>(null) }

    fun resetForm() {
        editingId = null; name = ""; time = ""; party = 2; table = ""
    }

    val speechLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.StartActivityForResult(),
    ) { result ->
        if (result.resultCode == Activity.RESULT_OK) {
            val spoken = result.data
                ?.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)
                ?.firstOrNull()
                ?.trim()
            if (!spoken.isNullOrEmpty()) {
                name = if (name.isBlank()) spoken else "$name $spoken"
            }
        }
    }

    fun dictateName() {
        voiceError = null
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, "it-IT")
            putExtra(RecognizerIntent.EXTRA_PROMPT, "Detta il nome…")
        }
        try {
            speechLauncher.launch(intent)
        } catch (e: ActivityNotFoundException) {
            voiceError = "Riconoscimento vocale non disponibile su questo dispositivo. Puoi scrivere il nome."
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
                    text = "Un blocco note privato per le prenotazioni extra (telefono, walk-in, fuori da altri sistemi). Resta solo su questo dispositivo. Facoltativo: usalo come e quando vuoi.",
                )
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
                            text = if (editingId == null) "Aggiungi prenotazione" else "Modifica prenotazione",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                        )

                        OutlinedTextField(
                            value = name,
                            onValueChange = { name = it },
                            modifier = Modifier.fillMaxWidth(),
                            singleLine = true,
                            label = { Text("Nome") },
                            placeholder = { Text("Es. Mario Rossi") },
                            trailingIcon = {
                                TextButton(onClick = { dictateName() }) { Text("🎙 Detta") }
                            },
                        )

                        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                            OutlinedTextField(
                                value = time,
                                onValueChange = { time = it },
                                modifier = Modifier.weight(1f),
                                singleLine = true,
                                label = { Text("Orario") },
                                placeholder = { Text("20:30") },
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
                                textAlign = androidx.compose.ui.text.style.TextAlign.Center,
                            )
                            OutlinedButton(
                                onClick = { if (party < ReservationsViewModel.MAX_PARTY_SIZE) party++ },
                                modifier = Modifier.heightIn(min = 48.dp),
                            ) { Text("+") }
                        }

                        voiceError?.let {
                            Text(it, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.error)
                        }

                        BigActionButton(
                            text = if (editingId == null) "Aggiungi" else "Salva modifica",
                            onClick = {
                                onAddOrUpdate(editingId, name, time, party, table)
                                resetForm()
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

            if (items.isEmpty()) {
                item {
                    Text(
                        text = "Nessuna prenotazione annotata. Aggiungine una qui sopra.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(vertical = 8.dp),
                    )
                }
            } else {
                item {
                    Text(
                        text = "${items.size} in lista",
                        style = MaterialTheme.typography.labelLarge,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
                items(items = items, key = { it.id }) { r ->
                    ReservationRow(
                        reservation = r,
                        onEdit = {
                            editingId = r.id
                            name = r.name
                            time = r.time
                            party = r.partySize
                            table = r.table ?: ""
                        },
                        onRemove = { onRemove(r.id) },
                    )
                }
            }

            item { Spacer(Modifier.height(24.dp)) }
        }
    }
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
