package com.haposto.data.loyalty

import java.time.Duration
import java.time.Instant

/** Testi in italiano della tessera: regole, premi, esiti. Logica pura, senza Android. */
object LoyaltyTexts {

    /** T13: tipologie per la condizione del timbro, nell'ordine della lista. */
    val CONDITION_TYPES = listOf(
        "STARTER", "FIRST_COURSE", "MAIN_COURSE", "PIZZA", "SINGLE_DISH_OR_MENU", "DESSERT", "DRINK", "COFFEE",
    )

    /** §8.2: omaggi possibili, niente alcolici. */
    val GIFTS = listOf(
        "COFFEE", "DESSERT", "ICE_CREAM", "FRUIT", "STARTER", "BRUSCHETTA", "SIDE_DISH", "FIRST_COURSE",
        "MAIN_COURSE", "PIZZA", "DISH_OF_THE_DAY", "KIDS_MENU", "SOFT_DRINK", "WATER", "ALCOHOL_FREE_APERITIF",
        "COVER_CHARGE",
    )

    fun conditionType(code: String): String = when (code) {
        "STARTER" -> "antipasto"
        "FIRST_COURSE" -> "primo"
        "MAIN_COURSE" -> "secondo"
        "PIZZA" -> "pizza"
        "SINGLE_DISH_OR_MENU" -> "piatto unico o menù"
        "DESSERT" -> "dolce"
        "DRINK" -> "bevanda"
        "COFFEE" -> "caffè"
        else -> code.lowercase()
    }

    fun gift(code: String): String = when (code) {
        "COFFEE" -> "Caffè"
        "DESSERT" -> "Dolce"
        "ICE_CREAM" -> "Gelato o sorbetto"
        "FRUIT" -> "Frutta"
        "STARTER" -> "Antipasto"
        "BRUSCHETTA" -> "Stuzzichino o bruschetta"
        "SIDE_DISH" -> "Contorno"
        "FIRST_COURSE" -> "Primo piatto"
        "MAIN_COURSE" -> "Secondo piatto"
        "PIZZA" -> "Pizza"
        "DISH_OF_THE_DAY" -> "Piatto del giorno"
        "KIDS_MENU" -> "Menù bambini"
        "SOFT_DRINK" -> "Bibita analcolica"
        "WATER" -> "Acqua"
        "ALCOHOL_FREE_APERITIF" -> "Aperitivo analcolico"
        "COVER_CHARGE" -> "Coperto"
        else -> code
    }

    private val WEEKDAYS = listOf("lunedì", "martedì", "mercoledì", "giovedì", "venerdì", "sabato", "domenica")

    /** Giorno ISO: 1 = lunedì … 7 = domenica. */
    fun weekday(iso: Int): String = WEEKDAYS.getOrElse(iso - 1) { "?" }

    fun weekdayShort(iso: Int): String = weekday(iso).take(3)

    /** 1000 → "10 €", 750 → "7,50 €". */
    fun euro(cents: Int): String =
        if (cents % 100 == 0) "${cents / 100} €" else "${cents / 100},${(cents % 100).toString().padStart(2, '0')} €"

    /** T12: la condizione come la legge lo staff alla cassa. */
    fun condition(condition: LoyaltyCondition): String = when (condition.kind) {
        ConditionKind.SPEND -> "Spesa minima di ${euro(condition.minSpendCents ?: 0)} a persona"
        ConditionKind.ONE_OF -> "Almeno una consumazione tra: ${condition.types.joinToString(", ") { conditionType(it) }}"
        ConditionKind.TWO_OF -> "Almeno due consumazioni diverse tra: ${condition.types.joinToString(", ") { conditionType(it) }}"
    }

    fun slot(slot: DoubleSlot): String = when (slot) {
        DoubleSlot.ALL_DAY -> "tutto il giorno"
        DoubleSlot.LUNCH -> "a pranzo (11–15)"
        DoubleSlot.DINNER -> "a cena (18–23)"
    }

    /** T14. */
    fun doubleDay(doubleDay: DoubleDay?): String =
        if (doubleDay == null) "Nessun giorno a timbro doppio"
        else "Timbro doppio il ${weekday(doubleDay.weekday)} ${slot(doubleDay.slot)}"

    /** T40–T42: il premio in una riga; [forCustomer] cambia «sua» in «tua». */
    fun reward(rules: RewardRules, forCustomer: Boolean = false): String {
        val whose = if (forCustomer) "tua" else "sua"
        return when (rules.kind) {
            RewardKind.GIFT -> "Omaggio: ${gift(rules.gift.orEmpty()).lowercase()}"
            RewardKind.DISCOUNT -> buildString {
                append("${rules.percent ?: 0}% sulla $whose consumazione, max ${euro(rules.capCents ?: 0)}")
                rules.minSpendCents?.let { append(", con una spesa di almeno ${euro(it)}") }
            }
            RewardKind.VOUCHER ->
                "${euro(rules.amountCents ?: 0)} di sconto alla visita dopo, con una spesa di almeno ${euro(rules.minSpendCents ?: 0)}"
        }
    }

