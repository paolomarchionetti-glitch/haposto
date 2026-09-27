package com.haposto.ui.screens.home

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import com.haposto.ui.theme.HaPostoTheme
import org.junit.Rule
import org.junit.Test

class HomeScreenTest {

    @get:Rule
    val composeRule = createComposeRule()

    @Test
    fun loadingState_isVisible() {
        composeRule.setContent {
            HaPostoTheme {
                HomeScreen(
                    uiState = HomeUiState(isInitialLoading = true),
                    onSearchQueryChange = {},
                    onFilterSelected = {},
                    onManualAreaSelected = {},
                    onUseDeviceLocation = {},
                    onConfirmLocationRationale = {},
                    onOpenAppSettings = {},
                    onRestaurantClick = {},
                    onRestaurantAreaClick = {},
                )
            }
        }

        composeRule.onNodeWithText("Caricamento ristoranti").assertIsDisplayed()
    }

    @Test
    fun filteredEmptyState_isDistinctFromDirectoryEmpty() {
        composeRule.setContent {
            HaPostoTheme {
                HomeScreen(
                    uiState = HomeUiState(
                        isInitialLoading = false,
                        totalRestaurantCount = 10,
                        restaurants = emptyList(),
                    ),
                    onSearchQueryChange = {},
                    onFilterSelected = {},
                    onManualAreaSelected = {},
                    onUseDeviceLocation = {},
                    onConfirmLocationRationale = {},
                    onOpenAppSettings = {},
                    onRestaurantClick = {},
                    onRestaurantAreaClick = {},
                )
            }
        }

        composeRule.onNodeWithText("Nessun risultato").assertIsDisplayed()
    }

    @Test
    fun offlineBanner_isVisibleWithoutBlockingLocalContent() {
        composeRule.setContent {
            HaPostoTheme {
                HomeScreen(
                    uiState = HomeUiState(
                        isInitialLoading = false,
                        totalRestaurantCount = 0,
                        isOnline = false,
                    ),
                    onSearchQueryChange = {},
                    onFilterSelected = {},
                    onManualAreaSelected = {},
                    onUseDeviceLocation = {},
                    onConfirmLocationRationale = {},
                    onOpenAppSettings = {},
                    onRestaurantClick = {},
                    onRestaurantAreaClick = {},
                )
            }
        }

        composeRule.onNodeWithText("Sei offline").assertIsDisplayed()
        composeRule.onNodeWithText("Directory ancora vuota").assertIsDisplayed()
    }
}
