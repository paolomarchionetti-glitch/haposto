package com.haposto.data.loyalty

import java.time.Instant
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class LoyaltyTextsTest {

    @Test
    fun conditionsReadLikeTheSpecificationExamples() {
        assertEquals("Spesa minima di 15 € a persona", LoyaltyTexts.condition(LoyaltyCondition(ConditionKind.SPEND, 1500)))
        assertEquals(
            "Almeno una consumazione tra: pizza, primo, secondo",
            LoyaltyTexts.condition(LoyaltyCondition(ConditionKind.ONE_OF, types = listOf("PIZZA", "FIRST_COURSE", "MAIN_COURSE"))),
        )
        assertEquals(
            "Almeno due consumazioni diverse tra: antipasto, dolce",
            LoyaltyTexts.condition(LoyaltyCondition(ConditionKind.TWO_OF, types = listOf("STARTER", "DESSERT"))),
        )
    }

    @Test
    fun rewardsAreAlwaysPersonalAndCapped() {
        assertEquals("Omaggio: dolce", LoyaltyTexts.reward(RewardRules(RewardKind.GIFT, gift = "DESSERT")))
        assertEquals(
            "20% sulla tua consumazione, max 10 €",
            LoyaltyTexts.reward(RewardRules(RewardKind.DISCOUNT, percent = 20, capCents = 1000), forCustomer = true),
        )
        assertEquals(
            "20% sulla sua consumazione, max 10 €, con una spesa di almeno 25 €",
            LoyaltyTexts.reward(RewardRules(RewardKind.DISCOUNT, percent = 20, capCents = 1000, minSpendCents = 2500)),
        )
        assertEquals(
            "5 € di sconto alla visita dopo, con una spesa di almeno 15 €",
            LoyaltyTexts.reward(RewardRules(RewardKind.VOUCHER, amountCents = 500, minSpendCents = 1500)),
        )
    }

    @Test
    fun rewardUseListsEveryProtection() {
        val lines = LoyaltyTexts.rewardUse(
            RewardRules(RewardKind.GIFT, gift = "COFFEE", from = RewardFrom.NEXT_VISIT, weekdays = listOf(1, 2, 3), maxPerTable = 4),
        )
        assertEquals("Si usa dalla visita successiva", lines[0])
        assertEquals("Solo: lunedì, martedì, mercoledì", lines[1])
        assertEquals("Al massimo 4 premi per tavolo alla stessa visita", lines[2])
        assertEquals("Non cumulabile con altre offerte", lines[3])
        assertTrue(lines[4].startsWith("Valido 60 giorni"))
        assertEquals("Nessun limite di premi per tavolo", LoyaltyTexts.rewardUse(RewardRules(RewardKind.GIFT, gift = "COFFEE"))[2])
    }

    @Test
    fun doubleDayAndWeekdays() {
        assertEquals("Nessun giorno a timbro doppio", LoyaltyTexts.doubleDay(null))
        assertEquals("Timbro doppio il mercoledì a cena (18–23)", LoyaltyTexts.doubleDay(DoubleDay(3, DoubleSlot.DINNER)))
        assertEquals("dom", LoyaltyTexts.weekdayShort(7))
    }

    @Test
    fun euroFormatting() {
        assertEquals("10 €", LoyaltyTexts.euro(1000))
        assertEquals("7,50 €", LoyaltyTexts.euro(750))
        assertEquals("0,05 €", LoyaltyTexts.euro(5))
        assertEquals(750, LoyaltyTexts.parseEuroCents("7,50"))
        assertEquals(750, LoyaltyTexts.parseEuroCents(" 7.5 € "))
        assertEquals(800, LoyaltyTexts.parseEuroCents("8"))
        assertNull(LoyaltyTexts.parseEuroCents(""))
        assertNull(LoyaltyTexts.parseEuroCents("7,555"))
        assertNull(LoyaltyTexts.parseEuroCents("-3"))
        assertNull(LoyaltyTexts.parseEuroCents("dieci"))
    }

    @Test
    fun outcomesForStaff() {
        assertEquals(
            "+1 timbro · 4 su 10",
            LoyaltyTexts.outcome(StampMember("K4F7", StampOutcome.STAMPED, stampsAdded = 1, stamps = 4, required = 10)),
        )
        assertEquals(
            "+2 timbri (giorno doppio) · 10 su 10 · 🎁 premio sbloccato · 1 sulla tessera nuova",
            LoyaltyTexts.outcome(
                StampMember("K4F7", StampOutcome.STAMPED, stampsAdded = 2, doubleDay = true, stamps = 10, required = 10, rewardUnlocked = true, carry = 1),
            ),
        )
        assertEquals("già timbrato nelle ultime 4 ore: nessun timbro", LoyaltyTexts.outcome(StampMember("K4F7", StampOutcome.TOO_SOON)))
        assertEquals("gestisce il locale: escluso", LoyaltyTexts.outcome(StampMember(null, StampOutcome.SELF)))
    }

    @Test
    fun groupSummaryCountsExclusions() {
        val result = StampResult(
            ok = true,
            isGroup = true,
            people = 4,
            stamped = 2,
            members = listOf(
                StampMember("AAAA", StampOutcome.STAMPED),
                StampMember("BBBB", StampOutcome.STAMPED),
                StampMember("CCCC", StampOutcome.TOO_SOON),
                StampMember(null, StampOutcome.SELF),
            ),
        )
        assertEquals("Tavolo di 4 · 2 timbrati (1 già timbrato oggi, 1 gestisce il locale)", LoyaltyTexts.groupSummary(result))
        assertEquals(
            "Tavolo di 1 · 1 timbrato",
            LoyaltyTexts.groupSummary(StampResult(ok = true, isGroup = true, people = 1, stamped = 1, members = listOf(StampMember("AAAA", StampOutcome.STAMPED)))),
        )
    }

    @Test
    fun stampErrorsExplainWhatToDo() {
        val time: (Instant) -> String = { "21:30" }
        assertTrue(LoyaltyTexts.stampError(StampResult(ok = false, error = "TOKEN_USED"), time).contains("già stato usato"))
        assertEquals(
            "Codice sbagliato (restano 9 tentativi prima del blocco).",
            LoyaltyTexts.stampError(StampResult(ok = false, error = "INVALID_CODE", attemptsLeft = 9), time),
        )
        assertTrue(
            LoyaltyTexts.stampError(StampResult(ok = false, error = "CODE_LOCKED", lockedUntil = Instant.EPOCH), time).contains("fino alle 21:30"),
        )
    }

    @Test
    fun undoCountdownStopsAfterTwoMinutes() {
        val now = Instant.parse("2026-10-11T20:00:00Z")
        assertEquals("1:45", LoyaltyTexts.countdown(now.plusSeconds(105), now))
        assertEquals("0:05", LoyaltyTexts.countdown(now.plusSeconds(5), now))
        assertNull(LoyaltyTexts.countdown(now, now))
        assertNull(LoyaltyTexts.countdown(now.minusSeconds(1), now))
        assertNull(LoyaltyTexts.countdown(null, now))
    }

    @Test
    fun pactHasThreeLinesWithTheNotice() {
        val pact = LoyaltyTexts.pact(30)
        assertEquals(3, pact.size)
        assertTrue(pact[2].contains("30 giorni"))
    }

    @Test
    fun scanButtonOnlyWhenTheServerSaysSo() {
        assertTrue(!LoyaltyProgram.HIDDEN.canScan)
        assertTrue(!LoyaltyProgram(visible = true, level = LoyaltyLevel.NONE).canScan)
        assertTrue(LoyaltyProgram(visible = true, level = LoyaltyLevel.EXISTING).canScan)
        assertTrue(LoyaltyProgram(visible = true, level = LoyaltyLevel.REWARDS).canScan)
    }

    @Test
    fun onlyHapostoLoyaltyQrCodesAreAccepted() {
        val token = "0123456789abcdef0123456789abcdef"
        assertEquals(token, LoyaltyQr.tokenFrom(LoyaltyQr.encode(token)))
        assertEquals(token, LoyaltyQr.tokenFrom("HAPOSTO:TESSERA:" + token.uppercase()))
        assertNull(LoyaltyQr.tokenFrom("https://haposto.app/r/osteria"))
        assertNull(LoyaltyQr.tokenFrom(token))
        assertNull(LoyaltyQr.tokenFrom(LoyaltyQr.PREFIX + "123"))
        assertNull(LoyaltyQr.tokenFrom(null))
    }
}
