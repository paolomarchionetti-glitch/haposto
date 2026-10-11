package com.haposto.ui.screens.loyalty

import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material3.Button
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.haposto.data.loyalty.ConditionKind
import com.haposto.data.loyalty.DoubleDay
import com.haposto.data.loyalty.DoubleSlot
import com.haposto.data.loyalty.LoyaltyDraft
import com.haposto.data.loyalty.LoyaltyLimits
import com.haposto.data.loyalty.LoyaltyTexts
import com.haposto.data.loyalty.RewardFrom
import com.haposto.data.loyalty.RewardKind
import com.haposto.ui.components.BannerKind
import com.haposto.ui.components.BigActionButton
import com.haposto.ui.components.MessageBanner
import com.haposto.ui.components.SectionCard
import com.haposto.ui.components.SimpleScreen

private val STEP_TITLES = listOf("Timbri", "Condizione", "Giorno doppio", "Premio", "Come si usa il premio", "Riepilogo e patto")

/** Procedura guidata (T11–T19): sei passi, poi il patto con «Accetto». */
@Composable
internal fun LoyaltyWizardScreen(
    draft: LoyaltyDraft,
    step: Int,
    limits: LoyaltyLimits,
    isNewVersion: Boolean,
    nextVersion: Int,
    pactAccepted: Boolean,
    busy: Boolean,
    message: String?,
    needsMfa: Boolean,
    onOpenMfa: () -> Unit,
    onChange: ((LoyaltyDraft) -> LoyaltyDraft) -> Unit,
    onStep: (Int) -> Unit,
    onPactAccepted: (Boolean) -> Unit,
    onPublish: () -> Unit,
    onCancel: () -> Unit,
) {
    SimpleScreen(
        title = if (isNewVersion) "Nuove regole della tessera" else "Attiva la tessera",
        onBack = if (step > 0) ({ onStep(step - 1) }) else onCancel,
    ) {
        Text(
            "Passo ${step + 1} di ${STEP_TITLES.size} · ${STEP_TITLES[step]}",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
        )
        message?.let { MessageBanner(it, BannerKind.ERROR) }
        if (needsMfa) BigActionButton(text = "Inserisci il codice", onClick = onOpenMfa)

        when (step) {
            0 -> StampsStep(draft, limits, onChange)
            1 -> ConditionStep(draft, limits, onChange)
            2 -> DoubleDayStep(draft, onChange)
            3 -> RewardStep(draft, limits, onChange)
            4 -> RewardUseStep(draft, limits, onChange)
            else -> SummaryStep(draft, limits, isNewVersion, nextVersion, pactAccepted, busy, onPactAccepted, onPublish)
        }

        if (step < STEP_TITLES.size - 1) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedButton(
                    onClick = if (step > 0) ({ onStep(step - 1) }) else onCancel,
                    modifier = Modifier.weight(1f).heightIn(min = 52.dp),
                ) { Text(if (step > 0) "Indietro" else "Annulla") }
                Button(onClick = { onStep(step + 1) }, modifier = Modifier.weight(1f).heightIn(min = 52.dp)) {
                    Text("Avanti")
                }
            }
        }
        Spacer(Modifier.height(16.dp))
    }
}

@Composable
private fun StampsStep(draft: LoyaltyDraft, limits: LoyaltyLimits, onChange: ((LoyaltyDraft) -> LoyaltyDraft) -> Unit) {
    SectionCard(title = "Quanti timbri servono per il premio?", subtitle = "Le tessere di carta più usate ne hanno 10.") {
        NumberStepper(
            value = draft.stampsRequired,
            range = limits.stampsMin..limits.stampsMax,
            onChange = { value -> onChange { it.copy(stampsRequired = value) } },
            format = { "$it timbri" },
        )
    }
}

