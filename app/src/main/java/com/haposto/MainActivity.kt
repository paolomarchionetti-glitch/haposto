package com.haposto

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.getValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.haposto.ui.HaPostoApp
import com.haposto.ui.navigation.DeepLink
import kotlinx.coroutines.flow.MutableStateFlow

class MainActivity : ComponentActivity() {

    /** Apertura richiesta da una notifica, consumata dalla navigazione una sola volta. */
    private val pendingDeepLink = MutableStateFlow<DeepLink?>(null)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        AppDependencies.init(this)
        enableEdgeToEdge()
        // Dopo una rotazione l'intent è lo stesso: non va riaperto.
        if (savedInstanceState == null) pendingDeepLink.value = DeepLink.from(intent)
        setContent {
            val deepLink by pendingDeepLink.collectAsStateWithLifecycle()
            HaPostoApp(
                deepLink = deepLink,
                onDeepLinkHandled = { pendingDeepLink.value = null },
            )
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        DeepLink.from(intent)?.let { pendingDeepLink.value = it }
    }
}
