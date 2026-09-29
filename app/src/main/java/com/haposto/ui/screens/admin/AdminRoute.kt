package com.haposto.ui.screens.admin

import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Checkbox
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.PrimaryScrollableTabRow
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Tab
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import com.haposto.data.admin.AdminClaim
import com.haposto.data.admin.AdminRepository
import com.haposto.data.admin.AdminSubscriptionRow
import com.haposto.data.auth.AuthRepository
import com.haposto.data.auth.AuthState
import com.haposto.ui.components.BannerKind
import com.haposto.ui.components.BigActionButton
import com.haposto.ui.components.LabeledValue
import com.haposto.ui.components.MessageBanner
import com.haposto.ui.components.SectionCard
import com.haposto.ui.components.SimpleScreen
import java.time.Duration
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import kotlinx.coroutines.delay

/**
 * Pannello amministratore (nascosto: si apre tenendo premuta 5 secondi la versione in Account).
 * Tre barriere: account marcato admin nel database, verifica in due passaggi, seconda password
 * del pannello. Lo sblocco vale 30 minuti su questo telefono; ogni azione finisce nel registro.
 */
@Composable
fun AdminRoute(
    admin: AdminRepository?,
    auth: AuthRepository,
    onBack: () -> Unit,
    onOpenMfa: () -> Unit,
    onOpenRestaurant: (String) -> Unit,
    onOpenUser: (String) -> Unit,
) {
    val authState = auth.state.collectAsStateWithLifecycle().value
    val signedIn = authState as? AuthState.SignedIn

    if (admin == null) {
        SimpleScreen(title = "Area riservata", onBack = onBack) {
            MessageBanner("Non disponibile in questa versione.")
        }
        return
    }
    if (signedIn == null) {
        SimpleScreen(title = "Area riservata", onBack = onBack) {
            MessageBanner("Accedi prima dall'area Account.")
        }
        return
    }
    if (!signedIn.mfa.verified) {
        SimpleScreen(title = "Area riservata", onBack = onBack) {
            MessageBanner("Serve la verifica in due passaggi attiva e confermata in questa sessione.")
            BigActionButton(text = "Verifica in due passaggi", onClick = onOpenMfa)
        }
        return
    }

    val viewModel: AdminViewModel = viewModel(factory = viewModelFactory { initializer { AdminViewModel(admin) } })
    val state = viewModel.state.collectAsStateWithLifecycle().value
    val status = state.status

    LaunchedEffect(status?.unlockedUntil) {
        while (true) {
            delay(15_000)
            viewModel.checkExpiry()
        }
    }

    when {
        status == null -> SimpleScreen(title = "Area riservata", onBack = onBack) {
            MessageBanner(state.statusError ?: "Controllo…", if (state.statusError != null) BannerKind.ERROR else BannerKind.INFO)
        }
        !status.isAdminAccount -> SimpleScreen(title = "Area riservata", onBack = onBack) {
            MessageBanner("Accesso non consentito.", BannerKind.ERROR)
        }
        !status.isUnlocked -> UnlockScreen(state, onBack, viewModel::unlock)
        else -> AdminHome(state, viewModel, onBack, onOpenRestaurant, onOpenUser)
    }
}

