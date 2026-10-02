package com.haposto.ui

import androidx.compose.foundation.layout.consumeWindowInsets
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.haposto.AppDependencies
import com.haposto.ui.components.AppBottomBar
import com.haposto.ui.navigation.AppDestination
import com.haposto.ui.navigation.DeepLink
import com.haposto.ui.screens.access.RestaurantAccessRoute
import com.haposto.ui.screens.account.AccountRoute
import com.haposto.ui.screens.admin.AdminRestaurantRoute
import com.haposto.ui.screens.admin.AdminRoute
import com.haposto.ui.screens.admin.AdminUserRoute
import com.haposto.ui.screens.area.RegisterRestaurantRoute
import com.haposto.ui.screens.area.RestaurantAreaRoute
import com.haposto.ui.screens.detail.RestaurantDetailRoute
import com.haposto.ui.screens.favorites.FavoritesRoute
import com.haposto.ui.screens.home.HomeRoute
import com.haposto.ui.screens.legal.LegalDocument
import com.haposto.ui.screens.legal.LegalDocumentRoute
import com.haposto.ui.screens.mfa.MfaRoute
import com.haposto.ui.screens.onboarding.OnboardingPrefs
import com.haposto.ui.screens.onboarding.OnboardingScreen
import com.haposto.ui.screens.plus.PlusRoute
import com.haposto.ui.screens.reservations.ReservationsRoute
import com.haposto.ui.screens.restaurant.RestaurantManagerRoute
import com.haposto.ui.screens.settings.RestaurantSettingsRoute
import com.haposto.ui.theme.HaPostoTheme

@Composable
fun HaPostoApp(
    deepLink: DeepLink? = null,
    onDeepLinkHandled: () -> Unit = {},
) {
    val context = LocalContext.current.applicationContext
    var showOnboarding by remember { mutableStateOf(!OnboardingPrefs.hasSeen(context)) }

    HaPostoTheme {
        if (showOnboarding) {
            OnboardingScreen(onFinish = {
                OnboardingPrefs.markSeen(context)
                showOnboarding = false
            })
        } else {
            MainNavigation(deepLink = deepLink, onDeepLinkHandled = onDeepLinkHandled)
        }
    }
}

