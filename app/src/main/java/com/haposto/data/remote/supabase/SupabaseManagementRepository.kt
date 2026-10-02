package com.haposto.data.remote.supabase

import com.haposto.data.ErrorMessages
import com.haposto.data.Outcome
import com.haposto.data.outcomeOf
import com.haposto.data.restaurant.ActivityEntry
import com.haposto.data.restaurant.ClaimStatus
import com.haposto.data.restaurant.CodeCheck
import com.haposto.data.restaurant.DailyStat
import com.haposto.data.restaurant.ManagedRestaurant
import com.haposto.data.restaurant.ManagerInfo
import com.haposto.data.restaurant.MemberRole
import com.haposto.data.restaurant.MyClaim
import com.haposto.data.restaurant.NewRestaurantForm
import com.haposto.data.restaurant.RestaurantManagementRepository
import com.haposto.data.restaurant.RestaurantMember
import com.haposto.data.restaurant.RestaurantExtras
import com.haposto.data.restaurant.RestaurantFile
import com.haposto.data.restaurant.RestaurantPlan
import com.haposto.domain.model.AvailabilityStatus
import com.haposto.domain.model.GeoPoint
import com.haposto.domain.model.OpeningHours
import com.haposto.domain.model.Restaurant
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.functions.functions
import io.github.jan.supabase.postgrest.postgrest
import io.ktor.client.request.parameter
import io.ktor.client.request.setBody
import io.ktor.client.statement.bodyAsText
import io.ktor.http.ContentType
import io.ktor.http.content.ByteArrayContent
import io.ktor.http.isSuccess
import java.time.LocalDate
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.intOrNull
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.put

class SupabaseManagementRepository(private val client: SupabaseClient) : RestaurantManagementRepository {

    override suspend fun myRestaurants(): Outcome<List<ManagedRestaurant>> = outcomeOf {
        client.postgrest.rpc("my_restaurants").decodeList<MyRestaurantDto>().map { it.toDomain() }
    }

    override suspend fun myClaims(): Outcome<List<MyClaim>> = outcomeOf {
        client.postgrest.rpc("my_claims").decodeList<MyClaimDto>().map { it.toDomain() }
    }

    override suspend fun searchDirectory(query: String, near: GeoPoint): Outcome<List<Restaurant>> = outcomeOf {
        val params = buildJsonObject {
            put("lat", near.latitude)
            put("long", near.longitude)
            put("radius_meters", SEARCH_RADIUS_METERS)
            put("search_text", query.trim().takeIf(String::isNotEmpty))
        }
        client.postgrest.rpc("nearby_restaurants", params)
            .decodeList<NearbyRestaurantDto>()
            .map(NearbyRestaurantDto::toDomain)
            .take(30)
    }

    override suspend fun submitClaim(restaurantId: String, contactInfo: String): Outcome<String> = outcomeOf {
        client.postgrest.rpc(
            "submit_restaurant_claim",
            buildJsonObject {
                put("p_restaurant_id", restaurantId)
                put("p_contact_info", contactInfo.trim())
            },
        ).decodeAs<String>()
    }

    override suspend fun registerNewRestaurant(form: NewRestaurantForm): Outcome<String> = outcomeOf {
        client.postgrest.rpc(
            "register_new_restaurant",
            buildJsonObject {
                put("p_name", form.name.trim())
                put("p_category", form.category.trim())
                put("p_address", form.address.trim())
                put("p_city", form.city.trim())
                put("p_province", form.province.trim())
                put("p_latitude", form.location.latitude)
                put("p_longitude", form.location.longitude)
                put("p_phone_number", form.phoneNumber.trim())
                put("p_contact_info", form.contactInfo.trim())
            },
        ).decodeAs<String>()
    }

    override suspend fun cancelClaim(claimId: String): Outcome<Unit> = outcomeOf {
        client.postgrest.rpc("cancel_my_claim", buildJsonObject { put("p_claim_id", claimId) })
        Unit
    }

    override suspend fun verifyClaimCode(claimId: String, code: String): Outcome<CodeCheck> = outcomeOf {
        client.postgrest.rpc(
            "verify_my_claim_code",
            buildJsonObject {
                put("p_claim_id", claimId)
                put("p_code", code.filter(Char::isDigit))
            },
        ).decodeList<CodeCheckDto>().first().let { CodeCheck(it.ok, it.errorCode, it.attemptsLeft ?: 0) }
    }

