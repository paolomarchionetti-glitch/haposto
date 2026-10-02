package com.haposto.ui.components

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.speech.RecognizerIntent
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState

/**
 * Dettatura con il riconoscimento vocale di sistema (Google), in italiano. Non serve il permesso
 * del microfono: lo chiede l'app di riconoscimento. Restituisce la funzione da chiamare al tocco
 * del tasto 🎙; [onText] riceve la frase capita, [onUnavailable] scatta se sul telefono manca.
 */
@Composable
fun rememberSpeechInput(
    prompt: String,
    onText: (String) -> Unit,
    onUnavailable: () -> Unit,
): () -> Unit {
    val currentOnUnavailable by rememberUpdatedState(onUnavailable)
    val launcher = rememberLauncherForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
        if (result.resultCode == Activity.RESULT_OK) {
            result.data
                ?.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)
                ?.firstOrNull()
                ?.trim()
                ?.takeIf { it.isNotEmpty() }
                ?.let(onText)
        }
    }
    return remember(launcher, prompt) {
        {
            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                putExtra(RecognizerIntent.EXTRA_LANGUAGE, "it-IT")
                putExtra(RecognizerIntent.EXTRA_PROMPT, prompt)
            }
            try {
                launcher.launch(intent)
            } catch (e: ActivityNotFoundException) {
                currentOnUnavailable()
            }
        }
    }
}
