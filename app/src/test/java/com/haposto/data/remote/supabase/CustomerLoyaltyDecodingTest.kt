package com.haposto.data.remote.supabase

import com.haposto.data.loyalty.ConditionKind
import com.haposto.data.loyalty.GroupState
import com.haposto.data.loyalty.LoyaltyLevel
import com.haposto.data.loyalty.LoyaltyQr
import com.haposto.data.loyalty.RestaurantLoyaltyBox
import com.haposto.data.loyalty.RewardKind
import com.haposto.data.loyalty.StampOutcome
import com.haposto.data.loyalty.TokenState
import java.time.Instant
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test

/** JSON vero delle funzioni del cliente della migration 0018 (database locale con i dati di prova). */
class CustomerLoyaltyDecodingTest {

    private val rules = """{"reward": {"from": "SAME_VISIT", "gift": "DESSERT", "kind": "GIFT", "percent": null,
        "weekdays": null, "cap_cents": null, "cumulable": false, "valid_days": 60, "amount_cents": null, "max_per_table": 1,
        "min_spend_cents": null}, "version": 1, "condition": {"kind": "ONE_OF", "types": ["FIRST_COURSE", "PIZZA"],
        "min_spend_cents": null}, "double_day": null, "version_id": "56c7eb1a-3e81-4e00-a595-65b7a476df29",
        "accepted_at": "2026-10-11T16:48:25.499369+00:00", "stamps_required": 10, "inactivity_months": 6}"""

    private val reward = """{"code": "WU7V", "gift": null, "kind": "VOUCHER", "status": "AVAILABLE", "percent": null,
        "weekdays": [1, 2, 3], "cap_cents": null, "cumulable": false, "reward_id": "3daeee4a-7c10-45aa-92de-b7f5e582713b",
        "expires_at": "2026-12-10T16:02:42.322061+00:00", "usable_now": false,
        "unlocked_at": "2026-10-11T16:02:42.322061+00:00", "usable_from": "2026-10-11T20:02:42.322061+00:00",
        "amount_cents": 500, "max_per_table": null, "min_spend_cents": 1500}"""

    @Test
    fun accessDecidesWhatTheCustomerSees() {
        val fresh = decodeLoyaltyAccess("""{"level": "NEW", "visible": true, "has_cards": false}""")
        assertEquals(LoyaltyLevel.NEW, fresh.level)
        assertTrue(fresh.visible)
        assertFalse(fresh.hasCards)

        val hidden = decodeLoyaltyAccess("""{"level": "NONE", "visible": false, "has_cards": false}""")
        assertFalse(hidden.visible)
        assertEquals(LoyaltyLevel.NONE, decodeLoyaltyAccess("""{"level": "SOMETHING_NEW"}""").level)
    }

    @Test
    fun restaurantBoxHiddenStartAndCard() {
        assertSame(RestaurantLoyaltyBox.HIDDEN, decodeRestaurantLoyaltyBox("""{"available": false}"""))

        val start = decodeRestaurantLoyaltyBox(
            """{"card": null, "code": null, "rules": $rules, "status": "ACTIVE", "rewards": [], "available": true,
              "can_start": true, "closing_until": null}""",
        )
        assertTrue(start.available && start.canStart)
        assertNull(start.card)
        assertNull(start.code)
        assertEquals(10, start.rules!!.stampsRequired)
        assertEquals(RewardKind.GIFT, start.rules!!.reward.kind)
        assertEquals("DESSERT", start.rules!!.reward.gift)

        val withCard = decodeRestaurantLoyaltyBox(
            """{"card": {"rules": $rules, "stamps": 1, "started_at": "2026-10-11T16:48:25.499369+00:00",
              "last_stamp_at": "2026-10-11T16:48:25.499369+00:00"}, "code": "WU7V", "rules": $rules, "status": "CLOSING",
              "rewards": [$reward], "available": true, "can_start": false, "closing_until": "2026-11-10T16:48:25+00:00"}""",
        )
        assertEquals("WU7V", withCard.code)
        assertEquals(1, withCard.card!!.stamps)
        assertEquals(ConditionKind.ONE_OF, withCard.card!!.rules!!.condition.kind)
        assertEquals("CLOSING", withCard.status)
        assertEquals(Instant.parse("2026-11-10T16:48:25Z"), withCard.closingUntil)
        val voucher = withCard.rewards.single()
        assertEquals(RewardKind.VOUCHER, voucher.rules.kind)
        assertFalse(voucher.usableNow)
        assertEquals(listOf(1, 2, 3), voucher.rules.weekdays)
    }

