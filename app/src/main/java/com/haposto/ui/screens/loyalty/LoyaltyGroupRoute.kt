package com.haposto.ui.screens.loyalty

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.repeatOnLifecycle
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import com.haposto.data.Outcome
import com.haposto.data.auth.AuthRepository
import com.haposto.data.loyalty.CustomerLoyaltyRepository
import com.haposto.data.loyalty.GroupResult
import com.haposto.data.loyalty.GroupState
import com.haposto.data.loyalty.LoyaltyGroup
import com.haposto.data.loyalty.LoyaltyTexts
import com.haposto.data.loyalty.StampOutcome
import com.haposto.ui.components.BannerKind
import com.haposto.ui.components.BigActionButton
import com.haposto.ui.components.MessageBanner
import com.haposto.ui.components.SimpleScreen
import java.time.Instant
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class LoyaltyGroupState(
    val starting: Boolean = true,
    /** Il tavolo con il QR mostrato; la scadenza del QR è calcolata con l'orologio del telefono. */
    val group: LoyaltyGroup? = null,
    val members: Int = 1,
    val groupState: GroupState = GroupState.OPEN,
    val result: GroupResult? = null,
    val paused: Boolean = false,
    val failed: Boolean = false,
    /** Chiuso dal capogruppo con «Chiudi il tavolo». */
    val closedByMe: Boolean = false,
    val busy: Boolean = false,
    val message: String? = null,
) {
    val running: Boolean get() = !paused && !failed && !closedByMe && result == null && groupState == GroupState.OPEN
}

/**
 * «👥 Siamo in gruppo» (§6.2): il capogruppo mostra il QR del tavolo, che si rinnova ogni 60
 * secondi; sotto vede quante persone si sono unite e, dopo la scansione, il proprio timbro.
 */
class LoyaltyGroupViewModel(
    private val restaurantId: String,
    private val loyalty: CustomerLoyaltyRepository,
    private val clock: () -> Instant = Instant::now,
) : ViewModel() {

    private val mutable = MutableStateFlow(LoyaltyGroupState())
    val state = mutable.asStateFlow()

    private var renewals = 0

    suspend fun run() {
        while (mutable.value.running) {
            val group = mutable.value.group
            if (group == null) {
                if (!useGroup(loyalty.createGroup(restaurantId))) continue
            } else if (LoyaltyTexts.secondsLeft(group.token.expiresAt, clock()) <= LoyaltyQrViewModel.RENEW_BEFORE_SECONDS) {
                if (renewals >= LoyaltyQrViewModel.MAX_RENEWALS) {
                    mutable.update { it.copy(paused = true) }
                    return
                }
                if (!useGroup(loyalty.groupToken(group.groupId))) continue
            }
            val groupId = mutable.value.group?.groupId ?: return
            loyalty.groupStatus(groupId).valueOrNull?.let { status ->
                mutable.update { it.copy(members = status.members, groupState = status.state, result = status.result) }
            }
            if (!mutable.value.running) return
            delay(LoyaltyQrViewModel.POLL_MILLIS)
        }
    }

    private suspend fun useGroup(outcome: Outcome<LoyaltyGroup>): Boolean = when (outcome) {
        is Outcome.Success -> {
            val group = outcome.value
            val token = group.token.copy(expiresAt = clock().plusSeconds(group.token.seconds.toLong()))
            renewals++
            mutable.update { it.copy(starting = false, group = group.copy(token = token), members = group.members, message = null) }
            true
        }
        // Il QR non si rinnova più: il tavolo è stato scansionato proprio ora oppure è scaduto.
        is Outcome.Failure -> if (outcome.code == "GROUP_CLOSED") {
            val status = mutable.value.group?.groupId?.let { loyalty.groupStatus(it).valueOrNull }
            mutable.update {
                it.copy(
                    starting = false,
                    groupState = status?.state?.takeIf { state -> state != GroupState.OPEN } ?: GroupState.CLOSED,
                    result = status?.result,
                    members = status?.members ?: it.members,
                )
            }
            false
        } else {
            val transient = outcome.code == "UNKNOWN"
            mutable.update { it.copy(starting = false, failed = !transient, message = outcome.message) }
            if (transient) delay(LoyaltyQrViewModel.RETRY_MILLIS)
            false
        }
    }

    /** Dopo la pausa: stesso tavolo, QR nuovo. Dopo un errore o a tavolo scaduto: tavolo nuovo. */
    fun restart() {
        renewals = 0
        mutable.update {
            val sameTable = it.paused && !it.failed && it.groupState == GroupState.OPEN
            if (sameTable) {
                LoyaltyGroupState(group = it.group?.let { g -> g.copy(token = g.token.copy(expiresAt = null)) }, members = it.members)
            } else {
                LoyaltyGroupState()
            }
        }
    }

    /** Il capogruppo chiude il tavolo per tutti. */
    fun close(onClosed: () -> Unit) {
        val groupId = mutable.value.group?.groupId
        if (groupId == null) {
            onClosed()
            return
        }
        viewModelScope.launch {
            mutable.update { it.copy(busy = true) }
            when (val result = loyalty.leaveGroup(groupId)) {
                is Outcome.Success -> {
                    mutable.update { it.copy(busy = false, closedByMe = true) }
                    onClosed()
                }
                is Outcome.Failure -> mutable.update { it.copy(busy = false, message = result.message) }
            }
        }
    }
}

