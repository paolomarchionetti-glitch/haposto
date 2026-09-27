# HAPOSTO — STEP 7.8: rifinitura visiva + guida test + Supabase

## Parte A — Cosa ho migliorato graficamente (7.8)

1. **Font brand Poppins.** È il salto più visibile. Ho incluso Poppins (Regular/Medium/SemiBold/Bold/Black) direttamente nel progetto (`res/font/`), senza dipendenze e senza rete: tutta l'app ora usa un font moderno e coerente al posto del font di sistema. Licenza OFL inclusa in `docs/POPPINS_OFL.txt`.
2. **Header brandizzato in Home.** Al posto della barra bianca c'è ora un'intestazione a **gradiente ink** con il wordmark "HAPOSTO", la tagline e il badge stato (DEMO / SUPABASE DEV), con angoli inferiori arrotondati. Dà subito un'aria da prodotto vero.

Anteprima: `brand/anteprima_home_7_8.png`.

> Nessuna dipendenza nuova, nessuna modifica al contratto V1, nessun impatto su Supabase.

---

## Parte B — File aggiunti/modificati (dalle ultime due fasi)

### STEP 7.8 (rifinitura visiva)
**Aggiunti**
- `app/src/main/res/font/poppins_regular.ttf` (+ medium, semibold, bold, black)
- `docs/POPPINS_OFL.txt` (licenza font)

**Modificati**
- `app/src/main/java/com/haposto/ui/theme/Type.kt` — usa Poppins
- `app/src/main/java/com/haposto/ui/screens/home/HomeScreen.kt` — header a gradiente (rimossa la vecchia TopAppBar)

### STEP 7.7 (prenotazioni + correzioni build)
**Aggiunti**
- `app/src/main/java/com/haposto/data/reservations/Reservation.kt`
- `app/src/main/java/com/haposto/data/reservations/ReservationStore.kt`
- `app/src/main/java/com/haposto/ui/screens/reservations/ReservationsViewModel.kt`
- `app/src/main/java/com/haposto/ui/screens/reservations/ReservationsScreen.kt`
- `app/src/main/java/com/haposto/ui/screens/reservations/ReservationsRoute.kt`

**Modificati**
- `ui/navigation/AppDestination.kt` — rotta `reservations/{restaurantId}`
- `ui/HaPostoApp.kt` — composable rotta + `onOpenReservations`
- `ui/screens/restaurant/RestaurantManagerRoute.kt` — passa `onOpenReservations`
- `ui/screens/restaurant/RestaurantManagerScreen.kt` — card d'ingresso prenotazioni
- `AndroidManifest.xml` — `<queries>` per il riconoscimento vocale
- `data/remote/supabase/SupabaseRestaurantRepository.kt` — fix `rpc` (JsonObject)
- `ui/screens/access/RestaurantAccessScreen.kt` — fix import `weight`
- `ui/screens/restaurant/RestaurantManagerViewModel.kt` — fix inferenza tipo

---

## Parte C — Cosa fare DOPO IL BUILD, per testare

Prima assicurati che compili (Sync → Make Project). Se `AnimatedVisibility` risulta non risolto, avvisami: è un cambio di una riga.

### 1. Avvio e aspetto
- L'app parte con l'**onboarding** (primo avvio). Chiudilo.
- La Home ha l'**header a gradiente** con il font Poppins. Testi e tasti devono avere il nuovo font.

### 2. Modalità dati (dipende da Supabase, vedi Parte D)
- Senza configurazione Supabase: badge **DEMO** e dati locali dimostrativi.
- Con Supabase configurato: badge **SUPABASE DEV** e ristoranti dal seed reale.

### 3. Flusso cliente
- Tocca "**Mostra solo dove c'è posto**": la lista si filtra.
- Cambia area dalla riga posizione ("Cambia"): le distanze cambiano.
- Apri una card → dettaglio → prova "Indicazioni" e (dove presente) "Chiama".
- Verifica un locale con stato scaduto: deve risultare **DA AGGIORNARE**.