    override suspend fun managerInfo(restaurantId: String): Outcome<ManagerInfo> = outcomeOf {
        client.postgrest.rpc("restaurant_manager_info", buildJsonObject { put("p_restaurant_id", restaurantId) })
            .decodeList<ManagerInfoDto>()
            .firstOrNull()
            ?.toDomain()
            ?: error("Not authorized for this restaurant")
    }

    override suspend fun updateProfile(
        restaurantId: String,
        name: String,
        category: String,
        phoneNumber: String?,
        phonePublic: Boolean,
        openingHours: OpeningHours?,
    ): Outcome<Unit> = outcomeOf {
        client.postgrest.rpc(
            "update_restaurant_profile",
            buildJsonObject {
                put("p_restaurant_id", restaurantId)
                put("p_name", name.trim())
                put("p_category", category.trim())
                put("p_phone_number", phoneNumber?.trim()?.takeIf(String::isNotEmpty))
                put("p_phone_public", phonePublic)
                put("p_opening_hours", openingHours?.toJson() ?: JsonNull)
            },
        )
        Unit
    }

    override suspend fun members(restaurantId: String): Outcome<List<RestaurantMember>> = outcomeOf {
        client.postgrest.rpc("restaurant_members", buildJsonObject { put("p_restaurant_id", restaurantId) })
            .decodeList<MemberDto>()
            .map { it.toDomain() }
    }

    override suspend fun addStaff(restaurantId: String, email: String): Outcome<Unit> = outcomeOf {
        client.postgrest.rpc(
            "add_restaurant_staff",
            buildJsonObject {
                put("p_restaurant_id", restaurantId)
                put("p_email", email.trim())
            },
        )
        Unit
    }

    override suspend fun removeStaff(restaurantId: String, userId: String): Outcome<Unit> = outcomeOf {
        client.postgrest.rpc(
            "remove_restaurant_staff",
            buildJsonObject {
                put("p_restaurant_id", restaurantId)
                put("p_user_id", userId)
            },
        )
        Unit
    }

    override suspend fun activity(restaurantId: String, limit: Int): Outcome<List<ActivityEntry>> = outcomeOf {
        client.postgrest.rpc(
            "restaurant_activity",
            buildJsonObject {
                put("p_restaurant_id", restaurantId)
                put("p_limit", limit)
            },
        ).decodeList<ActivityDto>().map { ActivityEntry(parseTimestamp(it.happenedAt.orEmpty()), it.kind, it.actor.orEmpty(), it.summary.orEmpty()) }
    }

    override suspend fun stats(restaurantId: String, days: Int): Outcome<List<DailyStat>> = outcomeOf {
        client.postgrest.rpc(
            "restaurant_stats",
            buildJsonObject {
                put("p_restaurant_id", restaurantId)
                put("p_days", days)
            },
        ).decodeList<DailyStatDto>().mapNotNull { it.toDomain() }
    }

    override suspend fun publish(
        restaurantId: String,
        status: AvailabilityStatus,
        availableTables: Int?,
        estimatedWaitMinutes: Int?,
        note: String?,
        offer: String?,
    ): Outcome<Unit> {
        if (status !in PUBLISHABLE) return ErrorMessages.failure("INVALID_STATUS")
        return outcomeOf {
            client.postgrest.rpc(
                "set_restaurant_live_status",
                buildJsonObject {
                    put("p_restaurant_id", restaurantId)
                    put("p_status", status.name)
                    put("p_available_tables", if (status == AvailabilityStatus.FULL) null else availableTables)
                    put("p_estimated_wait_minutes", estimatedWaitMinutes)
                    put("p_note", note?.trim()?.takeIf(String::isNotEmpty))
                    // Solo se c'è: la versione con l'offerta esiste dalla migration 0015; senza offerta
                    // la pubblicazione funziona anche su un database che non l'ha ancora.
                    val cleanOffer = offer?.trim()?.takeIf(String::isNotEmpty)
                    if (status != AvailabilityStatus.FULL && cleanOffer != null) put("p_offer", cleanOffer)
                },
            )
            Unit
        }
    }

    override suspend fun extras(restaurantId: String): Outcome<RestaurantExtras> = outcomeOf {
        client.postgrest.rpc("restaurant_extras", buildJsonObject { put("p_restaurant_id", restaurantId) })
            .decodeList<ExtrasDto>()
            .firstOrNull()
            ?.toDomain()
            ?: RestaurantExtras()
    }

