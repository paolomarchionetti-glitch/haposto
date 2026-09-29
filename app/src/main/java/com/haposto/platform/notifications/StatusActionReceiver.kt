package com.haposto.platform.notifications

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.haposto.AppDependencies
import com.haposto.data.Outcome
import com.haposto.domain.model.AvailabilityStatus
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

/** Tasti "C'è posto / Pochi posti / Completo" nella notifica: pubblicano senza aprire l'app. */
class StatusActionReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val restaurantId = intent.getStringExtra(EXTRA_RESTAURANT_ID) ?: return
        val restaurantName = intent.getStringExtra(EXTRA_RESTAURANT_NAME).orEmpty()
        val status = runCatching { AvailabilityStatus.valueOf(intent.getStringExtra(EXTRA_STATUS).orEmpty()) }.getOrNull() ?: return
        val notificationId = intent.getIntExtra(EXTRA_NOTIFICATION_ID, 0)
        val appContext = context.applicationContext
        val pending = goAsync()
        scope.launch {
            try {
                AppDependencies.init(appContext)
                val management = AppDependencies.managementRepository
                val result = management?.publish(restaurantId, status, null, null, null)
                val text = when (result) {
                    is Outcome.Success -> {
                        Reminders.scheduleAfterPublish(appContext, restaurantId, restaurantName, status)
                        "✓ Pubblicato: i clienti lo vedono per 30 minuti."
                    }
                    is Outcome.Failure -> "Non pubblicato: ${result.message}"
                    null -> "Apri l'app per aggiornare lo stato."
                }
                HaPostoNotifications.showConfirmation(appContext, notificationId, restaurantName, text)
            } finally {
                pending.finish()
            }
        }
    }

    companion object {
        private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

        private const val ACTION = "com.haposto.action.PUBLISH_STATUS"
        private const val EXTRA_RESTAURANT_ID = "restaurant_id"
        private const val EXTRA_RESTAURANT_NAME = "restaurant_name"
        private const val EXTRA_STATUS = "status"
        private const val EXTRA_NOTIFICATION_ID = "notification_id"

        fun actions(context: Context, restaurantId: String, restaurantName: String, notificationId: Int): List<Pair<String, PendingIntent>> =
            listOf(
                "✓ C'è posto" to AvailabilityStatus.AVAILABLE,
                "! Pochi posti" to AvailabilityStatus.LIMITED,
                "✕ Completo" to AvailabilityStatus.FULL,
            ).mapIndexed { index, (label, status) ->
                val intent = Intent(context, StatusActionReceiver::class.java).apply {
                    action = ACTION
                    putExtra(EXTRA_RESTAURANT_ID, restaurantId)
                    putExtra(EXTRA_RESTAURANT_NAME, restaurantName)
                    putExtra(EXTRA_STATUS, status.name)
                    putExtra(EXTRA_NOTIFICATION_ID, notificationId)
                }
                label to PendingIntent.getBroadcast(
                    context,
                    notificationId * 10 + index,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
            }
    }
}
