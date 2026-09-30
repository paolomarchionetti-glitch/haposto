package com.haposto.platform.notifications

import android.Manifest
import android.app.Notification
import android.app.NotificationManager
import android.os.Build
import androidx.core.app.NotificationManagerCompat
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.After
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Le notifiche (dal server e promemoria locali) arrivano davvero ad Android: tutte passano da
 * HaPostoNotifications.post(), che deve consegnarle al sistema.
 */
@RunWith(AndroidJUnit4::class)
class HaPostoNotificationsTest {

    private val context = InstrumentationRegistry.getInstrumentation().targetContext

    @Before
    fun grantPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            InstrumentationRegistry.getInstrumentation().uiAutomation
                .grantRuntimePermission(context.packageName, Manifest.permission.POST_NOTIFICATIONS)
        }
        HaPostoNotifications.createChannels(context)
    }

    @After
    fun cleanUp() {
        NotificationManagerCompat.from(context).cancelAll()
    }

    @Test
    fun showMessage_postsTheServerNotification() {
        HaPostoNotifications.showMessage(context, "CLAIM_UPDATE", "Prova HAPOSTO", "Le notifiche funzionano", null)

        assertTrue("notifica dal server non mostrata", waitForNotificationTitled("Prova HAPOSTO"))
    }

    @Test
    fun showManagerReminder_postsTheLocalReminder() {
        HaPostoNotifications.showManagerReminder(context, "restaurant-test", "Osteria di prova", "C'è posto")

        assertTrue("promemoria locale non mostrato", waitForNotificationTitled("Osteria di prova"))
    }

    private fun waitForNotificationTitled(title: String): Boolean {
        val manager = context.getSystemService(NotificationManager::class.java)
        repeat(50) {
            val found = manager.activeNotifications.any {
                it.notification.extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() == title
            }
            if (found) return true
            Thread.sleep(100)
        }
        return false
    }
}
