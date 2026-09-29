package com.haposto.ui.screens.admin

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.haposto.data.Outcome
import com.haposto.data.admin.AdminClaim
import com.haposto.data.admin.AdminOverview
import com.haposto.data.admin.AdminPaymentRow
import com.haposto.data.admin.AdminRepository
import com.haposto.data.admin.AdminRestaurantRow
import com.haposto.data.admin.AdminStatus
import com.haposto.data.admin.AdminSubscriptionRow
import com.haposto.data.admin.AdminUserRow
import com.haposto.data.admin.AuditRow
import com.haposto.data.admin.ConfigEntry
import java.time.Instant
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

enum class AdminTab(val label: String) {
    OVERVIEW("Panoramica"),
    CLAIMS("Richieste"),
    RESTAURANTS("Locali"),
    USERS("Utenti"),
    SUBSCRIPTIONS("Abbonamenti"),
    PAYMENTS("Pagamenti"),
    LOG("Registro"),
    SETTINGS("Impostazioni"),
}

data class AdminUiState(
    val status: AdminStatus? = null,
    val statusError: String? = null,
    val tab: AdminTab = AdminTab.OVERVIEW,
    val overview: AdminOverview? = null,
    val claims: List<AdminClaim> = emptyList(),
    val restaurants: List<AdminRestaurantRow> = emptyList(),
    val users: List<AdminUserRow> = emptyList(),
    val subscriptions: List<AdminSubscriptionRow> = emptyList(),
    val payments: List<AdminPaymentRow> = emptyList(),
    val audit: List<AuditRow> = emptyList(),
    val config: List<ConfigEntry> = emptyList(),
    /** Codice da dettare al telefono del locale (mostrato una volta). */
    val issuedCode: Pair<AdminClaim, String>? = null,
    val busy: Boolean = false,
    val message: String? = null,
    val messageIsError: Boolean = false,
)

class AdminViewModel(private val admin: AdminRepository) : ViewModel() {

    private val mutable = MutableStateFlow(AdminUiState())
    val state = mutable.asStateFlow()

    init {
        refreshStatus()
    }

    fun refreshStatus() {
        viewModelScope.launch {
            when (val result = admin.status()) {
                is Outcome.Success -> {
                    mutable.update { it.copy(status = result.value, statusError = null) }
                    if (result.value.isUnlocked) loadTab(mutable.value.tab)
                }
                is Outcome.Failure -> mutable.update { it.copy(statusError = result.message) }
            }
        }
    }

    fun unlock(username: String, password: String) = act {
        when (val result = admin.unlock(username, password)) {
            is Outcome.Success -> {
                refreshStatus()
                null
            }
            is Outcome.Failure -> result
        }
    }

    fun lock() = act {
        admin.lock()
        mutable.update { AdminUiState(status = it.status?.copy(unlockedUntil = null)) }
        refreshStatus()
        null
    }

    /** Il server chiude il pannello dopo 30 minuti: lo chiudiamo anche sullo schermo. */
    fun checkExpiry() {
        val until = mutable.value.status?.unlockedUntil ?: return
        if (until.isBefore(Instant.now())) refreshStatus()
    }

    fun selectTab(tab: AdminTab) {
        mutable.update { it.copy(tab = tab, message = null) }
        loadTab(tab)
    }

    fun loadTab(tab: AdminTab, query: String? = null, filter: String? = null) {
        viewModelScope.launch {
            val failure: Outcome.Failure? = when (tab) {
                AdminTab.OVERVIEW -> admin.overview().onValue { v -> mutable.update { it.copy(overview = v) } }
                AdminTab.CLAIMS -> admin.pendingClaims().onValue { v -> mutable.update { it.copy(claims = v) } }
                AdminTab.RESTAURANTS -> admin.restaurants(query, filter).onValue { v -> mutable.update { it.copy(restaurants = v) } }
                AdminTab.USERS -> admin.users(query, filter ?: "ALL").onValue { v -> mutable.update { it.copy(users = v) } }
                AdminTab.SUBSCRIPTIONS -> admin.subscriptions(filter ?: "ALL").onValue { v -> mutable.update { it.copy(subscriptions = v) } }
                AdminTab.PAYMENTS -> admin.payments().onValue { v -> mutable.update { it.copy(payments = v) } }
                AdminTab.LOG -> admin.auditLog(null, query).onValue { v -> mutable.update { it.copy(audit = v) } }
                AdminTab.SETTINGS -> admin.config().onValue { v -> mutable.update { it.copy(config = v) } }
            }
            failure?.let { f ->
                mutable.update { it.copy(message = f.message, messageIsError = true) }
                if (f.code == "ADMIN_REQUIRED") refreshStatus()
            }
        }
    }

    fun issueCode(claim: AdminClaim) = act {
        when (val result = admin.issueClaimCode(claim.claimId)) {
            is Outcome.Success -> {
                mutable.update { it.copy(issuedCode = claim to result.value) }
                loadTab(AdminTab.CLAIMS)
                null
            }
            is Outcome.Failure -> result
        }
    }

    fun dismissCode() = mutable.update { it.copy(issuedCode = null) }

    fun reviewClaim(claim: AdminClaim, approve: Boolean, note: String, skipPhoneCheck: Boolean) = act(
        success = if (approve) "✓ Richiesta approvata: il titolare riceve una notifica." else "Richiesta rifiutata.",
    ) {
        (admin.reviewClaim(claim.claimId, approve, note, skipPhoneCheck) as? Outcome.Failure).also {
            if (it == null) loadTab(AdminTab.CLAIMS)
        }
    }

    fun setConfig(key: String, json: String) = act(success = "✓ Impostazione salvata.") {
        (admin.setConfig(key, json) as? Outcome.Failure).also { if (it == null) loadTab(AdminTab.SETTINGS) }
    }

    fun cancelSubscription(row: AdminSubscriptionRow) = act(success = "✓ Abbonamento chiuso.") {
        (admin.cancelSubscription(row.kind, row.subscriptionId, "Chiuso dal pannello") as? Outcome.Failure)
            .also { if (it == null) loadTab(AdminTab.SUBSCRIPTIONS) }
    }

    fun clearMessage() = mutable.update { it.copy(message = null) }

    private fun act(success: String? = null, block: suspend () -> Outcome.Failure?) {
        viewModelScope.launch {
            mutable.update { it.copy(busy = true, message = null) }
            val failure = block()
            mutable.update {
                it.copy(
                    busy = false,
                    message = failure?.message ?: success,
                    messageIsError = failure != null,
                )
            }
            if (failure?.code == "ADMIN_REQUIRED") refreshStatus()
        }
    }
}

/** Esegue [onSuccess] col valore e restituisce l'eventuale errore. */
internal inline fun <T> Outcome<T>.onValue(onSuccess: (T) -> Unit): Outcome.Failure? = when (this) {
    is Outcome.Success -> {
        onSuccess(value)
        null
    }
    is Outcome.Failure -> this
}
