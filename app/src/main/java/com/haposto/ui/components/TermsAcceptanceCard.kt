package com.haposto.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.material3.Checkbox
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.haposto.ui.screens.legal.LegalDocument

/**
 * Accettazione di termini e privacy al primo accesso (e quando cambiano versione).
 * Per i ristoratori anche le condizioni dedicate e l'approvazione specifica delle clausole
 * onerose (artt. 1341-1342 c.c.): una casella separata, come richiede la legge.
 */
@Composable
fun TermsAcceptanceCard(
    needsUserTerms: Boolean,
    needsRestaurantTerms: Boolean,
    isBusy: Boolean,
    onOpenDocument: (LegalDocument) -> Unit,
    onAccept: (marketingOptIn: Boolean) -> Unit,
) {
    var terms by rememberSaveable { mutableStateOf(false) }
    var restaurantTerms by rememberSaveable { mutableStateOf(false) }
    var clauses by rememberSaveable { mutableStateOf(false) }
    var marketing by rememberSaveable { mutableStateOf(false) }

    val ready = (!needsUserTerms || terms) && (!needsRestaurantTerms || (restaurantTerms && clauses))

    SectionCard(
        title = "Prima di continuare",
        subtitle = "Leggi e accetta i documenti. Puoi rileggerli quando vuoi da Account → Informazioni.",
    ) {
        if (needsUserTerms) {
            CheckRow(checked = terms, onChecked = { terms = it }, text = "Ho letto e accetto i Termini d'uso e l'Informativa privacy (obbligatorio)")
            Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                TextButton(onClick = { onOpenDocument(LegalDocument.TERMS) }) { Text("Leggi i Termini") }
                TextButton(onClick = { onOpenDocument(LegalDocument.PRIVACY) }) { Text("Leggi la Privacy") }
            }
        }
        if (needsRestaurantTerms) {
            CheckRow(
                checked = restaurantTerms,
                onChecked = { restaurantTerms = it },
                text = "Accetto le Condizioni di servizio per i ristoranti (obbligatorio)",
            )
            CheckRow(
                checked = clauses,
                onChecked = { clauses = it },
                text = "Approvo specificamente le clausole 2.3, 4.4, 5.1, 6.2, 8 e 9 delle Condizioni (artt. 1341-1342 c.c.) (obbligatorio)",
            )
            TextButton(onClick = { onOpenDocument(LegalDocument.RESTAURANT_TERMS) }) { Text("Leggi le Condizioni per i ristoranti") }
        }
        if (needsUserTerms) {
            CheckRow(
                checked = marketing,
                onChecked = { marketing = it },
                text = "Voglio ricevere via email le novità di HAPOSTO (facoltativo, revocabile)",
            )
        }
        BigActionButton(
            text = if (isBusy) "Salvo…" else "Accetto e continuo",
            enabled = ready && !isBusy,
            onClick = { onAccept(marketing) },
        )
    }
}

@Composable
private fun CheckRow(checked: Boolean, onChecked: (Boolean) -> Unit, text: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = 48.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Checkbox(checked = checked, onCheckedChange = onChecked)
        Text(text = text, style = MaterialTheme.typography.bodyMedium, modifier = Modifier.weight(1f))
    }
}
