package com.haposto.data.remote.supabase

import com.haposto.data.Outcome
import com.haposto.data.loyalty.ConditionKind
import com.haposto.data.loyalty.DoubleDay
import com.haposto.data.loyalty.DoubleSlot
import com.haposto.data.loyalty.HourCount
import com.haposto.data.loyalty.LoyaltyCardRow
import com.haposto.data.loyalty.LoyaltyCondition
import com.haposto.data.loyalty.LoyaltyDraft
import com.haposto.data.loyalty.LoyaltyLevel
import com.haposto.data.loyalty.LoyaltyLimits
import com.haposto.data.loyalty.LoyaltyProgram
import com.haposto.data.loyalty.LoyaltyReports
import com.haposto.data.loyalty.LoyaltyReward
import com.haposto.data.loyalty.LoyaltyRules
import com.haposto.data.loyalty.LoyaltyStats
import com.haposto.data.loyalty.LoyaltyVersionRow
import com.haposto.data.loyalty.RestaurantLoyaltyRepository
import com.haposto.data.loyalty.RewardFrom
import com.haposto.data.loyalty.RewardKind
import com.haposto.data.loyalty.RewardRules
import com.haposto.data.loyalty.StampMember
import com.haposto.data.loyalty.StampOutcome
import com.haposto.data.loyalty.StampResult
import com.haposto.data.outcomeOf
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.postgrest.postgrest
import java.time.Instant
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

class SupabaseLoyaltyRepository(private val client: SupabaseClient) : RestaurantLoyaltyRepository {

    private suspend fun rpc(name: String, params: JsonObject): String = client.postgrest.rpc(name, params).data

    /** Chiamata senza risultato da leggere. */
    private suspend fun call(name: String, params: JsonObject) {
        client.postgrest.rpc(name, params)
    }

    override suspend fun program(restaurantId: String): Outcome<LoyaltyProgram> = outcomeOf {
        decodeLoyaltyProgram(rpc("restaurant_loyalty_program", buildJsonObject { put("p_restaurant_id", restaurantId) }))
    }

    override suspend fun publish(restaurantId: String, draft: LoyaltyDraft): Outcome<Int> = outcomeOf {
        loyaltyJson.decodeFromString<LoyaltyPublishDto>(
            rpc("publish_loyalty_version", buildJsonObject {
                put("p_restaurant_id", restaurantId)
                put("p_rules", draft.toJson())
                put("p_pact_accepted", true)
            }),
        ).version
    }

    override suspend fun close(restaurantId: String): Outcome<Instant?> = outcomeOf {
        loyaltyJson.decodeFromString<String?>(
            rpc("close_loyalty_program", buildJsonObject { put("p_restaurant_id", restaurantId) }),
        )?.let(::parseTimestamp)
    }

    override suspend fun stampToken(restaurantId: String, token: String): Outcome<StampResult> = outcomeOf {
        decodeStampResult(rpc("register_stamp", buildJsonObject {
            put("p_restaurant_id", restaurantId)
            put("p_token", token)
        }))
    }

    override suspend fun stampCode(restaurantId: String, code: String): Outcome<StampResult> = outcomeOf {
        decodeStampResult(rpc("register_stamp", buildJsonObject {
            put("p_restaurant_id", restaurantId)
            put("p_code", code.trim())
        }))
    }

    override suspend fun undo(scanId: String): Outcome<Unit> = outcomeOf {
        call("undo_stamp", buildJsonObject { put("p_scan_id", scanId) })
    }

    override suspend fun useReward(restaurantId: String, rewardId: String, discountCents: Int?): Outcome<Unit> = outcomeOf {
        call("use_reward", buildJsonObject {
            put("p_restaurant_id", restaurantId)
            put("p_reward_id", rewardId)
            put("p_discount_cents", discountCents)
        })
    }

    override suspend fun stats(restaurantId: String, days: Int): Outcome<LoyaltyStats> = outcomeOf {
        decodeLoyaltyStats(rpc("restaurant_loyalty_stats", buildJsonObject {
            put("p_restaurant_id", restaurantId)
            put("p_days", days)
        }))
    }

    override suspend fun cards(restaurantId: String): Outcome<List<LoyaltyCardRow>> = outcomeOf {
        decodeLoyaltyCards(rpc("restaurant_loyalty_cards", buildJsonObject {
            put("p_restaurant_id", restaurantId)
            put("p_limit", 200)
        }))
    }
}

internal val loyaltyJson = Json { ignoreUnknownKeys = true }