### 4. Flusso ristoratore
- Barra in basso → **Ristoratore** → completa l'accesso demo → apri la dashboard.
- Premi i **tre tasti grandi** (C'è posto / Pochi posti / Completo): lo stato cambia nell'app.
  (In Step 7 la scrittura è locale in RAM: chiudendo e riaprendo torna al valore del backend. È corretto.)
- Apri "**Dettagli facoltativi**" e prova tavoli/attesa/nota.
- Card "**Info locale**": prova l'interruttore del telefono.

### 5. Prenotazioni di sala (nuovo)
- Nell'area ristoratore, in fondo: "**📋 Prenotazioni di sala → Apri**".
- Aggiungi una riga: nome, orario, persone, tavolo. Premi **Aggiungi**.
- Prova "**🎙 Detta**" sul Nome (parla in italiano); il testo compare nel campo, modificabile.
- Tocca una riga per **modificarla**, "Rimuovi" per cancellarla.
- Chiudi e riapri l'app: le prenotazioni **restano** (salvate sul dispositivo).

### 6. Test automatici (facoltativo)
- Unit test (`app/src/test`): dominio/dati, non toccati dalle modifiche UI — dovrebbero restare verdi.
- Strumentazione (`app/src/androidTest`): alcuni test cercano testi cambiati da 7.5–7.8; se falliscono, vanno aggiornati alle nuove stringhe. Non bloccano l'app.

---

## Parte D — Operazioni Supabase

### Per le PRENOTAZIONI: nulla
Il blocco prenotazioni è **solo sul dispositivo**. Non richiede nessuna operazione Supabase, nessuna tabella, nessun permesso.

### Cosa fare ORA (per far leggere l'app dal backend reale — Step 7)
1. Crea un progetto **Supabase DEV** (regione EU). Password DB solo nel password manager.
2. In SQL Editor esegui le migration **in ordine, una alla volta**:
   `0001_extensions.sql` → `0002_schema.sql` → `0003_functions.sql` → `0004_rls_and_grants.sql`
   **NON** eseguire `0005_realtime_future.sql` (è per lo Step 10).
3. Carica il seed: `900_example_fictional_data.sql`.
4. Verifica: esegui `step7_manual_smoke.sql` e controlla che PostGIS/pg_trgm ci siano, RLS attivo sulle 5 tabelle, la ricerca "levante" trovi l'Osteria Levante Demo, `invalid_full_rows = 0`.
5. Copia **Project URL** e **publishable key** (inizia con `sb_publishable_`).
6. Mettile in `local.properties` (senza virgolette):
   ```
   SUPABASE_URL=https://TUO_REF.supabase.co
   SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxx
   ```
7. Rifai il build: la Home mostra **SUPABASE DEV** e i ristoranti del seed.

I file SQL sono nel progetto sotto `supabase/migrations`, `supabase/seeds`, `supabase/tests`. Guida dettagliata: `docs/MD1_GUIDA_BUILD_E_SUPABASE.md`.

⚠️ Mai usare in app `sb_secret_…`, `service_role` o la password del database.

### Cosa dovrai fare in FUTURO (non ora)
- **Step 8 — Auth reale:** abilitare l'autenticazione in Supabase; sblocca le scritture del ristoratore.
- **Step 9 — Scritture LIVE reali:** il manager scriverà davvero via RPC autenticata (`set_restaurant_live_status`), sostituendo l'overlay in RAM.
- **Step 10 — Realtime:** eseguire `0005_realtime_future.sql` per gli aggiornamenti dal vivo.
- **Step 11 — Notifiche push (FCM):** reminder di aggiornamento e avvisi.
- **Prenotazioni in cloud (solo se vorrai):** dopo l'Auth, una nuova tabella `reservations` con RLS per sincronizzare tra più dispositivi della sala. Facoltativo: oggi restano locali.

---

## Come procedere
1. Compila e prova seguendo la Parte C.
2. Fai le operazioni Supabase della Parte D quando vuoi passare da DEMO a dati reali.
3. Qualsiasi errore rosso: mandami il primo con **file e riga**.
