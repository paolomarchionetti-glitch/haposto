package com.haposto.ui.screens.home

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.createSavedStateHandle
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import com.haposto.data.location.DeviceLocationProvider
import com.haposto.data.location.DeviceLocationResult
import com.haposto.data.location.LocationSession
import com.haposto.data.network.NetworkMonitor
import com.haposto.data.repository.RestaurantDataSource
import com.haposto.data.repository.RestaurantRepository
import com.haposto.data.repository.RestaurantRepositoryMetadata
import com.haposto.domain.model.ManualArea
import com.haposto.domain.model.Restaurant
import com.haposto.domain.model.RestaurantFilter
import com.haposto.domain.usecase.RestaurantDistance
import com.haposto.domain.usecase.RestaurantQuery
import java.time.Instant
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.onStart
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

@OptIn(ExperimentalCoroutinesApi::class)
class HomeViewModel(
    repository: RestaurantRepository,
    private val deviceLocationProvider: DeviceLocationProvider,
    private val locationSession: LocationSession,
    networkMonitor: NetworkMonitor,
    private val savedStateHandle: SavedStateHandle,
) : ViewModel() {

    private val searchQuery = savedStateHandle.getStateFlow(KEY_SEARCH_QUERY, "")
    private val selectedFilterName = savedStateHandle.getStateFlow(
        KEY_FILTER,
        RestaurantFilter.ALL.name,
    )
    private val isLocating = kotlinx.coroutines.flow.MutableStateFlow(false)
    private val locationNotice = kotlinx.coroutines.flow.MutableStateFlow<LocationNotice?>(null)
    private val dataSource = (repository as? RestaurantRepositoryMetadata)?.dataSource
        ?: RestaurantDataSource.LOCAL_DEMO

    private val retryToken = kotlinx.coroutines.flow.MutableStateFlow(0)

    private val repositorySnapshot: Flow<RepositorySnapshot> = retryToken
        .flatMapLatest {
            repository.observeRestaurants()
                .map<List<Restaurant>, RepositorySnapshot> { RepositorySnapshot.Content(it) }
                .onStart { emit(RepositorySnapshot.Loading) }
                .catch { throwable ->
                    emit(
                        RepositorySnapshot.Error(
                            throwable.message?.takeIf(String::isNotBlank)
                                ?: "Non è stato possibile caricare i ristoranti.",
                        ),
                    )
                }
        }

    private val controls = combine(
        searchQuery,
        selectedFilterName,
        locationSession.origin,
        isLocating,
        locationNotice,
    ) { query, filterName, origin, locating, notice ->
        HomeControls(
            query = query,
            filter = runCatching { RestaurantFilter.valueOf(filterName) }
                .getOrDefault(RestaurantFilter.ALL),
            origin = origin,
            locating = locating,
            notice = notice,
        )
    }

    val uiState = combine(
        repositorySnapshot,
        controls,
        clockTicker(),
        networkMonitor.isOnline.onStart { emit(true) },
    ) { snapshot, controls, now, isOnline ->
        val sourceRestaurants = (snapshot as? RepositorySnapshot.Content)?.restaurants.orEmpty()
        val restaurantsWithDistance = RestaurantDistance.attach(
            restaurants = sourceRestaurants,
            origin = controls.origin.point,
        )

        HomeUiState(
            searchQuery = controls.query,
            selectedFilter = controls.filter,
            restaurants = RestaurantQuery.apply(
                restaurants = restaurantsWithDistance,
                query = controls.query,
                filter = controls.filter,
                now = now,
            ),
            totalRestaurantCount = sourceRestaurants.size,
            now = now,
            distanceOrigin = controls.origin,
            isLocating = controls.locating,
            locationNotice = controls.notice,
            isInitialLoading = snapshot is RepositorySnapshot.Loading,
            errorMessage = (snapshot as? RepositorySnapshot.Error)?.message,
            isOnline = isOnline,
            isDemoData = dataSource != RestaurantDataSource.SUPABASE,
            isSupabaseBacked = dataSource == RestaurantDataSource.SUPABASE,
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = HomeUiState(
            searchQuery = savedStateHandle[KEY_SEARCH_QUERY] ?: "",
            selectedFilter = runCatching {
                RestaurantFilter.valueOf(savedStateHandle[KEY_FILTER] ?: RestaurantFilter.ALL.name)
            }.getOrDefault(RestaurantFilter.ALL),
            distanceOrigin = locationSession.origin.value,
        ),
    )

    init {
        savedStateHandle.get<String>(KEY_MANUAL_AREA)?.let { savedArea ->
            runCatching { ManualArea.valueOf(savedArea) }
                .getOrNull()
                ?.let(locationSession::useManualArea)
        }
    }

    fun onSearchQueryChange(query: String) {
        savedStateHandle[KEY_SEARCH_QUERY] = query.take(80)
    }

    fun onFilterSelected(filter: RestaurantFilter) {
        savedStateHandle[KEY_FILTER] = filter.name
    }

    fun onManualAreaSelected(area: ManualArea) {
        savedStateHandle[KEY_MANUAL_AREA] = area.name
        locationSession.useManualArea(area)
        locationNotice.value = null
    }

    fun retryRestaurantLoad() {
        retryToken.value += 1
    }

    fun onLocationRationaleRequired() {
        isLocating.value = false
        locationNotice.value = LocationNotice.RATIONALE_REQUIRED
    }

    fun onLocationPermissionDenied(permanentlyDenied: Boolean) {
        isLocating.value = false
        locationNotice.value = if (permanentlyDenied) {
            LocationNotice.PERMISSION_DENIED_PERMANENT
        } else {
            LocationNotice.PERMISSION_DENIED
        }
    }

    fun requestDeviceLocation(isPrecisePermission: Boolean) {
        if (isLocating.value) return

        viewModelScope.launch {
            isLocating.value = true
            locationNotice.value = null

            when (val result = deviceLocationProvider.currentLocation()) {
                is DeviceLocationResult.Success -> {
                    // Device coordinates intentionally remain RAM-only and are never copied to SavedStateHandle.
                    locationSession.useDeviceLocation(
                        point = result.point,
                        accuracyMeters = result.accuracyMeters,
                        isPrecise = isPrecisePermission,
                    )
                }

                DeviceLocationResult.PermissionMissing -> {
                    locationNotice.value = LocationNotice.PERMISSION_DENIED
                }

                DeviceLocationResult.ServicesDisabled -> {
                    locationNotice.value = LocationNotice.SERVICES_DISABLED
                }

                DeviceLocationResult.Unavailable -> {
                    locationNotice.value = LocationNotice.UNAVAILABLE
                }
            }

            isLocating.value = false
        }
    }

    private fun clockTicker(): Flow<Instant> = flow {
        while (true) {
            emit(Instant.now())
            delay(15_000)
        }
    }

    private data class HomeControls(
        val query: String,
        val filter: RestaurantFilter,
        val origin: com.haposto.domain.model.DistanceOrigin,
        val locating: Boolean,
        val notice: LocationNotice?,
    )

    private sealed interface RepositorySnapshot {
        data object Loading : RepositorySnapshot
        data class Content(val restaurants: List<Restaurant>) : RepositorySnapshot
        data class Error(val message: String) : RepositorySnapshot
    }

    companion object {
        private const val KEY_SEARCH_QUERY = "home.searchQuery"
        private const val KEY_FILTER = "home.filter"
        private const val KEY_MANUAL_AREA = "home.manualArea"
    }
}

fun HomeViewModelFactory(
    repository: RestaurantRepository,
    deviceLocationProvider: DeviceLocationProvider,
    locationSession: LocationSession,
    networkMonitor: NetworkMonitor,
): ViewModelProvider.Factory = viewModelFactory {
    initializer {
        HomeViewModel(
            repository = repository,
            deviceLocationProvider = deviceLocationProvider,
            locationSession = locationSession,
            networkMonitor = networkMonitor,
            savedStateHandle = createSavedStateHandle(),
        )
    }
}
