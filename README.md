# HAPOSTO — app Android, database Supabase, sito

**Versione:** 0.9.0 — app completa lato codice (in attesa di configurazione e test finali)
**Area pilota:** Pesaro e provincia

HAPOSTO è una utility locale per capire rapidamente quali ristoranti dichiarano disponibilità **adesso**, con timestamp e TTL.

## Stato attuale (da leggere per primo)

| Parte | Dove | Stato |
|---|---|---|
| App Android: versioni **Demo** / **Dev** / **Prod** | `app/` | completa: lista e mappa, preferiti, account Google, verifica in due passaggi per i ristoratori, area ristoratore reale (rivendicazione con codice telefonico, registrazione, dashboard, QR, statistiche, orari, staff, dettatura di dettagli e prenotazioni, note pronte, offerta della serata, link al menù e un file), pannello admin nascosto con seconda password, HAPOSTO Plus (Google Play), notifiche push e promemoria, termini e privacy |
| Database | `supabase/migrations/0001–0016` | completo, verificato dalla CI (238 controlli su permessi e regole) |
| Edge Function | `supabase/functions/` | push FCM, verifica Google Play, notifiche Play, checkout/portale/webhook Stripe, foto o PDF del menù |
| Sito | `web/` | home, area ristoratori (Pro), pagina pubblica `/r/…` per i QR (con offerta e menù), pagine legali, cancellazione account |

**A che punto è la configurazione:** `docs/HAPOSTO_STATO_CONFIGURAZIONE.md` (parti fatte, prossima
parte, come riprendere). Registro delle modifiche: `docs/modifiche/`. Regole per chi lavora al
codice (anche Claude): `CLAUDE.md`.

**Cosa manca (lo fai tu, con la guida):** eseguire le migration 0012–0013, attivare Google e la 2FA
in Supabase, creare le chiavi (Google, Firebase, Play, Stripe), pubblicare Edge Function e sito,
test finali → **`docs/HAPOSTO_GUIDA_CONFIGURAZIONE_COMPLETA.md`**.

Build Variants in Android Studio: `demoDebug` (nessun server), `devDebug` (Supabase DEV),
`prodDebug`/`prodRelease` (produzione). Comandi: `./gradlew testDemoDebugUnitTest`,
`./gradlew assembleDebug` (tutte e tre le versioni), `./gradlew lintDemoDebug`,
`./gradlew connectedDemoDebugAndroidTest`.

Strumenti gratuiti: Supabase Free (database, login, tempo reale, Edge Function), Google Sign-In,
Firebase Cloud Messaging, MapLibre + OpenFreeMap (mappe), Cloudflare/GitHub Pages (sito).

---

# Storico: Step 7

## Cosa cambia nello STEP 7

Per la prima volta il progetto può leggere un backend reale:

```text
Android Home
↓
Supabase PostgREST
↓
nearby_restaurants RPC
↓
PostGIS
↓
restaurants + restaurant_live_status
```

Se `local.properties` contiene Project URL + publishable key validi, la Home mostra:

```text
SUPABASE DEV
```

e legge la directory dal progetto Supabase configurato.

Se entrambe le proprietà sono assenti, HAPOSTO mantiene il fallback fake locale per sviluppo UI.

Se la configurazione è parziale/errata, mostra un errore invece di fare fallback silenzioso.

---

# Setup consigliato

Leggi nell'ordine:

1. `docs/STEP_7_SETUP_SUPABASE.md`
2. `docs/STEP_7_BUILD_AND_TEST.md`
3. `docs/STEP_7_TROUBLESHOOTING.md`

Il primo documento guida dalla creazione del progetto Supabase fino a `local.properties`.

Il secondo è la checklist per il primo vero Sync/Build/Test sul tuo PC.

---

# Stato backend STEP 7

## Reale

```text
Supabase Project             ON quando configurato
PostgreSQL                   ON
PostGIS                      ON
RLS/grants directory         ON
RPC nearby_restaurants       ON
consumer read                ON
network errors               REAL
```

## Ancora demo/off

```text
consumer account             NESSUNO
Google Auth ristoratore      DEMO LOCALE
claim                         DEMO LOCALE
admin approval                DEMO LOCALE
manager LIVE write            RAM ONLY
manager phone write           RAM ONLY
Realtime                      OFF
FCM                           OFF
billing                       OFF
```

La separazione è intenzionale: nello Step 7 validiamo prima database, RLS pubblico, PostGIS, networking Android e build reale.

---

# SQL da eseguire

In Supabase SQL Editor, uno alla volta:

```text
supabase/migrations/0001_extensions.sql
supabase/migrations/0002_schema.sql
supabase/migrations/0003_functions.sql
supabase/migrations/0004_rls_and_grants.sql
```

Poi, per DEV:

```text
supabase/seeds/900_example_fictional_data.sql
supabase/tests/step7_manual_smoke.sql
```

