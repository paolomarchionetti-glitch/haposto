package com.haposto.data.auth

import java.security.MessageDigest
import java.security.SecureRandom

/**
 * Nonce per l'accesso con Google: a Google si passa l'impronta SHA-256, a Supabase il valore in
 * chiaro. Così un token rubato non si può riusare su un'altra richiesta di accesso.
 */
object Nonce {
    private val random = SecureRandom()

    fun generate(): Pair<String, String> {
        val bytes = ByteArray(32).also(random::nextBytes)
        val raw = bytes.joinToString("") { "%02x".format(it) }
        return raw to sha256Hex(raw)
    }

    fun sha256Hex(value: String): String =
        MessageDigest.getInstance("SHA-256")
            .digest(value.toByteArray(Charsets.UTF_8))
            .joinToString("") { "%02x".format(it) }
}
