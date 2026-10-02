package com.haposto.data.restaurant

import android.content.Context

/** Ultime note salvate nelle preferenze dell'app, una lista per locale (solo su questo telefono). */
class SharedPrefsRecentNotesStore(context: Context, restaurantId: String) : RecentNotesStore {

    private val prefs = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    private val key = "notes_" + restaurantId.replace(Regex("[^A-Za-z0-9_-]"), "_")

    override fun load(): List<String> =
        prefs.getString(key, null)?.split(SEPARATOR)?.filter { it.isNotBlank() }.orEmpty()

    override fun save(notes: List<String>) {
        prefs.edit().putString(key, notes.joinToString(SEPARATOR)).apply()
    }

    private companion object {
        const val PREFS = "recent_notes"
        const val SEPARATOR = "\u001F"
    }
}
