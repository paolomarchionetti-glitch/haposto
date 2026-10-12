# 2026-10-11 — Tessera fedeltà, PR C: app del cliente

- **Data:** 11 ottobre 2026
- **Branch:** `claude/amazing-pasteur-dull9l`
- **PR:** [#28](https://github.com/paolomarchionetti-glitch/haposto/pull/28)
- **Motivo:** terzo dei cinque passi della tessera fedeltà nascosta (specifiche v3, regole
  T1–T61). Dopo il database (PR A, #26) e il lato ristoratore (PR B, #27), il lato cliente: QR
  personale, tavolo di gruppo, «Le mie tessere», segnalazioni e schermata della privacy. Lo vedono
  solo i clienti tester con la modalità `TEST`, perché decide il server (`loyalty_access`,
  `loyalty_restaurant_card`). Con la modalità `OFF` non cambia nulla.

## File modificati, aggiunti, rinominati ed eliminati

| File | Tipo |
|---|---|
| `app/src/main/java/com/haposto/data/loyalty/CustomerLoyaltyRepository.kt` | aggiunto |
| `app/src/main/java/com/haposto/data/remote/supabase/SupabaseCustomerLoyaltyRepository.kt` | aggiunto |
| `app/src/main/java/com/haposto/ui/screens/loyalty/LoyaltyCustomerComponents.kt` | aggiunto |
| `app/src/main/java/com/haposto/ui/screens/loyalty/LoyaltyRestaurantBox.kt` | aggiunto |
| `app/src/main/java/com/haposto/ui/screens/loyalty/LoyaltyQrRoute.kt` | aggiunto |
| `app/src/main/java/com/haposto/ui/screens/loyalty/LoyaltyGroupRoute.kt` | aggiunto |
| `app/src/main/java/com/haposto/ui/screens/loyalty/LoyaltyJoinRoute.kt` | aggiunto |
| `app/src/main/java/com/haposto/ui/screens/loyalty/LoyaltyCardsRoute.kt` | aggiunto |
| `app/src/main/java/com/haposto/data/loyalty/LoyaltyModels.kt` | modificato |
| `app/src/main/java/com/haposto/data/loyalty/LoyaltyTexts.kt` | modificato |
| `app/src/main/java/com/haposto/data/remote/supabase/SupabaseLoyaltyRepository.kt` | modificato |
| `app/src/main/java/com/haposto/data/Outcome.kt` | modificato |
| `app/src/main/java/com/haposto/AppDependencies.kt` | modificato |
| `app/src/main/java/com/haposto/ui/HaPostoApp.kt` | modificato |
| `app/src/main/java/com/haposto/ui/navigation/AppDestination.kt` | modificato |
| `app/src/main/java/com/haposto/ui/screens/account/AccountRoute.kt` | modificato |
| `app/src/main/java/com/haposto/ui/screens/detail/RestaurantDetailRoute.kt` | modificato |
| `app/src/main/java/com/haposto/ui/screens/detail/RestaurantDetailScreen.kt` | modificato |
| `app/src/main/java/com/haposto/ui/screens/loyalty/LoyaltyComponents.kt` | modificato |
| `app/src/test/java/com/haposto/data/remote/supabase/CustomerLoyaltyDecodingTest.kt` | aggiunto |
| `app/src/test/java/com/haposto/data/loyalty/LoyaltyTextsTest.kt` | modificato |
| `app/src/androidTest/java/com/haposto/ui/screens/loyalty/LoyaltyCustomerScreensTest.kt` | aggiunto |
| `README.md` | modificato |
| `docs/HAPOSTO_TESSERA_SPECIFICHE.md` | modificato |
| `docs/HAPOSTO_GUIDA_CONFIGURAZIONE_COMPLETA.md` | modificato |
| `docs/HAPOSTO_STATO_CONFIGURAZIONE.md` | modificato |
| `docs/modifiche/2026-10-11_pr28-tessera-app-cliente.md` | aggiunto (questo file) |

Nessun file rinominato o eliminato. Nessuna migration nuova, nessuna dipendenza nuova.

## Dettaglio delle modifiche

### Dati (logica pura, senza Android)

- **Modelli del cliente**: cosa mostrare (`LoyaltyAccess`), riquadro del locale, la propria
  tessera con la data dell'azzeramento, QR da 60 secondi, esito del proprio QR, tavolo di gruppo
  (creato, a cui ci si è uniti, stato ed esito per ogni membro), voci di «Le mie tessere», i due
  tipi di segnalazione.
- **Repository** `CustomerLoyaltyRepository` e implementazione Supabase con le 12 funzioni del
  cliente della 0018 (`loyalty_access`, `loyalty_restaurant_card`, `create_visit_token`,
  `visit_token_status`, `create_loyalty_group`, `loyalty_group_token`, `join_loyalty_group`,
  `leave_loyalty_group`, `loyalty_group_status`, `my_loyalty_cards`, `leave_loyalty_card`,
  `report_loyalty_problem`). Le classi di lettura del JSON hanno il prefisso `Customer` (nomi unici
  nel pacchetto, vedi PR B); quelle della PR B diventano `internal` per riusare regole e premi.
  Nella versione DEMO non esiste.
- **Testi in italiano**:
  - riepilogo «10 timbri → 20% sulla tua consumazione, max 10 €», avanzamento «4 su 10», codice di
    riserva leggibile a voce («BQM C6P»);
  - esito sul telefono del cliente (§6.1): «✓ +1 timbro · 4 su 10», «✓ +2 timbri, giorno doppio»,
    «🎁 Premio sbloccato», «Hai già avuto un timbro qui nelle ultime 4 ore…», e per il tavolo anche
    «Lo staff ha annullato la scansione del tavolo»;
  - stato della tessera del locale (in chiusura fino al…, finita), data dell'azzeramento (T24),
    premi da usare con validità e giorni (si usa oggi / dalla prossima visita / solo lunedì…);
  - i due tasti delle segnalazioni (T48) e la schermata della privacy (T59: cosa vede il locale,
    cosa conserva HAPOSTO e per quanto).
- **Messaggi d'errore** nuovi: QR del tavolo non valido o scaduto, tavolo al completo, chiuso o non
  trovato, segnalazione non consentita o troppo ravvicinata.

### Schermate (solo DEV/PROD, solo se il server rende visibile la tessera)

- **Scheda del locale** → riquadro **🎫 Tessera fedeltà** sotto gli orari: riepilogo, timbri
  (●●●●○○○○○○), premi, regole della propria versione (T27), il proprio codice anonimo, tasti
  **Mostra il mio QR**, **👥 Siamo in gruppo**, **Unisciti a un tavolo**, **Segnala un problema**
  (due tasti con conferma) e **Lascia questa tessera** (con conferma). Senza account i tasti portano
  ad Account (T61). Si ricarica a ogni ritorno sulla scheda.
- **Il mio QR**:
  - schermata con screenshot bloccati (`FLAG_SECURE`) e luminosità al massimo, ripristinati
    all'uscita;
  - QR con cornice animata e orologio che scorre (una foto statica si riconosce), codice di
    riserva, barra del conto alla rovescia;
  - nuovo QR 2 secondi prima della scadenza; il QR appena sostituito resta controllato finché
    scade; l'esito arriva entro un secondo dalla scansione (controllo ogni secondo, solo con la
    schermata aperta);
  - dopo circa 10 minuti senza scansione il QR va in pausa («Mostra di nuovo il QR»);
  - il QR si genera alla dimensione minima e si ingrandisce senza sfocare: compare subito (§6.1).
- **Siamo in gruppo** (capogruppo): QR del tavolo che si rinnova, «Tavolo: N persone ✓», istruzioni
  per gli altri con l'orario entro cui unirsi, **Chiudi il tavolo**; dopo la scansione il proprio
  timbro. Se il tavolo viene scansionato proprio mentre il QR si rinnova, l'app lo riconosce e
  mostra l'esito invece di «scaduto».
- **Unisciti a un tavolo**: lo scanner di Google si apre subito; accetta solo il QR del tavolo
  HAPOSTO; poi «✓ Sei nel tavolo · N persone» e, dopo la scansione alla cassa, il proprio timbro;
  **Esci dal tavolo**.
- **Account → Tessere fedeltà → Le mie tessere** (solo se `loyalty_access` risponde
  `visible: true`): per ogni locale timbri, data dell'azzeramento, premi, regole, codice, QR,
  segnalazioni e «Lascia questa tessera»; in alto **Unisciti a un tavolo**.
- **Privacy al primo uso** (T59) prima del primo QR, tavolo o ingresso in un tavolo: si accetta una
  volta per telefono.

### Documenti

- Specifiche: PR C realizzata, come è stata realizzata (§15.2).
- Guida, Parte 11: come provare il lato cliente sul DEV in modalità test (QR, codice, gruppo,
  Le mie tessere).
- Stato: PR C fatta, prova facoltativa sul DEV, prossima PR D. README: tessera nascosta nella riga
  dell'app.

## Costi

Nessuno: solo app, nessun servizio nuovo. Il controllo dell'esito (una chiamata al secondo con il
QR aperto, al massimo una decina di minuti) resta ampiamente nei limiti di Supabase Free.

