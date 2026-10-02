package com.haposto.data.restaurant

/** Ultime note pubblicate da questo telefono per un locale, per riusarle con un tocco. */
interface RecentNotesStore {
    fun load(): List<String>
    fun save(notes: List<String>)
}

object RecentNotes {
    const val MAX = 5

    /** [note] in cima alla lista, senza doppioni (maiuscole e spazi non contano), al massimo [MAX]. */
    fun add(current: List<String>, note: String): List<String> {
        val clean = note.trim().replace(Regex("\\s+"), " ")
        if (clean.isEmpty()) return current
        val key = clean.lowercase()
        return (listOf(clean) + current.filterNot { it.trim().lowercase() == key }).take(MAX)
    }
}

/** Nessuna memoria (versione Demo e test). */
object NoRecentNotes : RecentNotesStore {
    override fun load(): List<String> = emptyList()
    override fun save(notes: List<String>) = Unit
}
