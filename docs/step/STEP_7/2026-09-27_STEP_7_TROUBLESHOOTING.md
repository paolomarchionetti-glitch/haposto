# HAPOSTO — STEP 7 troubleshooting

## 1. `Gradle executable not found`

Causa: lo ZIP non contiene l'official `gradle-wrapper.jar`.

Soluzione:

```text
installa/scarica Gradle 9.5.0
cd HaPosto
gradle wrapper --gradle-version 9.5.0
```

Poi usa `gradlew.bat` / `./gradlew` standard.

---

## 2. Sync fallisce sulle dipendenze Supabase/Ktor

Controlla:

- internet;
- Maven Central non bloccato;
- JDK 17;
- nessun proxy aziendale che intercetti TLS;
- version catalog non modificato.

Versioni Step 7:

```text
supabase-kt 3.7.0
Ktor 3.5.2
```

Non abbassare versioni casualmente prima di salvare il messaggio originale.

---

## 3. Home mostra `fallback locale`

Il build non ha ricevuto le due proprietà.

Controlla che `local.properties` sia nella stessa root di:

```text
settings.gradle.kts
build.gradle.kts
app/
```

E che contenga:

```properties
SUPABASE_URL=https://PROJECT.supabase.co
SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
```

Poi Sync + Clean/Rebuild.

---

## 4. `Configurazione Supabase incompleta`

Hai compilato con una sola delle due proprietà.

Aggiungi sia URL sia publishable key, oppure rimuovi entrambe per tornare esplicitamente al fallback demo.

---

## 5. `SUPABASE_PUBLISHABLE_KEY non valida`

Step 7 richiede la nuova chiave:

```text
sb_publishable_...
```

Non usare:

```text
sb_secret_...
service_role
```

Se hai un progetto legacy e vedi soltanto le vecchie chiavi, crea la nuova publishable key nel pannello API Keys.

---

## 6. `Serializer for class ... not found`

Verifica che:

```text
org.jetbrains.kotlin.plugin.serialization
```

sia applicato e che i DTO Supabase abbiano `@Serializable`.

Non rimuovere il plugin serialization dallo Step 7.

---

## 7. HTTP 401 / API key error

Controlla:

- Project URL dello stesso progetto da cui hai copiato la key;
- nessuno spazio finale;
- publishable key completa;
- non hai copiato una secret key;
- hai rifatto build dopo la modifica di `local.properties`.

---

## 8. HTTP/DB `42501` / permission denied

Possibile problema GRANT/RLS.

Riesegui prima i controlli read-only di:

```text
supabase/tests/step7_manual_smoke.sql
```

Non disabilitare RLS come scorciatoia.

Controlla che `0004_rls_and_grants.sql` sia terminato senza errori.

---

## 9. La query restituisce lista vuota ma il seed esiste

Controlla:

1. `step7_manual_smoke.sql` query `nearby_restaurants`;
2. coordinate del seed;
3. PostGIS installato nello schema atteso;
4. `partnership_status` non `SUSPENDED`;
5. raggio 60 km rispetto all'area selezionata.

---

## 10. PostGIS: tipo/funzione non trovata in `extensions`

Probabile installazione PostGIS in schema differente.

Su un progetto DEV appena creato, usa `0001_extensions.sql` come prima operazione e non installare PostGIS manualmente in un altro schema prima della migration.

---

## 11. `nearby_restaurants` non esiste / signature mismatch

Step 7 usa la firma:

```text
nearby_restaurants(
  double precision,
  double precision,
  integer,
  text
)
```

Assicurati di avere eseguito la versione Step 7 di `0003_functions.sql` e `0004_rls_and_grants.sql`.

---

## 12. `DA AGGIORNARE` non compare

Controlla `valid_until` nel database. Lo stato è stale quando:

```text
now >= valid_until
```

Il seed crea intenzionalmente un record scaduto.

---

## 13. Dashboard manager non modifica Supabase

È corretto nello Step 7.

La scrittura reale richiede:

```text
STEP 8 → Auth/claim
STEP 9 → authenticated RPC writes
```

Step 7 usa un overlay RAM per non fingere autorizzazioni production.

---

## 14. Offline banner ma risultati ancora visibili

Può essere normale se la schermata conserva l'ultimo snapshot già caricato nella composizione/processo. Non presentarlo come conferma di freshness server.

Il comportamento production verrà raffinato quando avremo cache/network policy definitive.

---

## 15. Errori da mandare per diagnosi

Invia sempre il **primo errore causale**, non soltanto gli ultimi 50 errori a cascata.

Per Gradle/compile: Build Output completo.

Per runtime: Logcat con:

```text
FATAL EXCEPTION
...
Caused by:
```

Per Supabase: messaggio PostgREST/HTTP senza chiavi o password.
