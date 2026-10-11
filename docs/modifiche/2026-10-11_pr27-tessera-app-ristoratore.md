# 2026-10-11 — Tessera fedeltà, PR B: app del ristoratore

- **Data:** 11 ottobre 2026
- **Branch:** `claude/amazing-pasteur-dull9l`
- **PR:** [#27](https://github.com/paolomarchionetti-glitch/haposto/pull/27)
- **Motivo:** secondo dei cinque passi della tessera fedeltà nascosta (specifiche v3, regole
  T1–T61). Dopo il database (PR A, #26), il lato ristoratore dell'app: attivazione con il patto,
  regole, «Timbra», premi e statistiche. Lo vedono solo i locali tester con la modalità `TEST`,
  perché decide il server (`restaurant_loyalty_program`). Con la modalità `OFF` non cambia nulla.

## File modificati, aggiunti, rinominati ed eliminati

| File | Tipo |
|---|---|
| `app/src/main/java/com/haposto/data/loyalty/LoyaltyModels.kt` | aggiunto |
| `app/src/main/java/com/haposto/data/loyalty/LoyaltyTexts.kt` | aggiunto |
| `app/src/main/java/com/haposto/data/loyalty/LoyaltyDraft.kt` | aggiunto |
| `app/src/main/java/com/haposto/data/loyalty/RestaurantLoyaltyRepository.kt` | aggiunto |
| `app/src/main/java/com/haposto/data/remote/supabase/SupabaseLoyaltyRepository.kt` | aggiunto |
| `app/src/main/java/com/haposto/platform/qr/QrScanner.kt` | aggiunto |
| `app/src/main/java/com/haposto/ui/screens/loyalty/LoyaltyComponents.kt` | aggiunto |
| `app/src/main/java/com/haposto/ui/screens/loyalty/LoyaltyManageRoute.kt` | aggiunto |
| `app/src/main/java/com/haposto/ui/screens/loyalty/LoyaltyWizard.kt` | aggiunto |
| `app/src/main/java/com/haposto/ui/screens/loyalty/LoyaltyStampRoute.kt` | aggiunto |
| `app/src/main/java/com/haposto/AppDependencies.kt` | modificato |
| `app/src/main/java/com/haposto/data/Outcome.kt` | modificato |
| `app/src/main/java/com/haposto/ui/HaPostoApp.kt` | modificato |
| `app/src/main/java/com/haposto/ui/navigation/AppDestination.kt` | modificato |
| `app/src/main/java/com/haposto/ui/screens/restaurant/RestaurantManagerRoute.kt` | modificato |
| `app/src/main/java/com/haposto/ui/screens/restaurant/RestaurantManagerScreen.kt` | modificato |
| `app/src/main/java/com/haposto/ui/screens/settings/RestaurantSettingsRoute.kt` | modificato |
| `app/build.gradle.kts` | modificato |
| `gradle/libs.versions.toml` | modificato |
| `app/src/test/java/com/haposto/data/loyalty/LoyaltyTextsTest.kt` | aggiunto |
| `app/src/test/java/com/haposto/data/loyalty/LoyaltyDraftTest.kt` | aggiunto |
| `app/src/test/java/com/haposto/data/remote/supabase/LoyaltyDecodingTest.kt` | aggiunto |
| `app/src/androidTest/java/com/haposto/ui/screens/loyalty/LoyaltyWizardScreenTest.kt` | aggiunto |
| `app/src/androidTest/java/com/haposto/ui/screens/restaurant/RestaurantManagerScreenTest.kt` | modificato |
| `docs/HAPOSTO_TESSERA_SPECIFICHE.md` | modificato |
| `docs/HAPOSTO_GUIDA_CONFIGURAZIONE_COMPLETA.md` | modificato |
| `docs/HAPOSTO_STATO_CONFIGURAZIONE.md` | modificato |
| `docs/modifiche/2026-10-11_pr27-tessera-app-ristoratore.md` | aggiunto (questo file) |

Nessun file rinominato o eliminato. Nessuna migration nuova.

## Dettaglio delle modifiche

### Dati (logica pura, senza Android)

- **Modelli** della tessera: regole di una versione, limiti, programma del locale, esito di una
  scansione per persona (solo codice anonimo), premi, statistiche, tessere. `canScan` decide il
  tasto «Timbra» (T34): tessera attiva, in preavviso o con premi ancora da consegnare.
- **Testi in italiano**:
  - condizione («Spesa minima di 15 € a persona», «Almeno una consumazione tra: …»);
  - giorno doppio e premio («20% sulla sua consumazione, max 10 €», «5 € di sconto alla visita
    dopo, con una spesa di almeno 15 €»);
  - regole di utilizzo, patto in tre righe (T16);
  - esiti («+1 timbro · 4 su 10», «già timbrato nelle ultime 4 ore»), riepilogo del tavolo
    («Tavolo di 4 · 3 timbrati (1 gestisce il locale)»);
  - errori di scansione e conto alla rovescia dell'annullamento.
- **Procedura guidata** (`LoyaltyDraft`): le scelte in euro interi, i controlli con i limiti del
  server (timbri 5–20, spesa 5–50 €, sconto 5–50% con tetto 5–50 €, buono 2–20 € con spesa almeno
  doppia e solo dalla visita dopo, giorni ≥ 3, premi per tavolo 1–10 o senza limite) e il JSON
  esatto che si aspetta `publish_loyalty_version`. «Cambia le regole» riparte dalla versione attiva.
- **QR della tessera**: `haposto:tessera:` + codice casuale di 32 caratteri; lo staff accetta solo
  questi (un QR qualsiasi, per esempio quello del menù, viene rifiutato con un messaggio chiaro).
- **Repository** `RestaurantLoyaltyRepository` e implementazione Supabase (programma, pubblicazione,
  chiusura, timbro da QR o da codice, annullamento, premio, statistiche, tessere). Nella versione
  DEMO non esiste. Su un database senza la 0018 le chiamate falliscono e la tessera resta nascosta.

### Schermate (solo DEV/PROD, solo se il server rende visibile la tessera)

- **Gestisci il locale** → riquadro **Tessera fedeltà** con lo stato → scheda della tessera:
  - stato (attiva, in chiusura, sospesa, tolta, finita), tessere attive e premi da consegnare;
  - le regole della versione attiva e la data del patto;
  - segnalazioni (T53), statistiche a 7/30/90 giorni (§11), tessere con il codice anonimo;
  - per il titolare: **Attiva la tessera** / **Cambia le regole** (nuova versione, vale solo per
    chi inizia da oggi) e **Chiudi la tessera** con la conferma dei 30 giorni di preavviso.
- **Procedura guidata** in sei passi:
  1. timbri;
  2. condizione;
  3. giorno doppio;
  4. premio (omaggio dalla lista di 16, sconto personale, buono);
  5. come si usa il premio;
  6. riepilogo e patto con «Accetto».

  I numeri si scelgono con «−» e «+»; a ogni passo c'è l'anteprima del testo per i clienti.
- **Dashboard**: tasto secondario **📷 Timbra la tessera fedeltà** sotto «Gestisci il locale»,
  solo con la tessera attiva (T34).
- **Timbra**:
  - lo scanner di Google si apre subito, senza permesso della fotocamera per l'app;
  - esito del singolo («✓ Cliente K4F7 · +1 timbro · 4 su 10» con la condizione) o del tavolo
    (numero di persone ed esclusi, T30);
  - premi da consegnare con le loro regole e i tasti «Consegnato» / «Applicato» (con lo sconto
    fatto, facoltativo);
  - **Annulla** con il conto alla rovescia dei 2 minuti, **Inserisci codice** per i 6 caratteri di
    riserva, «Timbra il prossimo».
- Messaggi in italiano per tutti i codici d'errore della tessera.
- Dipendenza nuova: `com.google.android.gms:play-services-code-scanner:16.1.0` (gratuita).

### Documenti

- Specifiche: PR B realizzata; contenuto dei QR (§15.2).
- Guida, Parte 11: come provare il lato ristoratore sul DEV in modalità test.
- Stato: PR B fatta, prova facoltativa sul DEV, prossima PR C.

## Costi

Nessuno: lo scanner di Google Play services è gratuito; nessun servizio nuovo.

## Verifiche

- JSON di prova presi dal database locale con la 0018 (Postgres 16): programma attivo e non
  attivato, timbro singolo e di gruppo (con premio e persona esclusa), codice sbagliato, QR già
  usato, statistiche, tessere. Generandoli si è visto anche il rifiuto `REWARD_NOT_TODAY` per un
  premio valido in altri giorni.
- Test JVM, eseguiti sulla JVM con supabase-kt 3.7.0 (in questo ambiente manca l'SDK Android):
  `LoyaltyTextsTest` (12), `LoyaltyDraftTest` (7), `LoyaltyDecodingTest` (7), più
  `AdminDetailDecodingTest` (4) della PR A: **30 test su 30 passano**. Compilano senza errori
  modelli, testi, procedura guidata e repository Supabase.
- Test su emulatore aggiunti: il tasto «Timbra» c'è solo quando il server lo consente; la tessera
  si attiva solo dopo «Accetto».
- Le schermate Compose e lo scanner (Google Maven non raggiungibile da questo ambiente) li
  compila la CI: build delle tre varianti, lint, test JVM, test su emulatore.
- Prima esecuzione della CI fallita: una classe privata `MemberDto` aveva lo stesso nome di una già
  presente nello stesso pacchetto (`SupabaseManagementRepository.kt`), e su Kotlin/JVM non si può.
  L'errore è stato riprodotto in locale con un file che simula il conflitto. Corretto dando a tutte
  le classi interne del repository della tessera il prefisso `Loyalty`; dopo la correzione la
  compilazione passa e i 30 test sono ancora verdi.
