package com.haposto.ui.screens.restaurant

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.createSavedStateHandle
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import com.haposto.data.repository.RestaurantRepository
import com.haposto.domain.model.AvailabilityRules
import com.haposto.domain.model.AvailabilityStatus
import com.haposto.domain.model.EffectiveAvailability
import com.haposto.domain.usecase.AvailabilityResolver
import java.time.Instant
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

class RestaurantManagerViewModel(
    private val restaurantId: String,
    private val repository: RestaurantRepository,
    private val savedStateHandle: SavedStateHandle,
) : ViewModel() {

    private val availableTables = MutableStateFlow(
        savedStateHandle.get<Int>(KEY_TABLES)?.let(::decodeOptionalInt),
    )
    private val estimatedWaitMinutes = MutableStateFlow(
        savedStateHandle.get<Int>(KEY_WAIT)?.let(::decodeOptionalInt),
    )
    private val note = MutableStateFlow(savedStateHandle[KEY_NOTE] ?: "")
    private val isSaving = MutableStateFlow(false)
    private val message = MutableStateFlow<String?>(null)
    private var draftInitialized = savedStateHandle[KEY_INITIALIZED] ?: false

    private val draft = combine(
        availableTables,
        estimatedWaitMinutes,
        note,
        isSaving,
        message,
    ) { tables, wait, noteValue, saving, messageValue ->
        DraftState(tables, wait, noteValue, saving, messageValue)
    }

    val uiState = combine(
        // On a backend error keep the last known record so the dashboard stays usable instead of crashing.
        repository.observeRestaurants()
            .catch { emit(listOfNotNull(repository.findById(restaurantId))) },
        draft,
        clockTicker(),
    ) { restaurants, draft, now ->
        val restaurant = restaurants.firstOrNull { it.id == restaurantId }
        if (!draftInitialized && restaurant != null) {
            restaurant.liveAvailability?.let { live ->
                updateTables(live.availableTables)
                updateWait(live.estimatedWaitMinutes)
                updateNote(live.note.orEmpty())
            }
            draftInitialized = true
            savedStateHandle[KEY_INITIALIZED] = true
        }
        RestaurantManagerUiState(
            restaurant = restaurant,
            effectiveAvailability = restaurant?.let { AvailabilityResolver.resolve(it, now) }
                ?: EffectiveAvailability(AvailabilityStatus.STALE),
            now = now,
            availableTables = draft.tables,
            estimatedWaitMinutes = draft.wait,
            note = draft.note,
            isSaving = draft.saving,
            message = draft.message,
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = repository.findById(restaurantId)?.let { restaurant ->
            val initialNow = Instant.now()
            RestaurantManagerUiState(
                restaurant = restaurant,
                effectiveAvailability = AvailabilityResolver.resolve(restaurant, initialNow),
                now = initialNow,
                availableTables = if (savedStateHandle.get<Boolean>(KEY_INITIALIZED) == true) {
                    savedStateHandle.get<Int>(KEY_TABLES)?.let(::decodeOptionalInt)
                } else {
                    restaurant.liveAvailability?.availableTables
                },
                estimatedWaitMinutes = if (savedStateHandle.get<Boolean>(KEY_INITIALIZED) == true) {
                    savedStateHandle.get<Int>(KEY_WAIT)?.let(::decodeOptionalInt)
                } else {
                    restaurant.liveAvailability?.estimatedWaitMinutes
                },
                note = savedStateHandle.get<String>(KEY_NOTE)
                    ?: restaurant.liveAvailability?.note.orEmpty(),
            )
        } ?: RestaurantManagerUiState(),
    )

    fun publishStatus(status: AvailabilityStatus) {
        if (status !in setOf(
                AvailabilityStatus.AVAILABLE,
                AvailabilityStatus.LIMITED,
                AvailabilityStatus.FULL,
            )
        ) return

        viewModelScope.launch {
            isSaving.value = true
            message.value = null
            if (status == AvailabilityStatus.FULL) {
                updateTables(null)
            }
            val success = repository.publishAvailability(
                restaurantId = restaurantId,
                status = status,
                availableTables = availableTables.value,
                estimatedWaitMinutes = estimatedWaitMinutes.value,
                note = note.value.trim().takeIf { it.isNotEmpty() },
            )
            isSaving.value = false
            message.value = if (success) {
                "✓ Pubblicato adesso: i clienti lo vedono per 30 minuti."
            } else {
                "Non è stato possibile pubblicare. Controlla la connessione e riprova."
            }
        }
    }

    fun refreshCurrentStatus() {
        val current = repository.findById(restaurantId)?.liveAvailability?.status ?: return
        publishStatus(current)
    }

    fun decrementTables() {
        updateTables(
            when (val current = availableTables.value) {
                null -> 0
                0 -> null
                else -> current - 1
            },
        )
    }

    fun incrementTables() {
        updateTables(((availableTables.value ?: 0) + 1).coerceAtMost(AvailabilityRules.MAX_AVAILABLE_TABLES))
    }

    fun setWait(minutes: Int?) {
        updateWait(minutes)
    }

    fun setNote(value: String) {
        updateNote(value.take(AvailabilityRules.MAX_NOTE_LENGTH))
    }

    fun setPhonePublic(isPublic: Boolean) {
        viewModelScope.launch {
            val success = repository.setPhonePublic(restaurantId, isPublic)
            message.value = if (success) {
                if (isPublic) "Telefono reso pubblico." else "Telefono nascosto agli utenti."
            } else {
                "Impossibile modificare la visibilità del telefono."
            }
        }
    }

    fun clearMessage() {
        message.value = null
    }

    private fun updateTables(value: Int?) {
        availableTables.value = value
        savedStateHandle[KEY_TABLES] = encodeOptionalInt(value)
    }

    private fun updateWait(value: Int?) {
        estimatedWaitMinutes.value = value
        savedStateHandle[KEY_WAIT] = encodeOptionalInt(value)
    }

    private fun updateNote(value: String) {
        note.value = value
        savedStateHandle[KEY_NOTE] = value
    }

    private fun encodeOptionalInt(value: Int?): Int = value ?: NULL_INT_SENTINEL

    private fun decodeOptionalInt(value: Int): Int? =
        value.takeUnless { it == NULL_INT_SENTINEL }

    private fun clockTicker() = flow {
        while (true) {
            emit(Instant.now())
            delay(15_000)
        }
    }

    private data class DraftState(
        val tables: Int?,
        val wait: Int?,
        val note: String,
        val saving: Boolean,
        val message: String?,
    )

    companion object {
        private const val KEY_TABLES = "manager.tables"
        private const val KEY_WAIT = "manager.wait"
        private const val KEY_NOTE = "manager.note"
        private const val KEY_INITIALIZED = "manager.initialized"
        private const val NULL_INT_SENTINEL = -1
    }
}

fun RestaurantManagerViewModelFactory(
    restaurantId: String,
    repository: RestaurantRepository,
): ViewModelProvider.Factory = viewModelFactory {
    initializer {
        RestaurantManagerViewModel(
            restaurantId = restaurantId,
            repository = repository,
            savedStateHandle = createSavedStateHandle(),
        )
    }
}
