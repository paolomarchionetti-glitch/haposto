package com.haposto.ui.screens.restaurant

import com.haposto.domain.model.AvailabilityStatus
import com.haposto.domain.model.EffectiveAvailability
import com.haposto.domain.model.Restaurant
import java.time.Instant

data class RestaurantManagerUiState(
    val restaurant: Restaurant? = null,
    val effectiveAvailability: EffectiveAvailability = EffectiveAvailability(AvailabilityStatus.STALE),
    val now: Instant = Instant.now(),
    val availableTables: Int? = null,
    val estimatedWaitMinutes: Int? = null,
    val note: String = "",
    val isSaving: Boolean = false,
    val message: String? = null,
    /** Ultime note pubblicate da questo telefono, la più recente per prima. */
    val recentNotes: List<String> = emptyList(),
    /** Offerta della serata in preparazione (vuota = nessuna). */
    val offer: String = "",
) {
    val canManage: Boolean get() = restaurant != null
    val noteRemaining: Int get() = 80 - note.length
    val offerRemaining: Int get() = 60 - offer.length
}
