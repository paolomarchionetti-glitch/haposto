package com.haposto.ui.screens.loyalty

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.test.and
import androidx.compose.ui.test.assertIsEnabled
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollTo
import com.haposto.data.loyalty.LoyaltyDraft
import com.haposto.data.loyalty.LoyaltyLimits
import com.haposto.ui.theme.HaPostoTheme
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

class LoyaltyWizardScreenTest {

    @get:Rule
    val composeRule = createComposeRule()

    /** T16: riepilogo e patto in tre righe; si attiva solo dopo «Accetto». */
    @Test
    fun summary_activatesOnlyAfterAcceptingThePact() {
        var accepted by mutableStateOf(false)
        var published = false
        composeRule.setContent {
            HaPostoTheme {
                LoyaltyWizardScreen(
                    draft = LoyaltyDraft(),
                    step = 5,
                    limits = LoyaltyLimits(),
                    isNewVersion = false,
                    nextVersion = 1,
                    pactAccepted = accepted,
                    busy = false,
                    message = null,
                    needsMfa = false,
                    onOpenMfa = {},
                    onChange = {},
                    onStep = {},
                    onPactAccepted = { accepted = it },
                    onPublish = { published = true },
                    onCancel = {},
                )
            }
        }

        composeRule.onNodeWithText("Riconosco i premi maturati", substring = true).performScrollTo()
        val activate = composeRule.onNode(hasText("Attiva la tessera") and hasClickAction())
        activate.performScrollTo().assertIsNotEnabled()

        composeRule.onNodeWithText("Accetto").performScrollTo().performClick()
        activate.performScrollTo().assertIsEnabled().performClick()
        composeRule.runOnIdle { assertTrue(published) }
    }
}
