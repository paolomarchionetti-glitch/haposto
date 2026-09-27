package com.haposto.ui

import androidx.compose.foundation.layout.consumeWindowInsets
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.haposto.AppDependencies
import com.haposto.ui.components.AppBottomBar
import com.haposto.ui.navigation.AppDestination
import com.haposto.ui.screens.access.RestaurantAccessRoute
import com.haposto.ui.screens.detail.RestaurantDetailRoute
import com.haposto.ui.screens.favorites.FavoritesRoute
import com.haposto.ui.screens.home.HomeRoute
import com.haposto.ui.screens.onboarding.OnboardingPrefs
import com.haposto.ui.screens.onboarding.OnboardingScreen
import com.haposto.ui.screens.reservations.ReservationsRoute
import com.haposto.ui.screens.restaurant.RestaurantManagerRoute
import com.haposto.ui.theme.HaPostoTheme

@Composable
fun HaPostoApp() {
    val context = LocalContext.current.applicationContext
    var showOnboarding by remember { mutableStateOf(!OnboardingPrefs.hasSeen(context)) }

    HaPostoTheme {
        if (showOnboarding) {
            OnboardingScreen(onFinish = {
                OnboardingPrefs.markSeen(context)
                showOnboarding = false
            })
        } else {
            MainNavigation()
        }
    }
}

@Composable
private fun MainNavigation() {
    val navController = rememberNavController()
    val context = LocalContext.current.applicationContext
    val repository = AppDependencies.restaurantRepository
    val accessRepository = AppDependencies.restaurantAccessRepository
    val locationSession = AppDependencies.locationSession
    val deviceLocationProvider = remember(context) { AppDependencies.deviceLocationProvider(context) }
    val networkMonitor = remember(context) { AppDependencies.networkMonitor(context) }

    val backStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = backStackEntry?.destination?.route

    Scaffold(
        bottomBar = {
            if (AppDestination.isTopLevel(currentRoute)) {
                AppBottomBar(
                    currentRoute = currentRoute,
                    onSelectNearby = {
                        navController.navigate(AppDestination.HOME) {
                            popUpTo(AppDestination.HOME) { inclusive = false }
                            launchSingleTop = true
                        }
                    },
                    onSelectFavorites = {
                        navController.navigate(AppDestination.FAVORITES) {
                            launchSingleTop = true
                        }
                    },
                    onSelectRestaurateur = {
                        navController.navigate(AppDestination.RESTAURANT_ACCESS) {
                            launchSingleTop = true
                        }
                    },
                )
            }
        },
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = AppDestination.HOME,
            // Each screen has its own Scaffold: consuming the insets already applied here keeps the
            // inner Scaffolds from adding the status/navigation bar padding a second time.
            modifier = Modifier
                .padding(innerPadding)
                .consumeWindowInsets(innerPadding),
        ) {
            composable(AppDestination.HOME) {
                HomeRoute(
                    repository = repository,
                    deviceLocationProvider = deviceLocationProvider,
                    locationSession = locationSession,
                    networkMonitor = networkMonitor,
                    onRestaurantClick = { restaurantId ->
                        navController.navigate(AppDestination.restaurantDetail(restaurantId))
                    },
                    onRestaurantAreaClick = {
                        navController.navigate(AppDestination.RESTAURANT_ACCESS) {
                            launchSingleTop = true
                        }
                    },
                )
            }
            composable(AppDestination.FAVORITES) {
                FavoritesRoute()
            }
            composable(AppDestination.RESTAURANT_DETAIL) { entry ->
                RestaurantDetailRoute(
                    restaurantId = entry.arguments?.getString("restaurantId").orEmpty(),
                    repository = repository,
                    locationSession = locationSession,
                    onBack = navController::navigateUp,
                )
            }
            composable(AppDestination.RESTAURANT_ACCESS) {
                RestaurantAccessRoute(
                    restaurantRepository = repository,
                    accessRepository = accessRepository,
                    networkMonitor = networkMonitor,
                    onBack = navController::navigateUp,
                    onOpenDashboard = { restaurantId ->
                        navController.navigate(AppDestination.restaurantManager(restaurantId)) {
                            launchSingleTop = true
                            popUpTo(AppDestination.RESTAURANT_ACCESS) { inclusive = false }
                        }
                    },
                )
            }
            composable(AppDestination.RESTAURANT_MANAGER) { entry ->
                val managerRestaurantId = entry.arguments?.getString("restaurantId").orEmpty()
                RestaurantManagerRoute(
                    restaurantId = managerRestaurantId,
                    repository = repository,
                    accessRepository = accessRepository,
                    networkMonitor = networkMonitor,
                    onBack = navController::navigateUp,
                    onGoToAccess = {
                        navController.navigate(AppDestination.RESTAURANT_ACCESS) {
                            popUpTo(AppDestination.RESTAURANT_ACCESS) { inclusive = false }
                            launchSingleTop = true
                        }
                    },
                    onOpenReservations = {
                        navController.navigate(AppDestination.reservations(managerRestaurantId)) {
                            launchSingleTop = true
                        }
                    },
                )
            }
            composable(AppDestination.RESERVATIONS) { entry ->
                ReservationsRoute(
                    restaurantId = entry.arguments?.getString("restaurantId").orEmpty(),
                    onBack = navController::navigateUp,
                )
            }
        }
    }
}
