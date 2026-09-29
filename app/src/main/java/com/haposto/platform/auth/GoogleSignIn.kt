package com.haposto.platform.auth

import android.content.Context
import androidx.credentials.CredentialManager
import androidx.credentials.CustomCredential
import androidx.credentials.GetCredentialRequest
import androidx.credentials.exceptions.GetCredentialCancellationException
import androidx.credentials.exceptions.GetCredentialException
import androidx.credentials.exceptions.NoCredentialException
import com.google.android.libraries.identity.googleid.GetSignInWithGoogleOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import com.google.android.libraries.identity.googleid.GoogleIdTokenParsingException
import com.haposto.config.AppConfig
import com.haposto.data.ErrorMessages
import com.haposto.data.Outcome
import com.haposto.data.auth.GoogleIdToken
import com.haposto.data.auth.Nonce

/**
 * "Accedi con Google" con Credential Manager (finestra standard di Android). HAPOSTO riceve solo
 * un token firmato da Google che Supabase verifica: nessuna password passa dall'app.
 */
object GoogleSignIn {

    /** [activityContext] deve essere l'Activity: Android mostra la finestra sopra di lei. */
    suspend fun requestIdToken(activityContext: Context): Outcome<GoogleIdToken> {
        val serverClientId = AppConfig.googleWebClientId
        if (serverClientId.isBlank()) return ErrorMessages.failure("NOT_CONFIGURED")

        val (rawNonce, hashedNonce) = Nonce.generate()
        val option = GetSignInWithGoogleOption.Builder(serverClientId)
            .setNonce(hashedNonce)
            .build()
        val request = GetCredentialRequest.Builder()
            .addCredentialOption(option)
            .build()

        return try {
            val credential = CredentialManager.create(activityContext)
                .getCredential(activityContext, request)
                .credential
            if (credential is CustomCredential &&
                credential.type == GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL
            ) {
                val idToken = GoogleIdTokenCredential.createFrom(credential.data).idToken
                Outcome.Success(GoogleIdToken(idToken = idToken, rawNonce = rawNonce))
            } else {
                ErrorMessages.failure("GOOGLE_SIGN_IN_UNAVAILABLE")
            }
        } catch (_: GetCredentialCancellationException) {
            ErrorMessages.failure("GOOGLE_SIGN_IN_CANCELLED")
        } catch (_: NoCredentialException) {
            ErrorMessages.failure("GOOGLE_NO_ACCOUNT")
        } catch (_: GetCredentialException) {
            ErrorMessages.failure("GOOGLE_SIGN_IN_UNAVAILABLE")
        } catch (_: GoogleIdTokenParsingException) {
            ErrorMessages.failure("GOOGLE_SIGN_IN_UNAVAILABLE")
        }
    }
}
