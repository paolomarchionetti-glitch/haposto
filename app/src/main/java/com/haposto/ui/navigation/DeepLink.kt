package com.haposto.ui.navigation

import android.content.Intent
import com.haposto.platform.notifications.HaPostoNotifications

/** Aperture dell'app da una notifica: scheda del locale o dashboard del proprio locale. */
sealed interface DeepLink {
    data class Restaurant(val restaurantId: String) : DeepLink
    data class Dashboard(val restaurantId: String) : DeepLink

    companion object {
        fun from(intent: Intent?): DeepLink? {
            if (intent == null) return null
            intent.getStringExtra(HaPostoNotifications.EXTRA_OPEN_DASHBOARD)
                ?.takeIf { it.isNotBlank() }
                ?.let { return Dashboard(it) }
            intent.getStringExtra(HaPostoNotifications.EXTRA_OPEN_RESTAURANT)
                ?.takeIf { it.isNotBlank() }
                ?.let { return Restaurant(it) }
            return null
        }
    }
}