@Composable
private fun ConditionStep(draft: LoyaltyDraft, limits: LoyaltyLimits, onChange: ((LoyaltyDraft) -> LoyaltyDraft) -> Unit) {
    SectionCard(
        title = "Quando si dà il timbro?",
        subtitle = "La condizione la controlla lo staff alla cassa e vale per ogni persona, anche nei gruppi.",
    ) {
        ChoiceRow("Spesa minima a persona", draft.conditionKind == ConditionKind.SPEND, { onChange { it.copy(conditionKind = ConditionKind.SPEND) } })
        ChoiceRow("Almeno una consumazione fra quelle scelte", draft.conditionKind == ConditionKind.ONE_OF, { onChange { it.copy(conditionKind = ConditionKind.ONE_OF) } })
        ChoiceRow("Almeno due consumazioni diverse fra quelle scelte", draft.conditionKind == ConditionKind.TWO_OF, { onChange { it.copy(conditionKind = ConditionKind.TWO_OF) } })
        if (draft.conditionKind == ConditionKind.SPEND) {
            NumberStepper(
                value = draft.minSpendEuro,
                range = (limits.spendMinCents / 100)..(limits.spendMaxCents / 100),
                onChange = { value -> onChange { it.copy(minSpendEuro = value) } },
                format = { "$it €" },
            )
        } else {
            LoyaltyTexts.CONDITION_TYPES.forEach { type ->
                CheckRow(
                    text = LoyaltyTexts.conditionType(type).replaceFirstChar { it.uppercase() },
                    checked = type in draft.types,
                    onChange = { checked -> onChange { it.copy(types = if (checked) it.types + type else it.types - type) } },
                )
            }
        }
        Text("Ai clienti: «${LoyaltyTexts.condition(draft.toRules(limits).condition)}»", style = MaterialTheme.typography.bodySmall)
    }
}

@Composable
private fun DoubleDayStep(draft: LoyaltyDraft, onChange: ((LoyaltyDraft) -> LoyaltyDraft) -> Unit) {
    SectionCard(
        title = "Un giorno a timbro doppio?",
        subtitle = "Facoltativo: aiuta a riempire un giorno più tranquillo. Al massimo uno a settimana.",
    ) {
        ChoiceRow("Nessun giorno doppio", draft.doubleWeekday == null, { onChange { it.copy(doubleWeekday = null) } })
        ChoiceRow("Un giorno a settimana", draft.doubleWeekday != null, { onChange { it.copy(doubleWeekday = it.doubleWeekday ?: 2) } })
        if (draft.doubleWeekday != null) {
            Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                (1..7).forEach { day ->
                    FilterChip(
                        selected = draft.doubleWeekday == day,
                        onClick = { onChange { it.copy(doubleWeekday = day) } },
                        label = { Text(LoyaltyTexts.weekdayShort(day)) },
                    )
                }
            }
            Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                DoubleSlot.entries.forEach { slot ->
                    FilterChip(
                        selected = draft.doubleSlot == slot,
                        onClick = { onChange { it.copy(doubleSlot = slot) } },
                        label = { Text(LoyaltyTexts.slot(slot)) },
                    )
                }
            }
        }
        Text(LoyaltyTexts.doubleDay(draft.doubleWeekday?.let { DoubleDay(it, draft.doubleSlot) }), style = MaterialTheme.typography.bodySmall)
    }
}

