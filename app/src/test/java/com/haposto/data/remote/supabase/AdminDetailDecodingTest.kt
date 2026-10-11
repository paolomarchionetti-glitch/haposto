package com.haposto.data.remote.supabase

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/** Schede del pannello admin lette dal JSON delle funzioni SQL (con e senza la migration 0018). */
class AdminDetailDecodingTest {

    private val restaurant = """
        "restaurant": {"id": "10000000-0000-0000-0000-000000000001", "city": "Pesaro", "name": "Osteria Levante Demo",
          "slug": "osteria-levante-demo-pesaro", "address": "Via Demo 12", "category": "Cucina italiana",
          "latitude": 43.9102, "province": "PU", "longitude": 12.9149, "created_at": "2026-10-11T15:12:41.241145+00:00",
          "data_source": "MANUAL", "phone_number": "+390721000001", "phone_public": true,
          "partnership_status": "ACTIVE_PARTNER"},
        "plan_code": "RESTAURANT_PRO", "plan_source": "BETA", "plan_valid_until": "2027-06-30T23:59:59+00:00",
        "partner_since": "2026-10-11T15:12:41.241145+00:00",
        "stats_30_days": {"call_taps": 0, "detail_views": 3, "live_updates": 0, "directions_taps": 0}
    """.trimIndent()

    @Test
    fun restaurantDetailReadsLoyaltyTesterAndStatus() {
        val detail = decodeAdminRestaurantDetail(
            """{$restaurant, "loyalty": {"status": "ACTIVE", "tester": true, "current": null, "versions": 2,
               "active_cards": 5, "closing_until": null, "reports_60_days": 0, "suspended_until": null}}""",
        )

        assertEquals(true, detail.loyaltyTester)
        assertEquals("ACTIVE", detail.loyaltyStatus)
        assertEquals("BETA", detail.planSource)
        assertEquals(3, detail.stats30Days["detail_views"])
    }

    @Test
    fun restaurantDetailBefore0018HasNoLoyaltySection() {
        val detail = decodeAdminRestaurantDetail("{$restaurant}")

        assertNull(detail.loyaltyTester)
        assertNull(detail.loyaltyStatus)
    }

    @Test
    fun userDetailReadsLoyaltyTesterFromProfile() {
        val user = decodeAdminUserDetail(userJson(""", "loyalty_tester": true"""))

        assertEquals(true, user.loyaltyTester)
        assertEquals("test-user@haposto.test", user.email)
    }

    @Test
    fun userDetailBefore0018HasNoLoyaltySection() {
        assertNull(decodeAdminUserDetail(userJson("")).loyaltyTester)
    }

    private fun userJson(loyaltyField: String) = """
        {"user": {"id": "a1afb271-f4ed-4dc0-a0e4-ba1b5440d1aa", "email": "test-user@haposto.test",
                  "created_at": "2026-10-11T15:12:37.545811+00:00", "last_sign_in_at": null},
         "profile": {"id": "a1afb271-f4ed-4dc0-a0e4-ba1b5440d1aa", "blocked_at": null, "display_name": null,
                     "blocked_reason": null, "marketing_opt_in": false, "is_platform_admin": false,
                     "accepted_terms_version": null$loyaltyField},
         "consumer_plan": "CONSUMER_FREE", "restaurants": [], "claims": [], "subscriptions": [],
         "favorites": 0, "active_alerts": 0, "recent_activity": []}
    """.trimIndent()
}
