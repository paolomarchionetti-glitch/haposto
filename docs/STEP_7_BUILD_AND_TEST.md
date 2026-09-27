# HAPOSTO — STEP 7: Gradle Sync, Build e testing sul tuo PC

Obiettivo: dopo il setup Supabase, ottenere il primo **build Android reale** e raccogliere eventuali errori da correggere nello step successivo.

---

# 1. Apri il progetto corretto

In Android Studio:

```text
File → Open
```

Seleziona la cartella:

```text
HaPosto/
```

non lo ZIP e non la cartella superiore che contiene altri step.

---

# 2. Controlla JDK Gradle

Apri:

```text
File/Settings
→ Build, Execution, Deployment
→ Build Tools
→ Gradle
```

Imposta Gradle JDK su JDK 17.

Il progetto usa AGP 9.3.0 e punta a Gradle 9.5.0.

---

# 3. Nota importante sul Gradle Wrapper del pacchetto

Il pacchetto conserva `gradle-wrapper.properties`, ma l'ambiente che genera questi ZIP non è riuscito a recuperare il binario ufficiale `gradle-wrapper.jar`.

Quindi **non interpretare l'assenza del JAR come un errore del codice HAPOSTO**.

Prima del primo build hai due possibilità.

## Percorso consigliato: genera una volta il wrapper standard

1. Scarica/installare Gradle 9.5.0 sul PC.
2. Apri un terminale nella root `HaPosto/`.
3. Esegui:

```text
gradle wrapper --gradle-version 9.5.0
```

Dopo il comando devono esistere:

```text
gradle/wrapper/gradle-wrapper.jar
gradle/wrapper/gradle-wrapper.properties
gradlew
gradlew.bat
```

Da quel momento usa il wrapper standard.

## Alternativa

Configura temporaneamente Android Studio per usare una installazione locale Gradle 9.5.0 e poi genera comunque il wrapper standard appena possibile.

---

# 4. Gradle Sync

Dopo aver sistemato il wrapper:

```text
File → Sync Project with Gradle Files
```

oppure usa il comando/icone di Sync dell'IDE.

Durante il primo sync verranno scaricate le dipendenze, fra cui:

```text
supabase-kt BOM 3.7.0
postgrest-kt
Ktor OkHttp 3.5.2
```

### Risultato atteso

Nessun errore Gradle rosso.

Se fallisce, **non modificare versioni a caso**. Copia il primo errore completo e consulta `STEP_7_TROUBLESHOOTING.md`.

---

# 5. Build debug

Quando Sync è verde:

```text
Build → Make Project
```

Poi, se vuoi produrre esplicitamente l'APK debug:

```text
Build → Build App Bundle(s) / APK(s) → Build APK(s)
```

oppure da terminale, dopo aver creato il wrapper standard:

```text
./gradlew assembleDebug
```

Windows:

```text
gradlew.bat assembleDebug
```

---

# 6. Unit test

Da Android Studio:

```text
app/src/test
→ tasto destro
→ Run Tests
```

Oppure:

```text
gradlew.bat testDebugUnitTest
```

I test locali devono continuare a coprire:

- TTL;
- Haversine;
- search/filter;
- local repository contract;
- access shell;
- pre-backend acceptance loop;
- AvailabilityRules;
- configurazione Supabase Step 7.

---

# 7. Avvia su emulatore/device

Consigliato per il primo test:

- dispositivo Android moderno / API 35+;
- rete attiva;
- localizzazione disponibile;
- app reinstallata pulita se arrivi da build precedenti.

Premi `Run app`.

---

# 8. Test A — verifica connessione Supabase

Con `local.properties` configurato correttamente, Home deve mostrare:

```text
SUPABASE DEV
Pesaro e provincia · Supabase DEV
```

Devono apparire i nomi del seed:

```text
Osteria Levante Demo
Porto 46 Demo
Corte Adriatica Demo
...
```

Se invece vedi:

```text
DEMO
fallback locale
```

le proprietà non sono state lette in fase di build. Controlla `local.properties`, poi fai:

```text
Sync
Build → Clean Project
Build → Rebuild Project
```

---

# 9. Test B — PostGIS / aree manuali

Dalla Home seleziona in sequenza:

```text
Pesaro
Fano
Urbino
Gabicce Mare
```

Aspettative:

- la lista viene ricaricata dal backend;
- le distanze cambiano;
- Fano avvicina `Linea Cucina Demo`;
- Urbino avvicina `Civico Zero Demo`.

La query RPC usa un raggio DEV di 60 km.

---

# 10. Test C — posizione dispositivo

Premi:

```text
USA LA MIA POSIZIONE
```

Testa almeno:

1. posizione precisa concessa;
2. posizione approssimativa concessa;
3. permesso negato;
4. se possibile, permesso negato permanentemente + apertura Impostazioni.

Con Supabase attivo, la Home deve spiegare che le coordinate vengono usate come parametro RPC ma non salvate nelle tabelle HAPOSTO.

---

# 11. Test D — search/filter

Cerca:

```text
levante
pesce
vegetariana
```

Poi prova:

```text
Tutti
C'è posto
Pochi posti
Live
```

Lo Step 7 mantiene il filtro UI locale sullo snapshot geografico. Il database ha già anche il supporto `search_text` verificabile via smoke SQL.

---

# 12. Test E — freshness

Nel seed:

```text
Casa Miralfiore Demo
```

ha uno stato già scaduto.

In UI deve risultare:

```text
DA AGGIORNARE
```

non `C'È POSTO`.

Questo è un controllo cruciale di trust.

---

# 13. Test F — telefono pubblico

`Osteria Levante Demo` ha un telefono pubblico di test.

Apri il dettaglio e verifica che compaia:

```text
CHIAMA
```

Altri record senza telefono pubblico non devono mostrare il pulsante.

Non effettuare una chiamata reale: i numeri del seed sono fittizi.

---

# 14. Test G — offline/rete

Con app aperta:

1. disattiva Wi-Fi/dati;
2. torna alla Home o premi `RIPROVA`;
3. verifica banner offline/error handling;
4. riattiva rete;
5. premi `RIPROVA`.

La directory Supabase deve tornare caricabile.

---

# 15. Test H — area ristoratore Step 7

Il flusso ristoratore resta volutamente demo:

```text
Sei un ristoratore?
→ Google DEMO
→ claim demo
→ approvazione demo
→ dashboard
```

Dopo approvazione, modifica uno stato.

Deve cambiare nell'app perché Step 7 applica un overlay RAM sul record letto da Supabase.

### Controllo fondamentale

Apri Supabase Dashboard e verifica che `restaurant_live_status` **NON sia stato modificato** dalla dashboard Android.

È il comportamento corretto dello Step 7.

---

# 16. Test I — chiusura processo

Dopo una modifica manager locale:

1. chiudi completamente l'app;
2. termina il processo;
3. riaprila.

Il valore deve tornare a quello presente nel database Supabase.

Questo prova che la scrittura manager Step 7 è realmente RAM-only.

---

# 17. Instrumentation test Compose

Con emulatore/device collegato:

```text
app/src/androidTest
→ Run All Tests
```

Oppure:

```text
gradlew.bat connectedDebugAndroidTest
```

---

# 18. Cosa mandarmi se trovi un errore

Per lo step successivo invia, idealmente:

1. screenshot del primo errore rosso;
2. testo completo da `Build Output`;
3. nome file + numero riga;
4. se è runtime, stack trace Logcat dall'inizio di `FATAL EXCEPTION` fino a `Caused by` finale;
5. se è Supabase, HTTP/status/error message ma **oscura eventuali chiavi**;
6. dimmi se l'errore avviene in Sync, compile, install, startup o richiesta Supabase.

Non inviare mai `sb_secret_*`, `service_role` o password database.
