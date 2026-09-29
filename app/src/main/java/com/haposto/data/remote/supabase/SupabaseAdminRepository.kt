package com.haposto.data.remote.supabase

import com.haposto.data.ErrorMessages
import com.haposto.data.Outcome
import com.haposto.data.admin.AdminActivity
import com.haposto.data.admin.AdminClaim
import com.haposto.data.admin.AdminClaimSummary
import com.haposto.data.admin.AdminMember
import com.haposto.data.admin.AdminOverview
import com.haposto.data.admin.AdminPaymentRow
import com.haposto.data.admin.AdminPublish
import com.haposto.data.admin.AdminRepository
import com.haposto.data.admin.AdminRestaurantDetail
import com.haposto.data.admin.AdminRestaurantRow
import com.haposto.data.admin.AdminStatus
import com.haposto.data.admin.AdminSubscriptionRow
import com.haposto.data.admin.AdminSubscriptionSummary
import com.haposto.data.admin.AdminUserDetail
import com.haposto.data.admin.AdminUserRestaurant
import com.haposto.data.admin.AdminUserRow
import com.haposto.data.admin.AuditRow
import com.haposto.data.admin.ConfigEntry
import com.haposto.data.admin.RestaurantEdit
import com.haposto.data.admin.UnlockResult
import com.haposto.data.outcomeOf
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.postgrest.postgrest
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.intOrNull
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.put

class SupabaseAdminRepository(private val client: SupabaseClient) : AdminRepository {

    private val json = Json { ignoreUnknownKeys = true }

    private suspend fun rpc(name: String, params: JsonObject = JsonObject(emptyMap())): String =
        client.postgrest.rpc(name, params).data

    override suspend fun status(): Outcome<AdminStatus> = outcomeOf {
        json.decodeFromString<List<AdminStatusDto>>(rpc("my_admin_status")).first().let {
            AdminStatus(
                isAdminAccount = it.isAdminAccount,
                hasCredentials = it.hasCredentials,
                mfaOk = it.mfaOk,
                unlockedUntil = it.unlockedUntil?.let(::parseTimestamp),
                lockedUntil = it.lockedUntil?.let(::parseTimestamp),
            )
        }
    }

    override suspend fun unlock(username: String, password: String): Outcome<UnlockResult> {
        val result = outcomeOf {
            json.decodeFromString<List<UnlockDto>>(
                rpc("admin_unlock", buildJsonObject {
                    put("p_username", username)
                    put("p_password", password)
                }),
            ).first()
        }
        return when (result) {
            is Outcome.Failure -> result
            is Outcome.Success -> {
                val dto = result.value
                if (dto.ok) {
                    Outcome.Success(UnlockResult(true, null, dto.validUntil?.let(::parseTimestamp)))
                } else {
                    ErrorMessages.failure(dto.errorCode ?: "INVALID_CREDENTIALS")
                }
            }
        }
    }

    override suspend fun lock(): Outcome<Unit> = outcomeOf { rpc("admin_lock"); Unit }

    override suspend fun overview(): Outcome<AdminOverview> = outcomeOf {
        val obj = json.decodeFromString<JsonObject>(rpc("admin_overview"))
        AdminOverview(
            OVERVIEW_LABELS.mapNotNull { (key, label) ->
                val raw = (obj[key] as? JsonPrimitive)?.contentOrNull ?: return@mapNotNull null
                val value = if (key.endsWith("_cents")) euro(raw.toIntOrNull() ?: 0) else raw
                label to value
            },
        )
    }

    override suspend fun pendingClaims(): Outcome<List<AdminClaim>> = outcomeOf {
        json.decodeFromString<List<AdminClaimDto>>(rpc("admin_pending_claims")).map { it.toDomain() }
    }

    override suspend fun issueClaimCode(claimId: String): Outcome<String> = outcomeOf {
        json.decodeFromString<String>(rpc("admin_issue_claim_code", buildJsonObject { put("p_claim_id", claimId) }))
    }

