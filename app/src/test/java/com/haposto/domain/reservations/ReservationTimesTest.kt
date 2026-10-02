package com.haposto.domain.reservations

import com.haposto.domain.model.OpeningHours
import com.haposto.domain.model.TimeRange
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class ReservationTimesTest {

    @Test
    fun typedDigitsGetTheColonByThemselves() {
        assertEquals("2", ReservationTimes.formatTyped("2"))
        assertEquals("20", ReservationTimes.formatTyped("20"))
        assertEquals("20:3", ReservationTimes.formatTyped("203"))
        assertEquals("20:30", ReservationTimes.formatTyped("2030"))
        assertEquals("9:30", ReservationTimes.formatTyped("930"))
        assertEquals("20:30", ReservationTimes.formatTyped("20:30"))
        assertEquals("20:30", ReservationTimes.formatTyped("20305"))
    }

    @Test
    fun normalize_completesTheTime() {
        assertEquals("20:00", ReservationTimes.normalize("20"))
        assertEquals("20:30", ReservationTimes.normalize("20:3"))
        assertEquals("20:30", ReservationTimes.normalize("2030"))
        assertEquals("09:30", ReservationTimes.normalize("9:30"))
        assertEquals("21:15", ReservationTimes.normalize("21.15"))
        assertEquals("09:30", ReservationTimes.normalize("930"))
        assertNull(ReservationTimes.normalize(""))
        assertNull(ReservationTimes.normalize("sera"))
        assertNull(ReservationTimes.normalize("25:00"))
        assertNull(ReservationTimes.normalize("20:75"))
    }

    @Test
    fun slotsFollowTheOpeningHours_untilHalfAnHourBeforeClosing() {
        val friday = LocalDate.of(2026, 10, 2)
        val hours = OpeningHours(
            mapOf(
                DayOfWeek.FRIDAY to listOf(
                    TimeRange(LocalTime.of(12, 0), LocalTime.of(14, 0)),
                    TimeRange(LocalTime.of(19, 15), LocalTime.of(0, 30)),
                ),
                DayOfWeek.MONDAY to emptyList(),
            ),
        )
        val labels = ReservationTimes.slots(hours, friday).map(ReservationTimes::format)
        assertEquals(
            listOf("12:00", "12:30", "13:00", "13:30", "19:30", "20:00", "20:30", "21:00", "21:30", "22:00", "22:30", "23:00", "23:30", "00:00"),
            labels,
        )
        assertTrue(ReservationTimes.slots(hours, LocalDate.of(2026, 10, 5)).isEmpty())
    }

    @Test
    fun withoutHours_lunchAndDinnerAreProposed() {
        val labels = ReservationTimes.slots(null, LocalDate.of(2026, 10, 2)).map(ReservationTimes::format)
        assertEquals("12:00", labels.first())
        assertEquals("14:00", labels[4])
        assertEquals("19:00", labels[5])
        assertEquals("22:30", labels.last())
    }

    @Test
    fun today_startsFromNow() {
        val date = LocalDate.of(2026, 10, 2)
        val labels = ReservationTimes.slots(null, date, now = LocalDateTime.of(date, LocalTime.of(20, 10)))
            .map(ReservationTimes::format)
        assertEquals("20:00", labels.first())
        val tomorrow = ReservationTimes.slots(null, date.plusDays(1), now = LocalDateTime.of(date, LocalTime.of(20, 10)))
        assertEquals(LocalTime.of(12, 0), tomorrow.first())
    }
}
