package com.haposto.domain.voice

import com.haposto.domain.model.AvailabilityRules

/** Dettagli facoltativi capiti da una frase; null = la frase non ne parla (il campo resta com'è). */
data class DetailsDraft(
    val tables: Int? = null,
    val waitMinutes: Int? = null,
    val note: String? = null,
) {
    val isEmpty: Boolean get() = tables == null && waitMinutes == null && note == null
}

/**
 * "Tre tavoli, dieci minuti, solo tavoli fuori" → tavoli 3, attesa 10 minuti, nota "Solo tavoli
 * fuori". L'attesa diventa uno dei valori che l'app propone (0, 10, 20, 30 minuti); quello che
 * resta della frase diventa la nota (o tutto quello che segue la parola "nota").
 */
object DetailsDictation {

    /** Valori dei tasti "Attesa indicativa" della dashboard (oltre a "non indicata"). */
    val WAIT_CHOICES = listOf(0, 10, 20, 30)

    private val N = "(${ItalianNumbers.PATTERN})"
    private val OPTIONS = setOf(RegexOption.IGNORE_CASE)
    private const val WAIT_SUFFIX = "(?:\\s+di\\s+attesa$WORD_END)?"

    private val NOTE_KEYWORD = Regex("${WORD_START}nota$WORD_END\\s*[:,.-]?\\s*(.+)$", OPTIONS)
    private val NO_TABLES = Regex("$WORD_START(?:nessun|zero)\\s+tavol[oi](?:\\s+liber[oi])?$WORD_END", OPTIONS)
    private val TABLES_BEFORE = Regex("$WORD_START$N\\s+tavol[oi](?:\\s+liber[oi])?$WORD_END", OPTIONS)
    private val TABLES_AFTER = Regex("${WORD_START}tavol[oi]\\s+(?:liber[oi]\\s+)?$N$WORD_END(?!\\s*min)", OPTIONS)
    private val NO_WAIT = Regex("$WORD_START(?:nessuna|niente|senza|zero)\\s+attesa$WORD_END", OPTIONS)
    private val WAIT_MINUTES = Regex(
        "$WORD_START(?:(?:di\\s+)?attesa\\s+(?:di\\s+)?(?:circa\\s+)?)?$N\\s*(?:minuti|minuto|min)$WORD_END$WAIT_SUFFIX",
        OPTIONS,
    )
    private val WAIT_HALF_HOUR = Regex("$WORD_START(?:(?:di\\s+)?attesa\\s+(?:di\\s+)?)?mezz'?\\s*ora$WORD_END$WAIT_SUFFIX", OPTIONS)
    private val WAIT_QUARTER = Regex("$WORD_START(?:un\\s+)?quarto\\s+d'?\\s*ora$WORD_END$WAIT_SUFFIX", OPTIONS)
    private val WAIT_HOUR = Regex("$WORD_START(?:un'?\\s*ora|1\\s+ora)$WORD_END$WAIT_SUFFIX", OPTIONS)

    private val NOTE_START = setOf("e", "ed", "con", "poi", "inoltre", "di", "attesa", "nota")
    private val NOTE_END = setOf("e", "ed", "con", "poi", "di", "attesa")

    fun parse(text: String): DetailsDraft {
        val dictated = DictationText(text)
        var note: String? = null
        dictated.take(NOTE_KEYWORD) { match -> cleanNote(match.groupValues[1])?.also { note = it } != null }

        var tables: Int? = null
        dictated.take(NO_TABLES) { tables = 0; true } ||
            dictated.take(TABLES_BEFORE) { match -> tablesFrom(match)?.also { tables = it } != null } ||
            dictated.take(TABLES_AFTER) { match -> tablesFrom(match)?.also { tables = it } != null }

        var wait: Int? = null
        dictated.take(NO_WAIT) { wait = 0; true } ||
            dictated.take(WAIT_MINUTES) { match ->
                ItalianNumbers.parse(match.groupValues[1])?.also { wait = waitChoice(it) } != null
            } ||
            dictated.take(WAIT_HALF_HOUR) { wait = 30; true } ||
            dictated.take(WAIT_QUARTER) { wait = waitChoice(15); true } ||
            dictated.take(WAIT_HOUR) { wait = 30; true }

        if (note == null) {
            note = cleanNote(
                dictated.leftoverSegments()
                    .map { it.trimWords(NOTE_START, NOTE_END) }
                    .filter { segment -> segment.any(Char::isLetter) }
                    .joinToString(", "),
            )
        }
        return DetailsDraft(tables = tables, waitMinutes = wait, note = note)
    }

    /** Minuti detti → valore più vicino tra quelli dei tasti (a metà strada si arrotonda in su). */
    fun waitChoice(minutes: Int): Int = when {
        minutes <= 0 -> 0
        minutes < 15 -> 10
        minutes < 25 -> 20
        else -> 30
    }

    private fun tablesFrom(match: MatchResult): Int? =
        ItalianNumbers.parse(match.groupValues[1])?.takeIf { it <= AvailabilityRules.MAX_AVAILABLE_TABLES }

    private fun cleanNote(raw: String): String? {
        val text = raw.trim().replace(Regex("\\s+"), " ").trim(',', ';', ' ')
        if (text.none(Char::isLetter)) return null
        return text.capitalizedFirst().limitTo(AvailabilityRules.MAX_NOTE_LENGTH)
    }
}