## Verifiche

- JSON di prova presi dal database locale con la 0018 (Postgres 16) chiamando le funzioni del
  cliente: accesso, riquadro (anonimo, prima tessera, con tessera), QR e suo stato (in attesa,
  usato con l'esito), tavolo creato, ingresso nel tavolo, stato del tavolo (aperto, usato con
  l'esito), «Le mie tessere».
- Test JVM, eseguiti sulla JVM con supabase-kt 3.7.0 (in questo ambiente manca l'SDK Android):
  `CustomerLoyaltyDecodingTest` (5, nuovo), `LoyaltyTextsTest` (18, di cui 6 nuovi),
  `LoyaltyDecodingTest` (7), `LoyaltyDraftTest` (7), `AdminDetailDecodingTest` (4):
  **41 test su 41 passano**. Compila senza errori anche il repository Supabase del cliente.
- Controllato che nel pacchetto `data.remote.supabase` e in `ui.screens.loyalty` non ci siano due
  classi con lo stesso nome (l'errore della prima CI della PR B).
- Test su emulatore aggiunti (`LoyaltyCustomerScreensTest`): QR con codice di riserva e «Siamo in
  gruppo»; esito «✓ +1 timbro · 4 su 10»; senza account «Mostra il mio QR» porta all'accesso;
  avanzamento della tessera e segnalazione inviata solo dopo la conferma; privacy al primo uso.
- Le schermate Compose (Google Maven non raggiungibile da questo ambiente) le compila la CI: build
  delle tre varianti, lint, test JVM, test su emulatore.
