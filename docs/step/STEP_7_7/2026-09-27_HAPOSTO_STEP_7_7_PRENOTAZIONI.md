# HAPOSTO — STEP 7.7: correzioni build + Blocco prenotazioni di sala

## Parte A — Correzioni degli errori di compilazione

Erano errori **preesistenti** in codice mai compilato prima (non introdotti dal 7.5/7.6), più uno mio nella schermata prenotazioni. Tutti risolti.

1. **`SupabaseRestaurantRepository.kt` — `rpc(...)` e `decodeList` (righe ~123-125).**
   In questa versione di supabase-kt la `rpc` accetta i parametri come `JsonObject`, non come oggetto serializzabile. Ora costruisco il `JsonObject` con le chiavi esatte della funzione SQL (`lat`, `long`, `radius_meters`). L'errore su `decodeList` era a cascata da questa chiamata e sparisce di conseguenza.

2. **`RestaurantAccessScreen.kt:11` — import errato.**
   `import androidx.compose.foundation.layout.weight` non esiste come import (weight è un'estensione di scope). Rimosso: `Modifier.weight()` funziona dentro Row/Column senza import.

3. **`RestaurantManagerViewModel.kt:86, 91` — inferenza di tipo.**
   `savedStateHandle[KEY_INITIALIZED] == true` non permette di inferre il tipo. Reso esplicito: `savedStateHandle.get<Boolean>(KEY_INITIALIZED) == true`.

4. **`ReservationsScreen.kt` (mio) — campo scritto male + import.**
   Rimossa una riga `keyboardType` malformata e corretto l'import di `BorderStroke` (sta in `androidx.compose.foundation`, non `material3`).

> Il compilatore Kotlin riporta tutti gli errori di un passaggio, quindi questi 5 erano l'insieme completo. Dopo le correzioni la compilazione dovrebbe arrivare in fondo, includendo il nuovo modulo.

---

## Parte B — Blocco prenotazioni di sala (nuovo)

Esattamente come concordato: **interno al ristoratore, facoltativo, solo sul dispositivo, minimale, con dettatura vocale.**

### Cos'è
Un blocco note privato per le prenotazioni extra (telefono, walk-in, fuori da altri sistemi). Non è prenotazione lato cliente, non tocca i due loop core, non sostituisce TheFork.

### Come ci si arriva
Area ristoratore → card discreta **"📋 Prenotazioni di sala — Apri"** (in fondo, facoltativa). Chi non la usa non la nota.

### Cosa fa
Lista aggiornabile ordinata per orario. Ogni riga = **nome · orario · persone · tavolo (opz.)**. Aggiungi, tocca una riga per modificarla, "Rimuovi" per cancellarla. Niente stato/nota: minimale come richiesto.

### Voce
Tasto **"🎙 Detta"** accanto al campo Nome: usa il riconoscimento vocale di sistema in italiano (`RecognizerIntent`), nessun permesso microfono nell'app. Se il dispositivo non ha il riconoscimento, mostra un avviso e si scrive a mano. Il mic della tastiera resta comunque disponibile su tutti i campi.

### Dove finiscono i dati
**Solo su questo dispositivo**, in un file JSON interno all'app (uno per ristorante), tramite la serializzazione già presente nel progetto. Nessun dato personale dei clienti va in cloud. Nessuna dipendenza nuova, nessun Auth richiesto: funziona da subito. La sincronizzazione multi-dispositivo resta un'opzione futura (dopo lo Step 8).

### File nuovi
```
data/reservations/Reservation.kt            modello (@Serializable)
data/reservations/ReservationStore.kt       persistenza locale su file
ui/screens/reservations/ReservationsViewModel.kt   stato + CRUD (+ factory)
ui/screens/reservations/ReservationsScreen.kt      lista + form + dettatura
ui/screens/reservations/ReservationsRoute.kt       aggancio ViewModel/schermata
```

### File modificati (cablaggio)
```
ui/navigation/AppDestination.kt             rotta "reservations/{restaurantId}"
ui/HaPostoApp.kt                            composable rotta + onOpenReservations
ui/screens/restaurant/RestaurantManagerRoute.kt   passa onOpenReservations
ui/screens/restaurant/RestaurantManagerScreen.kt  card d'ingresso (param con default)
AndroidManifest.xml                         <queries> per il riconoscimento vocale
```

### Nota sui permessi
Il `<queries>` nel manifest serve solo, su Android 11+, a far **risolvere** l'app di riconoscimento vocale. Non aggiunge il permesso microfono: la registrazione la fa l'app di sistema.

### Test
Come per 7.5/7.6, alcuni test di strumentazione Compose potrebbero cercare testi cambiati; i test di dominio/dati non sono toccati. La schermata manager ha `onOpenReservations` con default `{}`, quindi i test esistenti che la costruiscono continuano a compilare.

---

## Come procedere
1. Compila di nuovo: le 5 correzioni + il modulo dovrebbero dare build pulito.
2. Se resta acceso `AnimatedVisibility` (sta in compose-animation), dimmelo: lo sostituisco con un `if`.
3. Provalo: Ristoratore → area → "Prenotazioni di sala" → aggiungi una riga, prova "🎙 Detta".
4. Qualsiasi errore rosso: mandami il primo con file e riga.