/** Le funzioni internal servono ai test (JSON vero della migration 0018). */
internal fun decodeLoyaltyProgram(text: String): LoyaltyProgram =
    loyaltyJson.decodeFromString<LoyaltyProgramDto>(text).toDomain()

internal fun decodeStampResult(text: String): StampResult =
    loyaltyJson.decodeFromString<LoyaltyStampResultDto>(text).toDomain()

internal fun decodeLoyaltyStats(text: String): LoyaltyStats =
    loyaltyJson.decodeFromString<LoyaltyStatsDto>(text).toDomain()

internal fun decodeLoyaltyCards(text: String): List<LoyaltyCardRow> =
    loyaltyJson.decodeFromString<List<LoyaltyCardDto>>(text).map { it.toDomain() }

internal inline fun <reified T : Enum<T>> enumOr(value: String?, fallback: T): T =
    enumValues<T>().firstOrNull { it.name == value } ?: fallback

@Serializable
internal data class LoyaltyPublishDto(val version: Int = 0)

@Serializable
internal data class LoyaltyConditionDto(
    val kind: String = "ONE_OF",
    @SerialName("min_spend_cents") val minSpendCents: Int? = null,
    val types: List<String>? = null,
) {
    fun toDomain() = LoyaltyCondition(enumOr(kind, ConditionKind.ONE_OF), minSpendCents, types.orEmpty())
}

@Serializable
internal data class LoyaltyDoubleDayDto(val weekday: Int = 0, val slot: String = "ALL_DAY")

@Serializable
internal data class LoyaltyRewardDto(
    val kind: String = "GIFT",
    val gift: String? = null,
    val percent: Int? = null,
    @SerialName("cap_cents") val capCents: Int? = null,
    @SerialName("amount_cents") val amountCents: Int? = null,
    @SerialName("min_spend_cents") val minSpendCents: Int? = null,
    val from: String? = null,
    val weekdays: List<Int>? = null,
    @SerialName("max_per_table") val maxPerTable: Int? = null,
    val cumulable: Boolean = false,
    @SerialName("valid_days") val validDays: Int = 60,
) {
    fun toDomain() = RewardRules(
        kind = enumOr(kind, RewardKind.GIFT),
        gift = gift,
        percent = percent,
        capCents = capCents,
        amountCents = amountCents,
        minSpendCents = minSpendCents,
        from = enumOr(from, RewardFrom.SAME_VISIT),
        weekdays = weekdays,
        maxPerTable = maxPerTable,
        cumulable = cumulable,
        validDays = validDays,
    )
}

@Serializable
internal data class LoyaltyRulesDto(
    val version: Int = 0,
    @SerialName("stamps_required") val stampsRequired: Int = 0,
    val condition: LoyaltyConditionDto = LoyaltyConditionDto(),
    @SerialName("double_day") val doubleDay: LoyaltyDoubleDayDto? = null,
    val reward: LoyaltyRewardDto = LoyaltyRewardDto(),
    @SerialName("inactivity_months") val inactivityMonths: Int = 6,
    @SerialName("accepted_at") val acceptedAt: String? = null,
) {
    fun toDomain() = LoyaltyRules(
        version = version,
        stampsRequired = stampsRequired,
        condition = condition.toDomain(),
        doubleDay = doubleDay?.let { DoubleDay(it.weekday, enumOr(it.slot, DoubleSlot.ALL_DAY)) },
        reward = reward.toDomain(),
        inactivityMonths = inactivityMonths,
        acceptedAt = acceptedAt?.let(::parseTimestamp),
    )
}

@Serializable
internal data class LoyaltyLimitsDto(
    @SerialName("stamps_min") val stampsMin: Int = 5,
    @SerialName("stamps_max") val stampsMax: Int = 20,
    @SerialName("spend_min_cents") val spendMinCents: Int = 500,
    @SerialName("spend_max_cents") val spendMaxCents: Int = 5000,
    @SerialName("discount_percent_min") val discountPercentMin: Int = 5,
    @SerialName("discount_percent_max") val discountPercentMax: Int = 50,
    @SerialName("discount_cap_min_cents") val discountCapMinCents: Int = 500,
    @SerialName("discount_cap_max_cents") val discountCapMaxCents: Int = 5000,
    @SerialName("voucher_min_cents") val voucherMinCents: Int = 200,
    @SerialName("voucher_max_cents") val voucherMaxCents: Int = 2000,
    @SerialName("reward_valid_days") val rewardValidDays: Int = 60,
    @SerialName("inactivity_months") val inactivityMonths: Int = 6,
    @SerialName("closing_notice_days") val closingNoticeDays: Int = 30,
    @SerialName("stamp_gap_hours") val stampGapHours: Int = 4,
    @SerialName("undo_minutes") val undoMinutes: Int = 2,
    @SerialName("group_max_people") val groupMaxPeople: Int = 20,
) {
    fun toDomain() = LoyaltyLimits(
        stampsMin, stampsMax, spendMinCents, spendMaxCents, discountPercentMin, discountPercentMax,
        discountCapMinCents, discountCapMaxCents, voucherMinCents, voucherMaxCents, rewardValidDays,
        inactivityMonths, closingNoticeDays, stampGapHours, undoMinutes, groupMaxPeople,
    )
}

