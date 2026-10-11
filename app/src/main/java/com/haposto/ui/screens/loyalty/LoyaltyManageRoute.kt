package com.haposto.ui.screens.loyalty

import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import com.haposto.data.ErrorMessages
import com.haposto.data.Outcome
import com.haposto.data.loyalty.LoyaltyCardRow
import com.haposto.data.loyalty.LoyaltyDraft
import com.haposto.data.loyalty.LoyaltyProgram
import com.haposto.data.loyalty.LoyaltyStats
import com.haposto.data.loyalty.LoyaltyTexts
import com.haposto.data.loyalty.RestaurantLoyaltyRepository
import com.haposto.data.restaurant.MemberRole
import com.haposto.data.restaurant.RestaurantManagementRepository
import com.haposto.ui.components.BannerKind
import com.haposto.ui.components.BigActionButton
import com.haposto.ui.components.LabeledValue
import com.haposto.ui.components.MessageBanner
import com.haposto.ui.components.SectionCard
import com.haposto.ui.components.SimpleScreen
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class LoyaltyManageState(
    val loading: Boolean = true,
    val program: LoyaltyProgram = LoyaltyProgram.HIDDEN,
    val isOwner: Boolean = false,
    val stats: LoyaltyStats? = null,
    val statsDays: Int = 30,
    val cards: List<LoyaltyCardRow> = emptyList(),
    /** Non nullo = procedura guidata aperta (attivazione o nuova versione). */
    val draft: LoyaltyDraft? = null,
    val step: Int = 0,
    val pactAccepted: Boolean = false,
    val busy: Boolean = false,
    val message: String? = null,
    val messageIsError: Boolean = false,
    val needsMfa: Boolean = false,
)

class LoyaltyManageViewModel(
    private val restaurantId: String,
    private val loyalty: RestaurantLoyaltyRepository,
    private val management: RestaurantManagementRepository,
) : ViewModel() {

    private val mutable = MutableStateFlow(LoyaltyManageState())
    val state = mutable.asStateFlow()

    init {
        reload()
    }

    fun reload() {
        viewModelScope.launch {
            val program = loyalty.program(restaurantId).valueOrNull ?: LoyaltyProgram.HIDDEN
            val owner = management.managerInfo(restaurantId).valueOrNull?.myRole == MemberRole.OWNER
            val days = mutable.value.statsDays
            val stats = if (program.visible) loyalty.stats(restaurantId, days).valueOrNull else null
            val cards = if (program.visible) loyalty.cards(restaurantId).valueOrNull.orEmpty() else emptyList()
            mutable.update { it.copy(loading = false, program = program, isOwner = owner, stats = stats, cards = cards) }
        }
    }

    fun loadStats(days: Int) {
        mutable.update { it.copy(statsDays = days) }
        viewModelScope.launch {
            loyalty.stats(restaurantId, days).valueOrNull?.let { stats -> mutable.update { it.copy(stats = stats) } }
        }
    }

    fun startWizard() {
        val current = mutable.value.program.current
        mutable.update {
            it.copy(draft = current?.let { rules -> LoyaltyDraft.from(rules) } ?: LoyaltyDraft(), step = 0, pactAccepted = false, message = null)
        }
    }

    fun cancelWizard() = mutable.update { it.copy(draft = null, step = 0, pactAccepted = false) }

    fun updateDraft(transform: (LoyaltyDraft) -> LoyaltyDraft) =
        mutable.update { state -> state.copy(draft = state.draft?.let(transform), pactAccepted = false) }

    fun goToStep(step: Int) = mutable.update { it.copy(step = step.coerceIn(0, WIZARD_STEPS - 1)) }

    fun setPactAccepted(accepted: Boolean) = mutable.update { it.copy(pactAccepted = accepted) }

    fun publish() {
        val state = mutable.value
        val draft = state.draft ?: return
        val problems = draft.problems(state.program.limits)
        if (problems.isNotEmpty() || !state.pactAccepted) return
        act(onSuccess = { version -> "✓ Tessera attiva (versione $version). Vale per le tessere che iniziano da oggi." }) {
            loyalty.publish(restaurantId, draft).also { result ->
                if (result is Outcome.Success) mutable.update { it.copy(draft = null, step = 0, pactAccepted = false) }
            }
        }
    }

    fun close() {
        act(onSuccess = { until ->
            "✓ Tessera in chiusura" + (until?.let { " fino al ${LOYALTY_DATE.format(it)}" } ?: "") +
                ": niente tessere nuove, chi l'ha già può completarla."
        }) { loyalty.close(restaurantId) }
    }

    fun show(text: String, error: Boolean = false) = mutable.update { it.copy(message = text, messageIsError = error) }

    private fun <T> act(onSuccess: (T) -> String, block: suspend () -> Outcome<T>) {
        viewModelScope.launch {
            mutable.update { it.copy(busy = true, message = null, needsMfa = false) }
            when (val result = block()) {
                is Outcome.Success -> {
                    mutable.update { it.copy(busy = false, message = onSuccess(result.value), messageIsError = false) }
                    reload()
                }
                is Outcome.Failure -> mutable.update {
                    it.copy(busy = false, message = result.message, messageIsError = true, needsMfa = result.code == "MFA_REQUIRED")
                }
            }
        }
    }

    companion object {
        const val WIZARD_STEPS = 6
    }
}

