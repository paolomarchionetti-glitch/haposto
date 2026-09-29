package com.haposto.config

import com.haposto.BuildConfig

/**
 * Le tre versioni dell'app (product flavor):
 * - [DEMO]: dati dimostrativi nel telefono, nessun server, nessun account vero;
 * - [DEV]: progetto Supabase DEV (dati di prova, simulatore, account di prova);
 * - [PROD]: progetto Supabase di produzione (utenti e locali veri).
 */
enum class AppEnvironment(val badge: String?) {
    DEMO("DEMO"),
    DEV("DEV"),
    PROD(null),
    ;

    val usesBackend: Boolean get() = this != DEMO

    companion object {
        fun fromName(name: String): AppEnvironment =
            entries.firstOrNull { it.name.equals(name.trim(), ignoreCase = true) } ?: DEMO
    }
}

/** Impostazioni di build lette una volta sola. Nessun segreto: solo valori pubblici. */
object AppConfig {
    val environment: AppEnvironment = AppEnvironment.fromName(BuildConfig.HAPOSTO_ENV)

    val publicSiteUrl: String = BuildConfig.PUBLIC_SITE_URL.trim().trimEnd('/')
        .ifEmpty { "https://haposto.app" }

    /** Client ID "Web" di Google Cloud: serve a Credential Manager e a Supabase Auth. */
    val googleWebClientId: String = BuildConfig.GOOGLE_WEB_CLIENT_ID.trim()

    val firebase: FirebaseSettings? = FirebaseSettings(
        applicationId = BuildConfig.FIREBASE_APP_ID.trim(),
        apiKey = BuildConfig.FIREBASE_API_KEY.trim(),
        projectId = BuildConfig.FIREBASE_PROJECT_ID.trim(),
        senderId = BuildConfig.FIREBASE_SENDER_ID.trim(),
    ).takeIf { it.isComplete }

    val versionCode: Int = BuildConfig.VERSION_CODE
    val versionName: String = BuildConfig.VERSION_NAME

    /** Indirizzo della pagina pubblica del locale (QR, condivisione). */
    fun publicRestaurantUrl(slug: String): String = "$publicSiteUrl/r/$slug"

    /** Documenti legali pubblicati sul sito (le stesse versioni sono incluse nell'app). */
    val privacyUrl: String get() = "$publicSiteUrl/privacy"
    val termsUrl: String get() = "$publicSiteUrl/termini"
    val restaurantTermsUrl: String get() = "$publicSiteUrl/termini-ristoranti"
    val deleteAccountUrl: String get() = "$publicSiteUrl/cancella-account"
}

data class FirebaseSettings(
    val applicationId: String,
    val apiKey: String,
    val projectId: String,
    val senderId: String,
) {
    val isComplete: Boolean
        get() = applicationId.isNotEmpty() && apiKey.isNotEmpty() && projectId.isNotEmpty() && senderId.isNotEmpty()
}
