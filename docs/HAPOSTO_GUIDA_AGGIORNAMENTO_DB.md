# HAPOSTO — Guida all'aggiornamento del database Supabase (migration 0006–0011)

Questa guida ti porta, passo per passo, dal database dello **Step 7** (migration 0001–0004) al
database **completo** che supporta account, piani a pagamento, Plus, pagina pubblica e statistiche.

- Tempo: 20–30 minuti.
- Tutto si fa dal browser, in **Supabase → SQL Editor**. Non serve installare nulla.
- Ogni file è **rieseguibile**: se lo lanci due volte non rompe niente.
- Prima fallo sul progetto **DEV**. In produzione solo quando il DEV funziona.

> Tutte le migration sono state provate prima di consegnartele: vengono applicate e verificate
> automaticamente a ogni modifica del codice (job **Supabase SQL** della CI GitHub, 58 controlli).

---

## 1. Prima di iniziare

### 1.1 Controlla da dove parti

SQL Editor → New query → incolla → **Run**:

```sql
select
    exists (select 1 from pg_tables where schemaname = 'public' and tablename = 'restaurants') as step7_ok,
    exists (select 1 from information_schema.columns
            where table_schema = 'public' and table_name = 'restaurants' and column_name = 'data_source') as gia_aggiornato;
```

| step7_ok | gia_aggiornato | Cosa fare |
|---|---|---|
| true | false | parti dal capitolo 2 |
| true | true | l'hai già fatto in parte: rieseguire tutto in ordine è sicuro |
| false | – | prima esegui 0001–0004 (`docs/STEP_7_SETUP_SUPABASE.md`) |

### 1.2 Backup (consigliato, obbligatorio in produzione)

- **Piano Pro Supabase**: Database → **Backups** → verifica che ci sia il backup giornaliero.
- **Piano gratuito**: Table Editor → per ogni tabella importante (`restaurants`, `restaurant_live_status`)
  → **Export → CSV**. Sul DEV con soli dati di prova puoi saltare.

### 1.3 Regola d'oro

Esegui i file **nell'ordine** e **un file alla volta**, sempre il file intero (Ctrl+A, Ctrl+C dal file,
Ctrl+V nell'editor). **Non** eseguire `0005_realtime_future.sql`: è per lo Step 10.

---

## 2. Le 6 migration, in ordine

Per ciascuna: SQL Editor → **New query** → incolla il file intero → **Run**.
Risultato atteso: `Success. No rows returned` (eventuali righe "NOTICE ... skipping" sono normali).

| Ordine | File | Cosa aggiunge | Verifica rapida (nuova query) | Risultato atteso |
|---|---|---|---|---|
| 1 | `supabase/migrations/0006_hardening_and_data_source.sql` | permessi più stretti, provenienza dati, configurazione pubblica | `select key from public.app_config order by key;` | `beta`, `dev_tools_enabled`, `min_supported_app_version` |
| 2 | `supabase/migrations/0007_accounts_and_claims.sql` | profili utente, amministratore, richieste di gestione (claim), registrazione locale | `select count(*) from public.profiles;` | un numero (anche 0) |
| 3 | `supabase/migrations/0008_plans_and_billing.sql` | piani, abbonamenti, pagamenti, dati di fatturazione, diritti | `select code, price_month_cents from public.plans order by code;` | 5 piani |
| 4 | `supabase/migrations/0009_favorites_alerts_notifications.sql` | preferiti, avvisi Plus, token push, coda notifiche | `select count(*) from public.favorites;` | `0` |
| 5 | `supabase/migrations/0010_reservations_cloud.sql` | registro prenotazioni sincronizzato (Pro) | `select count(*) from public.reservations;` | `0` |
| 6 | `supabase/migrations/0011_public_page_stats_import.sql` | slug/pagina pubblica, statistiche, import directory | `select name, slug from public.restaurants limit 5;` | ogni locale ha uno slug, es. `osteria-levante-demo-pesaro` |

L'app attuale continua a funzionare identica durante e dopo l'aggiornamento: la funzione che usa
(`nearby_restaurants`) non cambia.

---

## 3. Verifica completa automatica (consigliata)

Lo script `supabase/tests/step8_to_17_checks.sql` impersona visitatore, ristoratore, staff, utente,
admin e server dei pagamenti e controlla **58 regole** (chi può fare cosa). Lavora dentro una
transazione annullata alla fine: **non lascia dati**.

### 3.1 Crea 5 utenti di prova (una volta sola)

Supabase → **Authentication** → **Users** → **Add user** → **Create new user**, con
"Auto Confirm User" attivo e una password qualsiasi:

```
test-admin@haposto.test
test-owner@haposto.test
test-staff@haposto.test
test-user@haposto.test
test-user2@haposto.test
```

### 3.2 Carica il seed dello Step 7 (se non c'è già)

Lo script usa i locali "Demo" (`supabase/seeds/900_example_fictional_data.sql`).

### 3.3 Esegui

SQL Editor → incolla tutto `supabase/tests/step8_to_17_checks.sql` → **Run**.

