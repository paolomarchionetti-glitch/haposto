package com.haposto.ui.screens.access

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performScrollTo
import com.haposto.domain.model.RestaurantClaim
import com.haposto.domain.model.RestaurantClaimStatus
import com.haposto.domain.model.RestaurantDemoAccount
import com.haposto.ui.theme.HaPostoTheme
import java.time.Instant
import org.junit.Rule
import org.junit.Test

class RestaurantAccessScreenTest {

    @get:Rule
    val composeRule = createComposeRule()

    @Test
    fun signedOutOffline_showsDemoAndConnectivityDisclosure() {
        composeRule.setContent {
            HaPostoTheme {
                RestaurantAccessScreen(
                    uiState = RestaurantAccessUiState(),
                    isOnline = false,
                    onBack = {},
                    onSignInDemoGoogle = {},
                    onSearchQueryChange = {},
                    onRestaurantSelected = {},
                    onCancelSelection = {},
                    onContactInfoChange = {},
                    onSubmitClaim = {},
                    onApproveDemo = {},
                    onOpenDashboard = {},
                    onSignOut = {},
                    onResetDemo = {},
                )
            }
        }

        composeRule.onNodeWithText("STEP 6 · DEMO PRE-BACKEND").assertIsDisplayed()
        composeRule.onNodeWithText("Sei offline").assertIsDisplayed()
        composeRule.onNodeWithText("Passo 1 di 3 · Accedi").assertIsDisplayed()
        composeRule.onNodeWithText("CONTINUA CON GOOGLE · DEMO LOCALE").performScrollTo().assertIsDisplayed()
    }

    @Test
    fun pendingClaim_keepsDashboardLocked() {
        val account = RestaurantDemoAccount(
            id = "demo",
            displayName = "Titolare Demo",
            email = "demo@invalid",
        )
        val claim = RestaurantClaim(
            id = "claim",
            restaurantId = "levante-demo",
            accountId = account.id,
            status = RestaurantClaimStatus.PENDING,
            contactInfo = "demo-contact",
            createdAt = Instant.parse("2026-08-24T18:00:00Z"),
        )

        composeRule.setContent {
            HaPostoTheme {
                RestaurantAccessScreen(
                    uiState = RestaurantAccessUiState(
                        phase = RestaurantAccessPhase.PENDING,
                        account = account,
                        claim = claim,
                    ),
                    onBack = {},
                    onSignInDemoGoogle = {},
                    onSearchQueryChange = {},
                    onRestaurantSelected = {},
                    onCancelSelection = {},
                    onContactInfoChange = {},
                    onSubmitClaim = {},
                    onApproveDemo = {},
                    onOpenDashboard = {},
                    onSignOut = {},
                    onResetDemo = {},
                )
            }
        }

        // On small screens the demo-admin button sits below the fold: scroll to it first.
        composeRule.onNodeWithText("Passo 3 di 3 · Verifica in corso").assertIsDisplayed()
        composeRule.onNodeWithText("RICHIESTA IN VERIFICA").performScrollTo().assertIsDisplayed()
        composeRule.onNodeWithText("SIMULA APPROVAZIONE ADMIN").performScrollTo().assertIsDisplayed()
    }
}
