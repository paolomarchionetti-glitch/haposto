buildscript {
    dependencies {
        // AGP 9 uses built-in Kotlin. Keep KGP aligned with the Compose/Serialization compiler
        // plugins used by this project instead of falling back to AGP's older runtime KGP.
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.4.10")
    }
}

plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.compose.compiler) apply false
    alias(libs.plugins.kotlin.serialization) apply false
}
