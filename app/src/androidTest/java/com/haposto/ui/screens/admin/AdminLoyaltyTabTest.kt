package com.haposto.ui.screens.admin

import androidx.compose.ui.test.hasScrollAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollToNode
import com.haposto.data.admin.AdminLoyaltyOverview
import com.haposto.data.admin.AdminLoyaltyRestaurant
import com.haposto.data.admin.AdminLoyaltyUser
import com.haposto.ui.theme.HaPostoTheme
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test

class AdminLoyaltyTabTest {

    @get:Rule
    val composeRule = createComposeRule()

    private val suspended = AdminLoyaltyRestaurant("r1", "Osteria Levante Demo", "Pesaro", "SUSPENDED")

    private val overview = AdminLoyaltyOverview(
        mode = "TEST",
        launched = false,
        programs = mapOf("ACTIVE" to 1, "SUSPENDED" to 1),
        cards = mapOf("active" to 2),
        rewards = emptyMap(),
        last30Days = mapOf("scans" to 2, "stamps" to 2),
        rewardKinds = mapOf("DISCOUNT" to 1),
        versions = 1,
        pacts = 1,
        reports60Days = 0,
        testerRestaurants = listOf(AdminLoyaltyRestaurant("r6", "Linea Cucina Demo", "Fano", "ACTIVE"), suspended),
        testerUsers = listOf(AdminLoyaltyUser("u1", "test-user@haposto.test")),
        sanctioned = listOf(suspended),
    )

    /** §13: modalità e numeri da leggere; «Ridai la tessera» solo per i locali sospesi o con la tessera tolta. */
    @Test
    fun tab_showsModeAndLetsAdminRestoreASuspendedCard() {
        var restored: String? = null
        composeRule.setContent {
            HaPostoTheme {
                AdminLoyaltyContent(
                    overview = overview,
                    busy = false,
                    onOpenRestaurant = {},
                    onOpenUser = {},
                    onRestore = { restored = it },
                )
            }
        }
        composeRule.onNodeWithText("Prova: solo locali e clienti tester (gli admin sempre)").assertExists()
        composeRule.onNode(hasScrollAction()).performScrollToNode(hasText("Ridai la tessera"))
        composeRule.onNodeWithText("Ridai la tessera").performClick()
        composeRule.runOnIdle { assertEquals("r1", restored) }
    }
}