@Composable
private fun UnlockScreen(state: AdminUiState, onBack: () -> Unit, onUnlock: (String, String) -> Unit) {
    var username by rememberSaveable { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    val status = state.status
    SimpleScreen(title = "Area riservata", onBack = onBack) {
        SectionCard(
            title = "Sblocca il pannello",
            subtitle = "Inserisci il nome utente e la password del pannello (diversi da quelli di Google).",
        ) {
            if (status?.hasCredentials == false) {
                MessageBanner("Credenziali del pannello non ancora create: vedi la guida admin (SQL Editor).", BannerKind.ERROR)
            }
            status?.lockedUntil?.let {
                MessageBanner("Bloccato per troppi tentativi fino alle ${TIME.format(it.atZone(ZoneId.systemDefault()))}.", BannerKind.ERROR)
            }
            OutlinedTextField(
                value = username,
                onValueChange = { username = it.take(32) },
                label = { Text("Nome utente") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
            )
            OutlinedTextField(
                value = password,
                onValueChange = { password = it.take(128) },
                label = { Text("Password del pannello") },
                singleLine = true,
                visualTransformation = PasswordVisualTransformation(),
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
                modifier = Modifier.fillMaxWidth(),
            )
            BigActionButton(
                text = if (state.busy) "Verifico…" else "Sblocca",
                enabled = username.isNotBlank() && password.length >= 12 && !state.busy,
                onClick = {
                    onUnlock(username, password)
                    password = ""
                },
            )
        }
        state.message?.let { MessageBanner(it, if (state.messageIsError) BannerKind.ERROR else BannerKind.INFO) }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun AdminHome(
    state: AdminUiState,
    viewModel: AdminViewModel,
    onBack: () -> Unit,
    onOpenRestaurant: (String) -> Unit,
    onOpenUser: (String) -> Unit,
) {
    val remaining = state.status?.unlockedUntil?.let { Duration.between(Instant.now(), it).toMinutes().coerceAtLeast(0) } ?: 0
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Pannello HAPOSTO · ${remaining} min", fontWeight = FontWeight.Bold) },
                navigationIcon = { TextButton(onClick = onBack) { Text("Indietro") } },
                actions = { TextButton(onClick = viewModel::lock) { Text("Blocca") } },
            )
        },
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding),
        ) {
            PrimaryScrollableTabRow(selectedTabIndex = state.tab.ordinal) {
                AdminTab.entries.forEach { tab ->
                    Tab(
                        selected = tab == state.tab,
                        onClick = { viewModel.selectTab(tab) },
                        text = { Text(tab.label) },
                    )
                }
            }
            state.message?.let {
                MessageBanner(
                    it,
                    if (state.messageIsError) BannerKind.ERROR else BannerKind.SUCCESS,
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                )
            }
            when (state.tab) {
                AdminTab.OVERVIEW -> OverviewTab(state)
                AdminTab.CLAIMS -> ClaimsTab(state, viewModel)
                AdminTab.RESTAURANTS -> RestaurantsTab(state, viewModel, onOpenRestaurant)
                AdminTab.USERS -> UsersTab(state, viewModel, onOpenUser)
                AdminTab.SUBSCRIPTIONS -> SubscriptionsTab(state, viewModel)
                AdminTab.PAYMENTS -> PaymentsTab(state)
                AdminTab.LOG -> LogTab(state, viewModel)
                AdminTab.SETTINGS -> SettingsTab(state, viewModel)
            }
        }
    }

    state.issuedCode?.let { (claim, code) ->
        AlertDialog(
            onDismissRequest = viewModel::dismissCode,
            title = { Text("Codice per ${claim.restaurantName}") },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text(
                        code.chunked(3).joinToString(" "),
                        fontSize = 40.sp,
                        fontWeight = FontWeight.Black,
                        fontFamily = FontFamily.Monospace,
                    )
                    Text("Chiama il numero PUBBLICO del locale: ${claim.restaurantPhone ?: "cercalo su Google Maps o sul sito del locale"}.")
                    Text("Detta il codice solo a chi risponde al telefono del locale. Vale 48 ore, 5 tentativi. Non verrà più mostrato.")
                }
            },
            confirmButton = { TextButton(onClick = viewModel::dismissCode) { Text("Fatto") } },
        )
    }
}

@Composable
private fun AdminList(content: androidx.compose.foundation.lazy.LazyListScope.() -> Unit) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = androidx.compose.foundation.layout.PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
        content = content,
    )
}

@Composable
private fun RowCard(onClick: (() -> Unit)? = null, content: @Composable () -> Unit) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .then(if (onClick != null) Modifier.clickable(onClick = onClick) else Modifier),
        shape = MaterialTheme.shapes.medium,
        color = MaterialTheme.colorScheme.surfaceVariant,
    ) {
        Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) { content() }
    }
}

@Composable
private fun OverviewTab(state: AdminUiState) {
    AdminList {
        val entries = state.overview?.entries.orEmpty()
        if (entries.isEmpty()) item { Text("Carico…") }
        items(entries) { (label, value) ->
            RowCard { LabeledValue(label, value) }
        }
    }
}