@Composable
private fun MainNavigation(deepLink: DeepLink?, onDeepLinkHandled: () -> Unit) {
    val navController = rememberNavController()
    val context = LocalContext.current.applicationContext
    val repository = AppDependencies.restaurantRepository
    val accessRepository = AppDependencies.restaurantAccessRepository
    val auth = AppDependencies.authRepository
    // null nella versione DEMO: l'area ristoratore resta quella simulata.
    val management = AppDependencies.managementRepository
    val admin = AppDependencies.adminRepository
    val consumer = AppDependencies.consumerRepository
    val locationSession = AppDependencies.locationSession
    val deviceLocationProvider = remember(context) { AppDependencies.deviceLocationProvider(context) }
    val networkMonitor = remember(context) { AppDependencies.networkMonitor(context) }
    val favorites = remember(context) { AppDependencies.favorites(context) }
    val restaurateurRoute = if (management != null) AppDestination.RESTAURANT_AREA else AppDestination.RESTAURANT_ACCESS

    val backStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = backStackEntry?.destination?.route

    LaunchedEffect(deepLink) {
        when (deepLink) {
            null -> return@LaunchedEffect
            is DeepLink.Restaurant -> navController.navigate(AppDestination.restaurantDetail(deepLink.restaurantId)) {
                launchSingleTop = true
            }
            is DeepLink.Dashboard -> navController.navigate(AppDestination.restaurantManager(deepLink.restaurantId)) {
                launchSingleTop = true
            }
        }
        onDeepLinkHandled()
    }

    val openDocument: (LegalDocument) -> Unit = { document ->
        navController.navigate(AppDestination.legal(document.key)) { launchSingleTop = true }
    }
    val openMfa: () -> Unit = { navController.navigate(AppDestination.MFA) { launchSingleTop = true } }
    val openPlus: () -> Unit = { navController.navigate(AppDestination.PLUS) { launchSingleTop = true } }
    val openAccount: () -> Unit = { navController.navigateToTab(AppDestination.ACCOUNT) }

    Scaffold(
        bottomBar = {
            if (AppDestination.isTopLevel(currentRoute)) {
                AppBottomBar(
                    currentRoute = currentRoute,
                    onSelectNearby = { navController.navigateToTab(AppDestination.HOME) },
                    onSelectFavorites = { navController.navigateToTab(AppDestination.FAVORITES) },
                    onSelectRestaurateur = { navController.navigateToTab(restaurateurRoute) },
                    onSelectAccount = openAccount,
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
                    onRestaurantAreaClick = { navController.navigateToTab(restaurateurRoute) },
                )
            }
            composable(AppDestination.FAVORITES) {
                FavoritesRoute(
                    repository = repository,
                    locationSession = locationSession,
                    favorites = favorites,
                    onRestaurantClick = { restaurantId ->
                        navController.navigate(AppDestination.restaurantDetail(restaurantId))
                    },
                )
            }
            composable(AppDestination.ACCOUNT) {
                AccountRoute(
                    auth = auth,
                    onOpenDocument = openDocument,
                    onOpenMfa = openMfa,
                    onOpenPlus = openPlus,
                    onOpenAdmin = { navController.navigate(AppDestination.ADMIN) { launchSingleTop = true } },
                )
            }
            composable(AppDestination.RESTAURANT_DETAIL) { entry ->
                RestaurantDetailRoute(
                    restaurantId = entry.arguments?.getString("restaurantId").orEmpty(),
                    repository = repository,
                    locationSession = locationSession,
                    favorites = favorites,
                    onBack = navController::navigateUp,
                    consumer = consumer,
                    auth = auth,
                    onOpenPlus = openPlus,
                    onOpenAccount = openAccount,
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
            composable(AppDestination.RESTAURANT_AREA) {
                if (management != null) {
                    RestaurantAreaRoute(
                        auth = auth,
                        management = management,
                        locationSession = locationSession,
                        onOpenDashboard = { restaurantId ->
                            navController.navigate(AppDestination.restaurantManager(restaurantId)) {
                                launchSingleTop = true
                            }
                        },
                        onOpenMfa = openMfa,
                        onOpenDocument = openDocument,
                        onRegisterNew = {
                            navController.navigate(AppDestination.REGISTER_RESTAURANT) { launchSingleTop = true }
                        },
                    )
                }
            }
            composable(AppDestination.REGISTER_RESTAURANT) {
                if (management != null) {
                    RegisterRestaurantRoute(
                        management = management,
                        locationSession = locationSession,
                        onDone = navController::navigateUp,
                        onBack = navController::navigateUp,
                    )
                }
            }
            composable(AppDestination.RESTAURANT_MANAGER) { entry ->
                val managerRestaurantId = entry.arguments?.getString("restaurantId").orEmpty()
                RestaurantManagerRoute(
                    restaurantId = managerRestaurantId,
                    repository = repository,
                    accessRepository = accessRepository,
                    networkMonitor = networkMonitor,
                    onBack = navController::navigateUp,
                    onGoToAccess = { navController.navigateToTab(restaurateurRoute) },
                    onOpenReservations = {
                        navController.navigate(AppDestination.reservations(managerRestaurantId)) {
                            launchSingleTop = true
                        }
                    },
                    management = management,
                    auth = auth,
                    onOpenSettings = {
                        navController.navigate(AppDestination.restaurantSettings(managerRestaurantId)) {
                            launchSingleTop = true
                        }
                    },
                    onOpenMfa = openMfa,
                )
            }
            composable(AppDestination.RESTAURANT_SETTINGS) { entry ->
                if (management != null) {
                    RestaurantSettingsRoute(
                        restaurantId = entry.arguments?.getString("restaurantId").orEmpty(),
                        management = management,
                        onBack = navController::navigateUp,
                        onOpenMfa = openMfa,
                    )
                }
            }
            composable(AppDestination.RESERVATIONS) { entry ->
                ReservationsRoute(
                    restaurantId = entry.arguments?.getString("restaurantId").orEmpty(),
                    onBack = navController::navigateUp,
                    management = management,
                )
            }
            composable(AppDestination.MFA) {
                MfaRoute(
                    auth = auth,
                    onDone = navController::navigateUp,
                    onBack = navController::navigateUp,
                )
            }
            composable(AppDestination.LEGAL) { entry ->
                LegalDocumentRoute(
                    document = LegalDocument.fromKey(entry.arguments?.getString("document")),
                    onBack = navController::navigateUp,
                )
            }
            composable(AppDestination.PLUS) {
                PlusRoute(
                    consumer = consumer,
                    auth = auth,
                    onBack = navController::navigateUp,
                    onOpenAccount = openAccount,
                    onOpenDocument = openDocument,
                )
            }
            composable(AppDestination.ADMIN) {
                AdminRoute(
                    admin = admin,
                    auth = auth,
                    onBack = navController::navigateUp,
                    onOpenMfa = openMfa,
                    onOpenRestaurant = { restaurantId ->
                        navController.navigate(AppDestination.adminRestaurant(restaurantId))
                    },
                    onOpenUser = { userId -> navController.navigate(AppDestination.adminUser(userId)) },
                )
            }
            composable(AppDestination.ADMIN_RESTAURANT) { entry ->
                if (admin != null) {
                    AdminRestaurantRoute(
                        restaurantId = entry.arguments?.getString("restaurantId").orEmpty(),
                        admin = admin,
                        onBack = navController::navigateUp,
                        onOpenUser = { userId -> navController.navigate(AppDestination.adminUser(userId)) },
                    )
                }
            }
            composable(AppDestination.ADMIN_USER) { entry ->
                if (admin != null) {
                    AdminUserRoute(
                        userId = entry.arguments?.getString("userId").orEmpty(),
                        admin = admin,
                        onBack = navController::navigateUp,
                        onOpenRestaurant = { restaurantId ->
                            navController.navigate(AppDestination.adminRestaurant(restaurantId))
                        },
                    )
                }
            }
        }
    }
}

/**
 * Le schede in basso non si accumulano: con "indietro" si torna sempre a Vicino, e riaprire una
 * scheda riparte dalla sua schermata principale (il pannello admin non resta aperto "dietro").
 */
private fun NavHostController.navigateToTab(route: String) {
    navigate(route) {
        popUpTo(AppDestination.HOME) { inclusive = false }
        launchSingleTop = true
    }
}
