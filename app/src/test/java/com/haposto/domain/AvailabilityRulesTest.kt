package com.haposto.domain

import com.haposto.domain.model.AvailabilityRules
import com.haposto.domain.model.AvailabilityStatus
import com.haposto.domain.model.LiveAvailability
import java.time.Instant
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

class AvailabilityRulesTest {

    @Test
    fun frozenV1Limits_areStable() {
        assertEquals(30L, AvailabilityRules.LIVE_TTL_MINUTES)
        assertEquals(99, AvailabilityRules.MAX_AVAILABLE_TABLES)
        assertEquals(240, AvailabilityRules.MAX_ESTIMATED_WAIT_MINUTES)
        assertEquals(80, AvailabilityRules.MAX_NOTE_LENGTH)
    }

    @Test
    fun fullCannotExposeAvailableTables() {
        val now = Instant.parse("2026-08-24T18:00:00Z")

        assertThrows(IllegalArgumentException::class.java) {
            LiveAvailability(
                status = AvailabilityStatus.FULL,
                updatedAt = now,
                validUntil = now.plusSeconds(1_800),
                availableTables = 1,
            )
        }
    }
}
