package com.haposto

import android.content.Context
import com.haposto.data.favorites.FavoritesStore
import com.haposto.data.fake.FakeRestaurantAccessRepository
import com.haposto.data.fake.FakeRestaurantRepository
import com.haposto.data.location.AndroidDeviceLocationProvider
import com.haposto.data.location.DeviceLocationProvider
import com.haposto.data.location.LocationSession
import com.haposto.data.network.AndroidNetworkMonitor
import com.haposto.data.network.NetworkMonitor
import com.haposto.data.remote.supabase.ConfigurationErrorRestaurantRepository
import com.haposto.data.remote.supabase.SupabaseClientProvider
import com.haposto.data.remote.supabase.SupabaseRestaurantRepository
import com.haposto.data.repository.RestaurantAccessRepository
import com.haposto.data.repository.RestaurantRepository

object AppDependencies {

    val locationSession: LocationSession by lazy { LocationSession() }

    /**
     * STEP 7 behavior:
     * - no Supabase values -> local fallback, useful for UI work;
     * - valid Project URL + publishable key -> real Supabase read path;
     * - partial/invalid values -> visible Home error instead of silently falling back.
     */
    val restaurantRepository: RestaurantRepository by lazy {
        val config = SupabaseClientProvider.configuration
        when {
            config.isAbsent -> FakeRestaurantRepository()
            config.validationError() != null -> ConfigurationErrorRestaurantRepository(
                message = config.validationError().orEmpty(),
            )
            else -> SupabaseRestaurantRepository(
                client = SupabaseClientProvider.client,
                locationSession = locationSession,
            )
        }
    }

    /** Real Supabase Auth/claim starts in STEP 8. */
    val restaurantAccessRepository: RestaurantAccessRepository by lazy {
        FakeRestaurantAccessRepository(restaurantRepository = restaurantRepository)
    }

    @Volatile
    private var favoritesStore: FavoritesStore? = null

    /** Un solo archivio preferiti per tutta l'app, così dettaglio e tab restano allineati. */
    fun favorites(context: Context): FavoritesStore =
        favoritesStore ?: synchronized(this) {
            favoritesStore ?: FavoritesStore(context.applicationContext).also { favoritesStore = it }
        }

    fun deviceLocationProvider(context: Context): DeviceLocationProvider =
        AndroidDeviceLocationProvider(context.applicationContext)

    fun networkMonitor(context: Context): NetworkMonitor =
        AndroidNetworkMonitor(context.applicationContext)
}
