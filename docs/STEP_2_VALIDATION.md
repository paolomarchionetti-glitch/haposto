# HAPOSTO — STEP 2 Validation

**Data:** 24 agosto 2026

## Controlli eseguiti nel pacchetto

### Struttura / sorgenti

- [x] XML parsati correttamente;
- [x] `ACCESS_COARSE_LOCATION` presente;
- [x] `ACCESS_FINE_LOCATION` presente;
- [x] `ACCESS_BACKGROUND_LOCATION` assente;
- [x] nessun Google Maps SDK / Places SDK aggiunto;
- [x] nessuna chiamata Supabase introdotta nello Step 2;
- [x] nessuna posizione persistita in DataStore/Preferences/file;
- [x] dataset demo privo di nomi/telefoni di ristoranti reali;
- [x] codice `domain/` compilato isolatamente con `kotlinc` disponibile nell'ambiente;
- [x] ZIP verificato dopo la creazione;
- [x] manifest SHA-256 dei file rigenerato.

### Logica coperta da test JUnit

- [x] TTL/freshness;
- [x] stato non collegato;
- [x] ricerca e filtri;
- [x] ordinamento distanza;
- [x] ricerca per città;
- [x] Haversine: zero distance;
- [x] Haversine: distanza di riferimento;
- [x] Haversine: simmetria;
- [x] attach distanza a Restaurant.

## Limite dell'ambiente di generazione

Non è stato possibile eseguire un `assembleDebug` Android completo perché il container non espone un Android SDK installato/configurato.

Il controllo effettuato qui comprende quindi sorgenti puri, XML, struttura, regole di sicurezza/privacy e pacchetto. Il build Android finale va eseguito in Android Studio tramite Gradle Sync + Run.

## Test manuali consigliati in Android Studio

1. avvio senza popup permission;
2. tap `USA LA MIA POSIZIONE`;
3. concedere Precise;
4. reinstallare/revocare e provare Approximate;
5. rifiutare il permesso;
6. spegnere la localizzazione di sistema;
7. cambiare area manuale;
8. ruotare/navigare Home → dettaglio → back;
9. verificare distanze e ordinamento;
10. aprire Intent indicazioni.

## Smoke test geografico eseguito

Il dominio compilato isolatamente ha prodotto:

```text
0° → stesso punto = 0 km
1° longitudine all'equatore ≈ 111.195 km
Pesaro centro → Fano centro ≈ 11.354 km
```

## Nota Gradle Wrapper

Come nello Step 0/1, il repository contiene `gradle-wrapper.properties` e script bootstrap, ma non il binario ufficiale `gradle-wrapper.jar`. Non è stato inventato o sostituito con un binario non verificato. Se serve il wrapper CLI standard, generarlo con Gradle 9.5.0 tramite `gradle wrapper --gradle-version 9.5.0`.

## Provenienza base

Lo Step 2 è stato generato partendo dallo ZIP Step 1 caricato nel progetto. Il file sorgente verificato aveva SHA-256:

```text
db5ef8c3f3e30a2cbec934412d50993f6183e3ed9584c24980462641364727dc
```

Il valore coincide con il companion `.sha256` dello Step 1.
