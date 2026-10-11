package com.haposto.ui.screens.loyalty

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import com.haposto.data.Outcome
import com.haposto.data.loyalty.LoyaltyProgram
import com.haposto.data.loyalty.LoyaltyQr
import com.haposto.data.loyalty.LoyaltyReward
import com.haposto.data.loyalty.LoyaltyTexts
import com.haposto.data.loyalty.RestaurantLoyaltyRepository
import com.haposto.data.loyalty.RewardKind
import com.haposto.data.loyalty.StampOutcome
import com.haposto.data.loyalty.StampResult
import com.haposto.platform.qr.QrScanner
import com.haposto.ui.components.BannerKind
import com.haposto.ui.components.BigActionButton
import com.haposto.ui.components.InfoDisclosure
import com.haposto.ui.components.MessageBanner
import com.haposto.ui.components.SectionCard
import com.haposto.ui.components.SimpleScreen
import java.time.Instant
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class LoyaltyStampState(
    val loading: Boolean = true,
    val program: LoyaltyProgram = LoyaltyProgram.HIDDEN,
    val busy: Boolean = false,
    val result: StampResult? = null,
    /** Premi consegnati o applicati dopo questa scansione. */
    val usedRewards: Set<String> = emptySet(),
    val undone: Boolean = false,
    val message: String? = null,
    val messageIsError: Boolean = false,
    val needsMfa: Boolean = false,
)

class LoyaltyStampViewModel(
    private val restaurantId: String,
    private val loyalty: RestaurantLoyaltyRepository,
) : ViewModel() {

    private val mutable = MutableStateFlow(LoyaltyStampState())
    val state = mutable.asStateFlow()

    init {
        viewModelScope.launch {
            val program = loyalty.program(restaurantId).valueOrNull ?: LoyaltyProgram.HIDDEN
            mutable.update { it.copy(loading = false, program = program) }
        }
    }

    /** Contenuto letto dallo scanner: solo i QR della tessera HAPOSTO. */
    fun onScanned(raw: String) {
        val token = LoyaltyQr.tokenFrom(raw)
        if (token == null) {
            show("Non è il QR della tessera HAPOSTO: chiedi al cliente di aprire «Mostra il mio QR».", error = true)
            return
        }
        stamp { loyalty.stampToken(restaurantId, token) }
    }

    fun stampCode(code: String) {
        if (code.isBlank()) return
        stamp { loyalty.stampCode(restaurantId, code) }
    }

    private fun stamp(block: suspend () -> Outcome<StampResult>) {
        viewModelScope.launch {
            mutable.update { it.copy(busy = true, message = null, needsMfa = false) }
            when (val result = block()) {
                is Outcome.Success -> mutable.update {
                    it.copy(busy = false, result = result.value, usedRewards = emptySet(), undone = false)
                }
                is Outcome.Failure -> mutable.update {
                    it.copy(busy = false, message = result.message, messageIsError = true, needsMfa = result.code == "MFA_REQUIRED")
                }
            }
        }
    }

    /** T33: solo per un errore dello staff, entro 2 minuti. */
    fun undo() {
        val scanId = mutable.value.result?.scanId ?: return
        viewModelScope.launch {
            mutable.update { it.copy(busy = true, message = null) }
            when (val result = loyalty.undo(scanId)) {
                is Outcome.Success -> mutable.update {
                    it.copy(busy = false, undone = true, message = "Scansione annullata: nessun timbro è stato dato.", messageIsError = false)
                }
                is Outcome.Failure -> mutable.update { it.copy(busy = false, message = result.message, messageIsError = true) }
            }
        }
    }

    fun useReward(reward: LoyaltyReward, discountText: String) {
        val cents = if (reward.rules.kind == RewardKind.GIFT) null else LoyaltyTexts.parseEuroCents(discountText)
        if (reward.rules.kind != RewardKind.GIFT && discountText.isNotBlank() && cents == null) {
            show("Importo dello sconto non valido: scrivi per esempio 7,50.", error = true)
            return
        }
        viewModelScope.launch {
            mutable.update { it.copy(busy = true, message = null) }
            when (val result = loyalty.useReward(restaurantId, reward.rewardId, cents)) {
                is Outcome.Success -> mutable.update {
                    it.copy(busy = false, usedRewards = it.usedRewards + reward.rewardId, message = null)
                }
                is Outcome.Failure -> mutable.update { it.copy(busy = false, message = result.message, messageIsError = true) }
            }
        }
    }

    fun show(text: String, error: Boolean = false) = mutable.update { it.copy(message = text, messageIsError = error) }
}

