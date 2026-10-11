package com.haposto.ui.screens.loyalty

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
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
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import com.haposto.data.Outcome
import com.haposto.data.auth.AuthRepository
import com.haposto.data.loyalty.CustomerLoyaltyRepository
import com.haposto.data.loyalty.LoyaltyTexts
import com.haposto.data.loyalty.StampMember
import com.haposto.data.loyalty.StampOutcome
import com.haposto.data.loyalty.TokenState
import com.haposto.data.loyalty.VisitToken
import com.haposto.ui.components.BannerKind
import com.haposto.ui.components.BigActionButton
import com.haposto.ui.components.MessageBanner
import com.haposto.ui.components.SimpleScreen
import java.time.Instant
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update

data class LoyaltyQrState(
    val starting: Boolean = true,
    /** Il QR mostrato; [VisitToken.expiresAt] è calcolata con l'orologio del telefono. */
    val token: VisitToken? = null,
    val result: StampMember? = null,
    /** Dopo una decina di minuti senza scansione il QR si ferma, per non consumare batteria. */
    val paused: Boolean = false,
    val failed: Boolean = false,
    val message: String? = null,
) {
    val running: Boolean get() = result == null && !paused && !failed
}

/**
 * QR personale (§6.1): nuovo ogni 60 secondi e valido una volta sola. Il QR appena sostituito
 * resta controllato finché scade, perché lo staff può averlo scansionato all'ultimo secondo.
 */
class LoyaltyQrViewModel(
    private val restaurantId: String,
    private val loyalty: CustomerLoyaltyRepository,
    private val clock: () -> Instant = Instant::now,
) : ViewModel() {

    private val mutable = MutableStateFlow(LoyaltyQrState())
    val state = mutable.asStateFlow()

    private val live = mutableListOf<VisitToken>()
    private var renewals = 0

    /** Gira finché la schermata è visibile (la chiama la schermata con repeatOnLifecycle). */
    suspend fun run() {
        while (mutable.value.running) {
            val shown = mutable.value.token
            if (shown == null || LoyaltyTexts.secondsLeft(shown.expiresAt, clock()) <= RENEW_BEFORE_SECONDS) {
                if (renewals >= MAX_RENEWALS) {
                    mutable.update { it.copy(paused = true) }
                    return
                }
                if (!renew()) continue
            }
            for (token in live.toList()) {
                val status = loyalty.tokenStatus(token.token).valueOrNull ?: continue
                when (status.state) {
                    TokenState.USED -> {
                        mutable.update { it.copy(result = status.result ?: StampMember(null, StampOutcome.UNKNOWN)) }
                        return
                    }
                    TokenState.EXPIRED -> live.remove(token)
                    TokenState.WAITING -> Unit
                }
            }
            live.removeAll { it.expiresAt?.plusSeconds(GRACE_SECONDS)?.isBefore(clock()) == true }
            delay(POLL_MILLIS)
        }
    }

    /** false = non riuscito: con un errore di rete riprova da solo, altrimenti si ferma. */
    private suspend fun renew(): Boolean = when (val created = loyalty.createToken(restaurantId)) {
        is Outcome.Success -> {
            val token = created.value.copy(expiresAt = clock().plusSeconds(created.value.seconds.toLong()))
            live += token
            renewals++
            mutable.update { it.copy(starting = false, token = token, message = null) }
            true
        }
        is Outcome.Failure -> {
            val transient = created.code == "UNKNOWN"
            mutable.update {
                it.copy(starting = false, token = if (transient) it.token else null, failed = !transient, message = created.message)
            }
            if (transient) delay(RETRY_MILLIS)
            false
        }
    }

    /** «Mostra di nuovo il QR» dopo la pausa o un errore. */
    fun restart() {
        renewals = 0
        mutable.update { it.copy(paused = false, failed = false, message = null, token = null, starting = true) }
    }

    companion object {
        const val RENEW_BEFORE_SECONDS = 2L
        const val GRACE_SECONDS = 5L
        const val MAX_RENEWALS = 10
        const val POLL_MILLIS = 1_000L
        const val RETRY_MILLIS = 3_000L
    }
}

