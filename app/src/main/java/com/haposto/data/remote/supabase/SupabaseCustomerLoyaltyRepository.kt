package com.haposto.data.remote.supabase

import com.haposto.data.Outcome
import com.haposto.data.loyalty.CustomerLoyaltyRepository
import com.haposto.data.loyalty.GroupResult
import com.haposto.data.loyalty.GroupState
import com.haposto.data.loyalty.GroupStatus
import com.haposto.data.loyalty.JoinedGroup
import com.haposto.data.loyalty.LoyaltyAccess
import com.haposto.data.loyalty.LoyaltyGroup
import com.haposto.data.loyalty.LoyaltyLevel
import com.haposto.data.loyalty.LoyaltyReportKind
import com.haposto.data.loyalty.MyCard
import com.haposto.data.loyalty.MyLoyaltyCard
import com.haposto.data.loyalty.RestaurantLoyaltyBox
import com.haposto.data.loyalty.StampOutcome
import com.haposto.data.loyalty.TokenState
import com.haposto.data.loyalty.TokenStatus
import com.haposto.data.loyalty.VisitToken
import com.haposto.data.outcomeOf
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.postgrest.postgrest
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

class SupabaseCustomerLoyaltyRepository(private val client: SupabaseClient) : CustomerLoyaltyRepository {

    private suspend fun rpc(name: String, params: JsonObject = JsonObject(emptyMap())): String =
        client.postgrest.rpc(name, params).data

    /** Chiamata senza risultato da leggere. */
    private suspend fun call(name: String, params: JsonObject) {
        client.postgrest.rpc(name, params)
    }

    override suspend fun access(): Outcome<LoyaltyAccess> = outcomeOf { decodeLoyaltyAccess(rpc("loyalty_access")) }

    override suspend fun restaurantBox(restaurantId: String): Outcome<RestaurantLoyaltyBox> = outcomeOf {
        decodeRestaurantLoyaltyBox(rpc("loyalty_restaurant_card", buildJsonObject { put("p_restaurant_id", restaurantId) }))
    }

    override suspend fun createToken(restaurantId: String): Outcome<VisitToken> = outcomeOf {
        decodeVisitToken(rpc("create_visit_token", buildJsonObject { put("p_restaurant_id", restaurantId) }))
    }

    override suspend fun tokenStatus(token: String): Outcome<TokenStatus> = outcomeOf {
        decodeTokenStatus(rpc("visit_token_status", buildJsonObject { put("p_token", token) }))
    }

    override suspend fun createGroup(restaurantId: String): Outcome<LoyaltyGroup> = outcomeOf {
        decodeLoyaltyGroup(rpc("create_loyalty_group", buildJsonObject { put("p_restaurant_id", restaurantId) }))
    }

    override suspend fun groupToken(groupId: String): Outcome<LoyaltyGroup> = outcomeOf {
        decodeLoyaltyGroup(rpc("loyalty_group_token", buildJsonObject { put("p_group_id", groupId) }))
    }

    override suspend fun joinGroup(token: String): Outcome<JoinedGroup> = outcomeOf {
        decodeJoinedGroup(rpc("join_loyalty_group", buildJsonObject { put("p_token", token) }))
    }

    override suspend fun leaveGroup(groupId: String): Outcome<Unit> = outcomeOf {
        call("leave_loyalty_group", buildJsonObject { put("p_group_id", groupId) })
    }

    override suspend fun groupStatus(groupId: String): Outcome<GroupStatus> = outcomeOf {
        decodeGroupStatus(rpc("loyalty_group_status", buildJsonObject { put("p_group_id", groupId) }))
    }

    override suspend fun myCards(): Outcome<List<MyLoyaltyCard>> = outcomeOf { decodeMyLoyaltyCards(rpc("my_loyalty_cards")) }

    override suspend fun leaveCard(restaurantId: String): Outcome<Unit> = outcomeOf {
        call("leave_loyalty_card", buildJsonObject { put("p_restaurant_id", restaurantId) })
    }

    override suspend fun report(restaurantId: String, kind: LoyaltyReportKind): Outcome<Unit> = outcomeOf {
        call("report_loyalty_problem", buildJsonObject {
            put("p_restaurant_id", restaurantId)
            put("p_kind", kind.name)
        })
    }
}

/** Le funzioni internal servono ai test (JSON vero della migration 0018). */
internal fun decodeLoyaltyAccess(text: String): LoyaltyAccess =
    loyaltyJson.decodeFromString<CustomerAccessDto>(text).let {
        LoyaltyAccess(enumOr(it.level, LoyaltyLevel.NONE), it.hasCards, it.visible)
    }

internal fun decodeRestaurantLoyaltyBox(text: String): RestaurantLoyaltyBox =
    loyaltyJson.decodeFromString<CustomerBoxDto>(text).toDomain()

internal fun decodeVisitToken(text: String): VisitToken = loyaltyJson.decodeFromString<CustomerTokenDto>(text).toDomain()

internal fun decodeTokenStatus(text: String): TokenStatus =
    loyaltyJson.decodeFromString<CustomerTokenStatusDto>(text).let {
        TokenStatus(enumOr(it.status, TokenState.EXPIRED), it.result?.toDomain())
    }

internal fun decodeLoyaltyGroup(text: String): LoyaltyGroup =
    loyaltyJson.decodeFromString<CustomerGroupDto>(text).let {
        LoyaltyGroup(
            groupId = it.groupId,
            token = VisitToken(it.token, it.code, it.expiresAt?.let(::parseTimestamp), it.seconds),
            joinUntil = it.joinUntil?.let(::parseTimestamp),
            expiresAt = it.groupExpiresAt?.let(::parseTimestamp),
            members = it.members,
        )
    }

