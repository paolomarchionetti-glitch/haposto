package com.haposto.data.restaurant

import java.time.Duration
import java.time.Instant
import java.time.ZoneOffset
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class PlanNoticesTest {

    private val now = Instant.parse("2027-07-10T10:00:00Z")
    private val pro = setOf("LIVE_STATUS", "LIVE_DETAILS")

    private fun plan(source: String, validUntil: Instant?, features: Set<String> = pro) = RestaurantPlan(
        code = if ("LIVE_STATUS" in features) "RESTAURANT_PRO" else "RESTAURANT_BASIC",
        name = "Pro",
        source = source,
        validUntil = validUntil,
        features = features,
        staffLimit = 5,
        analyticsDays = 90,
    )

    @Test
    fun noPlan_saysNotConnected() {
        val none = plan("NONE", null, features = setOf("ANALYTICS_BASIC"))
        assertTrue(PlanNotices.warning(none, now)!!.contains("Non collegato"))
        assertEquals("Nessun piano: il locale appare «Non collegato»", PlanNotices.sourceLabel(none))
    }

    @Test
    fun trialEndingWithinAWeek_isAnnouncedWithItsDate() {
        val trial = plan("TRIAL", now.plus(Duration.ofDays(3)))
        assertEquals(
            "Il periodo gratuito finisce il 13/07/2027: poi il locale appare «Non collegato». " +
                "Per informazioni sui piani scrivi a info@haposto.app.",
            PlanNotices.warning(trial, now, ZoneOffset.UTC),
        )
        assertEquals("Prova gratuita", PlanNotices.sourceLabel(trial))
    }

    @Test
    fun farAwayEnds_renewingStripe_andOldDatabases_sayNothing() {
        assertNull(PlanNotices.warning(plan("BETA", now.plus(Duration.ofDays(30))), now))
        assertNull(PlanNotices.warning(plan("STRIPE", now.plus(Duration.ofDays(2))), now))
        // Database senza la 0016: il vecchio Basic gratuito pubblicava ancora lo stato.
        assertNull(PlanNotices.warning(plan("FREE", null, features = setOf("LIVE_STATUS")), now))
    }

    @Test
    fun manualPlan_speaksOfThePlan() {
        val manual = plan("MANUAL", now.plus(Duration.ofHours(20)))
        assertTrue(PlanNotices.warning(manual, now, ZoneOffset.UTC)!!.startsWith("Il piano finisce il 11/07/2027"))
    }
}
