package com.haposto.data.favorites

import android.content.Context
import androidx.core.content.edit
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.updateAndGet

/**
 * Preferiti salvati solo su questo telefono: gratuiti, senza account.
 * Con un account (Step 8) si potranno sincronizzare tra dispositivi; gli avvisi
 * "c'è posto" per i preferiti sono una funzione Plus (vedi supabase/migrations/0009).
 */
class FavoritesStore(context: Context) {

    private val prefs = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    private val _ids = MutableStateFlow(prefs.getStringSet(KEY_IDS, emptySet()).orEmpty().toSet())

    val ids: StateFlow<Set<String>> = _ids.asStateFlow()

    fun toggle(restaurantId: String) {
        val next = _ids.updateAndGet { current ->
            if (restaurantId in current) current - restaurantId else current + restaurantId
        }
        prefs.edit { putStringSet(KEY_IDS, next) }
    }

    private companion object {
        const val PREFS = "haposto_favorites"
        const val KEY_IDS = "restaurant_ids"
    }
}
