package com.haposto.data.remote.supabase

import com.haposto.data.admin.AdminLoyaltyTexts
import com.haposto.data.admin.AdminRestaurantLoyalty
import java.time.Instant
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** Scheda «Tessere» e tessera nella scheda del locale: JSON vero della migration 0018 (database locale). */
class AdminLoyaltyDecodingTest {

    private val overviewJson = """{"mode": "TEST", "cards": {"ended": 0, "reset": 0, "active": 2, "completed": 0}, "pacts": 1,
        "config": {"mode": "TEST", "launched": false, "stamps_max": 20, "stamps_min": 5, "report_warn": 3, "undo_minutes": 2,
          "scans_per_day": 300, "spend_max_eur": 50, "spend_min_eur": 5, "token_seconds": 60, "report_suspend": 5,
          "code_errors_max": 10, "report_gap_days": 90, "stamp_gap_hours": 4, "suspension_days": 90, "voucher_max_eur": 20,
          "voucher_min_eur": 2, "group_max_people": 20, "scans_per_10_min": 60, "code_lock_minutes": 10, "inactivity_months": 6,
          "reward_valid_days": 60, "group_join_minutes": 10, "report_window_days": 60, "closing_notice_days": 30,
          "group_valid_minutes": 60, "reward_scan_minutes": 30, "discount_cap_max_eur": 50, "discount_cap_min_eur": 5,
          "discount_percent_max": 50, "discount_percent_min": 5, "report_eligible_days": 60, "removal_window_months": 12},
        "rewards": {"used": 0, "ended": 0, "expired": 0, "available": 0}, "programs": {"ACTIVE": 1, "SUSPENDED": 1}, "versions": 1,
        "sanctioned": [{"name": "Osteria Levante Demo", "status": "SUSPENDED", "restaurant_id": "10000000-0000-0000-0000-000000000001",
          "suspended_until": "2027-01-10T06:13:23.128219+00:00"}],
        "last_30_days": {"scans": 2, "people": 2, "stamps": 2, "group_scans": 0, "rewards_used": 0, "discount_cents": 650,
          "rewards_unlocked": 0},
        "reward_kinds": {"DISCOUNT": 1},
        "tester_users": [{"email": "test-user2@haposto.test", "user_id": "1c072bf2-8002-4d57-b7d5-01342a1687b7"},
          {"email": "test-user@haposto.test", "user_id": "5cf0f077-194f-475d-90a4-228e27aa1274"}],
        "reports_60_days": 0,
        "tester_restaurants": [{"city": "Fano", "name": "Linea Cucina Demo", "status": "ACTIVE",
          "restaurant_id": "10000000-0000-0000-0000-000000000006"},
          {"city": "Pesaro", "name": "Osteria Levante Demo", "status": "SUSPENDED",
          "restaurant_id": "10000000-0000-0000-0000-000000000001"}]}"""

    @Test
    fun overviewReadsNumbersTestersAndSanctions() {
        val overview = decodeAdminLoyaltyOverview(overviewJson)

        assertEquals("TEST", overview.mode)
        assertFalse(overview.launched)
        assertEquals(mapOf("ACTIVE" to 1, "SUSPENDED" to 1), overview.programs)
        assertEquals(2, overview.cards["active"])
        assertEquals(650, overview.last30Days["discount_cents"])
        assertEquals(1, overview.rewardKinds["DISCOUNT"])
        assertEquals(1, overview.pacts)
        assertEquals(2, overview.testerRestaurants.size)
        assertEquals("Fano", overview.testerRestaurants.first().city)
        assertEquals("test-user2@haposto.test", overview.testerUsers.first().email)
        val sanctioned = overview.sanctioned.single()
        assertEquals("SUSPENDED", sanctioned.status)
        assertEquals(Instant.parse("2027-01-10T06:13:23.128219Z"), sanctioned.suspendedUntil)
    }

