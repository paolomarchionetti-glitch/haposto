# HAPOSTO — STEP 5 Validation

**Data:** 24 agosto 2026  
**Versione:** `0.5.0-step5`

---

# 1. Provenienza base

Lo ZIP Step 4 caricato è stato verificato prima delle modifiche:

```text
SHA-256 = b392da69581864c99e2887da0b175cdc917ed5389d87288efc38bdf488ebf745
```

Quindi STEP 5 è stato costruito sulla versione cumulativa corretta.

---

# 2. Core Kotlin

Compilati con `kotlinc`:

- domain model;
- domain use case;
- repository boundary;
- fake repository;
- fake access repository;
- LocationSession;
- NetworkMonitor interface.

Esito:

```text
CORE_KOTLIN_OK
```

Sono stati compilati separatamente anche gli UI state puri:

```text
HomeUiState
RestaurantAccessUiState
RestaurantManagerUiState
```

Esito:

```text
UI_STATE_KOTLIN_OK
```

---

# 3. Smoke test Step 5

Eseguito un programma Kotlin standalone che verifica:

- repository demo disponibile;
- publish LIVE ancora funzionante;
- update `LIMITED` condiviso nel repository;
- empty reason `DIRECTORY_EMPTY`;
- empty reason `NO_MATCHES`.

Esito:

```text
STEP5_CORE_SMOKE_OK
```

---

# 4. Kotlin parser scan

Tutti i file Kotlin `src/main` sono stati passati al parser del compilatore Kotlin senza classpath Android.

Come previsto, il compile completo fallisce per riferimenti Android/AndroidX non disponibili nell'ambiente, ma la scansione non ha prodotto errori sintattici del tipo:

```text
expecting
unclosed
unexpected tokens
missing '}'
```

Esito:

```text
KOTLIN_SYNTAX_SCAN_OK
```

Questo controllo non sostituisce `Build > Make Project` in Android Studio.

---

# 5. XML Android

Tutti gli XML sono stati parsati correttamente.

Esito:

```text
XML_OK 12 files
```

---

# 6. Manifest / permessi

Permessi presenti:

```text
INTERNET
ACCESS_NETWORK_STATE
ACCESS_COARSE_LOCATION
ACCESS_FINE_LOCATION
```

Assenti:

```text
ACCESS_BACKGROUND_LOCATION
CAMERA
READ_CONTACTS
POST_NOTIFICATIONS
READ_MEDIA_IMAGES
```

Esito:

```text
PERMISSIONS_OK
```

---

# 7. Posizione / privacy

Verificato staticamente che `HomeViewModel`:

- usa `SavedStateHandle` per query/filtro/area manuale;
- non definisce chiavi latitude/longitude;
- non salva coordinate device nel SavedState;
- mantiene la location device in `LocationSession` RAM-only.

Il recapito digitato nella shell claim resta anch'esso RAM-only e non viene copiato nel SavedState.

Esito:

```text
SAVED_STATE_PRIVACY_OK
```

---

# 8. Connettività

Aggiunto:

```text
NetworkMonitor
AndroidNetworkMonitor
```

Il monitor usa soltanto `ConnectivityManager` e `NetworkCapabilities`.

Non effettua HTTP call.

La Home e la dashboard ristoratore consumano soltanto `Flow<Boolean>` online/offline.

---

# 9. Auth/backend guard

Controlli statici:

```text
FirebaseAuth = assente
Google OAuth runtime = assente
ACCESS_BACKGROUND_LOCATION = assente
JWT-like key literal = assente
secret Supabase key literal = assente
```

Il provider Supabase resta scaffold dormiente e i campi BuildConfig restano vuoti se non configurati localmente.

Esito:

```text
RUNTIME_GUARDS_OK
```

---

# 10. SQL Supabase

Le migration e il seed sono stati confrontati byte-per-byte con lo Step 4 originale:

```text
0001_extensions.sql
0002_schema.sql
0003_functions.sql
0004_rls_and_grants.sql
0005_realtime_future.sql
900_example_fictional_data.sql
```

Esito:

```text
SQL_UNCHANGED_OK
```

