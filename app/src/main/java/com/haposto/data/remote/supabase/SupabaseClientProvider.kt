package com.haposto.data.remote.supabase

import com.haposto.BuildConfig
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.auth.Auth
import io.github.jan.supabase.auth.SessionManager
import io.github.jan.supabase.createSupabaseClient
import io.github.jan.supabase.functions.Functions
import io.github.jan.supabase.postgrest.Postgrest
import io.github.jan.supabase.realtime.Realtime

/**
 * Client Supabase unico dell'app (versioni DEV e PROD).
 *
 * Android contiene solo il Project URL e la chiave "publishable", che è pubblica per natura: la
 * sicurezza sta nelle regole del database (RLS e funzioni). Mai sb_secret_, service_role, password
 * del database o chiavi di firma nell'APK.
 */
object SupabaseClientProvider {

    val configuration: SupabaseConfiguration
        get() = SupabaseConfiguration(
            // The dashboard URL is sometimes copied with a trailing "/": accept it.
            url = BuildConfig.SUPABASE_URL.trim().trimEnd('/'),
            publishableKey = BuildConfig.SUPABASE_PUBLISHABLE_KEY.trim(),
        )

    val isConfigured: Boolean
        get() = configuration.isComplete && configuration.validationError() == null

    @Volatile
    private var sessionManager: SessionManager? = null

    /** Da chiamare all'avvio, prima di usare [client]: la sessione viene salvata cifrata. */
    fun useSessionManager(manager: SessionManager) {
        sessionManager = manager
    }

    val client: SupabaseClient by lazy {
        val config = configuration
        check(config.isComplete) {
            "Supabase non configurato. Copia local.properties.example in local.properties e inserisci Project URL + publishable key."
        }
        check(config.validationError() == null) { config.validationError().orEmpty() }

        createSupabaseClient(
            supabaseUrl = config.url,
            supabaseKey = config.publishableKey,
        ) {
            install(Auth) {
                sessionManager?.let { this.sessionManager = it }
                alwaysAutoRefresh = true
                autoLoadFromStorage = true
                autoSaveToStorage = true
            }
            install(Postgrest)
            install(Realtime)
            install(Functions)
        }
    }
}
