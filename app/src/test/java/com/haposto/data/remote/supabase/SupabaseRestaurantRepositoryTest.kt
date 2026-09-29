package com.haposto.data.remote.supabase

import com.haposto.data.ErrorMessages
import com.haposto.data.Outcome
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
        val radiusCalls = mutableListOf<Int>()
        var failuresToThrow = 0
        var publishAttempts = 0
        /** null = the database accepts the publication and stores it like the real function. */
        var publishError: String? = null

        override suspend fun nearby(latitude: Double, longitude: Double, radiusMeters: Int): List<Restaurant> {
            nearbyCalls += latitude to longitude
            radiusCalls += radiusMeters
            if (failuresToThrow > 0) {
                failuresToThrow--
                throw IllegalStateException("Rete non disponibile")
            }
            return rows
        }

        override suspend fun publishLiveStatus(
            restaurantId: String,
            status: AvailabilityStatus,
            availableTables: Int?,
            estimatedWaitMinutes: Int?,
            note: String?,
        ): Outcome<Unit> {
            publishAttempts++
            publishError?.let { return ErrorMessages.failure(it) }
            rows = rows.map { if (it.id == restaurantId) it.withStatus(status) else it }
            return Outcome.Success(Unit)
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
    fun aRefusedPublicationChangesNothingAndTellsWhy() = runTest {
        val api = FakeDirectoryApi(listOf(levante)).apply { publishError = "MFA_REQUIRED" }
        val repository = repository(api)
        val emissions = collect(repository)

        val result = repository.publishAvailabilityResult(levante.id, AvailabilityStatus.FULL)
        runCurrent()

        assertEquals("MFA_REQUIRED", (result as Outcome.Failure).code)
        assertEquals(levante.liveAvailability?.status, emissions.lastStatus())
        assertEquals(1, api.nearbyCalls.size)
    }

    @Test
    fun anAcceptedPublicationIsShownAtOnceAndThenFollowsTheServer() = runTest {
        val api = FakeDirectoryApi(listOf(levante))
        val repository = repository(api)
        val emissions = collect(repository)

        assertTrue(repository.publishAvailability(levante.id, AvailabilityStatus.FULL))
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

    @Test
    fun aRealtimeSignalRefreshesWithoutWaitingAMinute() = runTest {
        val api = FakeDirectoryApi(listOf(levante))
        val repository = repository(api)
        val emissions = collect(repository)

        api.rows = listOf(levante.withStatus(AvailabilityStatus.LIMITED))
        repository.requestRefresh()
        runCurrent()

        assertEquals(2, api.nearbyCalls.size)
        assertEquals(AvailabilityStatus.LIMITED, emissions.lastStatus())
    }

    @Test
    fun plusSearchesAWiderArea() = runTest {
        val api = FakeDirectoryApi(listOf(levante))
        val repository = repository(api)
        collect(repository)

        repository.setSearchRadiusKm(100)
        advanceTimeBy(200)
        runCurrent()

        assertEquals(listOf(60_000, 100_000), api.radiusCalls)
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
