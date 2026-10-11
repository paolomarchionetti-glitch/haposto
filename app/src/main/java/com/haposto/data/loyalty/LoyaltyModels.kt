package com.haposto.data.loyalty

import java.time.Instant

/**
 * Tessera fedeltà (funzione nascosta, migration 0018; regole in docs/HAPOSTO_TESSERA_SPECIFICHE.md).
 * Il server decide sempre: queste classi descrivono solo quello che risponde.
 */
enum class ConditionKind { SPEND, ONE_OF, TWO_OF }

enum class RewardKind { GIFT, DISCOUNT, VOUCHER }

enum class RewardFrom { SAME_VISIT, NEXT_VISIT }

enum class DoubleSlot { ALL_DAY, LUNCH, DINNER }

/** NEW: timbra e apre tessere nuove · EXISTING: solo tessere iniziate · REWARDS: solo premi da consegnare. */
enum class LoyaltyLevel { NEW, EXISTING, REWARDS, NONE }

/** T12–T13: spesa minima a persona, oppure una o due consumazioni fra le tipologie scelte. */
data class LoyaltyCondition(
    val kind: ConditionKind,
    val minSpendCents: Int? = null,
    val types: List<String> = emptyList(),
)

/** T14: giorno ISO (1 = lunedì … 7 = domenica) e fascia. */
data class DoubleDay(val weekday: Int, val slot: DoubleSlot)

/** T40–T47: il premio e come si usa. [weekdays] null = tutti i giorni; [maxPerTable] null = senza limite. */
data class RewardRules(
    val kind: RewardKind,
    val gift: String? = null,
    val percent: Int? = null,
    val capCents: Int? = null,
    val amountCents: Int? = null,
    val minSpendCents: Int? = null,
    val from: RewardFrom = RewardFrom.SAME_VISIT,
    val weekdays: List<Int>? = null,
    val maxPerTable: Int? = null,
    val cumulable: Boolean = false,
    val validDays: Int = 60,
)

/** Una versione del programma del locale (immutabile, T18). */
data class LoyaltyRules(
    val version: Int,
    val stampsRequired: Int,
    val condition: LoyaltyCondition,
    val doubleDay: DoubleDay?,
    val reward: RewardRules,
    val inactivityMonths: Int = 6,
    val acceptedAt: Instant? = null,
)

/** Limiti delle scelte del ristoratore (impostazione `loyalty` dell'admin). */
data class LoyaltyLimits(
    val stampsMin: Int = 5,
    val stampsMax: Int = 20,
    val spendMinCents: Int = 500,
    val spendMaxCents: Int = 5000,
    val discountPercentMin: Int = 5,
    val discountPercentMax: Int = 50,
    val discountCapMinCents: Int = 500,
    val discountCapMaxCents: Int = 5000,
    val voucherMinCents: Int = 200,
    val voucherMaxCents: Int = 2000,
    val rewardValidDays: Int = 60,
    val inactivityMonths: Int = 6,
    val closingNoticeDays: Int = 30,
    val stampGapHours: Int = 4,
    val undoMinutes: Int = 2,
    val groupMaxPeople: Int = 20,
)

/** T53: segnalazioni ricevute (senza sapere chi) e soglie. */
data class LoyaltyReports(val count: Int, val warn: Int, val suspend: Int, val windowDays: Int)

data class LoyaltyVersionRow(val version: Int, val acceptedAt: Instant?)

