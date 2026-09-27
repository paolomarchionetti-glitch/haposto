package com.haposto.ui.screens.reservations

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.haposto.data.reservations.Reservation
import com.haposto.data.reservations.ReservationStore
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import java.util.UUID

class ReservationsViewModel(
    private val store: ReservationStore,
) : ViewModel() {

    private val _items = MutableStateFlow<List<Reservation>>(emptyList())
    val items: StateFlow<List<Reservation>> = _items.asStateFlow()

    /** Serializes file writes so a slower, older save can never overwrite a newer list. */
    private val saveMutex = Mutex()

    init {
        viewModelScope.launch {
            val loaded = withContext(Dispatchers.IO) { store.load() }
            // Keep anything added/edited while the file was still loading.
            _items.update { current ->
                val editedIds = current.mapTo(HashSet()) { it.id }
                (loaded.filterNot { it.id in editedIds } + current).sortedBy { it.sortKey }
            }
        }
    }

    fun addOrUpdate(
        editingId: String?,
        name: String,
        time: String,
        partySize: Int,
        table: String?,
    ) {
        val cleanName = name.trim()
        if (cleanName.isEmpty()) return
        val entry = Reservation(
            id = editingId ?: UUID.randomUUID().toString(),
            name = cleanName,
            time = time.trim(),
            partySize = partySize.coerceIn(1, MAX_PARTY_SIZE),
            table = table?.trim()?.ifBlank { null },
        )
        val next = if (editingId != null && _items.value.any { it.id == editingId }) {
            _items.value.map { if (it.id == editingId) entry else it }
        } else {
            _items.value + entry
        }
        persist(next)
    }

    fun remove(id: String) {
        persist(_items.value.filterNot { it.id == id })
    }

    private fun persist(list: List<Reservation>) {
        _items.value = list.sortedBy { it.sortKey }
        viewModelScope.launch {
            saveMutex.withLock {
                // Always write the latest list, not the snapshot captured when this save was queued.
                val latest = _items.value
                withContext(Dispatchers.IO) { store.save(latest) }
            }
        }
    }

    companion object {
        const val MAX_PARTY_SIZE = 99
    }
}

class ReservationsViewModelFactory(
    private val context: Context,
    private val restaurantId: String,
) : ViewModelProvider.Factory {
    @Suppress("UNCHECKED_CAST")
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        return ReservationsViewModel(ReservationStore(context, restaurantId)) as T
    }
}
