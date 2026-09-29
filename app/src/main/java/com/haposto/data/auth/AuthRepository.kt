package com.haposto.data.auth

import com.haposto.data.ErrorMessages
import com.haposto.data.Outcome
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

/**
 * Account HAPOSTO (Supabase Auth). Facoltativo per chi cerca un posto, obbligatorio per chi
 * gestisce un locale. Il login è solo con Google: HAPOSTO non conserva password.
 */
interface AuthRepository {
    /** false nella versione demo o se Supabase non è configurato. */
    val isAvailable: Boolean
    val state: StateFlow<AuthState>

    suspend fun signInWithGoogle(token: GoogleIdToken): Outcome<Unit>

    /** [everywhere] = esce anche dagli altri telefoni (revoca tutte le sessioni). */
    suspend fun signOut(everywhere: Boolean = false): Outcome<Unit>

    suspend fun refresh()

    suspend fun startTotpEnrollment(): Outcome<TotpEnrollment>

    /** Verifica un codice a 6 cifre: completa la configurazione o sblocca la sessione (aal2). */
    suspend fun verifyTotp(factorId: String, code: String): Outcome<Unit>

    suspend fun loadProfile(): Outcome<UserProfile>
    suspend fun acceptTerms(version: String): Outcome<Unit>
    suspend fun acceptRestaurantTerms(version: String, specificClausesAccepted: Boolean): Outcome<Unit>
    suspend fun setMarketingConsent(optIn: Boolean): Outcome<Unit>
    suspend fun setNotificationPrefs(managerReminders: Boolean?, availabilityAlerts: Boolean?, claimUpdates: Boolean?): Outcome<Unit>
    suspend fun deleteAccount(): Outcome<Unit>
}

/** Versione demo / senza configurazione: nessun account, nessuna chiamata di rete. */
class UnavailableAuthRepository : AuthRepository {
    override val isAvailable: Boolean = false
    override val state: StateFlow<AuthState> = MutableStateFlow(AuthState.SignedOut)
    private fun <T> unavailable(): Outcome<T> = ErrorMessages.failure("DEMO_MODE")

    override suspend fun signInWithGoogle(token: GoogleIdToken): Outcome<Unit> = unavailable()
    override suspend fun signOut(everywhere: Boolean): Outcome<Unit> = Outcome.Success(Unit)
    override suspend fun refresh() = Unit
    override suspend fun startTotpEnrollment(): Outcome<TotpEnrollment> = unavailable()
    override suspend fun verifyTotp(factorId: String, code: String): Outcome<Unit> = unavailable()
    override suspend fun loadProfile(): Outcome<UserProfile> = unavailable()
    override suspend fun acceptTerms(version: String): Outcome<Unit> = unavailable()
    override suspend fun acceptRestaurantTerms(version: String, specificClausesAccepted: Boolean): Outcome<Unit> = unavailable()
    override suspend fun setMarketingConsent(optIn: Boolean): Outcome<Unit> = unavailable()
    override suspend fun setNotificationPrefs(managerReminders: Boolean?, availabilityAlerts: Boolean?, claimUpdates: Boolean?): Outcome<Unit> = unavailable()
    override suspend fun deleteAccount(): Outcome<Unit> = unavailable()
}
