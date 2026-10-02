package com.haposto.domain.voice

import com.haposto.domain.model.OpeningHours
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.LocalTime
import java.time.temporal.TemporalAdjusters

/** Prenotazione capita da una frase; null = la frase non ne parla (il campo resta com'è). */
data class ReservationDraft(
    val name: String? = null,
    val time: LocalTime? = null,
    val partySize: Int? = null,
    val table: String? = null,
    val date: LocalDate? = null,
) {
    val isEmpty: Boolean get() = name == null && time == null && partySize == null && table == null && date == null
}

/**
 * "Rossi, quattro, alle venti e trenta, tavolo dodici" → nome Rossi, 4 persone, 20:30, tavolo 12.
 * Capisce anche "domani", "sabato", "a pranzo", "alle otto e mezza", "tavolo da 6", "4 adulti e 2
 * bambini". "Alle 8" diventa 20:00 se il locale a quell'ora è aperto la sera (orari del locale o,
 * se mancano, regola semplice: da 1 a 10 è pomeriggio/sera). Tutto avviene sul telefono.
 */
object ReservationDictation {

    const val MAX_PARTY = 99

    private val N = "(${ItalianNumbers.PATTERN})"
    private val OPTIONS = setOf(RegexOption.IGNORE_CASE)
    private val MINUTES = "(mezza|mezzo|un\\s+quarto|quarto|tre\\s+quarti|${ItalianNumbers.PATTERN})"

    private val DAY = Regex(
        "$WORD_START(oggi|stasera|stamattina|stamani|domani|dopodomani|" +
            "luned[iì]|marted[iì]|mercoled[iì]|gioved[iì]|venerd[iì]|sabato|domenica)$WORD_END",
        OPTIONS,
    )
    private val MOMENT = Regex("$WORD_START(?:a\\s+|per\\s+|di\\s+)?(pranzo|cena|sera|pomeriggio|mattina)$WORD_END", OPTIONS)
    private val NOON = Regex("$WORD_START(?:a\\s+)?mezzogiorno(?:\\s+e\\s+$MINUTES)?$WORD_END", OPTIONS)
    private val TIME_DIGITS = Regex(
        "$WORD_START(?:(?:alle|ore|per\\s+le|verso\\s+le|dalle)\\s+)?(\\d{1,2})\\s*[:.]\\s*(\\d{2})$WORD_END",
        OPTIONS,
    )
    private val TIME_WORDS = Regex(
        "$WORD_START(?:alle|ore|per\\s+le|verso\\s+le|all')\\s*$N(?:\\s+e\\s+$MINUTES)?" +
            "(?:\\s+meno\\s+(un\\s+quarto|quarto|${ItalianNumbers.PATTERN}))?$WORD_END",
        OPTIONS,
    )
    private val TIME_BARE = Regex("$WORD_START$N\\s+e\\s+$MINUTES$WORD_END", OPTIONS)
    private val PEOPLE = Regex(
        "$WORD_START$N\\s+(?:persone|persona|pax|coperti|coperto|posti|ospiti|adulti|adulto|bambini|bambino)$WORD_END",
        OPTIONS,
    )
    private val PEOPLE_AFTER_WORD = Regex(
        "$WORD_START(?:tavolo\\s+(?:da|per)|siamo\\s+in|saremo\\s+in|in|per)\\s+$N$WORD_END(?!\\s*[:.]\\s*\\d)(?!\\s+e\\s)",
        OPTIONS,
    )
    private val TABLE = Regex(
        "${WORD_START}tavolo\\s+(?:numero\\s+|n\\.?\\s*)?(\\d{1,3}[a-z]?|${ItalianNumbers.PATTERN}|" +
            "fuori|esterno|interno|dentro|dehors|veranda|giardino|terrazza|bancone|sala)$WORD_END",
        OPTIONS,
    )
    private val LONE_NUMBER = Regex("$WORD_START(${ItalianNumbers.PATTERN_FROM_TWO})$WORD_END", OPTIONS)
    private val BOOKING_WORDS = Regex(
        "$WORD_START(?:(?:a|al)\\s+nome(?:\\s+di)?|prenotazione|prenota|prenotare|segna|aggiungi|" +
            "signora|signor|sig\\.ra|sig\\.)$WORD_END",
        OPTIONS,
    )

    private val NAME_START = setOf("per", "e", "ed", "alle", "ore", "con", "a", "al", "da", "in", "il", "la", "lo", "le", "i", "nome")
    private val NAME_END = setOf(
        "per", "e", "ed", "alle", "ore", "con", "a", "al", "da", "in", "di", "del", "della",
        "il", "la", "lo", "le", "i", "tavolo", "persone", "verso",
    )

