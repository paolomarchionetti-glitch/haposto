package com.haposto.ui.screens.loyalty

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import android.view.WindowManager
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.FilterQuality
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.core.content.edit
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.haposto.data.auth.AuthRepository
import com.haposto.data.auth.AuthState
import com.haposto.data.loyalty.LoyaltyReportKind
import com.haposto.data.loyalty.LoyaltyReward
import com.haposto.data.loyalty.LoyaltyTexts
import com.haposto.platform.qr.QrCodes
import com.haposto.ui.components.BigActionButton
import com.haposto.ui.components.MessageBanner
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import kotlinx.coroutines.delay

/** T59: la schermata della privacy si accetta una volta sola, su questo telefono. */
object LoyaltyPrefs {
    private const val PREFS = "haposto_prefs"
    private const val KEY_PRIVACY = "loyalty_privacy_v1"

    fun privacyAccepted(context: Context): Boolean =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getBoolean(KEY_PRIVACY, false)

    fun acceptPrivacy(context: Context) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit { putBoolean(KEY_PRIVACY, true) }
    }
}

/** T59: cosa vede il locale, cosa conserva HAPOSTO e per quanto. Poi «Accetto e continuo». */
@Composable
fun LoyaltyPrivacyNotice(onAccept: () -> Unit, onCancel: () -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text("Prima di iniziare", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
        Text(
            "La tessera è gratis. Ecco cosa succede ai tuoi dati:",
            style = MaterialTheme.typography.bodyLarge,
        )
        LoyaltyTexts.PRIVACY_NOTICE.forEach { line ->
            Text("• $line", style = MaterialTheme.typography.bodyMedium)
        }
        BigActionButton(text = "Accetto e continuo", onClick = onAccept)
        TextButton(onClick = onCancel, modifier = Modifier.fillMaxWidth()) { Text("Non ora") }
    }
}

/** Mostra [content] solo dopo aver accettato la privacy della tessera (una volta per telefono). */
@Composable
internal fun LoyaltyPrivacyGate(onCancel: () -> Unit, content: @Composable () -> Unit) {
    val context = LocalContext.current
    var accepted by rememberSaveable { mutableStateOf(LoyaltyPrefs.privacyAccepted(context)) }
    if (accepted) {
        content()
    } else {
        LoyaltyPrivacyNotice(
            onAccept = {
                LoyaltyPrefs.acceptPrivacy(context)
                accepted = true
            },
            onCancel = onCancel,
        )
    }
}

/** T61: l'accesso con Google si chiede solo qui (QR, gruppo, tavolo), non prima. */
@Composable
internal fun LoyaltySignInGate(auth: AuthRepository, onOpenAccount: () -> Unit, content: @Composable () -> Unit) {
    when (auth.state.collectAsStateWithLifecycle().value) {
        is AuthState.SignedIn -> content()
        AuthState.Loading -> MessageBanner("Controllo l'accesso…")
        AuthState.SignedOut -> Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text("Accedi con Google per raccogliere i timbri", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
            Text(
                "La tessera è gratis. Si accede una volta sola, dalla scheda Account.",
                style = MaterialTheme.typography.bodyMedium,
            )
            BigActionButton(text = "Accedi con Google", onClick = onOpenAccount)
        }
    }
}

internal tailrec fun Context.findLoyaltyActivity(): Activity? = when (this) {
    is Activity -> this
    is ContextWrapper -> baseContext.findLoyaltyActivity()
    else -> null
}

/**
 * Schermata del QR (T35): blocca screenshot e registrazioni (FLAG_SECURE) e porta la luminosità al
 * massimo, così lo scanner del locale legge subito. Tutto torna com'era quando si esce.
 */
@Composable
internal fun SecureBrightScreen() {
    val activity = LocalContext.current.findLoyaltyActivity() ?: return
    DisposableEffect(activity) {
        val window = activity.window
        val previousBrightness = window.attributes.screenBrightness
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        window.attributes = window.attributes.apply {
            screenBrightness = WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_FULL
        }
        onDispose {
            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
            window.attributes = window.attributes.apply { screenBrightness = previousBrightness }
        }
    }
}

private val CLOCK: DateTimeFormatter = DateTimeFormatter.ofPattern("HH:mm:ss").withZone(ZoneId.systemDefault())

/**
 * QR con cornice animata e orologio che scorre: lo staff riconosce subito una foto statica.
 * [secondsLeft] e [seconds] servono alla barra del conto alla rovescia.
 */
