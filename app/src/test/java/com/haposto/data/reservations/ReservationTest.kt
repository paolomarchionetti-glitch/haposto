package com.haposto.data.reservations

import org.junit.Assert.assertEquals
import org.junit.Test

class ReservationTest {

    private fun at(time: String) = Reservation(id = time, name = "Test", time = time, partySize = 2)

    @Test
    fun sortKey_acceptsCommonTimeFormats() {
        assertEquals(20 * 60 + 30, at("20:30").sortKey)
        assertEquals(20 * 60 + 30, at("20.30").sortKey)
        assertEquals(9 * 60, at("9").sortKey)
        assertEquals(21 * 60 + 5, at(" 21:05 ").sortKey)
    }

    @Test
    fun sortKey_putsUnreadableTimesLast() {
        assertEquals(Int.MAX_VALUE, at("").sortKey)
        assertEquals(Int.MAX_VALUE, at("sera").sortKey)
        assertEquals(Int.MAX_VALUE, at("25:00").sortKey)
    }

    @Test
    fun reservations_sortChronologically() {
        val sorted = listOf(at("21:15"), at("sera"), at("19:30"), at("20")).sortedBy { it.sortKey }
        assertEquals(listOf("19:30", "20", "21:15", "sera"), sorted.map { it.time })
    }
}
