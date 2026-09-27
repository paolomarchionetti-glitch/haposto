package com.haposto.data.reservations

import android.content.Context
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.io.File

/**
 * Persistenza locale delle prenotazioni, per singolo ristorante.
 * Salva un file JSON nella storage interna dell'app: i dati non lasciano il
 * dispositivo. Usa kotlinx.serialization, già presente nel progetto (zero
 * dipendenze nuove).
 */
class ReservationStore(
    context: Context,
    restaurantId: String,
) {
    private val appContext = context.applicationContext
    private val file = File(appContext.filesDir, "reservations_${sanitize(restaurantId)}.json")
    private val json = Json { ignoreUnknownKeys = true }

    fun load(): List<Reservation> = try {
        if (file.exists()) {
            json.decodeFromString<List<Reservation>>(file.readText())
        } else {
            emptyList()
        }
    } catch (e: Exception) {
        emptyList()
    }

    fun save(items: List<Reservation>) {
        try {
            file.writeText(json.encodeToString(items))
        } catch (e: Exception) {
            // Blocco note best-effort: un errore di scrittura non deve far crashare l'app.
        }
    }

    private fun sanitize(id: String): String =
        id.ifBlank { "default" }.replace(Regex("[^A-Za-z0-9_-]"), "_")
}
