package com.haposto.data.reservations

import android.content.Context
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.io.File

/**
 * Persistenza locale delle prenotazioni, per singolo ristorante.
 * Salva un file JSON nella storage interna dell'app: i dati non lasciano il
 * dispositivo (la cartella `reservations/` è esclusa dal backup cloud, vedi
 * res/xml/data_extraction_rules.xml e backup_rules.xml). Usa kotlinx.serialization.
 */
class ReservationStore(
    context: Context,
    restaurantId: String,
) {
    private val appContext = context.applicationContext
    private val fileName = "reservations_${sanitize(restaurantId)}.json"
    private val directory = File(appContext.filesDir, DIRECTORY)
    private val file = File(directory, fileName)

    /** File scritto dalle build 7.7/7.8 direttamente in filesDir, prima della cartella dedicata. */
    private val legacyFile = File(appContext.filesDir, fileName)

    private val json = Json { ignoreUnknownKeys = true }

    fun load(): List<Reservation> = try {
        migrateLegacyFile()
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
            directory.mkdirs()
            file.writeText(json.encodeToString(items))
        } catch (e: Exception) {
            // Blocco note best-effort: un errore di scrittura non deve far crashare l'app.
        }
    }

    private fun migrateLegacyFile() {
        if (!file.exists() && legacyFile.exists()) {
            directory.mkdirs()
            if (!legacyFile.renameTo(file)) {
                legacyFile.copyTo(file, overwrite = false)
                legacyFile.delete()
            }
        }
    }

    private fun sanitize(id: String): String =
        id.ifBlank { "default" }.replace(Regex("[^A-Za-z0-9_-]"), "_")

    private companion object {
        const val DIRECTORY = "reservations"
    }
}
