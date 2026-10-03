# 2026-10-03 — Modello di pagamento: prova, "Non collegato", prezzi IVA inclusa, semestrale

- **Data:** 3 ottobre 2026
- **Branch:** `claude/amazing-pasteur-dull9l`
- **PR:** [#18](https://github.com/paolomarchionetti-glitch/haposto/pull/18)
- **Motivo:** decisioni del titolare del 2 ottobre 2026 sul modello di pagamento:
  1. chi non paga → **"Non collegato"**;
  2. **Pro**, IVA inclusa: 19,90 € al mese, 99,90 € per 6 mesi, 199,90 € l'anno (provvisori);
  3. chi entra a beta finita ha **un mese di prova**, modificabile dal pannello admin;
  4. **Plus** per gli utenti, IVA inclusa: 0,99 € al mese, 4,99 € per 6 mesi, 9,99 € l'anno (vantaggi
     da definire meglio).

## File modificati, aggiunti, rinominati ed eliminati

| File | Tipo |
|---|---|
| `supabase/migrations/0016_paid_plans_and_trial.sql` | aggiunto |
| `supabase/tests/step20_paid_plans_trial_checks.sql` | aggiunto |
| `supabase/tests/step8_to_17_checks.sql` | modificato |
| `supabase/ops/scheduled_jobs.sql` | modificato |
| `supabase/functions/_shared/stripe.ts` | modificato |
| `supabase/functions/_shared/billing_test.ts` | modificato |
| `supabase/functions/stripe-checkout/index.ts` | modificato |
| `.github/workflows/android-ci.yml` | modificato |
| `app/src/main/java/com/haposto/data/restaurant/PlanNotices.kt` | aggiunto |
| `app/src/test/java/com/haposto/data/restaurant/PlanNoticesTest.kt` | aggiunto |
| `app/src/main/java/com/haposto/data/restaurant/ManagementModels.kt` | modificato |
| `app/src/main/java/com/haposto/data/Outcome.kt` | modificato |
| `app/src/main/java/com/haposto/platform/billing/PlayBilling.kt` | modificato |
| `app/src/main/java/com/haposto/ui/screens/restaurant/RestaurantManagerRoute.kt` | modificato |
| `app/src/main/java/com/haposto/ui/screens/restaurant/RestaurantManagerScreen.kt` | modificato |
| `app/src/main/java/com/haposto/ui/screens/settings/RestaurantSettingsRoute.kt` | modificato |
| `app/src/main/assets/legal/termini-ristoranti.md` | modificato |
| `web/src/assets/ristoratori.js` | modificato |
| `web/src/ristoratori/index.html` | modificato |
| `docs/HAPOSTO_GUIDA_CONFIGURAZIONE_COMPLETA.md` | modificato |
| `docs/HAPOSTO_GUIDA_APP_TUTORIAL.md` | modificato |
| `docs/HAPOSTO_MODELLO_PREMIUM_E_ACCOUNT.md` | modificato |
| `docs/HAPOSTO_ROADMAP_COMPLETA.md` | modificato |
| `docs/HAPOSTO_STATO_CONFIGURAZIONE.md` | modificato |
| `README.md` | modificato |
| `docs/modifiche/2026-10-03_pr18-modello-di-pagamento.md` | aggiunto (questo file) |

Nessun file rinominato o eliminato.

## Dettaglio delle modifiche

### Database (migration 0016, rieseguibile)

- **Prezzi** nella tabella `plans`, IVA inclusa: Pro 1990 / 9990 / 19990 centesimi, Plus 99 / 499 / 999.
  - Colonne nuove: `price_semester_cents` e `stripe_price_semester`.
  - Gli abbonamenti accettano il periodo `SEMESTER`.
- **"Basic" diventa "Nessun piano"**: non è più in vendita e non pubblica lo stato. Restano solo le
  statistiche essenziali.
- **Prova del locale**:
  - colonna `restaurants.partner_since`: si segna la prima volta che il locale diventa partner e
    non riparte se esce e rientra. Ai partner esistenti si dà la data dell'approvazione o della
    creazione;
  - impostazione `restaurant_trial` (`{"days": 30}`), modificabile dal pannello admin (0–365,
    numeri interi; ogni modifica va nel registro operazioni);
  - fine del periodo gratuito = il più tardi tra fine beta e inizio partner + giorni di prova.
    Così chi entra poco prima della fine della beta ha comunque il suo mese.
- **Piano che vale adesso** (`restaurant_plan_code`, `restaurant_entitlements`): abbonamento →
  prova → nessun piano. Fonte: `STRIPE` / `MANUAL`, `BETA`, `TRIAL` oppure `NONE`.
- **Senza piano non si pubblica**: un trigger sulla tabella dello stato risponde
  `SUBSCRIPTION_REQUIRED` a titolare e staff, con qualsiasi versione dell'app. Le scritture senza
  utente non sono toccate (server, seed, strumenti DEV).
