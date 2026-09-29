package com.haposto.data.auth

import java.time.Instant

data class AuthUser(
    val id: String,
    val email: String?,
    val displayName: String?,
)

/**
 * Stato della 2FA (codice a 6 cifre di un'app di autenticazione, TOTP).
 * [verified] = in questa sessione il codice è già stato inserito (livello "aal2").
 */
data class MfaState(
    val totpFactorId: String?,
    val verified: Boolean,
) {
    val enrolled: Boolean get() = totpFactorId != null
}

sealed interface AuthState {
    data object Loading : AuthState
    data object SignedOut : AuthState
    data class SignedIn(val user: AuthUser, val mfa: MfaState) : AuthState
}

/** Dati per configurare l'app di autenticazione (Google Authenticator, Microsoft Authenticator…). */
data class TotpEnrollment(
    val factorId: String,
    val otpauthUri: String,
    val secret: String,
)

data class UserProfile(
    val userId: String,
    val email: String?,
    val displayName: String?,
    val isAdminAccount: Boolean,
    val blocked: Boolean,
    val blockedReason: String?,
    val acceptedTermsVersion: String?,
    val currentTermsVersion: String?,
    val acceptedRestaurantTermsVersion: String?,
    val currentRestaurantTermsVersion: String?,
    val marketingOptIn: Boolean,
    val notifyManagerReminders: Boolean,
    val notifyAvailabilityAlerts: Boolean,
    val notifyClaimUpdates: Boolean,
    val consumerPlan: String,
    val consumerPlanUntil: Instant?,
    val restaurants: Int,
) {
    val needsTerms: Boolean
        get() = acceptedTermsVersion == null ||
            (currentTermsVersion != null && acceptedTermsVersion != currentTermsVersion)

    val needsRestaurantTerms: Boolean
        get() = acceptedRestaurantTermsVersion == null ||
            (currentRestaurantTermsVersion != null && acceptedRestaurantTermsVersion != currentRestaurantTermsVersion)

    val hasPlus: Boolean get() = consumerPlan == "CONSUMER_PLUS"
}

/** Token di Google pronto per Supabase, con il nonce "in chiaro" usato per chiederlo. */
data class GoogleIdToken(
    val idToken: String,
    val rawNonce: String,
)