    override suspend fun reviewClaim(claimId: String, approve: Boolean, note: String?, skipPhoneCheck: Boolean): Outcome<Unit> =
        outcomeOf {
            rpc("admin_review_claim", buildJsonObject {
                put("p_claim_id", claimId)
                put("p_approve", approve)
                put("p_note", note?.trim()?.takeIf(String::isNotEmpty))
                put("p_skip_phone_check", skipPhoneCheck)
            })
            Unit
        }

    override suspend fun restaurants(query: String?, status: String?, offset: Int): Outcome<List<AdminRestaurantRow>> = outcomeOf {
        json.decodeFromString<List<AdminRestaurantRowDto>>(
            rpc("admin_list_restaurants", buildJsonObject {
                put("p_query", query?.trim()?.takeIf(String::isNotEmpty))
                put("p_status", status)
                put("p_limit", PAGE)
                put("p_offset", offset)
            }),
        ).map { it.toDomain() }
    }

    override suspend fun restaurantDetail(restaurantId: String): Outcome<AdminRestaurantDetail> = outcomeOf {
        json.decodeFromString<AdminRestaurantDetailDto>(
            rpc("admin_restaurant_detail", buildJsonObject { put("p_restaurant_id", restaurantId) }),
        ).toDomain()
    }

    override suspend fun setRestaurantStatus(restaurantId: String, status: String, note: String?): Outcome<Unit> = outcomeOf {
        rpc("admin_set_restaurant_status", buildJsonObject {
            put("p_restaurant_id", restaurantId)
            put("p_status", status)
            put("p_note", note?.trim()?.takeIf(String::isNotEmpty))
        })
        Unit
    }

    override suspend fun updateRestaurant(restaurantId: String, edit: RestaurantEdit): Outcome<Unit> = outcomeOf {
        rpc("admin_update_restaurant", buildJsonObject {
            put("p_restaurant_id", restaurantId)
            put("p_name", edit.name)
            put("p_category", edit.category)
            put("p_address", edit.address)
            put("p_city", edit.city)
            put("p_province", edit.province)
            put("p_latitude", edit.latitude)
            put("p_longitude", edit.longitude)
            put("p_phone_number", edit.phoneNumber)
            put("p_phone_public", edit.phonePublic)
        })
        Unit
    }

    override suspend fun addMember(restaurantId: String, email: String, role: String, note: String?): Outcome<Unit> = outcomeOf {
        rpc("admin_add_member", buildJsonObject {
            put("p_restaurant_id", restaurantId)
            put("p_email", email.trim())
            put("p_role", role)
            put("p_note", note)
        })
        Unit
    }

    override suspend fun removeMember(restaurantId: String, userId: String, note: String?): Outcome<Unit> = outcomeOf {
        rpc("admin_remove_member", buildJsonObject {
            put("p_restaurant_id", restaurantId)
            put("p_user_id", userId)
            put("p_note", note)
        })
        Unit
    }

    override suspend fun grantRestaurantPlan(restaurantId: String, planCode: String, months: Int, note: String?): Outcome<Unit> =
        outcomeOf {
            rpc("admin_grant_restaurant_plan", buildJsonObject {
                put("p_restaurant_id", restaurantId)
                put("p_plan_code", planCode)
                put("p_months", months)
                put("p_note", note)
            })
            Unit
        }

    override suspend fun users(query: String?, filter: String, offset: Int): Outcome<List<AdminUserRow>> = outcomeOf {
        json.decodeFromString<List<AdminUserRowDto>>(
            rpc("admin_list_users", buildJsonObject {
                put("p_query", query?.trim()?.takeIf(String::isNotEmpty))
                put("p_filter", filter)
                put("p_limit", PAGE)
                put("p_offset", offset)
            }),
        ).map { it.toDomain() }
    }

    override suspend fun userDetail(userId: String): Outcome<AdminUserDetail> = outcomeOf {
        json.decodeFromString<AdminUserDetailDto>(
            rpc("admin_user_detail", buildJsonObject { put("p_user_id", userId) }),
        ).toDomain()
    }

