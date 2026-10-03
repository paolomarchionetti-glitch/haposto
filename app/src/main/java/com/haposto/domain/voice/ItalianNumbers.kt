package com.haposto.domain.voice

/**
 * Numeri da 0 a 99 come li restituisce la dettatura: in cifre ("4") o in lettere ("quattro",
 * "ventotto", "ventitré"). Usato per capire le frasi dettate senza servizi esterni.
 */
internal object ItalianNumbers {

    private val UNITS = listOf("zero", "uno", "due", "tre", "quattro", "cinque", "sei", "sette", "otto", "nove")
    private val TEENS = listOf(
        "dieci", "undici", "dodici", "tredici", "quattordici",
        "quindici", "sedici", "diciassette", "diciotto", "diciannove",
    )
    private val TENS = listOf("venti", "trenta", "quaranta", "cinquanta", "sessanta", "settanta", "ottanta", "novanta")

    private val WORDS: Map<String, Int> = buildMap {
        UNITS.forEachIndexed { value, word -> put(word, value) }
        put("un", 1)
        put("una", 1)
        TEENS.forEachIndexed { index, word -> put(word, 10 + index) }
        TENS.forEachIndexed { index, tens ->
            val value = 20 + index * 10
            put(tens, value)
            for (unit in 1..9) {
                val unitWord = UNITS[unit]
                // "ventuno", "trentotto": la vocale finale cade davanti a "uno" e "otto".
                val word = if (unitWord.first() in "uo") tens.dropLast(1) + unitWord else tens + unitWord
                put(word, value + unit)
            }
            put(tens + "tré", value + 3)
        }
    }

    /** Espressione regolare (senza gruppi) per un numero in cifre o in lettere. */
    val PATTERN: String = "(?:\\d{1,3}|" + WORDS.keys.sortedByDescending { it.length }.joinToString("|") + ")"

    /** Come [PATTERN] ma senza "un", "una", "uno" (troppo comuni per un numero isolato). */
    val PATTERN_FROM_TWO: String = "(?:\\d{1,3}|" +
        WORDS.filterValues { it >= 2 }.keys.sortedByDescending { it.length }.joinToString("|") + ")"

    fun parse(token: String): Int? {
        val word = token.trim().lowercase()
        return word.toIntOrNull() ?: WORDS[word] ?: WORDS[word.replace('é', 'e').replace('è', 'e')]
    }
}

/** Confini di parola che valgono anche per le lettere accentate. */
internal const val WORD_START = "(?<![\\p{L}\\p{N}])"
internal const val WORD_END = "(?![\\p{L}\\p{N}])"
