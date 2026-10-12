package com.haposto.ui.screens.loyalty

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
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
import com.haposto.data.loyalty.CustomerLoyaltyRepository
import com.haposto.data.loyalty.LoyaltyReportKind
import com.haposto.data.loyalty.LoyaltyReward
import com.haposto.data.loyalty.LoyaltyRules
import com.haposto.data.loyalty.LoyaltyTexts
import com.haposto.data.loyalty.MyCard
import com.haposto.data.loyalty.RestaurantLoyaltyBox
import com.haposto.ui.components.BannerKind
import com.haposto.ui.components.BigActionButton
import com.haposto.ui.components.MessageBanner
import com.haposto.ui.components.SectionCard
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class LoyaltyBoxState(
    val box: RestaurantLoyaltyBox = RestaurantLoyaltyBox.HIDDEN,
    val busy: Boolean = false,
    val message: String? = null,
    val messageIsError: Boolean = false,
)

/** Riquadro della tessera nella scheda del locale: il server decide se mostrarlo (T9). */
class LoyaltyBoxViewModel(
    private val restaurantId: String,
    private val loyalty: CustomerLoyaltyRepository,
) : ViewModel() {

    private val mutable = MutableStateFlow(LoyaltyBoxState())
    val state = mutable.asStateFlow()

    /** Errori di rete: il riquadro resta com'era (o nascosto), niente messaggi a chi non lo vede. */
    fun reload() {
        mutable.update { it.copy(message = null) }
        viewModelScope.launch {
            loyalty.restaurantBox(restaurantId).valueOrNull?.let { box -> mutable.update { it.copy(box = box) } }
        }
    }

    fun report(kind: LoyaltyReportKind) = act(
        block = { loyalty.report(restaurantId, kind) },
        success = "✓ Segnalazione inviata. Grazie: il locale non saprà chi l'ha fatta.",
    )

    fun leave() = act(block = { loyalty.leaveCard(restaurantId) }, success = "Hai lasciato la tessera di questo locale.")

    private fun act(block: suspend () -> Outcome<Unit>, success: String) {
        viewModelScope.launch {
            mutable.update { it.copy(busy = true, message = null) }
            when (val result = block()) {
                is Outcome.Success -> {
                    val box = loyalty.restaurantBox(restaurantId).valueOrNull ?: mutable.value.box
                    mutable.update { it.copy(busy = false, box = box, message = success, messageIsError = false) }
                }
                is Outcome.Failure -> mutable.update { it.copy(busy = false, message = result.message, messageIsError = true) }
            }
        }
    }
}

/** Da mettere nella scheda del locale: non mostra niente se la tessera non è disponibile. */
@Composable
fun LoyaltyRestaurantSection(
    restaurantId: String,
    loyalty: CustomerLoyaltyRepository,
    auth: AuthRepository,
    onShowQr: () -> Unit,
    onGroup: () -> Unit,
    onJoin: () -> Unit,
    onOpenAccount: () -> Unit,
) {
    val userId = (auth.state.collectAsStateWithLifecycle().value as? AuthState.SignedIn)?.user?.id
    val viewModel: LoyaltyBoxViewModel = viewModel(
        key = "loyalty-box-$restaurantId-${userId.orEmpty()}",
        factory = viewModelFactory { initializer { LoyaltyBoxViewModel(restaurantId, loyalty) } },
    )
    // Ricarica a ogni ritorno sulla scheda (dopo il QR i timbri sono cambiati).
    LaunchedEffect(viewModel) { viewModel.reload() }
    val state = viewModel.state.collectAsStateWithLifecycle().value
    if (!state.box.available) {
        // Una segnalazione può sospendere la tessera: il riquadro sparisce, la conferma resta.
        state.message?.let { MessageBanner(it, if (state.messageIsError) BannerKind.ERROR else BannerKind.SUCCESS) }
        return
    }
    val signedIn = userId != null
    LoyaltyRestaurantBoxContent(
        state = state,
        signedIn = signedIn,
        onShowQr = if (signedIn) onShowQr else onOpenAccount,
        onGroup = if (signedIn) onGroup else onOpenAccount,
        onJoin = if (signedIn) onJoin else onOpenAccount,
        onReport = viewModel::report,
        onLeave = viewModel::leave,
    )
}

