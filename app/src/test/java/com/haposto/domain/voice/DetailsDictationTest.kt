package com.haposto.domain.voice

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
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
    fun noWait_inAnyOrder() {
        listOf("nessuna attesa", "attesa nessuna", "attesa zero", "niente attesa", "non c'è attesa", "si entra subito")
            .forEach { phrase ->
                val draft = DetailsDictation.parse(phrase)
                assertEquals(phrase, 0, draft.waitMinutes)
                assertNull(phrase, draft.note)
            }
    }

    @Test
    fun waitNotIndicated_clearsTheWait() {
        listOf("attesa non indicata", "togli l'attesa", "attesa non la so", "cancella attesa").forEach { phrase ->
            val draft = DetailsDictation.parse(phrase)
            assertTrue(phrase, draft.waitCleared)
            assertNull(phrase, draft.waitMinutes)
            assertNull(phrase, draft.note)
            assertFalse(phrase, draft.isEmpty)
        }
    }

    @Test
    fun otherFieldsCanBeClearedToo() {
        val draft = DetailsDictation.parse("togli i tavoli, nessuna nota, togli l'offerta, venti minuti")
        assertTrue(draft.tablesCleared)
        assertTrue(draft.noteCleared)
        assertTrue(draft.offerCleared)
        assertNull(draft.offer)
        assertNull(draft.note)
        assertEquals(20, draft.waitMinutes)
    }

    @Test
    fun estimatesAndRanges() {
        assertEquals(20, DetailsDictation.parse("una ventina di minuti").waitMinutes)
        assertEquals(10, DetailsDictation.parse("circa una decina di minuti").waitMinutes)
        assertEquals(20, DetailsDictation.parse("10-15 minuti").waitMinutes)
        assertEquals(20, DetailsDictation.parse("tra dieci e quindici minuti di attesa").waitMinutes)
        assertEquals(30, DetailsDictation.parse("una mezz'oretta").waitMinutes)
        assertEquals(30, DetailsDictation.parse("tre quarti d'ora").waitMinutes)
        assertEquals(2, DetailsDictation.parse("un paio di tavoli").tables)
        assertEquals(3, DetailsDictation.parse("tre o quattro tavoli").tables)
        assertEquals(1, DetailsDictation.parse("solo un tavolo").tables)
        assertEquals(0, DetailsDictation.parse("tavoli liberi nessuno").tables)
        assertEquals(4, DetailsDictation.parse("quattro tavolini liberi").tables)
    }

    @Test
    fun fillerWordsDoNotEndUpInTheNote() {
        val draft = DetailsDictation.parse("allora due tavoli e dieci minuti")
        assertEquals(2, draft.tables)
        assertEquals(10, draft.waitMinutes)
        assertNull(draft.note)
    }

    @Test
    fun emptyDictation_changesNothing() {
        assertTrue(DetailsDictation.parse("  ").isEmpty)
        assertTrue(DetailsDictation.parse("e, con").isEmpty)
    }
}
