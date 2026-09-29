# LEGGIMI prima del primo build

## 1. Package aggiornato

Tutto il progetto usa ora il package **`com.haposto`** (prima era `it.haposto.app`).
Struttura sorgenti: `app/src/main/java/com/haposto/...`.
`namespace` e `applicationId` in `app/build.gradle.kts` sono `com.haposto`.

## 2. Gradle wrapper incluso

Il repository contiene il wrapper standard (`gradlew`, `gradlew.bat`,
`gradle/wrapper/gradle-wrapper.jar`) configurato su Gradle 9.5.0: non serve
generarlo. Android Studio lo usa in automatico; da terminale usa `./gradlew`
(o `gradlew.bat` su Windows).

## 3. Configura Supabase e scegli la versione

Copia `local.properties.example` in `local.properties` e compila le chiavi (DEV, poi
produzione, Google, Firebase): istruzioni in `docs/HAPOSTO_GUIDA_CONFIGURAZIONE_COMPLETA.md`.

In Android Studio → *Build Variants* scegli `demoDebug` (nessun server, dati di prova nel
telefono), `devDebug` (Supabase DEV con account veri) o `prodDebug`/`prodRelease` (produzione).
Le tre versioni si installano insieme sullo stesso telefono.

## 4. JDK 21

`gradle/gradle-daemon-jvm.properties` chiede Java 21 per il daemon Gradle.
In Android Studio la JBR inclusa (Java 21) va bene: *Settings → Build Tools →
Gradle → Gradle JDK*. Se manca, Gradle può scaricarla da solo.

## 5. Test

- **Unit test** (`app/src/test`): dominio, dati, parsing Supabase e ViewModel.
  `./gradlew testDemoDebugUnitTest`.
- **Test strumentali Compose** (`app/src/androidTest`): servono un device o un
  emulatore collegato. `./gradlew connectedDemoDebugAndroidTest`.
- La CI GitHub esegue unit test, build e lint a ogni push/PR.
