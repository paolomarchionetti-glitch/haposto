package com.haposto.data.restaurant

import org.junit.Assert.assertEquals
import org.junit.Test

class RecentNotesTest {

    @Test
    fun newestFirst_withoutDuplicates_atMostFive() {
        var notes = emptyList<String>()
        listOf("Solo esterni", "Bancone", "solo  esterni ", "A", "B", "C", "D").forEach { notes = RecentNotes.add(notes, it) }
        assertEquals(listOf("D", "C", "B", "A", "solo esterni"), notes)
    }

    @Test
    fun blankNotesAreIgnored() {
        assertEquals(listOf("Bancone"), RecentNotes.add(listOf("Bancone"), "   "))
    }
}
