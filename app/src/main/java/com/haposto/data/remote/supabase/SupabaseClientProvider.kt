package com.haposto.data.remote.supabase

import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.createSupabaseClient
import io.github.jan.supabase.postgrest.Postgrest
import com.haposto.BuildConfig

/**
 * STEP 7: first real Supabase activation.
 *
 * Android may contain only the Project URL and a low-privilege publishable key.
 * Never put sb_secret_*, service_role, database passwords or signing secrets in the APK.
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
            // STEP 7 intentionally installs only PostgREST.
            // Auth is activated in STEP 8 and Realtime in STEP 10.
            install(Postgrest)
        }
    }
}
