package com.haposto.testutil

import com.haposto.data.location.DeviceLocationProvider
import com.haposto.data.location.DeviceLocationResult
import com.haposto.data.network.NetworkMonitor
import com.haposto.data.repository.RestaurantRepository
import com.haposto.domain.model.AvailabilityStatus
import com.haposto.domain.model.Restaurant
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.flow

class FakeNetworkMonitor(online: Boolean = true) : NetworkMonitor {
    val online = MutableStateFlow(online)
    override val isOnline: Flow<Boolean> = this.online
}

class UnavailableLocationProvider : DeviceLocationProvider {
    override suspend fun currentLocation(): DeviceLocationResult = DeviceLocationResult.Unavailable
}

/**
 * Simulates a backend that fails the first [failures] subscriptions (like Supabase offline)
 * and then serves [restaurants]. [findById] keeps answering from its last known snapshot.
 */
class FlakyRestaurantRepository(
    private val restaurants: List<Restaurant>,
    private var failures: Int = 1,
) : RestaurantRepository {
    var subscriptions = 0
        private set

    override fun observeRestaurants(): Flow<List<Restaurant>> = flow {
        subscriptions++
        if (failures > 0) {
            failures--
            throw IllegalStateException("Backend non raggiungibile")
        }
        emit(restaurants)
    }

    override fun findById(id: String): Restaurant? = restaurants.firstOrNull { it.id == id }

    override suspend fun publishAvailability(
        restaurantId: String,
        status: AvailabilityStatus,
        availableTables: Int?,
        estimatedWaitMinutes: Int?,
        note: String?,
    ): Boolean = false

    override suspend fun setPhonePublic(restaurantId: String, isPublic: Boolean): Boolean = false
}