/** «Mostra il mio QR»: scheda del locale o «Le mie tessere» (T61: l'accesso si chiede qui). */
@Composable
fun LoyaltyQrRoute(
    restaurantId: String,
    restaurantName: String?,
    loyalty: CustomerLoyaltyRepository,
    auth: AuthRepository,
    onBack: () -> Unit,
    onOpenAccount: () -> Unit,
    onGroup: () -> Unit,
) {
    SimpleScreen(title = "Il mio QR", onBack = onBack) {
        LoyaltySignInGate(auth = auth, onOpenAccount = onOpenAccount) {
            LoyaltyPrivacyGate(onCancel = onBack) {
                val viewModel: LoyaltyQrViewModel = viewModel(
                    key = "loyalty-qr-$restaurantId",
                    factory = viewModelFactory { initializer { LoyaltyQrViewModel(restaurantId, loyalty) } },
                )
                val state = viewModel.state.collectAsStateWithLifecycle().value
                val lifecycle = LocalLifecycleOwner.current.lifecycle
                LaunchedEffect(viewModel, state.running) {
                    if (state.running) lifecycle.repeatOnLifecycle(Lifecycle.State.STARTED) { viewModel.run() }
                }
                LoyaltyQrContent(
                    state = state,
                    restaurantName = restaurantName,
                    onGroup = onGroup,
                    onRestart = viewModel::restart,
                    onDone = onBack,
                )
            }
        }
    }
}

/** Contenuto senza stato, per i test. */
@Composable
fun LoyaltyQrContent(
    state: LoyaltyQrState,
    restaurantName: String?,
    onGroup: () -> Unit,
    onRestart: () -> Unit,
    onDone: () -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
        restaurantName?.let {
            Text(it, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
        }
        state.message?.let { MessageBanner(it, if (state.failed) BannerKind.ERROR else BannerKind.INFO) }
        val result = state.result
        val token = state.token
        when {
            result != null -> {
                StampResultCard(LoyaltyTexts.customerResult(result), stamped = result.outcome == StampOutcome.STAMPED)
                BigActionButton(text = "Fatto", onClick = onDone)
            }
            state.failed -> OutlinedButton(onClick = onRestart, modifier = Modifier.fillMaxWidth()) { Text("Riprova") }
            state.paused -> {
                MessageBanner("QR in pausa per risparmiare batteria.")
                BigActionButton(text = "Mostra di nuovo il QR", onClick = onRestart)
            }
            token == null -> MessageBanner("Preparo il QR…")
            else -> {
                SecureBrightScreen()
                var now by remember { mutableStateOf(Instant.now()) }
                LaunchedEffect(token.token) {
                    while (true) {
                        now = Instant.now()
                        delay(500)
                    }
                }
                LiveQr(
                    content = token.qrContent,
                    code = token.code,
                    secondsLeft = LoyaltyTexts.secondsLeft(token.expiresAt, now),
                    seconds = token.seconds,
                    label = "QR della tessera da mostrare alla cassa",
                )
                Text(
                    "Mostralo alla cassa quando paghi: il timbro arriva qui appena lo staff lo scansiona.",
                    style = MaterialTheme.typography.bodyMedium,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth(),
                )
                OutlinedButton(onClick = onGroup, modifier = Modifier.fillMaxWidth()) { Text("👥  Siamo in gruppo") }
            }
        }
        Spacer(Modifier.height(16.dp))
    }
}

/** «✓ +1 timbro · 4 su 10», grande. */
@Composable
internal fun StampResultCard(text: String, stamped: Boolean) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        color = if (stamped) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.secondaryContainer,
        contentColor = if (stamped) MaterialTheme.colorScheme.onPrimaryContainer else MaterialTheme.colorScheme.onSecondaryContainer,
        shape = MaterialTheme.shapes.large,
    ) {
        Text(
            text,
            modifier = Modifier.padding(24.dp),
            style = if (stamped) MaterialTheme.typography.headlineSmall else MaterialTheme.typography.titleMedium,
            fontWeight = if (stamped) FontWeight.Black else FontWeight.SemiBold,
        )
    }
}