@Composable
private fun ClaimsTab(state: AdminUiState, viewModel: AdminViewModel) {
    var reviewing by remember { mutableStateOf<Pair<AdminClaim, Boolean>?>(null) }
    AdminList {
        if (state.claims.isEmpty()) item { Text("Nessuna richiesta da verificare. 🎉") }
        items(state.claims, key = { it.claimId }) { claim ->
            RowCard {
                Text(claim.restaurantName, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
                Text("${claim.restaurantAddress}, ${claim.restaurantCity}", style = MaterialTheme.typography.bodySmall)
                Text("Telefono pubblico: ${claim.restaurantPhone ?: "non presente"}", style = MaterialTheme.typography.bodySmall)
                Text("Richiedente: ${claim.requesterName ?: ""} ${claim.requesterEmail} · recapito ${claim.contactInfo}", style = MaterialTheme.typography.bodySmall)
                if (claim.currentOwners > 0) {
                    Text("⚠ Il locale ha già ${claim.currentOwners} titolare/i: possibile cambio di gestione.", color = MaterialTheme.colorScheme.error)
                }
                Text(
                    when {
                        claim.phoneVerified -> "✓ Verifica telefonica completata"
                        claim.phoneCodeActive -> "Codice inviato, in attesa che il richiedente lo inserisca"
                        else -> "Da verificare al telefono"
                    },
                    style = MaterialTheme.typography.labelLarge,
                    fontWeight = FontWeight.SemiBold,
                )
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    if (!claim.phoneVerified) {
                        OutlinedButton(onClick = { viewModel.issueCode(claim) }, enabled = !state.busy) {
                            Text(if (claim.phoneCodeActive) "Nuovo codice" else "Genera codice")
                        }
                    }
                    OutlinedButton(onClick = { reviewing = claim to true }, enabled = !state.busy) { Text("Approva") }
                    TextButton(onClick = { reviewing = claim to false }, enabled = !state.busy) { Text("Rifiuta") }
                }
            }
        }
    }
    reviewing?.let { (claim, approve) ->
        ReviewDialog(
            claim = claim,
            approve = approve,
            onDismiss = { reviewing = null },
            onConfirm = { note, skip ->
                viewModel.reviewClaim(claim, approve, note, skip)
                reviewing = null
            },
        )
    }
}

@Composable
private fun ReviewDialog(claim: AdminClaim, approve: Boolean, onDismiss: () -> Unit, onConfirm: (String, Boolean) -> Unit) {
    var note by rememberSaveable { mutableStateOf("") }
    var skip by rememberSaveable { mutableStateOf(false) }
    val needsSkip = approve && !claim.phoneVerified
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(if (approve) "Approvare ${claim.restaurantName}?" else "Rifiutare la richiesta?") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedTextField(
                    value = note,
                    onValueChange = { note = it.take(500) },
                    label = { Text(if (approve) "Nota (es. verificato al telefono)" else "Motivo (lo vede il richiedente)") },
                )
                if (needsSkip) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Checkbox(checked = skip, onCheckedChange = { skip = it })
                        Text("Approvo senza codice telefonico (es. verificato di persona). Serve una nota.")
                    }
                }
            }
        },
        confirmButton = {
            TextButton(
                onClick = { onConfirm(note, skip) },
                enabled = !needsSkip || (skip && note.trim().length >= 5),
            ) { Text(if (approve) "Approva" else "Rifiuta") }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Annulla") } },
    )
}

@Composable
private fun SearchBar(placeholder: String, filters: List<Pair<String?, String>>, onSearch: (String, String?) -> Unit) {
    var query by rememberSaveable(placeholder) { mutableStateOf("") }
    var filter by rememberSaveable(placeholder) { mutableStateOf(filters.firstOrNull()?.first) }
    Column(Modifier.padding(horizontal = 16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            OutlinedTextField(
                value = query,
                onValueChange = { query = it.take(80) },
                label = { Text(placeholder) },
                singleLine = true,
                modifier = Modifier.weight(1f),
            )
            TextButton(onClick = { onSearch(query, filter) }) { Text("Cerca") }
        }
        Row(
            Modifier
                .fillMaxWidth()
                .horizontalScroll(rememberScrollState()),
            horizontalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            filters.forEach { (value, label) ->
                FilterChip(
                    selected = filter == value,
                    onClick = {
                        filter = value
                        onSearch(query, value)
                    },
                    label = { Text(label) },
                )
            }
        }
    }
}

