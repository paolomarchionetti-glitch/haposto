package com.haposto

import android.content.Context
import com.haposto.config.AppConfig
import com.haposto.config.AppEnvironment
import com.haposto.data.admin.AdminRepository
import com.haposto.data.auth.AuthRepository
import com.haposto.data.auth.AuthState
import com.haposto.data.auth.UnavailableAuthRepository
import com.haposto.data.consumer.ConsumerRepository
import com.haposto.data.consumer.UnavailableConsumerRepository
import com.haposto.data.favorites.FavoritesStore
import com.haposto.data.fake.FakeRestaurantAccessRepository
import com.haposto.data.fake.FakeRestaurantRepository
import com.haposto.data.location.AndroidDeviceLocationProvider
import com.haposto.data.location.DeviceLocationProvider
import com.haposto.data.location.LocationSession
import com.haposto.data.network.AndroidNetworkMonitor
import com.haposto.data.network.NetworkMonitor
import com.haposto.data.remote.supabase.ConfigurationErrorRestaurantRepository
import com.haposto.data.remote.supabase.LiveStatusRealtime
import com.haposto.data.remote.supabase.SecureSessionManager
import com.haposto.data.remote.supabase.SupabaseAdminRepository
import com.haposto.data.remote.supabase.SupabaseAuthRepository
import com.haposto.data.remote.supabase.SupabaseClientProvider
import com.haposto.data.remote.supabase.SupabaseConsumerRepository
import com.haposto.data.remote.supabase.SupabaseManagementRepository
import com.haposto.data.remote.supabase.SupabaseRestaurantRepository
import com.haposto.data.repository.RestaurantAccessRepository
import com.haposto.data.repository.RestaurantRepository
import com.haposto.data.restaurant.RestaurantManagementRepository
import com.haposto.platform.notifications.PushMessaging
import com.haposto.platform.security.KeystoreSecretStore
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch

/**
 * Composizione dell'app. Tre versioni:
 * - DEMO: dati dimostrativi nel telefono, nessun account (flusso ristoratore simulato);
 * - DEV / PROD: Supabase con account reali, 2FA per i ristoratori, pannello admin, Plus.
 */
object AppDependencies {

    val environment: AppEnvironment = AppConfig.environment

    /** Coroutine dell'app intera (sessione, realtime, sincronizzazioni). */
    val appScope: CoroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    @Volatile
    private var initialized = false

    /**
     * Da chiamare all'avvio (Application) e da ogni punto d'ingresso in background (notifiche):
     * prepara la sessione cifrata prima che il client Supabase venga creato.
     */
    fun init(context: Context) {
        if (initialized) return
        synchronized(this) {
            if (initialized) return
            val appContext = context.applicationContext
            if (usesBackend) {
                SupabaseClientProvider.useSessionManager(SecureSessionManager(KeystoreSecretStore(appContext)))
            }
            initialized = true
        }
    }

    /** true = versione DEV/PROD con Supabase configurato correttamente. */
    val usesBackend: Boolean
        get() = environment.usesBackend && SupabaseClientProvider.isConfigured

    val locationSession: LocationSession by lazy { LocationSession() }

    /**
     * - DEMO: dati locali di prova;
     * - DEV/PROD configurati: Supabase;
     * - DEV/PROD con configurazione mancante o sbagliata: errore visibile in Home (mai dati finti).
     */
    val restaurantRepository: RestaurantRepository by lazy {
        val config = SupabaseClientProvider.configuration
        when {
            !environment.usesBackend -> FakeRestaurantRepository()
            config.isAbsent -> ConfigurationErrorRestaurantRepository(
                message = "Questa è la versione ${environment.name}: in local.properties mancano indirizzo e chiave " +
                    "Supabase (vedi docs/HAPOSTO_GUIDA_CONFIGURAZIONE_COMPLETA.md).",
            )
            config.validationError() != null -> ConfigurationErrorRestaurantRepository(
                message = config.validationError().orEmpty(),
            )
            else -> SupabaseRestaurantRepository(
                client = SupabaseClientProvider.client,
                locationSession = locationSession,
            )
        }
    }

    /** Solo DEMO: accesso ristoratore simulato (nessun account vero). */
    val restaurantAccessRepository: RestaurantAccessRepository by lazy {
        FakeRestaurantAccessRepository(restaurantRepository = restaurantRepository)
    }

    val authRepository: AuthRepository by lazy {
        if (usesBackend) SupabaseAuthRepository(SupabaseClientProvider.client, appScope) else UnavailableAuthRepository()
    }

    val managementRepository: RestaurantManagementRepository? by lazy {
        if (usesBackend) SupabaseManagementRepository(SupabaseClientProvider.client) else null
    }

    val adminRepository: AdminRepository? by lazy {
        if (usesBackend) SupabaseAdminRepository(SupabaseClientProvider.client) else null
    }

    val consumerRepository: ConsumerRepository by lazy {
        if (usesBackend) SupabaseConsumerRepository(SupabaseClientProvider.client) else UnavailableConsumerRepository()
    }

    private val realtime: LiveStatusRealtime? by lazy {
        if (usesBackend) {
            LiveStatusRealtime(SupabaseClientProvider.client) { restaurantRepository.requestRefresh() }
        } else {
            null
        }
    }

    /**
     * Avvio dei servizi di sfondo (dopo [init]): tempo reale, raggio Plus, token notifiche.
     */
    fun startBackgroundServices(context: Context) {
        if (!usesBackend) return
        realtime?.start(appScope)
        PushMessaging.initialize(context.applicationContext)
        appScope.launch {
            authRepository.state
                .map { (it as? AuthState.SignedIn)?.user?.id }
                .distinctUntilChanged()
                .collect { userId ->
                    val entitlements = consumerRepository.entitlements().valueOrNull
                    (restaurantRepository as? SupabaseRestaurantRepository)
                        ?.setSearchRadiusKm(entitlements?.searchRadiusKm ?: 60)
                    if (userId != null) {
                        runCatching { PushMessaging.registerForCurrentUser() }
                        favorites(context).syncWithAccount()
                    }
                }
        }
    }

    @Volatile
    private var favoritesStore: FavoritesStore? = null

    /** Un solo archivio preferiti per tutta l'app, così dettaglio e tab restano allineati. */
    fun favorites(context: Context): FavoritesStore =
        favoritesStore ?: synchronized(this) {
            favoritesStore ?: FavoritesStore(
                context = context.applicationContext,
                remote = if (usesBackend) consumerRepository else null,
                scope = appScope,
            ).also { favoritesStore = it }
        }

    fun deviceLocationProvider(context: Context): DeviceLocationProvider =
        AndroidDeviceLocationProvider(context.applicationContext)

    fun networkMonitor(context: Context): NetworkMonitor =
        AndroidNetworkMonitor(context.applicationContext)
}
