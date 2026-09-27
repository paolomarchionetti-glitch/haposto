# HAPOSTO — Roadmap integrativa (settembre 2026)

> **Aggiornamento:** l'elenco completo e dettagliato di tutte le attività fino alla fine del progetto
> (login reali, termini e privacy, pagamenti, Play Store, pilot, gestione) e il calendario aggiornato
> sono in **`HAPOSTO_ROADMAP_COMPLETA.md`**. Questo documento resta come riepilogo dello Step 7.9.

Aggiorna `ROADMAP.md` e `HAPOSTO_ROADMAP_TOP_FREEMIUM.md` con quello che è stato fatto in questo
passaggio e con l'ordine dei lavori da qui al lancio. Dove i due documenti precedenti non coincidono,
vale questo.

Legenda: ✅ fatto · 🟩 database pronto, manca l'app · ⬜ da fare · 🔴 critico · 🟠 alto · 🟡 medio · 🟢 opzionale

---

## 1. Dove siamo

| Step | Contenuto | Stato |
|---|---|---|
| 0–6 | Fondazione Android, UI consumer, posizione, dashboard locale, claim demo, robustezza, demo completa | ✅ |
| 7 | Supabase: directory reale, RPC `nearby_restaurants`, RLS, seed di prova | ✅ |
| 7.5–7.8 | Brand, bottom nav, onboarding, interfaccia essenziale, registro prenotazioni locale | ✅ |
| **7.9** | **Questo passaggio**: dati pseudo-realistici, simulatore, database completo, UI a prova di errore | ✅ |

### Cosa ha aggiunto lo Step 7.9

- **Database completo** (migration 0006–0011): account e profili, amministratore, richieste di gestione,
  registrazione di un locale nuovo, piani Basic/Pro/Pro+ e Gratis/Plus, abbonamenti, pagamenti,
  dati di fatturazione elettronica, preferiti e avvisi, token push, coda notifiche, prenotazioni cloud,
  pagina pubblica con slug, statistiche giornaliere, import della directory. 58 controlli automatici.
- **Ambiente DEV pseudo-realistico**: 36 locali credibili in 4 città, simulatore che segue gli orari
  italiani (pranzo, cena, weekend, notte), locali "pigri", scrittura condivisa tra due telefoni.
- **App**: la lista si aggiorna da sola ogni minuto; la dashboard del ristoratore mostra in grande
  "I clienti adesso vedono", quanto manca alla scadenza e un tasto unico "È ancora così: confermo";
  tasti di stato pieni e grandi con simbolo; stati leggibili anche da chi non distingue i colori
  (✓ ! ✕ ? –) e con contrasto verificato; percorso di accesso in 3 passi numerati; preferiti salvati
  sul telefono con tab dedicata.
- **CI**: oltre a build, test e lint, ora a ogni modifica gira anche tutto il database su un Postgres
  con PostGIS (migration, seed, simulatore, controlli, KPI, pulizia).

---

## 2. La strada da qui al lancio

| Step | Titolo | Priorità | Stato | Dipende da |
|---|---|---|---|---|
| 8 | Login Google reale + richiesta di gestione reale | 🔴 | 🟩 | 7.9 |
| 9 | Pubblicazione dello stato protetta (fine del demo) | 🔴 | 🟩 | 8 |
| 10 | Aggiornamento in tempo reale (Realtime) | 🟠 | 🟩 (`0005`) | 9 |
| 11 | Promemoria al ristoratore (notifiche) | 🟠 | 🟩 | 9 |
| 12 | Pagina pubblica + QR "Prima di chiamare" | 🟠 | 🟩 | 9 |
| 13 | **Pilot Pesaro** (20–40 locali veri) | 🔴 | ⬜ | 8–12 |
| 14 | Pagamenti ristoranti (Pro, Stripe web) | 🟠 | 🟩 | 13 |
| 15 | Pubblicazione su Play Store + privacy + KPI | 🔴 | ⬜ (parallelo) | 7.9 |
| 16 | HAPOSTO Plus per gli utenti (Google Play Billing) | 🟡 | 🟩 | 11, 15 |
| 17 | Statistiche per il ristoratore (Pro) | 🟡 | 🟩 | 9 |
| 18 | Vista mappa | 🟢 | ⬜ | 13 |
| 19 | iOS | 🟢 | ⬜ | stabilità Android |

"🟩" significa che tabelle, permessi e funzioni sono già scritti e verificati: il lavoro rimasto è
nell'app (schermate, chiamate) e, dove indicato, in una piccola funzione server (Edge Function).

