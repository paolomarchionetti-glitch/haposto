package com.haposto.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

@Composable
fun AppStatePanel(
    title: String,
    body: String,
    modifier: Modifier = Modifier,
    showProgress: Boolean = false,
    actionLabel: String? = null,
    onAction: (() -> Unit)? = null,
    isError: Boolean = false,
) {
    Surface(
        modifier = modifier.fillMaxWidth(),
        color = if (isError) {
            MaterialTheme.colorScheme.errorContainer
        } else {
            MaterialTheme.colorScheme.surfaceVariant
        },
        contentColor = if (isError) {
            MaterialTheme.colorScheme.onErrorContainer
        } else {
            MaterialTheme.colorScheme.onSurfaceVariant
        },
        shape = MaterialTheme.shapes.large,
    ) {
        Column(
            modifier = Modifier.padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            if (showProgress) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    CircularProgressIndicator()
                    Text(
                        text = title,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                    )
                }
            } else {
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                )
            }
            Text(
                text = body,
                style = MaterialTheme.typography.bodyMedium,
            )
            if (actionLabel != null && onAction != null) {
                OutlinedButton(
                    onClick = onAction,
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Text(actionLabel)
                }
            }
        }
    }
}

@Composable
fun OfflineBanner(
    modifier: Modifier = Modifier,
    demoLocalData: Boolean = true,
    body: String? = null,
) {
    Surface(
        modifier = modifier.fillMaxWidth(),
        color = MaterialTheme.colorScheme.secondaryContainer,
        contentColor = MaterialTheme.colorScheme.onSecondaryContainer,
        shape = MaterialTheme.shapes.medium,
    ) {
        Column(
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp),
            verticalArrangement = Arrangement.spacedBy(3.dp),
        ) {
            Text(
                text = "Sei offline",
                style = MaterialTheme.typography.labelLarge,
                fontWeight = FontWeight.Bold,
            )
            Text(
                text = body ?: if (demoLocalData) {
                    "I dati demo locali restano consultabili. Con il backend, gli stati LIVE potrebbero non essere aggiornati finché la connessione non torna disponibile."
                } else {
                    "Gli stati LIVE potrebbero non essere aggiornati finché la connessione non torna disponibile."
                },
                style = MaterialTheme.typography.bodySmall,
            )
        }
    }
}
