package com.haposto.domain.voice

import com.haposto.domain.model.AvailabilityRules

/**
 * Dettagli facoltativi capiti da una frase; null = la frase non ne parla (il campo resta com'è).
 * I flag "…Cleared" dicono che la frase chiede di togliere il campo ("attesa non indicata",
 * "togli la nota"): l'attesa e i tavoli tornano "non indicati", nota e offerta vuote.
 */
data class DetailsDraft(
    val tables: Int? = null,
    val waitMinutes: Int? = null,
    val note: String? = null,
    val offer: String? = null,
    val tablesCleared: Boolean = false,
    val waitCleared: Boolean = false,
    val noteCleared: Boolean = false,
    val offerCleared: Boolean = false,
) {
    val isEmpty: Boolean
        get() = tables == null && waitMinutes == null && note == null && offer == null &&
            !tablesCleared && !waitCleared && !noteCleared && !offerCleared
}

/**
 * "Tre tavoli, dieci minuti, solo tavoli fuori" → tavoli 3, attesa 10 minuti, nota "Solo tavoli
 * fuori". L'attesa diventa uno dei valori che l'app propone (0, 10, 20, 30 minuti); quello che
 * resta della frase diventa la nota (o quello che segue la parola "nota"). Quello che segue la
 * parola "offerta" diventa l'offerta della serata ("offerta dolce offerto").
 * Capisce anche l'ordine inverso ("attesa nessuna"), le stime ("una ventina di minuti", "un paio
 * di tavoli", "10-15 minuti") e i comandi per togliere un campo ("attesa non indicata",
 * "togli i tavoli", "nessuna nota", "togli l'offerta").
 */
object DetailsDictation {

    /** Valori dei tasti "Attesa indicativa" della dashboard (oltre a "non indicata"). */
    val WAIT_CHOICES = listOf(0, 10, 20, 30)

    private val N = "(${ItalianNumbers.PATTERN})"
    private val OPTIONS = setOf(RegexOption.IGNORE_CASE)
    private const val WAIT_SUFFIX = "(?:\\s+di\\s+attesa$WORD_END)?"
    private const val TABLES_WORD = "tavol(?:o|i|ino|ini)"
    private const val FREE_WORD = "(?:\\s+liber[oi])?"
    private const val THE = "(?:(?:il|lo|la|l'|i|gli|le)\\s*)?"
    private const val REMOVE = "(?:togli|toglie|togliere|cancella|cancellare|rimuovi|rimuovere|elimina|azzera|via)"

    // Comandi per togliere un campo: si cercano prima di tutto il resto.
    private val CLEAR_OFFER = Regex(
        "$WORD_START(?:(?:nessuna|niente|senza)\\s+offerta|$REMOVE\\s+${THE}offerta|offerta\\s+(?:nessuna|niente|no))$WORD_END",
        OPTIONS,
    )
    private val CLEAR_NOTE = Regex(
        "$WORD_START(?:(?:nessuna|niente|senza)\\s+nota|$REMOVE\\s+${THE}nota|nota\\s+(?:nessuna|niente|no))$WORD_END",
        OPTIONS,
    )
    private val CLEAR_WAIT = Regex(
        "$WORD_START(?:(?:l'\\s*)?attesa\\s+(?:non\\s+(?:indicata|specificata|la\\s+so|lo\\s+so|so)|sconosciuta|da\\s+vedere)|" +
            "$REMOVE\\s+${THE}attesa|(?:senza|non)\\s+indicare\\s+${THE}attesa|attesa\\s+non\\s+so)$WORD_END",
        OPTIONS,
    )
    private val CLEAR_TABLES = Regex(
        "$WORD_START(?:$TABLES_WORD\\s+non\\s+(?:indicat[oi]|specificat[oi]|lo\\s+so|li\\s+so|so)|" +
            "$REMOVE\\s+${THE}$TABLES_WORD|(?:senza|non)\\s+indicare\\s+${THE}$TABLES_WORD)$WORD_END",
        OPTIONS,
    )

