# HAPOSTO — Database integrativo: cosa c'è, a cosa serve, chi può fare cosa

Riferimento per le migration **0006–0011** (account, pagamenti ristoranti e utenti, Plus, pagina
pubblica, statistiche) e per i file di supporto. Per **come** eseguirle: `HAPOSTO_GUIDA_AGGIORNAMENTO_DB.md`.
Per il modello di business che implementano: `HAPOSTO_MODELLO_PREMIUM_E_ACCOUNT.md`.

> I file SQL stanno in `supabase/` (non in `docs/`) perché sono codice eseguibile e vengono
> verificati automaticamente dalla CI a ogni modifica: qui trovi la spiegazione.

---

## 1. Mappa dei file

| File | Tipo | Quando si esegue |
|---|---|---|
| `migrations/0001`–`0004` | base Step 7 (directory, stati live, RLS) | già fatto |
| `migrations/0005_realtime_future.sql` | Realtime (stati aggiornati in 1–2 secondi) | dopo la 0013 (guida di configurazione, Parte 1); rieseguibile |
| `migrations/0006_hardening_and_data_source.sql` | permessi, provenienza dati, configurazione | subito |
| `migrations/0007_accounts_and_claims.sql` | profili, admin, claim, registrazione locale | subito (usato dallo Step 8) |
| `migrations/0008_plans_and_billing.sql` | piani, abbonamenti, pagamenti, fatturazione, diritti | subito (usato dallo Step 14) |
| `migrations/0009_favorites_alerts_notifications.sql` | preferiti, avvisi Plus, push, promemoria | subito (usato dagli Step 11 e 16) |
| `migrations/0010_reservations_cloud.sql` | prenotazioni di sala sincronizzate | subito (funzione Pro futura) |
| `migrations/0011_public_page_stats_import.sql` | pagina pubblica/QR, statistiche, import directory | subito (Step 12 e 17) |
| `seeds/900_example_fictional_data.sql` | 7 locali "Demo" (Step 7) | DEV |
| `seeds/910_pseudo_realistic_dev_seed.sql` | 36 locali pseudo-realistici | DEV |
| `dev/dev_tools.sql` | simulatore + scrittura dall'app sui locali di prova | **solo DEV** |
| `dev/dev_purge.sql` | rimuove strumenti e dati di prova | prima della produzione |
| `ops/scheduled_jobs.sql` | lavori pianificati (promemoria, pulizie) | produzione, con pg_cron |
| `ops/kpi_queries.sql` | 11 query di controllo e KPI (sola lettura) | quando vuoi |
| `ops/import_osm_overpass.sql` | importa i ristoranti reali da OpenStreetMap | per ogni città, anche ogni mese |
| `tests/step8_to_17_checks.sql` | 58 controlli automatici (si annulla da solo) | dopo ogni aggiornamento |
| `tests/osm_import_check.sql` + `tests/fixtures/` | verifica dell'import OSM con dati inventati | solo CI |
| `tests/local_only_supabase_emulation.sql` | emulazione di Supabase per la CI | **mai su Supabase** |

---

## 2. Tabelle nuove

