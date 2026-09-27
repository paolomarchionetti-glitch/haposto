package com.haposto.ui.screens.home

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.hasScrollToIndexAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performScrollToNode
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
        // The empty-state panel follows the search controls: on small screens scroll the list to it.
        composeRule.onNode(hasScrollToIndexAction())
            .performScrollToNode(hasText("Directory ancora vuota"))
        composeRule.onNodeWithText("Directory ancora vuota").assertIsDisplayed()
    }
}
