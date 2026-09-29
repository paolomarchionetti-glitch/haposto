package com.haposto.ui.components

import androidx.compose.runtime.Composable
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import com.haposto.data.Outcome
import com.haposto.data.auth.GoogleIdToken
import com.haposto.platform.auth.GoogleSignIn
import kotlinx.coroutines.launch

/** Tasto grande "Accedi con Google": apre la finestra di Android e restituisce il token. */
@Composable
fun GoogleSignInButton(
    onResult: (Outcome<GoogleIdToken>) -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    text: String = "G  Accedi con Google",
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    BigActionButton(
        text = text,
        enabled = enabled,
        modifier = modifier,
        onClick = { scope.launch { onResult(GoogleSignIn.requestIdToken(context)) } },
    )
}