NON eseguire nello Step 7:

```text
supabase/migrations/0005_realtime_future.sql
```

---

# Configurazione Android

Copia:

```text
local.properties.example
```

nelle proprietà locali esistenti, senza cancellare `sdk.dir`:

```properties
SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
SUPABASE_PUBLISHABLE_KEY=sb_publishable_REPLACE_ME
```

Mai inserire nell'app:

```text
sb_secret_...
service_role
database password
JWT signing secret
admin token
```

---

# Privacy posizione STEP 7

La posizione del dispositivo:

- resta RAM-only sul telefono;
- non viene salvata in `SavedStateHandle`;
- con Supabase attivo viene inviata via HTTPS come parametro della query geo;
- non viene inserita nelle tabelle HAPOSTO.

---

# Business rules V1

```text
TTL LIVE                      30 minuti
Tavoli liberi                 0..99
Attesa indicativa             0..240 min
Nota                          max 80 caratteri
FULL                          nessun availableTables
STALE                         derivato dal tempo
NOT_CONNECTED                 derivato dalla partnership
```

Le stesse regole sono ora presenti sia nel dominio Android sia nello schema/funzioni SQL.

---

# Versioni Step 7

```text
versionCode     8
versionName     0.7.0-step7
AGP             9.3.0
Gradle target   9.5.0
Kotlin          2.4.10
Supabase Kotlin 3.7.0
Ktor            3.5.2
minSdk          26
```

---

# Gradle Wrapper, build e test

Il repository contiene il wrapper Gradle standard (`gradlew`, `gradlew.bat`,
`gradle/wrapper/gradle-wrapper.jar`, distribuzione 9.5.0): non serve generarlo.
Il daemon Gradle usa Java 21 (`gradle/gradle-daemon-jvm.properties`); la JBR inclusa
in Android Studio va bene.

```text
./gradlew testDemoDebugUnitTest            # unit test JVM (dominio, dati, ViewModel)
./gradlew assembleDebug                    # APK debug delle tre versioni (demo, dev, prod)
./gradlew lintDemoDebug                    # Android lint
./gradlew connectedDemoDebugAndroidTest    # test Compose su device/emulatore collegato
```

Su Windows usa `gradlew.bat` al posto di `./gradlew`.

La CI GitHub (`.github/workflows/android-ci.yml`) esegue unit test, build delle tre versioni e
dell'APK di test strumentali, lint, migration e controlli SQL, controllo delle Edge Function
(Deno) e test su emulatore a ogni push/PR, senza nessuna credenziale. Il workflow `website.yml`
costruisce il sito.

Dettagli: `docs/STEP_7_BUILD_AND_TEST.md`.

---

# Documentazione principale

Da dove partire (settembre 2026):

- `docs/HAPOSTO_GUIDA_CONFIGURAZIONE_COMPLETA.md` — **tutte le operazioni rimaste**, in ordine: migration 0012–0013, login Google e 2FA, chiavi, Edge Function, Google Play, Stripe, sito, produzione, test finali
- `docs/HAPOSTO_GUIDA_APP_TUTORIAL.md` — come si usa l'app, per utenti e ristoratori
- `docs/HAPOSTO_GUIDA_TEST_PSEUDOREALISTICO.md` — provare l'app con 36 locali che cambiano da soli, anche con due telefoni
- `docs/HAPOSTO_GUIDA_AGGIORNAMENTO_DB.md` — aggiornare Supabase con le migration 0006–0011, passo per passo (0012–0013: guida di configurazione, Parte 1)
- `docs/HAPOSTO_GUIDA_APP_E_DATI_REALI.md` — cosa è reale e cosa simulato, import dei locali da OpenStreetMap, prove sul campo, pilot
- `docs/HAPOSTO_MODELLO_PREMIUM_E_ACCOUNT.md` — piani Pro (prova, poi "Non collegato" senza abbonamento) e Gratis/Plus, registrazione, acquisti
- `docs/HAPOSTO_SQL_INTEGRATIVO.md` — tabelle, funzioni e permessi del database completo
- `docs/HAPOSTO_ROADMAP_COMPLETA.md` — **tutte** le attività da oggi alla fine del progetto: login, privacy, pagamenti, Play Store, pilot, calendario
- `docs/HAPOSTO_ROADMAP_INTEGRATIVA.md` — cosa ha aggiunto lo Step 7.9

Riferimenti Step 7 e architettura:

- `docs/STEP_7_SETUP_SUPABASE.md`
- `docs/STEP_7_BUILD_AND_TEST.md`
- `docs/STEP_7_TROUBLESHOOTING.md`
- `docs/STEP_7_MODIFICA.md`
- `docs/STEP_7_VALIDATION.md`
- `docs/V1_CONTRACT_FREEZE.md`
- `docs/ROADMAP.md`
- `docs/ARCHITECTURE.md`