@Composable
private fun RewardStep(draft: LoyaltyDraft, limits: LoyaltyLimits, onChange: ((LoyaltyDraft) -> LoyaltyDraft) -> Unit) {
    SectionCard(
        title = "Qual è il premio?",
        subtitle = "Sempre personale, mai in denaro, niente alcolici. Il locale non ci deve perdere.",
    ) {
        ChoiceRow("🎁 Un omaggio dalla lista", draft.rewardKind == RewardKind.GIFT, { onChange { it.copy(rewardKind = RewardKind.GIFT) } })
        ChoiceRow("％ Uno sconto sulla sua consumazione", draft.rewardKind == RewardKind.DISCOUNT, { onChange { it.copy(rewardKind = RewardKind.DISCOUNT) } })
        ChoiceRow("🎟 Un buono per la visita dopo", draft.rewardKind == RewardKind.VOUCHER, { onChange { it.copy(rewardKind = RewardKind.VOUCHER) } })
    }
    when (draft.rewardKind) {
        RewardKind.GIFT -> SectionCard(title = "Omaggio") {
            LoyaltyTexts.GIFTS.forEach { gift ->
                ChoiceRow(LoyaltyTexts.gift(gift), draft.gift == gift, { onChange { it.copy(gift = gift) } })
            }
        }
        RewardKind.DISCOUNT -> SectionCard(title = "Sconto personale", subtitle = "Solo sulla consumazione di chi ha il premio, mai sul tavolo.") {
            Text("Percentuale", style = MaterialTheme.typography.labelLarge)
            NumberStepper(
                value = draft.percent,
                range = limits.discountPercentMin..limits.discountPercentMax,
                onChange = { value -> onChange { it.copy(percent = value) } },
                format = { "$it%" },
                step = 5,
            )
            Text("Tetto massimo (obbligatorio)", style = MaterialTheme.typography.labelLarge)
            NumberStepper(
                value = draft.capEuro,
                range = (limits.discountCapMinCents / 100)..(limits.discountCapMaxCents / 100),
                onChange = { value -> onChange { it.copy(capEuro = value) } },
                format = { "max $it €" },
            )
            SwitchRow("Con una spesa minima", draft.discountMinSpendEuro != null, { on ->
                onChange { it.copy(discountMinSpendEuro = if (on) 20 else null) }
            })
            draft.discountMinSpendEuro?.let { minSpend ->
                NumberStepper(
                    value = minSpend,
                    range = 5..200,
                    onChange = { value -> onChange { it.copy(discountMinSpendEuro = value) } },
                    format = { "almeno $it €" },
                    step = 5,
                )
            }
        }
        RewardKind.VOUCHER -> SectionCard(title = "Buono per la visita dopo", subtitle = "Si usa dalla visita successiva e non dà resto.") {
            Text("Valore del buono", style = MaterialTheme.typography.labelLarge)
            NumberStepper(
                value = draft.voucherEuro,
                range = (limits.voucherMinCents / 100)..(limits.voucherMaxCents / 100),
                onChange = { value ->
                    onChange { it.copy(voucherEuro = value, voucherMinSpendEuro = maxOf(it.voucherMinSpendEuro, value * 2)) }
                },
                format = { "$it €" },
            )
            Text("Spesa minima per usarlo (almeno il doppio)", style = MaterialTheme.typography.labelLarge)
            NumberStepper(
                value = draft.voucherMinSpendEuro,
                range = (draft.voucherEuro * 2)..200,
                onChange = { value -> onChange { it.copy(voucherMinSpendEuro = value) } },
                format = { "almeno $it €" },
            )
        }
    }
    Text("Ai clienti: «${LoyaltyTexts.reward(draft.toRules(limits).reward, forCustomer = true)}»", style = MaterialTheme.typography.bodySmall)
}

