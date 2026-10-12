package com.haposto.data.admin

import com.haposto.data.loyalty.LoyaltyTexts

/** Testi della tessera nel pannello admin (scheda «Tessere» e scheda del locale). Logica pura. */
object AdminLoyaltyTexts {

    data class Section(val title: String, val rows: List<Pair<String, String>>)

    private val PROGRAM_ORDER = listOf("ACTIVE", "CLOSING", "SUSPENDED", "REMOVED", "ENDED", "NONE")

    /** OFF, TEST, ON, EXISTING_ONLY (impostazione `loyalty`). */
    fun mode(mode: String): String = when (mode) {
        "OFF" -> "Spenta: nessuno la vede"
        "TEST" -> "Prova: solo locali e clienti tester (gli admin sempre)"
        "ON" -> "Attiva per tutti"
        "EXISTING_ONLY" -> "Solo le tessere già iniziate"
        else -> mode
    }

    /** Stato della tessera di un locale. */
    fun programStatus(status: String?): String = when (status) {
        null, "NONE" -> "non attivata"
        "ACTIVE" -> "attiva"
        "CLOSING" -> "in chiusura (preavviso)"
        "SUSPENDED" -> "sospesa per segnalazioni"
        "REMOVED" -> "tolta (solo l'admin la ridà)"
        "ENDED" -> "finita"
        else -> status.lowercase()
    }

    fun rewardKind(kind: String): String = when (kind) {
        "GIFT" -> "Omaggio"
        "DISCOUNT" -> "Sconto personale"
        "VOUCHER" -> "Buono per la visita dopo"
        else -> kind
    }

    /** Le regole attuali di un locale in una riga: «10 timbri → 20% sulla sua consumazione, max 10 €». */
    fun rules(detail: AdminRestaurantLoyalty): String? =
        detail.rules?.let { "${it.stampsRequired} timbri → ${LoyaltyTexts.reward(it.reward)}" }

    /** I numeri della scheda «Tessere» (§11), sezione per sezione. */
    fun sections(overview: AdminLoyaltyOverview): List<Section> {
        fun count(map: Map<String, Int>, key: String) = (map[key] ?: 0).toString()
        val programs = overview.programs.entries
            .sortedBy { (status, _) -> PROGRAM_ORDER.indexOf(status).let { if (it < 0) PROGRAM_ORDER.size else it } }
            .map { (status, n) -> programStatus(status).replaceFirstChar(Char::uppercase) to n.toString() }
        val kinds = overview.rewardKinds.entries
            .sortedByDescending { it.value }
            .map { (kind, n) -> rewardKind(kind) to n.toString() }
        return listOf(
            Section("Locali con la tessera", programs.ifEmpty { listOf("Nessun locale" to "0") }),
            Section(
                "Tessere dei clienti",
                listOf(
                    "Attive" to count(overview.cards, "active"),
                    "Completate (premio sbloccato)" to count(overview.cards, "completed"),
                    "Azzerate (nessuna visita per mesi)" to count(overview.cards, "reset"),
                    "Finite con la tessera del locale" to count(overview.cards, "ended"),
                ),
            ),
            Section(
                "Ultimi 30 giorni",
                listOf(
                    "Scansioni" to count(overview.last30Days, "scans"),
                    "di cui tavoli di gruppo" to count(overview.last30Days, "group_scans"),
                    "Persone timbrate" to count(overview.last30Days, "people"),
                    "Timbri" to count(overview.last30Days, "stamps"),
                    "Premi sbloccati" to count(overview.last30Days, "rewards_unlocked"),
                    "Premi usati" to count(overview.last30Days, "rewards_used"),
                    "Sconti riconosciuti" to LoyaltyTexts.euro(overview.last30Days["discount_cents"] ?: 0),
                ),
            ),
            Section(
                "Premi",
                listOf(
                    "Da usare" to count(overview.rewards, "available"),
                    "Usati" to count(overview.rewards, "used"),
                    "Scaduti" to count(overview.rewards, "expired"),
                    "Finiti con la tessera" to count(overview.rewards, "ended"),
                ),
            ),
            Section("Premi scelti dai locali attivi", kinds.ifEmpty { listOf("Nessuno" to "0") }),
            Section(
                "Versioni, patti e segnalazioni",
                listOf(
                    "Versioni delle regole" to overview.versions.toString(),
                    "Patti accettati" to overview.pacts.toString(),
                    "Segnalazioni negli ultimi 60 giorni" to overview.reports60Days.toString(),
                ),
            ),
        )
    }
}
