package com.haposto.ui.screens.loyalty

import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.key
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import com.haposto.data.Outcome
import com.haposto.data.loyalty.CustomerLoyaltyRepository
import com.haposto.data.loyalty.LoyaltyReportKind
import com.haposto.data.loyalty.LoyaltyTexts
import com.haposto.data.loyalty.MyLoyaltyCard
import com.haposto.ui.components.BannerKind
import com.haposto.ui.components.BigActionButton
import com.haposto.ui.components.MessageBanner
import com.haposto.ui.components.SectionCard
import com.haposto.ui.components.SimpleScreen
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class LoyaltyCardsState(
    val loading: Boolean = true,
    val cards: List<MyLoyaltyCard> = emptyList(),
    val busy: Boolean = false,
    val message: String? = null,
    val messageIsError: Boolean = false,
)

class LoyaltyCardsViewModel(private val loyalty: CustomerLoyaltyRepository) : ViewModel() {

    private val mutable = MutableStateFlow(LoyaltyCardsState())
    val state = mutable.asStateFlow()

    fun reload() {
        viewModelScope.launch {
            when (val result = loyalty.myCards()) {
                is Outcome.Success -> mutable.update { it.copy(loading = false, cards = result.value) }
                is Outcome.Failure -> mutable.update { it.copy(loading = false, message = result.message, messageIsError = true) }
            }
        }
    }

    fun report(restaurantId: String, kind: LoyaltyReportKind) = act(
        block = { loyalty.report(restaurantId, kind) },
        success = "✓ Segnalazione inviata. Grazie: il locale non saprà chi l'ha fatta.",
    )

    fun leave(restaurantId: String) = act(block = { loyalty.leaveCard(restaurantId) }, success = "Tessera lasciata.")

    private fun act(block: suspend () -> Outcome<Unit>, success: String) {
        viewModelScope.launch {
            mutable.update { it.copy(busy = true, message = null) }
            when (val result = block()) {
                is Outcome.Success -> {
                    val cards = loyalty.myCards().valueOrNull ?: mutable.value.cards
                    mutable.update { it.copy(busy = false, cards = cards, message = success, messageIsError = false) }
                }
                is Outcome.Failure -> mutable.update { it.copy(busy = false, message = result.message, messageIsError = true) }
            }
        }
    }
}

/** Account → «Le mie tessere» (T27): tessere attive e premi da usare, con le regole di ognuna. */
@Composable
fun LoyaltyCardsRoute(
    loyalty: CustomerLoyaltyRepository,
    onBack: () -> Unit,
    onShowQr: (String) -> Unit,
    onJoin: () -> Unit,
) {
    val viewModel: LoyaltyCardsViewModel = viewModel(
        key = "loyalty-cards",
        factory = viewModelFactory { initializer { LoyaltyCardsViewModel(loyalty) } },
    )
    LaunchedEffect(viewModel) { viewModel.reload() }
    val state = viewModel.state.collectAsStateWithLifecycle().value
    SimpleScreen(title = "Le mie tessere", onBack = onBack) {
        LoyaltyCardsContent(
            state = state,
            onShowQr = onShowQr,
            onJoin = onJoin,
            onReport = viewModel::report,
            onLeave = viewModel::leave,
        )
    }
}

/** Contenuto senza stato, per i test. */
@Composable
fun LoyaltyCardsContent(
    state: LoyaltyCardsState,
    onShowQr: (String) -> Unit,
    onJoin: () -> Unit,
    onReport: (String, LoyaltyReportKind) -> Unit,
    onLeave: (String) -> Unit,
) {
    state.message?.let { MessageBanner(it, if (state.messageIsError) BannerKind.ERROR else BannerKind.SUCCESS) }
    BigActionButton(text = "Unisciti a un tavolo", onClick = onJoin, enabled = !state.busy)
    when {
        state.loading -> MessageBanner("Carico le tue tessere…")
        state.cards.isEmpty() -> MessageBanner(
            "Non hai ancora tessere. La tessera nasce al primo timbro: nella scheda di un locale con la tessera " +
                "tocca «Mostra il mio QR» quando paghi.",
        )
        else -> state.cards.forEach { entry ->
            key(entry.restaurantId) {
                val rules = entry.card?.rules
                SectionCard(
                    title = entry.restaurantName + entry.city.takeIf { it.isNotBlank() }?.let { " · $it" }.orEmpty(),
                    subtitle = rules?.let(LoyaltyTexts::summary),
                ) {
                    CustomerCardBody(
                        rules = rules,
                        card = entry.card,
                        rewards = entry.rewards,
                        code = entry.code,
                        statusText = LoyaltyTexts.customerStatus(entry.programStatus, entry.closingUntil) { LOYALTY_DATE.format(it) },
                        canStart = false,
                        signedIn = true,
                        busy = state.busy,
                        onShowQr = { onShowQr(entry.restaurantId) },
                        onGroup = null,
                        onJoin = null,
                        onReport = { kind -> onReport(entry.restaurantId, kind) },
                        onLeave = { onLeave(entry.restaurantId) },
                        resetText = LoyaltyTexts.resetNotice(entry.card?.resetAt) { LOYALTY_DATE.format(it) },
                    )
                }
            }
        }
    }
    Text(
        "La tessera è gratis. Il locale vede solo un codice anonimo, diverso per ogni locale.",
        style = MaterialTheme.typography.bodySmall,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
    )
    Spacer(Modifier.height(16.dp))
}
