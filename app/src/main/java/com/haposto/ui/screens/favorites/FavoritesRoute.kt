package com.haposto.ui.screens.favorites

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

/**
 * Preferiti — placeholder STEP 7.5.
 *
 * Funzione consumer Plus: qui arriveranno i locali salvati e l'alert
 * "avvisami quando torna C'è posto" (Step 16). Per ora mostra un teaser
 * elegante invece di un tab vuoto.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FavoritesRoute(modifier: Modifier = Modifier) {
    Scaffold(
        modifier = modifier,
        topBar = {
            TopAppBar(title = { Text("Preferiti", fontWeight = FontWeight.Bold) })
        },
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Surface(
                color = MaterialTheme.colorScheme.secondaryContainer,
                contentColor = MaterialTheme.colorScheme.onSecondaryContainer,
                shape = MaterialTheme.shapes.large,
                modifier = Modifier.fillMaxWidth(),
            ) {
                Column(
                    modifier = Modifier.padding(20.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    Text("Presto disponibile", style = MaterialTheme.typography.labelLarge, fontWeight = FontWeight.Bold)
                    Text(
                        "Salva i tuoi locali preferiti e ricevi un avviso quando tornano \u201CC'è posto\u201D.",
                        style = MaterialTheme.typography.bodyMedium,
                    )
                    Text(
                        "Sarà parte di HAPOSTO Plus.",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
        }
    }
}
