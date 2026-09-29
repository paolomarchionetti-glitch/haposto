package com.haposto.ui.components

import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.waitForUpOrCancellation
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.pointer.pointerInput

/**
 * Gesto nascosto: tenere premuto per [holdMillis] (default 5 secondi) senza alzare il dito.
 * Nessun segno visibile: serve solo ad aprire il pannello amministratore, che poi chiede
 * comunque account admin, 2FA e seconda password.
 */
fun Modifier.secretLongPress(holdMillis: Long = 5_000, onTriggered: () -> Unit): Modifier =
    pointerInput(holdMillis) {
        awaitEachGesture {
            awaitFirstDown(requireUnconsumed = false)
            var heldLongEnough = true
            withTimeoutOrNull(holdMillis) {
                // Dito alzato (o gesto annullato, es. scorrimento) prima del tempo: niente.
                waitForUpOrCancellation()
                heldLongEnough = false
            }
            if (heldLongEnough) onTriggered()
        }
    }
