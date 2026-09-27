package com.haposto.ui.screens.access

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedCard
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.haposto.domain.model.Restaurant
import com.haposto.ui.components.AdaptiveScrollableContent
import com.haposto.ui.components.OfflineBanner
import java.time.ZoneId
import java.time.format.DateTimeFormatter

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RestaurantAccessScreen(
    uiState: RestaurantAccessUiState,
    isOnline: Boolean = true,
    onBack: () -> Unit,
    onSignInDemoGoogle: () -> Unit,
    onSearchQueryChange: (String) -> Unit,
    onRestaurantSelected: (String) -> Unit,
    onCancelSelection: () -> Unit,
    onContactInfoChange: (String) -> Unit,
    onSubmitClaim: () -> Unit,
    onApproveDemo: () -> Unit,
    onOpenDashboard: (String) -> Unit,
    onSignOut: () -> Unit,
    onResetDemo: () -> Unit,
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text(
                            text = "HAPOSTO RISTORATORI",
                            fontWeight = FontWeight.Black,
                            color = MaterialTheme.colorScheme.primary,
                        )
                        Text(
                            text = "Accesso e verifica · prototipo locale",
                            style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                },
                navigationIcon = {
                    TextButton(onClick = onBack) {
                        Text("Indietro")
                    }
                },
            )
        },
    ) { innerPadding ->
        AdaptiveScrollableContent(
            innerPadding = innerPadding,
        ) {
            DemoBanner()
            if (!isOnline) {
                OfflineBanner(
                    body = "La shell locale resta utilizzabile, ma login, claim e approvazione reali richiederanno connessione al backend.",
                )
            }
            AccessProgress(phase = uiState.phase)

            when (uiState.phase) {
                RestaurantAccessPhase.SIGNED_OUT -> SignedOutContent(
                    isBusy = uiState.isBusy,
                    message = uiState.message,
                    onSignInDemoGoogle = onSignInDemoGoogle,
                )

                RestaurantAccessPhase.SEARCH -> SearchContent(
                    uiState = uiState,
                    onSearchQueryChange = onSearchQueryChange,
                    onRestaurantSelected = onRestaurantSelected,
                    onSignOut = onSignOut,
                )

                RestaurantAccessPhase.CLAIM_FORM -> ClaimFormContent(
                    uiState = uiState,
                    onContactInfoChange = onContactInfoChange,
                    onSubmitClaim = onSubmitClaim,
                    onCancelSelection = onCancelSelection,
                )

                RestaurantAccessPhase.PENDING -> PendingContent(
                    uiState = uiState,
                    onApproveDemo = onApproveDemo,
                    onResetDemo = onResetDemo,
                )

                RestaurantAccessPhase.APPROVED -> ApprovedContent(
                    uiState = uiState,
                    onOpenDashboard = onOpenDashboard,
                    onSignOut = onSignOut,
                    onResetDemo = onResetDemo,
                )
            }

            BetaDisclosure()
            Spacer(Modifier.height(8.dp))
        }
    }
}

/** "Passo X di 3": il ristoratore sa sempre dove si trova e quanto manca. */
@Composable
private fun AccessProgress(phase: RestaurantAccessPhase) {
    val (step, title) = when (phase) {
        RestaurantAccessPhase.SIGNED_OUT -> 1 to "Accedi"
        RestaurantAccessPhase.SEARCH -> 2 to "Trova il tuo locale"
        RestaurantAccessPhase.CLAIM_FORM -> 2 to "Conferma che è il tuo locale"
        RestaurantAccessPhase.PENDING -> 3 to "Verifica in corso"
        RestaurantAccessPhase.APPROVED -> 3 to "Fatto: puoi gestire il locale"
    }
    val done = phase == RestaurantAccessPhase.APPROVED
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .semantics(mergeDescendants = true) {},
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Text(
            text = if (done) "✓ $title" else "Passo $step di 3 · $title",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.primary,
        )
        Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            (1..3).forEach { index ->
                val reached = index <= step || done
                Surface(
                    modifier = Modifier
                        .weight(1f)
                        .height(6.dp),
                    color = if (reached) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outlineVariant,
                    shape = MaterialTheme.shapes.small,
                ) {}
            }
        }
    }
}

@Composable
private fun DemoBanner() {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        color = MaterialTheme.colorScheme.tertiaryContainer,
        shape = MaterialTheme.shapes.large,
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            Text(
                text = "STEP 6 · DEMO PRE-BACKEND",
                style = MaterialTheme.typography.labelLarge,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onTertiaryContainer,
            )
            Text(
                text = "Nessuna autenticazione Google reale, nessun documento inviato e nessun dato salvato su server.",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onTertiaryContainer,
            )
        }
    }
}