---

## 3. Dettaglio degli step

### Step 8 — Login Google reale + richiesta di gestione

**Obiettivo:** chi apre l'area ristoratore entra con il proprio account Google e chiede di gestire il
proprio locale; tu approvi.

App:
- Credential Manager + Supabase Auth (Google, ID token). Nessuna password da ricordare.
- Sostituire `FakeRestaurantAccessRepository` con un repository Supabase che chiama
  `submit_restaurant_claim`, `register_new_restaurant`, `cancel_my_claim`, `my_restaurants`.
- Schermata "Il tuo locale non c'è?" → modulo breve (nome, indirizzo, telefono) → `register_new_restaurant`.
- Termini e privacy al primo accesso → `accept_terms('2026-10')`.
- Il tasto "Simula approvazione admin" resta solo nelle build di debug.

Tu (admin): approvi da SQL Editor (`HAPOSTO_GUIDA_AGGIORNAMENTO_DB.md` §4); più avanti un mini pannello web.

**Fatto quando:** un ristoratore vero accede, trova il suo locale, invia la richiesta; dopo la tua
approvazione vede la dashboard; un secondo account non può vedere né modificare quel locale.

### Step 9 — Pubblicazione protetta

**Obiettivo:** gli stati li scrive solo chi gestisce il locale, dal proprio account.

- La dashboard chiama `set_restaurant_live_status` (esiste già, controlla ruolo e piano).
- Si toglie l'overlay in memoria dell'app e la scrittura DEV (`dev_publish_live_status` resta solo
  per il progetto DEV).
- Dettagli (tavoli, attesa, nota) visibili solo con Pro: durante la beta tutti hanno Pro gratis
  (`app_config.beta`), quindi nessun ristoratore perde nulla.
- Staff: `add_restaurant_staff(email)` per camerieri e soci (Pro).

**Fatto quando:** con due telefoni e due account reali, lo stato pubblicato da A compare su B entro
un minuto; un account non autorizzato riceve "Non hai i permessi".

### Step 10 — Tempo reale

- Eseguire `0005_realtime_future.sql`; l'app si iscrive ai cambi di `restaurant_live_status` e la
  lista si aggiorna in 1–2 secondi. Il refresh ogni minuto resta come rete di sicurezza.

**Fatto quando:** B vede il cambio di A in meno di 3 secondi con rete buona.

### Step 11 — Promemoria al ristoratore

