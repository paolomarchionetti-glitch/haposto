package com.haposto.data.restaurant

import java.time.Duration
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter

/**
 * Cosa dire al ristoratore sul suo piano, nella dashboard e in "Gestisci il locale".
 * Dopo la prova gratuita, senza abbonamento il locale appare "Non collegato" e non pubblica.
 * Solo informazioni: nell'app niente inviti né link al pagamento (regole di Google Play sui
 * pagamenti, vedi HAPOSTO_MODELLO_PREMIUM_E_ACCOUNT.md); Pro si attiva sul sito.
 */
object PlanNotices {

    /** Da quanti giorni prima della fine si avvisa (come gli avvisi del server). */
    const val WARNING_DAYS = 7L

    private val DATE: DateTimeFormatter = DateTimeFormatter.ofPattern("dd/MM/yyyy")
    private const val CONTACT = "Per informazioni sui piani scrivi a info@haposto.app."

    fun sourceLabel(plan: RestaurantPlan): String = when {
        !plan.isConnected -> "Nessun piano: il locale appare «Non collegato»"
        plan.source == "BETA" -> "Gratis durante la beta"
        plan.source == "TRIAL" -> "Prova gratuita"
        plan.source == "STRIPE" -> "Abbonamento attivo"
        plan.source == "MANUAL" -> "Attivato da HAPOSTO"
        else -> "Attivo"
    }

    /** Avviso da mostrare (null = niente da dire): piano finito o in scadenza entro 7 giorni. */
    fun warning(plan: RestaurantPlan, now: Instant, zone: ZoneId = ZoneId.systemDefault()): String? {
        if (!plan.isConnected) {
            return "Il periodo gratuito è finito: il locale appare «Non collegato» e lo stato non si pubblica. $CONTACT"
        }
        val end = plan.validUntil ?: return null
        // Gli abbonamenti Stripe si rinnovano da soli: la disdetta si gestisce sul sito.
        if (plan.source == "STRIPE" || end.isBefore(now)) return null
        if (Duration.between(now, end) > Duration.ofDays(WARNING_DAYS)) return null
        val what = if (plan.source == "MANUAL") "Il piano" else "Il periodo gratuito"
        return "$what finisce il ${DATE.format(end.atZone(zone))}: poi il locale appare «Non collegato». $CONTACT"
    }
}
