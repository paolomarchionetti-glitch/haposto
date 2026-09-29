package com.haposto.platform.notifications

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import androidx.work.workDataOf
import com.haposto.domain.model.AvailabilityRules
import com.haposto.domain.model.AvailabilityStatus
import java.util.concurrent.TimeUnit

/**
 * Promemoria sul telefono del ristoratore, 5 minuti prima che lo stato scada. Funziona anche senza
 * server notifiche; con le notifiche push attive arriva comunque un solo avviso per volta.
 */
object Reminders {

    private const val MINUTES_BEFORE_EXPIRY = 5L

    fun scheduleAfterPublish(context: Context, restaurantId: String, restaurantName: String, status: AvailabilityStatus) {
        val delayMinutes = AvailabilityRules.LIVE_TTL_MINUTES - MINUTES_BEFORE_EXPIRY
        val request = OneTimeWorkRequestBuilder<ReminderWorker>()
            .setInitialDelay(delayMinutes, TimeUnit.MINUTES)
            .setInputData(
                workDataOf(
                    ReminderWorker.KEY_ID to restaurantId,
                    ReminderWorker.KEY_NAME to restaurantName,
                    ReminderWorker.KEY_STATUS to status.name,
                ),
            )
            .build()
        WorkManager.getInstance(context)
            .enqueueUniqueWork(workName(restaurantId), ExistingWorkPolicy.REPLACE, request)
    }

    fun cancel(context: Context, restaurantId: String) {
        WorkManager.getInstance(context).cancelUniqueWork(workName(restaurantId))
    }

    private fun workName(restaurantId: String) = "reminder-$restaurantId"
}

class ReminderWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        val id = inputData.getString(KEY_ID) ?: return Result.success()
        val name = inputData.getString(KEY_NAME).orEmpty()
        val status = when (inputData.getString(KEY_STATUS)) {
            AvailabilityStatus.AVAILABLE.name -> "C'è posto"
            AvailabilityStatus.LIMITED.name -> "Pochi posti"
            AvailabilityStatus.FULL.name -> "Completo"
            else -> null
        }
        HaPostoNotifications.showManagerReminder(applicationContext, id, name, status)
        return Result.success()
    }

    companion object {
        const val KEY_ID = "restaurant_id"
        const val KEY_NAME = "restaurant_name"
        const val KEY_STATUS = "status"
    }
}