@Composable
private fun RewardUseStep(draft: LoyaltyDraft, limits: LoyaltyLimits, onChange: ((LoyaltyDraft) -> LoyaltyDraft) -> Unit) {
    SectionCard(title = "Da quando si usa") {
        val voucher = draft.rewardKind == RewardKind.VOUCHER
        ChoiceRow("Subito, anche alla stessa visita", draft.effectiveFrom == RewardFrom.SAME_VISIT, { onChange { it.copy(from = RewardFrom.SAME_VISIT) } }, enabled = !voucher)
        ChoiceRow("Dalla visita successiva", draft.effectiveFrom == RewardFrom.NEXT_VISIT, { onChange { it.copy(from = RewardFrom.NEXT_VISIT) } }, enabled = !voucher)
        Text(
            if (voucher) "Il buono si usa sempre dalla visita dopo." else "«Dalla visita successiva» è un motivo in più per tornare.",
            style = MaterialTheme.typography.bodySmall,
        )
    }
    SectionCard(title = "In quali giorni", subtitle = "Tutti, oppure almeno 3 a settimana (per esempio non il venerdì e il sabato).") {
        SwitchRow("Tutti i giorni", draft.weekdays.isEmpty(), { all ->
            onChange { it.copy(weekdays = if (all) emptySet() else setOf(1, 2, 3, 4)) }
        })
        if (draft.weekdays.isNotEmpty()) {
            Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                (1..7).forEach { day ->
                    FilterChip(
                        selected = day in draft.weekdays,
                        onClick = {
                            onChange { current ->
                                val days = if (day in current.weekdays) current.weekdays - day else current.weekdays + day
                                // Tutti e sette = «tutti i giorni»; meno di 3 non si salva (lo dice il riepilogo).
                                current.copy(weekdays = if (days.size == 7) emptySet() else days)
                            }
                        },
                        label = { Text(LoyaltyTexts.weekdayShort(day)) },
                    )
                }
            }
        }
    }
    SectionCard(title = "Quanti premi per tavolo alla stessa visita", subtitle = "Gli altri restano validi per un'altra visita: niente «30 dolci in una volta».") {
        SwitchRow("Senza limite", draft.maxPerTable == null, { unlimited -> onChange { it.copy(maxPerTable = if (unlimited) null else 4) } })
        draft.maxPerTable?.let { max ->
            NumberStepper(
                value = max,
                range = 1..10,
                onChange = { value -> onChange { it.copy(maxPerTable = value) } },
                format = { "$it per tavolo" },
            )
        }
    }
    SectionCard(title = "Altre offerte") {
        SwitchRow("Cumulabile con l'offerta della serata e altre promozioni", draft.cumulable, { on -> onChange { it.copy(cumulable = on) } })
        Text("Il premio vale ${limits.rewardValidDays} giorni dallo sblocco (uguale per tutti).", style = MaterialTheme.typography.bodySmall)
    }
}

@Composable
private fun SummaryStep(
    draft: LoyaltyDraft,
    limits: LoyaltyLimits,
    isNewVersion: Boolean,
    nextVersion: Int,
    pactAccepted: Boolean,
    busy: Boolean,
    onPactAccepted: (Boolean) -> Unit,
    onPublish: () -> Unit,
) {
    val problems = draft.problems(limits)
    SectionCard(title = "Riepilogo (versione $nextVersion)") {
        RulesSummary(draft.toRules(limits, nextVersion))
        if (isNewVersion) {
            Text(
                "Vale solo per chi inizia da oggi, con i timbri a zero. Chi ha già timbri completa con le regole di prima.",
                style = MaterialTheme.typography.bodySmall,
            )
        }
    }
    if (problems.isNotEmpty()) {
        MessageBanner(problems.joinToString("\n"), BannerKind.ERROR)
    }
    SectionCard(title = "Il patto", subtitle = "Le regole non si possono cambiare per chi ha già iniziato.") {
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            LoyaltyTexts.pact(limits.closingNoticeDays).forEach { line ->
                Text("• $line", style = MaterialTheme.typography.bodyLarge)
            }
        }
        CheckRow("Accetto", pactAccepted, onPactAccepted, enabled = problems.isEmpty() && !busy)
        Text("L'accettazione si registra con data, versione e account. Serve la verifica in due passaggi.", style = MaterialTheme.typography.bodySmall)
    }
    BigActionButton(
        text = if (isNewVersion) "Pubblica le nuove regole" else "Attiva la tessera",
        onClick = onPublish,
        enabled = pactAccepted && problems.isEmpty() && !busy,
    )
}