/** Dashboard → 📷 Timbra (T34): lo scanner di Google si apre subito. */
@Composable
fun LoyaltyStampRoute(
    restaurantId: String,
    loyalty: RestaurantLoyaltyRepository,
    onBack: () -> Unit,
    onOpenMfa: () -> Unit,
) {
    val viewModel: LoyaltyStampViewModel = viewModel(
        key = "loyalty-stamp-$restaurantId",
        factory = viewModelFactory { initializer { LoyaltyStampViewModel(restaurantId, loyalty) } },
    )
    val state = viewModel.state.collectAsStateWithLifecycle().value
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val launchScanner: () -> Unit = {
        scope.launch {
            when (val scan = QrScanner.scan(context)) {
                is QrScanner.Result.Scanned -> viewModel.onScanned(scan.raw)
                QrScanner.Result.Cancelled -> Unit
                is QrScanner.Result.Failed -> viewModel.show(
                    "Lo scanner non si è aperto: aggiorna Google Play services oppure usa «Inserisci codice».",
                    error = true,
                )
            }
        }
    }
    var autoStarted by rememberSaveable { mutableStateOf(false) }
    LaunchedEffect(state.program.canScan) {
        if (state.program.canScan && !autoStarted) {
            autoStarted = true
            launchScanner()
        }
    }

    SimpleScreen(title = "Timbra la tessera", onBack = onBack) {
        state.message?.let { MessageBanner(it, if (state.messageIsError) BannerKind.ERROR else BannerKind.SUCCESS) }
        if (state.needsMfa) BigActionButton(text = "Inserisci il codice", onClick = onOpenMfa)
        when {
            state.loading -> MessageBanner("Preparo lo scanner…")
            !state.program.canScan -> MessageBanner("La tessera non è attiva per questo locale.")
            else -> {
                state.result?.let { result ->
                    if (!state.undone) {
                        ResultCard(
                            result = result,
                            gapHours = state.program.limits.stampGapHours,
                            usedRewards = state.usedRewards,
                            busy = state.busy,
                            onUseReward = viewModel::useReward,
                            onUndo = viewModel::undo,
                        )
                    }
                }
                BigActionButton(
                    text = if (state.result == null) "📷  Scansiona il QR del cliente" else "📷  Timbra il prossimo",
                    onClick = launchScanner,
                    enabled = !state.busy,
                )
                CodeEntry(enabled = !state.busy, onSubmit = viewModel::stampCode)
                InfoDisclosure(
                    label = "Come funziona",
                    text = "Il cliente apre «Mostra il mio QR» nell'app HAPOSTO: il QR cambia ogni 60 secondi e vale una volta sola. " +
                        "Per un tavolo di amici basta scansionare il «QR del tavolo»: ognuno riceve il suo timbro. " +
                        "Prima di timbrare controlla la condizione (spesa o consumazioni). «Annulla» serve solo per un errore, entro 2 minuti.",
                )
            }
        }
        Spacer(Modifier.height(16.dp))
    }
}

