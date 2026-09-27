# HAPOSTO — STEP 6 Validation

## 1. Base verificata

ZIP di partenza:

```text
HAPOSTO_STEP_5_ANDROID_STUDIO.zip
```

SHA-256 atteso/verificato:

```text
0f112d08c493fdba7fc90133f713f4ccf7a75e050b6f528d0f46b7d94f54faaf
```

Quindi STEP 6 parte dalla build cumulativa corretta.

---

## 2. Correzione di integrazione individuata

È stato individuato e corretto un mismatch di firma:

```text
HaPostoApp → RestaurantAccessRoute(networkMonitor = ...)
```

mentre la route STEP 5 non dichiarava ancora quel parametro.

STEP 6 aggiunge il parametro e lo utilizza per la disclosure offline della shell ristoratore.

Questo è documentato perché il full Android build non era stato disponibile negli step precedenti.

---

## 3. Core/business validation

Validati localmente con Kotlin/JVM:

- model availability;
- business rules;
- repository fake;
- access repository fake;
- loop pre-backend consumer/manager.

Smoke marker atteso:

```text
STEP6_PREBACKEND_SMOKE_OK
```

---

## 4. Freeze invariants

Controllati:

```text
TTL = 30 min
max tables = 99
max wait = 240
max note = 80
FULL + availableTables != null → invalid
DIRECTORY_ONLY cannot publish
phone toggle does not refresh live timestamp
```

---

## 5. Android/static checks

Controllati staticamente:

- manifest XML;
- resource XML;
- version catalog TOML;
- navigation route signatures principali;
- `ACCESS_BACKGROUND_LOCATION` assente;
- Supabase provider non invocato dalla UI;
- nessuna Auth Google reale;
- nessuna chiave reale;
- coordinate device non persistite;
- SQL invariati rispetto allo STEP 5.

---

## 6. UI tests source

Presenti:

```text
HomeScreenTest
RestaurantManagerAccessDeniedScreenTest
RestaurantAccessScreenTest
RestaurantManagerScreenTest
```

L'ambiente corrente non dispone di Android SDK/emulatore completo, quindi gli instrumentation test sono preparati ma non dichiarati come eseguiti qui.

---

## 7. Limite build

Non viene dichiarato un `assembleDebug` completo perché l'ambiente non include il toolchain Android completo né il `gradle-wrapper.jar` ufficiale.

Prima di STEP 7, in Android Studio eseguire:

```text
Gradle Sync
Build > Make Project
app/src/test
app/src/androidTest su emulatore/device
```

---

## 8. Supabase

STEP 6 non esegue:

- creazione progetto;
- migration;
- Auth;
- Realtime;
- PostGIS runtime;
- networking verso Supabase.

Lo scaffold resta dormiente.

---

## 9. Risultati effettivamente ottenuti nell'ambiente di generazione

```text
CORE_KOTLIN_OK
UNIT_TEST_SOURCES_KOTLIN_OK
STEP6_PREBACKEND_SMOKE_OK
XML_AND_TOML_OK (12 XML)
NO_BACKGROUND_LOCATION_OK
ACCESS_ROUTE_SIGNATURE_OK
SUPABASE_PROVIDER_DORMANT_OK
REAL_AUTH_RUNTIME_OFF_OK
SECRET_SCAN_OK
SAVED_STATE_PRIVACY_SCAN_OK
SQL_UNCHANGED_OK
```

Il pacchetto finale contiene 118 file reali, incluso il manifest SHA-256 del progetto.
