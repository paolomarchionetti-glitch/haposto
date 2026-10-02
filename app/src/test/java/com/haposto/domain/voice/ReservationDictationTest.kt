package com.haposto.domain.voice

import com.haposto.domain.model.OpeningHours
import com.haposto.domain.model.TimeRange
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.LocalTime
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class ReservationDictationTest {

    /** Giovedì. */
    private val today = LocalDate.of(2026, 10, 1)

    private fun parse(text: String, hours: OpeningHours? = null) = ReservationDictation.parse(text, today, hours)

    @Test
    fun oneSentence_fillsEveryField() {
        val draft = parse("Rossi, quattro, alle venti e trenta, tavolo dodici")
        assertEquals("Rossi", draft.name)
        assertEquals(4, draft.partySize)
        assertEquals(LocalTime.of(20, 30), draft.time)
        assertEquals("12", draft.table)
        assertNull(draft.date)
    }

    @Test
    fun bookingWords_dayAndPeople() {
        val draft = parse("prenotazione a nome mario bianchi per 6 persone domani alle 8")
        assertEquals("Mario Bianchi", draft.name)
        assertEquals(6, draft.partySize)
        assertEquals(LocalTime.of(20, 0), draft.time)
        assertEquals(today.plusDays(1), draft.date)
    }

    @Test
    fun digitsAsTheRecognizerWritesThem() {
        val draft = parse("Verdi 2 persone alle 13:15 tavolo 7")
        assertEquals("Verdi", draft.name)
        assertEquals(2, draft.partySize)
        assertEquals(LocalTime.of(13, 15), draft.time)
        assertEquals("7", draft.table)
    }

    @Test
    fun tableForPeople_isTheNumberOfPeople() {
        val draft = parse("Esposito tavolo da 4 alle 21.30")
        assertEquals("Esposito", draft.name)
        assertEquals(4, draft.partySize)
        assertNull(draft.table)
        assertEquals(LocalTime.of(21, 30), draft.time)
    }

    @Test
    fun lunchAndOneOClock() {
        val draft = parse("Ferrari in 3 all'una a pranzo")
        assertEquals("Ferrari", draft.name)
        assertEquals(3, draft.partySize)
        assertEquals(LocalTime.of(13, 0), draft.time)
    }

    @Test
    fun weekdayAndHalfPast() {
        val draft = parse("Russo 5 alle otto e mezza sabato")
        assertEquals("Russo", draft.name)
        assertEquals(5, draft.partySize)
        assertEquals(LocalTime.of(20, 30), draft.time)
        assertEquals(LocalDate.of(2026, 10, 3), draft.date)
    }

    @Test
    fun quarterTo() {
        val draft = parse("Gallo per due persone alle nove meno un quarto")
        assertEquals("Gallo", draft.name)
        assertEquals(2, draft.partySize)
        assertEquals(LocalTime.of(20, 45), draft.time)
    }

    @Test
    fun tonight_withTableFirst() {
        val draft = parse("stasera alle 9 Colombo tavolo 7 per 4")
        assertEquals("Colombo", draft.name)
        assertEquals(LocalTime.of(21, 0), draft.time)
        assertEquals("7", draft.table)
        assertEquals(4, draft.partySize)
        assertEquals(today, draft.date)
    }

    @Test
    fun surnamesWithParticlesAreKept() {
        val draft = parse("di maio 4 persone alle 20")
        assertEquals("Di Maio", draft.name)
        assertEquals(4, draft.partySize)
        assertEquals(LocalTime.of(20, 0), draft.time)
    }

    @Test
    fun adultsAndChildrenAreAdded() {
        val draft = parse("4 adulti e 2 bambini alle 20 Bruno")
        assertEquals(6, draft.partySize)
        assertEquals("Bruno", draft.name)
    }

    @Test
    fun nameOnly() {
        val draft = parse("Mario Rossi")
        assertEquals("Mario Rossi", draft.name)
        assertNull(draft.time)
        assertNull(draft.partySize)
        assertNull(draft.table)
    }

    @Test
    fun noon() {
        assertEquals(LocalTime.of(12, 30), parse("Conti a mezzogiorno e mezza").time)
    }

    @Test
    fun openingHoursDecideMorningOrEvening() {
        val lunchOnly = OpeningHours(mapOf(DayOfWeek.THURSDAY to listOf(TimeRange(LocalTime.of(11, 0), LocalTime.of(15, 0)))))
        assertEquals(LocalTime.of(11, 0), parse("Neri alle 11", lunchOnly).time)
        val bothServices = OpeningHours(
            mapOf(
                DayOfWeek.THURSDAY to listOf(
                    TimeRange(LocalTime.of(12, 0), LocalTime.of(15, 0)),
                    TimeRange(LocalTime.of(19, 0), LocalTime.of(23, 30)),
                ),
            ),
        )
        assertEquals(LocalTime.of(13, 0), parse("Neri alle 1", bothServices).time)
        assertEquals(LocalTime.of(19, 30), parse("Neri alle 7 e mezza", bothServices).time)
        assertEquals(LocalTime.of(11, 0), parse("Neri alle 11").time)
    }

    @Test
    fun timeWithPreposition_isNotTakenForPeople() {
        val first = parse("Marino alle 20 in 4")
        assertEquals(LocalTime.of(20, 0), first.time)
        assertEquals(4, first.partySize)
        val second = parse("Fontana per le 21 e 15 per 3")
        assertEquals("Fontana", second.name)
        assertEquals(LocalTime.of(21, 15), second.time)
        assertEquals(3, second.partySize)
    }

    @Test
    fun outdoorTable() {
        assertEquals("Fuori", parse("Lombardi tavolo fuori alle 20").table)
    }

    @Test
    fun emptyText() {
        assertTrue(parse("   ").isEmpty)
    }
}