- **"Non collegato" per chi guarda**: lista, pagina del QR e dettagli mostrano il partner senza piano
  come "solo directory", senza stato, offerta, link e file. Le colonne restano le stesse: le app
  installate funzionano. Il piano si calcola solo per i partner, non per le migliaia di locali di
  directory.
- **Avvisi di scadenza**: `enqueue_plan_expiry_notices()` manda una notifica al titolare (non allo
  staff) 7 giorni e 1 giorno prima della fine.
  - Vale per prova, beta, mesi regalati e Stripe disdetto; non per Stripe che si rinnova da solo.
  - Una sola volta per scadenza (tabella `plan_expiry_notices`, con i permessi espliciti come
    richiede Supabase dal 2026).
  - Lavoro pianificato `haposto-plan-expiry-notices` in `supabase/ops/scheduled_jobs.sql`, ogni
    giorno alle 08:00 UTC.
- **Controlli**: `step20_paid_plans_trial_checks.sql` (42 controlli), anche sul "nuovo progetto di
  produzione". In `step8_to_17_checks.sql` i controlli del vecchio "Basic gratuito" sono diventati
  quelli del nuovo modello:
  - catalogo con 3 piani in vendita;
  - senza piano: SUBSCRIPTION_REQUIRED;
  - conteggio delle pubblicazioni del giorno: 4.

### Edge Function

- `stripe-checkout`: periodo `SEMESTER`. Il prezzo arriva da `STRIPE_PRICE_PRO_SEMESTER` o da
  `plans.stripe_price_semester`. L'IVA del segreto `STRIPE_TAX_RATE_ID` ora è inclusa nel prezzo.
- `_shared/stripe.ts`: `billingInterval` (un prezzo mensile con `interval_count` 6 è semestrale) e
  `requestedInterval`, con test.

### App

- **Dashboard**: avviso in cima quando il piano è finito o finisce entro 7 giorni, con il tasto
  **Vedi il tuo piano**.
- **Gestisci il locale → Il tuo piano**:
  - fonte (beta, prova, abbonamento, attivato da HAPOSTO, nessun piano) e data di fine;
  - l'avviso e cosa include Pro.
- Messaggio in italiano per `SUBSCRIPTION_REQUIRED`.
- Plus: il periodo `P6M` si legge "ogni 6 mesi".
- **Regole di Google Play**: nell'app niente inviti né link al pagamento, come già stabilito in
  `HAPOSTO_MODELLO_PREMIUM_E_ACCOUNT.md`, sezione 6. Restano solo le informazioni e il contatto
  email. La stessa regola vale per il testo della notifica di scadenza.

### Sito (area ristoratori)

- Prezzi letti dal database con "IVA inclusa"; tre tasti: mensile, semestrale, annuale.
- Avviso "Non collegato" o "la prova finisce il …".
- Etichette della prova.
- Riquadro "Prova gratuita" al posto di "Basic · gratis".
- Corretto un difetto che c'era già: con le condizioni accettate la pagina mostrava la scritta
  "null". Il motivo: `replaceChildren` scrive le parti assenti come testo.

### Documenti

- **Guida**:
  - Parte 7: tre piani base di Plus;
  - Parte 8: tre prezzi Stripe IVA inclusa, prezzo semestrale, aliquota inclusa, come cambiare i
    prezzi;
  - 10.2: migration fino alla 0016, con `restaurant_trial` tra le impostazioni attese;
  - Parte 11: durata della prova e mesi di Pro regalati.
- Aggiornati anche modello premium, roadmap (D5 e sintesi pagamenti) e tutorial ("Quanto costa?").
- **Bozza delle condizioni per i ristoranti**: clausole 4.1–4.4 e 10 riscritte sul nuovo modello.
  È ancora una bozza da far verificare a un avvocato; la versione resta 2026-10 finché non viene
  pubblicata.

## Costi

Nessuno. Stripe e Google Play si configurano solo con le Parti 7 e 8, già rimandate.

## Verifiche

Eseguite in locale prima dell'invio:

- **Job "Supabase SQL" della CI** completo, con la 0016:
  - migration e loro riesecuzione;
  - step8_to_17 (aggiornato), step18, step19 e **step20**;
  - ordine della guida, KPI, import OSM, strumenti e pulizia DEV;
  - nuovo progetto di produzione (stessi permessi del DEV, anche per `plan_expiry_notices`; step20
    compreso).

  Tutto verde.
- **Edge Function**: `deno check`, `deno lint`, `deno test` (14 test, 1 nuovo).
- **Kotlin** su JVM:
  - dominio: 60 test;
  - livello dati e ViewModel della dashboard: 52 test, compresi i 4 nuovi di `PlanNoticesTest`.
- **Sito**:
  - build e 4 test;
  - prova in Chromium dell'area ristoratori con un finto Supabase: prova finita, prova in scadenza,
    Stripe attivo;
  - il difetto "null" prima riprodotto, poi risolto.
- CI su GitHub: vedi la PR.