@Composable
private fun RestaurantsTab(state: AdminUiState, viewModel: AdminViewModel, onOpenRestaurant: (String) -> Unit) {
    Column {
        SearchBar(
            placeholder = "Nome, città, id o slug",
            filters = listOf(null to "Tutti", "CLAIM_PENDING" to "In verifica", "ACTIVE_PARTNER" to "Partner", "DIRECTORY_ONLY" to "Solo directory", "SUSPENDED" to "Sospesi"),
            onSearch = { q, f -> viewModel.loadTab(AdminTab.RESTAURANTS, q, f) },
        )
        AdminList {
            items(state.restaurants, key = { it.restaurantId }) { row ->
                RowCard(onClick = { onOpenRestaurant(row.restaurantId) }) {
                    Text(row.name, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
                    Text("${row.city} · ${statusLabel(row.partnershipStatus)} · ${planLabel(row.planCode)} · ${row.members} membri", style = MaterialTheme.typography.bodySmall)
                    Text("Ultimo stato: ${row.lastPublishAt?.let { DATE_TIME.format(it.atZone(ZoneId.systemDefault())) } ?: "mai"} · ${row.dataSource}", style = MaterialTheme.typography.bodySmall)
                }
            }
        }
    }
}

@Composable
private fun UsersTab(state: AdminUiState, viewModel: AdminViewModel, onOpenUser: (String) -> Unit) {
    Column {
        SearchBar(
            placeholder = "Email, nome o id",
            filters = listOf("ALL" to "Tutti", "RESTAURANT" to "Ristoratori", "PLUS" to "Plus", "BLOCKED" to "Sospesi", "ADMINS" to "Admin"),
            onSearch = { q, f -> viewModel.loadTab(AdminTab.USERS, q, f) },
        )
        AdminList {
            items(state.users, key = { it.userId }) { user ->
                RowCard(onClick = { onOpenUser(user.userId) }) {
                    Text(user.email, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
                    Text(
                        listOfNotNull(
                            user.displayName,
                            if (user.consumerPlan == "CONSUMER_PLUS") "Plus" else null,
                            if (user.restaurants > 0) "${user.restaurants} locali" else null,
                            if (user.isAdmin) "ADMIN" else null,
                            if (user.blockedAt != null) "SOSPESO" else null,
                        ).joinToString(" · ").ifEmpty { "Utente" },
                        style = MaterialTheme.typography.bodySmall,
                    )
                }
            }
        }
    }
}

@Composable
private fun SubscriptionsTab(state: AdminUiState, viewModel: AdminViewModel) {
    var confirm by remember { mutableStateOf<AdminSubscriptionRow?>(null) }
    Column {
        SearchBar(
            placeholder = "Filtra",
            filters = listOf("ALL" to "Tutti", "RESTAURANT" to "Ristoranti", "CONSUMER" to "Utenti Plus"),
            onSearch = { _, f -> viewModel.loadTab(AdminTab.SUBSCRIPTIONS, null, f) },
        )
        AdminList {
            items(state.subscriptions, key = { it.subscriptionId }) { row ->
                RowCard {
                    Text(row.subjectName, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
                    Text("${planLabel(row.planCode)} · ${row.status} · ${row.provider}", style = MaterialTheme.typography.bodySmall)
                    row.periodEnd?.let { Text("Fino al ${DATE.format(it.atZone(ZoneId.systemDefault()))}", style = MaterialTheme.typography.bodySmall) }
                    if (row.isLive && row.isManual) {
                        TextButton(onClick = { confirm = row }) { Text("Chiudi") }
                    }
                }
            }
        }
    }
    confirm?.let { row ->
        AlertDialog(
            onDismissRequest = { confirm = null },
            title = { Text("Chiudere l'abbonamento di ${row.subjectName}?") },
            text = { Text("Il piano torna subito a quello gratuito.") },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.cancelSubscription(row)
                    confirm = null
                }) { Text("Chiudi") }
            },
            dismissButton = { TextButton(onClick = { confirm = null }) { Text("Annulla") } },
        )
    }
}

