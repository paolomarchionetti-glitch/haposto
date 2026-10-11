package com.haposto.platform.qr

import android.content.Context
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.codescanner.GmsBarcodeScannerOptions
import com.google.mlkit.vision.codescanner.GmsBarcodeScanning
import kotlin.coroutines.resume
import kotlinx.coroutines.suspendCancellableCoroutine

/**
 * Scanner QR di Google Play services: la schermata della fotocamera è di Google, quindi l'app
 * non chiede il permesso della fotocamera. Al primo uso Google può scaricare il modulo da sé.
 */
object QrScanner {

    sealed interface Result {
        data class Scanned(val raw: String) : Result
        data object Cancelled : Result
        data class Failed(val reason: String) : Result
    }

    /** [context] deve essere l'Activity (LocalContext di Compose). */
    suspend fun scan(context: Context): Result = suspendCancellableCoroutine { continuation ->
        val options = GmsBarcodeScannerOptions.Builder()
            .setBarcodeFormats(Barcode.FORMAT_QR_CODE)
            .build()
        GmsBarcodeScanning.getClient(context, options)
            .startScan()
            .addOnSuccessListener { barcode ->
                if (continuation.isActive) continuation.resume(Result.Scanned(barcode.rawValue.orEmpty()))
            }
            .addOnCanceledListener {
                if (continuation.isActive) continuation.resume(Result.Cancelled)
            }
            .addOnFailureListener { error ->
                if (continuation.isActive) continuation.resume(Result.Failed(error.message.orEmpty()))
            }
    }
}
