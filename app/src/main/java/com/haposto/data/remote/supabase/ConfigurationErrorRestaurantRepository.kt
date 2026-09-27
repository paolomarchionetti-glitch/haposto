package com.haposto.data.remote.supabase

import com.haposto.data.repository.RestaurantDataSource
import com.haposto.data.repository.RestaurantRepository
import com.haposto.data.repository.RestaurantRepositoryMetadata
import com.haposto.domain.model.AvailabilityStatus
import com.haposto.domain.model.Restaurant
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow

/** Makes a partial/invalid local.properties visible as a normal Home error instead of an app crash. */
class ConfigurationErrorRestaurantRepository(
    private val message: String,
) : RestaurantRepository, RestaurantRepositoryMetadata {
    override val dataSource = RestaurantDataSource.CONFIGURATION_ERROR

    override fun observeRestaurants(): Flow<List<Restaurant>> = flow {
        throw IllegalStateException(message)
    }

    override fun findById(id: String): Restaurant? = null

    override suspend fun publishAvailability(
        restaurantId: String,
        status: AvailabilityStatus,
        availableTables: Int?,
        estimatedWaitMinutes: Int?,
        note: String?,
    ): Boolean = false

    override suspend fun setPhonePublic(restaurantId: String, isPublic: Boolean): Boolean = false
}