    @Test
    fun personalTokenAndItsStatus() {
        val token = decodeVisitToken(
            """{"code": "BQMC6P", "token": "248aa18301cdf70c8d24525147648f47", "seconds": 60,
              "expires_at": "2026-10-11T16:49:25.499369+00:00"}""",
        )
        assertEquals("BQMC6P", token.code)
        assertEquals(60, token.seconds)
        assertEquals("haposto:tessera:248aa18301cdf70c8d24525147648f47", token.qrContent)
        assertEquals(token.token, LoyaltyQr.tokenFrom(token.qrContent))

        val waiting = decodeTokenStatus("""{"result": null, "status": "WAITING", "expires_at": "2026-10-11T16:49:25.499369+00:00"}""")
        assertEquals(TokenState.WAITING, waiting.state)
        assertNull(waiting.result)

        val used = decodeTokenStatus(
            """{"result": {"code": "WU7V", "carry": 0, "stamps": 1, "outcome": "STAMPED", "required": 10,
              "condition": {"kind": "ONE_OF", "types": ["FIRST_COURSE", "PIZZA"], "min_spend_cents": null},
              "double_day": false, "stamps_added": 1, "reward_unlocked": false}, "status": "USED",
              "expires_at": "2026-10-11T16:49:25.499369+00:00"}""",
        )
        assertEquals(TokenState.USED, used.state)
        assertEquals(StampOutcome.STAMPED, used.result!!.outcome)
        assertEquals(1, used.result!!.stamps)
        assertEquals(10, used.result!!.required)
    }

    @Test
    fun groupCreateJoinAndStatus() {
        val group = decodeLoyaltyGroup(
            """{"code": "XDNQKB", "token": "2914aef9ee4d4fec5b439bc3c37e1baa", "members": 1, "seconds": 60,
              "group_id": "759dcbdf-f42a-483e-9760-10a1737b31d9", "expires_at": "2026-10-11T16:49:25.499369+00:00",
              "join_until": "2026-10-11T16:58:25.499369+00:00", "group_expires_at": "2026-10-11T17:48:25.499369+00:00"}""",
        )
        assertEquals("759dcbdf-f42a-483e-9760-10a1737b31d9", group.groupId)
        assertEquals("XDNQKB", group.token.code)
        assertEquals(Instant.parse("2026-10-11T16:49:25.499369Z"), group.token.expiresAt)
        assertEquals(Instant.parse("2026-10-11T16:58:25.499369Z"), group.joinUntil)
        assertEquals(Instant.parse("2026-10-11T17:48:25.499369Z"), group.expiresAt)
        assertEquals(1, group.members)

        val joined = decodeJoinedGroup(
            """{"members": 2, "group_id": "759dcbdf-f42a-483e-9760-10a1737b31d9", "expires_at": "2026-10-11T17:48:25.499369+00:00",
              "restaurant_id": "10000000-0000-0000-0000-000000000006", "restaurant_name": "Linea Cucina Demo"}""",
        )
        assertEquals("Linea Cucina Demo", joined.restaurantName)
        assertEquals(2, joined.members)

        val open = decodeGroupStatus(
            """{"leader": false, "result": null, "status": "OPEN", "members": 2, "group_id": "759dcbdf-f42a-483e-9760-10a1737b31d9",
              "expires_at": "2026-10-11T17:48:25.499369+00:00", "join_until": "2026-10-11T16:58:25.499369+00:00",
              "restaurant_id": "10000000-0000-0000-0000-000000000006"}""",
        )
        assertEquals(GroupState.OPEN, open.state)
        assertFalse(open.leader)
        assertNull(open.result)

        val used = decodeGroupStatus(
            """{"leader": true, "result": {"undone": false, "outcome": "STAMPED", "double_day": false, "stamps_added": 1,
              "reward_unlocked": false}, "status": "USED", "members": 2, "group_id": "759dcbdf-f42a-483e-9760-10a1737b31d9",
              "expires_at": "2026-10-11T17:48:25.499369+00:00", "join_until": "2026-10-11T16:58:25.499369+00:00",
              "restaurant_id": "10000000-0000-0000-0000-000000000006"}""",
        )
        assertEquals(GroupState.USED, used.state)
        assertTrue(used.leader)
        assertEquals(StampOutcome.STAMPED, used.result!!.outcome)
        assertEquals(1, used.result!!.stampsAdded)
    }

    @Test
    fun myCardsWithResetDateAndRewards() {
        val cards = decodeMyLoyaltyCards(
            """[{"card": {"rules": $rules, "stamps": 1, "reset_at": "2027-04-11T16:48:25.499369+00:00",
              "started_at": "2026-10-11T16:48:25.499369+00:00", "last_stamp_at": "2026-10-11T16:48:25.499369+00:00"},
              "city": "Fano", "code": "WU7V", "rewards": [$reward], "closing_until": null,
              "restaurant_id": "10000000-0000-0000-0000-000000000006", "program_status": "ACTIVE",
              "restaurant_name": "Linea Cucina Demo"}]""",
        )
        val card = cards.single()
        assertEquals("Linea Cucina Demo", card.restaurantName)
        assertEquals("Fano", card.city)
        assertEquals("ACTIVE", card.programStatus)
        assertEquals(Instant.parse("2027-04-11T16:48:25.499369Z"), card.card!!.resetAt)
        assertEquals(10, card.card!!.rules!!.stampsRequired)
        assertEquals(500, card.rewards.single().rules.amountCents)

        assertTrue(decodeMyLoyaltyCards("[]").isEmpty())
    }
}
