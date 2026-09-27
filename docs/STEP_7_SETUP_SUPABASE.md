# HAPOSTO — STEP 7: setup Supabase DEV dettagliato

Questa guida porta un progetto HAPOSTO Step 7 da **ZIP appena estratto** a **directory letta realmente da Supabase**.

> STEP 7 collega solo il lato pubblico/consumer al database. Google Auth, claim reale e scrittura LIVE autenticata arrivano rispettivamente negli Step 8–9.

---

## 0. Prima di iniziare

Occorre:

- Android Studio con Android SDK installato;
- JDK 17 per Gradle/AGP;
- connessione internet;
- account Supabase;
- questo progetto Step 7 estratto in una cartella scrivibile.

Versioni del progetto Step 7:

```text
AGP                 9.3.0
Gradle target       9.5.0
JDK                 17
Kotlin              2.4.10
Supabase Kotlin     3.7.0
Ktor                3.5.2
minSdk              26
compile/targetSdk   37
```

---

# PARTE A — Creare il progetto Supabase

## 1. Crea un progetto DEV dedicato

1. Accedi a Supabase Dashboard.
2. Crea un nuovo progetto nell'organizzazione desiderata.
3. Nome consigliato: `haposto-dev`.
4. Scegli una regione europea vicina agli utenti del pilot, se disponibile.
5. Genera una password database forte.
6. Salvala in un password manager.
7. **Non copiarla mai in Android Studio, `local.properties`, Git o nell'APK.**
8. Attendi che il database risulti pronto.

Per Step 7 è consigliato un progetto DEV separato da qualunque futuro ambiente production.

---

# PARTE B — Creare schema e funzioni

## 2. Apri SQL Editor

Nel progetto Supabase:

```text
Dashboard
→ SQL Editor
→ New query
```

Esegui i file **uno per volta e in questo ordine**.

Non incollare tutti i file insieme: se uno fallisce, è molto più facile sapere dove si è fermato il setup.

## 3. Migration 0001 — estensioni

Apri localmente:

```text
supabase/migrations/0001_extensions.sql
```

Copia tutto → incolla nel SQL Editor → `Run`.

Deve creare/assicurare:

```text
postgis
pg_trgm
```

HAPOSTO utilizza lo schema `extensions` per i tipi/funzioni di queste estensioni.

### Se 0001 fallisce

Non continuare con 0002.

Controlla in:

```text
Database → Extensions
```

Se PostGIS era stato installato manualmente in uno schema differente su questo progetto DEV, il percorso più semplice in questa fase è usare un progetto DEV pulito oppure riallineare consapevolmente gli SQL. Non improvvisare cambi di schema a metà setup.

---

## 4. Migration 0002 — schema V1

Esegui:

```text
supabase/migrations/0002_schema.sql
```

Crea:

```text
restaurants
restaurant_live_status
restaurant_users
restaurant_claims
status_history
```

e gli enum:

```text
partnership_status
live_status
restaurant_user_role
claim_status
```

Le regole importanti sono già nel database:

```text
TTL concettuale LIVE        30 min
available_tables            0..99
estimated_wait_minutes      0..240
note                        <= 80 caratteri
FULL                        available_tables IS NULL
phone_public=true           richiede phone_number
```

Se 0002 produce un errore, fermati prima di 0003 e conserva il messaggio completo.

---

## 5. Migration 0003 — RPC e PostGIS

Esegui:

```text
supabase/migrations/0003_functions.sql
```

Crea:

```text
is_restaurant_member(...)
set_restaurant_live_status(...)
nearby_restaurants(...)
```

Nello Step 7 Android usa realmente soltanto:

```text
nearby_restaurants(lat, long, radius_meters, search_text)
```

Questa funzione:

- usa PostGIS;
- ordina per distanza;
- esclude `SUSPENDED`;
- restituisce il numero di telefono solo se `phone_public=true`;
- espone gli stati persistiti `AVAILABLE/LIMITED/FULL`;
- lascia che l'app derivi `DA AGGIORNARE` da `valid_until`;
- supporta anche ricerca testuale/fuzzy server-side tramite `search_text`;
- normalizza il raggio richiesto e lo limita a massimo **100 km**.

Nello Step 7 la Home scarica il normale snapshot geografico e applica ancora ricerca/filtri localmente per non rompere il contratto V1. Il parametro `search_text` viene verificato nello smoke SQL ed è già pronto per un pushdown completo futuro.

---

## 6. Migration 0004 — RLS e grant

Esegui:

```text
supabase/migrations/0004_rls_and_grants.sql
```

Questa migration:

1. abilita RLS sulle tabelle;
2. revoca i privilegi client preesistenti;
3. ri-concede solo i privilegi necessari;
4. rende la directory pubblicamente leggibile;
5. non concede scritture dirette al LIVE status;
6. concede l'RPC LIVE solo al ruolo `authenticated`, che useremo più avanti.

