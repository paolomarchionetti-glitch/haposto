# HAPOSTO — STEP 2
## Posizione reale + distanza locale, senza Supabase

**Data:** 24 agosto 2026  
**Versione app:** `0.2.0-step2`

## Scopo dello step

Aggiungere la prima funzionalità Android realmente legata al dispositivo senza introdurre backend: usare opzionalmente la posizione corrente per ordinare i ristoranti fake in base alla distanza.

La posizione deve essere una comodità, non una barriera: HAPOSTO continua a funzionare anche se il permesso viene negato.

---

## Modifiche effettuate

### 1. Permission foreground
Aggiunti al manifest:

```xml
ACCESS_COARSE_LOCATION
ACCESS_FINE_LOCATION
```

**Non è presente `ACCESS_BACKGROUND_LOCATION`.**

La richiesta runtime viene lanciata esclusivamente dopo tap su `USA LA MIA POSIZIONE`.

Su Android 12+ l'utente può concedere soltanto la posizione approssimativa: il flusso la accetta senza bloccare l'app.

### 2. DeviceLocationProvider
Nuova astrazione:

```text
DeviceLocationProvider
└── AndroidDeviceLocationProvider
```

L'implementazione usa:

```text
LocationManagerCompat.getCurrentLocation()
```

con un singolo fix foreground.

Non sono stati aggiunti:

- Google Maps SDK;
- Google Places;
- Fused Location Provider;
- tracking continuo;
- service foreground/background.

### 3. Timeout e fallback
Il provider tenta i provider Android disponibili e non attende indefinitamente.

Possibili esiti:

```text
Success
PermissionMissing
ServicesDisabled
Unavailable
```

In ogni caso di errore la Home resta utilizzabile col riferimento già selezionato.

### 4. Posizione soltanto in RAM
`LocationSession` contiene il riferimento di distanza corrente.

Non viene scritto in:

- SharedPreferences;
- DataStore;
- file;
- database;
- Supabase;
- analytics.

### 5. Aree manuali
Aggiunti quattro riferimenti:

```text
Pesaro centro
Fano centro
Urbino centro
Gabicce Mare
```

All'avvio è selezionato `Pesaro centro`.

L'utente può quindi utilizzare l'app senza concedere alcun permesso.

### 6. Coordinate sui record fake
`Restaurant` contiene ora:

```kotlin
location: GeoPoint
```

`distanceKm` è un valore derivato e opzionale, non un dato statico del repository.

Il dataset demo contiene punti fittizi geograficamente distribuiti nell'area pilota.

### 7. Haversine
Aggiunto `GeoDistance` in Kotlin puro.

La distanza viene calcolata tra:

```text
DistanceOrigin → Restaurant.location
```

senza servizi web o API mappe.

### 8. Riordino dinamico
Quando cambia:

- posizione dispositivo;
- area manuale;

le distanze vengono ricalcolate e `RestaurantQuery` ordina nuovamente i risultati.

Esempio:

- riferimento Pesaro → locali Pesaro in alto;
- riferimento Fano → record demo Fano sale in cima;
- riferimento Urbino → record demo Urbino sale in cima.

### 9. Home location panel
La Home dichiara sempre **da quale punto** vengono calcolate le distanze.

Per posizione dispositivo mostra inoltre:

- precisa/approssimativa in base al permesso concesso;
- accuratezza fornita dal fix Android, quando presente.

### 10. Dettaglio coerente
La scheda ristorante legge lo stesso `LocationSession` della Home.

Non può quindi mostrare una distanza demo differente da quella vista nella lista.

### 11. Indicazioni
`INDICAZIONI` apre un Intent `geo:` utilizzando le coordinate del record fake.

HAPOSTO non incorpora una mappa.

### 12. Ricerca
La ricerca ora considera anche `city`, utile con il dataset provinciale.

### 13. Test
Aggiunti test per:

- distanza zero;
- distanza Haversine nota;
- simmetria;
- associazione distanza al ristorante;
- ricerca per città;
- mantenimento dei test TTL/filter precedenti.

---

# Decisioni privacy

Lo Step 2 segue questa regola:

> **La posizione serve a ordinare la lista, non a tracciare l'utente.**

Non c'è alcuna funzione che richieda posizione in background.

Se l'utente non vuole condividerla, l'esperienza principale rimane disponibile tramite scelta manuale dell'area.

---

# Come provare la modifica

1. Apri `HaPosto/` in Android Studio.
2. Gradle Sync.
3. Avvia su API 26+.
4. Verifica che nessun popup posizione appaia automaticamente.
5. Tocca `USA LA MIA POSIZIONE`.
6. Prova:
   - permesso preciso;
   - permesso approssimativo;
   - rifiuto.
7. Cambia manualmente `Pesaro`, `Fano`, `Urbino`, `Gabicce Mare`.
8. Controlla che le card si riordinino.
9. Apri una card e verifica che il dettaglio usi lo stesso riferimento.
10. Prova `INDICAZIONI`.

---

# Cosa NON è stato implementato

- Supabase;
- PostGIS runtime;
- database;
- Auth;
- dashboard ristoratore;
- claim;
- Realtime;
- tracking background;
- mappa embedded;
- Places/geocoding;
- salvataggio posizione;
- notifiche;
- pagamenti.

---

# Step successivo preannunciato — STEP 3
## Dashboard ristoratore locale

Ancora senza Supabase e senza Auth reale.

Lo Step 3 aggiungerà:

- ingresso locale all'area ristoratore demo;
- un ristorante demo gestibile;
- tre pulsanti grandi `C'È POSTO / POCHI POSTI / COMPLETO`;
- aggiornamento con un singolo tap;
- timestamp immediato;
- TTL 30 minuti;
- dettagli opzionali tavoli/attesa/nota;
- telefono pubblico ON/OFF;
- condivisione dello stato in memoria con la Home consumer;
- test della logica di update.

**Supabase resterà OFF.**