@Composable
private fun PaymentsTab(state: AdminUiState) {
    AdminList {
        if (state.payments.isEmpty()) item { Text("Nessun pagamento registrato.") }
        items(state.payments, key = { it.paymentId }) { payment ->
            RowCard {
                Text(
                    "€ %d,%02d · %s".format(payment.amountCents / 100, payment.amountCents % 100, payment.status),
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.Bold,
                )
                Text("${payment.payerName} · ${payment.provider} · ${planLabel(payment.planCode.orEmpty())}", style = MaterialTheme.typography.bodySmall)
                Text(
                    "${payment.paidAt?.let { DATE_TIME.format(it.atZone(ZoneId.systemDefault())) }.orEmpty()} · fattura ${payment.invoiceNumber ?: "da emettere"}",
                    style = MaterialTheme.typography.bodySmall,
                )
            }
        }
    }
}

@Composable
private fun LogTab(state: AdminUiState, viewModel: AdminViewModel) {
    Column {
        SearchBar(
            placeholder = "Tipo di operazione (es. CLAIM, ADMIN, USER)",
            filters = emptyList(),
            onSearch = { q, _ -> viewModel.loadTab(AdminTab.LOG, q) },
        )
        AdminList {
            items(state.audit, key = { it.logId }) { row ->
                RowCard {
                    Text(row.action, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold, fontFamily = FontFamily.Monospace)
                    Text(
                        "${row.createdAt?.let { DATE_TIME.format(it.atZone(ZoneId.systemDefault())) }.orEmpty()} · ${row.actorKind} ${row.actorEmail.orEmpty()}",
                        style = MaterialTheme.typography.bodySmall,
                    )
                    listOfNotNull(row.restaurantName, row.targetEmail).takeIf { it.isNotEmpty() }?.let {
                        Text(it.joinToString(" · "), style = MaterialTheme.typography.bodySmall)
                    }
                    if (row.details.length > 2) {
                        Text(row.details.take(300), style = MaterialTheme.typography.bodySmall, fontFamily = FontFamily.Monospace)
                    }
                }
            }
        }
    }
}

@Composable
private fun SettingsTab(state: AdminUiState, viewModel: AdminViewModel) {
    AdminList {
        item {
            Text(
                "Impostazioni lette dall'app e dal database. Scrivi JSON valido. Ogni modifica finisce nel registro.",
                style = MaterialTheme.typography.bodySmall,
            )
        }
        items(state.config, key = { it.key }) { entry ->
            var value by rememberSaveable(entry.key, entry.valueJson) { mutableStateOf(entry.valueJson) }
            RowCard {
                Text(entry.key, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold, fontFamily = FontFamily.Monospace)
                entry.description?.let { Text(it, style = MaterialTheme.typography.bodySmall) }
                OutlinedTextField(
                    value = value,
                    onValueChange = { value = it },
                    textStyle = MaterialTheme.typography.bodySmall.copy(fontFamily = FontFamily.Monospace),
                    modifier = Modifier.fillMaxWidth(),
                )
                OutlinedButton(
                    onClick = { viewModel.setConfig(entry.key, value) },
                    enabled = value != entry.valueJson && !state.busy,
                ) { Text("Salva") }
            }
        }
    }
}

internal fun statusLabel(status: String): String = when (status) {
    "ACTIVE_PARTNER" -> "Partner"
    "CLAIM_PENDING" -> "In verifica"
    "DIRECTORY_ONLY" -> "Solo directory"
    "SUSPENDED" -> "Sospeso"
    "PAUSED" -> "In pausa"
    else -> status
}

internal fun planLabel(code: String): String = when (code) {
    "RESTAURANT_BASIC" -> "Basic"
    "RESTAURANT_PRO" -> "Pro"
    "RESTAURANT_PRO_PLUS" -> "Pro+"
    "CONSUMER_FREE" -> "Gratis"
    "CONSUMER_PLUS" -> "Plus"
    else -> code
}

internal val DATE: DateTimeFormatter = DateTimeFormatter.ofPattern("dd/MM/yyyy")
internal val DATE_TIME: DateTimeFormatter = DateTimeFormatter.ofPattern("dd/MM/yy HH:mm")
private val TIME: DateTimeFormatter = DateTimeFormatter.ofPattern("HH:mm")
