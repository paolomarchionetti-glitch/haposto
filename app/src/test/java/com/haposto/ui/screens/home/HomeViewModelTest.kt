package com.haposto.ui.screens.home

import androidx.lifecycle.SavedStateHandle
import com.haposto.data.fake.FakeRestaurantRepository
import com.haposto.data.location.LocationSession
import com.haposto.domain.model.ManualArea
import com.haposto.testutil.FakeNetworkMonitor
import com.haposto.testutil.FlakyRestaurantRepository
import com.haposto.testutil.MainDispatcherRule
import com.haposto.testutil.UnavailableLocationProvider
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Rule
import org.junit.Test

class HomeViewModelTest {

    @get:Rule
    val mainDispatcherRule = MainDispatcherRule()

    private val demoRestaurants = FakeRestaurantRepository().findById("levante-demo")!!.let(::listOf)

    private fun viewModel(
        repository: FlakyRestaurantRepository,
        network: FakeNetworkMonitor = FakeNetworkMonitor(),
    ) = HomeViewModel(
        repository = repository,
        deviceLocationProvider = UnavailableLocationProvider(),
        locationSession = LocationSession(),
        networkMonitor = network,
        savedStateHandle = SavedStateHandle(),
    )

    @Test
    fun loadError_isShownAndRetryRecovers() = runTest {
        val repository = FlakyRestaurantRepository(demoRestaurants, failures = 1)
        val viewModel = viewModel(repository)
        backgroundScope.launch { viewModel.uiState.collect {} }

        val failed = viewModel.uiState.first { it.errorMessage != null }
        assertEquals("Backend non raggiungibile", failed.errorMessage)

        viewModel.retryRestaurantLoad()

        val loaded = viewModel.uiState.first { it.restaurants.isNotEmpty() }
        assertNull(loaded.errorMessage)
    }

    @Test
    fun changingArea_afterAnError_reloadsAutomatically() = runTest {
        val repository = FlakyRestaurantRepository(demoRestaurants, failures = 1)
        val viewModel = viewModel(repository)
        backgroundScope.launch { viewModel.uiState.collect {} }
        viewModel.uiState.first { it.errorMessage != null }

        viewModel.onManualAreaSelected(ManualArea.FANO)

        val loaded = viewModel.uiState.first { it.restaurants.isNotEmpty() }
        assertEquals("Fano centro", loaded.distanceOrigin.label)
    }

    @Test
    fun connectionRestored_afterAnError_reloadsAutomatically() = runTest {
        val network = FakeNetworkMonitor(online = false)
        val repository = FlakyRestaurantRepository(demoRestaurants, failures = 1)
        val viewModel = viewModel(repository, network)
        backgroundScope.launch { viewModel.uiState.collect {} }
        viewModel.uiState.first { it.errorMessage != null }

        network.online.value = true

        viewModel.uiState.first { it.restaurants.isNotEmpty() }
        assertEquals(2, repository.subscriptions)
    }
}
