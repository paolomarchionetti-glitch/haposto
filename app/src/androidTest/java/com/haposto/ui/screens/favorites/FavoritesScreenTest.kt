package com.haposto.ui.screens.favorites

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import com.haposto.data.fake.FakeRestaurantRepository
import com.haposto.ui.theme.HaPostoTheme
import java.time.Instant
import org.junit.Rule
import org.junit.Test

class FavoritesScreenTest {

    @get:Rule
    val composeRule = createComposeRule()

    @Test
    fun noFavorites_explainsHowToSaveOne() {
        composeRule.setContent {
            HaPostoTheme {
                FavoritesScreen(
                    favorites = emptyList(),
                    notInAreaCount = 0,
                    now = Instant.now(),
                    onRestaurantClick = {},
                )
            }
        }

        composeRule.onNodeWithText("Nessun preferito ancora").assertIsDisplayed()
    }

    @Test
    fun savedFavorite_isListedWithItsName() {
        val levante = FakeRestaurantRepository().findById("levante-demo")!!
        composeRule.setContent {
            HaPostoTheme {
                FavoritesScreen(
                    favorites = listOf(levante),
                    notInAreaCount = 0,
                    now = Instant.now(),
                    onRestaurantClick = {},
                )
            }
        }

        composeRule.onNodeWithText(levante.name, substring = true).assertIsDisplayed()
    }
}
