# HAPOSTO — STEP 1
## Consumer UI con repository fake

**Data:** 24 agosto 2026  
**Versione app:** `0.1.0-step1`

## Scopo dello step

Trasformare la fondazione tecnica dello Step 0 in un primo prototipo consumer realmente navigabile **senza backend e senza Supabase**.

La scelta deriva dai documenti di analisi: prima si deve approvare l'esperienza utente, poi si collega l'infrastruttura.

---

## Modifiche effettuate

### 1. Home consumer
Aggiunta una Home Compose con:

- brand HAPOSTO;
- claim;
- area pilota `Pesaro · prototipo locale`;
- campo ricerca;
- filtri;
- lista ristoranti;
- stato e timestamp sempre visibili;
- disclaimer dati demo.

### 2. Dataset fittizio
`FakeRestaurantRepository.kt` contiene 10 attività interamente fittizie.

Non sono stati copiati:

- Google Maps;
- recensioni;
- fotografie;
- loghi;
- menù;
- numeri reali.

### 3. Stati
Supportati:

```text
AVAILABLE      → C'È POSTO
LIMITED        → POCHI POSTI
FULL           → COMPLETO
STALE          → DA AGGIORNARE
NOT_CONNECTED  → NON COLLEGATO
```

### 4. TTL 30 minuti
La logica è centralizzata in `AvailabilityResolver`.

Un partner con stato scaduto diventa automaticamente `STALE` lato UI. Nessun job o backend è necessario per questo prototipo.

### 5. Ricerca e filtri
Aggiunto `RestaurantQuery`, testabile senza Android.

Ricerca su:

- nome;
- categoria;
- indirizzo.

Filtri:

- Tutti;
- C'è posto;
- Pochi posti;
- Live.

### 6. Navigation Compose
Rotte:

```text
home
restaurant/{restaurantId}
```

### 7. Dettaglio ristorante
Mostra:

- nome;
- categoria;
- stato;
- freschezza;
- dettagli opzionali solo se lo stato è ancora live;
- indirizzo;
- distanza demo;
- pulsante Indicazioni;
- pulsante Chiama soltanto quando consentito.

### 8. Azioni esterne
`INDICAZIONI` usa un Intent `geo:` verso un'app di navigazione installata.

`CHIAMA` usa `ACTION_DIAL`, quindi l'app non effettua direttamente telefonate e non richiede permesso `CALL_PHONE`.

### 9. Test
Aggiunti test unitari per:

- stato fresco;
- stato scaduto;
- scadenza esatta;
- ristorante non collegato;
- filtri;
- ordinamento distanza;
- ricerca case-insensitive.

### 10. Supabase rinviato
I file SQL e lo scaffold Supabase sono mantenuti ma **non devono essere eseguiti/configurati**.

La roadmap è stata modificata su richiesta: prima completiamo i flussi Android locali, poi colleghiamo Supabase.

---

## Come provare STEP 1

1. Estrai lo ZIP.
2. Apri `HaPosto/` con Android Studio.
3. Esegui Gradle Sync.
4. Avvia su emulatore/dispositivo Android API 26+.
5. Non inserire credenziali Supabase.
6. Prova ricerca e filtri.
7. Apri le card.
8. Verifica `INDICAZIONI` e, sulle schede predisposte, `CHIAMA`.

### Test suggeriti

- cerca `pizza`;
- seleziona `C'è posto`;
- seleziona `Live`;
- cerca un testo inesistente per vedere l'empty state;
- apri `Casa Miralfiore`: lo stato iniziale è volutamente scaduto;
- apri un ristorante `NON COLLEGATO`;
- apri un ristorante con numero demo pubblico.

---

## Cosa NON è stato implementato

- posizione GPS reale;
- database;
- Supabase;
- Auth;
- claim ristorante;
- dashboard ristoratore;
- aggiornamenti LIVE veri;
- Realtime;
- notifiche;
- pagamenti.

Questo è intenzionale.

---

# Step successivo preannunciato — STEP 2

## Posizione locale + distanza reale lato Android

Senza Supabase.

Lo Step 2 aggiungerà:

- richiesta permission posizione con UX corretta;
- fallback se l'utente rifiuta;
- posizione corrente solo in memoria;
- coordinate fake dei ristoranti;
- calcolo distanza locale;
- ordinamento per distanza reale;
- selezione manuale area quando la posizione non è disponibile;
- mantenimento di `INDICAZIONI` verso app esterna;
- test della logica geografica.

**Supabase resterà ancora spento.**
