package com.haposto.ui.screens.restaurant

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import com.haposto.ui.theme.HaPostoTheme
import org.junit.Rule
import org.junit.Test

class RestaurantManagerAccessDeniedScreenTest {

    @get:Rule
    val composeRule = createComposeRule()

    @Test
    fun unauthorizedManagerRoute_showsGuardCopy() {
        composeRule.setContent {
            HaPostoTheme {
                RestaurantManagerAccessDeniedScreen(
                    onBack = {},
                    onGoToAccess = {},
                )
            }
        }

        composeRule.onNodeWithText("Accesso non autorizzato").assertIsDisplayed()
    }
}
