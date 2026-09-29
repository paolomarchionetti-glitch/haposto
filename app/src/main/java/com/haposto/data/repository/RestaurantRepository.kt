package com.haposto.data.repository

import com.haposto.data.ErrorMessages
import com.haposto.data.Outcome
import com.haposto.domain.model.AvailabilityStatus
import com.haposto.domain.model.Restaurant
import kotlinx.coroutines.flow.Flow

/**
 * Repository boundary shared by consumer and restaurant-manager flows.
 *
 * STEP 6 freezes this as the V1 pre-backend contract. The in-memory implementation is the reference
 * behavior; STEP 7 must implement the same boundary with Supabase without changing the Compose UI.
 */
interface RestaurantRepository {
    fun observeRestaurants(): Flow<List<Restaurant>>
    fun findById(id: String): Restaurant?

    /**
     * Publishes/refreshes the live state for an ACTIVE_PARTNER restaurant.
     * A successful publish always creates a new server-equivalent timestamp and a 30 minute TTL.
     * FULL never exposes a positive available-table count.
     */
    suspend fun publishAvailability(
        restaurantId: String,
        status: AvailabilityStatus,
        availableTables: Int? = null,
        estimatedWaitMinutes: Int? = null,
        note: String? = null,
    ): Boolean

    /** Enables/disables the public phone number without changing the live availability timestamp. */
    suspend fun setPhonePublic(
        restaurantId: String,
        isPublic: Boolean,
    ): Boolean

    /**
     * Like [publishAvailability] but with the reason of a failure (e.g. "MFA_REQUIRED"), so the
     * dashboard can tell the manager exactly what to do.
     */
    suspend fun publishAvailabilityResult(
        restaurantId: String,
        status: AvailabilityStatus,
        availableTables: Int? = null,
        estimatedWaitMinutes: Int? = null,
        note: String? = null,
    ): Outcome<Unit> =
        if (publishAvailability(restaurantId, status, availableTables, estimatedWaitMinutes, note)) {
            Outcome.Success(Unit)
        } else {
            ErrorMessages.failure("UNKNOWN")
        }

    /** Asks for fresh data now (e.g. a Realtime change arrived). No-op for local repositories. */
    fun requestRefresh() = Unit
}
