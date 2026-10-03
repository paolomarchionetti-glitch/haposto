package com.haposto.domain.voice

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class DetailsDictationTest {

    @Test
    fun fullSentence_fillsTablesWaitAndNote() {
        val draft = DetailsDictation.parse("tre tavoli, dieci minuti, solo tavoli fuori")
        assertEquals(3, draft.tables)
        assertEquals(10, draft.waitMinutes)
        assertEquals("Solo tavoli fuori", draft.note)
    }

    @Test
    fun digitsAndWordsInAnyOrder() {
        val draft = DetailsDictation.parse("20 minuti di attesa e 2 tavoli liberi")
        assertEquals(2, draft.tables)
        assertEquals(20, draft.waitMinutes)
        assertNull(draft.note)
    }

    @Test
    fun tablesAfterTheWord_andNoWait() {
        val draft = DetailsDictation.parse("tavoli liberi quattro, nessuna attesa")
        assertEquals(4, draft.tables)
        assertEquals(0, draft.waitMinutes)
        assertNull(draft.note)
    }

    @Test
    fun noteOnly_leavesTheOtherFieldsUntouched() {
        val draft = DetailsDictation.parse("cucina aperta fino alle 23")
        assertNull(draft.tables)
        assertNull(draft.waitMinutes)
        assertEquals("Cucina aperta fino alle 23", draft.note)
    }

    @Test
    fun noteKeyword_takesEverythingAfterIt() {
        val draft = DetailsDictation.parse("un tavolo nota: dehors con 2 tavoli all'ombra")
        assertEquals(1, draft.tables)
        assertEquals("Dehors con 2 tavoli all'ombra", draft.note)
    }

    @Test
    fun waitIsRoundedToTheAppChoices() {
        assertEquals(10, DetailsDictation.parse("5 minuti").waitMinutes)
        assertEquals(20, DetailsDictation.parse("un quarto d'ora").waitMinutes)
        assertEquals(30, DetailsDictation.parse("mezz'ora di attesa").waitMinutes)
        assertEquals(30, DetailsDictation.parse("attesa di 45 minuti").waitMinutes)
        assertEquals(30, DetailsDictation.parse("un'ora").waitMinutes)
        assertEquals(listOf(0, 10, 20, 30), DetailsDictation.WAIT_CHOICES)
    }

    @Test
    fun noTables() {
        assertEquals(0, DetailsDictation.parse("nessun tavolo libero").tables)
    }

    @Test
    fun accentsAndLongNotesAreKept() {
        val draft = DetailsDictation.parse(
            "più posti al bancone, caffè offerto a chi arriva entro le 21 e prenota il dolce della casa con anticipo",
        )
        val note = draft.note!!
        assertTrue(note.startsWith("Più posti al bancone, caffè offerto"))
        assertTrue(note.length <= 80)
    }

    @Test
    fun offerKeyword_fillsTheOfferOnly() {
        val draft = DetailsDictation.parse("due tavoli, offerta dolce offerto a chi arriva entro le 21")
        assertEquals(2, draft.tables)
        assertEquals("Dolce offerto a chi arriva entro le 21", draft.offer)
        assertNull(draft.note)
    }

    @Test
    fun noteAndOfferInTheSameSentence_inAnyOrder() {
        val first = DetailsDictation.parse("nota solo esterni, offerta calice offerto")
        assertEquals("Solo esterni", first.note)
        assertEquals("Calice offerto", first.offer)
        val second = DetailsDictation.parse("offerta meno 10 per cento. nota cucina fino alle 23")
        assertEquals("Meno 10 per cento", second.offer)
        assertEquals("Cucina fino alle 23", second.note)
    }

    @Test
    fun emptyDictation_changesNothing() {
        assertTrue(DetailsDictation.parse("  ").isEmpty)
        assertTrue(DetailsDictation.parse("e, con").isEmpty)
    }
}
