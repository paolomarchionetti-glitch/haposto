package com.haposto.ui.screens.restaurant

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
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

        composeRule.onNodeWithText("C'È POSTO").assertIsDisplayed()
        composeRule.onNodeWithText("POCHI POSTI").assertIsDisplayed()
        composeRule.onNodeWithText("COMPLETO").assertIsDisplayed()
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
