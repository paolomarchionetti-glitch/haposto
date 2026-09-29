package com.haposto.data.remote.supabase

import com.haposto.data.auth.SecretStore
import io.github.jan.supabase.auth.SessionManager
import io.github.jan.supabase.auth.user.UserSession
import kotlinx.serialization.json.Json

/** Sessione di Supabase Auth salvata solo in forma cifrata (token di accesso e di rinnovo). */
class SecureSessionManager(private val store: SecretStore) : SessionManager {

    private val json = Json {
        ignoreUnknownKeys = true
        encodeDefaults = true
    }

    override suspend fun saveSession(session: UserSession) {
        store.write(KEY, json.encodeToString(UserSession.serializer(), session))
    }

    /** Nessuna sessione salvata (o illeggibile): Supabase usa loadSessionOrNull e resta scollegato. */
    override suspend fun loadSession(): UserSession {
        val stored = store.read(KEY) ?: error("Nessuna sessione salvata")
        return json.decodeFromString(UserSession.serializer(), stored)
    }

    override suspend fun deleteSession() {
        store.delete(KEY)
    }

    private companion object {
        const val KEY = "supabase_session"
    }
}
