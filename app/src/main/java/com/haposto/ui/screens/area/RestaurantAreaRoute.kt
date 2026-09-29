package com.haposto.ui.screens.area

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import com.haposto.data.Outcome
import com.haposto.data.auth.AuthRepository
import com.haposto.data.auth.AuthState
import com.haposto.data.auth.GoogleIdToken
import com.haposto.data.auth.UserProfile
import com.haposto.data.location.LocationSession
import com.haposto.data.restaurant.ClaimStatus
import com.haposto.data.restaurant.ManagedRestaurant
import com.haposto.data.restaurant.MemberRole
import com.haposto.data.restaurant.MyClaim
import com.haposto.data.restaurant.RestaurantManagementRepository
import com.haposto.domain.model.PartnershipStatus
import com.haposto.domain.model.Restaurant
import com.haposto.ui.components.BannerKind
import com.haposto.ui.components.BigActionButton
import com.haposto.ui.components.GoogleSignInButton
import com.haposto.ui.components.InfoDisclosure
import com.haposto.ui.components.MessageBanner
import com.haposto.ui.components.SectionCard
import com.haposto.ui.components.SimpleScreen
import com.haposto.ui.components.TermsAcceptanceCard
import com.haposto.ui.screens.legal.LegalDocument
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

data class AreaData(
    val profile: UserProfile? = null,
    val restaurants: List<ManagedRestaurant> = emptyList(),
    val claims: List<MyClaim> = emptyList(),
    val loaded: Boolean = false,
)

data class AreaUiState(
    val auth: AuthState = AuthState.Loading,
    val data: AreaData = AreaData(),
    val searchResults: List<Restaurant> = emptyList(),
    val searching: Boolean = false,
    val busy: Boolean = false,
    val message: String? = null,
    val messageIsError: Boolean = false,
)

class RestaurantAreaViewModel(
    private val auth: AuthRepository,
    private val management: RestaurantManagementRepository,
    private val locationSession: LocationSession,
) : ViewModel() {

    private val data = MutableStateFlow(AreaData())
    private val search = MutableStateFlow<Pair<Boolean, List<Restaurant>>>(false to emptyList())
    private val busy = MutableStateFlow(false)
    private val message = MutableStateFlow<Pair<String, Boolean>?>(null)

    val uiState = combine(auth.state, data, search, busy, message) { state, areaData, results, isBusy, msg ->
        AreaUiState(
            auth = state,
            data = if (state is AuthState.SignedIn) areaData else AreaData(),
            searching = results.first,
            searchResults = results.second,
            busy = isBusy,
            message = msg?.first,
            messageIsError = msg?.second == true,
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), AreaUiState())

    init {
        viewModelScope.launch {
            auth.state.collect { state -> if (state is AuthState.SignedIn) reload() else data.value = AreaData() }
        }
    }

    fun reload() {
        viewModelScope.launch {
            val profile = auth.loadProfile().valueOrNull
            val restaurants = management.myRestaurants().valueOrNull.orEmpty()
            val claims = management.myClaims().valueOrNull.orEmpty()
            data.value = AreaData(profile, restaurants, claims, loaded = true)
        }
    }

    fun onGoogleResult(result: Outcome<GoogleIdToken>) = launchBusy {
        when (result) {
            is Outcome.Failure -> show(result.message, error = result.code != "GOOGLE_SIGN_IN_CANCELLED")
            is Outcome.Success -> (auth.signInWithGoogle(result.value) as? Outcome.Failure)?.let { show(it.message, true) }
        }
    }

    fun acceptTerms(marketing: Boolean) = launchBusy {
        val profile = data.value.profile
        if (profile?.needsTerms == true) {
            val result = auth.acceptTerms(profile.currentTermsVersion ?: DEFAULT_VERSION)
            if (result is Outcome.Failure) {
                show(result.message, true)
                return@launchBusy
            }
            if (marketing) auth.setMarketingConsent(true)
        }
        if (profile?.needsRestaurantTerms != false) {
            val result = auth.acceptRestaurantTerms(profile?.currentRestaurantTermsVersion ?: DEFAULT_VERSION, true)
            if (result is Outcome.Failure) show(result.message, true)
        }
        reload()
    }

    fun search(query: String) {
        viewModelScope.launch {
            search.value = true to search.value.second
            val results = management.searchDirectory(query, locationSession.origin.value.point).valueOrNull.orEmpty()
            search.value = false to results
        }
    }

    fun submitClaim(restaurant: Restaurant, contact: String) = launchBusy {
        when (val result = management.submitClaim(restaurant.id, contact)) {
            is Outcome.Success -> {
                show("✓ Richiesta inviata. HAPOSTO chiamerà il numero pubblico del locale per darti un codice.")
                search.value = false to emptyList()
            }
            is Outcome.Failure -> show(result.message, true)
        }
        reload()
    }

    fun cancelClaim(claimId: String) = launchBusy {
        report(management.cancelClaim(claimId), "Richiesta ritirata.")
        reload()
    }

    fun verifyCode(claimId: String, code: String) = launchBusy {
        when (val result = management.verifyClaimCode(claimId, code)) {
            is Outcome.Failure -> show(result.message, true)
            is Outcome.Success -> {
                val check = result.value
                if (check.ok) {
                    show("✓ Codice corretto: ora HAPOSTO completa la verifica e ti avvisa.")
                } else {
                    val base = com.haposto.data.ErrorMessages.messageFor(check.errorCode ?: "WRONG_CODE")
                    show(if (check.attemptsLeft > 0) "$base Tentativi rimasti: ${check.attemptsLeft}." else base, true)
                }
            }
        }
        reload()
    }

    private fun show(text: String, error: Boolean = false) {
        message.value = text to error
    }

    private fun report(result: Outcome<*>, success: String) = when (result) {
        is Outcome.Success -> show(success)
        is Outcome.Failure -> show(result.message, true)
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
        const val DEFAULT_VERSION = "2026-10"
    }
}

