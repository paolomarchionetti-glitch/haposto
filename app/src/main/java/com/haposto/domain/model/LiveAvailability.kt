package com.haposto.domain.model

import java.time.Instant

data class LiveAvailability(
    val status: AvailabilityStatus,
    val updatedAt: Instant,
    val validUntil: Instant,
    val availableTables: Int? = null,
    val estimatedWaitMinutes: Int? = null,
    val note: String? = null,
    /** Offerta della serata; scade con lo stato. */
    val offer: String? = null,
) {
    init {
        require(status in setOf(
            AvailabilityStatus.AVAILABLE,
            AvailabilityStatus.LIMITED,
            AvailabilityStatus.FULL,
        )) { "LiveAvailability may only contain a restaurant-published live status." }
        require(!validUntil.isBefore(updatedAt)) { "validUntil must be >= updatedAt" }
        require(availableTables == null || availableTables in 0..AvailabilityRules.MAX_AVAILABLE_TABLES)
        require(estimatedWaitMinutes == null || estimatedWaitMinutes in 0..AvailabilityRules.MAX_ESTIMATED_WAIT_MINUTES)
        require(note == null || note.length <= AvailabilityRules.MAX_NOTE_LENGTH)
        require(offer == null || offer.length <= AvailabilityRules.MAX_OFFER_LENGTH)
        require(status != AvailabilityStatus.FULL || availableTables == null) {
            "FULL cannot expose available tables."
        }
    }
}
