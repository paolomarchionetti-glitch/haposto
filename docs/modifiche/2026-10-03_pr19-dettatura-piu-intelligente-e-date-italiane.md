# 2026-10-03 — Dettatura più intelligente, date italiane, stato dopo il collaudo sul DEV

- **Data:** 3 ottobre 2026
- **Branch:** `claude/amazing-pasteur-dull9l`
- **PR:** [#19](https://github.com/paolomarchionetti-glitch/haposto/pull/19)
- **Motivo:** durante il collaudo sul DEV delle PR #16, #17 e #18, il titolare ha chiesto:
  - come dettare l'attesa "Non indicata" e "Nessuna";
  - di poter dettare qualsiasi orario nelle prenotazioni (es. 13.17);
  - una dettatura più intelligente;
  - un controllo sul fuso orario: il pannello di Supabase mostra gli orari 2 ore indietro.

  In più, rileggendo il codice per preparare le prove, è emerso che un'offerta dettata a voce
  saltava l'avviso di responsabilità della prima volta. A collaudo finito, lo stato va aggiornato.

## File modificati, aggiunti, rinominati ed eliminati

| File | Tipo |
|---|---|
| `app/src/main/java/com/haposto/domain/voice/DetailsDictation.kt` | modificato |
| `app/src/main/java/com/haposto/domain/voice/ReservationDictation.kt` | modificato |
| `app/src/main/java/com/haposto/ui/screens/restaurant/RestaurantManagerViewModel.kt` | modificato |
| `app/src/main/java/com/haposto/ui/screens/restaurant/RestaurantManagerScreen.kt` | modificato |
| `app/src/main/java/com/haposto/data/admin/AdminModels.kt` | modificato |
| `app/src/main/java/com/haposto/data/remote/supabase/SupabaseAdminRepository.kt` | modificato |
| `app/src/main/java/com/haposto/ui/screens/admin/AdminDetailRoutes.kt` | modificato |
| `app/src/main/java/com/haposto/ui/screens/admin/AdminRoute.kt` | modificato |
| `app/src/test/java/com/haposto/domain/voice/DetailsDictationTest.kt` | modificato |
| `app/src/test/java/com/haposto/domain/voice/ReservationDictationTest.kt` | modificato |
| `app/src/test/java/com/haposto/ui/screens/restaurant/RestaurantManagerViewModelTest.kt` | modificato |
| `supabase/migrations/0017_rome_dates_admin_plan.sql` | aggiunto |
| `supabase/tests/step21_rome_dates_checks.sql` | aggiunto |
| `.github/workflows/android-ci.yml` | modificato |
| `docs/HAPOSTO_GUIDA_APP_TUTORIAL.md` | modificato |
| `docs/HAPOSTO_GUIDA_CONFIGURAZIONE_COMPLETA.md` | modificato |
| `docs/HAPOSTO_STATO_CONFIGURAZIONE.md` | modificato |
| `README.md` | modificato |
| `docs/modifiche/2026-10-03_pr19-dettatura-piu-intelligente-e-date-italiane.md` | aggiunto (questo file) |

Nessun file rinominato o eliminato.

## Dettaglio delle modifiche

### Dettagli facoltativi a voce

- **Attesa "Nessuna" in ogni ordine**: prima «attesa nessuna» e «attesa zero» finivano nella nota.
  Ora diventano "Nessuna" come «nessuna attesa»; vale anche per «non c'è attesa» e «si entra subito».
- **Attesa "Non indicata"**: «attesa non indicata», «togli l'attesa», «attesa non la so».
- **Comandi per svuotare un campo**: «togli i tavoli», «nessuna nota», «togli l'offerta»,
  anche dentro una frase più lunga.
- **Stime e intervalli**:
  - «una ventina di minuti», «una decina di minuti», «mezz'oretta», «tre quarti d'ora»;
  - «10-15 minuti» e «tra dieci e quindici minuti» (si prende il più alto);
  - «un paio di tavoli», «tre o quattro tavoli» (si prende il più basso), «solo un tavolo»,
    «tavolini».
- Le parole di riempimento all'inizio della frase («allora», «ok», «ehm») non finiscono nella nota.
- L'interprete restituisce i nuovi flag `…Cleared`; il ViewModel li applica: tavoli e attesa "non
  indicati", nota e offerta vuote.
- **Offerta dettata**: passa dallo stesso avviso di responsabilità della prima volta. La frase
  viene applicata solo dopo **Ho capito**.

### Prenotazioni a voce

- **Qualsiasi orario**:
  - «alle 13.17», «alle tredici e diciassette» e «alle 13 e 17» funzionavano già (verificato con un
    test);
  - in più «alle 1317» e «ore 930» (cifre attaccate) e «alle 13 17» (separate da uno spazio, ma non
    «alle 8 10 persone»).
- **Date**:
  - «il 15» (questo mese, o il prossimo se il 15 è passato);
  - «15 ottobre» e «sabato 15 ottobre» (quest'anno, o il prossimo se la data è passata);
  - «sabato 3» è una data solo se quel sabato cade davvero il 3. Altrimenti, per esempio
    «domenica 3» quando la domenica è il 4, il 3 resta il numero di persone.
- **Persone**: «una coppia» = 2; «famiglia di 4», «gruppo di 6», «tavolata di 10».
- Dal nome si tolgono anche «dottor/dottoressa», «ingegner», «avvocato», «professor» (come già
  «signor/signora»).

### Fuso orario (migration 0017, rieseguibile)

- **Perché nessuno se ne accorgeva**: Supabase salva gli istanti in UTC e il suo pannello li mostra
  così. App, sito e pannello admin li mostrano già nell'ora del telefono, e statistiche,
  "di solito" e foto "solo per oggi" usavano già il giorno italiano.
- **I tre punti allineati** al giorno italiano, con la nuova funzione `today_rome()`:
  - pulizia delle prenotazioni di sala (30 giorni);
  - pulizia delle statistiche (2 anni);
  - somma degli ultimi 30 giorni nella scheda del locale del pannello admin.

  La differenza era al massimo di un paio d'ore a cavallo della mezzanotte.
- **Pannello admin, scheda del locale**:
  - il piano ora mostra la fonte (beta, prova, Stripe, regalato, Non collegato) e la scadenza;
  - nuova riga **Partner dal** (inizio della prova);
  - "Basic" si legge "Nessun piano".
- **Controlli**: `step21_rome_dates_checks.sql` (7 controlli), in CI anche sul "nuovo progetto di
  produzione".

### Documenti

- Tutorial: tabella delle frasi che la dettatura capisce (4.4) ed esempi nuovi per le prenotazioni
  (4.6).
- Guida: migration fino alla 0017 al punto 10.2.
- **Stato**:
  - collaudo sul DEV del 3 ottobre (PR #16, #17, #18) segnato come fatto;
  - Parte 6 aggiornata (7 funzioni, 9 lavori pianificati, ping attivo);
  - via le voci aperte ormai fatte; nuova miglioria n. 5;
  - due lezioni pratiche: orari in UTC nel pannello di Supabase, dove si trova *Run workflow*.
- README: migration 0001–0017, 245 controlli.

## Costi

Nessuno.

## Verifiche

Eseguite in locale prima dell'invio:

- **Job "Supabase SQL" della CI** completo, con la 0017, tutto verde:
  - migration 0001–0017 e loro riesecuzione;
  - controlli step8_to_17, step18, step19, step20 e **step21**;
  - nuovo progetto di produzione: stessi permessi del DEV, step21 compreso.
- **Kotlin** su JVM:
  - dominio: 69 test, compresi 6 nuovi sui Dettagli facoltativi e 4 sulle prenotazioni;
  - livello dati e ViewModel: 53 test, compreso il nuovo `dictation_canClearWaitAndNote`;
  - tutti i casi già esistenti restano verdi.
- **Schermate Compose** (dashboard, pannello admin) rilette: in locale non si compilano, lo fa la CI.
- CI su GitHub: vedi la PR.