@Serializable
internal data class LoyaltyReportsDto(
    val count: Int = 0,
    val warn: Int = 3,
    val suspend: Int = 5,
    @SerialName("window_days") val windowDays: Int = 60,
)

@Serializable
internal data class LoyaltyVersionDto(val version: Int = 0, @SerialName("accepted_at") val acceptedAt: String? = null)

@Serializable
internal data class LoyaltyProgramDto(
    val visible: Boolean = false,
    val level: String? = null,
    @SerialName("can_publish") val canPublish: Boolean = false,
    @SerialName("publish_blocker") val publishBlocker: String? = null,
    val status: String = "NONE",
    val current: LoyaltyRulesDto? = null,
    val versions: List<LoyaltyVersionDto> = emptyList(),
    @SerialName("closing_until") val closingUntil: String? = null,
    @SerialName("closing_reason") val closingReason: String? = null,
    @SerialName("suspended_until") val suspendedUntil: String? = null,
    @SerialName("active_cards") val activeCards: Int = 0,
    @SerialName("rewards_available") val rewardsAvailable: Int = 0,
    val reports: LoyaltyReportsDto? = null,
    val limits: LoyaltyLimitsDto = LoyaltyLimitsDto(),
) {
    fun toDomain() = if (!visible) {
        LoyaltyProgram.HIDDEN
    } else {
        LoyaltyProgram(
            visible = true,
            level = enumOr(level, LoyaltyLevel.NONE),
            canPublish = canPublish,
            publishBlocker = publishBlocker,
            status = status,
            current = current?.toDomain(),
            versions = versions.map { LoyaltyVersionRow(it.version, it.acceptedAt?.let(::parseTimestamp)) },
            closingUntil = closingUntil?.let(::parseTimestamp),
            closingReason = closingReason,
            suspendedUntil = suspendedUntil?.let(::parseTimestamp),
            activeCards = activeCards,
            rewardsAvailable = rewardsAvailable,
            reports = reports?.let { LoyaltyReports(it.count, it.warn, it.suspend, it.windowDays) },
            limits = limits.toDomain(),
        )
    }
}

@Serializable
internal data class LoyaltyMemberDto(
    val code: String? = null,
    val outcome: String? = null,
    @SerialName("stamps_added") val stampsAdded: Int = 0,
    @SerialName("double_day") val doubleDay: Boolean = false,
    val stamps: Int? = null,
    val required: Int? = null,
    @SerialName("reward_unlocked") val rewardUnlocked: Boolean = false,
    val carry: Int = 0,
    val condition: LoyaltyConditionDto? = null,
) {
    fun toDomain() = StampMember(
        code = code,
        outcome = enumOr(outcome, StampOutcome.UNKNOWN),
        stampsAdded = stampsAdded,
        doubleDay = doubleDay,
        stamps = stamps,
        required = required,
        rewardUnlocked = rewardUnlocked,
        carry = carry,
        condition = condition?.toDomain(),
    )
}

@Serializable
internal data class LoyaltyStampRewardDto(
    @SerialName("reward_id") val rewardId: String,
    val code: String? = null,
    val kind: String = "GIFT",
    val gift: String? = null,
    val percent: Int? = null,
    @SerialName("cap_cents") val capCents: Int? = null,
    @SerialName("amount_cents") val amountCents: Int? = null,
    @SerialName("min_spend_cents") val minSpendCents: Int? = null,
    val weekdays: List<Int>? = null,
    @SerialName("max_per_table") val maxPerTable: Int? = null,
    val cumulable: Boolean = false,
    @SerialName("unlocked_at") val unlockedAt: String? = null,
    @SerialName("usable_from") val usableFrom: String? = null,
    @SerialName("expires_at") val expiresAt: String? = null,
    @SerialName("usable_now") val usableNow: Boolean = false,
) {
    fun toDomain(): LoyaltyReward {
        val usable = usableFrom?.let(::parseTimestamp)
        val unlocked = unlockedAt?.let(::parseTimestamp)
        return LoyaltyReward(
            rewardId = rewardId,
            code = code,
            rules = RewardRules(
                kind = enumOr(kind, RewardKind.GIFT),
                gift = gift,
                percent = percent,
                capCents = capCents,
                amountCents = amountCents,
                minSpendCents = minSpendCents,
                // Il server non ripete «da quando»: si capisce dal momento in cui si può usare.
                from = if (usable != null && unlocked != null && usable.isAfter(unlocked)) RewardFrom.NEXT_VISIT else RewardFrom.SAME_VISIT,
                weekdays = weekdays,
                maxPerTable = maxPerTable,
                cumulable = cumulable,
            ),
            unlockedAt = unlocked,
            usableFrom = usable,
            expiresAt = expiresAt?.let(::parseTimestamp),
            usableNow = usableNow,
        )
    }
}

