package com.haposto.data.reservations

import kotlinx.serialization.Serializable

/**
 * Prenotazione di sala — modulo locale, lato ristoratore (STEP 7.7).
 *
 * È un blocco note personale: nessun dato lascia il dispositivo, nessun legame
 * col contratto V1 o con Supabase. `time` è testo libero ("20:30", "9") per
 * essere veloce da dettare/scrivere; il riordino usa un parse tollerante.
 */
@Serializable
data class Reservation(
    val id: String,
    val name: String,
    val time: String,
    val partySize: Int,
    val table: String? = null,
) {
    /** Minuti dalla mezzanotte per l'ordinamento; Int.MAX_VALUE se non interpretabile. */
    val sortKey: Int
        get() {
            val t = time.trim().replace('.', ':')
            val parts = t.split(":")
            val h = parts.getOrNull(0)?.filter { it.isDigit() }?.toIntOrNull() ?: return Int.MAX_VALUE
            val m = parts.getOrNull(1)?.filter { it.isDigit() }?.toIntOrNull() ?: 0
            if (h !in 0..23 || m !in 0..59) return Int.MAX_VALUE
            return h * 60 + m
        }
}
