import java.util.Properties
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.compose.compiler)
    alias(libs.plugins.kotlin.serialization)
}

val localProperties = Properties().apply {
    val localFile = rootProject.file("local.properties")
    if (localFile.exists()) {
        localFile.inputStream().use(::load)
    }
}

/** First non-blank value among [names], from local.properties or the environment (CI). */
fun localValue(vararg names: String): String =
    names.firstNotNullOfOrNull { name ->
        (localProperties.getProperty(name) ?: System.getenv(name))
            ?.trim()
            ?.takeIf(String::isNotEmpty)
    } ?: ""

fun String.asBuildConfigString(): String =
    "\"${replace("\\", "\\\\").replace("\"", "\\\"")}\""

/**
 * Per-environment values. DEV keeps accepting the pre-flavor keys SUPABASE_URL /
 * SUPABASE_PUBLISHABLE_KEY so an existing local.properties keeps working.
 */
fun com.android.build.api.dsl.ApplicationProductFlavor.environment(
    name: String,
    supabaseUrl: String,
    supabaseKey: String,
    firebasePrefix: String,
) {
    buildConfigField("String", "HAPOSTO_ENV", name.asBuildConfigString())
    buildConfigField("String", "SUPABASE_URL", supabaseUrl.asBuildConfigString())
    buildConfigField("String", "SUPABASE_PUBLISHABLE_KEY", supabaseKey.asBuildConfigString())
    buildConfigField(
        "String",
        "GOOGLE_WEB_CLIENT_ID",
        localValue("GOOGLE_WEB_CLIENT_ID_$name", "GOOGLE_WEB_CLIENT_ID").asBuildConfigString(),
    )
    // Firebase (solo notifiche push e report crash): facoltativo, senza file google-services.json.
    listOf("APP_ID", "API_KEY", "PROJECT_ID", "SENDER_ID").forEach { key ->
        val value = if (firebasePrefix.isEmpty()) "" else localValue("${firebasePrefix}_$key")
        buildConfigField("String", "FIREBASE_$key", value.asBuildConfigString())
    }
}

android {
    namespace = "com.haposto"
    compileSdk = 37

    defaultConfig {
        applicationId = "com.haposto"
        minSdk = 26
        targetSdk = 37
        versionCode = 9
        versionName = "0.9.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"

        buildConfigField(
            "String",
            "PUBLIC_SITE_URL",
            localValue("PUBLIC_SITE_URL").ifEmpty { "https://haposto.app" }.asBuildConfigString(),
        )
        manifestPlaceholders["appLabel"] = "HAPOSTO"
    }

    // Tre versioni installabili insieme sullo stesso telefono:
    //  - demo: dati finti nel telefono, nessun server (prove dell'interfaccia, test automatici);
    //  - dev:  progetto Supabase DEV (dati di prova, simulatore);
    //  - prod: progetto Supabase di produzione (utenti e locali veri).
    flavorDimensions += "environment"
    productFlavors {
        create("demo") {
            dimension = "environment"
            applicationIdSuffix = ".demo"
            versionNameSuffix = "-demo"
            manifestPlaceholders["appLabel"] = "HAPOSTO Demo"
            environment(name = "DEMO", supabaseUrl = "", supabaseKey = "", firebasePrefix = "")
        }
        create("dev") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            manifestPlaceholders["appLabel"] = "HAPOSTO Dev"
            environment(
                name = "DEV",
                supabaseUrl = localValue("SUPABASE_DEV_URL", "SUPABASE_URL"),
                supabaseKey = localValue("SUPABASE_DEV_PUBLISHABLE_KEY", "SUPABASE_PUBLISHABLE_KEY"),
                firebasePrefix = "FIREBASE_DEV",
            )
        }
        create("prod") {
            dimension = "environment"
            manifestPlaceholders["appLabel"] = "HAPOSTO"
            environment(
                name = "PROD",
                supabaseUrl = localValue("SUPABASE_PROD_URL"),
                supabaseKey = localValue("SUPABASE_PROD_PUBLISHABLE_KEY"),
                firebasePrefix = "FIREBASE_PROD",
            )
        }
    }

    // Firma di rilascio: SOLO da local.properties (mai in GitHub). Senza questi valori la build
    // release resta non firmata e Android Studio chiede la chiave con "Generate Signed Bundle".
    val keystorePath = localValue("HAPOSTO_KEYSTORE_FILE")
    if (keystorePath.isNotEmpty()) {
        signingConfigs {
            create("release") {
                storeFile = file(keystorePath)
                storePassword = localValue("HAPOSTO_KEYSTORE_PASSWORD")
                keyAlias = localValue("HAPOSTO_KEY_ALIAS")
                keyPassword = localValue("HAPOSTO_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        getByName("release") {
            if (keystorePath.isNotEmpty()) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

dependencies {
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.activity.compose)
    implementation(libs.androidx.lifecycle.runtime.ktx)
    implementation(libs.androidx.lifecycle.runtime.compose)
    implementation(libs.androidx.lifecycle.viewmodel.compose)
    implementation(libs.androidx.lifecycle.viewmodel.savedstate)
    implementation(libs.androidx.navigation.compose)

    val composeBom = platform(libs.androidx.compose.bom)
    implementation(composeBom)
    androidTestImplementation(composeBom)

    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.compose.ui.tooling.preview)
    implementation(libs.androidx.compose.material3)
    debugImplementation(libs.androidx.compose.ui.tooling)
    debugImplementation(libs.androidx.compose.ui.test.manifest)

    // Supabase: directory (PostgREST), account (Auth, con 2FA), aggiornamenti in tempo reale.
    implementation(platform(libs.supabase.bom))
    implementation(libs.supabase.postgrest)
    implementation(libs.supabase.auth)
    implementation(libs.supabase.realtime)
    implementation(libs.supabase.functions)
    implementation(libs.ktor.client.okhttp)
    implementation(libs.kotlinx.serialization.json)

    // Accesso con Google (Credential Manager, gratuito).
    implementation(libs.androidx.credentials)
    implementation(libs.androidx.credentials.play.services.auth)
    implementation(libs.googleid)

    // Mappa: MapLibre (open source) con le mappe gratuite di OpenFreeMap (dati OpenStreetMap).
    implementation(libs.maplibre.android)

    // QR code generati sul telefono.
    implementation(libs.zxing.core)

    // Promemoria locali al ristoratore (anche senza server notifiche).
    implementation(libs.androidx.work.runtime)

    // Notifiche push (Firebase Cloud Messaging, gratuito), configurazione facoltativa.
    implementation(platform(libs.firebase.bom))
    implementation(libs.firebase.messaging)

    // Abbonamento HAPOSTO Plus (Google Play Billing).
    implementation(libs.play.billing)

    testImplementation(libs.junit)
    testImplementation(libs.kotlinx.coroutines.test)
    androidTestImplementation(libs.androidx.junit)
    androidTestImplementation(libs.androidx.espresso.core)
    androidTestImplementation(libs.androidx.compose.ui.test.junit4)
}
