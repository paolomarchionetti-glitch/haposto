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
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
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
import com.haposto.data.loyalty.JoinedGroup
import com.haposto.data.loyalty.LoyaltyQr
import com.haposto.data.loyalty.LoyaltyTexts
import com.haposto.data.loyalty.StampOutcome
import com.haposto.platform.qr.QrScanner
import com.haposto.ui.components.BannerKind
import com.haposto.ui.components.BigActionButton
import com.haposto.ui.components.MessageBanner
import com.haposto.ui.components.SimpleScreen
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class LoyaltyJoinState(
    val busy: Boolean = false,
    val joined: JoinedGroup? = null,
    val members: Int = 0,
    val groupState: GroupState = GroupState.OPEN,
    val result: GroupResult? = null,
    /** Dopo un quarto d'ora l'app smette di controllare da sola: si aggiorna a mano. */
    val paused: Boolean = false,
    val message: String? = null,
    val messageIsError: Boolean = false,
) {
    val waiting: Boolean get() = joined != null && result == null && groupState == GroupState.OPEN && !paused
}

/** «Unisciti a un tavolo» (§6.2): si inquadra il QR del tavolo con lo scanner di Google. */
class LoyaltyJoinViewModel(private val loyalty: CustomerLoyaltyRepository) : ViewModel() {

    private val mutable = MutableStateFlow(LoyaltyJoinState())
    val state = mutable.asStateFlow()

    private var checks = 0

    fun onScanned(raw: String) {
        val token = LoyaltyQr.tokenFrom(raw)
        if (token == null) {
            show("Non è il QR di un tavolo HAPOSTO: inquadra il QR mostrato da chi ha toccato «Siamo in gruppo».", error = true)
            return
        }
        viewModelScope.launch {
            mutable.update { it.copy(busy = true, message = null) }
            when (val joined = loyalty.joinGroup(token)) {
                is Outcome.Success -> {
                    checks = 0
                    mutable.update {
                        LoyaltyJoinState(joined = joined.value, members = joined.value.members)
                    }
                }
                is Outcome.Failure -> mutable.update { it.copy(busy = false, message = joined.message, messageIsError = true) }
            }
        }
    }

    /** Controlla il tavolo finché lo staff lo scansiona (la chiama la schermata quando è visibile). */
    suspend fun run() {
        while (mutable.value.waiting) {
            refresh()
            if (++checks >= MAX_CHECKS && mutable.value.waiting) {
                mutable.update { it.copy(paused = true) }
                return
            }
            delay(POLL_MILLIS)
        }
    }

    private suspend fun refresh() {
        val groupId = mutable.value.joined?.groupId ?: return
        when (val status = loyalty.groupStatus(groupId)) {
            is Outcome.Success -> mutable.update {
                it.copy(members = status.value.members, groupState = status.value.state, result = status.value.result)
            }
            is Outcome.Failure -> if (status.code == "GROUP_NOT_FOUND") {
                mutable.update { it.copy(groupState = GroupState.CLOSED) }
            }
        }
    }

    fun resume() {
        checks = 0
        mutable.update { it.copy(paused = false) }
    }

    fun leave() {
        val groupId = mutable.value.joined?.groupId ?: return
        viewModelScope.launch {
            mutable.update { it.copy(busy = true) }
            when (val result = loyalty.leaveGroup(groupId)) {
                is Outcome.Success -> mutable.update { LoyaltyJoinState(message = "Sei uscito dal tavolo.") }
                is Outcome.Failure -> mutable.update { it.copy(busy = false, message = result.message, messageIsError = true) }
            }
        }
    }

    fun show(text: String, error: Boolean = false) = mutable.update { it.copy(message = text, messageIsError = error) }

    companion object {
        const val POLL_MILLIS = 2_000L
        const val MAX_CHECKS = 450
    }
}

