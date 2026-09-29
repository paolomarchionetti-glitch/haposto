package com.haposto.domain

import com.haposto.domain.model.OpeningHours
import com.haposto.domain.model.TimeRange
import java.time.DayOfWeek
import java.time.LocalTime
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class OpeningHoursTest {

    private val hours = OpeningHours(
        mapOf(
            DayOfWeek.MONDAY to emptyList(),
            DayOfWeek.FRIDAY to listOf(
                TimeRange(LocalTime.of(12, 0), LocalTime.of(14, 30)),
                TimeRange(LocalTime.of(19, 0), LocalTime.of(1, 0)),
            ),
        ),
    )

    @Test
    fun rangesAcrossMidnightStayOpenTheNextMorning() {
        assertTrue(hours.isOpen(DayOfWeek.FRIDAY, LocalTime.of(13, 0)))
        assertFalse(hours.isOpen(DayOfWeek.FRIDAY, LocalTime.of(16, 0)))
        assertTrue(hours.isOpen(DayOfWeek.FRIDAY, LocalTime.of(23, 30)))
        assertTrue(hours.isOpen(DayOfWeek.SATURDAY, LocalTime.of(0, 30)))
        assertFalse(hours.isOpen(DayOfWeek.SATURDAY, LocalTime.of(1, 0)))
        assertFalse(hours.isOpen(DayOfWeek.MONDAY, LocalTime.of(13, 0)))
    }

    @Test
    fun describeDistinguishesClosedFromNotIndicated() {
        val lines = hours.describe()
        assertEquals(7, lines.size)
        assertEquals("Lun chiuso", lines[0])
        assertEquals("Mar —", lines[1])
        assertEquals("Ven 12:00–14:30 · 19:00–01:00", lines[4])
    }

    @Test
    fun serverFormatRoundTrips() {
        val server = hours.toServerMap()
        assertEquals(listOf("mon", "fri"), server.keys.toList())
        assertEquals(listOf(listOf("12:00", "14:30"), listOf("19:00", "01:00")), server["fri"])
        assertEquals(hours, OpeningHours.fromServerMap(server))
    }

    @Test
    fun invalidServerDataIsRejectedInsteadOfCrashing() {
        assertNull(OpeningHours.fromServerMap(mapOf("xyz" to listOf(listOf("12:00", "14:00")))))
        assertNull(OpeningHours.fromServerMap(mapOf("mon" to listOf(listOf("12:00")))))
        assertNull(OpeningHours.fromServerMap(mapOf("mon" to listOf(listOf("12:00", "12:00")))))
        assertNull(OpeningHours.fromServerMap(mapOf("mon" to listOf(listOf("25:00", "26:00")))))
        val tooMany = List(OpeningHours.MAX_RANGES_PER_DAY + 1) { listOf("0$it:00", "0$it:30") }
        assertNull(OpeningHours.fromServerMap(mapOf("mon" to tooMany)))
    }

    @Test
    fun parseTimeAcceptsCommonWritings() {
        assertEquals(LocalTime.of(19, 0), OpeningHours.parseTime("19"))
        assertEquals(LocalTime.of(19, 30), OpeningHours.parseTime("19:30"))
        assertEquals(LocalTime.of(19, 30), OpeningHours.parseTime("19.30"))
        assertEquals(LocalTime.of(19, 30), OpeningHours.parseTime(" 1930 "))
    }
}