| Tabella | Cosa contiene | Chi legge | Chi scrive |
|---|---|---|---|
| `app_config` | impostazioni pubbliche (beta, versione minima, strumenti DEV) | tutti | solo tu (SQL Editor) |
| `profiles` | un profilo per ogni account: nome, admin, consensi | proprietario, admin | proprietario (nome, consenso marketing); il resto via funzioni |
| `plans` | catalogo piani con prezzi, funzioni e limiti | tutti (piani pubblici) | solo tu |
| `restaurant_subscriptions` | abbonamenti dei locali (Stripe, manuale, beta) | membri del locale, admin | solo server/admin via funzioni |
| `consumer_subscriptions` | abbonamenti Plus degli utenti | l'utente stesso, admin | solo server via funzioni |
| `restaurant_billing_profiles` | dati per la fattura elettronica (P.IVA, SDI/PEC) | titolare, admin | titolare |
| `payments` | registro dei pagamenti (specchio di Stripe/Google Play) | titolare (del suo locale), utente (i suoi), admin | solo server |
| `billing_events` | eventi webhook ricevuti (evita doppie elaborazioni) | nessuno dall'app | solo server |
| `favorites` | preferiti sincronizzati (Gratis max 5, Plus illimitati) | l'utente stesso | l'utente stesso |
| `availability_alerts` | "avvisami quando c'è posto" (solo Plus, vale una serata) | l'utente stesso | l'utente stesso (se Plus) |
| `device_push_tokens` | token Firebase dei telefoni | l'utente stesso | via `register_push_token` |
| `notification_outbox` | notifiche da inviare (avvisi, promemoria) | destinatario | il database (trigger) e il server |
| `reservations` | registro prenotazioni sincronizzato (Pro) | membri del locale | membri del locale con Pro |
| `restaurant_daily_stats` | contatori giornalieri anonimi per locale | via `restaurant_stats` | via `track_restaurant_event` e trigger |
| `directory_import_staging` | appoggio per importare una directory (es. OSM) | nessuno dall'app | `ops/import_osm_overpass.sql` o Table Editor |

Colonne nuove su tabelle esistenti:

- `restaurants.data_source` (`MANUAL`, `DEV_SEED`, `OSM_IMPORT`, `PARTNER_SIGNUP`) e `source_ref`
  (`osm:node/123` per OpenStreetMap, `field-test:…` per i locali delle prove sul campo, ignorati dal simulatore);
- `restaurants.slug` (indirizzo della pagina pubblica, generato da solo, pubblico);
- `restaurant_live_status.updated_via` e `status_history.updated_via` (`OWNER`, `STAFF`, `ADMIN`,
  `DEV_APP`, `DEV_SIMULATOR`);
- `restaurant_claims.review_note`.

---

## 3. Funzioni (RPC) e chi può chiamarle

### Pubbliche (anche senza account)

| Funzione | Cosa fa |
|---|---|
| `nearby_restaurants(lat, long, radius_meters, search_text)` | directory vicina (Step 7, invariata) |
| `public_restaurant_page(slug)` | dati per la pagina pubblica `haposto.app/<slug>` |
| `track_restaurant_event(restaurant_id, evento)` | conta `DETAIL_VIEW`, `DIRECTIONS_TAP`, `CALL_TAP`, `PUBLIC_PAGE_VIEW`, `SHARE` (anonimo) |
| `my_entitlements()` | piano e funzioni dell'utente (senza account: Gratis) |

### Utenti con account

| Funzione | Cosa fa |
|---|---|
| `accept_terms(versione)` | registra accettazione di termini e privacy |
| `register_push_token(token, piattaforma, versione_app)` | abilita le notifiche su questo telefono |
| `submit_restaurant_claim(locale, recapito)` | "questo locale è mio" |
| `register_new_restaurant(nome, categoria, indirizzo, città, provincia, lat, lon, telefono, recapito)` | locale nuovo + richiesta |
| `cancel_my_claim(richiesta)` | ritira una richiesta |
| `my_restaurants()` | locali che gestisco e con che ruolo |

### Titolari e staff

| Funzione | Chi | Cosa fa |
|---|---|---|
| `set_restaurant_live_status(locale, stato, tavoli, attesa, nota)` | titolare, staff | pubblica lo stato (tavoli/attesa/nota solo con Pro) |
| `restaurant_entitlements(locale)` | titolare, staff | piano attivo, funzioni, limiti, scadenza |
| `restaurant_stats(locale, giorni)` | titolare, staff | statistiche (Basic 7 giorni, Pro 90) |
| `add_restaurant_staff(locale, email)` / `remove_restaurant_staff(locale, utente)` | titolare (Pro) | gestione staff |

### Amministratore

`admin_pending_claims()`, `admin_review_claim(richiesta, approva, nota)`,
`admin_grant_restaurant_plan(locale, piano, mesi, nota)`, `admin_import_directory(fonte)`.

### Solo server (chiave `service_role`, dentro le Edge Function)

