# CLAUDE.md — regole del progetto HAPOSTO

HAPOSTO: app Android (Kotlin/Compose, versioni Demo/Dev/Prod) + Supabase (migration, RLS, Edge
Function Deno) + sito statico (`web/`, pubblicato su Cloudflare Pages). Area pilota: Pesaro.

## Da leggere per primi

1. `docs/configurazione/2026-10-17_HAPOSTO_STATO_CONFIGURAZIONE.md` — **dove siamo arrivati** e come si riprende.
2. `docs/configurazione/2026-10-12_HAPOSTO_GUIDA_CONFIGURAZIONE_COMPLETA.md` — tutte le operazioni di configurazione, in ordine.
3. `docs/roadmap/2026-10-12_HAPOSTO_ROADMAP_DA_QUI_AL_LANCIO.md` (percorso da seguire), `docs/roadmap/2026-10-05_HAPOSTO_ROADMAP_COMPLETA.md`
   (archivio delle scelte) e `README.md` (sezione "Stato attuale").
4. `docs/modifiche/` — registro di tutte le modifiche fatte (più recenti in fondo, per data).
5. `docs/README.md` — indice di tutti i documenti, divisi per tema.

## Regole di lavoro (sempre)

- **Lingua:** rispondere e scrivere documenti, commit e PR in **italiano**.
- **Segreti:** non chiedere, non modificare e non pubblicare password, token, chiavi segrete, file
  `.env` o `local.properties`; i valori li inserisce il titolare. Nei file del repository (pubblico)
  niente email personali né identificativi dei progetti Supabase: usare segnaposto come `REF_DEV`.
- **Branch:** mai lavorare direttamente su `main`. Ogni modifica su un branch dedicato → PR.
- **Prima di consegnare:** verificare con i test e la CI (replicando in locale quello che si può:
  vedi la sezione 6 di `docs/configurazione/2026-10-17_HAPOSTO_STATO_CONFIGURAZIONE.md`); per un errore, prima riprodurlo poi
  mostrarlo risolto.
- **Registro modifiche (obbligatorio):** per **ogni** PR o modifica ai file del repository aggiungere
  nella stessa PR un file `docs/modifiche/AAAA-MM-GG_prNN-titolo-breve.md` (data in testa al nome) con:
  data, branch, link alla PR, motivo; tabella dei file **modificati / aggiunti / rinominati /
  eliminati**; dettaglio di ogni modifica; verifiche fatte. Se il numero della PR non è ancora noto,
  aggiungerlo con un commit subito dopo aver aperto la PR.
- **Documenti in `docs/`:** in cartelle a tema (`configurazione/`, `guide/`, `roadmap/`,
  `progetto/`, `PR/`, `step/`; vedi `docs/README.md`), con il nome `AAAA-MM-GG_NOME.md` dove la data
  è quella dell'**ultimo aggiornamento del contenuto**. Quando si modifica un documento:
  - rinominarlo con `git mv` alla data del giorno (la storia del file resta);
  - aggiornare tutti i riferimenti (documenti, `README.md`, questo file, `docs/README.md`):
    aggiornare **solo** i riferimenti a un altro documento non cambia la data di chi lo cita;
  - nel codice, negli SQL e nei file di configurazione citare il documento con la **cartella**
    (es. «specifiche della tessera in `docs/PR/PR22-30_tessera-fedelta/`»), non con il nome
    datato.

  I documenti di una serie di PR (progetto, specifiche, collaudo) vanno in `docs/PR/PRxx-yy_tema/`.
  Fanno eccezione `docs/modifiche/` (regola sotto; i file non si modificano dopo l'unione),
  `docs/reference/` e `docs/README.md`. Il job «Documenti» della CI controlla nomi, riferimenti e
  indice (`node .github/scripts/check_docs.mjs`).
- **Guida passo passo:** il titolare segue la guida **una parte alla volta**. Prima di dare i passi,
  verificare che la guida corrisponda al codice; dare istruzioni precise (cosa cliccare/incollare) e
  aspettare la conferma. Se la guida o il codice hanno errori, correggerli (branch, test, CI,
  registro, PR) e aggiornare la guida con quello che emerge dalle prove reali.
- **Costi:** obiettivo costo zero. Prima di proporre qualcosa che costa o richiede una carta, dirlo
  chiaramente e chiedere.
- **Stato:** a fine parte aggiornare `docs/configurazione/2026-10-17_HAPOSTO_STATO_CONFIGURAZIONE.md` nella stessa PR.

## Comandi utili

- App: `./gradlew testDemoDebugUnitTest`, `./gradlew assembleDebug`, `./gradlew lintDemoDebug`,
  `./gradlew connectedDemoDebugAndroidTest`.
- Edge Function (da `supabase/functions`): `deno check */index.ts`, `deno lint`, `deno test --allow-env`.
- Sito: `node web/build.mjs`, `node --test web/tests/*.test.mjs`.
- Documenti: `node .github/scripts/check_docs.mjs` (nomi, riferimenti e indice di `docs/`).
- SQL: vedi il job "Supabase SQL" in `.github/workflows/android-ci.yml` (ordine delle migration,
  seed, controlli).