- Firebase Cloud Messaging (solo messaggi; niente Firebase Auth né database).
- Edge Function `push-dispatch` che legge `notification_outbox` e invia; `register_push_token` dall'app.
- Promemoria "Il tuo stato scade tra 5 minuti: è ancora così?" con 3 azioni rapide nella notifica
  (C'è posto / Pochi posti / Completo) che pubblicano senza aprire l'app.
- Attivare `ops/scheduled_jobs.sql`.

**Fatto quando:** nel pilot la percentuale di stati validi durante il servizio supera il 70%.

### Step 12 — Pagina pubblica + QR

- Pagina web statica (es. Cloudflare Pages o Supabase Storage) `haposto.app/<slug>` che chiama
  `public_restaurant_page(slug)` e `track_restaurant_event(..., 'PUBLIC_PAGE_VIEW')`.
- Generatore QR e adesivo A6 "Prima di chiamare, guarda se c'è posto" da stampare.

**Fatto quando:** un QR stampato apre la pagina del locale con lo stato attuale, senza installare l'app.

### Step 13 — Pilot Pesaro

- 20–40 locali veri in 2–3 zone vicine (centro, mare, Baia Flaminia): la **densità** conta più del numero.
- Directory reale importata da OpenStreetMap (`HAPOSTO_GUIDA_APP_E_DATI_REALI.md` §3).
- Pro gratis a tutti i partner (`admin_grant_restaurant_plan` o semplicemente la beta).
- Durata: 6–8 settimane. Una chiamata a settimana ai locali "silenziosi" (KPI 3).

**Criteri di successo** (query in `supabase/ops/kpi_queries.sql`):

| KPI | Soglia per andare avanti |
|---|---|
| Stati validi durante cena (KPI 1 alle 20:30) | ≥ 60% dei partner |
| Partner che aggiornano almeno 4 servizi su 7 | ≥ 50% |
| Utenti che tornano entro 7 giorni | ≥ 25% |
| Ristoratori che direbbero "lo pagherei" | ≥ 30% degli attivi |

Se i primi due non sono raggiunti, **non** si passa ai pagamenti: si lavora su promemoria e semplicità.

### Step 14 — Pagamenti ristoranti

- Pagina web di abbonamento (fuori dall'app, niente commissioni Play sul B2B) con Stripe Checkout.
- Edge Function `stripe-webhook`: verifica la firma e chiama `billing_log_event`,
  `billing_upsert_restaurant_subscription`, `billing_record_payment` (già pronte).
- Nell'app: sezione "Il tuo piano" che legge `restaurant_entitlements` e mostra solo lo stato del piano
  (nessun link di acquisto nell'app per il B2B finché le policy Play non sono verificate).
- Fatture elettroniche: Stripe Invoicing + intermediario SDI, oppure il tuo commercialista con i dati
  di `restaurant_billing_profiles`.

**Fatto quando:** un locale di prova paga in modalità test Stripe, il piano diventa Pro, lo storno o
il mancato rinnovo lo riportano a Basic dopo 3 giorni di tolleranza.

### Step 15 — Play Store (binario parallelo, iniziare subito)

- Account sviluppatore Play, test interno → test chiuso (almeno 12 tester per 14 giorni se l'account è
  personale) → produzione.
- Privacy policy pubblica, modulo "Sicurezza dei dati", testo della richiesta di posizione.
- Crash reporting e metriche essenziali senza dati personali.
- Firma dell'app, `versionCode` crescente, `min_supported_app_version` in `app_config`.

### Step 16 — HAPOSTO Plus

- Google Play Billing (abbonamento `haposto_plus`), Edge Function `play-verify` + notifiche RTDN →
  `billing_upsert_consumer_subscription`.
- Nell'app: preferiti sincronizzati (oggi sono sul telefono), "Avvisami quando c'è posto",
  raggio esteso, filtri avanzati.
- Regola: **la ricerca base resta sempre gratuita** e senza account.

### Step 17 — Statistiche ristoratore

- L'app chiama `track_restaurant_event` su apertura scheda, indicazioni, chiamata, condivisione.
- Nuova card "Quante persone ti hanno visto" nella dashboard (`restaurant_stats`, 7 giorni Basic, 90 Pro).

---

## 4. Calendario indicativo

| Periodo | Lavoro |
|---|---|
| Ottobre 2026 | Prove DEV pseudo-realistiche; Step 8 e 9; avvio Step 15 (account Play, privacy) |
| Novembre 2026 | Step 10, 11, 12; import directory Pesaro; primi 10 locali in prova |
| Dicembre 2026 – gennaio 2027 | Pilot (Step 13) con 20–40 locali; test chiuso Play |
| Febbraio – marzo 2027 | Decisione go/no-go sui KPI; Step 14 in modalità test; Step 17 |
| Primavera 2027 | Pubblicazione Play, Plus (Step 16), estensione a Fano |
| 30 giugno 2027 | Fine beta gratuita ristoranti (modificabile in `app_config`) |

Le date dipendono dal pilot: è meglio spostarle che lanciare con dati vecchi.

---

## 5. Rischi principali

| Rischio | Segnale | Contromisura |
|---|---|---|
| I ristoratori smettono di aggiornare | KPI 1 sotto 50% | promemoria (Step 11), tasto conferma, telefonata settimanale |
| Poca densità: l'utente trova 2 locali | KPI 4 | concentrarsi su una zona alla volta, directory OSM per riempire la lista |
| Lo stato è sbagliato e il cliente trova pieno | segnalazioni | scadenza 30 minuti già attiva, testo "non è una prenotazione" |
| Pagamenti B2B nell'app violano le policy Play | revisione Play | acquisto Pro solo su web, nell'app solo lo stato del piano |
| Dati di prova finiti in produzione | query `data_source = 'DEV_SEED'` | `dev_purge.sql` obbligatorio, progetti Supabase separati |
| Chiave segreta nell'APK | revisione codice | solo chiave publishable nell'app, `service_role` solo nelle Edge Function |

---

## 6. Cosa NON fare ora

- Prenotazioni fatte dal cliente tramite l'app (cambia l'identità del prodotto: vedi
  `HAPOSTO_ROADMAP_PRENOTAZIONI_E_UX.md`).
- Recensioni, foto caricate dagli utenti, menù completi: pesano, non aiutano "c'è posto adesso?".
- Chiedere l'account agli utenti per cercare: la ricerca resta libera.
- Più di 3 stati: "C'è posto / Pochi posti / Completo" è il prodotto.
