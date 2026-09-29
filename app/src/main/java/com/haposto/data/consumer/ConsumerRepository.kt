package com.haposto.data.consumer

import com.haposto.data.ErrorMessages
import com.haposto.data.Outcome
import com.haposto.domain.model.OpeningHours
import java.time.Instant

data class ConsumerEntitlements(
    val planCode: String,
    val planName: String,
    val features: Set<String>,
    val favoritesMax: Int,
    val searchRadiusKm: Int,
    val activeAlertsMax: Int,
    val validUntil: Instant?,
) {
    val isPlus: Boolean get() = planCode == "CONSUMER_PLUS"
    fun has(feature: String): Boolean = feature in features

    companion object {
        val FREE = ConsumerEntitlements(
            planCode = "CONSUMER_FREE",
            planName = "Gratis",
            features = setOf("SEARCH_LIVE", "FAVORITES_SYNC"),
            favoritesMax = 5,
            searchRadiusKm = 60,
            activeAlertsMax = 0,
            validUntil = null,
        )
    }
}

/** "Di solito com'è": quota di stati per giorno della settimana (1 = lunedì) e ora. */
data class PatternCell(
    val weekday: Int,
    val hour: Int,
    val samples: Int,
    val availableShare: Double,
    val limitedShare: Double,
    val fullShare: Double,
)

data class PublicDetails(val slug: String?, val openingHours: OpeningHours?)

enum class RestaurantEvent { DETAIL_VIEW, DIRECTIONS_TAP, CALL_TAP, SHARE }

/**
 * Funzioni per chi cerca un posto: Plus, preferiti sincronizzati, avvisi, statistiche anonime,
 * notifiche. Senza account resta tutto utilizzabile tranne ciò che è legato all'account.
 */
interface ConsumerRepository {
    val isAvailable: Boolean

    suspend fun entitlements(): Outcome<ConsumerEntitlements>

    suspend fun remoteFavorites(): Outcome<Set<String>>
    suspend fun addFavorite(restaurantId: String): Outcome<Unit>
    suspend fun removeFavorite(restaurantId: String): Outcome<Unit>

    suspend fun activeAlerts(): Outcome<Set<String>>
    suspend fun createAlert(restaurantId: String, includeLimited: Boolean): Outcome<Unit>
    suspend fun cancelAlert(restaurantId: String): Outcome<Unit>

    suspend fun availabilityPattern(restaurantId: String): Outcome<List<PatternCell>>
    suspend fun publicDetails(restaurantId: String): Outcome<PublicDetails>

    /** Contatore anonimo per le statistiche del locale (nessun dato dell'utente). */
    suspend fun trackEvent(restaurantId: String, event: RestaurantEvent)

    suspend fun registerPushToken(token: String, appVersion: String): Outcome<Unit>
    suspend fun unregisterPushToken(token: String): Outcome<Unit>

    /** Manda la ricevuta di Google Play al server, che la verifica con Google e attiva Plus. */
    suspend fun verifyPlayPurchase(productId: String, purchaseToken: String): Outcome<Unit>
}

class UnavailableConsumerRepository : ConsumerRepository {
    override val isAvailable: Boolean = false
    private fun <T> demo(): Outcome<T> = ErrorMessages.failure("DEMO_MODE")

    override suspend fun entitlements(): Outcome<ConsumerEntitlements> = Outcome.Success(ConsumerEntitlements.FREE)
    override suspend fun remoteFavorites(): Outcome<Set<String>> = demo()
    override suspend fun addFavorite(restaurantId: String): Outcome<Unit> = demo()
    override suspend fun removeFavorite(restaurantId: String): Outcome<Unit> = demo()
    override suspend fun activeAlerts(): Outcome<Set<String>> = Outcome.Success(emptySet())
    override suspend fun createAlert(restaurantId: String, includeLimited: Boolean): Outcome<Unit> = demo()
    override suspend fun cancelAlert(restaurantId: String): Outcome<Unit> = demo()
    override suspend fun availabilityPattern(restaurantId: String): Outcome<List<PatternCell>> = demo()
    override suspend fun publicDetails(restaurantId: String): Outcome<PublicDetails> = Outcome.Success(PublicDetails(null, null))
    override suspend fun trackEvent(restaurantId: String, event: RestaurantEvent) = Unit
    override suspend fun registerPushToken(token: String, appVersion: String): Outcome<Unit> = demo()
    override suspend fun unregisterPushToken(token: String): Outcome<Unit> = Outcome.Success(Unit)
    override suspend fun verifyPlayPurchase(productId: String, purchaseToken: String): Outcome<Unit> = demo()
}
