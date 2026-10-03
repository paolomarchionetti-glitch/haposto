package com.haposto.data.remote.supabase

import com.haposto.data.ErrorMessages
import com.haposto.data.Outcome
import com.haposto.data.consumer.ConsumerEntitlements
import com.haposto.data.consumer.ConsumerRepository
import com.haposto.data.consumer.PatternCell
import com.haposto.data.consumer.PublicDetails
import com.haposto.data.consumer.RestaurantEvent
import com.haposto.data.outcomeOf
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.functions.functions
import io.github.jan.supabase.postgrest.postgrest
import io.ktor.client.statement.bodyAsText
import io.ktor.http.isSuccess
import kotlin.coroutines.cancellation.CancellationException
import java.time.Instant
import java.time.temporal.ChronoUnit
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.intOrNull
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.put

class SupabaseConsumerRepository(private val client: SupabaseClient) : ConsumerRepository {

    override val isAvailable: Boolean = true

    private fun userId(): String? = client.auth.currentUserOrNull()?.id

    override suspend fun entitlements(): Outcome<ConsumerEntitlements> = outcomeOf {
        client.postgrest.rpc("my_entitlements").decodeList<EntitlementsDto>().firstOrNull()?.toDomain()
            ?: ConsumerEntitlements.FREE
    }

    override suspend fun remoteFavorites(): Outcome<Set<String>> = outcomeOf {
        if (userId() == null) error("AUTH_REQUIRED")
        client.postgrest.from("favorites").select().decodeList<FavoriteDto>().map { it.restaurantId }.toSet()
    }

    override suspend fun addFavorite(restaurantId: String): Outcome<Unit> = outcomeOf {
        val uid = userId() ?: error("AUTH_REQUIRED")
        client.postgrest.from("favorites").upsert(FavoriteDto(uid, restaurantId)) {
            ignoreDuplicates = true
        }
        Unit
    }

    override suspend fun removeFavorite(restaurantId: String): Outcome<Unit> = outcomeOf {
        val uid = userId() ?: error("AUTH_REQUIRED")
        client.postgrest.from("favorites").delete {
            filter {
                eq("user_id", uid)
                eq("restaurant_id", restaurantId)
            }
        }
        Unit
    }

    override suspend fun activeAlerts(): Outcome<Set<String>> = outcomeOf {
        if (userId() == null) return@outcomeOf emptySet()
        val now = Instant.now()
        client.postgrest.from("availability_alerts").select {
            filter { eq("is_active", true) }
        }.decodeList<AlertDto>()
            .filter { alert -> alert.expiresAt?.let(::parseTimestamp)?.isAfter(now) != false }
            .map { it.restaurantId }
            .toSet()
    }

    override suspend fun createAlert(restaurantId: String, includeLimited: Boolean): Outcome<Unit> = outcomeOf {
        val uid = userId() ?: error("AUTH_REQUIRED")
        client.postgrest.from("availability_alerts").insert(
            NewAlertDto(
                userId = uid,
                restaurantId = restaurantId,
                notifyOn = if (includeLimited) "AVAILABLE_OR_LIMITED" else "AVAILABLE",
                // Un avviso vale per la serata: 6 ore.
                expiresAt = Instant.now().plus(6, ChronoUnit.HOURS).toString(),
            ),
        )
        Unit
    }

    override suspend fun cancelAlert(restaurantId: String): Outcome<Unit> = outcomeOf {
        val uid = userId() ?: error("AUTH_REQUIRED")
        client.postgrest.from("availability_alerts").update({ set("is_active", false) }) {
            filter {
                eq("user_id", uid)
                eq("restaurant_id", restaurantId)
                eq("is_active", true)
            }
        }
        Unit
    }

    override suspend fun availabilityPattern(restaurantId: String): Outcome<List<PatternCell>> = outcomeOf {
        client.postgrest.rpc(
            "restaurant_availability_pattern",
            buildJsonObject { put("p_restaurant_id", restaurantId) },
        ).decodeList<PatternDto>().map {
            PatternCell(it.weekday, it.hour, it.samples, it.availableShare, it.limitedShare, it.fullShare)
        }
    }