/**
 * Area ristoratore con account vero (DEV/PROD), in 4 passi numerati:
 * 1 accedi con Google · 2 accetta le condizioni e proteggi l'account (2FA) · 3 trova il locale ·
 * 4 verifica telefonica, poi la dashboard.
 */
@Composable
fun RestaurantAreaRoute(
    auth: AuthRepository,
    management: RestaurantManagementRepository,
    locationSession: LocationSession,
    onOpenDashboard: (String) -> Unit,
    onOpenMfa: () -> Unit,
    onOpenDocument: (LegalDocument) -> Unit,
    onRegisterNew: () -> Unit,
) {
    val viewModel: RestaurantAreaViewModel = viewModel(
        factory = viewModelFactory { initializer { RestaurantAreaViewModel(auth, management, locationSession) } },
    )
    val state = viewModel.uiState.collectAsStateWithLifecycle().value
    val signedIn = state.auth as? AuthState.SignedIn
    val profile = state.data.profile

    SimpleScreen(title = "Area ristoratore", onBack = null) {
        state.message?.let { MessageBanner(it, if (state.messageIsError) BannerKind.ERROR else BannerKind.SUCCESS) }

        when {
            state.auth is AuthState.Loading -> MessageBanner("Controllo l'accesso…")
            signedIn == null -> {
                StepHeader(1, "Accedi")
                SectionCard(
                    title = "Gestisci il tuo locale su HAPOSTO",
                    subtitle = "Per sicurezza chi gestisce un locale entra con il proprio account Google e un codice sul telefono. " +
                        "Così nessuno può pubblicare al posto tuo.",
                ) {
                    GoogleSignInButton(onResult = viewModel::onGoogleResult, enabled = !state.busy)
                    InfoDisclosure(
                        label = "Perché serve un account?",
                        text = "Lo stato del tuo locale lo vedono i clienti: deve poterlo cambiare solo chi lavora lì. " +
                            "Con Google non devi ricordare un'altra password; la verifica in due passaggi aggiunge un codice che hai solo tu.",
                    )
                }
            }
            !state.data.loaded -> MessageBanner("Carico i tuoi dati…")
            profile?.blocked == true -> MessageBanner(
                "Il tuo account è sospeso${profile.blockedReason?.let { ": $it" }.orEmpty()}. Scrivi a info@haposto.app.",
                BannerKind.ERROR,
            )
            profile == null || profile.needsTerms || profile.needsRestaurantTerms -> {
                StepHeader(2, "Condizioni")
                TermsAcceptanceCard(
                    needsUserTerms = profile?.needsTerms != false,
                    needsRestaurantTerms = true,
                    isBusy = state.busy,
                    onOpenDocument = onOpenDocument,
                    onAccept = viewModel::acceptTerms,
                )
            }
            !signedIn.mfa.verified -> {
                StepHeader(2, "Proteggi l'account")
                SectionCard(
                    title = if (signedIn.mfa.enrolled) "Inserisci il codice di verifica" else "Attiva la verifica in due passaggi",
                    subtitle = if (signedIn.mfa.enrolled) {
                        "Apri l'app di autenticazione e inserisci il codice di 6 cifre di HAPOSTO."
                    } else {
                        "Serve una volta sola e richiede 2 minuti: poi basta il codice quando accedi da un telefono nuovo."
                    },
                ) {
                    BigActionButton(text = if (signedIn.mfa.enrolled) "Inserisci il codice" else "Attiva adesso", onClick = onOpenMfa)
                }
            }
            else -> ReadyContent(state, viewModel, onOpenDashboard, onRegisterNew)
        }
        Spacer(Modifier.height(16.dp))
    }
}

