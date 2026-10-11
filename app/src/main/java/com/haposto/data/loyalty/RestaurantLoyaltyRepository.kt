package com.haposto.data.loyalty

import com.haposto.data.Outcome
import java.time.Instant

/**
 * Tessera fedeltà, lato locale (versioni DEV e PROD). Ogni regola è nel database (modalità,
 * tester, ruoli, 2FA, limiti): qui solo le chiamate. Su un database senza la migration 0018 le
 * chiamate falliscono e la tessera resta nascosta.
 */
interface RestaurantLoyaltyRepository {
    /** Scheda della tessera; [LoyaltyProgram.visible] false = funzione non disponibile per il locale. */
    suspend fun program(restaurantId: String): Outcome<LoyaltyProgram>

    /** Nuova versione con il patto accettato (solo titolare, con 2FA); restituisce il numero di versione. */
    suspend fun publish(restaurantId: String, draft: LoyaltyDraft): Outcome<Int>

    /** T20: chiusura con preavviso; restituisce la fine del preavviso. */
    suspend fun close(restaurantId: String): Outcome<Instant?>

    /** Timbro dal QR scansionato (personale o del tavolo). */
    suspend fun stampToken(restaurantId: String, token: String): Outcome<StampResult>

    /** Timbro dal codice di riserva di 6 caratteri. */
    suspend fun stampCode(restaurantId: String, code: String): Outcome<StampResult>

    /** T33: annulla una scansione entro 2 minuti. */
    suspend fun undo(scanId: String): Outcome<Unit>

    /** Premio consegnato o applicato; [discountCents] = sconto riconosciuto (facoltativo). */
    suspend fun useReward(restaurantId: String, rewardId: String, discountCents: Int?): Outcome<Unit>

    suspend fun stats(restaurantId: String, days: Int): Outcome<LoyaltyStats>
    suspend fun cards(restaurantId: String): Outcome<List<LoyaltyCardRow>>
}