/** Scheda «Tessera fedeltà» del locale. Con [visible] false la tessera non esiste per il locale. */
data class LoyaltyProgram(
    val visible: Boolean,
    val level: LoyaltyLevel = LoyaltyLevel.NONE,
    val canPublish: Boolean = false,
    val publishBlocker: String? = null,
    /** NONE, ACTIVE, CLOSING, SUSPENDED, REMOVED, ENDED. */
    val status: String = "NONE",
    val current: LoyaltyRules? = null,
    val versions: List<LoyaltyVersionRow> = emptyList(),
    val closingUntil: Instant? = null,
    val closingReason: String? = null,
    val suspendedUntil: Instant? = null,
    val activeCards: Int = 0,
    val rewardsAvailable: Int = 0,
    val reports: LoyaltyReports? = null,
    val limits: LoyaltyLimits = LoyaltyLimits(),
) {
    /** T34: «Timbra» solo con la tessera attiva, in preavviso o con premi ancora da consegnare. */
    val canScan: Boolean get() = visible && level != LoyaltyLevel.NONE

    companion object {
        val HIDDEN = LoyaltyProgram(visible = false)
    }
}

/** Esito per persona di una scansione (codici della migration 0018). */
enum class StampOutcome { STAMPED, TOO_SOON, SELF, NO_ACCESS, NO_NEW_CARDS, PROGRAM_ENDED, UNKNOWN }

/** Una persona della scansione: solo il codice anonimo, mai dati personali (T55). */
data class StampMember(
    val code: String?,
    val outcome: StampOutcome,
    val stampsAdded: Int = 0,
    val doubleDay: Boolean = false,
    val stamps: Int? = null,
    val required: Int? = null,
    val rewardUnlocked: Boolean = false,
    val carry: Int = 0,
    val condition: LoyaltyCondition? = null,
)

/** Un premio da consegnare, con le regole della sua versione. */
data class LoyaltyReward(
    val rewardId: String,
    val code: String?,
    val rules: RewardRules,
    val unlockedAt: Instant?,
    val usableFrom: Instant?,
    val expiresAt: Instant?,
    val usableNow: Boolean,
)

/** Risposta di register_stamp. Con [ok] false, [error] dice perché (QR usato, codice sbagliato…). */
data class StampResult(
    val ok: Boolean,
    val error: String? = null,
    val attemptsLeft: Int? = null,
    val lockedUntil: Instant? = null,
    val scanId: String? = null,
    val isGroup: Boolean = false,
    val people: Int = 0,
    val stamped: Int = 0,
    val stamps: Int = 0,
    val undoUntil: Instant? = null,
    val members: List<StampMember> = emptyList(),
    val rewards: List<LoyaltyReward> = emptyList(),
)

data class HourCount(val weekday: Int, val hour: Int, val scans: Int)

/** Statistiche della tessera (§11): solo numeri. */
data class LoyaltyStats(
    val days: Int,
    val scans: Int = 0,
    val groupScans: Int = 0,
    val people: Int = 0,
    val stamps: Int = 0,
    val doubleStamps: Int = 0,
    val newCustomers: Int = 0,
    val returningPeople: Int = 0,
    val cardsStarted: Int = 0,
    val rewardsUnlocked: Int = 0,
    val rewardsUsed: Int = 0,
    val rewardsExpired: Int = 0,
    val discountCents: Int = 0,
    val activeCards: Int = 0,
    val nearRewardOne: Int = 0,
    val nearRewardTwo: Int = 0,
    val byHour: List<HourCount> = emptyList(),
)

/** Una tessera attiva nell'elenco del locale: codice anonimo e numeri. */
data class LoyaltyCardRow(
    val code: String,
    val stamps: Int,
    val required: Int,
    val version: Int,
    val startedAt: Instant?,
    val lastStampAt: Instant?,
    val rewardsAvailable: Int,
)

/** Contenuto dei QR della tessera (personale e del tavolo): solo un codice casuale (T56). */
object LoyaltyQr {
    const val PREFIX = "haposto:tessera:"

    private val token = Regex("^[0-9a-f]{32}$")

    fun encode(token: String): String = PREFIX + token

    /** Il codice del QR, oppure null se non è un QR della tessera HAPOSTO. */
    fun tokenFrom(raw: String?): String? {
        val text = raw?.trim().orEmpty()
        if (!text.startsWith(PREFIX, ignoreCase = true)) return null
        return text.substring(PREFIX.length).lowercase().takeIf { token.matches(it) }
    }
}
