package com.haposto.data.remote.supabase

import com.haposto.data.fake.FakeRestaurantRepository
import com.haposto.data.location.LocationSession
import com.haposto.domain.model.AvailabilityStatus
import com.haposto.domain.model.LiveAvailability
import com.haposto.domain.model.ManualArea
import com.haposto.domain.model.Restaurant
import java.time.Instant
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class SupabaseRestaurantRepositoryTest {

    private val levante = FakeRestaurantRepository().findById("levante-demo")!!

    private class FakeDirectoryApi(var rows: List<Restaurant>) : DirectoryApi {
        val nearbyCalls = mutableListOf<Pair<Double, Double>>()
        var failuresToThrow = 0
        var devPublishAttempts = 0
        /** null = the DEV function exists and stores the status like the real one. */
        var devPublishError: Exception? = IllegalStateException("PGRST202 Could not find the function")

        override suspend fun nearby(latitude: Double, longitude: Double, radiusMeters: Int): List<Restaurant> {
            nearbyCalls += latitude to longitude
            if (failuresToThrow > 0) {
                failuresToThrow--
                throw IllegalStateException("Rete non disponibile")
            }
            return rows
        }

        override suspend fun devPublishLiveStatus(
            restaurantId: String,
            status: AvailabilityStatus,
            availableTables: Int?,
            estimatedWaitMinutes: Int?,
            note: String?,
        ) {
            devPublishAttempts++
            devPublishError?.let { throw it }
            rows = rows.map { if (it.id == restaurantId) it.withStatus(status) else it }
        }
    }

    private fun repository(api: FakeDirectoryApi, session: LocationSession = LocationSession()) =
        SupabaseRestaurantRepository(api = api, locationSession = session, refreshIntervalMillis = 60_000)

    private fun TestScope.collect(repository: SupabaseRestaurantRepository): MutableList<List<Restaurant>> {
        val emissions = mutableListOf<List<Restaurant>>()
        backgroundScope.launch { repository.observeRestaurants().collect { emissions += it } }
        advanceTimeBy(200)
        runCurrent()
        return emissions
    }

    private fun List<List<Restaurant>>.lastStatus() = last().single().liveAvailability?.status

    @Test
    fun directoryIsRefreshedEveryMinute() = runTest {
        val api = FakeDirectoryApi(listOf(levante))
        val emissions = collect(repository(api))
        assertEquals(1, api.nearbyCalls.size)

        api.rows = listOf(levante.withStatus(AvailabilityStatus.FULL))
        advanceTimeBy(60_001)
        runCurrent()

        assertEquals(2, api.nearbyCalls.size)
        assertEquals(AvailabilityStatus.FULL, emissions.lastStatus())
    }

    @Test
    fun aFailedRefreshKeepsTheLastListOnScreen() = runTest {
        val api = FakeDirectoryApi(listOf(levante))
        val emissions = collect(repository(api))

        api.failuresToThrow = 1
        advanceTimeBy(60_001)
        runCurrent()
        assertEquals(1, emissions.size)
        assertEquals(listOf(levante.id), emissions.last().map { it.id })

        api.rows = listOf(levante.withStatus(AvailabilityStatus.LIMITED))
        advanceTimeBy(60_001)
        runCurrent()
        assertEquals(AvailabilityStatus.LIMITED, emissions.lastStatus())
    }

    @Test
    fun aFailedFirstLoadIsReportedToTheScreen() = runTest {
        val api = FakeDirectoryApi(listOf(levante)).apply { failuresToThrow = 1 }

        val error = runCatching { repository(api).observeRestaurants().first() }.exceptionOrNull()

        assertEquals("Rete non disponibile", error?.message)
    }

    @Test
    fun changingAreaReloadsAroundTheNewCentre() = runTest {
        val session = LocationSession()
        val api = FakeDirectoryApi(listOf(levante))
        collect(repository(api, session))

        session.useManualArea(ManualArea.FANO)
        advanceTimeBy(200)
        runCurrent()

        assertEquals(ManualArea.FANO.center.latitude, api.nearbyCalls.last().first, 0.0)
    }

    @Test
    fun withoutDevToolsTheChangeStaysLocalAndIsNotRetried() = runTest {
        val api = FakeDirectoryApi(listOf(levante))
        val repository = repository(api)
        val emissions = collect(repository)

        assertTrue(repository.publishAvailability(levante.id, AvailabilityStatus.FULL))
        runCurrent()
        assertEquals(AvailabilityStatus.FULL, emissions.lastStatus())

        // The backend still says AVAILABLE: the local change stays visible after a refresh.
        advanceTimeBy(60_001)
        runCurrent()
        assertEquals(AvailabilityStatus.FULL, emissions.lastStatus())

        repository.publishAvailability(levante.id, AvailabilityStatus.LIMITED)
        assertEquals(1, api.devPublishAttempts)
    }

    @Test
    fun withDevToolsTheChangeIsStoredAndThenFollowsTheServer() = runTest {
        val api = FakeDirectoryApi(listOf(levante)).apply { devPublishError = null }
        val repository = repository(api)
        val emissions = collect(repository)

        repository.publishAvailability(levante.id, AvailabilityStatus.FULL)
        runCurrent()
        assertEquals(AvailabilityStatus.FULL, emissions.lastStatus())
        // A successful write asks for an immediate refresh instead of waiting a minute.
        assertEquals(2, api.nearbyCalls.size)

        // Later someone else (another phone, the simulator) changes it: this phone follows.
        api.rows = listOf(levante.withStatus(AvailabilityStatus.LIMITED))
        advanceTimeBy(60_001)
        runCurrent()
        assertEquals(AvailabilityStatus.LIMITED, emissions.lastStatus())
    }
}

private fun Restaurant.withStatus(status: AvailabilityStatus): Restaurant {
    val now = Instant.now()
    return copy(
        liveAvailability = LiveAvailability(
            status = status,
            updatedAt = now,
            validUntil = now.plusSeconds(30 * 60),
        ),
    )
}