    /** T43–T47: come si usa il premio, una regola per riga. */
    fun rewardUse(rules: RewardRules): List<String> = listOf(
        if (rules.from == RewardFrom.SAME_VISIT) "Si usa subito, anche alla stessa visita" else "Si usa dalla visita successiva",
        if (rules.weekdays.isNullOrEmpty()) "Tutti i giorni" else "Solo: ${rules.weekdays.joinToString(", ") { weekday(it) }}",
        rules.maxPerTable?.let { "Al massimo $it ${if (it == 1) "premio" else "premi"} per tavolo alla stessa visita" }
            ?: "Nessun limite di premi per tavolo",
        if (rules.cumulable) "Cumulabile con altre offerte" else "Non cumulabile con altre offerte",
        "Valido ${rules.validDays} giorni dallo sblocco; mai in denaro, solo per chi l'ha maturato",
    )

    /** T16: il patto in tre righe. */
    fun pact(noticeDays: Int): List<String> = listOf(
        "Timbro ogni cliente che rispetta la condizione e mostra il QR.",
        "Riconosco i premi maturati entro la loro validità, alle condizioni dichiarate.",
        "Se smetto, i clienti hanno $noticeDays giorni per completare.",
    )

    fun status(program: LoyaltyProgram, formatDate: (Instant) -> String): String = when (program.status) {
        "ACTIVE" -> "Attiva"
        "CLOSING" -> "In chiusura" + (program.closingUntil?.let { " fino al ${formatDate(it)}" } ?: "")
        "SUSPENDED" -> "Sospesa per le segnalazioni dei clienti" + (program.suspendedUntil?.let { " fino al ${formatDate(it)}" } ?: "")
        "REMOVED" -> "Tolta per le segnalazioni dei clienti"
        "ENDED" -> "Finita"
        else -> "Non attivata"
    }

    /** Esito di una persona, dopo il codice (es. «+1 timbro · 4 su 10»). */
    fun outcome(member: StampMember, gapHours: Int = 4): String = when (member.outcome) {
        StampOutcome.STAMPED -> buildString {
            append("+${member.stampsAdded} ${if (member.stampsAdded == 1) "timbro" else "timbri"}")
            if (member.doubleDay) append(" (giorno doppio)")
            if (member.stamps != null && member.required != null) append(" · ${member.stamps} su ${member.required}")
            if (member.rewardUnlocked) append(" · 🎁 premio sbloccato")
            if (member.carry > 0) append(" · ${member.carry} sulla tessera nuova")
        }
        StampOutcome.TOO_SOON -> "già timbrato nelle ultime $gapHours ore: nessun timbro"
        StampOutcome.SELF -> "gestisce il locale: escluso"
        StampOutcome.NO_ACCESS -> "non può usare la tessera: escluso"
        StampOutcome.NO_NEW_CARDS -> "niente tessere nuove: la tessera è in chiusura"
        StampOutcome.PROGRAM_ENDED -> "tessera finita: solo premi da consegnare"
        StampOutcome.UNKNOWN -> "nessun timbro"
    }

    private fun excluded(outcome: StampOutcome): String = when (outcome) {
        StampOutcome.TOO_SOON -> "già timbrato oggi"
        StampOutcome.SELF -> "gestisce il locale"
        StampOutcome.NO_NEW_CARDS -> "niente tessere nuove"
        StampOutcome.PROGRAM_ENDED -> "tessera finita"
        else -> "escluso"
    }

    /** T29–T30: «Tavolo di 4 · 3 timbrati (1 già timbrato oggi)». */
    fun groupSummary(result: StampResult): String = buildString {
        append("Tavolo di ${result.people} · ${result.stamped} ${if (result.stamped == 1) "timbrato" else "timbrati"}")
        val others = result.members
            .filter { it.outcome != StampOutcome.STAMPED }
            .groupingBy { excluded(it.outcome) }
            .eachCount()
        if (others.isNotEmpty()) {
            append(" (")
            append(others.entries.joinToString(", ") { (label, count) -> "$count $label" })
            append(")")
        }
    }

    /** Messaggio per una scansione rifiutata senza eccezione (QR o codice). */
    fun stampError(result: StampResult, formatTime: (Instant) -> String): String = when (result.error) {
        "INVALID_TOKEN" -> "QR non valido per questo locale."
        "TOKEN_USED" -> "Questo QR è già stato usato: chiedi al cliente di aprirne uno nuovo."
        "TOKEN_EXPIRED" -> "QR scaduto: il cliente deve mostrare quello aggiornato."
        "INVALID_CODE" -> "Codice sbagliato" + (result.attemptsLeft?.let { " (restano $it tentativi prima del blocco)" } ?: "") + "."
        "CODE_LOCKED" -> "Troppi codici sbagliati: l'inserimento è bloccato" +
            (result.lockedUntil?.let { " fino alle ${formatTime(it)}" } ?: " per qualche minuto") + ". Il QR si può ancora scansionare."
        else -> "Scansione non riuscita."
    }

    /** Sconto scritto dallo staff: «7,50», «7.5» o «7 €» → 750; vuoto o non valido → null. */
    fun parseEuroCents(text: String): Int? {
        val clean = text.replace("€", "").trim().replace(',', '.')
        val value = clean.toBigDecimalOrNull() ?: return null
        if (value.signum() < 0 || value.scale() > 2 || value > java.math.BigDecimal(10_000)) return null
        return value.movePointRight(2).toInt()
    }

    /** T33: tempo che resta per annullare, «1:45»; null se non si può più. */
    fun countdown(until: Instant?, now: Instant): String? {
        if (until == null) return null
        val seconds = Duration.between(now, until).seconds
        if (seconds <= 0) return null
        return "${seconds / 60}:${(seconds % 60).toString().padStart(2, '0')}"
    }
}