    override suspend fun setUserBlocked(userId: String, blocked: Boolean, reason: String?): Outcome<Unit> = outcomeOf {
        rpc("admin_set_user_blocked", buildJsonObject {
            put("p_user_id", userId)
            put("p_blocked", blocked)
            put("p_reason", reason)
        })
        Unit
    }

    override suspend fun grantPlus(userId: String, months: Int, note: String?): Outcome<Unit> = outcomeOf {
        rpc("admin_grant_consumer_plan", buildJsonObject {
            put("p_user_id", userId)
            put("p_months", months)
            put("p_note", note)
        })
        Unit
    }

    override suspend fun subscriptions(kind: String): Outcome<List<AdminSubscriptionRow>> = outcomeOf {
        json.decodeFromString<List<AdminSubscriptionRowDto>>(
            rpc("admin_list_subscriptions", buildJsonObject {
                put("p_kind", kind)
                put("p_limit", 200)
            }),
        ).map { it.toDomain() }
    }

    override suspend fun cancelSubscription(kind: String, subscriptionId: String, note: String?): Outcome<Unit> = outcomeOf {
        rpc("admin_cancel_subscription", buildJsonObject {
            put("p_kind", kind)
            put("p_subscription_id", subscriptionId)
            put("p_note", note)
        })
        Unit
    }

    override suspend fun payments(offset: Int): Outcome<List<AdminPaymentRow>> = outcomeOf {
        json.decodeFromString<List<AdminPaymentDto>>(
            rpc("admin_list_payments", buildJsonObject {
                put("p_limit", PAGE)
                put("p_offset", offset)
            }),
        ).map { it.toDomain() }
    }

    override suspend fun auditLog(beforeId: Long?, action: String?): Outcome<List<AuditRow>> = outcomeOf {
        json.decodeFromString<List<AuditDto>>(
            rpc("admin_audit_log", buildJsonObject {
                put("p_limit", PAGE)
                put("p_before_id", beforeId)
                put("p_action", action?.trim()?.uppercase()?.takeIf(String::isNotEmpty))
            }),
        ).map { it.toDomain() }
    }

    override suspend fun config(): Outcome<List<ConfigEntry>> = outcomeOf {
        client.postgrest.from("app_config").select().decodeList<ConfigDto>()
            .sortedBy { it.key }
            .map { ConfigEntry(it.key, it.value.toString(), it.description) }
    }

    override suspend fun setConfig(key: String, valueJson: String): Outcome<Unit> {
        val value = runCatching { json.parseToJsonElement(valueJson) }.getOrNull()
            ?: return ErrorMessages.failure("INVALID_CONFIG_VALUE")
        return outcomeOf {
            rpc("admin_set_config", buildJsonObject {
                put("p_key", key)
                put("p_value", value)
            })
            Unit
        }
    }

    private companion object {
        const val PAGE = 50

        val OVERVIEW_LABELS = listOf(
            "claims_pending" to "Richieste da verificare",
            "partners" to "Locali partner",
            "partners_live_now" to "Partner con stato valido adesso",
            "publishes_last_24h" to "Pubblicazioni ultime 24 ore",
            "restaurants_total" to "Locali in directory",
            "restaurants_suspended" to "Locali sospesi",
            "users_total" to "Utenti registrati",
            "users_last_7_days" to "Nuovi utenti (7 giorni)",
            "users_blocked" to "Account sospesi",
            "restaurant_subscriptions_paid" to "Abbonamenti Pro pagati",
            "restaurant_subscriptions_manual" to "Pro regalati / manuali",
            "consumer_plus_active" to "Utenti Plus",
            "revenue_last_30_days_cents" to "Incassi ultimi 30 giorni",
            "beta_until" to "Fine beta",
        )

        fun euro(cents: Int): String = "€ %d,%02d".format(cents / 100, cents % 100)
    }
}

@Serializable
private data class AdminStatusDto(
    @SerialName("is_admin_account") val isAdminAccount: Boolean = false,
    @SerialName("has_credentials") val hasCredentials: Boolean = false,
    @SerialName("mfa_ok") val mfaOk: Boolean = false,
    @SerialName("unlocked_until") val unlockedUntil: String? = null,
    @SerialName("locked_until") val lockedUntil: String? = null,
)

