package com.haposto.ui.screens.account

import android.Manifest
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import com.haposto.config.AppConfig
import com.haposto.data.Outcome
import com.haposto.data.auth.AuthRepository
import com.haposto.data.auth.AuthState
import com.haposto.data.auth.GoogleIdToken
import com.haposto.data.auth.UserProfile
import com.haposto.platform.notifications.HaPostoNotifications
import com.haposto.platform.notifications.PushMessaging
import com.haposto.ui.components.BannerKind
import com.haposto.ui.components.BigActionButton
import com.haposto.ui.components.GoogleSignInButton
import com.haposto.ui.components.LabeledValue
import com.haposto.ui.components.MessageBanner
import com.haposto.ui.components.SectionCard
import com.haposto.ui.components.SimpleScreen
import com.haposto.ui.components.TermsAcceptanceCard
import com.haposto.ui.components.secretLongPress
import com.haposto.ui.screens.legal.LegalDocument
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

data class AccountUiState(
    val available: Boolean = false,
    val auth: AuthState = AuthState.Loading,
    val profile: UserProfile? = null,
    val busy: Boolean = false,
    val message: String? = null,
    val messageIsError: Boolean = false,
)

class AccountViewModel(private val auth: AuthRepository) : ViewModel() {
    private val profile = MutableStateFlow<UserProfile?>(null)
    private val busy = MutableStateFlow(false)
    private val message = MutableStateFlow<Pair<String, Boolean>?>(null)

    val uiState = combine(auth.state, profile, busy, message) { state, userProfile, isBusy, msg ->
        AccountUiState(
            available = auth.isAvailable,
            auth = state,
            profile = if (state is AuthState.SignedIn) userProfile else null,
            busy = isBusy,
            message = msg?.first,
            messageIsError = msg?.second == true,
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), AccountUiState(available = auth.isAvailable))

    init {
        viewModelScope.launch {
            auth.state.collect { state ->
                if (state is AuthState.SignedIn) reloadProfile() else profile.value = null
            }
        }
    }

    private suspend fun reloadProfile() {
        profile.value = auth.loadProfile().valueOrNull
    }

    fun onGoogleResult(result: Outcome<com.haposto.data.auth.GoogleIdToken>) = launchBusy {
        when (result) {
            is Outcome.Failure -> show(result.message, error = result.code != "GOOGLE_SIGN_IN_CANCELLED")
            is Outcome.Success -> signIn(result.value)
        }
    }

    private suspend fun signIn(token: GoogleIdToken) {
        when (val outcome = auth.signInWithGoogle(token)) {
            is Outcome.Success -> show("✓ Accesso eseguito.")
            is Outcome.Failure -> show(outcome.message, error = true)
        }
    }

    fun acceptTerms(marketing: Boolean) = launchBusy {
        val version = profile.value?.currentTermsVersion ?: DEFAULT_TERMS_VERSION
        val result = auth.acceptTerms(version)
        if (result is Outcome.Success && marketing) auth.setMarketingConsent(true)
        report(result, "✓ Grazie, tutto pronto.")
        reloadProfile()
    }

    fun setMarketing(optIn: Boolean) = launchBusy {
        report(auth.setMarketingConsent(optIn), if (optIn) "✓ Riceverai le novità." else "✓ Non riceverai più comunicazioni.")
        reloadProfile()
    }

    fun setNotifications(reminders: Boolean? = null, alerts: Boolean? = null, claims: Boolean? = null) = launchBusy {
        report(auth.setNotificationPrefs(reminders, alerts, claims), "✓ Preferenze salvate.")
        reloadProfile()
    }

    fun signOut(everywhere: Boolean) = launchBusy {
        runCatching { PushMessaging.unregisterCurrentDevice() }
        report(
            auth.signOut(everywhere),
            if (everywhere) "✓ Sei uscito da tutti i dispositivi." else "✓ Sei uscito.",
        )
    }

    fun deleteAccount() = launchBusy {
        runCatching { PushMessaging.unregisterCurrentDevice() }
        report(auth.deleteAccount(), "✓ Account eliminato. I preferiti restano solo su questo telefono.")
    }

    fun clearMessage() {
        message.value = null
    }

