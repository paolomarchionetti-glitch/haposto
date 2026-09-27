package com.haposto.data.remote.supabase

data class SupabaseConfiguration(
    val url: String,
    val publishableKey: String,
) {
    val isAbsent: Boolean get() = url.isBlank() && publishableKey.isBlank()
    val isComplete: Boolean get() = url.isNotBlank() && publishableKey.isNotBlank()

    fun validationError(): String? {
        if (isAbsent) return null
        if (!isComplete) {
            return "Configurazione Supabase incompleta: servono sia SUPABASE_URL sia SUPABASE_PUBLISHABLE_KEY in local.properties."
        }
        if (!url.startsWith("https://") || !url.endsWith(".supabase.co")) {
            return "SUPABASE_URL non valida. Usa il Project URL HTTPS mostrato nel pannello Connect di Supabase."
        }
        if (!publishableKey.startsWith("sb_publishable_")) {
            return "SUPABASE_PUBLISHABLE_KEY non valida per Step 7. Usa la nuova publishable key sb_publishable_… e non una secret/service_role key."
        }
        return null
    }
}