@Serializable
private data class UnlockDto(
    val ok: Boolean,
    @SerialName("error_code") val errorCode: String? = null,
    @SerialName("valid_until") val validUntil: String? = null,
)

@Serializable
private data class AdminClaimDto(
    @SerialName("claim_id") val claimId: String,
    @SerialName("created_at") val createdAt: String? = null,
    @SerialName("restaurant_id") val restaurantId: String,
    @SerialName("restaurant_name") val restaurantName: String,
    @SerialName("restaurant_city") val restaurantCity: String = "",
    @SerialName("restaurant_address") val restaurantAddress: String = "",
    @SerialName("restaurant_phone") val restaurantPhone: String? = null,
    @SerialName("partnership_status") val partnershipStatus: String = "",
    @SerialName("current_owners") val currentOwners: Int = 0,
    @SerialName("requester_id") val requesterId: String,
    @SerialName("requester_email") val requesterEmail: String? = null,
    @SerialName("requester_name") val requesterName: String? = null,
    @SerialName("contact_info") val contactInfo: String = "",
    @SerialName("phone_code_active") val phoneCodeActive: Boolean = false,
    @SerialName("phone_verified_at") val phoneVerifiedAt: String? = null,
) {
    fun toDomain() = AdminClaim(
        claimId, createdAt?.let(::parseTimestamp), restaurantId, restaurantName, restaurantCity, restaurantAddress,
        restaurantPhone, partnershipStatus, currentOwners, requesterId, requesterEmail.orEmpty(), requesterName,
        contactInfo, phoneCodeActive, phoneVerifiedAt != null,
    )
}

@Serializable
private data class AdminRestaurantRowDto(
    @SerialName("restaurant_id") val restaurantId: String,
    val name: String,
    val city: String = "",
    @SerialName("partnership_status") val partnershipStatus: String,
    @SerialName("data_source") val dataSource: String = "",
    @SerialName("plan_code") val planCode: String = "",
    val members: Int = 0,
    @SerialName("last_publish_at") val lastPublishAt: String? = null,
    @SerialName("phone_number") val phoneNumber: String? = null,
    val slug: String? = null,
) {
    fun toDomain() = AdminRestaurantRow(
        restaurantId, name, city, partnershipStatus, dataSource, planCode, members,
        lastPublishAt?.let(::parseTimestamp), phoneNumber, slug,
    )
}

@Serializable
private data class DetailRestaurantDto(
    val id: String,
    val name: String,
    val category: String = "",
    val address: String = "",
    val city: String = "",
    val province: String = "",
    @SerialName("phone_number") val phoneNumber: String? = null,
    @SerialName("phone_public") val phonePublic: Boolean = false,
    @SerialName("partnership_status") val partnershipStatus: String = "",
    @SerialName("data_source") val dataSource: String = "",
    val slug: String? = null,
    val latitude: Double? = null,
    val longitude: Double? = null,
)

@Serializable
private data class DetailMemberDto(
    @SerialName("user_id") val userId: String,
    val email: String? = null,
    val role: String = "",
    val since: String? = null,
)

@Serializable
private data class DetailClaimDto(
    @SerialName("claim_id") val claimId: String,
    val status: String = "",
    val email: String? = null,
    @SerialName("created_at") val createdAt: String? = null,
    @SerialName("phone_verified_at") val phoneVerifiedAt: String? = null,
    @SerialName("review_note") val reviewNote: String? = null,
)

@Serializable
private data class DetailSubscriptionDto(
    val id: String,
    @SerialName("plan_code") val planCode: String = "",
    val status: String = "",
    val provider: String = "",
    @SerialName("period_end") val periodEnd: String? = null,
    val note: String? = null,
) {
    fun toDomain() = AdminSubscriptionSummary(id, planCode, status, provider, periodEnd?.let(::parseTimestamp), note)
}

