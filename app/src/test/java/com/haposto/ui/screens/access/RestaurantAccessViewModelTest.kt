package com.haposto.ui.screens.access

import androidx.lifecycle.SavedStateHandle
import com.haposto.data.fake.FakeRestaurantAccessRepository
import com.haposto.data.fake.FakeRestaurantRepository
import com.haposto.data.remote.supabase.ConfigurationErrorRestaurantRepository
import com.haposto.testutil.MainDispatcherRule
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

class RestaurantAccessViewModelTest {

    @get:Rule
    val mainDispatcherRule = MainDispatcherRule()

    @Test
    fun misconfiguredDirectory_doesNotCrashAndShowsNoCandidates() = runTest {
        val directory = ConfigurationErrorRestaurantRepository("Configurazione Supabase incompleta")
        val viewModel = RestaurantAccessViewModel(
            restaurantRepository = directory,
            accessRepository = FakeRestaurantAccessRepository(directory),
            savedStateHandle = SavedStateHandle(),
        )
        backgroundScope.launch { viewModel.uiState.collect {} }

        viewModel.signInDemoGoogle()

        val state = viewModel.uiState.first { it.phase == RestaurantAccessPhase.SEARCH }
        assertTrue(state.candidates.isEmpty())
    }

    @Test
    fun demoDirectory_listsOnlyActivePartnersMatchingTheQuery() = runTest {
        val directory = FakeRestaurantRepository()
        val viewModel = RestaurantAccessViewModel(
            restaurantRepository = directory,
            accessRepository = FakeRestaurantAccessRepository(directory),
            savedStateHandle = SavedStateHandle(),
        )
        backgroundScope.launch { viewModel.uiState.collect {} }

        viewModel.signInDemoGoogle()
        viewModel.onSearchQueryChange("levante")

        val state = viewModel.uiState.first { it.searchQuery == "levante" && it.candidates.isNotEmpty() }
        assertEquals(listOf("levante-demo"), state.candidates.map { it.id })
    }
}
