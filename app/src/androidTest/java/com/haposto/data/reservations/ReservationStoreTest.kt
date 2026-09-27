package com.haposto.data.reservations

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import java.io.File
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class ReservationStoreTest {

    private val context = InstrumentationRegistry.getInstrumentation().targetContext
    private val restaurantId = "store-test"
    private val legacyFile = File(context.filesDir, "reservations_$restaurantId.json")
    private val storedFile = File(context.filesDir, "reservations/reservations_$restaurantId.json")

    @After
    fun cleanUp() {
        legacyFile.delete()
        storedFile.delete()
    }

    @Test
    fun saveThenLoad_roundTripsInTheBackupExcludedFolder() {
        val items = listOf(
            Reservation(id = "1", name = "Rossi", time = "20:30", partySize = 4, table = "12"),
            Reservation(id = "2", name = "Bianchi", time = "21", partySize = 2),
        )

        ReservationStore(context, restaurantId).save(items)

        assertTrue(storedFile.exists())
        assertEquals(items, ReservationStore(context, restaurantId).load())
    }

    @Test
    fun fileFromPreviousBuilds_isMovedIntoTheNewFolder() {
        legacyFile.writeText("""[{"id":"1","name":"Verdi","time":"19:45","partySize":3}]""")

        val loaded = ReservationStore(context, restaurantId).load()

        assertEquals(listOf("Verdi"), loaded.map { it.name })
        assertFalse(legacyFile.exists())
        assertTrue(storedFile.exists())
    }
}
