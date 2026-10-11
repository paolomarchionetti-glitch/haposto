package com.haposto.data.remote.supabase

import com.haposto.data.loyalty.ConditionKind
import com.haposto.data.loyalty.DoubleSlot
import com.haposto.data.loyalty.LoyaltyLevel
import com.haposto.data.loyalty.RewardFrom
import com.haposto.data.loyalty.RewardKind
import com.haposto.data.loyalty.StampOutcome
import java.time.Instant
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** JSON vero delle funzioni della migration 0018 (database locale con i dati di prova). */
class LoyaltyDecodingTest {

    private val limits = """
        "limits": {"stamps_max": 20, "stamps_min": 5, "undo_minutes": 2, "spend_max_cents": 5000, "spend_min_cents": 500,
          "stamp_gap_hours": 4, "group_max_people": 20, "inactivity_months": 6, "reward_valid_days": 60,
          "voucher_max_cents": 2000, "voucher_min_cents": 200, "closing_notice_days": 30, "discount_percent_max": 50,
          "discount_percent_min": 5, "discount_cap_max_cents": 5000, "discount_cap_min_cents": 500}
    """.trimIndent()

    private val condition = """{"kind": "ONE_OF", "types": ["FIRST_COURSE", "MAIN_COURSE", "PIZZA"], "min_spend_cents": null}"""

    @Test
    fun activeProgramWithItsRules() {
        val program = decodeLoyaltyProgram(
            """{"level": "NEW", $limits, "status": "ACTIVE",
              "current": {"reward": {"from": "SAME_VISIT", "gift": null, "kind": "DISCOUNT", "percent": 20, "weekdays": [5, 6, 7],
                "cap_cents": 1000, "cumulable": false, "valid_days": 60, "amount_cents": null, "max_per_table": 4, "min_spend_cents": null},
                "version": 1, "condition": $condition, "double_day": {"slot": "DINNER", "weekday": 3},
                "version_id": "a04651cc-c3d4-42f1-a416-62c7dd611ace", "accepted_at": "2026-10-11T16:02:42.322061+00:00",
                "stamps_required": 10, "inactivity_months": 6},
              "reports": {"warn": 3, "count": 0, "suspend": 5, "window_days": 60}, "visible": true,
              "versions": [{"version": 1, "accepted_at": "2026-10-11T16:02:42.322061+00:00"}], "can_publish": true,
              "active_cards": 0, "closing_until": null, "closing_reason": null, "publish_blocker": null,
              "suspended_until": null, "rewards_available": 0}""",
        )

        assertTrue(program.visible)
        assertTrue(program.canScan)
        assertEquals(LoyaltyLevel.NEW, program.level)
        assertEquals("ACTIVE", program.status)
        val rules = program.current!!
        assertEquals(10, rules.stampsRequired)
        assertEquals(ConditionKind.ONE_OF, rules.condition.kind)
        assertEquals(listOf("FIRST_COURSE", "MAIN_COURSE", "PIZZA"), rules.condition.types)
        assertEquals(DoubleSlot.DINNER, rules.doubleDay!!.slot)
        assertEquals(RewardKind.DISCOUNT, rules.reward.kind)
        assertEquals(listOf(5, 6, 7), rules.reward.weekdays)
        assertEquals(4, rules.reward.maxPerTable)
        assertEquals(1, program.versions.single().version)
        assertEquals(5, program.reports!!.suspend)
        assertEquals(30, program.limits.closingNoticeDays)
    }

    @Test
    fun programNotYetActivatedAndHiddenProgram() {
        val none = decodeLoyaltyProgram(
            """{"level": "NONE", $limits, "status": "NONE", "current": null,
              "reports": {"warn": 3, "count": 0, "suspend": 5, "window_days": 60}, "visible": true, "versions": [],
              "can_publish": true, "active_cards": 0, "closing_until": null, "closing_reason": null,
              "publish_blocker": null, "suspended_until": null, "rewards_available": 0}""",
        )
        assertTrue(none.visible && none.canPublish)
        assertFalse(none.canScan)
        assertNull(none.current)

        val hidden = decodeLoyaltyProgram("""{"visible": false}""")
        assertFalse(hidden.visible)
        assertFalse(hidden.canScan)
    }

    @Test
    fun singleStamp() {
        val result = decodeStampResult(
            """{"ok": true, "kind": "PERSONAL", "people": 1, "stamps": 1, "members": [{"code": "JBY7", "carry": 0, "stamps": 1,
              "outcome": "STAMPED", "required": 10, "condition": $condition, "double_day": false, "stamps_added": 1,
              "reward_unlocked": false}], "rewards": [], "scan_id": "822ba2a4-e2a6-4ae4-b21f-87cde22c086e", "stamped": 1,
              "undo_until": "2026-10-11T16:04:42.322061+00:00"}""",
        )
        assertTrue(result.ok)
        assertFalse(result.isGroup)
        assertEquals("JBY7", result.members.single().code)
        assertEquals(StampOutcome.STAMPED, result.members.single().outcome)
        assertEquals(10, result.members.single().required)
        assertEquals(Instant.parse("2026-10-11T16:04:42.322061Z"), result.undoUntil)
    }

