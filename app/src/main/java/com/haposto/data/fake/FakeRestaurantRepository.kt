package com.haposto.data.fake

import com.haposto.data.repository.RestaurantDataSource
import com.haposto.data.repository.RestaurantRepository
import com.haposto.data.repository.RestaurantRepositoryMetadata
import com.haposto.domain.model.AvailabilityRules
import com.haposto.domain.model.AvailabilityStatus
import com.haposto.domain.model.GeoPoint
import com.haposto.domain.model.LiveAvailability
import com.haposto.domain.model.PartnershipStatus
import com.haposto.domain.model.Restaurant
import com.haposto.domain.usecase.AvailabilityResolver
import java.time.Clock
import java.time.Duration
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow

/**
 * STEP 3–6 local demo restaurant repository and V1 contract reference implementation.
 * All activities, addresses and phone numbers are fictional.
 * Coordinates are demo points placed around Pesaro/Fano/Urbino solely to test distance logic.
 */
class FakeRestaurantRepository(
    private val clock: Clock = Clock.systemUTC(),
) : RestaurantRepository, RestaurantRepositoryMetadata {

    override val dataSource: RestaurantDataSource = RestaurantDataSource.LOCAL_DEMO

    private val restaurants = MutableStateFlow(buildRestaurants(clock))

    override fun observeRestaurants(): Flow<List<Restaurant>> = restaurants

    override fun findById(id: String): Restaurant? = restaurants.value.firstOrNull { it.id == id }


    override suspend fun publishAvailability(
        restaurantId: String,
        status: AvailabilityStatus,
        availableTables: Int?,
        estimatedWaitMinutes: Int?,
        note: String?,
    ): Boolean {
        require(status in setOf(
            AvailabilityStatus.AVAILABLE,
            AvailabilityStatus.LIMITED,
            AvailabilityStatus.FULL,
        )) { "Only restaurant-published live states may be published." }
        require(availableTables == null || availableTables in 0..AvailabilityRules.MAX_AVAILABLE_TABLES)
        require(estimatedWaitMinutes == null || estimatedWaitMinutes in 0..AvailabilityRules.MAX_ESTIMATED_WAIT_MINUTES)
        require(note == null || note.length <= AvailabilityRules.MAX_NOTE_LENGTH)

        val current = restaurants.value
        val index = current.indexOfFirst { it.id == restaurantId }
        if (index == -1) return false

        val restaurant = current[index]
        if (restaurant.partnershipStatus != PartnershipStatus.ACTIVE_PARTNER) return false

        val now = clock.instant()
        val updated = restaurant.copy(
            liveAvailability = LiveAvailability(
                status = status,
                updatedAt = now,
                validUntil = now.plus(Duration.ofMinutes(AvailabilityResolver.DEFAULT_TTL_MINUTES)),
                availableTables = if (status == AvailabilityStatus.FULL) null else availableTables,
                estimatedWaitMinutes = estimatedWaitMinutes,
                note = note?.trim()?.takeIf { it.isNotEmpty() },
            ),
        )
        restaurants.value = current.toMutableList().also { it[index] = updated }
        return true
    }

    override suspend fun setPhonePublic(
        restaurantId: String,
        isPublic: Boolean,
    ): Boolean {
        val current = restaurants.value
        val index = current.indexOfFirst { it.id == restaurantId }
        if (index == -1) return false

        val restaurant = current[index]
        if (restaurant.partnershipStatus != PartnershipStatus.ACTIVE_PARTNER) return false
        if (isPublic && restaurant.phoneNumber.isNullOrBlank()) return false

        restaurants.value = current.toMutableList().also {
            it[index] = restaurant.copy(phonePublic = isPublic)
        }
        return true
    }

    private fun buildRestaurants(clock: Clock): List<Restaurant> {
        val now = clock.instant()

        fun live(
            status: AvailabilityStatus,
            minutesAgo: Long,
            tables: Int? = null,
            wait: Int? = null,
            note: String? = null,
            ttlMinutes: Long = 30,
        ): LiveAvailability {
            val updatedAt = now.minus(Duration.ofMinutes(minutesAgo))
            return LiveAvailability(
                status = status,
                updatedAt = updatedAt,
                validUntil = updatedAt.plus(Duration.ofMinutes(ttlMinutes)),
                availableTables = tables,
                estimatedWaitMinutes = wait,
                note = note,
            )
        }

        return listOf(
            Restaurant(
                id = "levante-demo",
                name = "Osteria Levante",
                category = "Cucina italiana",
                address = "Via Demo 12, Pesaro",
                city = "Pesaro",
                location = GeoPoint(43.9102, 12.9149),
                partnershipStatus = PartnershipStatus.ACTIVE_PARTNER,
                liveAvailability = live(
                    status = AvailabilityStatus.AVAILABLE,
                    minutesAgo = 3,
                    tables = 4,
                    note = "Disponibili anche tavoli all'esterno",
                ),
                phoneNumber = "+390721000001",
                phonePublic = true,
            ),
            Restaurant(
                id = "porto-46-demo",
                name = "Porto 46",
                category = "Pesce",
                address = "Viale Esempio 46, Pesaro",
                city = "Pesaro",
                location = GeoPoint(43.9173, 12.9004),
                partnershipStatus = PartnershipStatus.ACTIVE_PARTNER,
                liveAvailability = live(
                    status = AvailabilityStatus.LIMITED,
                    minutesAgo = 7,
                    tables = 1,
                    wait = 10,
                    note = "Ultimi tavoli per piccoli gruppi",
                ),
            ),
            Restaurant(
                id = "corte-demo",
                name = "Corte Adriatica",
                category = "Contemporanea",
                address = "Piazza Demo 8, Pesaro",
                city = "Pesaro",
                location = GeoPoint(43.9090, 12.9120),
                partnershipStatus = PartnershipStatus.ACTIVE_PARTNER,
                liveAvailability = live(
                    status = AvailabilityStatus.FULL,
                    minutesAgo = 2,
                ),
            ),
            Restaurant(
                id = "forno-demo",
                name = "Forno del Mare",
                category = "Pizza",
                address = "Via Prototipo 21, Pesaro",
                city = "Pesaro",
                location = GeoPoint(43.9148, 12.9055),
                partnershipStatus = PartnershipStatus.ACTIVE_PARTNER,
                liveAvailability = live(
                    status = AvailabilityStatus.AVAILABLE,
                    minutesAgo = 12,
                    tables = 2,
                ),
                phoneNumber = "+390721000004",
                phonePublic = true,
            ),
            Restaurant(
                id = "miralfiore-demo",
                name = "Casa Miralfiore",
                category = "Tradizionale",
                address = "Via Scenario 5, Pesaro",
                city = "Pesaro",
                location = GeoPoint(43.9003, 12.9081),
                partnershipStatus = PartnershipStatus.ACTIVE_PARTNER,
                liveAvailability = live(
                    status = AvailabilityStatus.AVAILABLE,
                    minutesAgo = 41,
                    tables = 3,
                ),
            ),
            Restaurant(
                id = "riva-demo",
                name = "Riva 27",
                category = "Mediterranea",
                address = "Lungomare Demo 27, Pesaro",
                city = "Pesaro",
                location = GeoPoint(43.9210, 12.8985),
                partnershipStatus = PartnershipStatus.DIRECTORY_ONLY,
            ),
            Restaurant(
                id = "borgo-demo",
                name = "Borgo Ventuno",
                category = "Carne e griglia",
                address = "Strada Test 21, Pesaro",
                city = "Pesaro",
                location = GeoPoint(43.8946, 12.9277),
                partnershipStatus = PartnershipStatus.ACTIVE_PARTNER,
                liveAvailability = live(
                    status = AvailabilityStatus.LIMITED,
                    minutesAgo = 18,
                    wait = 20,
                ),
            ),
            Restaurant(
                id = "faro-demo",
                name = "Tavola del Faro",
                category = "Pesce",
                address = "Via Mock 3, Pesaro",
                city = "Pesaro",
                location = GeoPoint(43.9240, 12.9024),
                partnershipStatus = PartnershipStatus.DIRECTORY_ONLY,
            ),
            Restaurant(
                id = "linea-demo",
                name = "Linea Cucina",
                category = "Vegetariana",
                address = "Via Campione 14, Fano",
                city = "Fano",
                location = GeoPoint(43.8411, 13.0178),
                partnershipStatus = PartnershipStatus.ACTIVE_PARTNER,
                liveAvailability = live(
                    status = AvailabilityStatus.AVAILABLE,
                    minutesAgo = 1,
                    tables = 5,
                    note = "Servizio cena iniziato",
                ),
            ),
            Restaurant(
                id = "civico-demo",
                name = "Civico Zero",
                category = "Bistrot",
                address = "Via Placeholder 1, Urbino",
                city = "Urbino",
                location = GeoPoint(43.7261, 12.6388),
                partnershipStatus = PartnershipStatus.ACTIVE_PARTNER,
                liveAvailability = null,
            ),
        )
    }
}