    private fun show(text: String, error: Boolean = false) {
        message.value = text to error
    }

    private fun report(result: Outcome<*>, success: String) {
        when (result) {
            is Outcome.Success -> show(success)
            is Outcome.Failure -> show(result.message, error = true)
        }
    }

    private fun launchBusy(block: suspend () -> Unit) {
        viewModelScope.launch {
            busy.value = true
            message.value = null
            block()
            busy.value = false
        }
    }

    companion object {
        const val DEFAULT_TERMS_VERSION = "2026-10"
    }
}

@Composable
fun AccountRoute(
    auth: AuthRepository,
    onOpenDocument: (LegalDocument) -> Unit,
    onOpenMfa: () -> Unit,
    onOpenPlus: () -> Unit,
    onOpenAdmin: () -> Unit,
) {
    val viewModel: AccountViewModel = viewModel(factory = viewModelFactory { initializer { AccountViewModel(auth) } })
    val state = viewModel.uiState.collectAsStateWithLifecycle().value
    AccountScreen(
        state = state,
        onGoogleResult = viewModel::onGoogleResult,
        onAcceptTerms = viewModel::acceptTerms,
        onMarketingChange = viewModel::setMarketing,
        onRemindersChange = { viewModel.setNotifications(reminders = it) },
        onAlertsChange = { viewModel.setNotifications(alerts = it) },
        onClaimsChange = { viewModel.setNotifications(claims = it) },
        onSignOut = { viewModel.signOut(everywhere = false) },
        onSignOutEverywhere = { viewModel.signOut(everywhere = true) },
        onDeleteAccount = viewModel::deleteAccount,
        onOpenDocument = onOpenDocument,
        onOpenMfa = onOpenMfa,
        onOpenPlus = onOpenPlus,
        onOpenAdmin = onOpenAdmin,
    )
}

@Composable
fun AccountScreen(
    state: AccountUiState,
    onGoogleResult: (Outcome<GoogleIdToken>) -> Unit,
    onAcceptTerms: (Boolean) -> Unit,
    onMarketingChange: (Boolean) -> Unit,
    onRemindersChange: (Boolean) -> Unit,
    onAlertsChange: (Boolean) -> Unit,
    onClaimsChange: (Boolean) -> Unit,
    onSignOut: () -> Unit,
    onSignOutEverywhere: () -> Unit,
    onDeleteAccount: () -> Unit,
    onOpenDocument: (LegalDocument) -> Unit,
    onOpenMfa: () -> Unit,
    onOpenPlus: () -> Unit,
    onOpenAdmin: () -> Unit,
) {
    SimpleScreen(title = "Account", onBack = null) {
        state.message?.let { MessageBanner(it, if (state.messageIsError) BannerKind.ERROR else BannerKind.SUCCESS) }

        val signedIn = state.auth as? AuthState.SignedIn
        when {
            !state.available -> SectionCard(
                title = "Versione dimostrativa",
                subtitle = "In questa versione non ci sono account veri: tutto resta sul telefono. " +
                    "Cerca, salva i preferiti e prova l'area ristoratore simulata.",
            ) {}
            state.auth is AuthState.Loading -> MessageBanner("Controllo l'accesso…")
            signedIn == null -> SignedOutContent(state.busy, onGoogleResult)
            else -> SignedInContent(
                state = state,
                email = signedIn.user.email.orEmpty(),
                displayName = state.profile?.displayName ?: signedIn.user.displayName,
                mfaEnrolled = signedIn.mfa.enrolled,
                onAcceptTerms = onAcceptTerms,
                onMarketingChange = onMarketingChange,
                onRemindersChange = onRemindersChange,
                onAlertsChange = onAlertsChange,
                onClaimsChange = onClaimsChange,
                onSignOut = onSignOut,
                onSignOutEverywhere = onSignOutEverywhere,
                onDeleteAccount = onDeleteAccount,
                onOpenDocument = onOpenDocument,
                onOpenMfa = onOpenMfa,
                onOpenPlus = onOpenPlus,
            )
        }

        InformationSection(onOpenDocument = onOpenDocument, onOpenAdmin = onOpenAdmin)
        Spacer(Modifier.height(16.dp))
    }
}

