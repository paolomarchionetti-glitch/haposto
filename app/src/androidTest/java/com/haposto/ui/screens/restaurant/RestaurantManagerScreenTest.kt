package com.haposto.ui.screens.restaurant

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performScrollTo
import com.haposto.data.fake.FakeRestaurantRepository
import com.haposto.domain.model.AvailabilityStatus
import com.haposto.domain.usecase.AvailabilityResolver
import com.haposto.ui.theme.HaPostoTheme
import java.time.Instant
import org.junit.Rule
import org.junit.Test

class RestaurantManagerScreenTest {

    @get:Rule
    val composeRule = createComposeRule()

    @Test
    fun approvedDashboard_exposesThreeOneTapStates() {
        val restaurant = FakeRestaurantRepository().findById("levante-demo")!!
        val now = Instant.now()

        composeRule.setContent {
            HaPostoTheme {
                RestaurantManagerScreen(
                    uiState = RestaurantManagerUiState(
                        restaurant = restaurant,
                        effectiveAvailability = AvailabilityResolver.resolve(restaurant, now),
                        now = now,
                    ),
                    isOnline = true,
                    onBack = {},
                    onStatusSelected = {},
                    onDecrementTables = {},
                    onIncrementTables = {},
                    onWaitSelected = {},
                    onNoteChange = {},
                    onRefreshCurrentStatus = {},
                    onPhonePublicChange = {},
                )
            }
        }

        // The status labels also appear in the "Ora sei" badge: target the one-tap buttons explicitly.
        // On small screens the buttons sit below the status card: scroll to each one first.
        composeRule.onNodeWithContentDescription("Imposta stato C'è posto").performScrollTo().assertIsDisplayed()
        composeRule.onNodeWithContentDescription("Imposta stato Pochi posti").performScrollTo().assertIsDisplayed()
        composeRule.onNodeWithContentDescription("Imposta stato Completo").performScrollTo().assertIsDisplayed()
        // A live status can be re-confirmed with one tap from the status card.
        composeRule.onNodeWithContentDescription("Conferma lo stato attuale").performScrollTo().assertIsDisplayed()
    }

    @Test
    fun offlineDashboard_warnsThatLiveIsNotServerConfirmed() {
        val restaurant = FakeRestaurantRepository().findById("levante-demo")!!
        val now = Instant.now()

        composeRule.setContent {
            HaPostoTheme {
                RestaurantManagerScreen(
                    uiState = RestaurantManagerUiState(
                        restaurant = restaurant,
                        effectiveAvailability = AvailabilityResolver.resolve(restaurant, now),
                        now = now,
                    ),
                    isOnline = false,
                    onBack = {},
                    onStatusSelected = { _: AvailabilityStatus -> },
                    onDecrementTables = {},
                    onIncrementTables = {},
                    onWaitSelected = {},
                    onNoteChange = {},
                    onRefreshCurrentStatus = {},
                    onPhonePublicChange = {},
                )
            }
        }

        composeRule.onNodeWithText("Sei offline").assertIsDisplayed()
    }
}