    /**
     * [today] serve per "domani", "sabato"...; [selectedDay] è il giorno scelto nella schermata, usato
     * per capire se "alle 8" è mattina o sera quando la frase non nomina un giorno.
     */
    fun parse(
        text: String,
        today: LocalDate,
        hours: OpeningHours? = null,
        selectedDay: LocalDate = today,
    ): ReservationDraft {
        val dictated = DictationText(text)

        var date: LocalDate? = null
        var moment: Moment? = null
        dictated.take(DAY) { match ->
            val word = match.groupValues[1].lowercase()
            date = dateFor(word, today)
            if (word == "stasera") moment = Moment.EVENING
            if (word == "stamattina" || word == "stamani") moment = Moment.MORNING
            true
        }
        dictated.takeAll(MOMENT) { match ->
            moment = when (match.groupValues[1].lowercase()) {
                "pranzo" -> Moment.LUNCH
                "mattina" -> Moment.MORNING
                else -> Moment.EVENING
            }
            true
        }

        val day = (date ?: selectedDay).dayOfWeek
        var time: LocalTime? = null
        fun accept(hour: Int?, minute: Int?, ambiguous: Boolean = true): Boolean {
            if (hour == null || minute == null || hour !in 0..23 || minute !in 0..59) return false
            val resolved = if (ambiguous) resolveHour(hour, minute, moment, day, hours) else hour
            time = LocalTime.of(resolved, minute)
            return true
        }
        dictated.take(NOON) { match -> accept(12, minutesOf(match.groupValues[1]), ambiguous = false) } ||
            dictated.take(TIME_DIGITS) { match ->
                accept(match.groupValues[1].toIntOrNull(), match.groupValues[2].toIntOrNull())
            } ||
            dictated.take(TIME_WORDS) { match -> acceptWords(match, ::accept) } ||
            dictated.take(TIME_BARE) { match -> acceptWords(match, ::accept) }

        var people = 0
        dictated.takeAll(PEOPLE) { match ->
            val count = ItalianNumbers.parse(match.groupValues[1])
            if (count != null && count in 1..MAX_PARTY) people += count
            count != null
        }
        if (people == 0) {
            dictated.take(PEOPLE_AFTER_WORD) { match ->
                ItalianNumbers.parse(match.groupValues[1])?.takeIf { it in 1..MAX_PARTY }?.also { people = it } != null
            }
        }

        var table: String? = null
        dictated.take(TABLE) { match ->
            val raw = match.groupValues[1]
            table = ItalianNumbers.parse(raw)?.toString() ?: raw.lowercase().capitalizedFirst()
            true
        }

        if (people == 0) {
            dictated.take(LONE_NUMBER) { match ->
                ItalianNumbers.parse(match.groupValues[1])?.takeIf { it in 1..50 }?.also { people = it } != null
            }
        }

        dictated.takeAll(BOOKING_WORDS) { true }
        val name = dictated.leftoverSegments()
            .map { it.trimWords(NAME_START, NAME_END) }
            .firstOrNull { segment -> segment.any(Char::isLetter) }
            ?.split(' ')
            ?.joinToString(" ") { it.capitalizedFirst() }
            ?.limitTo(MAX_NAME_LENGTH)

        return ReservationDraft(
            name = name,
            time = time,
            partySize = people.takeIf { it > 0 },
            table = table,
            date = date,
        )
    }

    private const val MAX_NAME_LENGTH = 80

    private enum class Moment { MORNING, LUNCH, EVENING }

    /** "alle otto e mezza", "alle nove meno un quarto", "venti e trenta". */
    private fun acceptWords(match: MatchResult, accept: (Int?, Int?, Boolean) -> Boolean): Boolean {
        val hour = ItalianNumbers.parse(match.groupValues[1]) ?: return false
        val after = match.groupValues[2]
        val before = match.groupValues.getOrNull(3).orEmpty()
        return if (before.isNotEmpty()) {
            val minus = minutesOf(before) ?: return false
            if (minus !in 1..59) return false
            accept((hour + 23) % 24, 60 - minus, true)
        } else {
            accept(hour, if (after.isEmpty()) 0 else minutesOf(after), true)
        }
    }

    private fun minutesOf(words: String): Int? {
        val text = words.trim().lowercase().replace(Regex("\\s+"), " ")
        return when (text) {
            "" -> 0
            "mezza", "mezzo" -> 30
            "un quarto", "quarto" -> 15
            "tre quarti" -> 45
            else -> ItalianNumbers.parse(text)
        }
    }

    private fun resolveHour(hour: Int, minute: Int, moment: Moment?, day: DayOfWeek, hours: OpeningHours?): Int {
        if (hour == 0 || hour >= 12) return hour
        when (moment) {
            Moment.EVENING -> return hour + 12
            Moment.LUNCH -> return if (hour <= 4) hour + 12 else hour
            Moment.MORNING -> return hour
            null -> Unit
        }
        if (hours != null) {
            val morningOpen = hours.isOpen(day, LocalTime.of(hour, minute))
            val afternoonOpen = hours.isOpen(day, LocalTime.of(hour + 12, minute))
            if (afternoonOpen && !morningOpen) return hour + 12
            if (morningOpen && !afternoonOpen) return hour
        }
        return if (hour <= 10) hour + 12 else hour
    }

    private fun dateFor(word: String, today: LocalDate): LocalDate = when (word) {
        "oggi", "stasera", "stamattina", "stamani" -> today
        "domani" -> today.plusDays(1)
        "dopodomani" -> today.plusDays(2)
        else -> today.with(TemporalAdjusters.nextOrSame(WEEKDAYS.getValue(word.replace('ì', 'i'))))
    }

    private val WEEKDAYS = mapOf(
        "lunedi" to DayOfWeek.MONDAY,
        "martedi" to DayOfWeek.TUESDAY,
        "mercoledi" to DayOfWeek.WEDNESDAY,
        "giovedi" to DayOfWeek.THURSDAY,
        "venerdi" to DayOfWeek.FRIDAY,
        "sabato" to DayOfWeek.SATURDAY,
        "domenica" to DayOfWeek.SUNDAY,
    )
}
