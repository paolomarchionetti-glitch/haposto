package com.haposto.ui.screens.home

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import android.content.pm.PackageManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalContext
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.haposto.data.location.DeviceLocationProvider
import com.haposto.data.location.LocationSession
import com.haposto.data.network.NetworkMonitor
import com.haposto.data.repository.RestaurantRepository
import com.haposto.ui.util.ExternalActions

@Composable
fun HomeRoute(
    repository: RestaurantRepository,
    deviceLocationProvider: DeviceLocationProvider,
    locationSession: LocationSession,
    networkMonitor: NetworkMonitor,
    onRestaurantClick: (String) -> Unit,
    onRestaurantAreaClick: () -> Unit,
) {
    val context = LocalContext.current
    val activity = context.findActivity()
    val viewModel: HomeViewModel = viewModel(
        factory = HomeViewModelFactory(
            repository = repository,
            deviceLocationProvider = deviceLocationProvider,
            locationSession = locationSession,
            networkMonitor = networkMonitor,
        ),
    )
    val uiState = viewModel.uiState.collectAsStateWithLifecycle().value

    fun shouldShowRationale(): Boolean = activity?.let {
        ActivityCompat.shouldShowRequestPermissionRationale(
            it,
            Manifest.permission.ACCESS_FINE_LOCATION,
        ) || ActivityCompat.shouldShowRequestPermissionRationale(
            it,
            Manifest.permission.ACCESS_COARSE_LOCATION,
        )
    } == true

    val permissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestMultiplePermissions(),
    ) { permissions ->
        val fineGranted = permissions[Manifest.permission.ACCESS_FINE_LOCATION] == true
        val coarseGranted = permissions[Manifest.permission.ACCESS_COARSE_LOCATION] == true

        if (fineGranted || coarseGranted) {
            viewModel.requestDeviceLocation(isPrecisePermission = fineGranted)
        } else {
            viewModel.onLocationPermissionDenied(
                permanentlyDenied = !shouldShowRationale(),
            )
        }
    }

    val requestPermissions: () -> Unit = {
        permissionLauncher.launch(
            arrayOf(
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION,
            ),
        )
    }

    fun useDeviceLocation() {
        val fineGranted = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION,
        ) == PackageManager.PERMISSION_GRANTED
        val coarseGranted = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_COARSE_LOCATION,
        ) == PackageManager.PERMISSION_GRANTED

        when {
            fineGranted || coarseGranted -> {
                viewModel.requestDeviceLocation(isPrecisePermission = fineGranted)
            }
            shouldShowRationale() -> viewModel.onLocationRationaleRequired()
            else -> requestPermissions()
        }
    }

    HomeScreen(
        uiState = uiState,
        onSearchQueryChange = viewModel::onSearchQueryChange,
        onFilterSelected = viewModel::onFilterSelected,
        onManualAreaSelected = viewModel::onManualAreaSelected,
        onUseDeviceLocation = ::useDeviceLocation,
        onConfirmLocationRationale = requestPermissions,
        onOpenAppSettings = { ExternalActions.openAppSettings(context) },
        onRetry = viewModel::retryRestaurantLoad,
        onRestaurantClick = onRestaurantClick,
        onRestaurantAreaClick = onRestaurantAreaClick,
    )
}

private tailrec fun Context.findActivity(): Activity? = when (this) {
    is Activity -> this
    is ContextWrapper -> baseContext.findActivity()
    else -> null
}
