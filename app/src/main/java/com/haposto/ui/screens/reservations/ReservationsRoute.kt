package com.haposto.ui.screens.reservations

import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.viewmodel.compose.viewModel
import com.haposto.data.restaurant.RestaurantManagementRepository
import com.haposto.domain.model.OpeningHours
import java.time.LocalDate

@Composable
fun ReservationsRoute(
    restaurantId: String,
    onBack: () -> Unit,
    /** Versioni DEV/PROD: gli orari del locale decidono gli orari proposti a un tocco. */
    management: RestaurantManagementRepository? = null,
) {
    val context = LocalContext.current.applicationContext
    val viewModel: ReservationsViewModel = viewModel(
        factory = ReservationsViewModelFactory(context, restaurantId),
    )
    val items by viewModel.items.collectAsState()
    val openingHours by produceState<OpeningHours?>(initialValue = null, management, restaurantId) {
        value = management?.managerInfo(restaurantId)?.valueOrNull?.openingHours
    }

    ReservationsScreen(
        items = items,
        onAddOrUpdate = viewModel::addOrUpdate,
        onRemove = viewModel::remove,
        onBack = onBack,
        today = LocalDate.now(),
        openingHours = openingHours,
    )
}