È stato aggiornato soltanto `supabase/README.md` per indicare STEP 5.

---

# 11. State restoration

Le factory Home / RestaurantAccess / RestaurantManager sono state portate al pattern:

```text
viewModelFactory {
    initializer {
        createSavedStateHandle()
    }
}
```

Salvati solo dati UI necessari.

## Non persistiti intenzionalmente

```text
device coordinates
restaurant demo account
approved claim
live restaurant state
verification contact draft
```

Questi restano RAM-only fino al backend.

---

# 12. Accessibilità

Verificato nel codice:

- disponibilità sempre espressa con testo oltre al colore;
- `AvailabilityBadge` espone content description;
- `RestaurantCard` espone nome/categoria/distanza/stato/freshness come semantica aggregata;
- heading semantico Home;
- badge demo informativi non sono più controlli cliccabili senza azione;
- error/offline copy esplicito.

I componenti principali interattivi restano Material, quindi rispettano i touch target standard del toolkit.

---

# 13. Responsive/adaptive

Aggiunto:

```text
AdaptiveScrollableContent
```

Home, access, manager e detail limitano la larghezza leggibile su finestre ampie usando `BoxWithConstraints` / `widthIn`.

Questo viene fatto senza introdurre una nuova dipendenza adattiva prima del freeze V1.

---

# 14. Compose UI test

Aggiunti source test:

```text
HomeScreenTest.kt
RestaurantManagerAccessDeniedScreenTest.kt
```

Copertura prevista:

- loading;
- no matches;
- offline;
- directory empty;
- manager access guard.

Dipendenze aggiunte:

```text
androidx.compose.ui:ui-test-junit4
androidx.compose.ui:ui-test-manifest
```

Esito controllo presenza/configurazione:

```text
UI_TEST_SOURCES_OK
VERSION_CATALOG_OK
GRADLE_CONFIG_STATIC_OK
```

## Limite ambiente

Gli instrumentation test non sono stati eseguiti perché nell'ambiente di generazione non è disponibile Android SDK/emulatore.

---

# 15. Full Android build

Non è stato possibile eseguire:

```text
assembleDebug
connectedAndroidTest
```

perché l'ambiente non dispone dell'Android SDK completo e il progetto ereditato non contiene `gradle-wrapper.jar`.

Controllo finale richiesto in Android Studio:

```text
Gradle Sync
Build > Make Project
Run
```

Poi, se disponibile:

```text
Run Tests / connectedAndroidTest
```

---

# 16. Checklist manuale raccomandata

## Consumer

- [ ] Home apre senza login;
- [ ] loading non produce flash/error anomali;
- [ ] search e filtro funzionano;
- [ ] query/filtro sopravvivono a rotazione/recreation;
- [ ] area manuale viene ripristinata;
- [ ] coordinate device non vengono ripristinate dopo process death;
- [ ] offline banner compare disattivando rete;
- [ ] posizione precisa funziona;
- [ ] posizione approssimativa funziona;
- [ ] rationale appare quando Android lo richiede;
- [ ] denial permanente offre Impostazioni app;
- [ ] dettaglio apre;
- [ ] indicazioni/dialer gestiscono assenza handler.

## Ristoratore

- [ ] accesso demo resta chiaramente fittizio;
- [ ] ricerca attività funziona;
- [ ] claim form ripristina selezione ma non recapito;
- [ ] pending non apre dashboard;
- [ ] approved apre solo dashboard del locale associato;
- [ ] route manager non autorizzata resta bloccata;
- [ ] back stack non crea copie multiple;
- [ ] offline dashboard mostra warning;
- [ ] tre pulsanti LIVE continuano ad aggiornare la Home;
- [ ] draft tavoli/attesa/nota sopravvive a recreation.

## Large screen

- [ ] phone portrait;
- [ ] phone landscape;
- [ ] tablet / resizable emulator;
- [ ] contenuto resta centrato e leggibile.

---

# 17. Gate

STEP 5 non autorizza ancora l'attivazione Supabase.

Il gate backend resta:

```text
STEP 6 completato
↓
freeze modelli V1
↓
acceptance checklist
↓
STEP 7 Supabase
```
