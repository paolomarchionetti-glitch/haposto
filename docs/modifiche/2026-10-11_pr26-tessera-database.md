# 2026-10-11 — Tessera fedeltà, PR A: database, controlli e interruttore spento

- **Data:** 11 ottobre 2026
- **Branch:** `claude/amazing-pasteur-dull9l`
- **PR:** [#26](https://github.com/paolomarchionetti-glitch/haposto/pull/26)
- **Motivo:** primo dei cinque passi della tessera fedeltà decisa dal titolare come **funzione
  nascosta** (specifiche v3, `docs/HAPOSTO_TESSERA_SPECIFICHE.md`, regole T1–T61). Questa PR
  prepara tutto il lato server, con l'interruttore **spento**, e i «Tester tessera» nel pannello
  admin. Nell'app non si vede nulla: le schermate arrivano con le PR B (ristoratore) e C (cliente).

## File modificati, aggiunti, rinominati ed eliminati

| File | Tipo |
|---|---|
| `supabase/migrations/0018_loyalty_card.sql` | aggiunto |
| `supabase/tests/step22_loyalty_checks.sql` | aggiunto |
| `.github/workflows/android-ci.yml` | modificato |
| `supabase/ops/scheduled_jobs.sql` | modificato |
| `app/src/main/java/com/haposto/data/Outcome.kt` | modificato |
| `app/src/main/java/com/haposto/data/admin/AdminModels.kt` | modificato |
| `app/src/main/java/com/haposto/data/admin/AdminRepository.kt` | modificato |
| `app/src/main/java/com/haposto/data/remote/supabase/SupabaseAdminRepository.kt` | modificato |
| `app/src/main/java/com/haposto/ui/screens/admin/AdminDetailRoutes.kt` | modificato |
| `app/src/main/java/com/haposto/ui/screens/admin/AdminRoute.kt` | modificato |
| `app/src/test/java/com/haposto/data/remote/supabase/AdminDetailDecodingTest.kt` | aggiunto |
| `docs/HAPOSTO_TESSERA_SPECIFICHE.md` | modificato |
| `docs/HAPOSTO_GUIDA_CONFIGURAZIONE_COMPLETA.md` | modificato |
| `docs/HAPOSTO_STATO_CONFIGURAZIONE.md` | modificato |
| `README.md` | modificato |
| `docs/modifiche/2026-10-11_pr26-tessera-database.md` | aggiunto (questo file) |

Nessun file rinominato o eliminato.

## Dettaglio delle modifiche

### Migration `0018_loyalty_card.sql` (rieseguibile)

- **Interruttore** (T7–T10): impostazione `loyalty` in `app_config`, con `"mode": "OFF"`. Le
  modalità sono `OFF`, `TEST` (solo tester; gli admin sempre), `ON`, `EXISTING_ONLY` (solo le
  tessere iniziate). `admin_set_config` controlla ogni campo (solo campi noti, numeri interi entro
  i limiti, minimi non oltre i massimi). «Lanciata» lo decide il server: dopo il primo `ON` si
  passa solo fra `ON` ed `EXISTING_ONLY` (`LOYALTY_ALREADY_LAUNCHED`). Gli altri numeri sono i
  valori confermati (§18) e restano modificabili dall'admin.
- **Tester**: colonna `profiles.loyalty_tester` (non modificabile dall'app) e `tester` sul
  programma del locale; funzioni `admin_set_restaurant_loyalty_tester` e
  `admin_set_user_loyalty_tester`, con il registro operazioni.
- **Piano**: funzione `LOYALTY` aggiunta a Pro e Pro+ (in beta e in prova ce l'hanno tutti).
- **Consenso**: tipo `LOYALTY_PACT` in `consent_log` (T17).
- **Statistiche**: nove contatori anonimi nuovi in `restaurant_daily_stats` (scansioni, tavoli,
  persone, timbri, clienti nuovi, tessere iniziate, premi sbloccati e usati, sconti riconosciuti),
  che restano dopo la pulizia dei dati (T58).
- **Tabelle** (tutte senza accesso diretto dalle app, con i permessi espliciti per il server come
  vuole la regola della 0014): versioni **immutabili** (un trigger blocca modifiche e
  cancellazioni dirette, T18), programmi, codici anonimi, tessere (una attiva per locale),
  tavoli e loro membri, QR (solo impronte SHA-256), scansioni, esiti per persona, premi,
  segnalazioni, codici sbagliati. Rispetto all'elenco delle specifiche ci sono tre tabelle di
  servizio in più (`loyalty_group_members`, `loyalty_scans`, `loyalty_code_failures`) e i premi
  leggono le regole dalla versione immutabile invece di copiarle: le specifiche (§15) sono state
  aggiornate.
- **Funzioni per il cliente**: cosa mostrare, riquadro nella scheda del locale (anche senza
  account, solo con la tessera attiva per tutti), QR personale da 60 secondi con codice di riserva,
  esito del QR, tavolo di gruppo (crea, rinnova il QR, unisciti, esci, stato), «Le mie tessere»,
  lascia la tessera, segnalazione.
- **Funzioni per il locale**: scheda «Tessera fedeltà» (limiti, versioni, segnalazioni senza
  sapere chi), pubblicazione di una versione con il patto (tutti i limiti di T11–T15 e T40–T46),
  chiusura con preavviso, timbro (QR personale, QR del tavolo o codice), annullamento entro 2
  minuti, consegna del premio, statistiche ed elenco delle tessere con il solo codice anonimo.
- **Antifrode** (§7): QR monouso da 60 secondi legato al locale, 10 codici sbagliati in 10 minuti
  bloccano l'inserimento per 10 minuti (gli errori rispondono senza eccezione, così il conteggio
  resta salvato), un timbro ogni 4 ore, niente tessera per chi gestisce il locale (anche nei
  gruppi), tetti di 60 scansioni ogni 10 minuti e 300 al giorno, al massimo 40 QR ogni 10 minuti
  per cliente. In più, scelta di realizzazione a tutela del patto (T4): un premio si consegna solo
  a chi è stato scansionato in quel locale negli ultimi 30 minuti, così il locale non può segnare
  premi «usati» a distanza.
- **Gruppo** (T28–T31): fino a 20 persone, ci si unisce entro 10 minuti, la scansione vale entro
  60 minuti dalla creazione, un gruppo aperto alla volta; ognuno riceve il suo timbro con le sue
  regole e chi non può viene escluso da solo.
- **Sanzioni automatiche** (T48–T53), valutate a ogni segnalazione: avviso a 3 clienti diversi in
  60 giorni, sospensione di 90 giorni a 5 (tessere e premi dei clienti chiusi, con un avviso),
  tessera tolta alla seconda sospensione in 12 mesi; l'admin può ridarla
  (`admin_loyalty_restore`). Il locale resta sempre su HAPOSTO.
- **Lavoro pianificato** `loyalty_maintenance()`: uscita da HAPOSTO (fine subito, T22), Pro non
  pagato (preavviso di 30 giorni; se Pro torna durante il preavviso la tessera riparte, T21), fine
  del preavviso (T20; i premi restano validi fino alla scadenza e si consegnano ancora), fine della
  sospensione, avviso 15 giorni prima dell'azzeramento se mancano 1–3 timbri e azzeramento dopo 6
  mesi (T24), scadenza dei premi (T47), pulizia (T58). A interruttore spento fa solo scadenze e
  pulizia.
- **Pannello**: `admin_loyalty_overview` (numeri per la futura scheda «Tessere», PR D) e la
  tessera nella scheda del locale.
- **Correzione**: `admin_restaurant_detail` calcola fonte e scadenza del piano senza passare da
  `restaurant_entitlements`, che dal SQL Editor (nessun utente collegato) rifiutava con «Not
  authorized for this restaurant» dalla migration 0017.

### Controlli e CI

- `supabase/tests/step22_loyalty_checks.sql`: **209 controlli**, uno o più per ogni regola
  verificabile dal database (interruttore, tester, patto e versioni, limiti dei premi, QR, codici,
  tetti, gruppo, giorno doppio, premio e riporto del timbro, annullamento, statistiche senza dati
  personali, segnalazioni e sanzioni, preavviso, Pro non pagato, uscita da HAPOSTO, azzeramento,
  scadenza, «solo esistenti», pannello, cancellazione dell'account, pulizia). Dentro la
  transazione l'orologio è fermo: il tempo «passa» spostando indietro le date salvate.
- CI: la 0018 nell'elenco delle migration e nella seconda esecuzione (`001[0-8]`); passo nuovo
  «Loyalty card checks (0018)»; `step22` anche sul progetto di produzione nuovo (senza permessi
  automatici).
- `supabase/ops/scheduled_jobs.sql`: lavoro `haposto-loyalty-maintenance` ogni giorno alle 07:40
  UTC.

### App (solo pannello admin)

- Scheda del locale: sezione **Tessera fedeltà (nascosta)** con lo stato della tessera e
  l'interruttore «Locale tester della tessera».
- Scheda dell'utente: sezione **Tessera fedeltà (nascosta)** con «Cliente tester della tessera».
- Le sezioni compaiono solo se il database ha già la 0018 (prima i campi mancano e restano nascoste).
- Messaggi in italiano per `LOYALTY_ALREADY_LAUNCHED` e `USER_NOT_FOUND`.
- Test JVM `AdminDetailDecodingTest`: le schede lette dal JSON vero delle funzioni SQL, con e senza
  la 0018.

### Documenti

- Specifiche (§15): tabelle, funzioni, codici d'errore e lavoro pianificato come realizzati.
- Guida: Parte 6.3 (il file dei lavori pianificati comprende la tessera), Parte 10.2 (migration
  0001–0018, `loyalty` fra le impostazioni attese), Parte 11 (modalità e tester della tessera).
- Stato: PR A fatta, passi da fare sul DEV, prossima PR B. README: database 0001–0018.

## Costi

Nessuno (Supabase Free; nessun servizio nuovo).

## Verifiche

- Problema di `admin_restaurant_detail` **riprodotto** su un database con le migration fino alla
  0017 (dal SQL Editor: `ERROR: Not authorized for this restaurant`) e **risolto** con la 0018
  (controllo in `step22`).
- Migration 0018 eseguita due volte di seguito senza errori.
- Job SQL della CI replicato in locale (Postgres 16 + PostGIS, passi letti dal workflow): tutte le
  migration due volte, seed, tutti i controlli (step8_to_17, step18–step22, ordine della guida,
  KPI, import OSM, strumenti DEV, pulizia DEV con le versioni immutabili), progetto di produzione
  nuovo con gli **stessi permessi** del DEV: **JOB SQL OK**.
- Kotlin: senza SDK Android in questo ambiente, lo strato dati del pannello
  (`Outcome.kt`, `data/admin/*`, `SupabaseAdminRepository.kt`) è stato compilato sulla JVM con
  supabase-kt 3.7.0 e `AdminDetailDecodingTest` passa (4 test su 4); l'etichetta dello stato della
  tessera compila senza avvisi. Build delle tre varianti, lint e test su emulatore: CI su GitHub.
