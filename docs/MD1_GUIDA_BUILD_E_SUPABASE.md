# MD1 — HAPOSTO · Guida completa a Build e Supabase

Guida unica e ordinata per portare HAPOSTO da **cartella estratta** a **app che gira sul telefono leggendo davvero da Supabase**.

> **Applica prima lo STEP 7.5** (vedi MD2). Il 7.5 cambia solo tema, componenti UI, navigazione e onboarding: **non tocca** repository, modelli, DTO o SQL. Quindi tutto ciò che segue resta identico e valido.

Tempo realistico la prima volta: **60–90 minuti**, quasi tutti di attesa (download dipendenze + primo build).

---

## Mappa del percorso

1. Preparare gli strumenti
2. Creare il progetto Supabase DEV
3. Eseguire le migration SQL (in ordine)
4. Caricare i dati demo (seed)
5. Verificare il database (smoke test SQL)
6. Recuperare URL e chiave pubblica
7. Configurare Android (`local.properties`)
8. Generare il Gradle Wrapper
9. Sync, build, test
10. Collaudo sull'app (checklist)
11. Problemi comuni e soluzioni

---

## 1. Prepara gli strumenti

Ti servono:

- **Android Studio** aggiornato, con Android SDK installato;
- **JDK 17** (obbligatorio per Gradle/AGP di questo progetto);
- connessione internet stabile;
- un **account Supabase**;
- il progetto HAPOSTO estratto in una cartella **scrivibile** (non dentro lo ZIP, non in una cartella di sistema).

Versioni di riferimento del progetto (non cambiarle a caso):

```
AGP              9.3.0
Gradle target    9.5.0
JDK              17
Kotlin           2.4.10
Supabase Kotlin  3.7.0
Ktor             3.5.2
minSdk           26
compile/target   37
```

---

## 2. Crea il progetto Supabase DEV

1. Entra nella Dashboard di Supabase.
2. Crea un **nuovo progetto** dedicato allo sviluppo. Nome consigliato: `haposto-dev`.
3. Scegli una **regione europea** vicina agli utenti del pilot.
4. Genera una **password database forte** e salvala **solo** nel tuo password manager.
5. **Non** scriverla mai in Android Studio, in `local.properties`, su Git o dentro l'APK.
6. Aspetta che il database risulti "pronto".

Tieni DEV separato da qualsiasi futuro ambiente di produzione.

---

## 3. Esegui le migration SQL (una alla volta, in ordine)

Apri **SQL Editor → New query**. Esegui i file **uno per volta**, in **quest'ordine esatto**. Non incollarli tutti insieme: se qualcosa fallisce, vuoi sapere esattamente dove.

### 3.1 — `0001_extensions.sql`

Assicura le estensioni PostgreSQL nello schema `extensions`:

```
postgis
pg_trgm
```

Se fallisce, **fermati** e controlla in *Database → Extensions*. Su un progetto DEV appena creato, esegui questo file **come prima operazione** e non installare PostGIS manualmente in un altro schema.

### 3.2 — `0002_schema.sql`

Crea le tabelle e gli enum del contratto V1:

```
Tabelle: restaurants, restaurant_live_status, restaurant_users,
         restaurant_claims, status_history
Enum:    partnership_status, live_status, restaurant_user_role, claim_status
```

Regole già scolpite nel database: TTL LIVE 30 min · `available_tables` 0–99 · `estimated_wait_minutes` 0–240 · `note` ≤ 80 caratteri · `FULL` ⇒ `available_tables IS NULL` · `phone_public=true` richiede un numero.

Se dà errore, **fermati prima di 0003** e conserva il messaggio completo.

### 3.3 — `0003_functions.sql`

Crea le funzioni RPC, tra cui l'unica usata davvero dall'app in Step 7:

```
nearby_restaurants(lat, long, radius_meters, search_text)
```

Usa PostGIS, ordina per distanza, esclude i `SUSPENDED`, restituisce il telefono solo se pubblico, espone gli stati `AVAILABLE/LIMITED/FULL` e lascia che l'app derivi `DA AGGIORNARE` dalla scadenza. Normalizza il raggio a **massimo 100 km**.

### 3.4 — `0004_rls_and_grants.sql`

Attiva la sicurezza: abilita **RLS** sulle tabelle, revoca i privilegi client preesistenti, ri-concede solo il minimo, rende la directory **pubblicamente leggibile** e riserva la scrittura LIVE al ruolo `authenticated` (che userai dallo Step 8–9 in poi).

> RLS e GRANT sono due livelli diversi. Non basta vedere "RLS enabled": questa migration ricostruisce i grant in modo minimo.

