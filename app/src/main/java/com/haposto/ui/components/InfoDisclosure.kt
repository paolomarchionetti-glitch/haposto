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
