package com.haposto.ui.util

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import androidx.core.net.toUri
import com.haposto.domain.model.Restaurant

object ExternalActions {

    fun openDirections(context: Context, restaurant: Restaurant): Boolean {
        val lat = restaurant.location.latitude
        val lon = restaurant.location.longitude
        val label = Uri.encode(restaurant.name)
        val intent = Intent(
            Intent.ACTION_VIEW,
            "geo:$lat,$lon?q=$lat,$lon($label)".toUri(),
        )
        return launchSafely(context, intent)
    }

    fun openDialer(context: Context, phoneNumber: String): Boolean {
        val intent = Intent(
            Intent.ACTION_DIAL,
            Uri.fromParts("tel", phoneNumber, null),
        )
        return launchSafely(context, intent)
    }

    /** Apre nel browser un sito o un file messo dal locale (solo indirizzi http/https). */
    fun openWebPage(context: Context, url: String): Boolean {
        val uri = url.trim().toUri()
        if (uri.scheme !in setOf("http", "https")) return false
        return launchSafely(context, Intent(Intent.ACTION_VIEW, uri))
    }

    fun openAppSettings(context: Context): Boolean {
        val intent = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.fromParts("package", context.packageName, null),
        )
        return launchSafely(context, intent)
    }

    private fun launchSafely(context: Context, intent: Intent): Boolean = try {
        context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        true
    } catch (_: ActivityNotFoundException) {
        false
    }
}