    override suspend fun publicDetails(restaurantId: String): Outcome<PublicDetails> = outcomeOf {
        client.postgrest.rpc(
            "restaurant_public_details",
            buildJsonObject { put("p_restaurant_id", restaurantId) },
        ).decodeList<PublicDetailsDto>().firstOrNull()
            ?.let {
                PublicDetails(
                    slug = it.slug,
                    openingHours = openingHoursFrom(it.openingHours),
                    websiteUrl = it.websiteUrl,
                    menuUrl = it.menuUrl,
                    fileUrl = it.filePath?.let(::publicFileUrl),
                    fileIsPdf = it.fileMime == "application/pdf",
                    fileTodayOnly = it.fileTodayOnly == true,
                )
            }
            ?: PublicDetails(null, null)
    }

    override suspend fun trackEvent(restaurantId: String, event: RestaurantEvent) {
        try {
            client.postgrest.rpc(
                "track_restaurant_event",
                buildJsonObject {
                    put("p_restaurant_id", restaurantId)
                    put("p_event", event.name)
                },
            )
        } catch (cancellation: CancellationException) {
            throw cancellation
        } catch (_: Exception) {
            // Le statistiche non devono mai disturbare l'utente.
        }
    }

    override suspend fun registerPushToken(token: String, appVersion: String): Outcome<Unit> = outcomeOf {
        if (userId() == null) error("AUTH_REQUIRED")
        client.postgrest.rpc(
            "register_push_token",
            buildJsonObject {
                put("p_token", token)
                put("p_platform", "ANDROID")
                put("p_app_version", appVersion)
            },
        )
        Unit
    }

    override suspend fun unregisterPushToken(token: String): Outcome<Unit> = outcomeOf {
        if (userId() != null) {
            client.postgrest.rpc("unregister_push_token", buildJsonObject { put("p_token", token) })
        }
        Unit
    }

    override suspend fun verifyPlayPurchase(productId: String, purchaseToken: String): Outcome<Unit> {
        if (userId() == null) return ErrorMessages.failure("AUTH_REQUIRED")
        return outcomeOf {
            val response = client.functions.invoke(
                function = "play-verify",
                body = buildJsonObject {
                    put("productId", productId)
                    put("purchaseToken", purchaseToken)
                },
            )
            if (!response.status.isSuccess()) error(response.bodyAsText().take(200))
            Unit
        }
    }
}

@Serializable
private data class EntitlementsDto(
    @SerialName("plan_code") val planCode: String,
    @SerialName("plan_name") val planName: String = "",
    val features: List<String> = emptyList(),
    val limits: JsonObject? = null,
    @SerialName("valid_until") val validUntil: String? = null,
) {
    fun toDomain() = ConsumerEntitlements(
        planCode = planCode,
        planName = planName,
        features = features.toSet(),
        favoritesMax = limits?.get("favorites_max")?.jsonPrimitive?.intOrNull ?: 5,
        searchRadiusKm = limits?.get("search_radius_km")?.jsonPrimitive?.intOrNull ?: 60,
        activeAlertsMax = limits?.get("active_alerts_max")?.jsonPrimitive?.intOrNull ?: 0,
        validUntil = validUntil?.let(::parseTimestamp),
    )
}

@Serializable
private data class FavoriteDto(
    @SerialName("user_id") val userId: String,
    @SerialName("restaurant_id") val restaurantId: String,
)

@Serializable
private data class AlertDto(
    @SerialName("restaurant_id") val restaurantId: String,
    @SerialName("expires_at") val expiresAt: String? = null,
)

@Serializable
private data class NewAlertDto(
    @SerialName("user_id") val userId: String,
    @SerialName("restaurant_id") val restaurantId: String,
    @SerialName("notify_on") val notifyOn: String,
    @SerialName("expires_at") val expiresAt: String,
)

@Serializable
private data class PatternDto(
    val weekday: Int,
    val hour: Int,
    val samples: Int,
    @SerialName("available_share") val availableShare: Double,
    @SerialName("limited_share") val limitedShare: Double,
    @SerialName("full_share") val fullShare: Double,
)

@Serializable
private data class PublicDetailsDto(
    val slug: String? = null,
    @SerialName("opening_hours") val openingHours: JsonElement? = null,
    @SerialName("website_url") val websiteUrl: String? = null,
    @SerialName("menu_url") val menuUrl: String? = null,
    @SerialName("file_path") val filePath: String? = null,
    @SerialName("file_mime") val fileMime: String? = null,
    @SerialName("file_today_only") val fileTodayOnly: Boolean? = null,
)

/** Indirizzo pubblico di un file del locale (contenitore "restaurant-files", lettura libera). */
internal fun publicFileUrl(path: String): String =
    "${SupabaseClientProvider.configuration.url}/storage/v1/object/public/restaurant-files/$path"
