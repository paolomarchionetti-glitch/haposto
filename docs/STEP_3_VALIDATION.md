# HAPOSTO — STEP 3 Validation

**Data:** 24 agosto 2026

## Validazioni eseguite nell'ambiente di generazione

### Core Kotlin

Compilati con `kotlinc`:

- `domain/model/*`;
- `domain/usecase/*`;
- `RestaurantRepository.kt`;
- `FakeRestaurantRepository.kt`.

Esito:

```text
KOTLIN_CORE_OK
```

È stato inoltre eseguito un piccolo programma smoke Kotlin reale contro `FakeRestaurantRepository`. Esito:

```text
STEP3_REPOSITORY_SMOKE_OK
```

### Regole funzionali controllate

- repository condiviso consumer/manager;
- publish consentito solo a `ACTIVE_PARTNER`;
- soli stati `AVAILABLE / LIMITED / FULL` pubblicabili;
- TTL locale = 30 minuti;
- nota max 80 caratteri;
- toggle telefono separato dal timestamp live;
- dettaglio consumer convertito da lookup statico a osservazione del repository.

### XML

Tutti gli XML Android presenti (`AndroidManifest.xml` + risorse) sono stati parsati correttamente:

```text
XML_OK 12 files
```

### SQL Supabase

I file di migration e seed restano quelli ereditati dallo Step 2. È stato modificato soltanto `supabase/README.md` per aggiornare le istruzioni allo Step 3.

### Backend

Confermato:

```text
Supabase runtime = OFF
Auth runtime = OFF
Realtime runtime = OFF
```

Nessuna credenziale reale inserita.

### Persistenza

Lo stato ristoratore rimane soltanto nel `MutableStateFlow` del repository fake.

Non sono stati introdotti:

- Room;
- DataStore;
- SharedPreferences;
- file di stato;
- network write.

## Full Android build

Non è stato possibile eseguire `assembleDebug` nell'ambiente di generazione perché il pacchetto ereditato non contiene `gradle-wrapper.jar` e non è presente una toolchain Android/Gradle completa locale.

Il controllo finale da eseguire in Android Studio rimane:

```text
Gradle Sync
Build > Make Project
Run su emulatore/dispositivo
```

## Checklist manuale raccomandata

- [ ] Home si apre;
- [ ] posizione Step 2 continua a funzionare;
- [ ] `Sei un ristoratore?` apre dashboard;
- [ ] verde aggiorna consumer;
- [ ] arancio aggiorna consumer;
- [ ] rosso aggiorna consumer;
- [ ] timestamp torna a `Aggiornato ora`;
- [ ] dettagli appaiono nel dettaglio consumer;
- [ ] toggle telefono nasconde/mostra `CHIAMA`;
- [ ] stato scade dopo TTL;
- [ ] nessun login viene richiesto;
- [ ] nessuna chiamata Supabase.
