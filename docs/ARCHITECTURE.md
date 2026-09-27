# HAPOSTO — Architettura Android STEP 7

## 1. Obiettivo

STEP 7 sostituisce il read path fake consumer con un adapter Supabase reale senza modificare il contratto V1 della UI.

```text
                         RestaurantRepository
                         V1 FROZEN BOUNDARY
                                  │
                   ┌──────────────┴──────────────┐
                   │                             │
             config assente                config valida
                   │                             │
      FakeRestaurantRepository      SupabaseRestaurantRepository
                   │                             │
                   │                    Supabase PostgREST
                   │                             │
                   │                  nearby_restaurants RPC
                   │                             │
                   │                         PostGIS
                   │                             │
                   └──────────────┬──────────────┘
                                  │
                       Home / Detail / Access
```

---

## 2. Configuration modes

### LOCAL_DEMO

Entrambe le proprietà Supabase sono vuote.

```text
AppDependencies → FakeRestaurantRepository
```

### SUPABASE

URL + publishable key validi.

```text
AppDependencies → SupabaseRestaurantRepository
```

### CONFIGURATION_ERROR

Una proprietà manca o il formato non è valido.

```text
ConfigurationErrorRestaurantRepository
→ Home error state
```

Non viene fatto fallback silenzioso.

---

## 3. Supabase client Step 7

Il client installa soltanto:

```text
Postgrest
```

Non installa ancora:

```text
Auth      → Step 8
Realtime  → Step 10
```

Engine HTTP:

```text
Ktor OkHttp 3.5.2
```

Client SDK:

```text
supabase-kt 3.7.0
```

---

## 4. Geo flow

```text
LocationSession
    │
    ├── ManualArea
    └── DeviceLocation foreground
            │
            ▼
SupabaseRestaurantRepository
            │
            ▼
nearby_restaurants(
  lat,
  long,
  radius_meters = 60000,
  search_text = null
)
            │
            ▼
PostGIS ST_DWithin / ST_Distance
            │
            ▼
NearbyRestaurantDto
            │
            ▼
Restaurant domain
```

La posizione del consumer non viene inserita in tabelle HAPOSTO.

---

## 5. Search

La funzione SQL supporta:

```text
search_text
```

con:

- name contains;
- category contains;
- city contains;
- pg_trgm similarity.

Per preservare il contratto V1 e non introdurre query network ad ogni carattere in questo primo wiring, la Home Step 7 continua a fare search/filter sullo snapshot geo ricevuto.

Il supporto server-side viene verificato da `supabase/tests/step7_manual_smoke.sql` ed è pronto per un pushdown completo successivo.

---

## 6. Mapping partnership

Backend:

```text
DIRECTORY_ONLY
CLAIM_PENDING
ACTIVE_PARTNER
PAUSED
SUSPENDED
```

Consumer domain V1:

```text
ACTIVE_PARTNER → ACTIVE_PARTNER
altro visibile → DIRECTORY_ONLY
SUSPENDED → escluso dall'RPC
```

---

## 7. Availability

Backend persiste solo:

```text
AVAILABLE
LIMITED
FULL
```

Il client continua a derivare:

```text
expired/missing ACTIVE_PARTNER → STALE
non-active consumer record     → NOT_CONNECTED
```

V1 invariants condivisi Android/SQL:

```text
TTL                          30 min
available_tables             0..99
estimated_wait_minutes       0..240
note                         <=80
FULL                         available_tables NULL
```

---

## 8. RLS + grants

`0004_rls_and_grants.sql` applica due livelli:

```text
Postgres grants
+
Row Level Security policies
```

Il client anon può leggere la directory e chiamare `nearby_restaurants`.

Non può scrivere direttamente `restaurant_live_status`.

---

## 9. Manager write path Step 7

Auth è ancora fake, quindi un client Step 7 non deve poter scrivere dati commerciali reali.

Per preservare la demo completa:

```text
Supabase backend restaurant
        │
        ▼
manager action
        │
        ▼
RAM-only override map
        │
        ▼
Home / Detail osservano override
```

Dopo process death l'override sparisce e torna il valore Supabase.

Step 9 sostituirà il body write con:

```text
authenticated set_restaurant_live_status RPC
```

---

## 10. Access/claim

Resta:

```text
FakeRestaurantAccessRepository
```

fino allo Step 8.

Quindi:

```text
Google DEMO
claim DEMO
approval DEMO
```

Non rappresentano autenticazione o autorizzazione reale.

---

## 11. Secrets boundary

APK può contenere:

```text
Project URL
sb_publishable_...
```

APK non deve contenere:

```text
sb_secret_...
service_role
DB password
JWT signing secret
admin token
```

La publishable key è identificatore client a basso privilegio; la sicurezza dati dipende da grants/RLS/Auth.

---

## 12. Realtime

OFF.

`0005_realtime_future.sql` non viene eseguito fino allo Step 10.

---

## 13. Build gate

Dopo setup sul PC:

```text
standard Gradle wrapper 9.5.0
→ Gradle Sync
→ Make Project
→ unit tests
→ run device/emulator
→ Supabase smoke
→ instrumentation tests
```

Vedere `STEP_7_BUILD_AND_TEST.md`.