/** Gestisci il locale → Tessera fedeltà: stato, regole, procedura guidata, statistiche (§11). */
@Composable
fun LoyaltyManageRoute(
    restaurantId: String,
    loyalty: RestaurantLoyaltyRepository,
    management: RestaurantManagementRepository,
    onBack: () -> Unit,
    onOpenMfa: () -> Unit,
) {
    val viewModel: LoyaltyManageViewModel = viewModel(
        key = "loyalty-manage-$restaurantId",
        factory = viewModelFactory { initializer { LoyaltyManageViewModel(restaurantId, loyalty, management) } },
    )
    val state = viewModel.state.collectAsStateWithLifecycle().value
    val draft = state.draft
    if (draft != null) {
        LoyaltyWizardScreen(
            draft = draft,
            step = state.step,
            limits = state.program.limits,
            isNewVersion = state.program.current != null,
            nextVersion = (state.program.versions.maxOfOrNull { it.version } ?: 0) + 1,
            pactAccepted = state.pactAccepted,
            busy = state.busy,
            message = state.message?.takeIf { state.messageIsError },
            needsMfa = state.needsMfa,
            onOpenMfa = onOpenMfa,
            onChange = viewModel::updateDraft,
            onStep = viewModel::goToStep,
            onPactAccepted = viewModel::setPactAccepted,
            onPublish = viewModel::publish,
            onCancel = viewModel::cancelWizard,
        )
        return
    }

    SimpleScreen(title = "Tessera fedeltà", onBack = onBack) {
        state.message?.let { MessageBanner(it, if (state.messageIsError) BannerKind.ERROR else BannerKind.SUCCESS) }
        if (state.needsMfa) BigActionButton(text = "Inserisci il codice", onClick = onOpenMfa)
        val program = state.program
        when {
            state.loading -> MessageBanner("Carico la tessera…")
            !program.visible -> MessageBanner("La tessera fedeltà non è disponibile per questo locale.")
            else -> {
                ProgramSection(program, state.isOwner, state.busy, onStart = viewModel::startWizard, onClose = viewModel::close)
                program.current?.let { rules ->
                    SectionCard(
                        title = "Le regole (versione ${rules.version})",
                        subtitle = rules.acceptedAt?.let { "Patto accettato il ${LOYALTY_DATE.format(it)}" },
                    ) { RulesSummary(rules) }
                }
                program.reports?.let { reports ->
                    SectionCard(title = "Segnalazioni dei clienti") {
                        Text(
                            "${reports.count} negli ultimi ${reports.windowDays} giorni. Avviso a ${reports.warn}; " +
                                "a ${reports.suspend} la tessera si sospende da sola. Non sai chi le ha fatte.",
                            style = MaterialTheme.typography.bodyMedium,
                        )
                    }
                }
                StatsSection(state.stats, state.statsDays, viewModel::loadStats)
                CardsSection(state.cards)
            }
        }
        Spacer(Modifier.height(16.dp))
    }
}

