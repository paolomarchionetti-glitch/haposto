package com.haposto.ui.screens.restaurant

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RestaurantManagerAccessDeniedScreen(
    onBack: () -> Unit,
    onGoToAccess: () -> Unit,
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Area ristoratore") },
                navigationIcon = {
                    androidx.compose.material3.TextButton(onClick = onBack) {
                        Text("Indietro")
                    }
                },
            )
        },
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(24.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Text(
                text = "Accesso non autorizzato",
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold,
            )
            Text(
                text = "Per gestire un locale serve un claim approvato associato a questo ristorante. Nella demo locale la verifica è simulata e non sostituisce la sicurezza del backend.",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Button(
                onClick = onGoToAccess,
                modifier = Modifier.fillMaxWidth(),
            ) {
                Text("VAI A ACCESSO E VERIFICA")
            }
            OutlinedButton(
                onClick = onBack,
                modifier = Modifier.fillMaxWidth(),
            ) {
                Text("TORNA INDIETRO")
            }
        }
    }
}