@Serializable
internal data class LoyaltyStampResultDto(
    val ok: Boolean = false,
    val error: String? = null,
    @SerialName("attempts_left") val attemptsLeft: Int? = null,
    @SerialName("locked_until") val lockedUntil: String? = null,
    @SerialName("scan_id") val scanId: String? = null,
    val kind: String? = null,
    val people: Int = 0,
    val stamped: Int = 0,
    val stamps: Int = 0,
    @SerialName("undo_until") val undoUntil: String? = null,
    val members: List<LoyaltyMemberDto> = emptyList(),
    val rewards: List<LoyaltyStampRewardDto> = emptyList(),
) {
    fun toDomain() = StampResult(
        ok = ok,
        error = error,
        attemptsLeft = attemptsLeft,
        lockedUntil = lockedUntil?.let(::parseTimestamp),
        scanId = scanId,
        isGroup = kind == "GROUP",
        people = people,
        stamped = stamped,
        stamps = stamps,
        undoUntil = undoUntil?.let(::parseTimestamp),
        members = members.map { it.toDomain() },
        rewards = rewards.map { it.toDomain() },
    )
}

@Serializable
internal data class LoyaltyHourDto(val weekday: Int = 0, val hour: Int = 0, val scans: Int = 0)

@Serializable
internal data class LoyaltyNearDto(val one: Int = 0, val two: Int = 0)

@Serializable
internal data class LoyaltyStatsDto(
    val days: Int = 30,
    val scans: Int = 0,
    @SerialName("group_scans") val groupScans: Int = 0,
    val people: Int = 0,
    val stamps: Int = 0,
    @SerialName("double_stamps") val doubleStamps: Int = 0,
    @SerialName("new_customers") val newCustomers: Int = 0,
    @SerialName("returning_people") val returningPeople: Int = 0,
    @SerialName("cards_started") val cardsStarted: Int = 0,
    @SerialName("rewards_unlocked") val rewardsUnlocked: Int = 0,
    @SerialName("rewards_used") val rewardsUsed: Int = 0,
    @SerialName("rewards_expired") val rewardsExpired: Int = 0,
    @SerialName("discount_cents") val discountCents: Int = 0,
    @SerialName("active_cards") val activeCards: Int = 0,
    @SerialName("near_reward") val nearReward: LoyaltyNearDto = LoyaltyNearDto(),
    @SerialName("by_hour") val byHour: List<LoyaltyHourDto> = emptyList(),
) {
    fun toDomain() = LoyaltyStats(
        days = days, scans = scans, groupScans = groupScans, people = people, stamps = stamps,
        doubleStamps = doubleStamps, newCustomers = newCustomers, returningPeople = returningPeople,
        cardsStarted = cardsStarted, rewardsUnlocked = rewardsUnlocked, rewardsUsed = rewardsUsed,
        rewardsExpired = rewardsExpired, discountCents = discountCents, activeCards = activeCards,
        nearRewardOne = nearReward.one, nearRewardTwo = nearReward.two,
        byHour = byHour.map { HourCount(it.weekday, it.hour, it.scans) },
    )
}

@Serializable
internal data class LoyaltyCardDto(
    val code: String = "",
    val stamps: Int = 0,
    val required: Int = 0,
    val version: Int = 0,
    @SerialName("started_at") val startedAt: String? = null,
    @SerialName("last_stamp_at") val lastStampAt: String? = null,
    @SerialName("rewards_available") val rewardsAvailable: Int = 0,
) {
    fun toDomain() = LoyaltyCardRow(
        code, stamps, required, version, startedAt?.let(::parseTimestamp), lastStampAt?.let(::parseTimestamp), rewardsAvailable,
    )
}
