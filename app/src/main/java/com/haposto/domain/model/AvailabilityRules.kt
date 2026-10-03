package com.haposto.domain.model

/**
 * Frozen V1 pre-backend business limits for live availability.
 *
 * STEP 7 server/RPC behavior must mirror these rules. Change them only through an explicit
 * contract-version update, not inside a repository implementation.
 */
object AvailabilityRules {
    const val LIVE_TTL_MINUTES = 30L
    const val MAX_AVAILABLE_TABLES = 99
    const val MAX_ESTIMATED_WAIT_MINUTES = 240
    const val MAX_NOTE_LENGTH = 80

    /** Offerta della serata (migration 0015): facoltativa, solo con "C'è posto" o "Pochi posti". */
    const val MAX_OFFER_LENGTH = 60
}