### 3.5 — NON eseguire `0005_realtime_future.sql`

È riservato allo **Step 10** (Realtime). Lascialo stare.

---

## 4. Carica i dati demo (seed)

Esegui:

```
900_example_fictional_data.sql
```

Inserisce **attività inventate** che coprono tutti i casi: C'È POSTO, POCHI POSTI, COMPLETO, stato scaduto (DA AGGIORNARE), NON COLLEGATO, con esempi a Pesaro, Fano e Urbino. Usa UUID deterministici, quindi puoi rilanciarlo in DEV senza duplicare i ristoranti principali.

---

## 5. Verifica il database (smoke test SQL)

Prima di toccare Android, esegui:

```
step7_manual_smoke.sql
```

Controlla che:

- compaiano le estensioni `postgis` e `pg_trgm`;
- le cinque tabelle abbiano `rls_enabled = true`;
- la query geo su Pesaro restituisca i ristoranti **ordinati per distanza**;
- la ricerca `search_text='levante'` restituisca **Osteria Levante Demo**;
- risulti `invalid_full_rows = 0`.

Se anche solo uno di questi controlli non passa, **sistema Supabase prima** di collegare l'app.

---

## 6. Recupera URL e chiave pubblica

Vai su **Connect** oppure **Settings → API Keys** e copia **solo**:

```
Project URL
Publishable key   (inizia con  sb_publishable_)
```

**Mai** usare in Android: `sb_secret_...`, `service_role`, password database, JWT signing secret, token admin. L'app **rifiuta** volutamente una chiave che non inizia con `sb_publishable_`.

---

## 7. Configura Android (`local.properties`)

Nella **root** del progetto apri `local.properties`. Se esiste già una riga `sdk.dir=...`, **non toccarla**. Aggiungi in fondo, **senza virgolette**:

```properties
SUPABASE_URL=https://TUO_PROJECT_REF.supabase.co
SUPABASE_PUBLISHABLE_KEY=sb_publishable_LA_TUA_CHIAVE
```

