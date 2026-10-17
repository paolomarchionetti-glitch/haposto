# MODIFICA — STEP 0 / Fondazione progetto

**Versione app:** `0.0.1-step0`  
**Data:** 24 agosto 2026

## Obiettivo dello step

Creare una base Android Studio pulita e importabile senza introdurre ancora logica di prodotto reale o dipendenza operativa da Supabase.

## Cosa è stato aggiunto

### Build

- progetto Gradle Kotlin DSL;
- root `build.gradle.kts`;
- `app/build.gradle.kts`;
- version catalog `gradle/libs.versions.toml`;
- AGP 9.3.0;
- Gradle target 9.5.0;
- Kotlin / Compose compiler 2.4.10;
- Compose BOM 2026.08.00;
- compile/target SDK 37;
- minSdk 26;
- Java/JVM 17.

### Android

- package `it.haposto.app`;
- `MainActivity`;
- shell Compose `HaPostoApp`;
- prima schermata `FoundationScreen`;
- tema visivo iniziale;
- icona provvisoria H minimale;
- permesso `INTERNET` già predisposto.

### Backend predisposto

- dipendenze Supabase `3.7.0`;
- PostgREST;
- Auth;
- Realtime;
- Ktor OkHttp `3.5.2` per compatibilità WebSocket futura;
- `SupabaseClientProvider`, intenzionalmente non utilizzato nello Step 0;
- configurazione da `local.properties`, mai hardcoded.

### Database predisposto ma NON attivato

Sono presenti SQL versionati per:

1. PostGIS + pg_trgm;
2. schema ristoranti/status/claim/membership/history;
3. RPC geospaziale e aggiornamento status;
4. RLS + grants;
5. Realtime futuro;
6. seed puramente fittizio.

**Non eseguire alcun SQL adesso.**

## Cosa NON è stato implementato

- lista vera dei ristoranti;
- navigazione tra schermate;
- posizione utente;
- query Supabase;
- login Google;
- claim ristorante;
- aggiornamento live;
- notifiche;
- pagamenti;
- mappa incorporata;
- foto;
- analytics.

È intenzionale.

## Istruzioni dopo aver aperto il progetto

1. Apri `HaPosto` in Android Studio.
2. Fai completare Gradle Sync.
3. Installa API 37 se richiesto.
4. Avvia l'app su un emulatore/dispositivo API 26+.
5. Devi vedere la schermata “Step 0 · Fondazione”.
6. **Non aggiungere ancora valori Supabase.**
7. Non eseguire gli SQL.

## Se Android Studio segnala il wrapper CLI

Il pacchetto include `gradle-wrapper.properties` ma non un JAR binario esterno. Android Studio può usare la configurazione. Per ricreare il wrapper CLI ufficiale, esegui una volta:

```bash
gradle wrapper --gradle-version 9.5.0
```

## Successivo step preannunciato — STEP 1

### “Consumer UI locale / dati fake”

Nel prossimo pacchetto costruiremo la prima esperienza reale senza backend:

- Home/List consumer HAPOSTO;
- 8–10 ristoranti **fittizi** hardcoded;
- card professionali senza foto;
- stati `C'È POSTO`, `POCHI POSTI`, `COMPLETO`, `DA AGGIORNARE`, `NON COLLEGATO`;
- timestamp e logica TTL locale;
- ricerca per nome;
- filtri minimi;
- schermata dettaglio ristorante;
- prima navigazione Compose;
- test della logica di freschezza.

Lo scopo dello Step 1 è fissare UX e modello UI **prima** di collegare Supabase.

## Step 2 già previsto

Dopo approvazione dello Step 1:

- creazione progetto Supabase Free;
- esecuzione SQL `0001` → `0004`;
- configurazione publishable key locale;
- lettura reale directory da Postgres;
- sostituzione repository fake con repository Supabase.