`billing_log_event`, `billing_upsert_restaurant_subscription`, `billing_upsert_consumer_subscription`,
`billing_record_payment`, `enqueue_manager_reminders`, `purge_old_reservations`.

L'app **non** contiene e **non deve mai** contenere la chiave `service_role`.

---

## 4. Come funziona il "diritto" a una funzione

```
restaurant_plan_code(locale) =
    abbonamento attivo (TRIALING / ACTIVE / PAST_DUE con 3 giorni di tolleranza)
    altrimenti Pro se siamo prima della fine beta (app_config.beta)
    altrimenti Basic

restaurant_has_feature(locale, 'LIVE_DETAILS') = la funzione è nell'elenco del piano?
```

Lo stesso schema vale per gli utenti (`consumer_plan_code`, `consumer_has_feature`).
Cambiare cosa include un piano = aggiornare la colonna `features` in `plans`, senza toccare codice.

---

## 5. Automatismi nel database

| Quando | Cosa succede |
|---|---|
| nuovo utente in Supabase Auth | viene creato il suo `profile` |
| un locale nuovo o rinominato | riceve uno `slug` unico (`osteria-del-porto-pesaro`, `…-2` se esiste già) |
| uno stato passa a "C'è posto"/"Pochi posti" | gli avvisi Plus su quel locale finiscono in `notification_outbox` e si spengono |
| ogni pubblicazione di stato | +1 agli aggiornamenti del giorno nelle statistiche |
| inserimento di un preferito oltre il limite | rifiutato con `FAVORITES_LIMIT_REACHED` |
| avviso senza Plus | rifiutato con `PLUS_REQUIRED` |
| ogni 5 minuti (pg_cron) | promemoria al titolare se lo stato scade entro 5 minuti (Pro) |
| ogni notte (pg_cron) | via le prenotazioni più vecchie di 30 giorni e le notifiche inviate da 30 giorni |

---

## 6. Codici di errore che l'app dovrà tradurre in italiano

| Codice | Messaggio suggerito all'utente |
|---|---|
| `AUTH_REQUIRED` | "Per questa funzione accedi con Google." |
| `PLAN_UPGRADE_REQUIRED` | "Disponibile con Pro." |
| `PLUS_REQUIRED` | "Gli avvisi sono una funzione Plus." |
| `FAVORITES_LIMIT_REACHED` | "Hai raggiunto 5 preferiti sincronizzati: con Plus sono illimitati." |
| `ALERTS_LIMIT_REACHED` | "Hai già 10 avvisi attivi." |
| `CLAIM_ALREADY_PENDING` | "La tua richiesta è già in verifica." |
| `ALREADY_MEMBER` | "Gestisci già questo locale." |
| `RESTAURANT_SUSPENDED` | "Questo locale non è al momento disponibile." |
| `USER_NOT_REGISTERED` | "Questa persona deve prima accedere una volta all'app." |
| `STAFF_LIMIT_REACHED` | "Hai raggiunto il numero massimo di account staff." |
| `OWNER_REQUIRED` / `ADMIN_REQUIRED` | "Non hai i permessi per questa operazione." |

---

## 7. Query operative

`supabase/ops/kpi_queries.sql` contiene 11 query pronte (sola lettura):

1. percentuale di partner con stato valido **adesso** (il KPI esistenziale);
2. aggiornamenti per servizio (pranzo/cena) negli ultimi 14 giorni;
3. partner "silenziosi" da più di 3 giorni (da chiamare);
4. densità per città (partner / in verifica / solo directory);
5. richieste di gestione da verificare;
6. abbonamenti per piano e fonte;
7. **MRR** stimato;
8. incassi mensili per ristoranti e Plus;
9. utenti registrati, Plus attivi, preferiti e avvisi;
10. visibilità per locale (visite, indicazioni, chiamate) — l'argomento di vendita di Pro;
11. notifiche in coda non inviate (controllo del server notifiche).

I dati di prova (`DEV_SEED`) sono esclusi dalle query di business.