    override suspend fun setQuickNotes(restaurantId: String, notes: List<String>): Outcome<List<String>> = outcomeOf {
        client.postgrest.rpc(
            "set_restaurant_quick_notes",
            buildJsonObject {
                put("p_restaurant_id", restaurantId)
                put("p_notes", JsonArray(notes.map(::JsonPrimitive)))
            },
        ).decodeAs<List<String>>()
    }

    override suspend fun setLinks(restaurantId: String, websiteUrl: String?, menuUrl: String?): Outcome<Unit> = outcomeOf {
        client.postgrest.rpc(
            "set_restaurant_links",
            buildJsonObject {
                put("p_restaurant_id", restaurantId)
                put("p_website_url", websiteUrl?.trim()?.takeIf(String::isNotEmpty))
                put("p_menu_url", menuUrl?.trim()?.takeIf(String::isNotEmpty))
            },
        )
        Unit
    }

    override suspend fun uploadFile(
        restaurantId: String,
        bytes: ByteArray,
        mimeType: String,
        todayOnly: Boolean,
    ): Outcome<Unit> = outcomeOf {
        // Edge Function restaurant-file: controlla tipo vero, peso e dimensioni, poi salva.
        val response = client.functions.invoke("restaurant-file") {
            parameter("restaurant_id", restaurantId)
            parameter("today_only", todayOnly)
            setBody(ByteArrayContent(bytes, ContentType.parse(mimeType)))
        }
        if (!response.status.isSuccess()) error(response.bodyAsText().take(200))
        Unit
    }

    override suspend fun removeFile(restaurantId: String): Outcome<Unit> = outcomeOf {
        val response = client.functions.invoke("restaurant-file") {
            parameter("restaurant_id", restaurantId)
            parameter("action", "remove")
        }
        if (!response.status.isSuccess()) error(response.bodyAsText().take(200))
        Unit
    }

    private companion object {
        const val SEARCH_RADIUS_METERS = 100_000
        val PUBLISHABLE = setOf(AvailabilityStatus.AVAILABLE, AvailabilityStatus.LIMITED, AvailabilityStatus.FULL)
    }
}

internal fun OpeningHours.toJson(): JsonObject = JsonObject(
    toServerMap().mapValues { (_, ranges) ->
        JsonArray(ranges.map { pair -> JsonArray(pair.map(::JsonPrimitive)) })
    },
)

internal fun openingHoursFrom(element: JsonElement?): OpeningHours? {
    val obj = element as? JsonObject ?: return null
    val raw = runCatching {
        obj.mapValues { (_, ranges) ->
            ranges.jsonArray.map { pair -> pair.jsonArray.map { it.jsonPrimitive.content } }
        }
    }.getOrNull() ?: return null
    return OpeningHours.fromServerMap(raw)
}

private fun roleOf(value: String?): MemberRole =
    if (value.equals("OWNER", ignoreCase = true)) MemberRole.OWNER else MemberRole.STAFF

@Serializable
internal data class MyRestaurantDto(
    @SerialName("restaurant_id") val restaurantId: String,
    val name: String,
    val city: String,
    val role: String,
    @SerialName("partnership_status") val partnershipStatus: String,
) {
    fun toDomain() = ManagedRestaurant(
        restaurantId = restaurantId,
        name = name,
        city = city,
        role = roleOf(role),
        isActivePartner = partnershipStatus == "ACTIVE_PARTNER",
    )
}

@Serializable
internal data class MyClaimDto(
    @SerialName("claim_id") val claimId: String,
    @SerialName("restaurant_id") val restaurantId: String,
    @SerialName("restaurant_name") val restaurantName: String,
    @SerialName("restaurant_city") val restaurantCity: String = "",
    val status: String,
    @SerialName("created_at") val createdAt: String? = null,
    @SerialName("review_note") val reviewNote: String? = null,
    @SerialName("phone_code_pending") val phoneCodePending: Boolean = false,
    @SerialName("phone_verified_at") val phoneVerifiedAt: String? = null,
) {
    fun toDomain() = MyClaim(
        claimId = claimId,
        restaurantId = restaurantId,
        restaurantName = restaurantName,
        restaurantCity = restaurantCity,
        status = ClaimStatus.entries.firstOrNull { it.name == status } ?: ClaimStatus.PENDING,
        createdAt = createdAt?.let(::parseTimestamp),
        reviewNote = reviewNote,
        phoneCodePending = phoneCodePending,
        phoneVerified = phoneVerifiedAt != null,
    )
}

