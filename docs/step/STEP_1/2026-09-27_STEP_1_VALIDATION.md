# HAPOSTO — STEP 1 validation report

**Data:** 24 agosto 2026

## Controlli eseguiti nel pacchetto

- struttura progetto derivata dallo Step 0;
- verifica presenza `build.gradle.kts` root/app e version catalog;
- verifica XML delle risorse/manifest;
- compilazione isolata con `kotlinc` dei modelli e use-case puri di dominio;
- verifica che i dati fake non usino foto/loghi/recensioni;
- ricerca di pattern tipici di secret privilegiati;
- verifica che Supabase non venga invocato dal flusso UI Step 1;
- verifica presenza SQL e documentazione, lasciati inattivi;
- verifica ZIP finale con test CRC.

## Limite dell'ambiente di build

L'ambiente usato per generare il pacchetto non dispone di Android SDK/Gradle installati come toolchain completa, quindi non è stato possibile eseguire qui `assembleDebug` dell'intera app Android.

Sono stati invece verificati i file di dominio Kotlin indipendenti da Android. Il progetto va quindi aperto in Android Studio e sottoposto a Gradle Sync/build locale, come previsto dalle istruzioni.

## Gradle Wrapper

Lo scaffold conserva la modalità dello Step 0:

- `gradle/wrapper/gradle-wrapper.properties` punta a Gradle 9.5.0;
- `gradlew` / `gradlew.bat` usano un'installazione Gradle disponibile;
- non è incluso un `gradle-wrapper.jar` binario non verificato.

Android Studio può scaricare/usare la distribuzione configurata; se si desidera il wrapper CLI standard, eseguire una sola volta in un ambiente con Gradle 9.5.0:

```bash
gradle wrapper --gradle-version 9.5.0
```

Poi committare i wrapper file ufficialmente generati.
