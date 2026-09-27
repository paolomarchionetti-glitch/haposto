# HAPOSTO — Tutorial dell'app

Guida passo per passo all'app **così com'è oggi** (versione di prova, Step 7.9), per chi la usa
per cercare un posto e per chi gestisce un ristorante. Alla fine trovi cosa cambierà con le
prossime versioni.

HAPOSTO risponde a una sola domanda: **"Dove c'è posto adesso, vicino a me?"**
Non è un sito di prenotazioni: lo stato lo dichiara il locale e vale 30 minuti.

---

## 1. Le cinque cose da sapere

| Simbolo | Scritta | Significa | Cosa fare |
|---|---|---|---|
| **✓** verde | **C'è posto** | il locale ha tavoli liberi adesso | vai o chiama |
| **!** ambra | **Pochi posti** | ultimi tavoli o breve attesa | meglio chiamare prima |
| **✕** rosso | **Completo** | niente posto in questo momento | scegli un altro locale |
| **?** grigio | **Da aggiornare** | il locale non ha confermato negli ultimi 30 minuti | chiama per sapere |
| **–** grigio | **Non collegato** | il locale è in elenco ma non usa ancora HAPOSTO | chiama se vuoi |

Il simbolo c'è sempre accanto al colore: si legge anche senza distinguere il verde dal rosso, e con
TalkBack l'app pronuncia "Disponibilità: C'è posto".

---

## 2. Primo avvio

1. **Tre schermate di benvenuto**: *Scopri dove c'è posto adesso* → *Dati freschi, di cui fidarti* →
   *Vicino a te*. Tocca **Avanti** oppure **Salta**, poi **Inizia**. Non compaiono più.
2. In alto nella Home vedi un'etichetta:
   - **DEMO** = dati dimostrativi dentro il telefono (10 locali fissi);
   - **SUPABASE DEV** = dati dal database di prova (vedi `HAPOSTO_GUIDA_TEST_PSEUDOREALISTICO.md`).

---

## 3. Per chi cerca un posto

### 3.1 La Home ("Vicino")

Dall'alto in basso:

| Elemento | A cosa serve |
|---|---|
| **Dove vuoi mangiare?** | titolo; sotto, quanti locali hanno posto ora e quanti ce ne sono nella zona |
| **📍 Pesaro centro · Cambia** | il punto da cui si calcolano le distanze. **Cambia** apre la scelta |
| **Cerca ristorante o cucina** | scrivi un nome o un tipo di cucina, es. "pizza" |
| **Mostra solo dove c'è posto** | un tocco e restano solo i locali ✓; ritocca per vedere tutti |
| **Lista dei locali** | dal più vicino; ogni riga ha nome, cucina, distanza, stato e da quanto tempo |
| **ⓘ Come funziona HAPOSTO** | spiegazione breve, si apre e si chiude |

### 3.2 Scegliere la zona

Tocca **Cambia** nella riga 📍:

- **Usa la mia posizione** → Android chiede il permesso. Va bene anche "posizione approssimativa".
  La posizione resta nel telefono: serve solo a ordinare per distanza e non viene salvata.
- **Oppure scegli un'area**: *Pesaro centro*, *Fano centro*, *Urbino centro*, *Gabicce Mare*.
  Non usa nessun dato personale.

Se hai negato il permesso e vuoi riattivarlo: **Apri impostazioni app** → Autorizzazioni → Posizione.

### 3.3 La scheda del locale

Tocca un locale nella lista:

- **Disponibilità adesso** con simbolo grande, da quanto è aggiornato e **Valido ancora ~N min**;
- se il locale li ha indicati: **tavoli liberi**, **attesa** e una **nota** (es. "Solo tavoli esterni");
- **INDICAZIONI** apre Google Maps (o l'app di mappe che usi) verso il locale;
- **CHIAMA** apre il telefono con il numero già scritto (solo se il locale ha reso pubblico il numero);
- **☆ Salva nei preferiti** / **★ Nei preferiti · tocca per togliere**.

Promemoria in fondo alla scheda: *lo stato è un'indicazione recente del locale, non una prenotazione*.

### 3.4 I preferiti

Tab **Preferiti** in basso:

- mostra i locali salvati con il loro **stato di adesso**;
- se un preferito è in un'altra città, l'app ti avvisa ("1 preferito è fuori dalla zona che stai
  guardando"): cambia zona per vederlo;
- i preferiti restano sul telefono, **gratis e senza account**.

### 3.5 Senza internet

Compare **Sei offline**: la lista resta visibile ma gli stati potrebbero essere vecchi. Quando torna la
rete la lista si aggiorna da sola entro un minuto. Anche con rete buona l'app ricontrolla ogni minuto.

---

## 4. Per chi gestisce un ristorante

### 4.1 Entrare (prima volta)

Tab **Ristoratore** → *Area ristoratore*. In alto vedi a che punto sei: **Passo 1 di 3**, **2 di 3**,
**3 di 3**, poi **✓ Fatto**.

| Passo | Cosa fai oggi (versione di prova) | Cosa succederà nella versione reale |
|---|---|---|
| 1 · Accedi | **CONTINUA CON GOOGLE · DEMO LOCALE** | accesso con il tuo account Google |
| 2 · Trova il tuo locale | cerca il nome, tocca il locale, **QUESTO È IL MIO LOCALE**, scrivi un recapito, **INVIA RICHIESTA DEMO** | uguale; se il locale non c'è potrai aggiungerlo |
| 3 · Verifica in corso | **SIMULA APPROVAZIONE ADMIN** (solo per prova) | HAPOSTO ti chiama al numero del locale e approva |
| ✓ Fatto | **APRI DASHBOARD** | uguale |

Nella versione di prova l'identità è fittizia ("Titolare Demo"): nessun login vero, nessun documento.

### 4.2 La dashboard: tutto in una schermata

```
┌──────────────────────────────────────┐
│ I clienti adesso vedono              │
│  ✓  C'è posto                        │
│  aggiornato 12 min fa                │
│  ▓▓▓▓▓▓▓▓▓▓░░░░░  Valido ancora ~18 minuti
│  [ ✓  È ancora così: confermo ]      │
└──────────────────────────────────────┘
Come siete messi adesso?
[ ✓  C'è posto      Ci sono tavoli liberi adesso ]
[ !  Pochi posti    Ultimi tavoli o breve attesa ]
[ ✕  Completo       Niente posto in questo momento ]
▸ Dettagli facoltativi  (tavoli, attesa, nota — puoi ignorarli)
▸ Info locale           (mostra o nascondi il telefono)
▸ 📋 Prenotazioni di sala
```

**Il riquadro in alto** dice esattamente cosa vedono i clienti e quanto manca alla scadenza.
La barra si accorcia con il passare dei minuti.

**I tre tasti grandi** pubblicano subito, con un tocco. Il tasto dello stato attuale ha il bordo spesso
e la scritta "Stato attuale". Il telefono vibra leggermente e compare
*"✓ Pubblicato adesso: i clienti lo vedono per 30 minuti."*

**È ancora così: confermo** rinnova lo stesso stato per altri 30 minuti. È il tasto da usare più spesso.

### 4.3 La regola dei tre momenti

Per avere clienti che si fidano bastano tre gesti a servizio:

1. **All'apertura** (es. 19:00): tocca **✓ C'è posto**.
2. **Quando cambia qualcosa** (sala quasi piena, poi completo, poi si libera): tocca il tasto giusto.
3. **Ogni mezz'ora**, se non è cambiato niente: **È ancora così: confermo**.

Se non fai nulla per 30 minuti lo stato diventa **? Da aggiornare** per i clienti. Non è un errore:
è il modo in cui HAPOSTO evita di mostrare informazioni vecchie. Un tocco e torna valido.

### 4.4 Dettagli facoltativi

Tocca **Dettagli facoltativi** solo se vuoi:

- **Tavoli liberi indicativi** con − e +;
- **Attesa indicativa** (Non indicata, Nessuna, 10 min, 20 min, 30+ min);
- **Nota breve** (max 80 caratteri), es. "Solo tavoli esterni", "Cucina fino alle 23".

Poi **Aggiorna dettagli e riconferma**: pubblica i dettagli e rinnova lo stato. Nella versione a
pagamento (Pro) i dettagli sono inclusi; durante la beta sono gratis per tutti.

### 4.5 Info locale

Interruttore **Mostra il numero e il tasto Chiama**: se è spento i clienti non vedono il numero.
Nome, indirizzo e orari per ora arrivano dalla scheda del locale; si potranno modificare dalla
versione con account reale.

### 4.6 Prenotazioni di sala

Un **blocco note** per le prenotazioni prese al telefono o di persona. Resta solo su questo telefono
e i clienti non lo vedono.

1. **Nome** (oppure **🎙 Detta** per dettarlo), **Orario** (es. 20:30), **Persone** con − e +,
   **Tavolo** facoltativo.
2. **Aggiungi**. La lista è ordinata per orario.
3. Tocca una prenotazione per **modificarla**; **Rimuovi** per cancellarla.

Con Pro, in futuro, le prenotazioni saranno condivise tra i telefoni dello staff.

### 4.7 Uscire

Nell'area di accesso: **ESCI**. **Azzera account e claim demo** riporta tutto all'inizio (solo prova).

---

## 5. Domande frequenti

**Il cliente può prenotare da HAPOSTO?**
No. Vede se c'è posto e ti chiama o arriva. Le prenotazioni restano tue.

**Se dimentico di aggiornare, i clienti vedono "C'è posto" anche se sono pieno?**
No: dopo 30 minuti lo stato diventa "Da aggiornare". Nessun dato vecchio viene mostrato come attuale.

**Quanto costa?**
Oggi niente. Il piano Basic (stato, telefono, pagina con QR, statistiche essenziali) resterà gratis;
Pro aggiunge dettagli, staff, promemoria, statistiche complete e prenotazioni condivise.
Durante la beta Pro è gratis. Dettagli: `HAPOSTO_MODELLO_PREMIUM_E_ACCOUNT.md`.

**Serve un account per cercare?**
No, mai. L'account servirà solo a chi gestisce un locale e a chi vorrà Plus (avvisi, preferiti su più telefoni).

**Più persone del locale possono aggiornare?**
Con Pro il titolare potrà aggiungere camerieri e soci con il loro account Google.

**La mia posizione viene salvata?**
No. Serve solo a ordinare la lista e resta sul telefono.

**Vedo "Configurazione Supabase incompleta".**
Manca una delle due righe in `local.properties`: vedi `HAPOSTO_GUIDA_TEST_PSEUDOREALISTICO.md` §5.

---

## 6. Cosa cambierà nelle prossime versioni

| Quando | Novità per l'utente | Novità per il ristoratore |
|---|---|---|
| Step 8–9 | — | accesso vero con Google, richiesta verificata da HAPOSTO, locale nuovo aggiungibile |
| Step 10 | la lista si aggiorna in pochi secondi | — |
| Step 11 | — | notifica "Il tuo stato scade: è ancora così?" con i 3 tasti direttamente nella notifica |
| Step 12 | pagina web del locale dal QR, senza installare l'app | adesivo QR "Prima di chiamare" da stampare |
| Step 14 | — | piano Pro a pagamento dal sito (dopo la beta) |
| Step 16 | **Plus**: "Avvisami quando c'è posto", preferiti su tutti i telefoni, raggio più ampio | — |
| Step 17 | — | "Quante persone ti hanno visto, chiesto indicazioni, chiamato" |
