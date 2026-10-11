package com.haposto.data.loyalty

import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.add
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlinx.serialization.json.putJsonArray
import kotlinx.serialization.json.putJsonObject

/**
 * Le scelte della procedura guidata (T11–T15, T40–T46), in euro interi. Il server ricontrolla
 * tutto ([toJson] diventa p_rules di publish_loyalty_version); qui si avvisa prima.
 * [weekdays] vuoto = tutti i giorni; [maxPerTable] null = senza limite.
 */
data class LoyaltyDraft(
    val stampsRequired: Int = 10,
    val conditionKind: ConditionKind = ConditionKind.ONE_OF,
    val minSpendEuro: Int = 15,
    val types: Set<String> = setOf("FIRST_COURSE", "MAIN_COURSE", "PIZZA"),
    val doubleWeekday: Int? = null,
    val doubleSlot: DoubleSlot = DoubleSlot.ALL_DAY,
    val rewardKind: RewardKind = RewardKind.GIFT,
    val gift: String = "DESSERT",
    val percent: Int = 20,
    val capEuro: Int = 10,
    val discountMinSpendEuro: Int? = null,
    val voucherEuro: Int = 5,
    val voucherMinSpendEuro: Int = 15,
    val from: RewardFrom = RewardFrom.NEXT_VISIT,
    val weekdays: Set<Int> = emptySet(),
    val maxPerTable: Int? = 4,
    val cumulable: Boolean = false,
) {
    /** Il buono si usa sempre dalla visita successiva (T42). */
    val effectiveFrom: RewardFrom get() = if (rewardKind == RewardKind.VOUCHER) RewardFrom.NEXT_VISIT else from

    /** Cosa non va, in italiano; vuoto = si può pubblicare. */
    fun problems(limits: LoyaltyLimits): List<String> = buildList {
        if (stampsRequired !in limits.stampsMin..limits.stampsMax) {
            add("I timbri per il premio vanno da ${limits.stampsMin} a ${limits.stampsMax}.")
        }
        when (conditionKind) {
            ConditionKind.SPEND -> if (minSpendEuro * 100 !in limits.spendMinCents..limits.spendMaxCents) {
                add("La spesa minima va da ${LoyaltyTexts.euro(limits.spendMinCents)} a ${LoyaltyTexts.euro(limits.spendMaxCents)}.")
            }
            ConditionKind.ONE_OF -> if (types.isEmpty()) add("Scegli almeno una tipologia di consumazione.")
            ConditionKind.TWO_OF -> if (types.size < 2) add("Per «due consumazioni diverse» scegli almeno due tipologie.")
        }
        if (doubleWeekday != null && doubleWeekday !in 1..7) add("Giorno doppio non valido.")
        when (rewardKind) {
            RewardKind.GIFT -> if (gift !in LoyaltyTexts.GIFTS) add("Scegli l'omaggio dalla lista.")
            RewardKind.DISCOUNT -> {
                if (percent !in limits.discountPercentMin..limits.discountPercentMax) {
                    add("Lo sconto va dal ${limits.discountPercentMin} al ${limits.discountPercentMax}%.")
                }
                if (capEuro * 100 !in limits.discountCapMinCents..limits.discountCapMaxCents) {
                    add("Il tetto dello sconto va da ${LoyaltyTexts.euro(limits.discountCapMinCents)} a ${LoyaltyTexts.euro(limits.discountCapMaxCents)}.")
                }
                if (discountMinSpendEuro != null && discountMinSpendEuro !in 1..500) add("Spesa minima per lo sconto non valida.")
            }
            RewardKind.VOUCHER -> {
                if (voucherEuro * 100 !in limits.voucherMinCents..limits.voucherMaxCents) {
                    add("Il buono va da ${LoyaltyTexts.euro(limits.voucherMinCents)} a ${LoyaltyTexts.euro(limits.voucherMaxCents)}.")
                }
                if (voucherMinSpendEuro < 2 * voucherEuro || voucherMinSpendEuro > 500) {
                    add("Per il buono la spesa minima è almeno il doppio del buono (${LoyaltyTexts.euro(voucherEuro * 200)}).")
                }
            }
        }
        if (weekdays.isNotEmpty() && (weekdays.size < 3 || weekdays.any { it !in 1..7 })) {
            add("Il premio si usa tutti i giorni oppure in almeno 3 giorni a settimana.")
        }
        if (maxPerTable != null && maxPerTable !in 1..10) add("Premi per tavolo: da 1 a 10, oppure senza limite.")
    }

    /** Le regole come le vedrà il cliente (riepilogo prima del patto). */
    fun toRules(limits: LoyaltyLimits, version: Int = 0): LoyaltyRules = LoyaltyRules(
        version = version,
        stampsRequired = stampsRequired,
        condition = LoyaltyCondition(
            kind = conditionKind,
            minSpendCents = if (conditionKind == ConditionKind.SPEND) minSpendEuro * 100 else null,
            types = if (conditionKind == ConditionKind.SPEND) emptyList() else LoyaltyTexts.CONDITION_TYPES.filter { it in types },
        ),
        doubleDay = doubleWeekday?.let { DoubleDay(it, doubleSlot) },
        reward = RewardRules(
            kind = rewardKind,
            gift = if (rewardKind == RewardKind.GIFT) gift else null,
            percent = if (rewardKind == RewardKind.DISCOUNT) percent else null,
            capCents = if (rewardKind == RewardKind.DISCOUNT) capEuro * 100 else null,
            amountCents = if (rewardKind == RewardKind.VOUCHER) voucherEuro * 100 else null,
            minSpendCents = when (rewardKind) {
                RewardKind.GIFT -> null
                RewardKind.DISCOUNT -> discountMinSpendEuro?.let { it * 100 }
                RewardKind.VOUCHER -> voucherMinSpendEuro * 100
            },
            from = effectiveFrom,
            weekdays = weekdays.sorted().takeIf { it.isNotEmpty() && it.size < 7 },
            maxPerTable = maxPerTable,
            cumulable = cumulable,
            validDays = limits.rewardValidDays,
        ),
        inactivityMonths = limits.inactivityMonths,
    )

    /** p_rules per publish_loyalty_version (migration 0018). */
    fun toJson(): JsonObject {
        val rules = toRules(LoyaltyLimits())
        return buildJsonObject {
            put("stamps_required", rules.stampsRequired)
            putJsonObject("condition") {
                put("kind", rules.condition.kind.name)
                if (rules.condition.kind == ConditionKind.SPEND) {
                    put("min_spend_cents", rules.condition.minSpendCents)
                } else {
                    putJsonArray("types") { rules.condition.types.forEach { add(it) } }
                }
            }
            val double = rules.doubleDay
            if (double == null) {
                put("double_day", JsonNull)
            } else {
                putJsonObject("double_day") {
                    put("weekday", double.weekday)
                    put("slot", double.slot.name)
                }
            }
            putJsonObject("reward") {
                val reward = rules.reward
                put("kind", reward.kind.name)
                reward.gift?.let { put("gift", it) }
                reward.percent?.let { put("percent", it) }
                reward.capCents?.let { put("cap_cents", it) }
                reward.amountCents?.let { put("amount_cents", it) }
                reward.minSpendCents?.let { put("min_spend_cents", it) }
                put("from", reward.from.name)
                val days = reward.weekdays
                if (days == null) put("weekdays", JsonNull) else putJsonArray("weekdays") { days.forEach { add(it) } }
                put("max_per_table", reward.maxPerTable)
                put("cumulable", reward.cumulable)
            }
        }
    }

    companion object {
        /** Riparte dalle regole attive («Cambia le regole» = nuova versione, T19). */
        fun from(rules: LoyaltyRules): LoyaltyDraft {
            val reward = rules.reward
            return LoyaltyDraft(
                stampsRequired = rules.stampsRequired,
                conditionKind = rules.condition.kind,
                minSpendEuro = (rules.condition.minSpendCents ?: 1500) / 100,
                types = rules.condition.types.toSet().ifEmpty { setOf("FIRST_COURSE", "MAIN_COURSE", "PIZZA") },
                doubleWeekday = rules.doubleDay?.weekday,
                doubleSlot = rules.doubleDay?.slot ?: DoubleSlot.ALL_DAY,
                rewardKind = reward.kind,
                gift = reward.gift ?: "DESSERT",
                percent = reward.percent ?: 20,
                capEuro = (reward.capCents ?: 1000) / 100,
                discountMinSpendEuro = if (reward.kind == RewardKind.DISCOUNT) reward.minSpendCents?.let { it / 100 } else null,
                voucherEuro = (reward.amountCents ?: 500) / 100,
                voucherMinSpendEuro = if (reward.kind == RewardKind.VOUCHER) (reward.minSpendCents ?: 1500) / 100 else 15,
                from = reward.from,
                weekdays = reward.weekdays.orEmpty().toSet(),
                maxPerTable = reward.maxPerTable,
                cumulable = reward.cumulable,
            )
        }
    }
}