`local.properties` è escluso da Git (c'è `local.properties.example` come modello).

**Come capire in quale modalità sei:**

| Cosa vedi in Home | Significato |
|---|---|
| `DEMO` · `fallback locale` | nessuna variabile Supabase letta |
| `SUPABASE DEV` · `Pesaro e provincia · Supabase DEV` | letto dal backend |
| errore esplicito | configurazione parziale/errata (non nascosta) |

---

## 8. Genera il Gradle Wrapper

Il pacchetto include `gradle-wrapper.properties` ma **non** il binario `gradle-wrapper.jar` (limite dell'ambiente che genera gli ZIP, **non** un errore del codice).

**Percorso consigliato:** installa Gradle 9.5.0 sul PC, apri un terminale nella root del progetto ed esegui **una volta**:

```
gradle wrapper --gradle-version 9.5.0
```

Devono comparire: `gradle/wrapper/gradle-wrapper.jar`, `gradle/wrapper/gradle-wrapper.properties`, `gradlew`, `gradlew.bat`. Da qui in poi usa il wrapper standard.

---

## 9. Sync, build, test

1. **Apri** in Android Studio la cartella del modulo app (non lo ZIP, non una cartella superiore con altri step).
2. **Gradle JDK 17**: *Settings → Build, Execution, Deployment → Build Tools → Gradle → Gradle JDK = 17*.
3. **Sync**: *File → Sync Project with Gradle Files*. Al primo sync scarica `supabase-kt 3.7.0`, `postgrest-kt`, `Ktor OkHttp 3.5.2`. Atteso: nessun errore rosso. Se fallisce, **non abbassare le versioni**: copia il primo errore e vai alla sezione 11.
4. **Build**: *Build → Make Project*. Per l'APK debug: *Build → Build APK(s)* oppure `./gradlew assembleDebug` (`gradlew.bat assembleDebug` su Windows).
5. **Unit test**: `app/src/test` → Run Tests (o `gradlew.bat testDebugUnitTest`). Devono restare verdi TTL, Haversine, search/filter, contratto repository locale, access shell, acceptance pre-backend, AvailabilityRules e configurazione Supabase.
6. **Instrumentation** (device/emulatore collegato): `app/src/androidTest` → Run All (o `gradlew.bat connectedDebugAndroidTest`).

---

## 10. Collaudo sull'app (checklist)

Consigliato: device/emulatore moderno (API 35+), rete attiva, localizzazione disponibile, app reinstallata pulita.

- **Al primo avvio** compare l'**onboarding** (3 schermate). "Salta"/"Inizia" lo chiude e non riappare. *(novità 7.5)*
- **Connessione backend**: Home mostra `SUPABASE DEV` e i nomi del seed (Osteria Levante Demo, Porto 46 Demo, …). Se vedi `fallback locale`, le proprietà non sono state lette → Sync + *Clean Project* + *Rebuild Project*.
- **PostGIS / aree**: cambiando area (Pesaro → Fano → Urbino → Gabicce Mare) la lista si ricarica e le **distanze cambiano**. Raggio DEV: 60 km.
- **Posizione dispositivo**: prova posizione precisa, approssimativa, permesso negato e (se possibile) negato permanente + apertura Impostazioni.
- **Freschezza**: `Casa Miralfiore Demo` ha uno stato scaduto → deve risultare **DA AGGIORNARE**, non C'È POSTO. Controllo cruciale di fiducia.
- **Telefono pubblico**: nel dettaglio di `Osteria Levante Demo` compare **Chiama**; altri record senza telefono pubblico no. (Numeri fittizi: non chiamare.)
- **Offline**: disattiva rete → banner offline; riattiva + Riprova → la directory torna.
- **Barra inferiore** *(novità 7.5)*: Vicino / Preferiti / Ristoratore. "Preferiti" mostra il teaser Plus; "Ristoratore" apre il flusso di accesso.
- **Ristoratore (resta demo in Step 7)**: dopo l'approvazione demo, modificando uno stato **cambia nell'app** (overlay in RAM) ma **NON** cambia `restaurant_live_status` su Supabase. Chiudendo e riaprendo l'app il valore torna quello del database. È corretto: la scrittura reale arriva allo Step 9.

---

## 11. Problemi comuni e soluzioni

**`Gradle executable not found`** — manca `gradle-wrapper.jar`. Installa Gradle 9.5.0 e lancia `gradle wrapper --gradle-version 9.5.0`, poi usa `gradlew`.

**Sync fallisce su Supabase/Ktor** — controlla internet, Maven Central non bloccato, JDK 17, nessun proxy aziendale che intercetti TLS, version catalog non modificato. Non abbassare le versioni prima di salvare il messaggio originale.

**Home mostra `fallback locale`** — il build non ha ricevuto le due proprietà. Verifica che `local.properties` sia nella stessa root di `settings.gradle.kts`/`build.gradle.kts`/`app/`, poi Sync + Clean + Rebuild.

**`Configurazione Supabase incompleta`** — hai messo solo una delle due proprietà. Mettile entrambe, oppure toglile entrambe per tornare al demo.

**`SUPABASE_PUBLISHABLE_KEY non valida`** — serve la chiave nuova `sb_publishable_...`. Se vedi solo chiavi legacy, crea la publishable key in *API Keys*.

**`Serializer for class ... not found`** — assicurati che il plugin `kotlin.plugin.serialization` sia applicato e che i DTO abbiano `@Serializable`. Non rimuovere il plugin.

**HTTP 401 / API key error** — Project URL dello **stesso** progetto della key, nessuno spazio finale, chiave completa e non-secret, e rifai il build dopo aver modificato `local.properties`.

**HTTP/DB `42501` / permission denied** — problema GRANT/RLS. Riesegui i controlli read-only di `step7_manual_smoke.sql` e verifica che `0004_rls_and_grants.sql` sia finito senza errori. Non disabilitare RLS come scorciatoia.

**Lista vuota ma il seed esiste** — controlla `nearby_restaurants` nello smoke, coordinate del seed, PostGIS nello schema atteso, `partnership_status` non `SUSPENDED`, raggio 60 km rispetto all'area scelta.

**PostGIS: tipo/funzione non trovata in `extensions`** — installazione in schema diverso. Su DEV pulito, `0001_extensions.sql` va eseguito per primo.

**`DA AGGIORNARE` non compare** — controlla `valid_until`: lo stato è scaduto quando `now >= valid_until`. Il seed crea apposta un record scaduto.

**Dashboard manager non modifica Supabase** — è corretto in Step 7 (overlay RAM). La scrittura reale arriva con Auth/claim (Step 8) e RPC autenticate (Step 9).

---

## Cosa mandarmi se qualcosa si rompe

1. Screenshot del **primo** errore rosso.
2. Testo completo del *Build Output*.
3. Nome file + numero riga.
4. Se runtime: Logcat da `FATAL EXCEPTION` fino all'ultimo `Caused by`.
5. Se Supabase: messaggio HTTP/PostgREST **oscurando le chiavi**.
6. In quale fase avviene: Sync, compile, install, startup o richiesta Supabase.

Non inviare mai `sb_secret_*`, `service_role` o password del database.