@Serializable
private data class DetailPublishDto(
    val status: String = "",
    @SerialName("updated_at") val updatedAt: String? = null,
    @SerialName("updated_via") val updatedVia: String = "",
    @SerialName("by_email") val byEmail: String? = null,
)

@Serializable
private data class AdminRestaurantDetailDto(
    val restaurant: DetailRestaurantDto,
    @SerialName("plan_code") val planCode: String = "",
    val members: List<DetailMemberDto> = emptyList(),
    val claims: List<DetailClaimDto> = emptyList(),
    val subscriptions: List<DetailSubscriptionDto> = emptyList(),
    @SerialName("recent_publishes") val recentPublishes: List<DetailPublishDto> = emptyList(),
    @SerialName("stats_30_days") val stats: JsonObject? = null,
) {
    fun toDomain() = AdminRestaurantDetail(
        restaurantId = restaurant.id,
        name = restaurant.name,
        category = restaurant.category,
        address = restaurant.address,
        city = restaurant.city,
        province = restaurant.province,
        phoneNumber = restaurant.phoneNumber,
        phonePublic = restaurant.phonePublic,
        partnershipStatus = restaurant.partnershipStatus,
        dataSource = restaurant.dataSource,
        slug = restaurant.slug,
        latitude = restaurant.latitude,
        longitude = restaurant.longitude,
        planCode = planCode,
        members = members.map { AdminMember(it.userId, it.email.orEmpty(), it.role, it.since?.let(::parseTimestamp)) },
        claims = claims.map {
            AdminClaimSummary(it.claimId, it.status, it.email, it.createdAt?.let(::parseTimestamp), it.phoneVerifiedAt != null, it.reviewNote)
        },
        subscriptions = subscriptions.map { it.toDomain() },
        recentPublishes = recentPublishes.map { AdminPublish(it.status, it.updatedAt?.let(::parseTimestamp), it.updatedVia, it.byEmail) },
        stats30Days = stats.orEmpty().mapValues { (_, v) -> v.jsonPrimitive.intOrNull ?: 0 },
    )
}

@Serializable
private data class AdminUserRowDto(
    @SerialName("user_id") val userId: String,
    val email: String? = null,
    @SerialName("display_name") val displayName: String? = null,
    @SerialName("created_at") val createdAt: String? = null,
    @SerialName("last_sign_in_at") val lastSignInAt: String? = null,
    @SerialName("is_admin") val isAdmin: Boolean = false,
    @SerialName("blocked_at") val blockedAt: String? = null,
    @SerialName("consumer_plan") val consumerPlan: String = "CONSUMER_FREE",
    val restaurants: Int = 0,
) {
    fun toDomain() = AdminUserRow(
        userId, email.orEmpty(), displayName, createdAt?.let(::parseTimestamp), lastSignInAt?.let(::parseTimestamp),
        isAdmin, blockedAt?.let(::parseTimestamp), consumerPlan, restaurants,
    )
}

@Serializable
private data class DetailUserDto(
    val id: String,
    val email: String? = null,
    @SerialName("created_at") val createdAt: String? = null,
    @SerialName("last_sign_in_at") val lastSignInAt: String? = null,
)

@Serializable
private data class DetailProfileDto(
    @SerialName("display_name") val displayName: String? = null,
    @SerialName("is_platform_admin") val isPlatformAdmin: Boolean = false,
    @SerialName("blocked_at") val blockedAt: String? = null,
    @SerialName("blocked_reason") val blockedReason: String? = null,
    @SerialName("marketing_opt_in") val marketingOptIn: Boolean = false,
    @SerialName("accepted_terms_version") val acceptedTermsVersion: String? = null,
)

@Serializable
private data class DetailUserRestaurantDto(
    @SerialName("restaurant_id") val restaurantId: String,
    val name: String = "",
    val city: String = "",
    val role: String = "",
)

@Serializable
private data class DetailActivityDto(
    @SerialName("created_at") val createdAt: String? = null,
    val action: String = "",
    @SerialName("actor_kind") val actorKind: String = "",
    val details: JsonElement? = null,
)

