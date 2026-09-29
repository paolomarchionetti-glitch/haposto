package com.haposto.domain.model

import java.time.DayOfWeek
import java.time.LocalTime

/** Una fascia di apertura; [close] prima di [open] vuol dire "dopo mezzanotte" (es. 19:00–01:00). */
data class TimeRange(val open: LocalTime, val close: LocalTime) {
    init {
        require(open != close) { "Apertura e chiusura non possono coincidere." }
    }

    fun label(): String = "${open.hhmm()}–${close.hhmm()}"
}

/**
 * Orari settimanali del locale. Formato sul server (colonna restaurants.opening_hours):
 * {"mon": [["12:00","14:30"],["19:00","23:30"]], "tue": [], ...}; giorno assente = non indicato.
 */
data class OpeningHours(val days: Map<DayOfWeek, List<TimeRange>>) {

    init {
        require(days.values.all { it.size <= MAX_RANGES_PER_DAY }) { "Al massimo $MAX_RANGES_PER_DAY fasce al giorno." }
    }

    fun rangesFor(day: DayOfWeek): List<TimeRange> = days[day].orEmpty()

    /** Il locale è aperto in quell'istante (considerando le fasce che passano la mezzanotte)? */
    fun isOpen(day: DayOfWeek, time: LocalTime): Boolean {
        val today = rangesFor(day).any { range ->
            if (range.close > range.open) time >= range.open && time < range.close
            else time >= range.open
        }
        val fromYesterday = rangesFor(day.minus(1)).any { range ->
            range.close < range.open && time < range.close
        }
        return today || fromYesterday
    }

    /** Righe leggibili, es. "Mar 12:00–14:30 · 19:00–23:30"; i giorni senza fasce sono "chiuso". */
    fun describe(): List<String> = DayOfWeek.entries.map { day ->
        val ranges = days[day]
        val text = when {
            ranges == null -> "—"
            ranges.isEmpty() -> "chiuso"
            else -> ranges.joinToString(" · ") { it.label() }
        }
        "${ITALIAN_SHORT.getValue(day)} $text"
    }

    /** Mappa pronta per il JSON del server. */
    fun toServerMap(): Map<String, List<List<String>>> = days.entries
        .sortedBy { it.key.value }
        .associate { (day, ranges) ->
            SERVER_KEYS.getValue(day) to ranges.map { listOf(it.open.hhmm(), it.close.hhmm()) }
        }

    val isEmpty: Boolean get() = days.isEmpty()

    companion object {
        const val MAX_RANGES_PER_DAY = 3

        val SERVER_KEYS: Map<DayOfWeek, String> = mapOf(
            DayOfWeek.MONDAY to "mon",
            DayOfWeek.TUESDAY to "tue",
            DayOfWeek.WEDNESDAY to "wed",
            DayOfWeek.THURSDAY to "thu",
            DayOfWeek.FRIDAY to "fri",
            DayOfWeek.SATURDAY to "sat",
            DayOfWeek.SUNDAY to "sun",
        )

        val ITALIAN_SHORT: Map<DayOfWeek, String> = mapOf(
            DayOfWeek.MONDAY to "Lun",
            DayOfWeek.TUESDAY to "Mar",
            DayOfWeek.WEDNESDAY to "Mer",
            DayOfWeek.THURSDAY to "Gio",
            DayOfWeek.FRIDAY to "Ven",
            DayOfWeek.SATURDAY to "Sab",
            DayOfWeek.SUNDAY to "Dom",
        )

        /** Legge la forma del server; restituisce null se il formato non è valido. */
        fun fromServerMap(raw: Map<String, List<List<String>>>): OpeningHours? = runCatching {
            val byKey = SERVER_KEYS.entries.associate { (day, key) -> key to day }
            OpeningHours(
                raw.entries.associate { (key, ranges) ->
                    val day = byKey[key] ?: error("giorno sconosciuto $key")
                    day to ranges.map { pair ->
                        require(pair.size == 2)
                        TimeRange(parseTime(pair[0]), parseTime(pair[1]))
                    }
                },
            )
        }.getOrNull()

        /** Accetta "19", "19:30", "19.30", "1930". */
        fun parseTime(text: String): LocalTime {
            val digits = text.trim().replace('.', ':')
            val (h, m) = when {
                digits.contains(':') -> digits.substringBefore(':') to digits.substringAfter(':')
                digits.length <= 2 -> digits to "0"
                digits.length == 4 -> digits.take(2) to digits.takeLast(2)
                else -> error("orario non valido: $text")
            }
            return LocalTime.of(h.toInt(), m.toInt())
        }
    }
}

private fun LocalTime.hhmm(): String = "%02d:%02d".format(hour, minute)
