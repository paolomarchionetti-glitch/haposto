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

    // Lato cliente.

    private val rules = LoyaltyRules(
        version = 1,
        stampsRequired = 10,
        condition = LoyaltyCondition(ConditionKind.SPEND, 1500),
        doubleDay = null,
        reward = RewardRules(RewardKind.DISCOUNT, percent = 20, capCents = 1000),
    )

    @Test
    fun customerSeesProgressAndTheRewardForHim() {
        assertEquals("10 timbri → 20% sulla tua consumazione, max 10 €", LoyaltyTexts.summary(rules))
        assertEquals("4 su 10", LoyaltyTexts.progress(4, 10))
        assertEquals("0 su 10", LoyaltyTexts.progress(-1, 10))
        assertEquals("BQM C6P", LoyaltyTexts.codeSpaced("BQMC6P"))
        assertEquals("K4F7", LoyaltyTexts.codeSpaced("K4F7"))
    }

    @Test
    fun qrCountdownNeverGoesNegative() {
        val now = Instant.parse("2026-10-11T12:00:00Z")
        assertEquals(42L, LoyaltyTexts.secondsLeft(now.plusSeconds(42), now))
        assertEquals(0L, LoyaltyTexts.secondsLeft(now.minusSeconds(5), now))
        assertEquals(0L, LoyaltyTexts.secondsLeft(null, now))
    }

    /** §6.1 punto 3: «✓ +1 timbro · 4 su 10», «+2, giorno doppio», «🎁 Premio sbloccato». */
    @Test
    fun customerResultReadsLikeTheSpecification() {
        assertEquals(
            "✓ +1 timbro · 4 su 10",
            LoyaltyTexts.customerResult(StampMember("K4F7", StampOutcome.STAMPED, stampsAdded = 1, stamps = 4, required = 10)),
        )
        assertEquals(
            "✓ +2 timbri, giorno doppio · 10 su 10 · 1 sulla tessera nuova · 🎁 Premio sbloccato",
            LoyaltyTexts.customerResult(
                StampMember(
                    "K4F7", StampOutcome.STAMPED, stampsAdded = 2, doubleDay = true, stamps = 10, required = 10,
                    rewardUnlocked = true, carry = 1,
                ),
            ),
        )
        assertEquals(
            "Hai già avuto un timbro qui nelle ultime 4 ore: questa volta niente timbro.",
            LoyaltyTexts.customerResult(StampMember("K4F7", StampOutcome.TOO_SOON)),
        )
        assertEquals(
            "Gestisci questo locale: la sua tessera non è per te.",
            LoyaltyTexts.customerResult(StampMember(null, StampOutcome.SELF)),
        )
    }

    @Test
    fun groupResultForEachMember() {
        assertEquals(
            "✓ +1 timbro",
            LoyaltyTexts.groupResult(GroupResult(StampOutcome.STAMPED, 1, doubleDay = false, undone = false, rewardUnlocked = false)),
        )
        assertEquals(
            "✓ +2 timbri, giorno doppio · 🎁 Premio sbloccato",
            LoyaltyTexts.groupResult(GroupResult(StampOutcome.STAMPED, 2, doubleDay = true, undone = false, rewardUnlocked = true)),
        )
        assertEquals(
            "Lo staff ha annullato la scansione del tavolo: nessun timbro.",
            LoyaltyTexts.groupResult(GroupResult(StampOutcome.STAMPED, 1, doubleDay = false, undone = true, rewardUnlocked = false)),
        )
    }

    @Test
    fun closingResetAndRewardsForTheCustomer() {
        val date: (Instant) -> String = { "10/11/2026" }
        assertNull(LoyaltyTexts.customerStatus("ACTIVE", null, date))
        assertEquals(
            "Il locale chiude la tessera: puoi completarla entro il 10/11/2026.",
            LoyaltyTexts.customerStatus("CLOSING", Instant.EPOCH, date),
        )
        assertEquals(
            "La tessera di questo locale è finita: restano i premi da usare.",
            LoyaltyTexts.customerStatus("SUSPENDED", null, date),
        )
        assertEquals("Se non torni, i timbri si azzerano il 10/11/2026.", LoyaltyTexts.resetNotice(Instant.EPOCH, date))
        assertNull(LoyaltyTexts.resetNotice(null, date))

        val now = Instant.parse("2026-10-11T12:00:00Z")
        val voucher = LoyaltyReward(
            rewardId = "r1",
            code = "K4F7",
            rules = RewardRules(RewardKind.VOUCHER, amountCents = 500, minSpendCents = 1500, from = RewardFrom.NEXT_VISIT),
            unlockedAt = now,
            usableFrom = now.plusSeconds(4 * 3600),
            expiresAt = now.plusSeconds(60L * 86_400),
            usableNow = false,
        )
        assertEquals(
            listOf(
                "🎁 5 € di sconto alla visita dopo, con una spesa di almeno 15 €",
                "Si usa dalla prossima visita.",
                "Valido fino al 10/11/2026",
            ),
            LoyaltyTexts.customerReward(voucher, now, date),
        )
        val notToday = voucher.copy(usableFrom = now.minusSeconds(60), rules = voucher.rules.copy(weekdays = listOf(1, 2, 3)))
        assertEquals("Oggi non si usa: solo lunedì, martedì, mercoledì.", LoyaltyTexts.customerReward(notToday, now, date)[1])
        assertEquals(
            "Si usa anche oggi: dillo alla cassa prima di pagare.",
            LoyaltyTexts.customerReward(voucher.copy(usableNow = true), now, date)[1],
        )
    }

    /** T48 e T59. */
    @Test
    fun reportButtonsAndPrivacyNotice() {
        assertEquals("Non hanno voluto timbrare", LoyaltyTexts.reportKind(LoyaltyReportKind.NO_STAMP))
        assertEquals("Non mi hanno riconosciuto il premio", LoyaltyTexts.reportKind(LoyaltyReportKind.REWARD_REFUSED))
        val notice = LoyaltyTexts.PRIVACY_NOTICE.joinToString(" ")
        assertTrue(notice.contains("codice anonimo"))
        assertTrue(notice.contains("24 mesi"))
        assertTrue(notice.contains("GPS"))
    }
}