@Serializable
private data class AdminUserDetailDto(
    val user: DetailUserDto,
    val profile: DetailProfileDto? = null,
    @SerialName("consumer_plan") val consumerPlan: String = "CONSUMER_FREE",
    val restaurants: List<DetailUserRestaurantDto> = emptyList(),
    val subscriptions: List<DetailSubscriptionDto> = emptyList(),
    val favorites: Int = 0,
    @SerialName("active_alerts") val activeAlerts: Int = 0,
    @SerialName("recent_activity") val recentActivity: List<DetailActivityDto> = emptyList(),
) {
    fun toDomain() = AdminUserDetail(
        userId = user.id,
        email = user.email.orEmpty(),
        createdAt = user.createdAt?.let(::parseTimestamp),
        lastSignInAt = user.lastSignInAt?.let(::parseTimestamp),
        displayName = profile?.displayName,
        isAdmin = profile?.isPlatformAdmin == true,
        blockedAt = profile?.blockedAt?.let(::parseTimestamp),
        blockedReason = profile?.blockedReason,
        marketingOptIn = profile?.marketingOptIn == true,
        acceptedTermsVersion = profile?.acceptedTermsVersion,
        consumerPlan = consumerPlan,
        restaurants = restaurants.map { AdminUserRestaurant(it.restaurantId, it.name, it.city, it.role) },
        subscriptions = subscriptions.map { it.toDomain() },
        favorites = favorites,
        activeAlerts = activeAlerts,
        recentActivity = recentActivity.map {
            AdminActivity(it.createdAt?.let(::parseTimestamp), it.action, it.actorKind, it.details?.toString().orEmpty())
        },
    )
}

@Serializable
private data class AdminSubscriptionRowDto(
    val kind: String,
    @SerialName("subscription_id") val subscriptionId: String,
    @SerialName("subject_id") val subjectId: String,
    @SerialName("subject_name") val subjectName: String? = null,
    @SerialName("plan_code") val planCode: String = "",
    val status: String = "",
    val provider: String = "",
    @SerialName("current_period_end") val currentPeriodEnd: String? = null,
    @SerialName("created_at") val createdAt: String? = null,
) {
    fun toDomain() = AdminSubscriptionRow(
        kind, subscriptionId, subjectId, subjectName.orEmpty(), planCode, status, provider,
        currentPeriodEnd?.let(::parseTimestamp), createdAt?.let(::parseTimestamp),
    )
}

@Serializable
private data class AdminPaymentDto(
    @SerialName("payment_id") val paymentId: String,
    @SerialName("paid_at") val paidAt: String? = null,
    @SerialName("payer_kind") val payerKind: String = "",
    @SerialName("payer_name") val payerName: String = "",
    val provider: String = "",
    @SerialName("plan_code") val planCode: String? = null,
    @SerialName("amount_cents") val amountCents: Int = 0,
    @SerialName("vat_cents") val vatCents: Int? = null,
    val status: String = "",
    @SerialName("invoice_number") val invoiceNumber: String? = null,
) {
    fun toDomain() = AdminPaymentRow(
        paymentId, paidAt?.let(::parseTimestamp), payerKind, payerName, provider, planCode, amountCents, vatCents,
        status, invoiceNumber,
    )
}

@Serializable
private data class AuditDto(
    @SerialName("log_id") val logId: Long,
    @SerialName("created_at") val createdAt: String? = null,
    @SerialName("actor_kind") val actorKind: String = "",
    @SerialName("actor_email") val actorEmail: String? = null,
    val action: String = "",
    @SerialName("restaurant_name") val restaurantName: String? = null,
    @SerialName("target_email") val targetEmail: String? = null,
    val details: JsonElement? = null,
) {
    fun toDomain() = AuditRow(
        logId, createdAt?.let(::parseTimestamp), actorKind, actorEmail, action, restaurantName, targetEmail,
        details?.toString().orEmpty(),
    )
}

@Serializable
private data class ConfigDto(
    val key: String,
    val value: JsonElement,
    val description: String? = null,
)