@Serializable
internal data class CodeCheckDto(
    val ok: Boolean,
    @SerialName("error_code") val errorCode: String? = null,
    @SerialName("attempts_left") val attemptsLeft: Int? = null,
)

@Serializable
internal data class ManagerInfoDto(
    @SerialName("restaurant_id") val restaurantId: String,
    val name: String,
    val category: String = "Ristorante",
    val address: String = "",
    val city: String = "",
    val province: String? = null,
    @SerialName("phone_number") val phoneNumber: String? = null,
    @SerialName("phone_public") val phonePublic: Boolean = false,
    @SerialName("opening_hours") val openingHours: JsonElement? = null,
    val slug: String? = null,
    @SerialName("partnership_status") val partnershipStatus: String,
    @SerialName("my_role") val myRole: String,
    @SerialName("plan_code") val planCode: String = "RESTAURANT_BASIC",
    @SerialName("plan_name") val planName: String = "Basic",
    @SerialName("plan_source") val planSource: String = "FREE",
    @SerialName("plan_valid_until") val planValidUntil: String? = null,
    val features: List<String> = emptyList(),
    val limits: JsonObject? = null,
    @SerialName("mfa_required") val mfaRequired: Boolean = true,
    @SerialName("mfa_ok") val mfaOk: Boolean = false,
) {
    fun toDomain() = ManagerInfo(
        restaurantId = restaurantId,
        name = name,
        category = category,
        address = address,
        city = city,
        phoneNumber = phoneNumber,
        phonePublic = phonePublic,
        openingHours = openingHoursFrom(openingHours),
        slug = slug,
        isActivePartner = partnershipStatus == "ACTIVE_PARTNER",
        isSuspended = partnershipStatus == "SUSPENDED",
        myRole = roleOf(myRole),
        plan = RestaurantPlan(
            code = planCode,
            name = planName,
            source = planSource,
            validUntil = planValidUntil?.let(::parseTimestamp),
            features = features.toSet(),
            staffLimit = limits?.get("staff_accounts")?.jsonPrimitive?.intOrNull ?: 0,
            analyticsDays = limits?.get("analytics_days")?.jsonPrimitive?.intOrNull ?: 7,
        ),
        mfaRequired = mfaRequired,
        mfaOk = mfaOk,
    )
}

@Serializable
internal data class MemberDto(
    @SerialName("user_id") val userId: String,
    val email: String = "",
    @SerialName("display_name") val displayName: String? = null,
    val role: String,
    @SerialName("member_since") val memberSince: String? = null,
) {
    fun toDomain() = RestaurantMember(userId, email, displayName, roleOf(role), memberSince?.let(::parseTimestamp))
}

@Serializable
internal data class ActivityDto(
    @SerialName("happened_at") val happenedAt: String? = null,
    val kind: String,
    val actor: String? = null,
    val summary: String? = null,
)

@Serializable
internal data class DailyStatDto(
    val day: String,
    @SerialName("detail_views") val detailViews: Int = 0,
    @SerialName("directions_taps") val directionsTaps: Int = 0,
    @SerialName("call_taps") val callTaps: Int = 0,
    @SerialName("public_page_views") val publicPageViews: Int = 0,
    val shares: Int = 0,
    @SerialName("live_updates") val liveUpdates: Int = 0,
) {
    fun toDomain(): DailyStat? = runCatching {
        DailyStat(LocalDate.parse(day), detailViews, directionsTaps, callTaps, publicPageViews, shares, liveUpdates)
    }.getOrNull()
}

@Serializable
internal data class ExtrasDto(
    @SerialName("quick_notes") val quickNotes: List<String>? = null,
    @SerialName("website_url") val websiteUrl: String? = null,
    @SerialName("menu_url") val menuUrl: String? = null,
    @SerialName("file_path") val filePath: String? = null,
    @SerialName("file_mime") val fileMime: String? = null,
    @SerialName("file_bytes") val fileBytes: Int? = null,
    @SerialName("file_expires_at") val fileExpiresAt: String? = null,
) {
    fun toDomain() = RestaurantExtras(
        quickNotes = quickNotes.orEmpty(),
        websiteUrl = websiteUrl,
        menuUrl = menuUrl,
        file = if (filePath != null && fileMime != null) {
            RestaurantFile(filePath, fileMime, fileBytes ?: 0, fileExpiresAt?.let(::parseTimestamp))
        } else {
            null
        },
    )
}
