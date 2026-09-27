package com.haposto.ui.screens.restaurant

import androidx.compose.runtime.Composable
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.haposto.data.network.NetworkMonitor
import com.haposto.data.repository.RestaurantAccessRepository
import com.haposto.data.repository.RestaurantRepository

@Composable
fun RestaurantManagerRoute(
    restaurantId: String,
    repository: RestaurantRepository,
    accessRepository: RestaurantAccessRepository,
    networkMonitor: NetworkMonitor,
    onBack: () -> Unit,
    onGoToAccess: () -> Unit,
    onOpenReservations: () -> Unit,
) {
    val isOnline = networkMonitor.isOnline
        .collectAsStateWithLifecycle(initialValue = true)
        .value

    val accessState = accessRepository.observeState()
        .collectAsStateWithLifecycle(initialValue = accessRepository.currentState())
        .value

    if (!accessState.canManage(restaurantId)) {
        RestaurantManagerAccessDeniedScreen(
            onBack = onBack,
            onGoToAccess = onGoToAccess,
        )
        return
    }

    val viewModel: RestaurantManagerViewModel = viewModel(
        factory = RestaurantManagerViewModelFactory(
            restaurantId = restaurantId,
            repository = repository,
        ),
    )
    val uiState = viewModel.uiState.collectAsStateWithLifecycle().value

    RestaurantManagerScreen(
        uiState = uiState,
        isOnline = isOnline,
        onBack = onBack,
        onStatusSelected = viewModel::publishStatus,
        onDecrementTables = viewModel::decrementTables,
        onIncrementTables = viewModel::incrementTables,
        onWaitSelected = viewModel::setWait,
        onNoteChange = viewModel::setNote,
        onRefreshCurrentStatus = viewModel::refreshCurrentStatus,
        onPhonePublicChange = viewModel::setPhonePublic,
        onOpenReservations = onOpenReservations,
    )
}