    private val NOTE_KEYWORD = Regex(
        "${WORD_START}nota$WORD_END\\s*[:,.-]?\\s*(.+?)(?=\\s*[,.;]?\\s*${WORD_START}offerta$WORD_END|$)",
        OPTIONS,
    )
    private val OFFER_KEYWORD = Regex(
        "${WORD_START}offerta$WORD_END\\s*[:,.-]?\\s*(.+?)(?=\\s*[,.;]?\\s*${WORD_START}nota$WORD_END|$)",
        OPTIONS,
    )

    private val NO_TABLES = Regex(
        "$WORD_START(?:(?:nessun|zero)\\s+$TABLES_WORD$FREE_WORD|$TABLES_WORD$FREE_WORD\\s+(?:nessuno|zero|0)|" +
            "non\\s+(?:ci\\s+sono|ho)\\s+$TABLES_WORD$FREE_WORD)$WORD_END",
        OPTIONS,
    )
    private val ONE_TABLE = Regex(
        "$WORD_START(?:un\\s+solo\\s+$TABLES_WORD|solo\\s+un\\s+$TABLES_WORD|un\\s+$TABLES_WORD\\s+solo|un\\s+$TABLES_WORD$FREE_WORD)$WORD_END",
        OPTIONS,
    )
    private val COUPLE_TABLES = Regex("${WORD_START}un\\s+paio\\s+di\\s+$TABLES_WORD$FREE_WORD$WORD_END", OPTIONS)
    // "tre tavoli", "3-4 tavoli", "tre o quattro tavoli" (si prende il numero più basso: è indicativo).
    private val TABLES_BEFORE = Regex(
        "$WORD_START$N(?:\\s*(?:-|o|/)\\s*${ItalianNumbers.PATTERN})?\\s+$TABLES_WORD$FREE_WORD$WORD_END",
        OPTIONS,
    )
    private val TABLES_AFTER = Regex(
        "$WORD_START$TABLES_WORD\\s+(?:liber[oi]\\s+)?(?:sono\\s+)?$N$WORD_END(?!\\s*min)",
        OPTIONS,
    )

    private val NO_WAIT = Regex(
        "$WORD_START(?:(?:nessuna|niente|senza|zero)\\s+attesa|nessun'\\s*attesa|" +
            "(?:l'\\s*)?attesa\\s+(?:nessuna|zero|niente|0)|non\\s+(?:c'\\s*è|c\\s+è|ce|c'e)\\s+(?:nessuna\\s+)?attesa|" +
            "si\\s+entra\\s+subito|nessun\\s+minuto)$WORD_END",
        OPTIONS,
    )
    // "10-15 minuti", "tra 10 e 15 minuti", "dieci o quindici minuti": si prende il più alto.
    private val WAIT_RANGE = Regex(
        "$WORD_START(?:(?:di\\s+)?attesa\\s+(?:di\\s+)?)?(?:tra\\s+|da\\s+)?$N\\s*(?:-|e|o|a|/)\\s*$N\\s*(?:minuti|minuto|min)$WORD_END$WAIT_SUFFIX",
        OPTIONS,
    )
    private val WAIT_ABOUT = Regex(
        "$WORD_START(?:(?:di\\s+)?attesa\\s+(?:di\\s+)?)?(?:circa\\s+)?una\\s+(decina|quindicina|ventina|trentina|quarantina)\\s+(?:di\\s+)?(?:minuti|min)$WORD_END$WAIT_SUFFIX",
        OPTIONS,
    )
    private val WAIT_MINUTES = Regex(
        "$WORD_START(?:(?:di\\s+)?attesa\\s+(?:di\\s+)?(?:circa\\s+)?)?(?:circa\\s+)?$N\\s*(?:minuti|minuto|min)$WORD_END$WAIT_SUFFIX",
        OPTIONS,
    )
    private val WAIT_HALF_HOUR = Regex(
        "$WORD_START(?:(?:di\\s+)?attesa\\s+(?:di\\s+)?)?(?:una\\s+)?mezz'?\\s*or(?:a|etta)$WORD_END$WAIT_SUFFIX",
        OPTIONS,
    )
    private val WAIT_QUARTER = Regex("$WORD_START(?:un\\s+)?quarto\\s+d'?\\s*ora$WORD_END$WAIT_SUFFIX", OPTIONS)
    private val WAIT_HOUR = Regex(
        "$WORD_START(?:un'?\\s*or(?:a|etta)|1\\s+ora|tre\\s+quarti\\s+d'?\\s*ora|più\\s+di\\s+mezz'?\\s*ora)$WORD_END$WAIT_SUFFIX",
        OPTIONS,
    )