/** Contenuto senza stato, per i test. */
@Composable
fun LoyaltyRestaurantBoxContent(
    state: LoyaltyBoxState,
    signedIn: Boolean,
    onShowQr: () -> Unit,
    onGroup: () -> Unit,
    onJoin: () -> Unit,
    onReport: (LoyaltyReportKind) -> Unit,
    onLeave: () -> Unit,
) {
    val box = state.box
    val rules = box.card?.rules ?: box.rules
    SectionCard(title = "🎫 Tessera fedeltà", subtitle = rules?.let(LoyaltyTexts::summary)) {
        CustomerCardBody(
            rules = rules,
            card = box.card,
            rewards = box.rewards,
            code = box.code,
            statusText = LoyaltyTexts.customerStatus(box.status, box.closingUntil) { LOYALTY_DATE.format(it) },
            canStart = box.canStart,
            signedIn = signedIn,
            busy = state.busy,
            onShowQr = onShowQr,
            onGroup = onGroup.takeIf { box.rules != null },
            onJoin = onJoin.takeIf { box.rules != null },
            onReport = onReport,
            onLeave = onLeave,
        )
        state.message?.let { MessageBanner(it, if (state.messageIsError) BannerKind.ERROR else BannerKind.SUCCESS) }
    }
}

/** Corpo comune a riquadro del locale e «Le mie tessere». */
@Composable
internal fun CustomerCardBody(
    rules: LoyaltyRules?,
    card: MyCard?,
    rewards: List<LoyaltyReward>,
    code: String?,
    statusText: String?,
    canStart: Boolean,
    signedIn: Boolean,
    busy: Boolean,
    onShowQr: () -> Unit,
    onGroup: (() -> Unit)?,
    onJoin: (() -> Unit)?,
    onReport: (LoyaltyReportKind) -> Unit,
    onLeave: () -> Unit,
    resetText: String? = null,
) {
    statusText?.let { MessageBanner(it) }
    val required = rules?.stampsRequired
    if (card != null && required != null) {
        StampProgress(card.stamps, required)
        resetText?.let { Text(it, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant) }
    } else if (canStart) {
        Text(
            "La tessera nasce al primo timbro: quando paghi, mostra il QR alla cassa.",
            style = MaterialTheme.typography.bodyMedium,
        )
    }
    CustomerRewards(rewards)
    rules?.let { RulesToggle(it) }

    BigActionButton(text = "Mostra il mio QR", onClick = onShowQr, enabled = !busy)
    if (onGroup != null || onJoin != null) {
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            onGroup?.let { OutlinedButton(onClick = it, enabled = !busy, modifier = Modifier.fillMaxWidth()) { Text("👥  Siamo in gruppo") } }
            onJoin?.let { OutlinedButton(onClick = it, enabled = !busy, modifier = Modifier.fillMaxWidth()) { Text("Unisciti a un tavolo") } }
        }
    }
    if (!signedIn) {
        Text(
            "Accedi con Google per raccogliere i timbri: è gratis.",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
    code?.let {
        Text(
            "Il tuo codice per questo locale: $it (il locale vede solo questo, mai il tuo nome).",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
    if (signedIn && code != null) {
        ReportButtons(enabled = !busy, onReport = onReport)
        if (card != null || rewards.isNotEmpty()) LeaveCardButton(enabled = !busy, onLeave = onLeave)
    }
}

/** T27: le regole della propria versione, chiuse di default. */
@Composable
private fun RulesToggle(rules: LoyaltyRules) {
    var open by rememberSaveable { mutableStateOf(false) }
    TextButton(onClick = { open = !open }) { Text(if (open) "Regole della tessera ▴" else "Regole della tessera ▾") }
    if (open) RulesSummary(rules, forCustomer = true)
}
