package com.haposto.domain.usecase

import com.haposto.domain.model.AvailabilityRules
import com.haposto.domain.model.AvailabilityStatus
import com.haposto.domain.model.EffectiveAvailability
import com.haposto.domain.model.PartnershipStatus
import com.haposto.domain.model.Restaurant
import java.time.Duration
import java.time.Instant
import kotlin.math.max

object AvailabilityResolver {

    const val DEFAULT_TTL_MINUTES = AvailabilityRules.LIVE_TTL_MINUTES

    fun resolve(restaurant: Restaurant, now: Instant): EffectiveAvailability {
        if (restaurant.partnershipStatus == PartnershipStatus.DIRECTORY_ONLY) {
            return EffectiveAvailability(status = AvailabilityStatus.NOT_CONNECTED)
        }

        val live = restaurant.liveAvailability
            ?: return EffectiveAvailability(status = AvailabilityStatus.STALE)

        if (!now.isBefore(live.validUntil)) {
            return EffectiveAvailability(
                status = AvailabilityStatus.STALE,
                updatedAt = live.updatedAt,
                validUntil = live.validUntil,
            )
        }

        return EffectiveAvailability(
            status = live.status,
            updatedAt = live.updatedAt,
            validUntil = live.validUntil,
            availableTables = live.availableTables,
            estimatedWaitMinutes = live.estimatedWaitMinutes,
            note = live.note,
        )
    }

    fun minutesSinceUpdate(updatedAt: Instant, now: Instant): Long =
        max(0L, Duration.between(updatedAt, now).toMinutes())

    fun relativeUpdateLabel(effective: EffectiveAvailability, now: Instant): String = when {
        effective.status == AvailabilityStatus.NOT_CONNECTED -> "Disponibilità non collegata"
        effective.updatedAt == null -> "Nessun aggiornamento recente"
        else -> {
            val minutes = minutesSinceUpdate(effective.updatedAt, now)
            val prefix = if (effective.status == AvailabilityStatus.STALE) {
                "Ultimo aggiornamento"
            } else {
                "Aggiornato"
            }
            when (minutes) {
                0L -> "$prefix ora"
                1L -> "$prefix 1 min fa"
                else -> "$prefix $minutes min fa"
            }
        }
    }
}
