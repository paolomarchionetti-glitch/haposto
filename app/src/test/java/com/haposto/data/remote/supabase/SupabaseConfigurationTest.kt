package com.haposto.data.remote.supabase

import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test

class SupabaseConfigurationTest {

    @Test
    fun emptyConfigurationIsAllowedAsExplicitLocalFallback() {
        val config = SupabaseConfiguration(url = "", publishableKey = "")
        assertNull(config.validationError())
    }

    @Test
    fun partialConfigurationIsRejected() {
        val config = SupabaseConfiguration(
            url = "https://example.supabase.co",
            publishableKey = "",
        )
        assertNotNull(config.validationError())
    }

    @Test
    fun secretKeyIsRejected() {
        val config = SupabaseConfiguration(
            url = "https://example.supabase.co",
            publishableKey = "sb_secret_never_ship_this",
        )
        assertNotNull(config.validationError())
    }

    @Test
    fun modernPublishableKeyIsAccepted() {
        val config = SupabaseConfiguration(
            url = "https://example.supabase.co",
            publishableKey = "sb_publishable_example",
        )
        assertNull(config.validationError())
    }
}
