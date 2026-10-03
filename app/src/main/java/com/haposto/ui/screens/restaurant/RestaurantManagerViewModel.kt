package com.haposto.ui.screens.restaurant

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.createSavedStateHandle
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import com.haposto.data.Outcome
import com.haposto.data.repository.RestaurantRepository
import com.haposto.data.restaurant.NoRecentNotes
import com.haposto.data.restaurant.RecentNotes
import com.haposto.data.restaurant.RecentNotesStore
import com.haposto.domain.model.AvailabilityRules
import com.haposto.domain.model.AvailabilityStatus
import com.haposto.domain.model.EffectiveAvailability
import com.haposto.domain.usecase.AvailabilityResolver
import com.haposto.domain.voice.DetailsDictation
import java.time.Instant
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

class RestaurantManagerViewModel(
    private val restaurantId: String,
    private val repository: RestaurantRepository,
    private val savedStateHandle: SavedStateHandle,
    /** Chiamato dopo ogni pubblicazione riuscita (es. per programmare il promemoria). */
    private val onPublished: (AvailabilityStatus) -> Unit = {},
    /** Ultime note usate su questo telefono (riusabili con un tocco). */
    private val recentNotesStore: RecentNotesStore = NoRecentNotes,
) : ViewModel() {

    private val mfaMissing = MutableStateFlow(false)

    private val availableTables = MutableStateFlow(
        savedStateHandle.get<Int>(KEY_TABLES)?.let(::decodeOptionalInt),
    )
    private val estimatedWaitMinutes = MutableStateFlow(
        savedStateHandle.get<Int>(KEY_WAIT)?.let(::decodeOptionalInt),
    )
    private val note = MutableStateFlow(savedStateHandle[KEY_NOTE] ?: "")
    private val offer = MutableStateFlow(savedStateHandle[KEY_OFFER] ?: "")
    private val isSaving = MutableStateFlow(false)
    private val message = MutableStateFlow<String?>(null)
    private val recentNotes = MutableStateFlow(recentNotesStore.load())
    private var draftInitialized = savedStateHandle[KEY_INITIALIZED] ?: false

    private val details = combine(availableTables, estimatedWaitMinutes, note, offer) { tables, wait, noteValue, offerValue ->
        DraftState(tables, wait, noteValue, offerValue, saving = false, message = null)
    }

    private val draft = combine(details, isSaving, message) { detailsValue, saving, messageValue ->
        detailsValue.copy(saving = saving, message = messageValue)
    }

    val uiState = combine(
        // On a backend error keep the last known record so the dashboard stays usable instead of crashing.
        repository.observeRestaurants()
            .catch { emit(listOfNotNull(repository.findById(restaurantId))) },
        draft,
        clockTicker(),
        recentNotes,
    ) { restaurants, draft, now, recent ->
        val restaurant = restaurants.firstOrNull { it.id == restaurantId }
        if (!draftInitialized && restaurant != null) {
            restaurant.liveAvailability?.let { live ->
                updateTables(live.availableTables)
                updateWait(live.estimatedWaitMinutes)
                updateNote(live.note.orEmpty())
                updateOffer(live.offer.orEmpty())
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
            offer = draft.offer,
            isSaving = draft.saving,
            message = draft.message,
            recentNotes = recent,
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
                recentNotes = recentNotes.value,
                offer = savedStateHandle.get<String>(KEY_OFFER)
                    ?: restaurant.liveAvailability?.offer.orEmpty(),
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
            val publishedNote = note.value.trim().takeIf { it.isNotEmpty() }
            val result = repository.publishAvailabilityResult(
                restaurantId = restaurantId,
                status = status,
                availableTables = availableTables.value,
                estimatedWaitMinutes = estimatedWaitMinutes.value,
                note = publishedNote,
                // Con "Completo" l'offerta non si pubblica (resta nel campo per la prossima volta).
                offer = offer.value.trim().takeIf { it.isNotEmpty() && status != AvailabilityStatus.FULL },
            )
            if (result is Outcome.Success && publishedNote != null) {
                recentNotes.value = RecentNotes.add(recentNotes.value, publishedNote)
                recentNotesStore.save(recentNotes.value)
            }
            isSaving.value = false
            mfaMissing.value = (result as? Outcome.Failure)?.code == "MFA_REQUIRED"
            message.value = when (result) {
                is Outcome.Success -> {
                    onPublished(status)
                    "✓ Pubblicato adesso: i clienti lo vedono per 30 minuti."
                }
                is Outcome.Failure -> if (result.code == "UNKNOWN") {
                    "Non è stato possibile pubblicare. Controlla la connessione e riprova."
                } else {
                    result.message
                }
            }
        }
    }

    /** true quando il server ha rifiutato perché manca il codice della verifica in due passaggi. */
    val needsMfa: StateFlow<Boolean> = mfaMissing.asStateFlow()

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

    /** Offerta della serata (facoltativa): si pubblica con lo stato e scade con lo stato. */
    fun setOffer(value: String) {
        updateOffer(value.take(AvailabilityRules.MAX_OFFER_LENGTH))
    }

    /**
     * Frase dettata ("tre tavoli, dieci minuti, solo tavoli fuori"): compila solo i dettagli che
     * nomina; gli altri restano come sono. Non pubblica: il ristoratore controlla e sceglie lo stato.
     */
    fun applyDictation(text: String) {
        val draft = DetailsDictation.parse(text)
        if (draft.isEmpty) {
            message.value = "Non ho capito i dettagli: riprova o scrivili a mano."
            return
        }
        message.value = null
        // "togli i tavoli", "attesa non indicata", "nessuna nota", "togli l'offerta".
        if (draft.tablesCleared) updateTables(null)
        if (draft.waitCleared) updateWait(null)
        if (draft.noteCleared) setNote("")
        if (draft.offerCleared) setOffer("")
        draft.tables?.let { updateTables(it) }
        draft.waitMinutes?.let { updateWait(it) }
        draft.note?.let { setNote(it) }
        draft.offer?.let { setOffer(it) }
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

    private fun updateOffer(value: String) {
        offer.value = value
        savedStateHandle[KEY_OFFER] = value
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
        val offer: String,
        val saving: Boolean,
        val message: String?,
    )

    companion object {
        private const val KEY_TABLES = "manager.tables"
        private const val KEY_WAIT = "manager.wait"
        private const val KEY_NOTE = "manager.note"
        private const val KEY_OFFER = "manager.offer"
        private const val KEY_INITIALIZED = "manager.initialized"
        private const val NULL_INT_SENTINEL = -1
    }
}

fun RestaurantManagerViewModelFactory(
    restaurantId: String,
    repository: RestaurantRepository,
    onPublished: (AvailabilityStatus) -> Unit = {},
    recentNotesStore: RecentNotesStore = NoRecentNotes,
): ViewModelProvider.Factory = viewModelFactory {
    initializer {
        RestaurantManagerViewModel(
            restaurantId = restaurantId,
            repository = repository,
            savedStateHandle = createSavedStateHandle(),
            onPublished = onPublished,
            recentNotesStore = recentNotesStore,
        )
    }
}
