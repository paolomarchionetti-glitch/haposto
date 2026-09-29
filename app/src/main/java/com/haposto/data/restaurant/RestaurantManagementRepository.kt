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

    /** Pubblicazione protetta (titolare o staff, con 2FA). */
    suspend fun publish(
        restaurantId: String,
        status: AvailabilityStatus,
        availableTables: Int?,
        estimatedWaitMinutes: Int?,
        note: String?,
    ): Outcome<Unit>
}
