# 2026-10-02 — Dettatura dei dettagli e prenotazioni di sala veloci

- **Data:** 2 ottobre 2026
- **Branch:** `claude/amazing-pasteur-dull9l`
- **PR:** [#18](https://github.com/paolomarchionetti-glitch/haposto/pull/18)
- **Motivo:** richiesta del titolare: il ristoratore deve fare il meno possibile. In "Dettagli
  facoltativi" la nota si deve poter dettare; nelle prenotazioni di sala si poteva dettare solo il
  nome e l'orario andava scritto per intero ("20:30", con i due punti). Serve una compilazione
  intelligente a voce, ma sempre correggibile a mano; poche opzioni, semplici e immediate.

## File modificati, aggiunti e rinominati

| File | Tipo |
|---|---|
| `app/src/main/java/com/haposto/domain/voice/ItalianNumbers.kt` | aggiunto |
| `app/src/main/java/com/haposto/domain/voice/DictationText.kt` | aggiunto |
| `app/src/main/java/com/haposto/domain/voice/DetailsDictation.kt` | aggiunto |
| `app/src/main/java/com/haposto/domain/voice/ReservationDictation.kt` | aggiunto |
| `app/src/main/java/com/haposto/domain/reservations/ReservationTimes.kt` | aggiunto |
| `app/src/main/java/com/haposto/data/reservations/Reservation.kt` | modificato |
| `app/src/main/java/com/haposto/data/restaurant/RecentNotes.kt` | aggiunto |
| `app/src/main/java/com/haposto/data/restaurant/SharedPrefsRecentNotesStore.kt` | aggiunto |
| `app/src/main/java/com/haposto/ui/components/SpeechInput.kt` | aggiunto |
| `app/src/main/java/com/haposto/ui/screens/restaurant/RestaurantManagerViewModel.kt` | modificato |
| `app/src/main/java/com/haposto/ui/screens/restaurant/RestaurantManagerUiState.kt` | modificato |
| `app/src/main/java/com/haposto/ui/screens/restaurant/RestaurantManagerScreen.kt` | modificato |
| `app/src/main/java/com/haposto/ui/screens/restaurant/RestaurantManagerRoute.kt` | modificato |
| `app/src/main/java/com/haposto/ui/screens/reservations/ReservationsScreen.kt` | modificato |
| `app/src/main/java/com/haposto/ui/screens/reservations/ReservationsViewModel.kt` | modificato |
| `app/src/main/java/com/haposto/ui/screens/reservations/ReservationsRoute.kt` | modificato |
| `app/src/main/java/com/haposto/ui/HaPostoApp.kt` | modificato |
| `app/src/test/java/com/haposto/domain/voice/DetailsDictationTest.kt` | aggiunto |
| `app/src/test/java/com/haposto/domain/voice/ReservationDictationTest.kt` | aggiunto |
| `app/src/test/java/com/haposto/domain/reservations/ReservationTimesTest.kt` | aggiunto |
| `app/src/test/java/com/haposto/data/reservations/ReservationListTest.kt` | aggiunto |
| `app/src/test/java/com/haposto/data/restaurant/RecentNotesTest.kt` | aggiunto |
| `app/src/test/java/com/haposto/ui/screens/restaurant/RestaurantManagerViewModelTest.kt` | modificato |
| `docs/HAPOSTO_GUIDA_APP_TUTORIAL.md` | modificato |
| `docs/modifiche/2026-10-02_pr18-dettatura-e-prenotazioni-veloci.md` | aggiunto (questo file) |

## Dettaglio delle modifiche

- **Interpretazione delle frasi dettate** (`domain/voice`, Kotlin puro, tutto sul telefono, nessun
  servizio esterno né costo): numeri in cifre o in lettere ("quattro", "ventotto", "ventitré");
  un testo da cui si tolgono i pezzi riconosciuti e quello che resta diventa nota o nome.
  - *Dettagli*: «tre tavoli, dieci minuti, solo tavoli fuori» → tavoli 3, attesa 10, nota "Solo
    tavoli fuori"; «nessuna attesa», «mezz'ora», «nota: …»; l'attesa diventa uno dei tasti
    dell'app (0, 10, 20, 30); compila solo i campi nominati.
  - *Prenotazioni*: «Rossi, quattro, alle venti e trenta, tavolo dodici» → nome, persone, orario,
    tavolo; anche «domani», «sabato», «stasera», «a pranzo», «alle otto e mezza», «alle nove meno un
    quarto», «tavolo da 6» (= persone), «4 adulti e 2 bambini» (= 6), «a nome di …». «Alle 8» è
    20:00 se il locale a quell'ora è aperto la sera (orari del locale; senza orari: 1–10 = sera).
- **Orari delle prenotazioni** (`ReservationTimes`): cifre digitate con i due punti automatici
  (2030 → 20:30, 930 → 9:30), orario completo al salvataggio (20 → 20:00), orari proposti a un tocco
  ogni 30 minuti dentro gli orari di apertura del giorno (fino a mezz'ora prima della chiusura;
  senza orari: 12:00–14:30 e 19:00–23:00; oggi si parte da adesso).
- **Prenotazioni con il giorno**: campo `date` (le prenotazioni salvate prima valgono per il giorno
  in cui l'app le ritrova); giorni passati cancellati all'apertura (restano solo sul telefono e solo
  il necessario); lista per giorno con il totale delle persone.
- **Schermata prenotazioni**: giorno Oggi / Domani / 📅 Altro giorno; un solo tasto **🎙 Detta la
  prenotazione** al posto della dettatura del solo nome; orari a un tocco; campo orario con tastiera
  numerica e due punti automatici; il resto invariato.
- **Dashboard, Dettagli facoltativi**: un solo tasto **🎙 Detta i dettagli** che compila tavoli,
  attesa e nota (non pubblica: il ristoratore controlla e sceglie lo stato); sotto la nota le
  **ultime 5 note** pubblicate da quel telefono per quel locale, riusabili con un tocco (salvate
  nelle preferenze dell'app).
- **Componente comune** `rememberSpeechInput`: riconoscimento vocale di sistema in italiano, senza
  permesso del microfono per l'app; messaggio chiaro se sul telefono manca.
- **Tutorial dell'app**: punti 4.4 e 4.6 aggiornati.

## Verifiche

- Logica compilata e provata in locale con Kotlin 2.4.10 (progetto JVM di prova con gli stessi
  file): **43 test verdi**, compresi i test già esistenti su orari di apertura e prenotazioni.
- Nuovi test del ViewModel della dashboard (dettatura, ultime note dopo una pubblicazione) e la
  compilazione delle schermate Compose: in CI (in questo ambiente l'SDK Android non si scarica).
- Test strumentali esistenti non toccati: i nuovi parametri delle schermate hanno valori predefiniti;
  il campo `date` delle prenotazioni è facoltativo (i file salvati prima si leggono ancora).
