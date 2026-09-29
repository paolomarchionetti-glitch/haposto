package com.haposto.ui.screens.plus

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.core.net.toUri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import com.haposto.data.Outcome
import com.haposto.data.auth.AuthRepository
import com.haposto.data.auth.AuthState
import com.haposto.data.consumer.ConsumerEntitlements
import com.haposto.data.consumer.ConsumerRepository
import com.haposto.platform.billing.PlayBilling
import com.haposto.platform.billing.PlusOffer
import com.haposto.ui.components.BannerKind
import com.haposto.ui.components.BigActionButton
import com.haposto.ui.components.MessageBanner
import com.haposto.ui.components.SectionCard
import com.haposto.ui.components.SimpleScreen
import com.haposto.ui.screens.legal.LegalDocument
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class PlusUiState(
    val entitlements: ConsumerEntitlements? = null,
    val offers: List<PlusOffer> = emptyList(),
    val offersError: String? = null,
    val busy: Boolean = false,
    val message: String? = null,
    val messageIsError: Boolean = false,
)

class PlusViewModel(
    private val consumer: ConsumerRepository,
    private val billing: PlayBilling,
) : ViewModel() {

    private val mutable = MutableStateFlow(PlusUiState())
    val state = mutable.asStateFlow()

    init {
        viewModelScope.launch {
            // Acquisto completato su Google Play → il server lo verifica e attiva Plus.
            billing.purchases.collect { purchase ->
                verify(purchase.products.firstOrNull() ?: PlayBilling.PRODUCT_ID, purchase.purchaseToken)
            }
        }
        refresh()
        viewModelScope.launch {
            when (val offers = billing.loadOffers()) {
                is Outcome.Success -> mutable.update { it.copy(offers = offers.value) }
                is Outcome.Failure -> mutable.update { it.copy(offersError = offers.message) }
            }
        }
    }

    fun refresh() {
        viewModelScope.launch {
            mutable.update { it.copy(entitlements = consumer.entitlements().valueOrNull) }
        }
    }

    fun buy(activity: Activity, offer: PlusOffer, userId: String) {
        val result = billing.launch(activity, offer, userId)
        if (result is Outcome.Failure) mutable.update { it.copy(message = result.message, messageIsError = true) }
    }

    fun restore() {
        viewModelScope.launch {
            mutable.update { it.copy(busy = true, message = null) }
            val owned = billing.ownedPurchases()
            if (owned.isEmpty()) {
                mutable.update { it.copy(busy = false, message = "Nessun abbonamento trovato per questo account Google.", messageIsError = false) }
            } else {
                owned.forEach { verify(it.products.firstOrNull() ?: PlayBilling.PRODUCT_ID, it.purchaseToken) }
            }
        }
    }

    private suspend fun verify(productId: String, token: String) {
        mutable.update { it.copy(busy = true, message = "Attivo HAPOSTO Plus…", messageIsError = false) }
        val result = consumer.verifyPlayPurchase(productId, token)
        val entitlements = consumer.entitlements().valueOrNull
        mutable.update {
            it.copy(
                busy = false,
                entitlements = entitlements,
                message = when (result) {
                    is Outcome.Success -> "✓ HAPOSTO Plus è attivo. Grazie!"
                    is Outcome.Failure -> "Pagamento ricevuto da Google, ma l'attivazione non è riuscita: tocca «Ripristina acquisti» tra poco. (${result.message})"
                },
                messageIsError = result is Outcome.Failure,
            )
        }
    }

    override fun onCleared() {
        billing.close()
    }
}

@Composable
fun PlusRoute(
    consumer: ConsumerRepository,
    auth: AuthRepository,
    onBack: () -> Unit,
    onOpenAccount: () -> Unit,
    onOpenDocument: (LegalDocument) -> Unit,
) {
    val context = LocalContext.current
    if (!consumer.isAvailable) {
        SimpleScreen(title = "HAPOSTO Plus", onBack = onBack) {
            MessageBanner("Nella versione demo gli acquisti non sono disponibili.")
            Benefits()
        }
        return
    }
    val viewModel: PlusViewModel = viewModel(
        factory = viewModelFactory { initializer { PlusViewModel(consumer, PlayBilling(context.applicationContext)) } },
    )
    val state = viewModel.state.collectAsStateWithLifecycle().value
    val authState = auth.state.collectAsStateWithLifecycle().value
    val userId = (authState as? AuthState.SignedIn)?.user?.id

    SimpleScreen(title = "HAPOSTO Plus", onBack = onBack) {
        state.message?.let { MessageBanner(it, if (state.messageIsError) BannerKind.ERROR else BannerKind.SUCCESS) }
        val entitlements = state.entitlements
        if (entitlements?.isPlus == true) {
            SectionCard(title = "✓ Hai HAPOSTO Plus") {
                entitlements.validUntil?.let {
                    Text("Rinnovo o scadenza: ${DATE.format(it.atZone(ZoneId.systemDefault()))}", style = MaterialTheme.typography.bodyMedium)
                }
                OutlinedButton(
                    onClick = {
                        context.startActivity(Intent(Intent.ACTION_VIEW, PlayBilling.manageSubscriptionUrl(context.packageName).toUri()))
                    },
                    modifier = Modifier.fillMaxWidth(),
                ) { Text("Gestisci o disdici su Google Play") }
            }
            Benefits()
        } else {
            Benefits()
            SectionCard(title = "Abbonati") {
                when {
                    userId == null -> {
                        Text("Per abbonarti serve l'accesso con Google (così Plus vale su tutti i tuoi telefoni).")
                        BigActionButton(text = "Vai ad Account e accedi", onClick = onOpenAccount)
                    }
                    state.offers.isEmpty() -> Text(state.offersError ?: "Carico i prezzi da Google Play…")
                    else -> state.offers.forEach { offer ->
                        BigActionButton(
                            text = "Abbonati · ${offer.formattedPrice} ${offer.periodLabel}" + if (offer.hasFreeTrial) " (prova gratuita)" else "",
                            enabled = !state.busy,
                            onClick = { context.findActivity()?.let { viewModel.buy(it, offer, userId) } },
                        )
                    }
                }
                TextButton(onClick = viewModel::restore, enabled = userId != null && !state.busy) { Text("Ripristina acquisti") }
                Text(
                    "Prezzi IVA inclusa. Il pagamento avviene con Google Play; l'abbonamento si rinnova automaticamente " +
                        "finché non lo disdici da Google Play → Abbonamenti. Iniziando subito a usare Plus rinunci al recesso " +
                        "di 14 giorni per i contenuti digitali (art. 59 Codice del Consumo).",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                TextButton(onClick = { onOpenDocument(LegalDocument.TERMS) }) { Text("Termini d'uso") }
            }
        }
        Spacer(Modifier.height(16.dp))
    }
}

@Composable
private fun Benefits() {
    SectionCard(title = "Cosa include", subtitle = "Cercare dove c'è posto resta sempre gratis.") {
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text("🔔  Avvisami quando c'è posto: una notifica appena il locale che aspetti si libera")
            Text("★  Preferiti illimitati, sincronizzati su tutti i tuoi telefoni")
            Text("📍  Ricerca fino a 100 km invece di 60")
            Text("📊  \"Di solito com'è\": quando quel locale è di solito pieno")
        }
    }
}

private tailrec fun Context.findActivity(): Activity? = when (this) {
    is Activity -> this
    is ContextWrapper -> baseContext.findActivity()
    else -> null
}

private val DATE: DateTimeFormatter = DateTimeFormatter.ofPattern("dd/MM/yyyy")
