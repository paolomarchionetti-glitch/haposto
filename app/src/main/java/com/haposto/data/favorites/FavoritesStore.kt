package com.haposto.data.favorites

import android.content.Context
import androidx.core.content.edit
import com.haposto.data.Outcome
import com.haposto.data.consumer.ConsumerRepository
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.updateAndGet
import kotlinx.coroutines.launch

/**
 * Preferiti: sempre salvati su questo telefono (gratis, senza account). Con un account vengono
 * anche sincronizzati sul server (Gratis fino a 5, Plus illimitati) e ritrovati su altri telefoni.
 */
class FavoritesStore(
    context: Context,
    private val remote: ConsumerRepository? = null,
    private val scope: CoroutineScope? = null,
) {

    private val prefs = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    private val _ids = MutableStateFlow(prefs.getStringSet(KEY_IDS, emptySet()).orEmpty().toSet())
    private val _lastSyncMessage = MutableStateFlow<String?>(null)

    val ids: StateFlow<Set<String>> = _ids.asStateFlow()

    /** Ultimo avviso della sincronizzazione (es. limite dei 5 preferiti del piano Gratis). */
    val lastSyncMessage: StateFlow<String?> = _lastSyncMessage.asStateFlow()

    fun toggle(restaurantId: String) {
        val adding = restaurantId !in _ids.value
        val next = _ids.updateAndGet { current ->
            if (restaurantId in current) current - restaurantId else current + restaurantId
        }
        save(next)
        val repository = remote ?: return
        scope?.launch {
            val result = if (adding) repository.addFavorite(restaurantId) else repository.removeFavorite(restaurantId)
            _lastSyncMessage.value = (result as? Outcome.Failure)
                ?.takeIf { it.code != "AUTH_REQUIRED" }
                ?.message
        }
    }

    /** Dopo l'accesso: unisce preferiti del telefono e dell'account. */
    suspend fun syncWithAccount() {
        val repository = remote ?: return
        val remoteIds = repository.remoteFavorites().valueOrNull ?: return
        val localOnly = _ids.value - remoteIds
        var limitReached = false
        localOnly.forEach { id ->
            val result = repository.addFavorite(id)
            if (result is Outcome.Failure && result.code == "FAVORITES_LIMIT_REACHED") limitReached = true
        }
        val merged = _ids.updateAndGet { it + remoteIds }
        save(merged)
        _lastSyncMessage.value = if (limitReached) {
            "Alcuni preferiti restano solo su questo telefono: con Plus li sincronizzi tutti."
        } else {
            null
        }
    }

    fun clearMessage() {
        _lastSyncMessage.value = null
    }

    private fun save(ids: Set<String>) {
        prefs.edit { putStringSet(KEY_IDS, ids) }
    }

    private companion object {
        const val PREFS = "haposto_favorites"
        const val KEY_IDS = "restaurant_ids"
    }
}