@Composable
private fun ReadyContent(
    state: AreaUiState,
    viewModel: RestaurantAreaViewModel,
    onOpenDashboard: (String) -> Unit,
    onRegisterNew: () -> Unit,
) {
    val data = state.data
    val pending = data.claims.filter { it.status == ClaimStatus.PENDING }

    if (data.restaurants.isNotEmpty()) {
        SectionCard(title = "I tuoi locali") {
            data.restaurants.forEach { restaurant ->
                RestaurantRow(restaurant, onOpen = { onOpenDashboard(restaurant.restaurantId) })
            }
        }
    }

    if (pending.isNotEmpty()) {
        StepHeader(4, "Verifica telefonica")
        pending.forEach { claim -> PendingClaimCard(claim, state.busy, viewModel) }
    }

    data.claims.filter { it.status == ClaimStatus.REJECTED }.take(3).forEach { claim ->
        MessageBanner(
            "${claim.restaurantName}: richiesta non approvata${claim.reviewNote?.let { " — $it" }.orEmpty()}.",
            BannerKind.ERROR,
        )
    }

    if (data.restaurants.isEmpty() && pending.isEmpty()) StepHeader(3, "Trova il tuo locale")
    ClaimSearchCard(state, viewModel, onRegisterNew)
}

@Composable
private fun RestaurantRow(restaurant: ManagedRestaurant, onOpen: () -> Unit) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onOpen),
        shape = MaterialTheme.shapes.medium,
        color = MaterialTheme.colorScheme.primaryContainer,
        contentColor = MaterialTheme.colorScheme.onPrimaryContainer,
    ) {
        Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f)) {
                Text(restaurant.name, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                Text(
                    "${restaurant.city} · ${if (restaurant.role == MemberRole.OWNER) "Titolare" else "Staff"}" +
                        if (restaurant.isActivePartner) "" else " · non attivo",
                    style = MaterialTheme.typography.bodySmall,
                )
            }
            Text("Apri ›", style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
        }
    }
}

