package com.haposto.ui.screens.access

import androidx.compose.runtime.Composable
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.haposto.data.network.NetworkMonitor
import com.haposto.data.repository.RestaurantAccessRepository
import com.haposto.data.repository.RestaurantRepository

@Composable
fun RestaurantAccessRoute(
    restaurantRepository: RestaurantRepository,
    accessRepository: RestaurantAccessRepository,
    networkMonitor: NetworkMonitor,
    onBack: () -> Unit,
    onOpenDashboard: (String) -> Unit,
) {
    val viewModel: RestaurantAccessViewModel = viewModel(
        factory = RestaurantAccessViewModelFactory(
            restaurantRepository = restaurantRepository,
            accessRepository = accessRepository,
        ),
    )
    val uiState = viewModel.uiState.collectAsStateWithLifecycle().value
    val isOnline = networkMonitor.isOnline
        .collectAsStateWithLifecycle(initialValue = true)
        .value

    RestaurantAccessScreen(
        uiState = uiState,
        isOnline = isOnline,
        onBack = onBack,
        onSignInDemoGoogle = viewModel::signInDemoGoogle,
        onSearchQueryChange = viewModel::onSearchQueryChange,
        onRestaurantSelected = viewModel::selectRestaurant,
        onCancelSelection = viewModel::cancelSelection,
        onContactInfoChange = viewModel::onContactInfoChange,
        onSubmitClaim = viewModel::submitClaim,
        onApproveDemo = viewModel::approvePendingClaimForDemo,
        onOpenDashboard = onOpenDashboard,
        onSignOut = viewModel::signOut,
        onResetDemo = viewModel::resetDemo,
    )
}
