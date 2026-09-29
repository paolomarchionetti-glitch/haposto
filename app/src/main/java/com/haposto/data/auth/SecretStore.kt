package com.haposto.data.auth

/**
 * Piccolo archivio di testi riservati. Su Android è cifrato con una chiave del Keystore che non
 * lascia mai il telefono (vedi platform/security/KeystoreSecretStore).
 */
interface SecretStore {
    fun read(key: String): String?
    fun write(key: String, value: String)
    fun delete(key: String)
}