internal fun decodeJoinedGroup(text: String): JoinedGroup =
    loyaltyJson.decodeFromString<CustomerJoinedDto>(text).let {
        JoinedGroup(it.groupId, it.restaurantId, it.restaurantName.orEmpty(), it.members)
    }

internal fun decodeGroupStatus(text: String): GroupStatus =
    loyaltyJson.decodeFromString<CustomerGroupStatusDto>(text).let {
        GroupStatus(
            groupId = it.groupId,
            restaurantId = it.restaurantId,
            leader = it.leader,
            members = it.members,
            joinUntil = it.joinUntil?.let(::parseTimestamp),
            expiresAt = it.expiresAt?.let(::parseTimestamp),
            state = enumOr(it.status, GroupState.CLOSED),
            result = it.result?.let { result ->
                GroupResult(
                    outcome = enumOr(result.outcome, StampOutcome.UNKNOWN),
                    stampsAdded = result.stampsAdded,
                    doubleDay = result.doubleDay,
                    undone = result.undone,
                    rewardUnlocked = result.rewardUnlocked,
                )
            },
        )
    }

internal fun decodeMyLoyaltyCards(text: String): List<MyLoyaltyCard> =
    loyaltyJson.decodeFromString<List<CustomerCardEntryDto>>(text).map { it.toDomain() }

@Serializable
internal data class CustomerAccessDto(
    val level: String? = null,
    @SerialName("has_cards") val hasCards: Boolean = false,
    val visible: Boolean = false,
)

@Serializable
internal data class CustomerMyCardDto(
    val stamps: Int = 0,
    @SerialName("started_at") val startedAt: String? = null,
    @SerialName("last_stamp_at") val lastStampAt: String? = null,
    @SerialName("reset_at") val resetAt: String? = null,
    val rules: LoyaltyRulesDto? = null,
) {
    fun toDomain() = MyCard(
        stamps = stamps,
        startedAt = startedAt?.let(::parseTimestamp),
        lastStampAt = lastStampAt?.let(::parseTimestamp),
        resetAt = resetAt?.let(::parseTimestamp),
        rules = rules?.toDomain(),
    )
}

@Serializable
internal data class CustomerBoxDto(
    val available: Boolean = false,
    @SerialName("can_start") val canStart: Boolean = false,
    val status: String? = null,
    @SerialName("closing_until") val closingUntil: String? = null,
    val rules: LoyaltyRulesDto? = null,
    val code: String? = null,
    val card: CustomerMyCardDto? = null,
    val rewards: List<LoyaltyStampRewardDto> = emptyList(),
) {
    fun toDomain() = if (!available) {
        RestaurantLoyaltyBox.HIDDEN
    } else {
        RestaurantLoyaltyBox(
            available = true,
            canStart = canStart,
            status = status,
            closingUntil = closingUntil?.let(::parseTimestamp),
            rules = rules?.toDomain(),
            code = code,
            card = card?.toDomain(),
            rewards = rewards.map { it.toDomain() },
        )
    }
}

@Serializable
internal data class CustomerTokenDto(
    val token: String,
    val code: String = "",
    @SerialName("expires_at") val expiresAt: String? = null,
    val seconds: Int = 60,
) {
    fun toDomain() = VisitToken(token, code, expiresAt?.let(::parseTimestamp), seconds)
}

@Serializable
internal data class CustomerTokenStatusDto(
    val status: String? = null,
    @SerialName("expires_at") val expiresAt: String? = null,
    val result: LoyaltyMemberDto? = null,
)

@Serializable
internal data class CustomerGroupDto(
    @SerialName("group_id") val groupId: String,
    val token: String,
    val code: String = "",
    val seconds: Int = 60,
    @SerialName("expires_at") val expiresAt: String? = null,
    @SerialName("join_until") val joinUntil: String? = null,
    @SerialName("group_expires_at") val groupExpiresAt: String? = null,
    val members: Int = 1,
)

@Serializable
internal data class CustomerJoinedDto(
    @SerialName("group_id") val groupId: String,
    @SerialName("restaurant_id") val restaurantId: String,
    @SerialName("restaurant_name") val restaurantName: String? = null,
    val members: Int = 1,
)

@Serializable
internal data class CustomerGroupResultDto(
    val outcome: String? = null,
    @SerialName("stamps_added") val stampsAdded: Int = 0,
    @SerialName("double_day") val doubleDay: Boolean = false,
    val undone: Boolean = false,
    @SerialName("reward_unlocked") val rewardUnlocked: Boolean = false,
)

@Serializable
internal data class CustomerGroupStatusDto(
    @SerialName("group_id") val groupId: String,
    @SerialName("restaurant_id") val restaurantId: String,
    val leader: Boolean = false,
    val members: Int = 0,
    @SerialName("join_until") val joinUntil: String? = null,
    @SerialName("expires_at") val expiresAt: String? = null,
    val status: String? = null,
    val result: CustomerGroupResultDto? = null,
)

@Serializable
internal data class CustomerCardEntryDto(
    @SerialName("restaurant_id") val restaurantId: String,
    @SerialName("restaurant_name") val restaurantName: String = "",
    val city: String = "",
    val code: String? = null,
    @SerialName("program_status") val programStatus: String? = null,
    @SerialName("closing_until") val closingUntil: String? = null,
    val card: CustomerMyCardDto? = null,
    val rewards: List<LoyaltyStampRewardDto> = emptyList(),
) {
    fun toDomain() = MyLoyaltyCard(
        restaurantId = restaurantId,
        restaurantName = restaurantName,
        city = city,
        code = code,
        programStatus = programStatus,
        closingUntil = closingUntil?.let(::parseTimestamp),
        card = card?.toDomain(),
        rewards = rewards.map { it.toDomain() },
    )
}
