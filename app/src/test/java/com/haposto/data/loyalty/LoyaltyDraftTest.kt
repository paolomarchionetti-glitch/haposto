package com.haposto.data.loyalty

import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class LoyaltyDraftTest {

    private val limits = LoyaltyLimits()

    @Test
    fun defaultDraftIsValid() {
        assertTrue(LoyaltyDraft().problems(limits).isEmpty())
    }

    @Test
    fun limitsOfTheRestaurantChoicesAreChecked() {
        assertEquals(1, LoyaltyDraft(stampsRequired = 4).problems(limits).size)
        assertEquals(1, LoyaltyDraft(stampsRequired = 21).problems(limits).size)
        assertEquals(1, LoyaltyDraft(conditionKind = ConditionKind.SPEND, minSpendEuro = 4).problems(limits).size)
        assertEquals(1, LoyaltyDraft(conditionKind = ConditionKind.ONE_OF, types = emptySet()).problems(limits).size)
        assertEquals(1, LoyaltyDraft(conditionKind = ConditionKind.TWO_OF, types = setOf("PIZZA")).problems(limits).size)
        assertEquals(1, LoyaltyDraft(rewardKind = RewardKind.DISCOUNT, percent = 60).problems(limits).size)
        assertEquals(1, LoyaltyDraft(rewardKind = RewardKind.DISCOUNT, capEuro = 60).problems(limits).size)
        assertEquals(1, LoyaltyDraft(rewardKind = RewardKind.VOUCHER, voucherEuro = 5, voucherMinSpendEuro = 9).problems(limits).size)
        assertEquals(1, LoyaltyDraft(rewardKind = RewardKind.VOUCHER, voucherEuro = 25, voucherMinSpendEuro = 50).problems(limits).size)
        assertEquals(1, LoyaltyDraft(weekdays = setOf(1, 2)).problems(limits).size)
        assertEquals(1, LoyaltyDraft(maxPerTable = 11).problems(limits).size)
        assertTrue(LoyaltyDraft(maxPerTable = null).problems(limits).isEmpty())
    }

    @Test
    fun voucherIsAlwaysFromTheNextVisit() {
        val draft = LoyaltyDraft(rewardKind = RewardKind.VOUCHER, from = RewardFrom.SAME_VISIT)
        assertEquals(RewardFrom.NEXT_VISIT, draft.effectiveFrom)
        assertEquals("NEXT_VISIT", draft.toJson()["reward"]!!.jsonObject["from"]!!.jsonPrimitive.content)
    }

    @Test
    fun jsonMatchesWhatPublishLoyaltyVersionExpects() {
        val json = LoyaltyDraft(
            stampsRequired = 8,
            conditionKind = ConditionKind.TWO_OF,
            types = setOf("PIZZA", "STARTER"),
            doubleWeekday = 3,
            doubleSlot = DoubleSlot.DINNER,
            rewardKind = RewardKind.DISCOUNT,
            percent = 20,
            capEuro = 10,
            discountMinSpendEuro = 25,
            from = RewardFrom.SAME_VISIT,
            weekdays = setOf(4, 1, 2),
            maxPerTable = 3,
            cumulable = true,
        ).toJson()

        assertEquals(8, json["stamps_required"]!!.jsonPrimitive.int)
        val condition = json["condition"]!!.jsonObject
        assertEquals("TWO_OF", condition["kind"]!!.jsonPrimitive.content)
        // Tipologie nell'ordine della lista, senza spesa minima.
        assertEquals(listOf("STARTER", "PIZZA"), condition["types"]!!.jsonArray.map { it.jsonPrimitive.content })
        assertTrue("min_spend_cents" !in condition)
        assertEquals(3, json["double_day"]!!.jsonObject["weekday"]!!.jsonPrimitive.int)
        val reward = json["reward"]!!.jsonObject
        assertEquals(20, reward["percent"]!!.jsonPrimitive.int)
        assertEquals(1000, reward["cap_cents"]!!.jsonPrimitive.int)
        assertEquals(2500, reward["min_spend_cents"]!!.jsonPrimitive.int)
        assertTrue("gift" !in reward && "amount_cents" !in reward)
        assertEquals(listOf(1, 2, 4), reward["weekdays"]!!.jsonArray.map { it.jsonPrimitive.int })
        assertEquals(3, reward["max_per_table"]!!.jsonPrimitive.int)
        assertEquals("true", reward["cumulable"]!!.jsonPrimitive.content)
    }

    @Test
    fun noDoubleDayAllWeekdaysAndNoTableLimitAreNulls() {
        val json = LoyaltyDraft(rewardKind = RewardKind.GIFT, gift = "COFFEE", weekdays = emptySet(), maxPerTable = null).toJson()
        assertEquals(JsonNull, json["double_day"])
        val reward = json["reward"]!!.jsonObject
        assertEquals(JsonNull, reward["weekdays"])
        assertEquals(JsonNull, reward["max_per_table"])
        assertEquals("COFFEE", reward["gift"]!!.jsonPrimitive.content)
        assertTrue("min_spend_cents" !in reward)
    }

    @Test
    fun spendConditionSendsOnlyTheAmount() {
        val condition = LoyaltyDraft(conditionKind = ConditionKind.SPEND, minSpendEuro = 15).toJson()["condition"]!!.jsonObject
        assertEquals(1500, condition["min_spend_cents"]!!.jsonPrimitive.int)
        assertTrue("types" !in condition)
    }

    @Test
    fun changingTheRulesStartsFromTheCurrentVersion() {
        val rules = LoyaltyRules(
            version = 2,
            stampsRequired = 12,
            condition = LoyaltyCondition(ConditionKind.SPEND, minSpendCents = 2000),
            doubleDay = DoubleDay(5, DoubleSlot.LUNCH),
            reward = RewardRules(RewardKind.VOUCHER, amountCents = 700, minSpendCents = 2000, from = RewardFrom.NEXT_VISIT, weekdays = listOf(1, 2, 3), maxPerTable = 2),
        )
        val draft = LoyaltyDraft.from(rules)
        assertEquals(12, draft.stampsRequired)
        assertEquals(20, draft.minSpendEuro)
        assertEquals(5, draft.doubleWeekday)
        assertEquals(7, draft.voucherEuro)
        assertEquals(20, draft.voucherMinSpendEuro)
        assertEquals(setOf(1, 2, 3), draft.weekdays)
        val back = draft.toRules(limits, version = 3)
        assertEquals(rules.condition, back.condition)
        assertEquals(rules.doubleDay, back.doubleDay)
        assertEquals(rules.reward.copy(validDays = limits.rewardValidDays), back.reward)
    }
}