- Esito positivo: nei messaggi trovi tante righe `ok: …` e in fondo **`TUTTI I CONTROLLI SUPERATI`**.
- Esito negativo: si ferma con `FAIL: …` e annulla tutto. Mandami quella riga.

---

## 4. Diventa amministratore della piattaforma

Serve per approvare le richieste dei ristoratori quando arriverà il login vero (Step 8).
Prima registrati nell'app o crea il tuo utente in Authentication, poi:

```sql
update public.profiles
set is_platform_admin = true
where id = (select id from auth.users where email = 'LA_TUA_EMAIL');
```

Operazioni da amministratore. Finché non c'è un pannello admin, dal SQL Editor devi "agire come te
stesso" (le funzioni `admin_*` controllano chi è l'utente). Esegui il blocco **tutto insieme**:

```sql
begin;
-- agisci come il tuo utente amministratore
select set_config('request.jwt.claim.sub',
                  (select id::text from auth.users where email = 'LA_TUA_EMAIL'), true);
set local role authenticated;

-- 1) richieste in attesa (copia il claim_id che ti interessa)
select * from public.admin_pending_claims();

-- 2) approva (true) o rifiuta (false) con una nota: togli il "--" quando sei pronto
-- select public.admin_review_claim('CLAIM_ID', true, 'Verificato al telefono del locale');

-- 3) regala Pro per 6 mesi a un partner del pilot
-- select public.admin_grant_restaurant_plan('ID_LOCALE', 'RESTAURANT_PRO', 6, 'Pilot Pesaro');
commit;
```

Senza le prime due istruzioni (cioè come utente tecnico `postgres`) le funzioni `admin_*`
rispondono `ADMIN_REQUIRED`: è voluto, così nessuno le usa per sbaglio.

---

## 5. Solo per il DEV: dati pseudo-realistici e simulatore

Dettagli in `docs/HAPOSTO_GUIDA_TEST_PSEUDOREALISTICO.md`. In breve:

1. `supabase/seeds/910_pseudo_realistic_dev_seed.sql` → Run (36 locali di prova).
2. Database → Extensions → **pg_cron** → Enable.
3. `supabase/dev/dev_tools.sql` → Run (simulatore ogni 5 minuti + scrittura dall'app sui locali di prova).

Per togliere tutto: `supabase/dev/dev_purge.sql`. **Obbligatorio prima della produzione.**

---

## 6. Solo per la produzione: lavori pianificati

Quando arrivano promemoria e notifiche (Step 11) e le prenotazioni sincronizzate:

1. Database → Extensions → **pg_cron** → Enable.
2. `supabase/ops/scheduled_jobs.sql` → Run.
3. Verifica: la query finale mostra 4 job attivi (`haposto-manager-reminders`, `haposto-purge-reservations`,
   `haposto-clean-outbox`, `haposto-expire-manual-subscriptions`).

---

## 7. Impostazioni che puoi cambiare senza toccare codice

Tabella `public.app_config` (Table Editor oppure SQL):

| Chiave | Valore di esempio | Effetto |
|---|---|---|
| `beta` | `{"restaurants_all_pro_until": "2027-06-30T23:59:59Z"}` | fino a quella data tutti i ristoranti hanno le funzioni Pro gratis |
| `min_supported_app_version` | `8` | versione minima dell'app (per chiedere un aggiornamento in futuro) |
| `dev_tools_enabled` | `true` / `false` | accende/spegne gli strumenti DEV senza cancellarli |

Esempio: chiudere la beta a fine anno:

```sql
update public.app_config
set value = '{"restaurants_all_pro_until": "2026-12-31T23:59:59Z"}', updated_at = now()
where key = 'beta';
```

I **prezzi** dei piani stanno in `public.plans` (in centesimi: `1290` = €12,90). Cambiarli non
modifica gli abbonamenti già attivi: gli importi reali li decide Stripe / Google Play.

---

## 8. Errori comuni

| Messaggio | Perché | Cosa fare |
|---|---|---|
| `relation "public.restaurants" does not exist` | mancano le migration dello Step 7 | esegui prima 0001–0004 |
| `type "extensions.geography" does not exist` | PostGIS non attivo | riesegui `0001_extensions.sql` |
| `function public.restaurant_role(uuid) does not exist` | ordine sbagliato | esegui le migration in ordine dalla 0006 |
| `permission denied for schema cron` / `schema "cron" does not exist` | pg_cron non attivo | Database → Extensions → pg_cron → Enable |
| `duplicate key value violates unique constraint "restaurants_slug_uidx"` | due locali con stesso nome e città creati a mano con lo stesso slug | lascia `slug` vuoto: lo genera il database |
| lo script di test si ferma con `FAIL` | una regola non è rispettata | mandami la riga `FAIL` completa |

---

## 9. Tornare indietro

Le migration aggiungono tabelle, colonne e funzioni senza cancellare dati esistenti. Se proprio
serve annullare sul DEV, la strada più semplice è un progetto DEV nuovo (gratuito) su cui rieseguire
tutto da capo. In produzione usa il backup del passo 1.2.