@Composable
private fun ProgramSection(
    program: LoyaltyProgram,
    isOwner: Boolean,
    busy: Boolean,
    onStart: () -> Unit,
    onClose: () -> Unit,
) {
    var confirmClose by rememberSaveable { mutableStateOf(false) }
    SectionCard(title = "La tessera del locale") {
        LabeledValue("Stato", LoyaltyTexts.status(program) { LOYALTY_DATE.format(it) })
        if (program.status == "CLOSING" && program.closingReason == "PLAN") {
            Text("Senza il piano Pro la tessera finisce alla data indicata.", style = MaterialTheme.typography.bodyMedium)
        }
        if (program.status != "NONE") {
            Text(
                "Tessere attive: ${program.activeCards} · premi da consegnare: ${program.rewardsAvailable}",
                style = MaterialTheme.typography.bodyMedium,
            )
        }
        if (program.current == null) {
            Text(
                "Una tessera timbri digitale: dopo un certo numero di visite il cliente ottiene un premio. " +
                    "Il timbro si dà scansionando il QR del cliente o del suo tavolo, e il locale vede solo un codice anonimo.",
                style = MaterialTheme.typography.bodyMedium,
            )
        }
        when {
            !isOwner -> Text("Le regole le sceglie il titolare.", style = MaterialTheme.typography.bodySmall)
            program.canPublish -> {
                BigActionButton(
                    text = if (program.current == null || program.status == "ENDED") "Attiva la tessera" else "Cambia le regole",
                    onClick = onStart,
                    enabled = !busy,
                )
                if (program.current != null) {
                    Text(
                        "Le regole nuove valgono solo per chi inizia da oggi: le tessere già iniziate restano con le regole di prima.",
                        style = MaterialTheme.typography.bodySmall,
                    )
                }
            }
            program.publishBlocker != null -> MessageBanner(ErrorMessages.messageFor(program.publishBlocker))
        }
        if (isOwner && program.status == "ACTIVE") {
            OutlinedButton(onClick = { confirmClose = true }, enabled = !busy, modifier = Modifier.fillMaxWidth()) {
                Text("Chiudi la tessera")
            }
        }
    }
    if (confirmClose) {
        AlertDialog(
            onDismissRequest = { confirmClose = false },
            title = { Text("Chiudere la tessera?") },
            text = {
                Text(
                    "Da subito nessuna tessera nuova. Per ${program.limits.closingNoticeDays} giorni chi ha già la tessera " +
                        "può continuare a timbrare; i premi sbloccati valgono fino alla loro scadenza. Poi la tessera finisce. " +
                        "I clienti ricevono un avviso.",
                )
            },
            confirmButton = {
                TextButton(onClick = {
                    confirmClose = false
                    onClose()
                }) { Text("Chiudi con preavviso") }
            },
            dismissButton = { TextButton(onClick = { confirmClose = false }) { Text("Annulla") } },
        )
    }
}

@Composable
private fun StatsSection(stats: LoyaltyStats?, days: Int, onDays: (Int) -> Unit) {
    SectionCard(title = "Statistiche della tessera", subtitle = "Solo numeri: mai nomi o email dei clienti.") {
        Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            listOf(7, 30, 90).forEach { option ->
                FilterChip(selected = days == option, onClick = { onDays(option) }, label = { Text("$option giorni") })
            }
        }
        if (stats == null) {
            Text("Nessun dato.", style = MaterialTheme.typography.bodyMedium)
            return@SectionCard
        }
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            StatLine("Visite timbrate", "${stats.scans} (di cui tavoli di gruppo: ${stats.groupScans})")
            StatLine("Persone timbrate", "${stats.people} · nuove ${stats.newCustomers} · di ritorno ${stats.returningPeople}")
            StatLine("Timbri dati", "${stats.stamps} (doppi: ${stats.doubleStamps})")
            StatLine("Tessere iniziate", "${stats.cardsStarted} · attive ora ${stats.activeCards}")
            StatLine("Premi", "sbloccati ${stats.rewardsUnlocked} · usati ${stats.rewardsUsed} · scaduti ${stats.rewardsExpired}")
            StatLine("Sconti riconosciuti", LoyaltyTexts.euro(stats.discountCents))
            StatLine("Vicini al premio", "a 1 timbro: ${stats.nearRewardOne} · a 2 timbri: ${stats.nearRewardTwo}")
        }
        val busiest = stats.byHour.sortedByDescending { it.scans }.take(3)
        if (busiest.isNotEmpty()) {
            Text(
                "Quando arrivano: " + busiest.joinToString(" · ") { "${LoyaltyTexts.weekday(it.weekday)} ore ${it.hour} (${it.scans})" },
                style = MaterialTheme.typography.bodySmall,
            )
        }
    }
}

@Composable
private fun StatLine(label: String, value: String) {
    Text(
        buildString { append(label).append(": ").append(value) },
        style = MaterialTheme.typography.bodyMedium,
    )
}

@Composable
private fun CardsSection(cards: List<LoyaltyCardRow>) {
    SectionCard(title = "Tessere attive", subtitle = "Ogni cliente ha un codice anonimo, diverso per ogni locale.") {
        if (cards.isEmpty()) {
            Text("Ancora nessuna.", style = MaterialTheme.typography.bodyMedium)
        }
        cards.take(100).forEach { card ->
            Row(Modifier.fillMaxWidth()) {
                Text(card.code, fontFamily = FontFamily.Monospace, fontWeight = FontWeight.Bold, modifier = Modifier.weight(0.25f))
                Text(
                    buildString {
                        append("${card.stamps} su ${card.required}")
                        card.lastStampAt?.let { append(" · ultima visita ").append(LOYALTY_DATE.format(it)) }
                        if (card.rewardsAvailable > 0) append(" · 🎁 ${card.rewardsAvailable}")
                    },
                    style = MaterialTheme.typography.bodyMedium,
                    modifier = Modifier.weight(0.75f),
                )
            }
        }
    }
}
