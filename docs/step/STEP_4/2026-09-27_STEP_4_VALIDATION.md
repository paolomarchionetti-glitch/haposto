# HAPOSTO — STEP 4 Validation

**Data:** 24 agosto 2026

## Validazioni eseguite nell'ambiente di generazione

### Provenienza base

Lo ZIP Step 3 caricato è stato verificato prima delle modifiche:

```text
SHA-256 = 3bbac7d106bad2b9528c287573199602cbaf518b5cdded24b881a479fae52888
```

Quindi STEP 4 è stato costruito sulla versione cumulativa corretta.

---

## Core Kotlin

Compilati con `kotlinc`:

- `domain/model/*`;
- `domain/usecase/*`;
- `RestaurantRepository.kt`;
- `RestaurantAccessRepository.kt`;
- `FakeRestaurantRepository.kt`;
- `FakeRestaurantAccessRepository.kt`.

È stato eseguito anche uno smoke program reale sul flusso accesso/claim.

Esito:

```text
STEP4_ACCESS_SMOKE_OK
```

### Regole controllate dallo smoke

- stato iniziale signed-out;
- directory-only non claimable nella shell Step 4;
- claim partner → `PENDING`;
- `PENDING` non autorizza dashboard;
- approvazione demo → `APPROVED`;
- approved autorizza solo il restaurant id associato;
- altro restaurant id resta non autorizzato;
- logout blocca la dashboard;
- nuovo demo sign-in recupera il claim RAM-only;
- reset cancella account + claim.

---

## XML Android

Tutti gli XML presenti sono stati parsati correttamente:

```text
XML_OK 12 files
```

---

## Guard dashboard

`RestaurantManagerRoute` non usa più il solo restaurant id come autorizzazione.

Condizione richiesta:

```text
RestaurantAccessState.canManage(restaurantId) == true
```

Altrimenti viene mostrato:

```text
RestaurantManagerAccessDeniedScreen
```

Questa guardia è intenzionalmente classificata come UX/client guard, non come security boundary.

---

## SQL Supabase

Hash delle migration e del seed confrontati prima/dopo lo Step 4:

```text
SQL_UNCHANGED_OK
```

È stato modificato soltanto `supabase/README.md`.

---

## Auth/backend

Confermato nello Step 4:

```text
Google SDK runtime = OFF
Supabase Auth runtime = OFF
Supabase database runtime = OFF
Realtime runtime = OFF
```

Il testo `Google` presente nella UI indica soltanto il provider futuro simulato.

Nessun token OAuth viene creato.

Controlli statici eseguiti:

```text
REAL_GOOGLE_AUTH_RUNTIME_OFF_OK
SUPABASE_PROVIDER_DORMANT_OK
SECRET_SCAN_OK
NO_BACKGROUND_LOCATION_OK
```

---

## Persistenza

Non sono stati introdotti:

- Room;
- DataStore;
- SharedPreferences per account/claim;
- file account;
- secure storage;
- network write.

Account demo e claim vivono in `MutableStateFlow` RAM-only.

---

## SQL Supabase

Le migration e il seed non sono stati modificati nello Step 4.

Rimangono da riesaminare prima dello Step 7, quando i modelli Android verranno congelati.

---

## Full Android build

Non è stato possibile eseguire `assembleDebug` nell'ambiente di generazione perché il pacchetto ereditato non contiene `gradle-wrapper.jar` e non è disponibile una toolchain Android/Gradle completa locale.

Controllo finale consigliato in Android Studio:

```text
Gradle Sync
Build > Make Project
Run su emulatore/dispositivo
```

---

## Checklist manuale raccomandata

- [ ] Home si apre senza login;
- [ ] `Sei un ristoratore?` apre la nuova area accesso;
- [ ] banner dichiara chiaramente DEMO LOCALE;
- [ ] demo Google porta a ricerca attività;
- [ ] ricerca filtra i partner demo;
- [ ] selezione locale apre claim form;
- [ ] recapito <3 caratteri non abilita invio;
- [ ] invio crea schermata pending;
- [ ] dashboard non è disponibile prima dell'approvazione;
- [ ] `Simula approvazione admin` porta ad approved;
- [ ] dashboard si apre solo per il locale claimato;
- [ ] stato manager continua ad aggiornare Home/detail;
- [ ] logout toglie l'accesso dashboard;
- [ ] reset riporta al principio;
- [ ] consumer continua a non avere account;
- [ ] nessuna chiamata Supabase.
