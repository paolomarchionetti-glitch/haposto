package com.haposto.data.reservations

import java.time.LocalDate
import kotlinx.serialization.Serializable

/**
 * Prenotazione di sala — modulo locale, lato ristoratore (STEP 7.7).
 *
 * È un blocco note personale: nessun dato lascia il dispositivo, nessun legame
 * col contratto V1 o con Supabase. `time` è testo ("20:30"; nelle versioni vecchie anche "9")
 * e il riordino usa un parse tollerante. `date` è il giorno in formato ISO ("2026-10-02"):
 * le prenotazioni salvate prima che esistesse non ce l'hanno e valgono per il giorno in cui
 * l'app le ritrova (vedi [ReservationList.withDates]).
 */
@Serializable
data class Reservation(
    val id: String,
    val name: String,
    val time: String,
    val partySize: Int,
    val table: String? = null,
    val date: String? = null,
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

    val localDate: LocalDate? get() = date?.let { runCatching { LocalDate.parse(it) }.getOrNull() }
}

/** Regole della lista: giorno di ogni prenotazione, pulizia dei giorni passati, ordine. */
object ReservationList {

    /** Le prenotazioni senza giorno (versioni precedenti dell'app) valgono per [today]. */
    fun withDates(items: List<Reservation>, today: LocalDate): List<Reservation> =
        items.map { if (it.localDate == null) it.copy(date = today.toString()) else it }

    /** Via le prenotazioni dei giorni passati: nel blocco note restano solo oggi e i giorni futuri. */
    fun upcoming(items: List<Reservation>, today: LocalDate): List<Reservation> =
        withDates(items, today).filter { !it.localDate!!.isBefore(today) }

    fun sorted(items: List<Reservation>): List<Reservation> =
        items.sortedWith(compareBy<Reservation> { it.localDate ?: LocalDate.MAX }.thenBy { it.sortKey })

    fun forDay(items: List<Reservation>, day: LocalDate): List<Reservation> =
        sorted(items.filter { it.localDate == day })
}