@Composable
fun LoyaltyGroupRoute(
    restaurantId: String,
    restaurantName: String?,
    loyalty: CustomerLoyaltyRepository,
    auth: AuthRepository,
    onBack: () -> Unit,
    onOpenAccount: () -> Unit,
) {
    SimpleScreen(title = "Siamo in gruppo", onBack = onBack) {
        LoyaltySignInGate(auth = auth, onOpenAccount = onOpenAccount) {
            LoyaltyPrivacyGate(onCancel = onBack) {
                val viewModel: LoyaltyGroupViewModel = viewModel(
                    key = "loyalty-group-$restaurantId",
                    factory = viewModelFactory { initializer { LoyaltyGroupViewModel(restaurantId, loyalty) } },
                )
                val state = viewModel.state.collectAsStateWithLifecycle().value
                val lifecycle = LocalLifecycleOwner.current.lifecycle
                LaunchedEffect(viewModel, state.running) {
                    if (state.running) lifecycle.repeatOnLifecycle(Lifecycle.State.STARTED) { viewModel.run() }
                }
                LoyaltyGroupContent(
                    state = state,
                    restaurantName = restaurantName,
                    onRestart = viewModel::restart,
                    onClose = { viewModel.close(onBack) },
                    onDone = onBack,
                )
            }
        }
    }
}

/** Contenuto senza stato, per i test. */
@Composable
fun LoyaltyGroupContent(
    state: LoyaltyGroupState,
    restaurantName: String?,
    onRestart: () -> Unit,
    onClose: () -> Unit,
    onDone: () -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
        restaurantName?.let { Text(it, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold) }
        state.message?.let { MessageBanner(it, if (state.failed) BannerKind.ERROR else BannerKind.INFO) }
        val result = state.result
        val group = state.group
        when {
            result != null -> {
                Text("Tavolo di ${state.members} · scansionato", style = MaterialTheme.typography.titleMedium)
                StampResultCard(LoyaltyTexts.groupResult(result), stamped = result.outcome == StampOutcome.STAMPED && !result.undone)
                BigActionButton(text = "Fatto", onClick = onDone)
            }
            state.failed -> OutlinedButton(onClick = onRestart, modifier = Modifier.fillMaxWidth()) { Text("Riprova") }
            state.groupState == GroupState.USED -> {
                StampResultCard("Il tavolo è stato scansionato alla cassa.", stamped = false)
                BigActionButton(text = "Fatto", onClick = onDone)
            }
            state.groupState == GroupState.CLOSED -> {
                MessageBanner("Il tavolo è scaduto senza scansione.")
                BigActionButton(text = "Crea un nuovo tavolo", onClick = onRestart)
            }
            state.paused -> {
                MembersLine(state.members)
                MessageBanner("QR del tavolo in pausa per risparmiare batteria: chi si è unito resta nel tavolo.")
                BigActionButton(text = "Mostra di nuovo il QR del tavolo", onClick = onRestart)
            }
            group == null -> MessageBanner("Preparo il tavolo…")
            else -> {
                SecureBrightScreen()
                MembersLine(state.members)
                var now by remember { mutableStateOf(Instant.now()) }
                LaunchedEffect(group.token.token) {
                    while (true) {
                        now = Instant.now()
                        delay(500)
                    }
                }
                LiveQr(
                    content = group.token.qrContent,
                    code = group.token.code,
                    secondsLeft = LoyaltyTexts.secondsLeft(group.token.expiresAt, now),
                    seconds = group.token.seconds,
                    label = "QR del tavolo",
                )
                Text(
                    "1. Gli altri aprono HAPOSTO → «Unisciti a un tavolo» e inquadrano questo QR" +
                        (group.joinUntil?.let { " entro le ${LOYALTY_TIME.format(it)}" } ?: "") + ".\n" +
                        "2. Alla cassa lo staff scansiona solo questo QR: ognuno riceve il suo timbro.",
                    style = MaterialTheme.typography.bodyMedium,
                    textAlign = TextAlign.Start,
                )
            }
        }
        if (result == null && state.group != null && state.groupState == GroupState.OPEN) {
            TextButton(onClick = onClose, enabled = !state.busy, modifier = Modifier.fillMaxWidth()) {
                Text("Chiudi il tavolo", color = MaterialTheme.colorScheme.error)
            }
        }
        Spacer(Modifier.height(16.dp))
    }
}

@Composable
private fun MembersLine(members: Int) {
    Text(
        "Tavolo: $members ${if (members == 1) "persona" else "persone"} ✓",
        style = MaterialTheme.typography.headlineSmall,
        fontWeight = FontWeight.Black,
    )
}
