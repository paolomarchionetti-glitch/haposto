package com.haposto.platform.billing

import android.app.Activity
import android.content.Context
import com.android.billingclient.api.BillingClient
import com.android.billingclient.api.BillingClientStateListener
import com.android.billingclient.api.BillingFlowParams
import com.android.billingclient.api.BillingResult
import com.android.billingclient.api.PendingPurchasesParams
import com.android.billingclient.api.ProductDetails
import com.android.billingclient.api.Purchase
import com.android.billingclient.api.PurchasesUpdatedListener
import com.android.billingclient.api.QueryProductDetailsParams
import com.android.billingclient.api.QueryPurchasesParams
import com.haposto.data.ErrorMessages
import com.haposto.data.Outcome
import com.haposto.data.auth.Nonce
import kotlin.coroutines.resume
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.suspendCancellableCoroutine

/** Un'offerta di HAPOSTO Plus come la mostra Google Play (prezzo già localizzato e con IVA). */
data class PlusOffer(
    val basePlanId: String,
    val offerToken: String,
    val formattedPrice: String,
    /** ISO 8601: P1M = al mese, P1Y = all'anno. */
    val billingPeriod: String,
    val hasFreeTrial: Boolean,
) {
    val periodLabel: String
        get() = when (billingPeriod) {
            "P1M" -> "al mese"
            "P1Y" -> "all'anno"
            else -> billingPeriod
        }
}

/**
 * Google Play Billing per l'abbonamento HAPOSTO Plus (prodotto "haposto_plus"). L'acquisto viene
 * poi verificato dal server (Edge Function play-verify), che attiva Plus e lo conferma a Google.
 */
class PlayBilling(context: Context) {

    private val mutablePurchases = MutableSharedFlow<Purchase>(extraBufferCapacity = 8)

    /** Acquisti appena completati (o ripristinati) da mandare al server. */
    val purchases: SharedFlow<Purchase> = mutablePurchases

    private val listener = PurchasesUpdatedListener { result, list ->
        if (result.responseCode == BillingClient.BillingResponseCode.OK) {
            list.orEmpty()
                .filter { it.purchaseState == Purchase.PurchaseState.PURCHASED }
                .forEach { mutablePurchases.tryEmit(it) }
        }
    }

    private val client: BillingClient = BillingClient.newBuilder(context.applicationContext)
        .setListener(listener)
        .enablePendingPurchases(PendingPurchasesParams.newBuilder().enableOneTimeProducts().build())
        .build()

    private var productDetails: ProductDetails? = null

    private suspend fun connect(): Boolean {
        if (client.isReady) return true
        return suspendCancellableCoroutine { continuation ->
            client.startConnection(object : BillingClientStateListener {
                override fun onBillingSetupFinished(result: BillingResult) {
                    if (continuation.isActive) {
                        continuation.resume(result.responseCode == BillingClient.BillingResponseCode.OK)
                    }
                }

                override fun onBillingServiceDisconnected() {
                    if (continuation.isActive) continuation.resume(false)
                }
            })
        }
    }

    suspend fun loadOffers(productId: String = PRODUCT_ID): Outcome<List<PlusOffer>> {
        if (!connect()) return ErrorMessages.failure("BILLING_UNAVAILABLE")
        val params = QueryProductDetailsParams.newBuilder()
            .setProductList(
                listOf(
                    QueryProductDetailsParams.Product.newBuilder()
                        .setProductId(productId)
                        .setProductType(BillingClient.ProductType.SUBS)
                        .build(),
                ),
            )
            .build()
        val details: ProductDetails? = suspendCancellableCoroutine { continuation ->
            client.queryProductDetailsAsync(params) { _, result ->
                if (continuation.isActive) continuation.resume(result.productDetailsList.firstOrNull())
            }
        }
        productDetails = details ?: return ErrorMessages.failure("BILLING_UNAVAILABLE")
        val offers = details.subscriptionOfferDetails.orEmpty().map { offer ->
            val phases = offer.pricingPhases.pricingPhaseList
            val paid = phases.lastOrNull()
            PlusOffer(
                basePlanId = offer.basePlanId,
                offerToken = offer.offerToken,
                formattedPrice = paid?.formattedPrice.orEmpty(),
                billingPeriod = paid?.billingPeriod.orEmpty(),
                hasFreeTrial = phases.any { it.priceAmountMicros == 0L },
            )
        }
        return Outcome.Success(offers)
    }

    /** Apre la schermata di pagamento di Google Play. [userId] lega l'acquisto all'account. */
    fun launch(activity: Activity, offer: PlusOffer, userId: String): Outcome<Unit> {
        val details = productDetails ?: return ErrorMessages.failure("BILLING_UNAVAILABLE")
        val params = BillingFlowParams.newBuilder()
            .setProductDetailsParamsList(
                listOf(
                    BillingFlowParams.ProductDetailsParams.newBuilder()
                        .setProductDetails(details)
                        .setOfferToken(offer.offerToken)
                        .build(),
                ),
            )
            // Google chiede un identificativo non personale: l'impronta dell'id utente.
            .setObfuscatedAccountId(Nonce.sha256Hex(userId).take(64))
            .build()
        val result = client.launchBillingFlow(activity, params)
        return if (result.responseCode == BillingClient.BillingResponseCode.OK) {
            Outcome.Success(Unit)
        } else {
            ErrorMessages.failure("BILLING_UNAVAILABLE")
        }
    }

    /** Abbonamenti già comprati con questo account Google (telefono nuovo, reinstallazione). */
    suspend fun ownedPurchases(): List<Purchase> {
        if (!connect()) return emptyList()
        val params = QueryPurchasesParams.newBuilder().setProductType(BillingClient.ProductType.SUBS).build()
        return suspendCancellableCoroutine { continuation ->
            client.queryPurchasesAsync(params) { _, list ->
                if (continuation.isActive) {
                    continuation.resume(list.filter { it.purchaseState == Purchase.PurchaseState.PURCHASED })
                }
            }
        }
    }

    fun close() {
        client.endConnection()
    }

    companion object {
        const val PRODUCT_ID = "haposto_plus"

        fun manageSubscriptionUrl(packageName: String): String =
            "https://play.google.com/store/account/subscriptions?sku=$PRODUCT_ID&package=$packageName"
    }
}
