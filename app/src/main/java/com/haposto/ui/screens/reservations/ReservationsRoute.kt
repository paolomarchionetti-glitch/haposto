package com.haposto.ui.screens.reservations

import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.viewmodel.compose.viewModel

@Composable
fun ReservationsRoute(
    restaurantId: String,
    onBack: () -> Unit,
) {
    val context = LocalContext.current.applicationContext
    val viewModel: ReservationsViewModel = viewModel(
        factory = ReservationsViewModelFactory(context, restaurantId),
    )
    val items by viewModel.items.collectAsState()

    ReservationsScreen(
        items = items,
        onAddOrUpdate = viewModel::addOrUpdate,
        onRemove = viewModel::remove,
        onBack = onBack,
    )
}
