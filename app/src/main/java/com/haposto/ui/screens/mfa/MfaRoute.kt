package com.haposto.ui.screens.mfa

import android.content.ActivityNotFoundException
import android.content.Intent
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.core.net.toUri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import com.haposto.data.Outcome
import com.haposto.data.auth.AuthRepository
import com.haposto.data.auth.AuthState
import com.haposto.data.auth.TotpEnrollment
import com.haposto.platform.qr.QrCodes
import com.haposto.ui.components.BannerKind
import com.haposto.ui.components.BigActionButton
import com.haposto.ui.components.InfoDisclosure
import com.haposto.ui.components.MessageBanner
import com.haposto.ui.components.SectionCard
import com.haposto.ui.components.SimpleScreen
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

data class MfaUiState(
    val auth: AuthState = AuthState.Loading,
    val enrollment: TotpEnrollment? = null,
    val busy: Boolean = false,
    val error: String? = null,
)

class MfaViewModel(private val auth: AuthRepository) : ViewModel() {
    private val enrollment = MutableStateFlow<TotpEnrollment?>(null)
    private val busy = MutableStateFlow(false)
    private val error = MutableStateFlow<String?>(null)

    val uiState = combine(auth.state, enrollment, busy, error) { state, pending, isBusy, message ->
        MfaUiState(state, pending, isBusy, message)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), MfaUiState())

    fun startEnrollment() = launchBusy {
        when (val result = auth.startTotpEnrollment()) {
            is Outcome.Success -> enrollment.value = result.value
            is Outcome.Failure -> error.value = result.message
        }
    }

    fun verify(code: String) = launchBusy {
        val signedIn = auth.state.value as? AuthState.SignedIn
        val factorId = enrollment.value?.factorId ?: signedIn?.mfa?.totpFactorId
        if (factorId == null) {
            error.value = "Prima configura l'app di autenticazione."
            return@launchBusy
        }
        when (val result = auth.verifyTotp(factorId, code)) {
            is Outcome.Success -> enrollment.value = null
            is Outcome.Failure -> error.value = "Codice non valido o scaduto: controlla l'ora del telefono e riprova."
                .takeIf { result.code == "UNKNOWN" } ?: result.message
        }
    }

    private fun launchBusy(block: suspend () -> Unit) {
        viewModelScope.launch {
            busy.value = true
            error.value = null
            block()
            busy.value = false
        }
    }
}

/**
 * Verifica in due passaggi (TOTP): obbligatoria per chi gestisce un locale e per il pannello admin.
 * Primo uso: si inquadra il QR con Google Authenticator (o simili) e si inserisce il codice.
 * Accessi successivi: basta il codice di 6 cifre.
 */
@Composable
fun MfaRoute(auth: AuthRepository, onDone: () -> Unit, onBack: () -> Unit) {
    val viewModel: MfaViewModel = viewModel(factory = viewModelFactory { initializer { MfaViewModel(auth) } })
    val state = viewModel.uiState.collectAsStateWithLifecycle().value
    val context = LocalContext.current
    var code by rememberSaveable { mutableStateOf("") }

    val signedIn = state.auth as? AuthState.SignedIn
    LaunchedEffect(signedIn?.mfa?.verified) {
        if (signedIn?.mfa?.verified == true) onDone()
    }

    SimpleScreen(title = "Verifica in due passaggi", onBack = onBack) {
        when {
            signedIn == null -> MessageBanner("Prima accedi con Google.", BannerKind.INFO)
            signedIn.mfa.verified -> MessageBanner("✓ Verifica in due passaggi attiva.", BannerKind.SUCCESS)
            state.enrollment != null -> {
                val enrollment = state.enrollment
                val qr = remember(enrollment.otpauthUri) { QrCodes.bitmap(enrollment.otpauthUri, 600).asImageBitmap() }
                SectionCard(
                    title = "1 · Collega l'app di autenticazione",
                    subtitle = "Apri Google Authenticator (o Microsoft Authenticator), tocca \"+\" e inquadra questo codice.",
                ) {
                    Image(
                        bitmap = qr,
                        contentDescription = "Codice QR per l'app di autenticazione",
                        modifier = Modifier
                            .size(220.dp)
                            .align(Alignment.CenterHorizontally),
                    )
                    OutlinedButton(
                        onClick = {
                            try {
                                context.startActivity(Intent(Intent.ACTION_VIEW, enrollment.otpauthUri.toUri()))
                            } catch (_: ActivityNotFoundException) {
                                context.startActivity(
                                    Intent(
                                        Intent.ACTION_VIEW,
                                        "https://play.google.com/store/apps/details?id=com.google.android.apps.authenticator2".toUri(),
                                    ),
                                )
                            }
                        },
                        modifier = Modifier.fillMaxWidth(),
                    ) { Text("È su questo telefono? Apri l'app") }
                    InfoDisclosure(
                        label = "Non riesci a inquadrare?",
                        text = "Nell'app scegli \"Inserisci chiave\" e scrivi: ${enrollment.secret.chunked(4).joinToString(" ")}",
                    )
                }
                CodeSection(code, { code = it.filter(Char::isDigit).take(6) }, state.busy) { viewModel.verify(code) }
            }
            signedIn.mfa.enrolled -> {
                MessageBanner("Per sicurezza inserisci il codice di 6 cifre dell'app di autenticazione.")
                CodeSection(code, { code = it.filter(Char::isDigit).take(6) }, state.busy) { viewModel.verify(code) }
                InfoDisclosure(
                    label = "Hai cambiato o perso il telefono?",
                    text = "Scrivi a info@haposto.app dall'email del tuo account: dopo una verifica ti togliamo la vecchia configurazione e potrai rifarla.",
                )
            }
            else -> {
                SectionCard(
                    title = "Proteggi il tuo account",
                    subtitle = "Oltre a Google, ti chiediamo un codice che cambia ogni 30 secondi e si trova solo sul tuo telefono. " +
                        "Così nessuno può pubblicare al posto tuo anche se conosce la tua password.",
                ) {
                    Text("Ti serve un'app gratuita come Google Authenticator.", style = MaterialTheme.typography.bodyMedium)
                    BigActionButton(
                        text = if (state.busy) "Preparo…" else "Configura adesso (2 minuti)",
                        enabled = !state.busy,
                        onClick = viewModel::startEnrollment,
                    )
                }
            }
        }
        state.error?.let { MessageBanner(it, BannerKind.ERROR) }
    }
}

@Composable
private fun CodeSection(code: String, onCodeChange: (String) -> Unit, busy: Boolean, onVerify: () -> Unit) {
    SectionCard(title = "Inserisci il codice") {
        OutlinedTextField(
            value = code,
            onValueChange = onCodeChange,
            label = { Text("Codice di 6 cifre") },
            singleLine = true,
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword),
            textStyle = MaterialTheme.typography.headlineSmall.copy(fontFamily = FontFamily.Monospace, fontWeight = FontWeight.Bold),
            modifier = Modifier.fillMaxWidth(),
        )
        BigActionButton(
            text = if (busy) "Verifico…" else "Verifica",
            enabled = code.length == 6 && !busy,
            onClick = onVerify,
        )
    }
}
