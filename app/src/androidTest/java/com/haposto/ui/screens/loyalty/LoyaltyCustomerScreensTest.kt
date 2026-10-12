package com.haposto.ui.screens.loyalty

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollTo
import com.haposto.data.loyalty.ConditionKind
import com.haposto.data.loyalty.LoyaltyCondition
import com.haposto.data.loyalty.LoyaltyReportKind
import com.haposto.data.loyalty.LoyaltyRules
import com.haposto.data.loyalty.MyCard
import com.haposto.data.loyalty.RestaurantLoyaltyBox
import com.haposto.data.loyalty.RewardKind
import com.haposto.data.loyalty.RewardRules
import com.haposto.data.loyalty.StampMember
import com.haposto.data.loyalty.StampOutcome
import com.haposto.data.loyalty.VisitToken
import com.haposto.ui.theme.HaPostoTheme
import java.time.Instant
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

class LoyaltyCustomerScreensTest {

    @get:Rule
    val composeRule = createComposeRule()

    private val rules = LoyaltyRules(
        version = 1,
        stampsRequired = 10,
        condition = LoyaltyCondition(ConditionKind.SPEND, 1500),
        doubleDay = null,
        reward = RewardRules(RewardKind.DISCOUNT, percent = 20, capCents = 1000),
    )

    private fun show(content: @Composable () -> Unit) {
        composeRule.setContent {
            HaPostoTheme {
                Column(Modifier.verticalScroll(rememberScrollState())) { content() }
            }
        }
    }

    /** §6.1: QR con codice di riserva leggibile e «👥 Siamo in gruppo». */
    @Test
    fun qr_showsBackupCodeAndGroupButton() {
        var group = false
        val token = VisitToken("248aa18301cdf70c8d24525147648f47", "BQMC6P", Instant.now().plusSeconds(60), 60)
        show {
            LoyaltyQrContent(
                state = LoyaltyQrState(starting = false, token = token),
                restaurantName = "Linea Cucina Demo",
                onGroup = { group = true },
                onRestart = {},
                onDone = {},
            )
        }
        composeRule.onNodeWithText("BQM C6P").performScrollTo()
        composeRule.onNode(hasText("Siamo in gruppo", substring = true) and hasClickAction()).performScrollTo().performClick()
        composeRule.runOnIdle { assertTrue(group) }
    }

    /** §6.1 punto 3: appena lo staff scansiona, «✓ +1 timbro · 4 su 10». */
    @Test
    fun qr_showsTheStampAsSoonAsTheStaffScans() {
        var done = false
        show {
            LoyaltyQrContent(
                state = LoyaltyQrState(
                    starting = false,
                    result = StampMember("K4F7", StampOutcome.STAMPED, stampsAdded = 1, stamps = 4, required = 10),
                ),
                restaurantName = null,
                onGroup = {},
                onRestart = {},
                onDone = { done = true },
            )
        }
        composeRule.onNodeWithText("✓ +1 timbro · 4 su 10").performScrollTo()
        composeRule.onNodeWithText("Fatto").performScrollTo().performClick()
        composeRule.runOnIdle { assertTrue(done) }
    }

    /** T61: senza account il riquadro si vede, ma «Mostra il mio QR» porta all'accesso. */
    @Test
    fun box_signedOutAsksToSignInOnlyWhenNeeded() {
        var qr = 0
        show {
            LoyaltyRestaurantBoxContent(
                state = LoyaltyBoxState(box = RestaurantLoyaltyBox(available = true, canStart = true, status = "ACTIVE", rules = rules)),
                signedIn = false,
                onShowQr = { qr++ },
                onGroup = {},
                onJoin = {},
                onReport = {},
                onLeave = {},
            )
        }
        composeRule.onNodeWithText("10 timbri → 20% sulla tua consumazione, max 10 €").performScrollTo()
        composeRule.onNodeWithText("Accedi con Google per raccogliere i timbri: è gratis.").performScrollTo()
        composeRule.onNodeWithText("Mostra il mio QR").performScrollTo().performClick()
        composeRule.runOnIdle { assertEquals(1, qr) }
    }

    /** T48: due tasti senza testo, con conferma; T27: avanzamento della propria tessera. */
    @Test
    fun box_withCardShowsProgressAndSendsReportAfterConfirm() {
        var reported: LoyaltyReportKind? = null
        show {
            LoyaltyRestaurantBoxContent(
                state = LoyaltyBoxState(
                    box = RestaurantLoyaltyBox(
                        available = true,
                        canStart = true,
                        status = "ACTIVE",
                        rules = rules,
                        code = "WU7V",
                        card = MyCard(stamps = 4, startedAt = null, lastStampAt = null, resetAt = null, rules = rules),
                    ),
                ),
                signedIn = true,
                onShowQr = {},
                onGroup = {},
                onJoin = {},
                onReport = { reported = it },
                onLeave = {},
            )
        }
        composeRule.onNodeWithText("4 su 10 timbri").performScrollTo()
        composeRule.onNodeWithText("Segnala un problema", substring = true).performScrollTo().performClick()
        composeRule.onNodeWithText("Non hanno voluto timbrare").performScrollTo().performClick()
        composeRule.onNodeWithText("Invia").performClick()
        composeRule.runOnIdle { assertEquals(LoyaltyReportKind.NO_STAMP, reported) }
    }

    /** T59: al primo uso cosa vede il locale e cosa conserva HAPOSTO, poi «Accetto e continuo». */
    @Test
    fun privacyNotice_explainsDataThenAccepts() {
        var accepted = false
        show { LoyaltyPrivacyNotice(onAccept = { accepted = true }, onCancel = {}) }
        composeRule.onNodeWithText("codice anonimo", substring = true).performScrollTo()
        composeRule.onNodeWithText("24 mesi", substring = true).performScrollTo()
        composeRule.onNodeWithText("Accetto e continuo").performScrollTo().performClick()
        composeRule.runOnIdle { assertTrue(accepted) }
    }
}