    private val NOTE_START = setOf(
        "e", "ed", "con", "poi", "inoltre", "di", "attesa", "nota", "allora", "ok", "okay", "ehm", "dunque", "quindi",
    )
    private val NOTE_END = setOf("e", "ed", "con", "poi", "di", "attesa")

    fun parse(text: String): DetailsDraft {
        val dictated = DictationText(text)
        val offerCleared = dictated.take(CLEAR_OFFER) { true }
        val noteCleared = dictated.take(CLEAR_NOTE) { true }
        val waitCleared = dictated.take(CLEAR_WAIT) { true }
        val tablesCleared = dictated.take(CLEAR_TABLES) { true }

        var offer: String? = null
        dictated.take(OFFER_KEYWORD) { match ->
            cleanText(match.groupValues[1], AvailabilityRules.MAX_OFFER_LENGTH)?.also { offer = it } != null
        }
        var note: String? = null
        dictated.take(NOTE_KEYWORD) { match -> cleanNote(match.groupValues[1])?.also { note = it } != null }

        var tables: Int? = null
        dictated.take(NO_TABLES) { tables = 0; true } ||
            dictated.take(COUPLE_TABLES) { tables = 2; true } ||
            dictated.take(ONE_TABLE) { tables = 1; true } ||
            dictated.take(TABLES_BEFORE) { match -> tablesFrom(match)?.also { tables = it } != null } ||
            dictated.take(TABLES_AFTER) { match -> tablesFrom(match)?.also { tables = it } != null }

        var wait: Int? = null
        dictated.take(NO_WAIT) { wait = 0; true } ||
            dictated.take(WAIT_RANGE) { match ->
                val low = ItalianNumbers.parse(match.groupValues[1])
                val high = ItalianNumbers.parse(match.groupValues[2])
                if (low == null || high == null) false else { wait = waitChoice(maxOf(low, high)); true }
            } ||
            dictated.take(WAIT_ABOUT) { match ->
                wait = waitChoice(ABOUT.getValue(match.groupValues[1].lowercase())); true
            } ||
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
        return DetailsDraft(
            tables = tables.takeUnless { tablesCleared },
            waitMinutes = wait.takeUnless { waitCleared },
            note = note.takeUnless { noteCleared },
            offer = offer.takeUnless { offerCleared },
            tablesCleared = tablesCleared,
            waitCleared = waitCleared,
            noteCleared = noteCleared,
            offerCleared = offerCleared,
        )
    }

    /** Minuti detti → valore più vicino tra quelli dei tasti (a metà strada si arrotonda in su). */
    fun waitChoice(minutes: Int): Int = when {
        minutes <= 0 -> 0
        minutes < 15 -> 10
        minutes < 25 -> 20
        else -> 30
    }

    private val ABOUT = mapOf("decina" to 10, "quindicina" to 15, "ventina" to 20, "trentina" to 30, "quarantina" to 40)

    private fun tablesFrom(match: MatchResult): Int? =
        ItalianNumbers.parse(match.groupValues[1])?.takeIf { it <= AvailabilityRules.MAX_AVAILABLE_TABLES }

    private fun cleanNote(raw: String): String? = cleanText(raw, AvailabilityRules.MAX_NOTE_LENGTH)

    private fun cleanText(raw: String, max: Int): String? {
        // ⁣ segna i pezzi già riconosciuti (vedi DictationText): qui conta come spazio.
        val text = raw.replace('⁣', ' ').replace(Regex("\\s+"), " ").trim(',', ';', '.', ' ')
        if (text.none(Char::isLetter)) return null
        return text.capitalizedFirst().limitTo(max)
    }
}
