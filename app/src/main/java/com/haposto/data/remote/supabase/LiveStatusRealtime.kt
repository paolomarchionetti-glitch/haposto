package com.haposto.data.remote.supabase

import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.realtime.PostgresAction
import io.github.jan.supabase.realtime.channel
import io.github.jan.supabase.realtime.postgresChangeFlow
import io.github.jan.supabase.realtime.realtime
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.FlowPreview
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.debounce
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.launch

/**
 * Aggiornamenti in tempo reale: quando un locale cambia stato, Supabase avvisa l'app e la lista si
 * ricarica in 1–2 secondi. Richiede la migration 0005 (publication supabase_realtime); se non c'è,
 * l'app continua con il controllo ogni minuto.
 */
class LiveStatusRealtime(
    private val client: SupabaseClient,
    private val onChange: () -> Unit,
) {
    private var job: Job? = null

    @OptIn(FlowPreview::class)
    fun start(scope: CoroutineScope) {
        if (job != null) return
        job = scope.launch {
            try {
                val channel = client.channel("live-status")
                channel.postgresChangeFlow<PostgresAction>(schema = "public") {
                    table = "restaurant_live_status"
                }
                    // Molti cambi insieme (es. il simulatore) = una sola ricarica.
                    .debounce(1_500)
                    .onEach { onChange() }
                    .launchIn(this)
                channel.subscribe()
            } catch (cancellation: CancellationException) {
                throw cancellation
            } catch (_: Exception) {
                // Realtime non attivo: resta il controllo periodico.
            }
        }
    }

    suspend fun stop() {
        job?.cancel()
        job = null
        runCatching { client.realtime.removeAllChannels() }
    }
}
