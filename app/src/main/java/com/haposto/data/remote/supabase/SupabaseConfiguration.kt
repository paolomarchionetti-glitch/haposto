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
            return "Configurazione Supabase incompleta: in local.properties servono sia l'indirizzo sia la chiave publishable di questa versione (DEV: SUPABASE_DEV_URL e SUPABASE_DEV_PUBLISHABLE_KEY; PROD: SUPABASE_PROD_URL e SUPABASE_PROD_PUBLISHABLE_KEY)."
        }
        if (!url.startsWith("https://") || !url.endsWith(".supabase.co")) {
            return "Indirizzo Supabase non valido. Usa il Project URL HTTPS mostrato nel pannello Connect di Supabase."
        }
        if (!publishableKey.startsWith("sb_publishable_")) {
            return "Chiave Supabase non valida. Usa la publishable key sb_publishable_…, mai una secret/service_role key."
        }
        return null
    }
}
