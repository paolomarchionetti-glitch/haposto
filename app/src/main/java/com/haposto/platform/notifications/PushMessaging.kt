package com.haposto.platform.notifications

import android.content.Context
import com.google.firebase.FirebaseApp
import com.google.firebase.FirebaseOptions
import com.google.firebase.messaging.FirebaseMessaging
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.haposto.AppDependencies
import com.haposto.config.AppConfig
import kotlin.coroutines.resume
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine

/**
 * Notifiche push con Firebase Cloud Messaging (gratuito). Facoltative: senza la configurazione
 * FIREBASE_* in local.properties l'app funziona e usa solo i promemoria locali.
 */
object PushMessaging {

    fun initialize(context: Context): Boolean {
        val settings = AppConfig.firebase ?: return false
        return runCatching {
            if (FirebaseApp.getApps(context).isEmpty()) {
                FirebaseApp.initializeApp(
                    context,
                    FirebaseOptions.Builder()
                        .setApplicationId(settings.applicationId)
                        .setApiKey(settings.apiKey)
                        .setProjectId(settings.projectId)
                        .setGcmSenderId(settings.senderId)
                        .build(),
                )
            }
            true
        }.getOrDefault(false)
    }

    val isEnabled: Boolean
        get() = AppConfig.firebase != null && runCatching { FirebaseApp.getInstance() }.isSuccess

    suspend fun currentToken(): String? {
        if (!isEnabled) return null
        return suspendCancellableCoroutine { continuation ->
            FirebaseMessaging.getInstance().token.addOnCompleteListener { task ->
                continuation.resume(if (task.isSuccessful) task.result else null)
            }
        }
    }

    /** Registra il telefono per l'utente collegato (chiamato dopo l'accesso e a ogni nuovo token). */
    suspend fun registerForCurrentUser() {
        val token = currentToken() ?: return
        AppDependencies.consumerRepository.registerPushToken(token, AppConfig.versionCode.toString())
    }

    suspend fun unregisterCurrentDevice() {
        val token = currentToken() ?: return
        AppDependencies.consumerRepository.unregisterPushToken(token)
    }
}

class HaPostoMessagingService : FirebaseMessagingService() {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    override fun onNewToken(token: String) {
        AppDependencies.init(applicationContext)
        scope.launch {
            AppDependencies.consumerRepository.registerPushToken(token, AppConfig.versionCode.toString())
        }
    }

    /** Il server manda messaggi "data": il testo e i tasti li costruisce l'app. */
    override fun onMessageReceived(message: RemoteMessage) {
        val data = message.data
        val kind = data["kind"].orEmpty()
        val restaurantId = data["restaurant_id"]
        val title = data["title"] ?: message.notification?.title ?: "HAPOSTO"
        val body = data["body"] ?: message.notification?.body.orEmpty()
        if (kind == "MANAGER_REMINDER" && restaurantId != null) {
            HaPostoNotifications.showManagerReminder(applicationContext, restaurantId, data["restaurant_name"] ?: title, null)
        } else {
            HaPostoNotifications.showMessage(applicationContext, kind, title, body, restaurantId)
        }
    }
}