@Composable
private fun PendingClaimCard(claim: MyClaim, busy: Boolean, viewModel: RestaurantAreaViewModel) {
    var code by rememberSaveable(claim.claimId) { mutableStateOf("") }
    SectionCard(
        title = claim.restaurantName,
        subtitle = if (claim.phoneVerified) {
            "✓ Verifica telefonica fatta. Manca solo l'approvazione di HAPOSTO: riceverai una notifica."
        } else {
            "HAPOSTO chiamerà il numero pubblico del locale e dirà un codice di 6 cifre. Scrivilo qui."
        },
    ) {
        if (!claim.phoneVerified) {
            OutlinedTextField(
                value = code,
                onValueChange = { code = it.filter(Char::isDigit).take(6) },
                label = { Text("Codice ricevuto al telefono del locale") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                modifier = Modifier.fillMaxWidth(),
            )
            BigActionButton(
                text = "Conferma il codice",
                enabled = code.length == 6 && !busy,
                onClick = { viewModel.verifyCode(claim.claimId, code) },
            )
        }
        TextButton(onClick = { viewModel.cancelClaim(claim.claimId) }, enabled = !busy) { Text("Ritira la richiesta") }
    }
}

@Composable
private fun ClaimSearchCard(state: AreaUiState, viewModel: RestaurantAreaViewModel, onRegisterNew: () -> Unit) {
    var query by rememberSaveable { mutableStateOf("") }
    var selectedId by rememberSaveable { mutableStateOf<String?>(null) }
    val contacts = remember { mutableStateMapOf<String, String>() }

    SectionCard(
        title = "Aggiungi un locale",
        subtitle = "Cerca il nome del tuo locale e tocca «È il mio locale».",
    ) {
        OutlinedTextField(
            value = query,
            onValueChange = { query = it.take(80) },
            label = { Text("Nome del locale o città") },
            singleLine = true,
            modifier = Modifier.fillMaxWidth(),
        )
        OutlinedButton(
            onClick = { viewModel.search(query) },
            enabled = query.trim().length >= 2 && !state.searching,
            modifier = Modifier.fillMaxWidth(),
        ) { Text(if (state.searching) "Cerco…" else "Cerca") }
        if (state.searching) LinearProgressIndicator(Modifier.fillMaxWidth())

        state.searchResults.forEach { restaurant ->
            val selected = restaurant.id == selectedId
            Surface(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { selectedId = if (selected) null else restaurant.id },
                shape = MaterialTheme.shapes.medium,
                color = if (selected) MaterialTheme.colorScheme.secondaryContainer else MaterialTheme.colorScheme.surfaceVariant,
            ) {
                Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(restaurant.name, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
                    Text(
                        "${restaurant.address} · ${restaurant.city}" +
                            if (restaurant.partnershipStatus == PartnershipStatus.ACTIVE_PARTNER) " · già gestito" else "",
                        style = MaterialTheme.typography.bodySmall,
                    )
                    if (selected) {
                        val contact = contacts[restaurant.id] ?: restaurant.phoneNumber.orEmpty()
                        OutlinedTextField(
                            value = contact,
                            onValueChange = { contacts[restaurant.id] = it.take(120) },
                            label = { Text("Il tuo telefono o email di lavoro") },
                            singleLine = true,
                            modifier = Modifier.fillMaxWidth(),
                        )
                        BigActionButton(
                            text = "È il mio locale: invia la richiesta",
                            enabled = contact.trim().length >= 3 && !state.busy,
                            onClick = { viewModel.submitClaim(restaurant, contact) },
                        )
                    }
                }
            }
        }
        if (!state.searching && state.searchResults.isEmpty() && query.isNotBlank()) {
            Text("Tocca «Cerca». Se il locale non compare, aggiungilo qui sotto.", style = MaterialTheme.typography.bodySmall)
        }
        TextButton(onClick = onRegisterNew) { Text("Il mio locale non c'è: aggiungilo") }
    }
}

@Composable
private fun StepHeader(step: Int, title: String) {
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Text(
            "Passo $step di 4 · $title",
            style = MaterialTheme.typography.labelLarge,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.primary,
        )
        LinearProgressIndicator(progress = { step / 4f }, modifier = Modifier.fillMaxWidth())
    }
}
