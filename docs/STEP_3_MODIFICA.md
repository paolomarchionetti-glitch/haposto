# HAPOSTO — STEP 3
## Dashboard ristoratore locale + stato condiviso consumer/manager

**Data:** 24 agosto 2026  
**Backend:** OFF  
**Supabase:** NON configurare / NON eseguire SQL

---

# Obiettivo dello Step 3

Chiudere per la prima volta il loop operativo centrale di HAPOSTO senza introdurre ancora autenticazione o backend:

```text
RISTORATORE DEMO
   ↓ un tap
C'È POSTO / POCHI POSTI / COMPLETO
   ↓
Repository locale condiviso
   ↓
HOME CONSUMER + DETTAGLIO
```

Lo Step 3 serve a validare il gesto che, secondo le analisi di prodotto, deve restare quasi ridicolmente semplice: il ristoratore non gestisce un software complesso, **tocca un semaforo**.

---

# Modifiche principali

## 1. Entry point ristoratore dalla Home

Aggiunto:

```text
Sei un ristoratore?
```

Nello Step 3 non viene mostrato un login finto. Il pulsante apre direttamente la dashboard del ristorante demo assegnato localmente:

```text
levante-demo
```

L'Auth reale rimane fuori scope e verrà prima simulata come UX shell nello Step 4, poi collegata realmente a Supabase nella fase backend.

---

## 2. Nuova dashboard ristoratore

Nuovi file principali:

```text
ui/screens/restaurant/
├── RestaurantManagerRoute.kt
├── RestaurantManagerScreen.kt
├── RestaurantManagerUiState.kt
└── RestaurantManagerViewModel.kt
```

La dashboard mostra:

- locale demo assegnato;
- stato attualmente visibile agli utenti;
- timestamp;
- tempo residuo indicativo del TTL;
- tre pulsanti grandi;
- dettagli facoltativi;
- visibilità telefono;
- messaggi di conferma locali.

---

## 3. Tre pulsanti operativi

```text
🟢 C'È POSTO
🟠 POCHI POSTI
🔴 COMPLETO
```

Regola deliberata:

> **nessuna finestra di conferma.**

Un tap pubblica immediatamente lo stato nel repository locale.

Ogni pubblicazione imposta:

```text
updatedAt = now
validUntil = now + 30 minuti
```

Quando viene pubblicato `COMPLETO`, il numero di tavoli liberi viene eliminato per evitare un'informazione semanticamente contraddittoria.

---

## 4. Dettagli facoltativi

Il ristoratore può ignorarli completamente.

Sono disponibili:

### Tavoli liberi

```text
Non indicato / 0..99
```

### Attesa indicativa

```text
Non indicata
Nessuna
10 min
20 min
30+ min
```

### Nota breve

Massimo:

```text
80 caratteri
```

Esempio:

```text
Disponibili solo tavoli esterni
```

Il pulsante:

```text
AGGIORNA DETTAGLI E RICONFERMA STATO
```

ripubblica lo stato corrente con i dettagli e rinnova timestamp + TTL. Questo è intenzionale: modificare i dettagli equivale a confermare che lo stato è ancora valido.

---

## 5. Telefono pubblico ON/OFF

Per il ristorante demo che possiede un numero telefonico è disponibile un `Switch`:

```text
Telefono pubblico ON/OFF
```

La modifica:

- viene condivisa immediatamente con la scheda consumer;
- fa apparire/scomparire `CHIAMA`;
- **non** modifica timestamp o TTL della disponibilità.

Sono due informazioni diverse e vengono trattate separatamente.

---

# Repository evoluto

`RestaurantRepository` non è più soltanto read-only.

Ora espone anche:

```kotlin
publishAvailability(...)
setPhonePublic(...)
```

`FakeRestaurantRepository` implementa entrambe le operazioni modificando lo stesso `MutableStateFlow<List<Restaurant>>` osservato dalla Home.

Questa scelta è importante per il futuro backend: le schermate dipendono dal contratto repository, non dal fatto che oggi i dati siano in RAM.

---

# Stato condiviso reale nella demo

Prima dello Step 3 i record fake erano essenzialmente statici.

Ora:

1. Home osserva `RestaurantRepository.observeRestaurants()`;
2. dashboard ristoratore aggiorna il repository;
3. `MutableStateFlow` emette la nuova lista;
4. Home si ricompone;
5. la card mostra il nuovo stato;
6. anche il dettaglio ora osserva il repository e rimane coerente.

Quindi il loop è realmente condiviso dentro il processo Android.

---

# Persistenza

Nessuna.

Gli aggiornamenti dello Step 3:

- non vengono salvati in file;
- non usano Room;
- non usano DataStore;
- non usano SharedPreferences;
- non vengono inviati a server;
- spariscono quando il processo dell'app viene terminato.

È voluto: stiamo validando prima UX e dominio.

---

# Supabase

Rimane completamente dormiente.

Non fare ora:

- progetto Supabase;
- migration;
- Auth;
- Project URL;
- publishable key;
- Realtime.

Gli SQL restano nel pacchetto solo per mantenere il contratto backend pianificato.

---

# Test aggiunti

Nuovo:

```text
FakeRestaurantRepositoryTest.kt
```

Copre almeno:

- pubblicazione stato;
- timestamp controllato;
- TTL esattamente 30 minuti;
- dettagli opzionali;
- impossibilità per un `DIRECTORY_ONLY` di pubblicare LIVE;
- telefono pubblico condiviso;
- toggle telefono che non altera il timestamp live.

Restano attivi i test precedenti per freshness, scadenza, query, filtri e geografia.

---

# Come provare manualmente Step 3

1. Avvia HAPOSTO.
2. In Home individua `Osteria Levante`.
3. Tocca `Sei un ristoratore?`.
4. Premi `COMPLETO`.
5. Torna indietro.
6. Verifica che `Osteria Levante` sia ora rossa e `COMPLETO`.
7. Riapri area ristoratore.
8. Premi `C'È POSTO`.
9. Imposta tavoli, attesa e nota.
10. Tocca `AGGIORNA DETTAGLI E RICONFERMA STATO`.
11. Torna alla Home e apri il dettaglio: i dettagli devono essere gli stessi.
12. Disattiva `Telefono pubblico`.
13. Torna nella scheda: `CHIAMA` deve sparire.
14. Riattivalo: `CHIAMA` deve tornare.

---

# File principali modificati

```text
AppDependencies.kt
RestaurantRepository.kt
FakeRestaurantRepository.kt
HaPostoApp.kt
AppDestination.kt
HomeRoute.kt
HomeScreen.kt
RestaurantDetailRoute.kt
app/build.gradle.kts
```

Nuovi:

```text
ui/screens/restaurant/*
FakeRestaurantRepositoryTest.kt
docs/STEP_3_MODIFICA.md
docs/STEP_3_VALIDATION.md
```

---

# Step successivo preannunciato — STEP 4

## Claim/Auth UX shell, ancora senza backend

Costruiremo il percorso ristoratore che precede la dashboard, ma con provider simulato:

```text
Sei un ristoratore?
↓
Accedi / continua demo
↓
Cerca il tuo ristorante
↓
Richiedi gestione
↓
Richiesta in verifica
↓
Approvato (scenario demo)
↓
Dashboard
```

Obiettivi Step 4:

- progettare il futuro Google login senza ancora collegarlo;
- simulare `CLAIM_PENDING / APPROVED`;
- definire copy della verifica manuale;
- mostrare chiaramente che la beta ristorante è gratuita ma il LIVE potrà diventare a pagamento;
- nessuna Auth Supabase reale.
