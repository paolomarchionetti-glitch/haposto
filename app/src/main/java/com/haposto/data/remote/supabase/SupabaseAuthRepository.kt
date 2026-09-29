package com.haposto.data.remote.supabase

import com.haposto.data.Outcome
import com.haposto.data.auth.AuthRepository
import com.haposto.data.auth.AuthState
import com.haposto.data.auth.AuthUser
import com.haposto.data.auth.GoogleIdToken
import com.haposto.data.auth.MfaState
import com.haposto.data.auth.TotpEnrollment
import com.haposto.data.auth.UserProfile
import com.haposto.data.outcomeOf
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.auth.SignOutScope
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.auth.mfa.AuthenticatorAssuranceLevel
import io.github.jan.supabase.auth.mfa.FactorType
import io.github.jan.supabase.auth.providers.Google
import io.github.jan.supabase.auth.providers.builtin.IDToken
import io.github.jan.supabase.auth.status.SessionStatus
import io.github.jan.supabase.auth.user.UserSession
import io.github.jan.supabase.postgrest.postgrest
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.put

class SupabaseAuthRepository(
    private val client: SupabaseClient,
    scope: CoroutineScope,
) : AuthRepository {

    override val isAvailable: Boolean = true

    private val mutableState = MutableStateFlow<AuthState>(AuthState.Loading)
    override val state: StateFlow<AuthState> = mutableState.asStateFlow()

    init {
        scope.launch {
            client.auth.sessionStatus.collect { status ->
                when (status) {
                    is SessionStatus.Authenticated -> mutableState.value = signedIn(status.session)
                    is SessionStatus.NotAuthenticated -> mutableState.value = AuthState.SignedOut
                    is SessionStatus.Initializing -> mutableState.value = AuthState.Loading
                    // Senza rete il rinnovo fallisce: si resta collegati con la sessione salvata.
                    is SessionStatus.RefreshFailure -> Unit
                }
            }
        }
    }

    private fun signedIn(session: UserSession): AuthState.SignedIn {
        val user = session.user
        val displayName = user?.userMetadata?.let { metadata ->
            (metadata["full_name"] ?: metadata["name"])?.jsonPrimitive?.content
        }
        val totp = client.auth.mfa.verifiedFactors.firstOrNull { it.factorType.equals("totp", ignoreCase = true) }
        val level = runCatching { client.auth.mfa.getAuthenticatorAssuranceLevel() }.getOrNull()
        return AuthState.SignedIn(
            user = AuthUser(id = user?.id.orEmpty(), email = user?.email, displayName = displayName),
            mfa = MfaState(
                totpFactorId = totp?.id,
                verified = level?.current == AuthenticatorAssuranceLevel.AAL2,
            ),
        )
    }

    private fun publishCurrent() {
        mutableState.value = client.auth.currentSessionOrNull()?.let(::signedIn) ?: AuthState.SignedOut
    }

    override suspend fun signInWithGoogle(token: GoogleIdToken): Outcome<Unit> = outcomeOf {
        client.auth.signInWith(IDToken) {
            idToken = token.idToken
            provider = Google
            nonce = token.rawNonce
        }
        publishCurrent()
    }

    override suspend fun signOut(everywhere: Boolean): Outcome<Unit> = outcomeOf {
        client.auth.signOut(if (everywhere) SignOutScope.GLOBAL else SignOutScope.LOCAL)
        mutableState.value = AuthState.SignedOut
    }

    override suspend fun refresh() {
        runCatching { client.auth.retrieveUserForCurrentSession(updateSession = true) }
        publishCurrent()
    }

    override suspend fun startTotpEnrollment(): Outcome<TotpEnrollment> = outcomeOf {
        // Una configurazione lasciata a metà (QR mostrato ma codice mai inserito) va rimossa,
        // altrimenti Supabase rifiuta la nuova.
        client.auth.mfa.retrieveFactorsForCurrentUser()
            .filter { !it.isVerified }
            .forEach { client.auth.mfa.unenroll(it.id) }
        val factor = client.auth.mfa.enroll(FactorType.TOTP, friendlyName = "HAPOSTO") {
            issuer = "HAPOSTO"
        }
        TotpEnrollment(factorId = factor.id, otpauthUri = factor.data.uri, secret = factor.data.secret)
    }

    override suspend fun verifyTotp(factorId: String, code: String): Outcome<Unit> = outcomeOf {
        client.auth.mfa.createChallengeAndVerify(factorId = factorId, code = code.filter(Char::isDigit))
        runCatching { client.auth.retrieveUserForCurrentSession(updateSession = true) }
        publishCurrent()
    }

    override suspend fun loadProfile(): Outcome<UserProfile> = outcomeOf {
        client.postgrest.rpc("my_profile")
            .decodeList<ProfileDto>()
            .firstOrNull()
            ?.toDomain()
            ?: error("AUTH_REQUIRED")
    }

    override suspend fun acceptTerms(version: String): Outcome<Unit> = outcomeOf {
        client.postgrest.rpc("accept_terms", buildJsonObject { put("p_version", version) })
        Unit
    }

    override suspend fun acceptRestaurantTerms(version: String, specificClausesAccepted: Boolean): Outcome<Unit> = outcomeOf {
        client.postgrest.rpc(
            "accept_restaurant_terms",
            buildJsonObject {
                put("p_version", version)
                put("p_specific_clauses_accepted", specificClausesAccepted)
            },
        )
        Unit
    }

    override suspend fun setMarketingConsent(optIn: Boolean): Outcome<Unit> = outcomeOf {
        client.postgrest.rpc("set_marketing_consent", buildJsonObject { put("p_opt_in", optIn) })
        Unit
    }

    override suspend fun setNotificationPrefs(
        managerReminders: Boolean?,
        availabilityAlerts: Boolean?,
        claimUpdates: Boolean?,
    ): Outcome<Unit> = outcomeOf {
        client.postgrest.rpc(
            "set_notification_prefs",
            buildJsonObject {
                put("p_manager_reminders", managerReminders)
                put("p_availability_alerts", availabilityAlerts)
                put("p_claim_updates", claimUpdates)
            },
        )
        Unit
    }

    override suspend fun deleteAccount(): Outcome<Unit> = outcomeOf {
        client.postgrest.rpc("delete_my_account")
        // L'utente non esiste più: si cancella anche la sessione salvata sul telefono.
        runCatching { client.auth.clearSession() }
        mutableState.value = AuthState.SignedOut
    }
}

