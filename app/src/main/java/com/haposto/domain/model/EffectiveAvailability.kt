package com.haposto.domain.model

import java.time.Instant

data class EffectiveAvailability(
    val status: AvailabilityStatus,
    val updatedAt: Instant? = null,
    val validUntil: Instant? = null,
    val availableTables: Int? = null,
    val estimatedWaitMinutes: Int? = null,
    val note: String? = null,
    /** Offerta della serata: solo finché lo stato è valido e c'è posto. */
    val offer: String? = null,
)
