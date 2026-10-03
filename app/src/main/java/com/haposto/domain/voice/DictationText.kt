package com.haposto.domain.voice

/** Testo dettato da cui si tolgono, uno alla volta, i pezzi riconosciuti (orario, persone, ...). */
internal class DictationText(text: String) {

    var rest: String = " " + text.replace('’', '\'').replace('\n', ' ') + " "
        private set

    /** Il primo risultato di [regex] che [use] accetta viene tolto dal testo. */
    fun take(regex: Regex, use: (MatchResult) -> Boolean): Boolean {
        val match = regex.findAll(rest).firstOrNull(use) ?: return false
        rest = rest.replaceRange(match.range, SEPARATOR)
        return true
    }

    /** Toglie tutti i risultati che [use] accetta; restituisce quanti sono. */
    fun takeAll(regex: Regex, use: (MatchResult) -> Boolean): Int {
        var count = 0
        while (take(regex, use)) count++
        return count
    }

    /** Pezzi rimasti, separati dove c'era un pezzo riconosciuto, una virgola o un punto e virgola. */
    fun leftoverSegments(): List<String> =
        rest.split(SEPARATOR.trim(), ",", ";")
            .map { it.trim().replace(Regex("\\s+"), " ") }
            .filter { it.isNotEmpty() }

    private companion object {
        const val SEPARATOR = " ⁣ "
    }
}

/** Toglie le parole di collegamento all'inizio e alla fine ("per", "e", "alle", ...). */
internal fun String.trimWords(atStart: Set<String>, atEnd: Set<String>): String {
    var words = split(' ').filter { it.isNotBlank() }
    fun key(word: String) = word.lowercase().trim('.', ':', '-', '!', '?')
    while (words.isNotEmpty() && key(words.first()) in atStart) words = words.drop(1)
    while (words.isNotEmpty() && key(words.last()) in atEnd) words = words.dropLast(1)
    return words.joinToString(" ").trim('.', ':', '-', ' ')
}

/** Prima lettera maiuscola (la dettatura restituisce quasi sempre tutto minuscolo). */
internal fun String.capitalizedFirst(): String = replaceFirstChar { it.titlecase() }

/** Testo al massimo di [max] caratteri, tagliato possibilmente tra due parole. */
internal fun String.limitTo(max: Int): String {
    if (length <= max) return this
    val cut = take(max)
    val space = cut.lastIndexOf(' ')
    return (if (space >= max / 2) cut.take(space) else cut).trimEnd()
}
