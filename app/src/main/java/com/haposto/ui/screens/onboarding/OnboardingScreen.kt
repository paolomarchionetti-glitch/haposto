package com.haposto.ui.screens.onboarding

import android.content.Context
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp

private data class OnbPage(val title: String, val body: String)

private val PAGES = listOf(
    OnbPage(
        "Scopri dove c'è posto adesso",
        "Apri, guarda i pallini verdi e vai. Niente telefonate, niente prenotazioni.",
    ),
    OnbPage(
        "Dati freschi, di cui fidarti",
        "Gli stati sono dichiarati dai locali e scadono dopo 30 minuti. Non è una prenotazione: la disponibilità può cambiare.",
    ),
    OnbPage(
        "Vicino a te",
        "Attiva la posizione oppure scegli una zona di Pesaro e provincia.",
    ),
)

/** Persistenza minima del "già visto" tramite SharedPreferences. */
object OnboardingPrefs {
    private const val PREFS = "haposto_prefs"
    private const val KEY_SEEN = "onboarding_seen_v1"

    fun hasSeen(context: Context): Boolean =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getBoolean(KEY_SEEN, false)

    fun markSeen(context: Context) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putBoolean(KEY_SEEN, true).apply()
    }
}

@Composable
fun OnboardingScreen(onFinish: () -> Unit) {
    var index by rememberSaveable { mutableIntStateOf(0) }
    val page = PAGES[index]
    val isLast = index == PAGES.lastIndex

    Surface(color = MaterialTheme.colorScheme.background) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                // Edge-to-edge: keep "Salta" and the main button clear of status/navigation bars.
                .windowInsetsPadding(WindowInsets.safeDrawing)
                .padding(28.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
                TextButton(onClick = onFinish) { Text("Salta") }
            }

            Spacer(Modifier.height(24.dp))

            // Marchio: pin + dot verde stilizzati
            BrandMark()

            Spacer(Modifier.weight(1f))

            Text(
                text = page.title,
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center,
            )
            Spacer(Modifier.height(12.dp))
            Text(
                text = page.body,
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center,
            )

            Spacer(Modifier.weight(1f))

            // Indicatori pagina
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                PAGES.indices.forEach { i ->
                    val selected = i == index
                    Box(
                        Modifier
                            .size(if (selected) 10.dp else 8.dp)
                            .clip(CircleShape)
                            .background(
                                if (selected) MaterialTheme.colorScheme.primary
                                else MaterialTheme.colorScheme.outlineVariant,
                            ),
                    )
                }
            }

            Spacer(Modifier.height(20.dp))

            Button(
                onClick = { if (isLast) onFinish() else index++ },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(54.dp),
            ) {
                Text(
                    text = if (isLast) "Inizia" else "Avanti",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                )
            }
        }
    }
}

@Composable
private fun BrandMark() {
    Box(
        modifier = Modifier
            .size(96.dp)
            .clip(MaterialTheme.shapes.extraLarge)
            .background(MaterialTheme.colorScheme.primary),
        contentAlignment = Alignment.Center,
    ) {
        Box(
            Modifier
                .size(34.dp)
                .clip(CircleShape)
                .background(com.haposto.ui.theme.BrandGreen),
        )
    }
}
