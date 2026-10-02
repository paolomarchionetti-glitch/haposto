package com.haposto.ui.screens.restaurant

import androidx.lifecycle.SavedStateHandle
import com.haposto.data.fake.FakeRestaurantRepository
import com.haposto.data.restaurant.RecentNotesStore
import com.haposto.domain.model.AvailabilityStatus
import com.haposto.testutil.FlakyRestaurantRepository
import com.haposto.testutil.MainDispatcherRule
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test

class RestaurantManagerViewModelTest {

    @get:Rule
    val mainDispatcherRule = MainDispatcherRule()

    @Test
    fun backendError_keepsLastKnownRestaurantInsteadOfCrashing() = runTest {
        val levante = FakeRestaurantRepository().findById("levante-demo")!!
        val repository = FlakyRestaurantRepository(restaurants = listOf(levante), failures = 1)
        val viewModel = RestaurantManagerViewModel(
            restaurantId = "levante-demo",
            repository = repository,
            savedStateHandle = SavedStateHandle(),
        )
        backgroundScope.launch { viewModel.uiState.collect {} }

        val state = viewModel.uiState.first { it.restaurant != null }
        assertEquals("levante-demo", state.restaurant?.id)
    }

    @Test
    fun publishFull_clearsTablesAndUpdatesSharedRepository() = runTest {
        val repository = FakeRestaurantRepository()
        val viewModel = RestaurantManagerViewModel(
            restaurantId = "levante-demo",
            repository = repository,
            savedStateHandle = SavedStateHandle(),
        )
        backgroundScope.launch { viewModel.uiState.collect {} }

        viewModel.publishStatus(AvailabilityStatus.FULL)

        val state = viewModel.uiState.first { it.effectiveAvailability.status == AvailabilityStatus.FULL }
        assertEquals(null, state.availableTables)
        assertEquals(AvailabilityStatus.FULL, repository.findById("levante-demo")?.liveAvailability?.status)
    }

    @Test
    fun dictation_fillsOnlyTheDetailsItNames() = runTest {
        val viewModel = RestaurantManagerViewModel(
            restaurantId = "levante-demo",
            repository = FakeRestaurantRepository(),
            savedStateHandle = SavedStateHandle(),
        )
        backgroundScope.launch { viewModel.uiState.collect {} }
        viewModel.uiState.first { it.restaurant != null }

        viewModel.applyDictation("tre tavoli, dieci minuti, solo tavoli fuori")

        val state = viewModel.uiState.first { it.note == "Solo tavoli fuori" }
        assertEquals(3, state.availableTables)
        assertEquals(10, state.estimatedWaitMinutes)
    }

    @Test
    fun publishedNote_isRememberedForNextTime() = runTest {
        val store = object : RecentNotesStore {
            var saved = listOf("Bancone")
            override fun load() = saved
            override fun save(notes: List<String>) {
                saved = notes
            }
        }
        val viewModel = RestaurantManagerViewModel(
            restaurantId = "levante-demo",
            repository = FakeRestaurantRepository(),
            savedStateHandle = SavedStateHandle(),
            recentNotesStore = store,
        )
        backgroundScope.launch { viewModel.uiState.collect {} }
        viewModel.uiState.first { it.restaurant != null }

        viewModel.setNote("Solo esterni")
        viewModel.publishStatus(AvailabilityStatus.AVAILABLE)

        viewModel.uiState.first { it.recentNotes.firstOrNull() == "Solo esterni" }
        assertEquals(listOf("Solo esterni", "Bancone"), store.saved)
    }
}