@Composable
internal fun LiveQr(content: String, code: String, secondsLeft: Long, seconds: Int, label: String) {
    val transition = rememberInfiniteTransition(label = "qr-frame")
    val phase by transition.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(tween(1_200, easing = LinearEasing), RepeatMode.Reverse),
        label = "qr-frame-phase",
    )
    val frame = lerp(MaterialTheme.colorScheme.primary, MaterialTheme.colorScheme.tertiary, phase)
    // Un pixel per modulo (dimensione 0 = la minima): si crea in pochi millisecondi (§6.1: QR in
    // meno di mezzo secondo) e si ingrandisce senza sfocare (FilterQuality.None).
    val bitmap = remember(content) { QrCodes.bitmap(content, 0).asImageBitmap() }
    var now by remember { mutableStateOf(Instant.now()) }
    LaunchedEffect(Unit) {
        while (true) {
            now = Instant.now()
            delay(250)
        }
    }
    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Surface(
            shape = MaterialTheme.shapes.large,
            color = Color.White,
            border = BorderStroke((6 + 4 * phase).dp, frame),
            modifier = Modifier
                .widthIn(max = 360.dp)
                .fillMaxWidth()
                .aspectRatio(1f),
        ) {
            Image(
                bitmap = bitmap,
                contentDescription = label,
                modifier = Modifier
                    .fillMaxSize()
                    .padding(16.dp),
                contentScale = ContentScale.Fit,
                filterQuality = FilterQuality.None,
            )
        }
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Box(
                Modifier
                    .size(10.dp)
                    .background(frame, CircleShape),
            )
            Text(CLOCK.format(now), style = MaterialTheme.typography.titleMedium, fontFamily = FontFamily.Monospace)
        }
        Text(
            LoyaltyTexts.codeSpaced(code),
            style = MaterialTheme.typography.headlineMedium,
            fontFamily = FontFamily.Monospace,
            fontWeight = FontWeight.Bold,
        )
        Text(
            "Codice di riserva, se il QR non si legge",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        LinearProgressIndicator(
            progress = { if (seconds <= 0) 0f else (secondsLeft.toFloat() / seconds).coerceIn(0f, 1f) },
            modifier = Modifier.fillMaxWidth(),
        )
        Text(
            if (secondsLeft > 0) "Si rinnova da solo tra $secondsLeft s" else "Rinnovo il QR…",
            style = MaterialTheme.typography.bodyMedium,
            textAlign = TextAlign.Center,
        )
    }
}

/** «●●●●○○○○○○ 4 su 10». */
@Composable
internal fun StampProgress(stamps: Int, required: Int) {
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Text(
            "${LoyaltyTexts.progress(stamps, required)} timbri",
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Black,
        )
        Text(
            "●".repeat(stamps.coerceIn(0, required)) + "○".repeat((required - stamps).coerceAtLeast(0)),
            style = MaterialTheme.typography.titleLarge,
            color = MaterialTheme.colorScheme.primary,
            modifier = Modifier.semantics { contentDescription = "${LoyaltyTexts.progress(stamps, required)} timbri" },
        )
    }
}

/** Premi da usare, come li legge il cliente. */
@Composable
internal fun CustomerRewards(rewards: List<LoyaltyReward>) {
    val now = remember { Instant.now() }
    rewards.forEach { reward ->
        Surface(
            modifier = Modifier.fillMaxWidth(),
            color = MaterialTheme.colorScheme.primaryContainer,
            contentColor = MaterialTheme.colorScheme.onPrimaryContainer,
            shape = MaterialTheme.shapes.medium,
        ) {
            Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                LoyaltyTexts.customerReward(reward, now) { LOYALTY_DATE.format(it) }.forEachIndexed { index, line ->
                    Text(
                        line,
                        style = if (index == 0) MaterialTheme.typography.titleMedium else MaterialTheme.typography.bodyMedium,
                        fontWeight = if (index == 0) FontWeight.Bold else FontWeight.Normal,
                    )
                }
            }
        }
    }
}

/** T48: due tasti senza testo, con conferma. Segnalando non si ottiene niente. */
@Composable
internal fun ReportButtons(enabled: Boolean, onReport: (LoyaltyReportKind) -> Unit) {
    var open by rememberSaveable { mutableStateOf(false) }
    var asking by rememberSaveable { mutableStateOf<LoyaltyReportKind?>(null) }
    TextButton(onClick = { open = !open }, enabled = enabled) {
        Text(if (open) "Segnala un problema ▴" else "Segnala un problema ▾")
    }
    if (open) {
        LoyaltyReportKind.entries.forEach { kind ->
            OutlinedButton(onClick = { asking = kind }, enabled = enabled, modifier = Modifier.fillMaxWidth()) {
                Text(LoyaltyTexts.reportKind(kind))
            }
        }
        Text(
            "Il locale non sa chi ha segnalato. Una segnalazione ogni 90 giorni, solo dopo un timbro negli ultimi 60.",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
    asking?.let { kind ->
        AlertDialog(
            onDismissRequest = { asking = null },
            title = { Text("Inviare la segnalazione?") },
            text = { Text("«${LoyaltyTexts.reportKind(kind)}». Il locale vede solo quante segnalazioni ha, mai chi le ha fatte.") },
            confirmButton = {
                TextButton(onClick = {
                    asking = null
                    open = false
                    onReport(kind)
                }) { Text("Invia") }
            },
            dismissButton = { TextButton(onClick = { asking = null }) { Text("Annulla") } },
        )
    }
}

/** T26: lasciare la tessera cancella timbri e premi di quel locale. */
@Composable
internal fun LeaveCardButton(enabled: Boolean, onLeave: () -> Unit) {
    var asking by rememberSaveable { mutableStateOf(false) }
    TextButton(onClick = { asking = true }, enabled = enabled) {
        Text("Lascia questa tessera", color = MaterialTheme.colorScheme.error)
    }
    if (asking) {
        AlertDialog(
            onDismissRequest = { asking = false },
            title = { Text("Lasciare la tessera?") },
            text = { Text("Timbri e premi di questo locale si cancellano e non si recuperano.") },
            confirmButton = {
                TextButton(onClick = {
                    asking = false
                    onLeave()
                }) { Text("Lascia la tessera", color = MaterialTheme.colorScheme.error) }
            },
            dismissButton = { TextButton(onClick = { asking = false }) { Text("Annulla") } },
        )
    }
}
