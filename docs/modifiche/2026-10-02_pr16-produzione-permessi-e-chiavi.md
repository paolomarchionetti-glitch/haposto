# 2026-10-02 — Parte 10: progetto di produzione su Supabase del 2026 (permessi e chiavi)

- **Data:** 2 ottobre 2026
- **Branch:** `claude/amazing-pasteur-dull9l`
- **PR:** [#16](https://github.com/paolomarchionetti-glitch/haposto/pull/16)
- **Motivo:** prima di dare i passi della Parte 10 (progetto di produzione) la guida è stata
  confrontata con il codice e con il comportamento attuale di Supabase per i progetti **nuovi**. Due
  cambiamenti di Supabase avrebbero rotto la produzione, pur con il DEV funzionante:
  1. dal 30 maggio 2026 i progetti nuovi **non danno più permessi automatici** sulle tabelle di
     `public` ai ruoli delle API (`anon`, `authenticated`, `service_role`; dal 30 ottobre 2026 vale
     anche per le tabelle nuove dei progetti esistenti). Le migration davano già permessi espliciti
     ad `anon` e `authenticated`, ma **non** a `service_role`: le Edge Function dei pagamenti (Plus e
     Pro) non avrebbero potuto leggere o scrivere `billing_events`, `plans`,
     `consumer_subscriptions`, `restaurant_subscriptions`;
  2. i progetti nuovi **non hanno chiavi legacy** (`anon`, `service_role`): le Edge Function
     cercavano solo `SUPABASE_SERVICE_ROLE_KEY` / `SUPABASE_ANON_KEY` (o un segreto copiato a mano) e
     avrebbero risposto `NOT_CONFIGURED`. Supabase passa invece le chiavi nuove in
     `SUPABASE_SECRET_KEYS` / `SUPABASE_PUBLISHABLE_KEYS` (JSON con la chiave `default`).
  Inoltre la Parte 10 della guida era un elenco sommario: mancavano il client Android per
  `com.haposto`, l'app Firebase di produzione, l'ordine giusto (l'accesso all'app prima delle
  credenziali admin), il cambio di progetto della CLI, i controlli attesi e la pausa dei progetti Free.

## File modificati, aggiunti e rinominati

| File | Tipo |
|---|---|
| `supabase/migrations/0014_explicit_grants.sql` | aggiunto |
| `supabase/functions/_shared/supabase.ts` | modificato |
| `supabase/functions/_shared/supabase_test.ts` | aggiunto |
| `.github/workflows/android-ci.yml` | modificato |
| `docs/HAPOSTO_GUIDA_CONFIGURAZIONE_COMPLETA.md` | modificato |
| `docs/HAPOSTO_GUIDA_APP_E_DATI_REALI.md` | modificato |
| `docs/HAPOSTO_STATO_CONFIGURAZIONE.md` | modificato |
| `README.md` | modificato |
| `docs/modifiche/2026-10-02_pr16-produzione-permessi-e-chiavi.md` | aggiunto (questo file) |

## Dettaglio delle modifiche

- **`0014_explicit_grants.sql`** (rieseguibile): `select, insert, update, delete` su tutte le tabelle
  di `public` e `usage, select` sulle sequenze a `service_role`, cioè gli stessi permessi che il
  ruolo ha in automatico sul DEV (lì il file non cambia nulla). In fondo mostra
  `tabelle_senza_permessi_del_server` (atteso 0). Il commento fissa la regola per il futuro: ogni
  tabella nuova ha i suoi `GRANT` espliciti nella migration che la crea.
- **`_shared/supabase.ts`:** la chiave del server e quella pubblica si cercano in quest'ordine:
  segreto `HAPOSTO_SECRET_KEY` / `HAPOSTO_PUBLISHABLE_KEY` messo a mano (resta valido), chiave
  `default` di `SUPABASE_SECRET_KEYS` / `SUPABASE_PUBLISHABLE_KEYS` (come indica la documentazione
  di Supabase), chiave legacy. Sul DEV le funzioni ripubblicate passano alle chiavi nuove, prima che
  Supabase spenga quelle legacy a fine 2026.
- **`_shared/supabase_test.ts`:** 4 test (progetto nuovo senza chiavi legacy, precedenze, progetto
  vecchio o JSON senza `default`, nessuna chiave → `NOT_CONFIGURED`).
- **CI, job SQL:** la 0014 nell'elenco delle migration e nella riesecuzione; nuovo passo *New
  production project (no automatic grants)*: database emulato come un progetto creato dopo il 30
  maggio 2026 (senza permessi automatici su tabelle e sequenze), solo migration; i permessi su
  tabelle e colonne di `anon`, `authenticated` e `service_role` devono coincidere con quelli del
  database "tipo DEV"; poi le operazioni che le Edge Function fanno con `service_role`, i controlli
  step8_to_17 e step18 e l'import OpenStreetMap come dal SQL Editor.
- **Guida, Parte 10** riscritta in 10 sottoparti da fare una alla volta: 10.1 creazione del progetto
  (regione, opzioni Data API, piano Free), 10.2 migration 0001–0014 con query di verifica e valori
  attesi, 10.3 directory OpenStreetMap, 10.4 login Google e 2FA (redirect URI, dominio, provider,
  Email spento, TOTP), 10.5 app `prodDebug` (client Android `com.haposto` con lo SHA-1 di debug,
  `local.properties`, voce di Authenticator da rinominare), 10.6 credenziali admin diverse dal DEV,
  10.7 app Firebase `com.haposto` e `FIREBASE_PROD_…`, 10.8 Edge Function e lavori pianificati
  (cambio di progetto della CLI, segreti nuovi), 10.9 sito sulla produzione (con le conseguenze),
  10.10 beta già attiva fino al 30 giugno 2027, backup, pausa dei progetti Free.
- **Guida, altre parti:** 2.2 (client Android di debug per `com.haposto` in Parte 10, quello di Play
  in Parte 7), fine del 6.2 (niente *secret key* nei segreti), diagnosi del 6.3
  (`500 DATABASE_ERROR`), durata della Parte 10 nella tabella iniziale.
- **`HAPOSTO_GUIDA_APP_E_DATI_REALI.md` e `README.md`:** elenco delle migration aggiornato (0014;
  la 0005 anche in produzione) e rimando alla Parte 10.
- **Stato:** Parte 10 in corso; da fare dopo l'unione: ripubblicare le funzioni sul DEV; lezione su
  permessi e chiavi dei progetti nuovi; note sulla CI.

## Verifiche

- **Errore riprodotto, poi risolto (SQL):** Postgres 16 + PostGIS in locale, emulazione di un
  progetto nuovo (senza permessi automatici): dopo 0001–0013 le 24 tabelle di `public` erano tutte
  senza permessi per `service_role` (e i controlli RLS passavano lo stesso: il difetto non si vedeva);
  dopo la 0014: 0, anche rieseguendola e anche sul database "tipo DEV".
- **Errore riprodotto, poi risolto (funzioni):** i nuovi test Deno fallivano sul codice di prima
  (2 su 4: con le sole chiavi nuove → `NOT_CONFIGURED`), passano dopo la correzione.
- **Job SQL della CI eseguito in locale per intero**, leggendo i passi `run` direttamente dal
  workflow: tutti verdi (`TUTTI I CONTROLLI SUPERATI`, `CONTROLLI SICUREZZA SUPERATI` due volte,
  KPI, `IMPORT OSM OK`, `STRUMENTI DEV OK`, pulizia DEV, nuovo passo di produzione).
- **Il nuovo passo protegge davvero:** togliendo la 0014 fallisce (810 permessi di `service_role`
  mancanti nel confronto con il DEV).
- Valori attesi della query di verifica della guida (10.2) ricavati da un database appena migrato.
- Edge Function: `deno check */index.ts`, `deno lint`, `deno test --allow-env` (9 test) verdi.
- Documentazione Supabase consultata: variabili delle Edge Function (`SUPABASE_SECRET_KEYS`,
  `SUPABASE_PUBLISHABLE_KEYS`), chiavi API e progetti senza chiavi legacy, permessi espliciti
  (*Securing your API*, discussione "Tables not exposed to Data and GraphQL API automatically").
- App Android non toccata (nessuna verifica Gradle necessaria); la CI completa gira sulla PR.
