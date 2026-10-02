# CLAUDE.md — regole del progetto HAPOSTO

HAPOSTO: app Android (Kotlin/Compose, versioni Demo/Dev/Prod) + Supabase (migration, RLS, Edge
Function Deno) + sito statico (`web/`, pubblicato su Cloudflare Pages). Area pilota: Pesaro.

## Da leggere per primi

1. `docs/HAPOSTO_STATO_CONFIGURAZIONE.md` — **dove siamo arrivati** e come si riprende.
2. `docs/HAPOSTO_GUIDA_CONFIGURAZIONE_COMPLETA.md` — tutte le operazioni di configurazione, in ordine.
3. `docs/HAPOSTO_ROADMAP_COMPLETA.md` e `README.md` (sezione "Stato attuale").
4. `docs/modifiche/` — registro di tutte le modifiche fatte (più recenti in fondo, per data).

## Regole di lavoro (sempre)

- **Lingua:** rispondere e scrivere documenti, commit e PR in **italiano**.
- **Segreti:** non chiedere, non modificare e non pubblicare password, token, chiavi segrete, file
  `.env` o `local.properties`; i valori li inserisce il titolare. Nei file del repository (pubblico)
  niente email personali né identificativi dei progetti Supabase: usare segnaposto come `REF_DEV`.
- **Branch:** mai lavorare direttamente su `main`. Ogni modifica su un branch dedicato → PR.
- **Prima di consegnare:** verificare con i test e la CI (replicando in locale quello che si può:
  vedi la sezione 6 di `docs/HAPOSTO_STATO_CONFIGURAZIONE.md`); per un errore, prima riprodurlo poi
  mostrarlo risolto.
- **Registro modifiche (obbligatorio):** per **ogni** PR o modifica ai file del repository aggiungere
  nella stessa PR un file `docs/modifiche/AAAA-MM-GG_prNN-titolo-breve.md` (data in testa al nome) con:
  data, branch, link alla PR, motivo; tabella dei file **modificati / aggiunti / rinominati /
  eliminati**; dettaglio di ogni modifica; verifiche fatte. Se il numero della PR non è ancora noto,
  aggiungerlo con un commit subito dopo aver aperto la PR.
- **Guida passo passo:** il titolare segue la guida **una parte alla volta**. Prima di dare i passi,
  verificare che la guida corrisponda al codice; dare istruzioni precise (cosa cliccare/incollare) e
  aspettare la conferma. Se la guida o il codice hanno errori, correggerli (branch, test, CI,
  registro, PR) e aggiornare la guida con quello che emerge dalle prove reali.
- **Costi:** obiettivo costo zero. Prima di proporre qualcosa che costa o richiede una carta, dirlo
  chiaramente e chiedere.
- **Stato:** a fine parte aggiornare `docs/HAPOSTO_STATO_CONFIGURAZIONE.md` nella stessa PR.

## Comandi utili

- App: `./gradlew testDemoDebugUnitTest`, `./gradlew assembleDebug`, `./gradlew lintDemoDebug`,
  `./gradlew connectedDemoDebugAndroidTest`.
- Edge Function (da `supabase/functions`): `deno check */index.ts`, `deno lint`, `deno test --allow-env`.
- Sito: `node web/build.mjs`, `node --test web/tests/*.test.mjs`.
- SQL: vedi il job "Supabase SQL" in `.github/workflows/android-ci.yml` (ordine delle migration,
  seed, controlli).
