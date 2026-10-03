package com.haposto.data.restaurant

import com.haposto.domain.model.GeoPoint
import com.haposto.domain.model.OpeningHours
import java.time.Instant
import java.time.LocalDate

enum class MemberRole { OWNER, STAFF }

/** Un locale che l'utente gestisce (titolare o staff). */
data class ManagedRestaurant(
    val restaurantId: String,
    val name: String,
    val city: String,
    val role: MemberRole,
    val isActivePartner: Boolean,
)

enum class ClaimStatus { PENDING, APPROVED, REJECTED, CANCELLED }

data class MyClaim(
    val claimId: String,
    val restaurantId: String,
    val restaurantName: String,
    val restaurantCity: String,
    val status: ClaimStatus,
    val createdAt: Instant?,
    val reviewNote: String?,
    /** HAPOSTO ha dettato il codice al telefono del locale: va inserito nell'app. */
    val phoneCodePending: Boolean,
    val phoneVerified: Boolean,
)

data class CodeCheck(
    val ok: Boolean,
    val errorCode: String?,
    val attemptsLeft: Int,
)

data class NewRestaurantForm(
    val name: String,
    val category: String,
    val address: String,
    val city: String,
    val province: String,
    val location: GeoPoint,
    val phoneNumber: String,
    val contactInfo: String,
)

data class RestaurantPlan(
    val code: String,
    val name: String,
    /** STRIPE, MANUAL, BETA, TRIAL (prova del locale), NONE (nessun piano); FREE sui database prima della 0016. */
    val source: String,
    val validUntil: Instant?,
    val features: Set<String>,
    val staffLimit: Int,
    val analyticsDays: Int,
) {
    val isPro: Boolean get() = "LIVE_DETAILS" in features
    /** Con un piano il locale si vede "collegato" e pubblica lo stato; senza appare "Non collegato". */
    val isConnected: Boolean get() = "LIVE_STATUS" in features
    fun has(feature: String): Boolean = feature in features
}

/** Tutto ciò che serve alla dashboard e alla gestione del locale. */
data class ManagerInfo(
    val restaurantId: String,
    val name: String,
    val category: String,
    val address: String,
    val city: String,
    val phoneNumber: String?,
    val phonePublic: Boolean,
    val openingHours: OpeningHours?,
    val slug: String?,
    val isActivePartner: Boolean,
    val isSuspended: Boolean,
    val myRole: MemberRole,
    val plan: RestaurantPlan,
    val mfaRequired: Boolean,
    val mfaOk: Boolean,
)

data class RestaurantMember(
    val userId: String,
    val email: String,
    val displayName: String?,
    val role: MemberRole,
    val since: Instant?,
)

data class ActivityEntry(
    val at: Instant?,
    val kind: String,
    val actor: String,
    val summary: String,
)

data class DailyStat(
    val day: LocalDate,
    val detailViews: Int,
    val directionsTaps: Int,
    val callTaps: Int,
    val publicPageViews: Int,
    val shares: Int,
    val liveUpdates: Int,
)

/** Note pronte, link e file del locale (migration 0015). */
data class RestaurantExtras(
    val quickNotes: List<String> = emptyList(),
    val websiteUrl: String? = null,
    val menuUrl: String? = null,
    val file: RestaurantFile? = null,
) {
    companion object {
        const val MAX_QUICK_NOTES = 8
    }
}

/** Il file facoltativo del locale; [expiresAt] non nullo = "solo per oggi". */
data class RestaurantFile(
    val path: String,
    val mimeType: String,
    val bytes: Int,
    val expiresAt: java.time.Instant?,
) {
    val isPdf: Boolean get() = mimeType == "application/pdf"
    val todayOnly: Boolean get() = expiresAt != null
}