@Composable
private fun SignedOutContent(busy: Boolean, onGoogleResult: (Outcome<GoogleIdToken>) -> Unit) {
    SectionCard(
        title = "Accedi (facoltativo)",
        subtitle = "Per cercare dove c'è posto non serve un account. Accedendo puoi:",
    ) {
        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Text("• ritrovare i preferiti su tutti i tuoi telefoni", style = MaterialTheme.typography.bodyMedium)
            Text("• ricevere l'avviso quando si libera un posto (Plus)", style = MaterialTheme.typography.bodyMedium)
            Text("• gestire il tuo locale, se sei un ristoratore", style = MaterialTheme.typography.bodyMedium)
        }
        GoogleSignInButton(onResult = onGoogleResult, enabled = !busy)
        Text(
            "Usiamo solo nome ed email del tuo account Google. Nessuna password viene salvata da HAPOSTO.",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

@Composable
private fun SignedInContent(
    state: AccountUiState,
    email: String,
    displayName: String?,
    mfaEnrolled: Boolean,
    onAcceptTerms: (Boolean) -> Unit,
    onMarketingChange: (Boolean) -> Unit,
    onRemindersChange: (Boolean) -> Unit,
    onAlertsChange: (Boolean) -> Unit,
    onClaimsChange: (Boolean) -> Unit,
    onSignOut: () -> Unit,
    onSignOutEverywhere: () -> Unit,
    onDeleteAccount: () -> Unit,
    onOpenDocument: (LegalDocument) -> Unit,
    onOpenMfa: () -> Unit,
    onOpenPlus: () -> Unit,
) {
    val profile = state.profile
    Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
        Text("Ciao${displayName?.let { ", $it" }.orEmpty()}", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
        Text(email, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }

    if (profile?.blocked == true) {
        MessageBanner(
            "Il tuo account è sospeso${profile.blockedReason?.let { ": $it" }.orEmpty()}. Scrivi a info@haposto.app.",
            BannerKind.ERROR,
        )
    }

    if (profile != null && profile.needsTerms) {
        TermsAcceptanceCard(
            needsUserTerms = true,
            needsRestaurantTerms = false,
            isBusy = state.busy,
            onOpenDocument = onOpenDocument,
            onAccept = onAcceptTerms,
        )
    }

    SectionCard(title = "Il tuo piano") {
        val plus = profile?.hasPlus == true
        LabeledValue("Piano", if (plus) "HAPOSTO Plus" else "Gratis")
        profile?.consumerPlanUntil?.takeIf { plus }?.let {
            LabeledValue("Valido fino al", DATE.format(it.atZone(ZoneId.systemDefault())))
        }
        OutlinedButton(onClick = onOpenPlus, modifier = Modifier.fillMaxWidth()) {
            Text(if (plus) "Gestisci HAPOSTO Plus" else "Scopri HAPOSTO Plus")
        }
    }

    SectionCard(
        title = "Sicurezza",
        subtitle = if (mfaEnrolled) "✓ Verifica in due passaggi attiva." else "Consigliata per tutti, obbligatoria per chi gestisce un locale.",
    ) {
        if (!mfaEnrolled) {
            OutlinedButton(onClick = onOpenMfa, modifier = Modifier.fillMaxWidth()) { Text("Attiva la verifica in due passaggi") }
        }
        OutlinedButton(onClick = onSignOutEverywhere, enabled = !state.busy, modifier = Modifier.fillMaxWidth()) {
            Text("Esci da tutti i dispositivi")
        }
    }

    if (profile != null) {
        NotificationsSection(profile, state.busy, onRemindersChange, onAlertsChange, onClaimsChange)
        SectionCard(title = "Privacy") {
            SwitchRow(
                text = "Ricevi via email le novità di HAPOSTO",
                checked = profile.marketingOptIn,
                enabled = !state.busy,
                onChange = onMarketingChange,
            )
            Text(
                "Per una copia dei tuoi dati scrivi a privacy@haposto.app.",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }

    OutlinedButton(onClick = onSignOut, enabled = !state.busy, modifier = Modifier.fillMaxWidth()) { Text("Esci") }
    DeleteAccountButton(enabled = !state.busy, onConfirm = onDeleteAccount)
}

@Composable
private fun NotificationsSection(
    profile: UserProfile,
    busy: Boolean,
    onRemindersChange: (Boolean) -> Unit,
    onAlertsChange: (Boolean) -> Unit,
    onClaimsChange: (Boolean) -> Unit,
) {
    val context = LocalContext.current
    var permissionGranted by remember { mutableStateOf(HaPostoNotifications.canPost(context)) }
    val launcher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        permissionGranted = granted
    }
    SectionCard(title = "Notifiche") {
        if (!permissionGranted && Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            MessageBanner("Le notifiche sono spente per HAPOSTO su questo telefono.")
            OutlinedButton(
                onClick = { launcher.launch(Manifest.permission.POST_NOTIFICATIONS) },
                modifier = Modifier.fillMaxWidth(),
            ) { Text("Consenti le notifiche") }
        }
        SwitchRow("Avvisi \"c'è posto\" (Plus)", profile.notifyAvailabilityAlerts, !busy, onAlertsChange)
        if (profile.restaurants > 0) {
            SwitchRow("Promemoria per aggiornare lo stato del mio locale", profile.notifyManagerReminders, !busy, onRemindersChange)
        }
        SwitchRow("Esito delle richieste di gestione", profile.notifyClaimUpdates, !busy, onClaimsChange)
    }
}

@Composable
private fun SwitchRow(text: String, checked: Boolean, enabled: Boolean, onChange: (Boolean) -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = 48.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(text, style = MaterialTheme.typography.bodyMedium, modifier = Modifier.weight(1f))
        Switch(checked = checked, onCheckedChange = onChange, enabled = enabled)
    }
}

@Composable
private fun DeleteAccountButton(enabled: Boolean, onConfirm: () -> Unit) {
    var open by rememberSaveable { mutableStateOf(false) }
    var typed by rememberSaveable { mutableStateOf("") }
    TextButton(onClick = { open = true }, enabled = enabled, modifier = Modifier.fillMaxWidth()) {
        Text("Elimina account", color = MaterialTheme.colorScheme.error)
    }
    if (open) {
        AlertDialog(
            onDismissRequest = { open = false },
            title = { Text("Eliminare l'account?") },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(
                        "Cancelliamo account, preferiti sincronizzati, avvisi e consensi. Se gestisci un locale da solo, " +
                            "il locale torna \"non collegato\". I pagamenti restano registrati (obbligo di legge) senza il tuo nome. " +
                            "Se hai Plus, prima disdicilo su Google Play.",
                    )
                    OutlinedTextField(
                        value = typed,
                        onValueChange = { typed = it },
                        label = { Text("Scrivi ELIMINA per confermare") },
                        singleLine = true,
                    )
                }
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        open = false
                        typed = ""
                        onConfirm()
                    },
                    enabled = typed.trim().equals("ELIMINA", ignoreCase = true),
                ) { Text("Elimina definitivamente", color = MaterialTheme.colorScheme.error) }
            },
            dismissButton = { TextButton(onClick = { open = false }) { Text("Annulla") } },
        )
    }
}

@Composable
private fun InformationSection(onOpenDocument: (LegalDocument) -> Unit, onOpenAdmin: () -> Unit) {
    SectionCard(title = "Informazioni") {
        LegalDocument.entries.filter { it != LegalDocument.COOKIES }.forEach { document ->
            TextButton(onClick = { onOpenDocument(document) }) { Text(document.title) }
        }
        Text(
            "Contatti: info@haposto.app · ${AppConfig.publicSiteUrl.removePrefix("https://")}",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        // Tenendo premuto 5 secondi si apre l'accesso al pannello amministratore (nessun segno visibile).
        Text(
            text = "HAPOSTO ${AppConfig.versionName} (${AppConfig.versionCode})" +
                (AppConfig.environment.badge?.let { " · $it" } ?: ""),
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(min = 48.dp)
                .secretLongPress(onTriggered = onOpenAdmin),
        )
    }
}

private val DATE: DateTimeFormatter = DateTimeFormatter.ofPattern("dd/MM/yyyy")
