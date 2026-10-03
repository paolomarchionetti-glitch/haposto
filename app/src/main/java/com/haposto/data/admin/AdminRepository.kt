package com.haposto.data.admin

import com.haposto.data.Outcome

/**
 * Pannello amministratore. Ogni funzione è protetta nel database: account admin + 2FA +
 * seconda password (sblocco valido 30 minuti su questo telefono). Tutto finisce nel registro.
 */
interface AdminRepository {
    suspend fun status(): Outcome<AdminStatus>
    suspend fun unlock(username: String, password: String): Outcome<UnlockResult>
    suspend fun lock(): Outcome<Unit>

    suspend fun overview(): Outcome<AdminOverview>

    suspend fun pendingClaims(): Outcome<List<AdminClaim>>
    suspend fun issueClaimCode(claimId: String): Outcome<String>
    suspend fun reviewClaim(claimId: String, approve: Boolean, note: String?, skipPhoneCheck: Boolean): Outcome<Unit>

    suspend fun restaurants(query: String?, status: String?, offset: Int = 0): Outcome<List<AdminRestaurantRow>>
    suspend fun restaurantDetail(restaurantId: String): Outcome<AdminRestaurantDetail>
    suspend fun setRestaurantStatus(restaurantId: String, status: String, note: String?): Outcome<Unit>
    suspend fun updateRestaurant(restaurantId: String, edit: RestaurantEdit): Outcome<Unit>
    suspend fun addMember(restaurantId: String, email: String, role: String, note: String?): Outcome<Unit>
    suspend fun removeMember(restaurantId: String, userId: String, note: String?): Outcome<Unit>
    suspend fun grantRestaurantPlan(restaurantId: String, planCode: String, months: Int, note: String?): Outcome<Unit>

    suspend fun users(query: String?, filter: String, offset: Int = 0): Outcome<List<AdminUserRow>>
    suspend fun userDetail(userId: String): Outcome<AdminUserDetail>
    suspend fun setUserBlocked(userId: String, blocked: Boolean, reason: String?): Outcome<Unit>
    suspend fun grantPlus(userId: String, months: Int, note: String?): Outcome<Unit>

    suspend fun subscriptions(kind: String): Outcome<List<AdminSubscriptionRow>>
    suspend fun cancelSubscription(kind: String, subscriptionId: String, note: String?): Outcome<Unit>
    suspend fun payments(offset: Int = 0): Outcome<List<AdminPaymentRow>>

    suspend fun auditLog(beforeId: Long?, action: String?): Outcome<List<AuditRow>>

    /** Link e file dei locali: da controllare (o tutti). */
    suspend fun restaurantExtras(onlyUnreviewed: Boolean = true): Outcome<List<AdminExtrasRow>>

    /** [action]: OK (visto), REMOVE_LINKS, REMOVE_FILE, REMOVE_ALL. */
    suspend fun reviewRestaurantExtras(restaurantId: String, action: String, reason: String?): Outcome<Unit>

    suspend fun config(): Outcome<List<ConfigEntry>>
    suspend fun setConfig(key: String, valueJson: String): Outcome<Unit>
}
