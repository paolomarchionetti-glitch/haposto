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
   - **DEV** = versione di prova collegata al database di prova (vedi `HAPOSTO_GUIDA_TEST_PSEUDOREALISTICO.md`); la versione definitiva non mostra etichette.

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
| **Lista dei locali** | dal più vicino; ogni riga ha nome, cucina, distanza, stato e **Valido ancora ~N min** |
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

- **Disponibilità adesso** con il simbolo e da quanto è aggiornato (es. *Aggiornato 5 min fa*);
- se il locale li ha indicati: **tavoli liberi**, **attesa** e una **nota** (es. "Solo tavoli esterni");
- **🏷 Offerta di stasera**, se il locale ne ha messa una (es. "Dolce offerto"): vale finché lo
  stato è aggiornato e non compare mai quando il locale è al completo. Nella lista lo stesso
  simbolo 🏷 segnala i locali con un'offerta;
- **Menù e sito**: i tasti **📋 Menù**, **📄 Menù (PDF)** o **📄 Menù del giorno** e **🌐 Sito del
  locale**, se il locale li ha messi;
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
│  Aggiornato 12 min fa                │
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

- **🎙 Detta i dettagli**: una frase sola, es. «tre tavoli, dieci minuti, solo tavoli fuori» →
  tavoli 3, attesa 10 min, nota "Solo tavoli fuori". Dopo la parola «offerta» detti l'offerta
  («due tavoli, offerta dolce offerto»), dopo «nota» la nota. Compila solo quello che dici;
  controlla e correggi a mano se serve. Esempi che capisce:

  | Detti | Diventa |
  |---|---|
  | «nessuna attesa», «attesa nessuna», «attesa zero», «non c'è attesa» | Attesa **Nessuna** |
  | «attesa non indicata», «togli l'attesa» | Attesa **Non indicata** |
  | «una ventina di minuti», «10-15 minuti», «mezz'oretta» | Attesa 20 min, 20 min, 30+ min |
  | «un paio di tavoli», «tre o quattro tavoli», «solo un tavolo» | Tavoli 2, 3, 1 |
  | «togli i tavoli», «nessuna nota», «togli l'offerta» | Campo svuotato |

- **Tavoli liberi indicativi** con − e +;
- **Attesa indicativa** (Non indicata, Nessuna, 10 min, 20 min, 30+ min);
- **Nota breve** (max 80 caratteri), es. "Solo tavoli esterni", "Cucina fino alle 23". Sotto
  compaiono le **note pronte** del locale e le **ultime note** usate da questo telefono: un tocco
  per riusarle. **＋ Salva questa nota tra le note pronte** la aggiunge per tutto il locale;
- **Offerta della serata (facoltativa)**, max 60 caratteri: un tocco su **−10%**, **−20%**,
  **Dolce offerto**, **Calice offerto**, oppure scrivila o dettala. La prima volta l'app ricorda
  che è un tuo impegno: dev'essere vera e rispettata. Si vede solo con **C'è posto** o **Pochi
  posti** e scade insieme allo stato (30 minuti senza conferma). Per toglierla svuota il campo.

Poi **Aggiorna dettagli e riconferma**: pubblica i dettagli e rinnova lo stato. Nella versione a
pagamento (Pro) i dettagli sono inclusi; durante la beta sono gratis per tutti.

### 4.5 Info locale

Interruttore **Mostra il numero e il tasto Chiama**: se è spento i clienti non vedono il numero.
Nome, indirizzo e orari per ora arrivano dalla scheda del locale; si potranno modificare dalla
versione con account reale.

### 4.5 bis Note pronte, menù, sito e file

Dalla dashboard: **⚙ Gestisci il locale**.

- **Note pronte** (fino a 8): le frasi che usi spesso nella nota, es. "Solo tavoli all'aperto".
  Scrivi → **Aggiungi**; **Togli** per eliminarne una. Le vede anche lo staff nella dashboard.
- **Menù, sito e file** (solo il titolare, con la verifica in due passaggi):
  - **Sito del locale** e **Link al menù** (sito, Instagram, Google Drive…) → **Salva i link**.
    Basta scrivere `www.…`: `https://` si aggiunge da solo;
  - **Scegli foto o PDF**: **un file solo**. Una foto la rimpicciolisce il telefono prima di
    inviarla; un PDF può pesare al massimo 2 MB. Poi l'app chiede **Vale solo per oggi?**:
    **Solo oggi** per il menù del giorno scritto a mano (si cancella da solo la mattina dopo),
    **No, resta** per un menù che vale sempre. Un file nuovo sostituisce il vecchio;
    **Togli il file** lo elimina.

Link e file li vedono i clienti nella scheda del locale e nella pagina del QR. HAPOSTO li
controlla e può toglierli se non sono adatti.

### 4.6 Prenotazioni di sala

Un **blocco note** per le prenotazioni prese al telefono o di persona. Resta solo su questo telefono
e i clienti non lo vedono.

1. In alto scegli il giorno: **Oggi**, **Domani** o **📅 Altro giorno**.
2. **🎙 Detta la prenotazione** con una frase sola, es. «Rossi, quattro, alle venti e trenta,
   tavolo dodici»: compila nome, persone, orario e tavolo. Capisce anche «domani», «sabato»,
   «il 15», «sabato 15 ottobre», «a pranzo», «alle otto e mezza», «tavolo da sei», «una coppia»,
   «famiglia di quattro» e qualsiasi orario: «alle 13.17», «alle tredici e diciassette», «alle
   1317». Toglie dal nome «signor», «dottor» e simili. Controlla e correggi se serve.
3. Oppure a mano: **Nome**; **Orario** con un tocco sugli orari proposti (dagli orari del locale)
   o scrivendo solo le cifre (2030 → 20:30, i due punti si mettono da soli); **Persone** con − e +;
   **Tavolo** facoltativo.
4. **Aggiungi**. La lista mostra il giorno scelto, in ordine di orario, con il totale delle persone.
5. Tocca una prenotazione per **modificarla**; **Rimuovi** per cancellarla. I giorni passati si
   cancellano da soli.

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
Durante la beta niente: tutti i locali hanno Pro gratis. Chi entra dopo ha una prova gratuita (un
mese). Poi Pro costa 19,90 € al mese, 99,90 € per 6 mesi o 199,90 € l'anno, IVA inclusa (prezzi
provvisori), e si attiva sul sito, area ristoratori. Senza abbonamento il locale resta nella lista
come **Non collegato**: niente stato, offerta, menù e sito. Una settimana e un giorno prima della
fine arriva un avviso, e in **Gestisci il locale → Il tuo piano** c'è sempre la data. Dettagli:
`HAPOSTO_MODELLO_PREMIUM_E_ACCOUNT.md`.

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
