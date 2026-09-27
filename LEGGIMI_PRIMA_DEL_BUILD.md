# LEGGIMI prima del primo build

## 1. Package aggiornato

Tutto il progetto usa ora il package **`com.haposto`** (prima era `it.haposto.app`).
Struttura sorgenti: `app/src/main/java/com/haposto/...`.
`namespace` e `applicationId` in `app/build.gradle.kts` sono `com.haposto`.

## 2. Manca `gradle-wrapper.jar` (normale)

Questo pacchetto include `gradle/wrapper/gradle-wrapper.properties`, `gradlew` e
`gradlew.bat`, ma **non** il binario `gradle-wrapper.jar` (non è includibile qui).
Non è un errore del codice.

**Genera il wrapper una volta**, con Gradle 9.5.0 installato sul PC, nella root del progetto:

```
gradle wrapper --gradle-version 9.5.0
```

In alternativa lascia che Android Studio lo rigeneri all'apertura. Dopodiché usa
`./gradlew` (o `gradlew.bat`) normalmente.

## 3. Configura Supabase

Copia `local.properties.example` in `local.properties` e inserisci
`SUPABASE_URL` e `SUPABASE_PUBLISHABLE_KEY`. Vedi `docs/STEP_7_SETUP_SUPABASE.md`
o la guida `MD1_GUIDA_BUILD_E_SUPABASE.md`.

## 4. JDK 17

Imposta *Gradle JDK = 17* in Android Studio (Settings → Build Tools → Gradle).

## 5. Nota sui test dopo il 7.5

Il 7.5 ha cambiato alcuni testi/struttura della UI (Home, card, navigazione).
- I **test unitari** (dominio/dati: TTL, Haversine, filtri, contratto repository,
  configurazione Supabase) **non sono influenzati**.
- Alcuni **test di strumentazione Compose** (`HomeScreenTest`, ecc.) potrebbero
  cercare testi non più presenti (es. il vecchio pulsante "Sei un ristoratore?"):
  in tal caso vanno aggiornati alle nuove stringhe. Non bloccano l'app.
