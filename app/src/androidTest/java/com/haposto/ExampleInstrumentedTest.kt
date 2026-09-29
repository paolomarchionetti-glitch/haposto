package com.haposto

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class ExampleInstrumentedTest {
    @Test
    fun appContextUsesExpectedPackage() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        // com.haposto (PROD), com.haposto.dev (DEV) o com.haposto.demo (DEMO).
        assertEquals(BuildConfig.APPLICATION_ID, context.packageName)
        assertTrue(context.packageName.startsWith("com.haposto"))
    }
}