    @Test
    fun overviewSectionsReadLikeThePanel() {
        val sections = AdminLoyaltyTexts.sections(decodeAdminLoyaltyOverview(overviewJson)).associateBy { it.title }

        assertEquals(
            listOf("Attiva" to "1", "Sospesa per segnalazioni" to "1"),
            sections.getValue("Locali con la tessera").rows,
        )
        assertEquals("2", sections.getValue("Tessere dei clienti").rows.toMap()["Attive"])
        assertEquals("6,50 €", sections.getValue("Ultimi 30 giorni").rows.toMap()["Sconti riconosciuti"])
        assertEquals(listOf("Sconto personale" to "1"), sections.getValue("Premi scelti dai locali attivi").rows)
        assertEquals("1", sections.getValue("Versioni, patti e segnalazioni").rows.toMap()["Patti accettati"])
        assertEquals("Prova: solo locali e clienti tester (gli admin sempre)", AdminLoyaltyTexts.mode("TEST"))
    }

    @Test
    fun emptyDatabaseStillShowsEverySection() {
        val sections = AdminLoyaltyTexts.sections(decodeAdminLoyaltyOverview("""{"mode": "OFF", "cards": {}, "rewards": {}}"""))

        assertEquals(6, sections.size)
        assertEquals(listOf("Nessun locale" to "0"), sections.first().rows)
        assertEquals("0 €", sections[2].rows.toMap()["Sconti riconosciuti"])
        assertEquals("Spenta: nessuno la vede", AdminLoyaltyTexts.mode("OFF"))
    }

    @Test
    fun restaurantDetailReadsRulesCountsAndSuspension() {
        val restaurant = """
            "restaurant": {"id": "10000000-0000-0000-0000-000000000006", "city": "Fano", "name": "Linea Cucina Demo",
              "slug": null, "address": "Via Demo 6", "category": "Cucina", "latitude": null, "province": "PU", "longitude": null,
              "data_source": "MANUAL", "phone_number": null, "phone_public": false, "partnership_status": "ACTIVE_PARTNER"},
            "plan_code": "RESTAURANT_PRO"
        """.trimIndent()
        val active = decodeAdminRestaurantDetail(
            """{$restaurant, "loyalty": {"status": "ACTIVE", "tester": true, "current": {"reward": {"from": "SAME_VISIT",
              "gift": null, "kind": "DISCOUNT", "percent": 20, "weekdays": null, "cap_cents": 1000, "cumulable": false,
              "valid_days": 60, "amount_cents": null, "max_per_table": 4, "min_spend_cents": null}, "version": 1,
              "condition": {"kind": "ONE_OF", "types": ["FIRST_COURSE", "PIZZA"], "min_spend_cents": null}, "double_day": null,
              "version_id": "2125a5a9-e21d-4f17-86fa-129a3dce578c", "accepted_at": "2026-10-12T06:13:23.128219+00:00",
              "stamps_required": 10, "inactivity_months": 6}, "versions": 1, "active_cards": 2, "closing_until": null,
              "reports_60_days": 0, "suspended_until": null}}""",
        )
        val loyalty = active.loyalty!!
        assertEquals(2, loyalty.activeCards)
        assertEquals(1, loyalty.versions)
        assertEquals("10 timbri → 20% sulla sua consumazione, max 10 €", AdminLoyaltyTexts.rules(loyalty))
        assertFalse(AdminRestaurantLoyalty.canRestore(active.loyaltyStatus))

        val suspended = decodeAdminRestaurantDetail(
            """{$restaurant, "loyalty": {"status": "SUSPENDED", "tester": true, "current": null, "versions": 0,
              "active_cards": 0, "closing_until": null, "reports_60_days": 0,
              "suspended_until": "2027-01-10T06:13:23.128219+00:00"}}""",
        )
        assertNull(AdminLoyaltyTexts.rules(suspended.loyalty!!))
        assertEquals(Instant.parse("2027-01-10T06:13:23.128219Z"), suspended.loyalty!!.suspendedUntil)
        assertTrue(AdminRestaurantLoyalty.canRestore(suspended.loyaltyStatus))
        assertTrue(AdminRestaurantLoyalty.canRestore("REMOVED"))

        assertNull(decodeAdminRestaurantDetail("{$restaurant}").loyalty)
    }
}
