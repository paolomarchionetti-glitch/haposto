package com.haposto.data.admin

import java.time.Instant

data class AdminStatus(
    val isAdminAccount: Boolean,
    val hasCredentials: Boolean,
    val mfaOk: Boolean,
    val unlockedUntil: Instant?,
    val lockedUntil: Instant?,
) {
    val isUnlocked: Boolean get() = unlockedUntil?.isAfter(Instant.now()) == true
}

data class UnlockResult(val ok: Boolean, val errorCode: String?, val validUntil: Instant?)

/** Numeri della panoramica, già in ordine di visualizzazione. */
data class AdminOverview(val entries: List<Pair<String, String>>)

data class AdminClaim(
    val claimId: String,
    val createdAt: Instant?,
    val restaurantId: String,
    val restaurantName: String,
    val restaurantCity: String,
    val restaurantAddress: String,
    val restaurantPhone: String?,
    val partnershipStatus: String,
    val currentOwners: Int,
    val requesterId: String,
    val requesterEmail: String,
    val requesterName: String?,
    val contactInfo: String,
    val phoneCodeActive: Boolean,
    val phoneVerified: Boolean,
)

data class AdminRestaurantRow(
    val restaurantId: String,
    val name: String,
    val city: String,
    val partnershipStatus: String,
    val dataSource: String,
    val planCode: String,
    val members: Int,
    val lastPublishAt: Instant?,
    val phoneNumber: String?,
    val slug: String?,
)

data class AdminMember(val userId: String, val email: String, val role: String, val since: Instant?)
data class AdminClaimSummary(val claimId: String, val status: String, val email: String?, val createdAt: Instant?, val phoneVerified: Boolean, val note: String?)
data class AdminSubscriptionSummary(val id: String, val planCode: String, val status: String, val provider: String, val periodEnd: Instant?, val note: String?)
data class AdminPublish(val status: String, val at: Instant?, val via: String, val byEmail: String?)

data class AdminRestaurantDetail(
    val restaurantId: String,
    val name: String,
    val category: String,
    val address: String,
    val city: String,
    val province: String,
    val phoneNumber: String?,
    val phonePublic: Boolean,
    val partnershipStatus: String,
    val dataSource: String,
    val slug: String?,
    val latitude: Double?,
    val longitude: Double?,
    val planCode: String,
    val members: List<AdminMember>,
    val claims: List<AdminClaimSummary>,
    val subscriptions: List<AdminSubscriptionSummary>,
    val recentPublishes: List<AdminPublish>,
    val stats30Days: Map<String, Int>,
)

data class AdminUserRow(
    val userId: String,
    val email: String,
    val displayName: String?,
    val createdAt: Instant?,
    val lastSignInAt: Instant?,
    val isAdmin: Boolean,
    val blockedAt: Instant?,
    val consumerPlan: String,
    val restaurants: Int,
)

data class AdminUserRestaurant(val restaurantId: String, val name: String, val city: String, val role: String)
data class AdminActivity(val at: Instant?, val action: String, val actorKind: String, val details: String)

data class AdminUserDetail(
    val userId: String,
    val email: String,
    val createdAt: Instant?,
    val lastSignInAt: Instant?,
    val displayName: String?,
    val isAdmin: Boolean,
    val blockedAt: Instant?,
    val blockedReason: String?,
    val marketingOptIn: Boolean,
    val acceptedTermsVersion: String?,
    val consumerPlan: String,
    val restaurants: List<AdminUserRestaurant>,
    val subscriptions: List<AdminSubscriptionSummary>,
    val favorites: Int,
    val activeAlerts: Int,
    val recentActivity: List<AdminActivity>,
)

data class AdminSubscriptionRow(
    val kind: String,
    val subscriptionId: String,
    val subjectId: String,
    val subjectName: String,
    val planCode: String,
    val status: String,
    val provider: String,
    val periodEnd: Instant?,
    val createdAt: Instant?,
) {
    val isLive: Boolean get() = status in setOf("TRIALING", "ACTIVE", "PAST_DUE")
    val isManual: Boolean get() = provider in setOf("MANUAL", "BETA", "PROMO")
}

data class AdminPaymentRow(
    val paymentId: String,
    val paidAt: Instant?,
    val payerKind: String,
    val payerName: String,
    val provider: String,
    val planCode: String?,
    val amountCents: Int,
    val vatCents: Int?,
    val status: String,
    val invoiceNumber: String?,
)

data class AuditRow(
    val logId: Long,
    val createdAt: Instant?,
    val actorKind: String,
    val actorEmail: String?,
    val action: String,
    val restaurantName: String?,
    val targetEmail: String?,
    val details: String,
)

data class ConfigEntry(val key: String, val valueJson: String, val description: String?)

/** Campi modificabili dall'admin su un locale (null = invariato). */
data class RestaurantEdit(
    val name: String? = null,
    val category: String? = null,
    val address: String? = null,
    val city: String? = null,
    val province: String? = null,
    val latitude: Double? = null,
    val longitude: Double? = null,
    val phoneNumber: String? = null,
    val phonePublic: Boolean? = null,
)

/** Link e file di un locale da controllare (migration 0015). */
data class AdminExtrasRow(
    val restaurantId: String,
    val name: String,
    val city: String,
    val websiteUrl: String?,
    val menuUrl: String?,
    val fileUrl: String?,
    val fileIsPdf: Boolean,
    val fileBytes: Int?,
    val fileTodayOnly: Boolean,
    val changedAt: Instant?,
    val reviewedAt: Instant?,
)