@Serializable
internal data class ProfileDto(
    @SerialName("user_id") val userId: String,
    val email: String? = null,
    @SerialName("display_name") val displayName: String? = null,
    @SerialName("is_admin_account") val isAdminAccount: Boolean = false,
    val blocked: Boolean = false,
    @SerialName("blocked_reason") val blockedReason: String? = null,
    @SerialName("accepted_terms_version") val acceptedTermsVersion: String? = null,
    @SerialName("current_terms_version") val currentTermsVersion: String? = null,
    @SerialName("accepted_restaurant_terms_version") val acceptedRestaurantTermsVersion: String? = null,
    @SerialName("current_restaurant_terms_version") val currentRestaurantTermsVersion: String? = null,
    @SerialName("marketing_opt_in") val marketingOptIn: Boolean = false,
    @SerialName("notify_manager_reminders") val notifyManagerReminders: Boolean = true,
    @SerialName("notify_availability_alerts") val notifyAvailabilityAlerts: Boolean = true,
    @SerialName("notify_claim_updates") val notifyClaimUpdates: Boolean = true,
    @SerialName("consumer_plan") val consumerPlan: String = "CONSUMER_FREE",
    @SerialName("consumer_plan_until") val consumerPlanUntil: String? = null,
    val restaurants: Int = 0,
) {
    fun toDomain() = UserProfile(
        userId = userId,
        email = email,
        displayName = displayName,
        isAdminAccount = isAdminAccount,
        blocked = blocked,
        blockedReason = blockedReason,
        acceptedTermsVersion = acceptedTermsVersion,
        currentTermsVersion = currentTermsVersion,
        acceptedRestaurantTermsVersion = acceptedRestaurantTermsVersion,
        currentRestaurantTermsVersion = currentRestaurantTermsVersion,
        marketingOptIn = marketingOptIn,
        notifyManagerReminders = notifyManagerReminders,
        notifyAvailabilityAlerts = notifyAvailabilityAlerts,
        notifyClaimUpdates = notifyClaimUpdates,
        consumerPlan = consumerPlan,
        consumerPlanUntil = consumerPlanUntil?.let(::parseTimestamp),
        restaurants = restaurants,
    )
}
