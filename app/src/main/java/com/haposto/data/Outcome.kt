package com.haposto.data

import kotlin.coroutines.cancellation.CancellationException

/**
 * Esito di un'operazione verso il server: il valore, oppure un codice d'errore stabile (quello
 * sollevato dal database, es. "MFA_REQUIRED") con il messaggio da mostrare in italiano.
 */
sealed interface Outcome<out T> {
    data class Success<T>(val value: T) : Outcome<T>
    data class Failure(val code: String, val message: String) : Outcome<Nothing>

    val valueOrNull: T? get() = (this as? Success<T>)?.value
    val isSuccess: Boolean get() = this is Success<*>
}

inline fun <T, R> Outcome<T>.map(transform: (T) -> R): Outcome<R> = when (this) {
    is Outcome.Success -> Outcome.Success(transform(value))
    is Outcome.Failure -> this
}

/** Esegue [block] trasformando ogni eccezione in [Outcome.Failure] con un messaggio comprensibile. */
suspend fun <T> outcomeOf(block: suspend () -> T): Outcome<T> = try {
    Outcome.Success(block())
} catch (cancellation: CancellationException) {
    throw cancellation
} catch (error: Throwable) {
    ErrorMessages.failureFor(error)
}

object ErrorMessages {

    /** Codici sollevati dalle funzioni SQL (supabase/migrations) → testo per l'utente. */
    private val messages = linkedMapOf(
        "MFA_REQUIRED" to "Per sicurezza serve il codice della verifica in due passaggi.",
        "ACCOUNT_BLOCKED" to "Questo account è sospeso. Scrivi all'assistenza HAPOSTO.",
        "AUTH_REQUIRED" to "Per questa funzione accedi con Google.",
        "ADMIN_REQUIRED" to "Pannello chiuso: sbloccalo di nuovo.",
        "OWNER_REQUIRED" to "Solo il titolare del locale può farlo.",
        "PLAN_UPGRADE_REQUIRED" to "Disponibile con il piano Pro.",
        "PLUS_REQUIRED" to "È una funzione di HAPOSTO Plus.",
        "FAVORITES_LIMIT_REACHED" to "Hai raggiunto il numero massimo di preferiti sincronizzati: con Plus sono illimitati.",
        "ALERTS_LIMIT_REACHED" to "Hai già il numero massimo di avvisi attivi.",
        "CLAIM_ALREADY_PENDING" to "La tua richiesta per questo locale è già in verifica.",
        "TOO_MANY_CLAIMS" to "Hai già 3 richieste in verifica: attendi l'esito.",
        "TOO_MANY_REGISTRATIONS" to "Hai già registrato due locali oggi: riprova domani.",
        "ALREADY_MEMBER" to "Questa persona gestisce già il locale.",
        "RESTAURANT_SUSPENDED" to "Questo locale è sospeso. Contatta HAPOSTO.",
        "RESTAURANT_NOT_FOUND" to "Locale non trovato.",
        "USER_NOT_REGISTERED" to "Questa persona deve prima accedere una volta all'app con quell'email.",
        "STAFF_LIMIT_REACHED" to "Hai raggiunto il numero massimo di collaboratori del tuo piano.",
        "INVALID_CONTACT" to "Scrivi un telefono o un'email validi (almeno 3 caratteri).",
        "INVALID_LOCATION" to "Posizione del locale non valida: sposta la mappa sul locale.",
        "INVALID_RESTAURANT_DATA" to "Controlla nome, indirizzo e città.",
        "INVALID_NAME" to "Il nome deve avere tra 2 e 160 caratteri.",
        "INVALID_CATEGORY" to "Scrivi il tipo di cucina (es. Trattoria).",
        "INVALID_PHONE" to "Numero di telefono non valido.",
        "PHONE_REQUIRED" to "Per mostrare il tasto Chiama serve un numero di telefono.",
        "INVALID_OPENING_HOURS" to "Orari non validi: controlla le fasce inserite.",
        "RATE_LIMITED" to "Troppi aggiornamenti in pochi minuti: attendi un momento.",
        "CLAIM_NOT_FOUND" to "Richiesta non trovata.",
        "CLAIM_NOT_PENDING" to "Questa richiesta è già stata chiusa.",
        "PHONE_NOT_VERIFIED" to "Prima serve la verifica con il codice al telefono del locale.",
        "WRONG_CODE" to "Codice sbagliato.",
        "TOO_MANY_ATTEMPTS" to "Troppi tentativi: chiedi a HAPOSTO un nuovo codice.",
        "NO_ACTIVE_CODE" to "Non c'è un codice attivo: aspetta la telefonata di HAPOSTO.",
        "SPECIFIC_CLAUSES_REQUIRED" to "Per continuare serve l'approvazione specifica delle clausole indicate.",
        "INVALID_TERMS_VERSION" to "Versione dei termini non valida.",
        "ACTIVE_RESTAURANT_SUBSCRIPTION" to "Prima disdici l'abbonamento Pro del tuo locale, poi potrai cancellare l'account.",
        "ACTIVE_PLUS_SUBSCRIPTION" to "Prima disdici HAPOSTO Plus da Google Play (Abbonamenti), poi potrai cancellare l'account.",
        "INVALID_CREDENTIALS" to "Nome utente o password del pannello non corretti.",
        "LOCKED" to "Troppi tentativi sbagliati: pannello bloccato per 15 minuti.",
        "NOT_ADMIN" to "Questo account non è amministratore.",
        "NO_CREDENTIALS" to "Credenziali del pannello non ancora create (vedi guida admin).",
        "SESSION_REQUIRED" to "Sessione non valida: esci e accedi di nuovo.",
        "CANNOT_BLOCK_SELF" to "Non puoi sospendere il tuo account.",
        "CANNOT_BLOCK_ADMIN" to "Un amministratore si toglie solo dal SQL Editor.",
        "PAID_SUBSCRIPTION_ACTIVE" to "C'è un abbonamento pagato attivo: si gestisce da Stripe o Google Play.",
        "SUBSCRIPTION_NOT_CANCELLABLE" to "Solo gli abbonamenti dati a mano si chiudono da qui.",
        "INVALID_MONTHS" to "Durata non valida (da 1 a 36 mesi).",
        "CONFIG_KEY_NOT_EDITABLE" to "Questa impostazione non si modifica dall'app.",
        "INVALID_CONFIG_VALUE" to "Valore dell'impostazione non valido.",
        "INVALID_EVENT" to "Evento non valido.",
        "Not authorized" to "Non hai i permessi per questo locale.",
        "not an active partner" to "Il locale non è ancora attivo su HAPOSTO.",
        "GOOGLE_SIGN_IN_CANCELLED" to "Accesso annullato.",
        "GOOGLE_NO_ACCOUNT" to "Nessun account Google su questo telefono: aggiungilo in Impostazioni → Account e riprova.",
        "GOOGLE_SIGN_IN_UNAVAILABLE" to "Accesso con Google non disponibile su questo telefono.",
        "NOT_CONFIGURED" to "Funzione non ancora configurata in questa versione dell'app.",
        "BILLING_UNAVAILABLE" to "Google Play non è disponibile per gli acquisti su questo telefono.",
        "DEMO_MODE" to "Nella versione demo questa funzione è simulata.",
        // Edge Function play-verify (acquisto HAPOSTO Plus).
        "PURCHASE_NOT_VALID" to "Google Play non riconosce questo acquisto.",
        "PURCHASE_OTHER_ACCOUNT" to "Questo abbonamento è legato a un altro account HAPOSTO.",
        "PLAY_API_ERROR" to "Verifica dell'acquisto non riuscita: riprova tra poco, non ti verrà addebitato due volte.",
    )

    const val GENERIC = "Operazione non riuscita. Controlla la connessione e riprova."

    fun failure(code: String): Outcome.Failure =
        Outcome.Failure(code, messages[code] ?: GENERIC)

    fun failureFor(error: Throwable): Outcome.Failure {
        val text = buildString {
            append(error.message.orEmpty())
            error.cause?.message?.let { append(' ').append(it) }
        }
        // Il codice più lungo vince: "ACCOUNT_BLOCKED" contiene anche "LOCKED".
        val code = messages.keys.filter { text.contains(it) }.maxByOrNull { it.length }
        return if (code != null) {
            Outcome.Failure(code, messages.getValue(code))
        } else {
            Outcome.Failure("UNKNOWN", GENERIC)
        }
    }

    fun messageFor(code: String): String = messages[code] ?: GENERIC
}
