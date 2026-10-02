package com.haposto.data.restaurant

import com.haposto.data.Outcome
import com.haposto.domain.model.AvailabilityStatus
import com.haposto.domain.model.GeoPoint
import com.haposto.domain.model.OpeningHours
import com.haposto.domain.model.Restaurant

/**
 * Area ristoratore con account vero (versioni DEV e PROD). Tutte le regole di sicurezza sono nel
 * database (2FA, ruoli, verifica telefonica): qui solo le chiamate.
 */
interface RestaurantManagementRepository {
    suspend fun myRestaurants(): Outcome<List<ManagedRestaurant>>
    suspend fun myClaims(): Outcome<List<MyClaim>>

    /** Cerca nella directory, anche i locali "non collegati", per chiederne la gestione. */
    suspend fun searchDirectory(query: String, near: GeoPoint): Outcome<List<Restaurant>>
    suspend fun submitClaim(restaurantId: String, contactInfo: String): Outcome<String>
    suspend fun registerNewRestaurant(form: NewRestaurantForm): Outcome<String>
    suspend fun cancelClaim(claimId: String): Outcome<Unit>
    suspend fun verifyClaimCode(claimId: String, code: String): Outcome<CodeCheck>

    suspend fun managerInfo(restaurantId: String): Outcome<ManagerInfo>
    suspend fun updateProfile(
        restaurantId: String,
        name: String,
        category: String,
        phoneNumber: String?,
        phonePublic: Boolean,
        openingHours: OpeningHours?,
    ): Outcome<Unit>

    suspend fun members(restaurantId: String): Outcome<List<RestaurantMember>>
    suspend fun addStaff(restaurantId: String, email: String): Outcome<Unit>
    suspend fun removeStaff(restaurantId: String, userId: String): Outcome<Unit>

    suspend fun activity(restaurantId: String, limit: Int = 60): Outcome<List<ActivityEntry>>
    suspend fun stats(restaurantId: String, days: Int): Outcome<List<DailyStat>>

    /** Pubblicazione protetta (titolare o staff, con 2FA), con l'eventuale offerta della serata. */
    suspend fun publish(
        restaurantId: String,
        status: AvailabilityStatus,
        availableTables: Int?,
        estimatedWaitMinutes: Int?,
        note: String?,
        offer: String? = null,
    ): Outcome<Unit>

    /** Note pronte, link e file del locale (titolare e staff). */
    suspend fun extras(restaurantId: String): Outcome<RestaurantExtras>

    /** Note pronte (titolare e staff, al massimo 8): restituisce la lista salvata. */
    suspend fun setQuickNotes(restaurantId: String, notes: List<String>): Outcome<List<String>>

    /** Link del sito e del menù (solo titolare); vuoto = nessun link. */
    suspend fun setLinks(restaurantId: String, websiteUrl: String?, menuUrl: String?): Outcome<Unit>

    /** File del locale (solo titolare): foto già ridotta (JPEG) o PDF; [todayOnly] = si cancella la notte dopo. */
    suspend fun uploadFile(restaurantId: String, bytes: ByteArray, mimeType: String, todayOnly: Boolean): Outcome<Unit>
    suspend fun removeFile(restaurantId: String): Outcome<Unit>
}
