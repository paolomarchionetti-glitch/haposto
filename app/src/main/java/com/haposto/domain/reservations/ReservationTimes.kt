package com.haposto.domain.reservations

import com.haposto.domain.model.OpeningHours
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime

/** Orari delle prenotazioni di sala: digitazione veloce e orari proposti a un tocco. */
object ReservationTimes {

    /** Fasce usate quando il locale non ha indicato gli orari di quel giorno. */
    private val DEFAULT_RANGES = listOf(LocalTime.of(12, 0) to LocalTime.of(14, 30), LocalTime.of(19, 0) to LocalTime.of(23, 0))

    /**
     * Cifre digitate → testo con i due punti messi da soli: "2" → "2", "20" → "20", "203" → "20:3",
     * "2030" → "20:30", "930" → "9:30" (93 non è un'ora). Ogni carattere che non è una cifra si ignora.
     */
    fun formatTyped(input: String): String {
        val digits = input.filter(Char::isDigit).take(4)
        return when {
            digits.length <= 2 -> digits
            digits.length == 3 && digits.take(2).toInt() > 23 -> "${digits[0]}:${digits.drop(1)}"
            else -> "${digits.take(2)}:${digits.drop(2)}"
        }
    }

    /**
     * Orario completo "HH:MM", o null se il testo non è un orario: "20" → "20:00", "20:3" → "20:30",
     * "9:30" → "09:30", "21.15" → "21:15".
     */
    fun normalize(text: String): String? {
        val clean = text.trim().replace('.', ':')
        if (clean.isEmpty()) return null
        val typed = when {
            ':' in clean -> clean
            clean.length <= 4 && clean.all(Char::isDigit) -> formatTyped(clean)
            else -> return null
        }
        val hourText = typed.substringBefore(':')
        val minuteText = if (':' in typed) typed.substringAfter(':') else ""
        val hour = hourText.toIntOrNull() ?: return null
        val minute = when (minuteText.length) {
            0 -> 0
            1 -> minuteText.toIntOrNull()?.times(10) ?: return null
            2 -> minuteText.toIntOrNull() ?: return null
            else -> return null
        }
        if (hour !in 0..23 || minute !in 0..59) return null
        return format(LocalTime.of(hour, minute))
    }

    fun format(time: LocalTime): String = "%02d:%02d".format(time.hour, time.minute)

    /**
     * Orari proposti per [date], ogni [stepMinutes] minuti, dentro le fasce di apertura del locale
     * (fino a mezz'ora prima della chiusura). Senza orari indicati: 12:00–14:30 e 19:00–23:00. Un
     * giorno di chiusura non ha orari. Per oggi ([now] nello stesso giorno) si parte da adesso.
     */
    fun slots(
        hours: OpeningHours?,
        date: LocalDate,
        now: LocalDateTime? = null,
        stepMinutes: Int = 30,
    ): List<LocalTime> {
        val dayRanges = hours?.days?.get(date.dayOfWeek)
        val ranges = when {
            dayRanges == null -> DEFAULT_RANGES
            else -> dayRanges.map { it.open to it.close }
        }
        val earliest = if (now != null && now.toLocalDate() == date) {
            now.hour * 60 + now.minute - 15
        } else {
            Int.MIN_VALUE
        }
        return ranges.flatMap { (open, close) ->
            val start = open.hour * 60 + open.minute
            var end = close.hour * 60 + close.minute
            if (end <= start) end += 24 * 60
            val first = ((start + stepMinutes - 1) / stepMinutes) * stepMinutes
            (first..end - 30 step stepMinutes)
                .filter { it >= earliest }
                .map { minutes -> LocalTime.of((minutes / 60) % 24, minutes % 60) }
        }.distinct()
    }
}