### Importante

RLS e GRANT sono due livelli diversi. Non considerare una tabella sicura soltanto perché `RLS enabled` compare nel Dashboard: Step 7 revoca esplicitamente i grant client e li ricostruisce in modo minimo.

---

## 7. NON eseguire 0005

Non eseguire:

```text
supabase/migrations/0005_realtime_future.sql
```

È riservato allo **Step 10**.

---

# PARTE C — Caricare dati DEV

## 8. Esegui il seed fittizio

Per vedere subito dati nell'app esegui:

```text
supabase/seeds/900_example_fictional_data.sql
```

Contiene solo attività inventate.

Inserisce esempi di:

- C'È POSTO;
- POCHI POSTI;
- COMPLETO;
- stato scaduto / DA AGGIORNARE;
- NON COLLEGATO;
- Pesaro;
- Fano;
- Urbino.

Il seed usa UUID deterministici e può essere rilanciato in DEV senza duplicare i ristoranti principali.

---

# PARTE D — Verificare il database prima di Android Studio

## 9. Smoke test SQL

Apri:

```text
supabase/tests/step7_manual_smoke.sql
```

Copia tutto nel SQL Editor e premi `Run`.

Controlla in particolare:

### Estensioni

Devono comparire:

```text
postgis
pg_trgm
```

### RLS

Le cinque tabelle devono riportare:

```text
rls_enabled = true
```

### Geo RPC

La query su Pesaro deve restituire i ristoranti seed ordinati per distanza.

### Ricerca

La query `search_text='levante'` deve restituire `Osteria Levante Demo`.

### FULL constraint

Deve risultare:

```text
invalid_full_rows = 0
```

Se questi controlli non passano, correggi Supabase **prima** di collegare Android.

---

# PARTE E — Recuperare Project URL e publishable key

## 10. Apri Connect

Nel progetto Supabase usa il pannello:

```text
Connect
```

oppure:

```text
Settings → API Keys
```

Servono soltanto:

```text
Project URL
Publishable key
```

La publishable key moderna inizia con:

```text
sb_publishable_
```

### NON usare mai in Android

```text
sb_secret_...
service_role
password database
JWT signing secret
access token amministrativi
```

Lo Step 7 rifiuta volutamente una chiave che non inizia con `sb_publishable_`.

---

# PARTE F — Configurare Android localmente

## 11. Non sovrascrivere `sdk.dir`

Android Studio normalmente crea/usa un file:

```text
local.properties
```

Questo file può già contenere qualcosa come:

```properties
sdk.dir=C\:\\Users\\TUO_NOME\\AppData\\Local\\Android\\Sdk
```

**Non cancellarlo.**

Apri `local.properties` nella root del progetto e aggiungi in fondo:

```properties
SUPABASE_URL=https://TUO_PROJECT_REF.supabase.co
SUPABASE_PUBLISHABLE_KEY=sb_publishable_LA_TUA_CHIAVE
```

Niente virgolette.

Il modello è:

```text
local.properties.example
```

`local.properties` è escluso da Git.

---

## 12. Come capire quale modalità è attiva

### Nessuna variabile Supabase

L'app parte con:

```text
DEMO
fallback locale
```

### URL + publishable key validi

La Home mostra:

```text
SUPABASE DEV
Pesaro e provincia · Supabase DEV
```

I ristoranti vengono letti dal progetto Supabase.

### Configurazione parziale/errata

La Home mostra un errore esplicito invece di nascondere il problema dietro al fallback.

---

# PARTE G — Privacy posizione Step 7

Con fallback locale:

```text
coordinate dispositivo → RAM del telefono → Haversine locale
```

Con Supabase configurato:

```text
coordinate dispositivo/manual area
→ parametro RPC nearby_restaurants
→ PostGIS
→ risultati ordinati
```

HAPOSTO Step 7 **non inserisce la posizione consumer in una tabella**.

Le coordinate vengono però necessariamente trasmesse via HTTPS a Supabase come parametri della richiesta geo. Per questo il copy privacy della Home è stato aggiornato rispetto agli Step 2–6.

---

# PARTE H — Cosa resta volutamente demo

Anche con `SUPABASE DEV` attivo:

```text
consumer directory      REAL Supabase
PostGIS                  REAL Supabase
RLS lettura              REAL Supabase
network errors           REAL

Google login             DEMO LOCALE
claim                    DEMO LOCALE
admin approval           DEMO LOCALE
manager LIVE write       RAM-ONLY OVERLAY
phone toggle manager     RAM-ONLY OVERLAY
Realtime                 OFF
```

Quindi non aspettarti che premere `COMPLETO` nella dashboard modifichi `restaurant_live_status` nel Dashboard Supabase: quella scrittura arriva allo Step 9.