@Composable
private fun SignedOutContent(
    isBusy: Boolean,
    message: String?,
    onSignInDemoGoogle: () -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Text(
            text = "Gestisci il tuo locale",
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold,
        )
        Text(
            text = "Nella versione reale il ristoratore accederà con Google e poi richiederà la gestione dell'attività. Qui proviamo lo stesso percorso senza provider esterni.",
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )

        Button(
            onClick = onSignInDemoGoogle,
            modifier = Modifier.fillMaxWidth(),
            enabled = !isBusy,
        ) {
            if (isBusy) {
                CircularProgressIndicator()
            } else {
                Text("CONTINUA CON GOOGLE · DEMO LOCALE")
            }
        }
        MessageText(message)
        Text(
            text = "Il pulsante crea soltanto l'identità fittizia ‘Titolare Demo’ in memoria.",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

@Composable
private fun SearchContent(
    uiState: RestaurantAccessUiState,
    onSearchQueryChange: (String) -> Unit,
    onRestaurantSelected: (String) -> Unit,
    onSignOut: () -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
        AccountSummary(uiState)
        Text(
            text = "Trova la tua attività",
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold,
        )
        Text(
            text = "Per questa shell locale mostriamo soltanto partner demo già collegati. Con il backend sarà possibile richiedere anche un locale presente solo in directory.",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        OutlinedTextField(
            value = uiState.searchQuery,
            onValueChange = onSearchQueryChange,
            modifier = Modifier.fillMaxWidth(),
            singleLine = true,
            label = { Text("Cerca nome, città o categoria") },
            placeholder = { Text("Es. Osteria Levante") },
        )

        if (uiState.candidates.isEmpty()) {
            Surface(
                modifier = Modifier.fillMaxWidth(),
                color = MaterialTheme.colorScheme.surfaceVariant,
                shape = MaterialTheme.shapes.large,
            ) {
                Text(
                    text = "Nessun partner demo trovato. Prova un altro termine.",
                    modifier = Modifier.padding(16.dp),
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        } else {
            uiState.candidates.forEach { restaurant ->
                ClaimCandidateCard(
                    restaurant = restaurant,
                    onClick = { onRestaurantSelected(restaurant.id) },
                )
            }
        }

        MessageText(uiState.message)
        TextButton(onClick = onSignOut) {
            Text("Esci dall'identità demo")
        }
    }
}

@Composable
private fun ClaimCandidateCard(
    restaurant: Restaurant,
    onClick: () -> Unit,
) {
    OutlinedCard(modifier = Modifier.fillMaxWidth()) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Top,
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = restaurant.name,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                    )
                    Text(
                        text = "${restaurant.category} · ${restaurant.city}",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
                Surface(
                    color = MaterialTheme.colorScheme.tertiaryContainer,
                    contentColor = MaterialTheme.colorScheme.onTertiaryContainer,
                    shape = MaterialTheme.shapes.small,
                ) {
                    Text(
                        text = "PARTNER DEMO",
                        modifier = Modifier.padding(horizontal = 9.dp, vertical = 6.dp),
                        style = MaterialTheme.typography.labelMedium,
                        fontWeight = FontWeight.Bold,
                    )
                }
            }
            Text(
                text = restaurant.address,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            OutlinedButton(
                onClick = onClick,
                modifier = Modifier.fillMaxWidth(),
            ) {
                Text("QUESTO È IL MIO LOCALE")
            }
        }
    }
}

@Composable
private fun ClaimFormContent(
    uiState: RestaurantAccessUiState,
    onContactInfoChange: (String) -> Unit,
    onSubmitClaim: () -> Unit,
    onCancelSelection: () -> Unit,
) {
    val restaurant = uiState.selectedRestaurant ?: return
    Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
        AccountSummary(uiState)
        Text(
            text = "Richiedi gestione",
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold,
        )
        Surface(
            modifier = Modifier.fillMaxWidth(),
            color = MaterialTheme.colorScheme.surfaceVariant,
            shape = MaterialTheme.shapes.large,
        ) {
            Column(
                modifier = Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(4.dp),
            ) {
                Text(restaurant.name, fontWeight = FontWeight.Bold)
                Text(
                    text = restaurant.address,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
        Text(
            text = "In produzione un amministratore controllerà che tu sia autorizzato a gestire il locale prima di abilitare i pulsanti LIVE.",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        OutlinedTextField(
            value = uiState.contactInfo,
            onValueChange = onContactInfoChange,
            modifier = Modifier.fillMaxWidth(),
            singleLine = true,
            label = { Text("Recapito per la verifica") },
            supportingText = { Text("Telefono o email aziendale · massimo 120 caratteri") },
        )
        Button(
            onClick = onSubmitClaim,
            modifier = Modifier.fillMaxWidth(),
            enabled = !uiState.isBusy && uiState.contactInfo.trim().length >= 3,
        ) {
            if (uiState.isBusy) CircularProgressIndicator() else Text("INVIA RICHIESTA DEMO")
        }
        OutlinedButton(
            onClick = onCancelSelection,
            modifier = Modifier.fillMaxWidth(),
            enabled = !uiState.isBusy,
        ) {
            Text("SCEGLI UN ALTRO LOCALE")
        }
        MessageText(uiState.message)
    }
}

@Composable
private fun PendingContent(
    uiState: RestaurantAccessUiState,
    onApproveDemo: () -> Unit,
    onResetDemo: () -> Unit,
) {
    val claim = uiState.claim ?: return
    val restaurant = uiState.claimRestaurant
    Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
        AccountSummary(uiState)
        StatusCard(
            title = "RICHIESTA IN VERIFICA",
            body = "${restaurant?.name ?: "Locale demo"}\nLa dashboard resta bloccata finché la richiesta non viene approvata.",
        )
        Text(
            text = "Recapito indicato: ${claim.contactInfo}",
            style = MaterialTheme.typography.bodyMedium,
        )
        Text(
            text = "Nella beta reale la verifica sarà manuale: contatto del locale, identità del richiedente e associazione al ristorante. Il client non potrà auto-approvarsi.",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        HorizontalDivider()
        Text(
            text = "Solo per test locale",
            style = MaterialTheme.typography.labelLarge,
            fontWeight = FontWeight.Bold,
        )
        Button(
            onClick = onApproveDemo,
            modifier = Modifier.fillMaxWidth(),
            enabled = !uiState.isBusy,
        ) {
            if (uiState.isBusy) CircularProgressIndicator() else Text("SIMULA APPROVAZIONE ADMIN")
        }
        Text(
            text = "Questo comando esiste soltanto nel repository fake e dovrà sparire dal client di produzione.",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.error,
        )
        MessageText(uiState.message)
        TextButton(onClick = onResetDemo) {
            Text("Azzera il percorso demo")
        }
    }
}

@Composable
private fun ApprovedContent(
    uiState: RestaurantAccessUiState,
    onOpenDashboard: (String) -> Unit,
    onSignOut: () -> Unit,
    onResetDemo: () -> Unit,
) {
    val claim = uiState.claim ?: return
    val restaurant = uiState.claimRestaurant
    Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
        AccountSummary(uiState)
        StatusCard(
            title = "GESTIONE ABILITATA",
            body = "${restaurant?.name ?: "Locale demo"}\nRuolo demo: OWNER",
        )
        Text(
            text = "L'approvazione consente l'accesso alla dashboard soltanto per il ristorante associato al claim.",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        claim.reviewedAt?.let { reviewedAt ->
            Text(
                text = "Approvazione demo: ${formatInstant(reviewedAt)}",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        Button(
            onClick = { onOpenDashboard(claim.restaurantId) },
            modifier = Modifier.fillMaxWidth(),
        ) {
            Text("APRI DASHBOARD")
        }
        MessageText(uiState.message)
        OutlinedButton(
            onClick = onSignOut,
            modifier = Modifier.fillMaxWidth(),
        ) {
            Text("ESCI")
        }
        TextButton(onClick = onResetDemo) {
            Text("Azzera account e claim demo")
        }
    }
}

@Composable
private fun AccountSummary(uiState: RestaurantAccessUiState) {
    val account = uiState.account ?: return
    Surface(
        modifier = Modifier.fillMaxWidth(),
        color = MaterialTheme.colorScheme.secondaryContainer,
        shape = MaterialTheme.shapes.large,
    ) {
        Column(
            modifier = Modifier.padding(14.dp),
            verticalArrangement = Arrangement.spacedBy(2.dp),
        ) {
            Text(
                text = account.displayName,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSecondaryContainer,
            )
            Text(
                text = account.email,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSecondaryContainer,
            )
        }
    }
}

@Composable
private fun StatusCard(
    title: String,
    body: String,
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        color = MaterialTheme.colorScheme.primaryContainer,
        shape = MaterialTheme.shapes.large,
    ) {
        Column(
            modifier = Modifier.padding(18.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            Text(
                text = title,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Black,
                color = MaterialTheme.colorScheme.onPrimaryContainer,
            )
            Text(
                text = body,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onPrimaryContainer,
            )
        }
    }
}

@Composable
private fun MessageText(message: String?) {
    if (!message.isNullOrBlank()) {
        Text(
            text = message,
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.primary,
        )
    }
}

@Composable
private fun BetaDisclosure() {
    HorizontalDivider()
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Text(
            text = "Beta ristoranti",
            style = MaterialTheme.typography.labelLarge,
            fontWeight = FontWeight.Bold,
        )
        Text(
            text = "HAPOSTO sarà gratuito durante la fase beta. Il servizio LIVE per i ristoranti potrà diventare a pagamento al termine della beta. Nessun costo verrà applicato automaticamente senza accettazione.",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

private fun formatInstant(value: java.time.Instant): String =
    DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")
        .withZone(ZoneId.systemDefault())
        .format(value)
