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
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.util.UUID

class ReservationsViewModel(
    private val store: ReservationStore,
) : ViewModel() {

    private val _items = MutableStateFlow<List<Reservation>>(emptyList())
    val items: StateFlow<List<Reservation>> = _items.asStateFlow()

    init {
        viewModelScope.launch {
            val loaded = withContext(Dispatchers.IO) { store.load() }
            _items.value = loaded.sortedBy { it.sortKey }
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
            partySize = partySize.coerceAtLeast(1),
            table = table?.trim()?.ifBlank { null },
        )
        val next = if (editingId != null) {
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
        val sorted = list.sortedBy { it.sortKey }
        _items.value = sorted
        viewModelScope.launch {
            withContext(Dispatchers.IO) { store.save(sorted) }
        }
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