@Composable
fun LoyaltyJoinRoute(
    loyalty: CustomerLoyaltyRepository,
    auth: AuthRepository,
    onBack: () -> Unit,
    onOpenAccount: () -> Unit,
) {
    SimpleScreen(title = "Unisciti a un tavolo", onBack = onBack) {
        LoyaltySignInGate(auth = auth, onOpenAccount = onOpenAccount) {
            LoyaltyPrivacyGate(onCancel = onBack) {
                val viewModel: LoyaltyJoinViewModel = viewModel(
                    key = "loyalty-join",
                    factory = viewModelFactory { initializer { LoyaltyJoinViewModel(loyalty) } },
                )
                val state = viewModel.state.collectAsStateWithLifecycle().value
                val context = LocalContext.current
                val scope = rememberCoroutineScope()
                val lifecycle = LocalLifecycleOwner.current.lifecycle
                LaunchedEffect(viewModel, state.waiting) {
                    if (state.waiting) lifecycle.repeatOnLifecycle(Lifecycle.State.STARTED) { viewModel.run() }
                }
                val launchScanner: () -> Unit = {
                    scope.launch {
                        when (val scan = QrScanner.scan(context)) {
                            is QrScanner.Result.Scanned -> viewModel.onScanned(scan.raw)
                            QrScanner.Result.Cancelled -> Unit
                            is QrScanner.Result.Failed -> viewModel.show(
                                "Lo scanner non si è aperto: aggiorna Google Play services e riprova.",
                                error = true,
                            )
                        }
                    }
                }
                var autoStarted by rememberSaveable { mutableStateOf(false) }
                LaunchedEffect(Unit) {
                    if (!autoStarted && state.joined == null) {
                        autoStarted = true
                        launchScanner()
                    }
                }
                LoyaltyJoinContent(
                    state = state,
                    onScan = launchScanner,
                    onResume = viewModel::resume,
                    onLeave = viewModel::leave,
                    onDone = onBack,
                )
            }
        }
    }
}

/** Contenuto senza stato, per i test. */
@Composable
fun LoyaltyJoinContent(
    state: LoyaltyJoinState,
    onScan: () -> Unit,
    onResume: () -> Unit,
    onLeave: () -> Unit,
    onDone: () -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
        state.message?.let { MessageBanner(it, if (state.messageIsError) BannerKind.ERROR else BannerKind.INFO) }
        val joined = state.joined
        val result = state.result
        when {
            joined == null -> {
                Text(
                    "Chi ha toccato «👥 Siamo in gruppo» ti mostra il QR del tavolo: inquadralo. " +
                        "Alla cassa lo staff scansiona solo quel QR e ognuno riceve il suo timbro.",
                    style = MaterialTheme.typography.bodyLarge,
                )
                BigActionButton(text = "📷  Inquadra il QR del tavolo", onClick = onScan, enabled = !state.busy)
            }
            result != null -> {
                Text(joined.restaurantName, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                StampResultCard(LoyaltyTexts.groupResult(result), stamped = result.outcome == StampOutcome.STAMPED && !result.undone)
                BigActionButton(text = "Fatto", onClick = onDone)
            }
            state.groupState == GroupState.USED -> {
                StampResultCard("Il tavolo è stato scansionato alla cassa.", stamped = false)
                BigActionButton(text = "Fatto", onClick = onDone)
            }
            state.groupState == GroupState.CLOSED -> {
                MessageBanner("Il tavolo è stato chiuso senza scansione.")
                OutlinedButton(onClick = onScan, modifier = Modifier.fillMaxWidth()) { Text("Inquadra un altro QR del tavolo") }
            }
            else -> {
                Text(joined.restaurantName, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                Text(
                    "✓ Sei nel tavolo · ${state.members} ${if (state.members == 1) "persona" else "persone"}",
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Black,
                )
                Text(
                    "Alla cassa lo staff scansiona il QR del tavolo: il tuo timbro compare qui.",
                    style = MaterialTheme.typography.bodyMedium,
                )
                if (state.paused) {
                    OutlinedButton(onClick = onResume, modifier = Modifier.fillMaxWidth()) { Text("Aggiorna") }
                }
                TextButton(onClick = onLeave, enabled = !state.busy, modifier = Modifier.fillMaxWidth()) {
                    Text("Esci dal tavolo", color = MaterialTheme.colorScheme.error)
                }
            }
        }
        Spacer(Modifier.height(16.dp))
    }
}
