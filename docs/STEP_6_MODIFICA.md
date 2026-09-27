# HAPOSTO — STEP 6 MODIFICA

## Obiettivo

Chiudere la demo Android pre-backend e congelare il comportamento V1 prima di collegare Supabase.

STEP 6 non introduce prenotazioni, social, billing, foto o nuove feature di marketplace.

---

## Modifiche principali

### 1. Freeze delle business rules

Nuovo:

```text
domain/model/AvailabilityRules.kt
```

Centralizza:

- TTL 30 minuti;
- tavoli 0–99;
- attesa 0–240;
- nota max 80;
- `FULL` senza `availableTables`.

`LiveAvailability`, `AvailabilityResolver`, fake repository e manager draft ora usano gli stessi limiti.

### 2. Repository reference behavior

`RestaurantRepository` e `RestaurantAccessRepository` sono marcati come contratti V1 pre-backend.

Il fake repository è la reference implementation che lo STEP 7 deve replicare lato Supabase.

### 3. FULL normalizzato anche nel repository

Prima il ViewModel manager azzerava i tavoli quando si selezionava `FULL`.

Ora anche il repository impone:

```text
FULL → availableTables = null
```

Quindi l'invariante non dipende dalla singola schermata chiamante.

### 4. Fix reale di integrazione AccessRoute

Nella base STEP 5 `HaPostoApp` passava `networkMonitor` a `RestaurantAccessRoute`, ma la route non dichiarava il parametro.

STEP 6 riallinea le firme e usa il monitor realmente:

```text
RestaurantAccessRoute
↓
NetworkMonitor
↓
RestaurantAccessScreen(isOnline)
```

La shell claim mostra ora disclosure offline.

### 5. Copy pre-backend

- `STEP 6 · DEMO PRE-BACKEND`;
- dashboard: `Claim approvato · demo locale`;
- copy locale aggiornato da Step 5 a Step 6.

### 6. Acceptance test end-to-end locale

Nuovo:

```text
PreBackendDemoAcceptanceTest.kt
```

Dimostra che manager e consumer condividono davvero lo stesso repository.

### 7. Contract compile smoke

Nuovo:

```text
RepositoryContractV1Test.kt
```

Compila/esercita le firme repository congelate.

### 8. UI tests aggiunti

Nuovi:

```text
RestaurantAccessScreenTest.kt
RestaurantManagerScreenTest.kt
```

Coprono almeno:

- access shell offline;
- pending claim;
- tre pulsanti stato;
- warning manager offline.

### 9. Documentazione gate

Nuovi:

```text
docs/V1_CONTRACT_FREEZE.md
docs/STEP_6_ACCEPTANCE.md
docs/STEP_6_MODIFICA.md
docs/STEP_6_VALIDATION.md
```

---

## Versione

```text
versionCode = 7
versionName = 0.6.0-step6
```

---

## Backend

Supabase resta completamente OFF nello STEP 6.

Il prossimo step è il primo in cui è consentito creare il progetto Supabase ed eseguire le migration previste, dopo riesame rispetto al contract freeze.