    @Test
    fun groupStampWithRewardAndExcludedManager() {
        val result = decodeStampResult(
            """{"ok": true, "kind": "GROUP", "people": 4, "stamps": 3, "members": [
              {"code": "JBY7", "carry": 0, "stamps": 10, "outcome": "STAMPED", "required": 10, "condition": $condition,
               "double_day": false, "stamps_added": 1, "reward_unlocked": true},
              {"code": "RKUG", "carry": 0, "stamps": 1, "outcome": "STAMPED", "required": 10, "condition": $condition,
               "double_day": false, "stamps_added": 1, "reward_unlocked": false},
              {"code": "NXDM", "carry": 0, "stamps": 1, "outcome": "STAMPED", "required": 10, "condition": $condition,
               "double_day": false, "stamps_added": 1, "reward_unlocked": false},
              {"code": null, "carry": 0, "stamps": null, "outcome": "SELF", "required": null, "condition": null,
               "double_day": false, "stamps_added": 0, "reward_unlocked": false}],
              "rewards": [{"code": "JBY7", "gift": null, "kind": "DISCOUNT", "status": "AVAILABLE", "percent": 20,
               "weekdays": [5, 6, 7], "cap_cents": 1000, "cumulable": false, "reward_id": "3daeee4a-7c10-45aa-92de-b7f5e582713b",
               "expires_at": "2026-12-10T16:02:42.322061+00:00", "usable_now": true,
               "unlocked_at": "2026-10-11T16:02:42.322061+00:00", "usable_from": "2026-10-11T16:02:42.322061+00:00",
               "amount_cents": null, "max_per_table": 4, "min_spend_cents": null}],
              "scan_id": "5133ef91-c063-471d-9f42-11ab64c5be4f", "stamped": 3, "undo_until": "2026-10-11T16:04:42.322061+00:00"}""",
        )
        assertTrue(result.isGroup)
        assertEquals(4, result.people)
        assertEquals(3, result.stamped)
        assertEquals(StampOutcome.SELF, result.members.last().outcome)
        assertNull(result.members.last().code)
        val reward = result.rewards.single()
        assertEquals("JBY7", reward.code)
        assertTrue(reward.usableNow)
        assertEquals(RewardFrom.SAME_VISIT, reward.rules.from)
        assertEquals(1000, reward.rules.capCents)
    }

    @Test
    fun rejectedScansAreNotExceptions() {
        val badCode = decodeStampResult("""{"ok": false, "error": "INVALID_CODE", "attempts_left": 9}""")
        assertFalse(badCode.ok)
        assertEquals("INVALID_CODE", badCode.error)
        assertEquals(9, badCode.attemptsLeft)
        assertEquals("TOKEN_USED", decodeStampResult("""{"ok": false, "error": "TOKEN_USED"}""").error)
    }

    @Test
    fun statsAndCards() {
        val stats = decodeLoyaltyStats(
            """{"days": 30, "scans": 2, "people": 4, "stamps": 4, "by_hour": [{"hour": 13, "scans": 1, "weekday": 7},
              {"hour": 18, "scans": 1, "weekday": 7}], "group_scans": 1, "near_reward": {"one": 0, "two": 0},
              "active_cards": 2, "rewards_used": 1, "cards_started": 3, "double_stamps": 0, "new_customers": 3,
              "discount_cents": 650, "rewards_expired": 0, "returning_people": 1, "rewards_unlocked": 1}""",
        )
        assertEquals(2, stats.scans)
        assertEquals(1, stats.groupScans)
        assertEquals(650, stats.discountCents)
        assertEquals(2, stats.byHour.size)

        val cards = decodeLoyaltyCards(
            """[{"code": "RKUG", "stamps": 1, "version": 1, "required": 10, "started_at": "2026-10-11T16:02:42.322061+00:00",
              "last_stamp_at": "2026-10-11T16:02:42.322061+00:00", "rewards_available": 0}]""",
        )
        assertEquals("RKUG", cards.single().code)
        assertEquals(10, cards.single().required)
    }

    @Test
    fun nextVisitRewardIsRecognised() {
        val result = decodeStampResult(
            """{"ok": true, "kind": "PERSONAL", "people": 1, "stamped": 1, "members": [], "rewards": [{"reward_id": "r1",
              "kind": "VOUCHER", "amount_cents": 500, "min_spend_cents": 1500, "unlocked_at": "2026-10-11T16:00:00Z",
              "usable_from": "2026-10-11T20:00:00Z", "expires_at": "2026-12-10T16:00:00Z", "usable_now": false}]}""",
        )
        assertEquals(RewardFrom.NEXT_VISIT, result.rewards.single().rules.from)
        assertFalse(result.rewards.single().usableNow)
    }
}
