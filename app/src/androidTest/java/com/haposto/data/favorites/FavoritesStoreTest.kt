package com.haposto.data.favorites

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class FavoritesStoreTest {

    private val context = InstrumentationRegistry.getInstrumentation().targetContext

    @After
    fun cleanUp() {
        context.getSharedPreferences("haposto_favorites", 0).edit().clear().commit()
    }

    @Test
    fun toggle_savesAndRemoves_andSurvivesANewInstance() {
        val store = FavoritesStore(context)
        store.toggle("levante-demo")
        store.toggle("porto-46-demo")
        store.toggle("porto-46-demo")

        assertEquals(setOf("levante-demo"), store.ids.value)
        assertEquals(setOf("levante-demo"), FavoritesStore(context).ids.value)

        store.toggle("levante-demo")
        assertTrue(FavoritesStore(context).ids.value.isEmpty())
    }
}