@Composable
private fun ResultCard(
    result: StampResult,
    gapHours: Int,
    usedRewards: Set<String>,
    busy: Boolean,
    onUseReward: (LoyaltyReward, String) -> Unit,
    onUndo: () -> Unit,
) {
    if (!result.ok) {
        MessageBanner(LoyaltyTexts.stampError(result) { LOYALTY_TIME.format(it) }, BannerKind.ERROR)
        return
    }
    val stampedSomeone = result.stamped > 0
    Surface(
        modifier = Modifier.fillMaxWidth(),
        color = if (stampedSomeone) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.secondaryContainer,
        contentColor = if (stampedSomeone) MaterialTheme.colorScheme.onPrimaryContainer else MaterialTheme.colorScheme.onSecondaryContainer,
        shape = MaterialTheme.shapes.large,
    ) {
        Column(Modifier.padding(18.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            if (result.isGroup) {
                Text(
                    (if (stampedSomeone) "✓ " else "") + LoyaltyTexts.groupSummary(result),
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Black,
                )
                Text("Se al tavolo sono di meno, tocca «Annulla».", style = MaterialTheme.typography.bodySmall)
            }
            result.members.forEach { member ->
                Text(
                    buildString {
                        if (member.outcome == StampOutcome.STAMPED) append("✓ ")
                        append(member.code?.let { "Cliente $it" } ?: "Persona")
                        append(" · ")
                        append(LoyaltyTexts.outcome(member, gapHours))
                    },
                    style = if (result.isGroup) MaterialTheme.typography.bodyLarge else MaterialTheme.typography.titleLarge,
                    fontWeight = if (result.isGroup) FontWeight.Normal else FontWeight.Black,
                )
            }
            result.members.firstNotNullOfOrNull { it.condition }?.let { condition ->
                Text("Condizione: ${LoyaltyTexts.condition(condition)}", style = MaterialTheme.typography.bodyMedium)
            }
            UndoButton(result.undoUntil, enabled = !busy && result.scanId != null, onUndo = onUndo)
        }
    }
    if (result.rewards.isNotEmpty()) {
        SectionCard(title = "🎁 Premi da consegnare", subtitle = "Il cliente può dire «la prossima volta»: in quel caso non toccare niente.") {
            result.rewards.forEach { reward ->
                RewardRow(reward, used = reward.rewardId in usedRewards, busy = busy, onUse = onUseReward)
            }
        }
    }
}

@Composable
private fun UndoButton(until: Instant?, enabled: Boolean, onUndo: () -> Unit) {
    var now by remember { mutableStateOf(Instant.now()) }
    LaunchedEffect(until) {
        while (until != null && Instant.now().isBefore(until)) {
            now = Instant.now()
            delay(1_000)
        }
        now = Instant.now()
    }
    val left = LoyaltyTexts.countdown(until, now) ?: return
    OutlinedButton(onClick = onUndo, enabled = enabled, modifier = Modifier.fillMaxWidth()) {
        Text("Annulla (ancora $left)")
    }
}

@Composable
private fun RewardRow(reward: LoyaltyReward, used: Boolean, busy: Boolean, onUse: (LoyaltyReward, String) -> Unit) {
    var amount by rememberSaveable(reward.rewardId) { mutableStateOf("") }
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Text(
            "${reward.code?.let { "Cliente $it · " }.orEmpty()}${LoyaltyTexts.reward(reward.rules)}",
            style = MaterialTheme.typography.bodyLarge,
            fontWeight = FontWeight.SemiBold,
        )
        val rules = LoyaltyTexts.rewardUse(reward.rules).drop(1).dropLast(1)
        Text(rules.joinToString(" · "), style = MaterialTheme.typography.bodySmall)
        reward.expiresAt?.let { Text("Valido fino al ${LOYALTY_DATE.format(it)}", style = MaterialTheme.typography.bodySmall) }
        when {
            used -> Text(
                if (reward.rules.kind == RewardKind.GIFT) "✓ Consegnato" else "✓ Applicato",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
            )
            !reward.usableNow -> Text(
                if (reward.usableFrom?.isAfter(Instant.now()) == true) "Si usa dalla visita successiva." else "Oggi non si usa (giorni scelti dal locale).",
                style = MaterialTheme.typography.bodyMedium,
            )
            reward.rules.kind == RewardKind.GIFT -> Button(onClick = { onUse(reward, "") }, enabled = !busy, modifier = Modifier.fillMaxWidth()) {
                Text("Consegnato")
            }
            else -> Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedTextField(
                    value = amount,
                    onValueChange = { amount = it.take(8) },
                    label = { Text("Sconto fatto (€)") },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    modifier = Modifier.weight(1f),
                )
                Button(onClick = { onUse(reward, amount) }, enabled = !busy) { Text("Applicato") }
            }
        }
    }
}

@Composable
private fun CodeEntry(enabled: Boolean, onSubmit: (String) -> Unit) {
    var open by rememberSaveable { mutableStateOf(false) }
    var code by rememberSaveable { mutableStateOf("") }
    if (!open) {
        OutlinedButton(onClick = { open = true }, enabled = enabled, modifier = Modifier.fillMaxWidth()) {
            Text("Inserisci codice (se il QR non si legge)")
        }
        return
    }
    SectionCard(title = "Codice di riserva", subtitle = "I 6 caratteri sotto il QR del cliente.") {
        OutlinedTextField(
            value = code,
            onValueChange = { text -> code = text.uppercase().filter { it.isLetterOrDigit() }.take(6) },
            label = { Text("Codice") },
            singleLine = true,
            textStyle = MaterialTheme.typography.headlineSmall.copy(fontFamily = FontFamily.Monospace),
            keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.Characters, keyboardType = KeyboardType.Ascii),
            modifier = Modifier.fillMaxWidth(),
        )
        Button(
            onClick = {
                onSubmit(code)
                code = ""
            },
            enabled = enabled && code.length == 6,
            modifier = Modifier.fillMaxWidth(),
        ) { Text("Timbra con il codice") }
    }
}
