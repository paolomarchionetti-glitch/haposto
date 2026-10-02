package com.haposto.data.reservations

import java.time.LocalDate
import org.junit.Assert.assertEquals
import org.junit.Test

class ReservationListTest {

    private val today = LocalDate.of(2026, 10, 2)

    private fun r(id: String, time: String, date: LocalDate?) =
        Reservation(id = id, name = id, time = time, partySize = 2, date = date?.toString())

    @Test
    fun oldReservationsWithoutDay_belongToToday() {
        val items = ReservationList.withDates(listOf(r("vecchia", "20:00", null)), today)
        assertEquals(today.toString(), items.single().date)
    }

    @Test
    fun pastDaysAreRemoved_todayAndFutureStay() {
        val items = listOf(r("ieri", "20:00", today.minusDays(1)), r("oggi", "21:00", today), r("domani", "13:00", today.plusDays(1)))
        assertEquals(listOf("oggi", "domani"), ReservationList.upcoming(items, today).map { it.id })
    }

    @Test
    fun oneDayAtATime_inTimeOrder() {
        val items = listOf(
            r("b", "21:15", today),
            r("domani", "12:00", today.plusDays(1)),
            r("a", "19:30", today),
            r("senza ora", "", today),
        )
        assertEquals(listOf("a", "b", "senza ora"), ReservationList.forDay(items, today).map { it.id })
        assertEquals(listOf("a", "b", "senza ora", "domani"), ReservationList.sorted(items).map { it.id })
    }
}
