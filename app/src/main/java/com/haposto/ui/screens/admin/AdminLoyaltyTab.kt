package com.haposto.ui.screens.admin

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.haposto.data.admin.AdminLoyaltyOverview
import com.haposto.data.admin.AdminLoyaltyRestaurant
import com.haposto.data.admin.AdminLoyaltyTexts
import com.haposto.ui.components.LabeledValue
import java.time.ZoneId

/**
 * Scheda «Tessere» (§11 e §13): i numeri della tessera fedeltà nascosta, solo da leggere, più i
 * tester e le sanzioni automatiche. Ridare la tessera è facoltativo: il sistema non lo richiede.
 */
@Composable
internal fun LoyaltyTab(
    state: AdminUiState,
    viewModel: AdminViewModel,
    onOpenRestaurant: (String) -> Unit,
    onOpenUser: (String) -> Unit,
) {
    var restoring by rememberSaveable { mutableStateOf<String?>(null) }
    AdminLoyaltyContent(
        overview = state.loyalty,
        busy = state.busy,
        onOpenRestaurant = onOpenRestaurant,
        onOpenUser = onOpenUser,
        onRestore = { restoring = it },
    )
    val target = state.loyalty?.sanctioned?.firstOrNull { it.restaurantId == restoring }
    if (target != null) {
        RestoreDialog(
            restaurant = target,
            onDismiss = { restoring = null },
            onConfirm = { note ->
                restoring = null
                viewModel.restoreLoyalty(target.restaurantId, note)
            },
        )
    }
}

/** Contenuto senza stato, per i test. */
@Composable
internal fun AdminLoyaltyContent(
    overview: AdminLoyaltyOverview?,
    busy: Boolean,
    onOpenRestaurant: (String) -> Unit,
    onOpenUser: (String) -> Unit,
    onRestore: (String) -> Unit,
) {
    AdminList {
        if (overview == null) {
            item { Text("Carico… (serve la migration 0018 sul database)") }
            return@AdminList
        }
        item {
            RowCard {
                LabeledValue("Modalità", AdminLoyaltyTexts.mode(overview.mode))
                if (overview.launched) {
                    Text(
                        "Già lanciata: non torna più a OFF o TEST, solo fra ON ed EXISTING_ONLY.",
                        style = MaterialTheme.typography.bodySmall,
                    )
                }
                Text("Si cambia in Impostazioni → loyalty → \"mode\".", style = MaterialTheme.typography.bodySmall)
            }
        }
        items(AdminLoyaltyTexts.sections(overview), key = { it.title }) { section ->
            RowCard {
                Text(section.title, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
                section.rows.forEach { (label, value) ->
                    Row(Modifier.fillMaxWidth()) {
                        Text(label, style = MaterialTheme.typography.bodyMedium, modifier = Modifier.weight(1f))
                        Text(value, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
                    }
                }
            }
        }
        item {
            Text("Sanzioni automatiche", style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
        }
        if (overview.sanctioned.isEmpty()) {
            item { Text("Nessun locale sospeso o con la tessera tolta.", style = MaterialTheme.typography.bodySmall) }
        }
        items(overview.sanctioned, key = { "sanction-" + it.restaurantId }) { restaurant ->
            RowCard {
                Text(restaurant.name, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
                Text(
                    AdminLoyaltyTexts.programStatus(restaurant.status) +
                        (restaurant.suspendedUntil?.let { " fino al " + DATE.format(it.atZone(ZoneId.systemDefault())) } ?: ""),
                    style = MaterialTheme.typography.bodySmall,
                )
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    TextButton(onClick = { onOpenRestaurant(restaurant.restaurantId) }) { Text("Apri il locale") }
                    OutlinedButton(onClick = { onRestore(restaurant.restaurantId) }, enabled = !busy) { Text("Ridai la tessera") }
                }
            }
        }
        item {
            Text("Tester", style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
        }
        item {
            RowCard {
                Text("Locali tester (${overview.testerRestaurants.size})", style = MaterialTheme.typography.labelLarge)
                if (overview.testerRestaurants.isEmpty()) Text("Nessuno.", style = MaterialTheme.typography.bodySmall)
                overview.testerRestaurants.forEach { restaurant ->
                    TextButton(onClick = { onOpenRestaurant(restaurant.restaurantId) }) {
                        Text(
                            "${restaurant.name}${restaurant.city?.let { " · $it" }.orEmpty()} · " +
                                AdminLoyaltyTexts.programStatus(restaurant.status),
                        )
                    }
                }
                Text("Clienti tester (${overview.testerUsers.size}; gli admin lo sono sempre)", style = MaterialTheme.typography.labelLarge)
                if (overview.testerUsers.isEmpty()) Text("Nessuno.", style = MaterialTheme.typography.bodySmall)
                overview.testerUsers.forEach { user ->
                    TextButton(onClick = { onOpenUser(user.userId) }) { Text(user.email) }
                }
            }
        }
        item {
            Text(
                "Le operazioni della tessera sono nel Registro: cerca LOYALTY.",
                style = MaterialTheme.typography.bodySmall,
            )
        }
    }
}

@Composable
private fun RestoreDialog(restaurant: AdminLoyaltyRestaurant, onDismiss: () -> Unit, onConfirm: (String) -> Unit) {
    var note by rememberSaveable { mutableStateOf("") }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Ridare la tessera a ${restaurant.name}?") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(
                    "La tessera passa a «finita»: il locale la riattiva accettando di nuovo il patto e le " +
                        "segnalazioni ripartono da zero. Non serve per far funzionare il sistema.",
                )
                OutlinedTextField(
                    value = note,
                    onValueChange = { note = it.take(200) },
                    label = { Text("Motivo (finisce nel registro)") },
                    modifier = Modifier.fillMaxWidth(),
                )
            }
        },
        confirmButton = { TextButton(onClick = { onConfirm(note) }) { Text("Ridai la tessera") } },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Annulla") } },
    )
}
