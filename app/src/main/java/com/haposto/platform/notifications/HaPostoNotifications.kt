package com.haposto.platform.notifications

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.haposto.MainActivity
import com.haposto.R

/** Canali e notifiche dell'app. Tutto locale: il testo arriva dal server o dal promemoria. */
object HaPostoNotifications {

    const val CHANNEL_REMINDERS = "manager_reminders"
    const val CHANNEL_ALERTS = "availability_alerts"
    const val CHANNEL_ACCOUNT = "account_updates"

    const val EXTRA_OPEN_RESTAURANT = "open_restaurant_id"
    const val EXTRA_OPEN_DASHBOARD = "open_dashboard_id"

    fun createChannels(context: Context) {
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        manager.createNotificationChannels(
            listOf(
                NotificationChannel(CHANNEL_REMINDERS, "Promemoria ristoratore", NotificationManager.IMPORTANCE_HIGH).apply {
                    description = "\"Il tuo stato sta per scadere: è ancora così?\" con i tasti per confermare."
                },
                NotificationChannel(CHANNEL_ALERTS, "Avvisi \"c'è posto\"", NotificationManager.IMPORTANCE_HIGH).apply {
                    description = "Quando un locale che aspetti segnala posti liberi (HAPOSTO Plus)."
                },
                NotificationChannel(CHANNEL_ACCOUNT, "Account e richieste", NotificationManager.IMPORTANCE_DEFAULT).apply {
                    description = "Esito delle richieste di gestione di un locale."
                },
            ),
        )
    }

    fun canPost(context: Context): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED

    /**
     * Unico punto che mostra notifiche: ricontrolla il permesso (Android 13+) proprio prima di
     * usarlo, perché l'utente può revocarlo in qualsiasi momento dalle impostazioni.
     */
    private fun post(context: Context, id: Int, notification: Notification) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        try {
            post(context, id, notification)
        } catch (_: SecurityException) {
            // Permesso revocato nel frattempo: la notifica si perde, l'app continua.
        }
    }

    private fun openAppIntent(context: Context, extra: String?, restaurantId: String?, requestCode: Int): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            if (extra != null && restaurantId != null) putExtra(extra, restaurantId)
        }
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun notificationId(restaurantId: String?, kind: String): Int =
        (kind + (restaurantId ?: "")).hashCode()

    /**
     * Promemoria al ristoratore con tre tasti che pubblicano senza aprire l'app.
     */
    fun showManagerReminder(context: Context, restaurantId: String, restaurantName: String, currentStatusLabel: String?) {
        if (!canPost(context)) return
        val id = notificationId(restaurantId, "reminder")
        val body = buildString {
            append("Il tuo stato scade tra pochi minuti")
            currentStatusLabel?.let { append(" (ora: ").append(it).append(')') }
            append(". È ancora così?")
        }
        val builder = NotificationCompat.Builder(context, CHANNEL_REMINDERS)
            .setSmallIcon(R.drawable.ic_launcher_monochrome)
            .setContentTitle(restaurantName)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(openAppIntent(context, EXTRA_OPEN_DASHBOARD, restaurantId, id))
        StatusActionReceiver.actions(context, restaurantId, restaurantName, id).forEach { (label, intent) ->
            builder.addAction(0, label, intent)
        }
        post(context, id, builder.build())
    }

    fun showMessage(context: Context, kind: String, title: String, body: String, restaurantId: String?) {
        if (!canPost(context)) return
        val channel = when (kind) {
            "AVAILABILITY_ALERT" -> CHANNEL_ALERTS
            "MANAGER_REMINDER" -> CHANNEL_REMINDERS
            else -> CHANNEL_ACCOUNT
        }
        val id = notificationId(restaurantId, kind)
        val extra = if (kind == "AVAILABILITY_ALERT") EXTRA_OPEN_RESTAURANT else null
        val notification = NotificationCompat.Builder(context, channel)
            .setSmallIcon(R.drawable.ic_launcher_monochrome)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setAutoCancel(true)
            .setContentIntent(openAppIntent(context, extra, restaurantId, id))
            .build()
        post(context, id, notification)
    }

    fun showConfirmation(context: Context, notificationId: Int, restaurantName: String, text: String) {
        if (!canPost(context)) return
        val notification = NotificationCompat.Builder(context, CHANNEL_REMINDERS)
            .setSmallIcon(R.drawable.ic_launcher_monochrome)
            .setContentTitle(restaurantName)
            .setContentText(text)
            .setTimeoutAfter(60_000)
            .setAutoCancel(true)
            .build()
        post(context, notificationId, notification)
    }
}
