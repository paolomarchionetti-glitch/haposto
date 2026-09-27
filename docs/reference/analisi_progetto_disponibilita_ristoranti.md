# Analisi ultra-approfondita del progetto “Posto?”  
## Disponibilità immediata dei ristoranti: FULL / FREE in tempo reale

**Data analisi:** 24 agosto 2026  
**Stato:** concept / pre-MVP  
**Obiettivo:** valutare fattibilità, valore per utenti e ristoratori, concorrenza, modello economico, rischi, UX, architettura Android→iOS e strategia di lancio.

---

# 1. Executive summary

L’idea è valida perché parte da un problema reale, frequente e molto semplice da comprendere:

> “Vorrei mangiare fuori adesso. Questo ristorante ha posto oppure devo chiamare?”

Il prodotto non dovrebbe nascere come un nuovo sistema di prenotazione completo, né come un concorrente diretto di TheFork, OpenTable o Google Maps. La sua forza sarebbe precisamente il contrario: **ridurre il problema a uno stato operativo immediato e leggibile in un secondo**.

Il ristorante, con uno o due tocchi, comunica:

- 🟢 **FREE / Disponibile**
- 🟠 **ULTIMI POSTI / Pochi tavoli**
- 🔴 **FULL / Completo**

e, opzionalmente:

- attesa stimata;
- uno/due/tre tavoli disponibili;
- disponibilità per gruppi;
- terrazza/interno;
- “solo senza prenotazione”;
- nota libera molto breve.

L’utente apre l’app, cerca o vede i ristoranti vicini e capisce immediatamente dove può andare.

## Verdetto sintetico

**Sì, vale la pena prototiparla.**

Ma il progetto funziona solo se vengono risolti quattro problemi prima ancora della programmazione avanzata:

1. **Freschezza del dato:** un FREE vecchio di 45 minuti può distruggere la fiducia.
2. **Adozione dei ristoranti:** l’aggiornamento deve richiedere letteralmente 1–2 secondi.
3. **Densità locale:** 500 ristoranti sparsi in tutta Italia valgono meno di 40 ristoranti concentrati nello stesso quartiere/città.
4. **Monetizzazione iniziale:** far pagare da subito sia utenti sia ristoratori rischia di bloccare la crescita.

La feature non è completamente nuova a livello mondiale. Esistono prodotti con waitlist, disponibilità in tempo reale e gestione dei walk-in; alcuni concetti recenti sono perfino molto vicini. Questo è però un segnale utile: **il problema è validato**. Il vantaggio competitivo dovrebbe essere la semplicità estrema, il focus sull’“adesso” e una distribuzione locale molto aggressiva.

---

# 2. Il problema che stai realmente risolvendo

Il prodotto non risolve principalmente “la prenotazione”.

Risolve **l’incertezza dell’ultimo minuto**.

Situazioni tipiche:

- sono le 20:30 e due persone vogliono uscire;
- sono in centro e voglio mangiare senza organizzarmi;
- il primo ristorante è pieno;
- non voglio telefonare a quattro locali;
- il ristorante sta lavorando e non vuole rispondere continuamente al telefono;
- non voglio creare account, scegliere fascia oraria, confermare e prenotare;
- voglio soltanto sapere: **“se parto ora, ho realisticamente possibilità di sedermi?”**

Questo è un problema diverso dalla prenotazione tradizionale.

## Chiamata telefonica attuale

Il flusso oggi spesso è:

1. Cerco il ristorante.
2. Apro Google.
3. Chiamo.
4. Nessuno risponde perché il personale è impegnato.
5. Richiamo.
6. Mi dicono “forse”.
7. Chiamo un secondo locale.
8. Ripeto.

Con il prodotto:

1. Apro.
2. Vedo 🟢.
3. Parto.

La differenza sembra piccola ma, quando è frequente, crea una UX molto migliore.

---

# 3. Perché il ristoratore potrebbe volerlo

L’errore sarebbe vendergli “un’altra app da gestire”.

Deve essere venduto così:

> “Ti faccio ricevere meno chiamate inutili e ti mando clienti quando hai tavoli vuoti. Per aggiornare la disponibilità tocchi un pulsante.”

Questo cambia completamente la percezione.

## Benefici per il ristorante

### 3.1 Meno telefonate durante il servizio

La sala non deve interrompersi per:

- “Avete posto?”
- “Siete pieni?”
- “Possiamo venire in quattro?”
- “Quanto bisogna aspettare?”

### 3.2 Monetizzazione dei tavoli vuoti

Un tavolo non occupato è inventory deperibile.

Un posto rimasto vuoto alle 21:00 non può essere “venduto domani”.

La disponibilità immediata è quindi economicamente interessante.

### 3.3 Nessun obbligo di mostrare la capacità reale

Questo è un buon punto della tua idea.

Il ristoratore può comunicare:

- disponibile;
- quasi pieno;
- pieno;

senza dichiarare:

- numero totale di coperti;
- percentuale di occupazione;
- fatturato;
- reale capacità del locale.

Le informazioni quantitative rimangono opzionali.

### 3.4 Nessun nuovo gestionale complesso

Il ristoratore non deve necessariamente:

- disegnare la pianta della sala;
- inserire ogni tavolo;
- gestire prenotazioni;
- importare clienti;
- installare un POS;
- creare CRM.

Questa semplicità è la tua differenziazione.

---

# 4. Concorrenza: l’idea è nuova?

## Risposta breve

**Il problema non è nuovo e alcune soluzioni sono molto vicine.  
Il posizionamento minimalista può invece essere differenziato.**

### Google Maps

Google può mostrare:

- orari di punta;
- affluenza live;
- durata tipica;
- tempi di attesa.

Ma il dato è inferito attraverso dati aggregati e non è un pulsante ufficiale del ristorante “ho un tavolo libero adesso”.

Quindi:

**Google dice:** “sembra molto affollato”.  
**Il tuo prodotto direbbe:** “il ristorante dichiara che accetta clienti adesso”.

Sono due informazioni diverse.

### TheFork Manager

TheFork offre disponibilità, prenotazioni, pianta tavoli, CRM, no-show, waiting list, canali di prenotazione e molte altre funzioni.

La tua opportunità non è fare “un TheFork più piccolo”.

È fare:

> **una cosa sola, in modo più immediato di tutti.**

### OpenTable

OpenTable dispone di:

- real-time inventory;
- availability controls;
- waitlist digitale;
- walk-in;
- quote di attesa;
- prenotazioni;
- gestione della sala.

Anche qui il prodotto è però una piattaforma di gestione più completa.

### Dojo / ex WalkUp

È un concorrente concettualmente importante perché permette di vedere tavoli last-minute, disponibilità e code virtuali.

È la dimostrazione che l’uso “sono fuori e voglio un tavolo subito” ha un mercato.

### SEEAT.app

È ancora più vicino alla tua idea: distingue esplicitamente la disponibilità immediata dalle normali prenotazioni e parla di posti aggiornati in tempo reale dai partner.

### Waitless

Ha stati simili a:

- Tables Available;
- Almost Full;
- Fully Occupied.

È praticamente una validazione indipendente della stessa intuizione.

## Conclusione competitiva

Non puoi costruire il vantaggio su:

> “Nessuno ha mai pensato a mostrare se il ristorante è pieno.”

Non è vero.

Puoi costruirlo su:

> “Nessuno nella mia area ha conquistato una massa critica di ristoranti con un sistema così semplice che perfino durante il servizio viene aggiornato costantemente.”

Quello può diventare un vantaggio reale.

---

# 5. Il vero prodotto: non FULL/FREE, ma TRUST

La schermata sembra essere il prodotto.

In realtà il prodotto è **la fiducia nella schermata**.

Supponiamo:

- ristorante aggiorna FREE alle 19:50;
- alle 20:15 arrivano 20 persone;
- diventa pieno;
- nessuno ricorda di aggiornare;
- utente vede FREE alle 20:35;
- percorre 4 km;
- arriva;
- “Mi dispiace, siamo completi”.

Una sola esperienza così può far disinstallare l’app.

## Soluzione: ogni stato deve avere una scadenza

Esempio:

🟢 **Disponibile ora**  
Aggiornato 7 min fa

oppure

⚪ **Disponibilità da confermare**  
Ultimo aggiornamento 48 min fa

Non bisogna mai trasformare uno stato vecchio in un’informazione apparentemente live.

## Regola proposta

Ogni aggiornamento crea:

```text
status = FREE
updated_at = 20:14
expires_at = 20:44
```

Dopo `expires_at`:

```text
status = UNKNOWN
```

Non rimane FREE.

---

# 6. Modello di stato consigliato

Non userei solo due stati.

Tre stati sono ancora semplicissimi ma molto più utili:

## 🟢 DISPONIBILE

“Possiamo accogliere nuovi clienti adesso.”

## 🟠 POCHI POSTI

“Potremmo ancora accogliere qualcuno, ma la disponibilità è molto limitata.”

## 🔴 COMPLETO

“Al momento non accettiamo altri clienti.”

## ⚪ DA CONFERMARE

Stato automatico se il ristorante non aggiorna da troppo tempo.

Questo quarto stato non è scelto normalmente dal ristorante. Lo genera il sistema.

---

# 7. Il problema del numero di persone

Questo è uno dei problemi più importanti.

Un ristorante può avere:

- un tavolo per 2;
- nessun tavolo per 4;
- spazio per 6 solo unendo tavoli;
- tavolo esterno ma non interno.

Quindi “FREE” non significa matematicamente “disponibile per qualunque gruppo”.

## MVP consigliato

Per non complicare il ristoratore:

### Stato principale

🟢 Disponibile  
🟠 Pochi posti  
🔴 Completo

### Optional quick tags

- `2 persone`
- `fino a 4`
- `gruppi 5+`
- `solo esterno`
- `solo interno`

Il ristoratore può ignorarli.

### Variante ancora più semplice

Il ristorante dichiara:

> “Disponibilità indicativa per piccoli gruppi. Per 5+ persone contattare il locale.”

Questo può essere sufficiente nella prima versione.

---

# 8. UX ristorante: deve essere quasi ridicola per quanto è semplice

## Home ristorante

Schermata intera:

```text
RISTORANTE DA MARIO

STATO ATTUALE

🟢 DISPONIBILE
Aggiornato 6 min fa

[ 🟢 FREE ]
[ 🟠 POCHI POSTI ]
[ 🔴 FULL ]

+ Aggiungi dettaglio
```

Un solo tap aggiorna.

Non aprire popup inutili.

Non chiedere conferme tipo:

> “Sei sicuro di voler impostare FULL?”

Durante il servizio sarebbe fastidioso.

---

# 9. Aggiornamento dalla notifica

Questa può diventare una killer feature.

Alle 19:30:

> **Come siete messi?**  
> 🟢 FREE  🟠 POCHI  🔴 FULL

Idealmente il ristoratore può cambiare stato direttamente dalla notifica o con un deep link che apre la schermata corretta.

Dopo 25 minuti:

> **Confermi ancora FREE?**  
> [Sì] [Pochi posti] [Full]

Così il dato rimane fresco senza obbligare il personale a ricordarsi dell’app.

---

# 10. “Status expiry” intelligente

Una versione più evoluta può imparare.

Esempio:

- lunedì: aggiornamento valido 45 min;
- sabato sera: 15–20 min;
- locale da 150 coperti: più stabile;
- locale da 20 coperti: cambia rapidamente.

Ma nell’MVP non serve AI.

### V1

- stato valido 30 minuti;
- reminder a 25;
- dopo 30 → grigio.

### V2

Ristorante seleziona:

- 15 min;
- 30 min;
- 60 min;
- fino al prossimo aggiornamento.

Io eviterei “fino al prossimo aggiornamento” come default.

---

# 11. User experience

## Home

L’utente apre e vede immediatamente:

```text
Vicino a te

🟢 Osteria X           350 m
   Disponibile · 4 min fa

🟠 Sushi Y             600 m
   Pochi posti · 8 min fa

🔴 Pizzeria Z          800 m
   Completo · 2 min fa

⚪ Trattoria W          1,1 km
   Da confermare
```

## Filtri essenziali

- solo disponibili;
- distanza;
- cucina;
- prezzo;
- aperti ora.

Non metterei 25 filtri nella V1.

---

# 12. Il timestamp deve essere protagonista

Queste due informazioni devono essere quasi inseparabili:

> 🟢 FREE  
> **Aggiornato 3 min fa**

Non:

> 🟢 FREE

con il timestamp nascosto nella scheda.

Il timestamp è ciò che permette all’utente di decidere quanto fidarsi.

---

# 13. Non promettere il tavolo

Il prodotto deve chiarire:

> “Lo stato indica la disponibilità comunicata recentemente dal ristorante e non costituisce una prenotazione.”

Perché:

- qualcuno può arrivare 2 minuti prima;
- il ristorante può ricevere una comitiva;
- un tavolo può diventare inutilizzabile;
- il locale può scegliere di bloccare i walk-in;
- la situazione cambia rapidamente.

Il prodotto vende **informazione live**, non una garanzia.

Se un giorno vorrai garantire il tavolo, quello diventa un altro prodotto: la prenotazione.

---

# 14. Verifica dei ristoranti

Hai ragione: serve l’OK del ristorante.

Non deve essere possibile che chiunque controlli lo stato di un’attività.

## Processo suggerito

1. Creazione account.
2. Ricerca del locale.
3. “Rivendica attività”.
4. Verifica.
5. Approvazione.
6. Creazione membri staff.

## Metodi di verifica possibili

- email sul dominio aziendale;
- chiamata al numero ufficiale del locale;
- codice inviato al locale;
- documento dell’attività in casi dubbi;
- verifica manuale iniziale;
- successivamente integrazione con provider/business identity.

## Staff

Il titolare può invitare:

- manager;
- maître;
- cassiere;
- responsabile sala.

Non devono condividere una password.

---

# 15. La pagina del ristorante

Informazioni minime:

- nome;
- indirizzo;
- categoria;
- fascia prezzo;
- orari;
- stato live;
- timestamp;
- eventuale nota;
- pulsante navigazione;
- pulsante sito;
- pulsante telefono.

Non devi trasformarti immediatamente in Tripadvisor.

## Da NON costruire nella V1

- recensioni;
- feed social;
- foto utenti;
- menù completo;
- chat;
- delivery;
- loyalty;
- pagamenti del conto;
- prenotazioni complesse.

Ogni feature aggiunta rischia di distruggere la chiarezza del concept.

---

# 16. Una feature molto potente: il link pubblico

Ogni ristorante dovrebbe avere un URL:

```text
app.it/ristorante-da-mario
```

La pagina mostra:

```text
🟢 DISPONIBILE ORA
Aggiornato 3 minuti fa
```

Questo crea valore anche per chi non ha ancora installato l’app.

Il locale può mettere il link:

- su Instagram;
- nel sito;
- in Google Business, ove consentito;
- nella bio;
- nel QR all’ingresso;
- nel messaggio automatico;
- nella pagina “contatti”.

## Perché è strategico

Se obblighi ogni persona a:

1. vedere un QR;
2. scaricare 80 MB;
3. registrarsi;
4. eventualmente pagare;
5. cercare il ristorante;

molti chiameranno comunque.

Una pagina web pubblica abbatte la frizione.

L’app diventa utile soprattutto per la scoperta aggregata.

---

# 17. La killer distribution feature: QR “Prima di chiamare”

Sticker per il locale:

> **Vuoi sapere se abbiamo posto?**  
> Scansiona qui.

Oppure:

> **Posti disponibili LIVE**  
> QR

Questo trasforma il ristorante stesso nel canale di acquisizione utenti.

È molto interessante perché riduce il costo marketing.

---

# 18. Il problema del doppio marketplace

Questo è un business a due lati:

### Lato A
ristoranti

### Lato B
utenti

Il valore di A aumenta se cresce B.

Il valore di B aumenta se cresce A.

È il classico problema “chicken and egg”.

## Se fai pagare entrambi subito

Ristorante:

> “Perché dovrei spendere €4,99 se ci sono 300 utenti?”

Utente:

> “Perché dovrei pagare €0,99 se trovo 12 ristoranti?”

Il risultato può essere:

- pochi ristoranti;
- pochi utenti;
- valore basso;
- churn;
- crescita bloccata.

---

# 19. Monetizzazione proposta inizialmente

La tua ipotesi:

- utente: **€0,99/mese**
- ristorante: **€4,99/mese**

è economicamente semplice e comprensibile.

Ma separerei:

## “Prezzo finale desiderato”

da

## “Prezzo al lancio”.

Non devono necessariamente coincidere.

---

# 20. Strategia di prezzo che consiglierei

## Utenti

### FREE

- ricerca ristoranti;
- stato live;
- distanza;
- scheda;
- navigazione.

### PLUS €0,99–€1,99/mese

- alert “avvisami quando torna disponibile”;
- preferiti;
- alert dei preferiti;
- filtri avanzati;
- storico disponibilità;
- ricerca in raggio maggiore;
- eventuale esperienza senza pubblicità.

**Il dato principale deve rimanere gratis**, almeno finché la rete non è molto forte.

Perché?

Perché la persona che dovrebbe pagare €0,99 solo per evitare una telefonata potrebbe semplicemente telefonare.

---

# 21. Prezzo ristoranti

Il tuo €4,99 è ottimo come:

- founding price;
- piano entry;
- lancio;
- prezzo psicologico;
- self-service.

Ma potrebbe essere troppo basso come prezzo definitivo se devi sostenere:

- vendita;
- supporto;
- onboarding;
- visite ai locali;
- pagamenti;
- amministrazione;
- churn.

## Possibile struttura

### BASIC — €0

- stato FREE / POCHI / FULL;
- pagina pubblica;
- QR.

### PRO — €7,99–€14,99/mese

- wait time;
- numero tavoli opzionale;
- notifiche ai follower;
- analytics;
- più account staff;
- note;
- storico;
- badge/widget sito;
- priorità nei risultati non sponsorizzati solo se rilevante;
- integrazioni future.

### PRO+ — futuro

- integrazione gestionale/POS;
- aggiornamento automatico;
- API;
- gruppi di ristoranti;
- analytics avanzati.

---

# 22. Perché dare BASIC gratis può essere più redditizio

Sembra controintuitivo.

Ma il ristorante gratuito aumenta il numero di ristoranti visibili.

Più ristoranti → più utenti.

Più utenti → più valore per il ristorante.

Più valore → più possibilità che acquisti PRO.

Il FREE non è necessariamente perdita di ricavo.

È **acquisition infrastructure**.

---

# 23. Economia di €0,99 utente

Un abbonamento da €0,99 è interessante come micro-subscription, ma i margini reali sono più bassi del prezzo mostrato.

Bisogna considerare:

- IVA;
- commissione store;
- rimborsi;
- eventuali costi di acquisizione;
- backend;
- supporto.

Con aliquote store nell’ordine del 15% per piccoli sviluppatori / determinate sottoscrizioni e IVA italiana, €0,99 può trasformarsi orientativamente in circa **€0,69 netti prima degli altri costi**, a seconda della struttura fiscale e delle condizioni applicabili.

Quindi servono molti abbonati.

---

# 24. Economia di €4,99 ristorante

Se il ristorante paga via web, un pagamento mensile molto piccolo soffre particolarmente della commissione fissa del payment processor.

Esempio Stripe standard per carte SEE:

- 1,5%;
- + €0,25.

Su €4,99 la parte fissa pesa parecchio.

## Soluzione

Offrire:

- €4,99 mese;
- oppure ~€49–€59 anno.

L’annuale riduce la quota relativa del costo fisso di pagamento e riduce churn.

In B2B va inoltre definito chiaramente se il prezzo è:

- €4,99 + IVA;
- oppure €4,99 IVA inclusa.

---

# 25. Esempi MRR lordi del modello originale

Prima di IVA, fee store, payment processing, rimborsi, marketing, supporto e infrastruttura:

| Utenti paganti | Ristoranti paganti | MRR utenti | MRR ristoranti | MRR totale |
|---:|---:|---:|---:|---:|
| 1.000 | 100 | €990 | €499 | €1.489 |
| 5.000 | 300 | €4.950 | €1.497 | €6.447 |
| 10.000 | 1.000 | €9.900 | €4.990 | €14.890 |
| 50.000 | 5.000 | €49.500 | €24.950 | €74.450 |

Il problema non è il calcolo.

Il problema è ottenere **10.000 persone disposte a pagare** un servizio che ha valore solo quando ha già molti locali.

Per questo la monetizzazione utenti dovrebbe essere seconda rispetto alla crescita.

---

# 26. Dimensione del settore

FIPE nel Rapporto Ristorazione 2026 indica **324.436 imprese** nel più ampio settore della ristorazione italiana nel 2025, con i ristoranti sostanzialmente stabili rispetto al 2024.

Non sono tutte target perfette: il numero include varie attività di ristorazione e pubblici esercizi.

Serve però a capire che il bacino potenziale nazionale è grande.

Con un modello da €4,99/mese:

- 1.000 locali → €4.990 MRR;
- 5.000 locali → €24.950 MRR;
- 10.000 locali → €49.900 MRR.

Ma per un marketplace locale conta molto di più la **densità** che la quantità nazionale.

---

# 27. 40 ristoranti in una zona possono valere più di 500 sparsi

Scenario A:

- 500 ristoranti;
- 500 città;
- quasi nessuno vicino a ogni utente.

Esperienza: pessima.

Scenario B:

- 50 ristoranti;
- un centro città;
- molti locali interessanti;
- stati aggiornati.

Esperienza: utile.

## Quindi

Non lancerei:

> “Disponibile in tutta Italia.”

Lancerei:

> “Nel quartiere X trovi già 40 ristoranti LIVE.”

Poi allargherei a cerchi concentrici.

---

# 28. Strategia geografica

Ordine ideale:

1. una piccola area;
2. centro città;
3. tutta la città;
4. città vicine;
5. seconda città completa;
6. replicazione.

Evita la macchia di leopardo.

---

# 29. Come convincere i primi ristoranti

Non parlare di tecnologia.

Pitch:

> “Quante chiamate ricevete il venerdì e sabato sera soltanto per chiedere se avete posto?”

Poi:

> “Vi diamo un pulsante. Verde, arancio o rosso. Gli utenti controllano da soli. Quando siete scarichi, il verde può portarvi clienti; quando siete pieni, smettete di ricevere chiamate inutili.”

Poi:

> “Per i primi mesi è gratuito.”

Molto più forte di:

> “Abbiamo creato una piattaforma digitale innovativa di real-time capacity management.”

---

# 30. Prima del codice: intervista 20–30 ristoranti

Questa fase vale più di un mese di programmazione.

## Domande

1. Quante chiamate “avete posto?” ricevete in un servizio medio?
2. In quali giorni sono più fastidiose?
3. Se aveste un pulsante unico da aggiornare, lo usereste?
4. Chi lo aggiornerebbe?
5. Quanto spesso sarebbe realistico aggiornarlo?
6. Preferireste FREE/FULL oppure FREE/POCHI/FULL?
7. Vorreste mostrare il numero di tavoli o no?
8. Sarebbe utile indicare il tempo di attesa?
9. Utilizzate TheFork/OpenTable/altri gestionali?
10. Sareste disposti a pagare €4,99?
11. €9,99?
12. Preferireste pagare solo se porta clienti?
13. Mettereste un QR “controlla disponibilità”?
14. Lo inserireste su Instagram/sito?
15. Che cosa vi farebbe smettere di usarlo?

Non cercare complimenti.

Cerca frasi come:

> “Sì, questo mi toglierebbe una rottura.”

Quello è il segnale.

---

# 31. MVP manuale prima dell’app completa

Si può validare quasi senza app.

## Ristorante

Pagina web privata:

```text
[ FREE ]
[ POCHI ]
[ FULL ]
```

## Utente

Pagina web:

```text
Ristoranti disponibili adesso
```

Con elenco e distanza.

Puoi provare con 10 locali.

Se nessuno aggiorna il pulsante, hai scoperto un problema fondamentale spendendo pochissimo.

Se invece aggiornano spontaneamente, allora vale la pena costruire bene l’app.

---

# 32. MVP Android

Se vuoi comunque partire direttamente Android:

## Schermate utente

1. Splash.
2. Posizione / scelta città.
3. Lista ristoranti.
4. Ricerca.
5. Scheda ristorante.
6. Preferiti.
7. Profilo.

## Schermate ristorante

1. Login.
2. Dashboard status.
3. Modifica dettaglio.
4. Staff.
5. Profilo locale.
6. Statistiche base.

---

# 33. Un’app o due app?

Per l’MVP farei **una sola app con ruoli diversi**:

```text
role = DINER
role = RESTAURANT_ADMIN
role = RESTAURANT_STAFF
```

Perché:

- meno codice;
- un solo store listing;
- un solo sistema auth;
- un solo deployment;
- più facile da testare.

In futuro, con scala sufficiente, puoi separare:

- Consumer App;
- Restaurant Manager.

---

# 34. Android oggi, iOS domani: architettura

L’importante non è necessariamente condividere ogni pixel.

L’importante è che il backend non sia Android-specifico.

## Possibile stack

### Frontend Android

- Kotlin;
- Jetpack Compose;
- MVVM / clean-ish architecture;
- repository layer;
- Coroutines / Flow;
- dependency injection;
- Retrofit/Ktor client se necessario.

### Backend

Ottime opzioni MVP:

- Supabase;
- Firebase;
- backend custom successivamente.

## Perché Supabase è interessante

Il dato principale è relazionale:

- ristoranti;
- location;
- staff;
- status;
- cronologia;
- subscription;
- favorites.

PostgreSQL si adatta bene.

Il realtime può propagare subito il cambio stato.

---

# 35. iOS

Tre strade.

## Opzione A — Android nativo + iOS nativo

Android:
Kotlin + Compose

iOS:
Swift + SwiftUI

Backend comune.

### Pro
- massima qualità nativa;
- facile seguire best practice di piattaforma.

### Contro
- due UI.

---

## Opzione B — Kotlin Multiplatform

Condividi:

- models;
- networking;
- repository;
- business logic;
- cache;
- autenticazione.

UI può rimanere specifica.

È un ottimo compromesso se vuoi restare nell’ecosistema Kotlin.

---

## Opzione C — Flutter

Una sola codebase Android+iOS.

Ottimo per un MVP consumer.

Se il tuo obiettivo principale è arrivare rapidamente su entrambe le piattaforme, è probabilmente la scelta più semplice.

---

# 36. Schema dati possibile

```text
users
-----
id
email
display_name
role
created_at

restaurants
-----------
id
name
address
latitude
longitude
category
price_level
verified
owner_user_id
created_at

restaurant_staff
----------------
restaurant_id
user_id
role

restaurant_status
-----------------
restaurant_id
status
note
estimated_wait_minutes
available_tables
max_party_size
updated_at
expires_at
updated_by

restaurant_status_history
-------------------------
id
restaurant_id
status
updated_at
expires_at

favorites
---------
user_id
restaurant_id

subscriptions
-------------
id
user_id / restaurant_id
plan
status
provider
started_at
expires_at
```

---

# 37. Stato corrente vs cronologia

Non sovrascriverei semplicemente il valore.

Terrei:

### current status

per query veloci.

### status history

per:

- analytics;
- capire affidabilità;
- creare orari tipici;
- valutare frequenza aggiornamenti;
- futuro ML;
- dispute;
- suggerimenti.

---

# 38. Reliability score interno

Ogni locale può avere un punteggio non necessariamente visibile:

```text
fresh_update_rate
user_mismatch_reports
average_refresh_interval
expired_status_count
```

Esempio:

```text
reliability_score = 0.94
```

Se un locale lascia continuamente dati scaduti:

- stato scade prima;
- riceve reminder;
- eventuale badge live viene rimosso.

---

# 39. Feedback utente anti-dato errato

Dopo la visita:

> “La disponibilità era corretta?”

- sì;
- no.

Non permetterei commenti aggressivi o recensioni.

Serve solo quality control.

Per evitare abuso:

- account verificato;
- rate limit;
- segnalazioni aggregate;
- nessuna modifica diretta dello stato da parte dell’utente.

---

# 40. Non permettere agli utenti di impostare FULL/FREE

Mai.

Altrimenti:

- troll;
- concorrenti;
- utenti arrabbiati;
- sabotaggi;
- errori.

Solo account autorizzati del locale possono pubblicare lo stato ufficiale.

---

# 41. Notifiche per gli utenti

Questa è una feature Premium molto forte.

Esempio:

> “Osteria X è tornata disponibile 🟢 — aggiornato adesso.”

Oppure:

> “3 ristoranti salvati entro 1 km hanno posto.”

È un motivo più convincente per pagare €0,99 rispetto al semplice accesso.

---

# 42. Alert “voglio mangiare adesso”

Utente:

```text
2 persone
entro 2 km
italiano / qualsiasi
budget €€
```

Poi:

> Avvisami per i prossimi 45 minuti se un locale compatibile passa a FREE.

Questo trasforma il prodotto da directory passiva a strumento attivo.

---

# 43. Future feature: “ping domanda”

Se 15 utenti stanno cercando tavolo in una zona e vari locali risultano “da confermare”, potresti inviare ai ristoranti:

> “12 persone stanno cercando un tavolo entro 1 km. Conferma il tuo stato.”

Molto potente.

Crea incentivo ad aggiornare proprio quando esiste domanda.

---

# 44. Future feature: “riempi ultimo tavolo”

Ristorante:

> “Ho un tavolo libero per 2.”

App:

> manda alert agli utenti vicini interessati.

Questo diventa molto più economicamente interessante per il ristoratore.

---

# 45. La prenotazione va aggiunta?

Non subito.

Se aggiungi prenotazioni entri in:

- gestione slot;
- no-show;
- conferme;
- cancellazioni;
- turni;
- disponibilità futura;
- table allocation;
- pagamenti;
- supporto.

Il progetto cambia completamente.

## Strategia

### Fase 1
informazione live.

### Fase 2
“sto arrivando” non vincolante.

### Fase 3
eventuale hold di 5–10 minuti.

### Fase 4
prenotazione vera soltanto se richiesta dal mercato.

---

# 46. Pulsante “Sto arrivando”

È interessante ma pericoloso.

Utente:

> “Sto arrivando — 2 persone — 8 min.”

Il ristorante vede:

> “3 gruppi stanno arrivando.”

Non è prenotazione.

Può aiutare il ristoratore ad anticipare domanda.

Ma crea aspettative.

Perciò va scritto chiaramente:

> “Non riserva il tavolo.”

Io lo terrei fuori dalla primissima versione.

---

# 47. GDPR / privacy

Principio fondamentale:

**raccogliere meno dati possibile.**

Per vedere un ristorante vicino non devi necessariamente memorizzare continuamente la posizione.

Puoi:

- usare posizione per query;
- memorizzare solo se serve;
- permettere ricerca manuale città;
- spiegare chiaramente l’uso.

Dati utenti:

- email;
- preferiti;
- subscription;
- notifiche;
- location solo quando necessaria.

Dati ristoratore:

- identità account;
- ruolo;
- attività collegata;
- audit degli aggiornamenti.

Servono:

- Privacy Policy;
- Termini;
- gestione cancellazione account;
- base giuridica corretta;
- gestione consensi marketing;
- accordi con fornitori.

Per il lancio commerciale va fatta una revisione legale/fiscale professionale.

---

# 48. Dati dei ristoranti e Google

Attenzione a non costruire il database copiando indiscriminatamente:

- foto;
- recensioni;
- testi;
- loghi;
- dataset Google.

Se utilizzi Google Places o altre API devi rispettarne licenze, attribution e regole di caching/storage.

Alternativa MVP:

- ristoranti partner inseriscono i propri dati;
- usi servizi cartografici soltanto per geocoding/mappe;
- tieni la proprietà del tuo dataset operativo.

---

# 49. Sicurezza

Minimo necessario:

- autenticazione;
- HTTPS;
- Row Level Security / authorization;
- staff roles;
- audit log;
- rate limiting;
- token sicuri;
- revoca staff;
- verifica email;
- protezione endpoint status.

Il bottone sembra banale, ma controlla informazione commerciale pubblica.

---

# 50. Stato aggiornato da più telefoni

Scenario:

- titolare imposta FREE;
- maître imposta FULL 30 secondi dopo.

Serve last-write-wins con:

- timestamp server;
- updated_by;
- realtime sync.

Tutti i device vedono immediatamente:

> FULL — aggiornato da Marco, 20:47.

---

# 51. Orari di servizio

Non mandare reminder casuali.

Il locale imposta:

```text
Pranzo 12:00–14:30
Cena 19:00–23:00
```

Lo stato può automaticamente diventare:

- chiuso;
- da confermare;

fuori dal servizio.

---

# 52. Stato “FULL” non deve durare fino al giorno dopo

Anche FULL deve scadere.

Esempio:

20:45 FULL.

Alle 22:00 alcuni tavoli si liberano.

Se nessuno aggiorna, non puoi mostrare FULL alle 23:15.

Ogni stato live ha TTL.

---

# 53. Offline / connessione scarsa

Il ristoratore deve ricevere feedback chiaro:

```text
Aggiornamento inviato ✓
```

oppure:

```text
Connessione assente — riprovo…
```

Non può credere di aver messo FULL quando il server mostra ancora FREE.

---

# 54. Analytics che possono giustificare il piano PRO

Esempi:

- visualizzazioni profilo;
- aperture navigazione;
- click telefono;
- click sito;
- utenti che hanno visto FREE;
- numero aggiornamenti;
- fasce con più richieste;
- utenti che impostano alert;
- conversioni indicative “sto arrivando” future.

Il ristorante deve poter dire:

> “Pago €10, ma questa app mi porta valore.”

---

# 55. CAC: il vero problema del prezzo €4,99

Se per acquisire un ristorante devi:

- andarci fisicamente;
- parlare 30 minuti;
- richiamare;
- assisterlo;
- configurare profilo;

il costo di acquisizione può superare facilmente molti mesi di ricavo.

Con €4,99/mese devi puntare fortemente su:

- onboarding self-service;
- referral;
- associazioni di categoria;
- gruppi ristorazione;
- QR;
- passaparola;
- agenti soltanto quando ARPU cresce.

---

# 56. Partnership interessanti

In futuro:

- associazioni ristoratori;
- consorzi centro storico;
- hotel;
- uffici turistici;
- food district;
- sistemi POS;
- gestionali;
- piattaforme di prenotazione;
- Google/Apple maps deep linking;
- servizi turistici.

Un hotel potrebbe usare l’app per dire al cliente:

> “Questi 7 locali vicino all’hotel hanno posto adesso.”

---

# 57. Turismo

Il prodotto può essere particolarmente utile ai turisti.

Il turista:

- non conosce i locali;
- non vuole chiamare in italiano;
- decide all’ultimo;
- si trova già in zona;
- ha bisogno di una risposta immediata.

Quindi multilingua può avere valore presto:

- italiano;
- inglese.

Non servono 12 lingue nell’MVP.

---

# 58. Search ranking

Non ordinerei soltanto per distanza.

Possibile ranking:

```text
score =
freshness
+ distance
+ verified_status
+ user_preferences
+ restaurant_quality_signal
```

Ma attenzione.

Un ristorante che paga non dovrebbe poter apparire come “più disponibile” se non lo è.

Gli eventuali risultati sponsorizzati devono essere identificati chiaramente.

---

# 59. “Disponibile” è il filtro principale

La feature più forte potrebbe essere banalmente:

> **Mostra solo 🟢**

L’utente non deve scegliere tra 800 locali.

Deve vedere:

> “Dove posso sedermi adesso?”

Questo è il job-to-be-done.

---

# 60. Naming / messaggio

Nomi possibili, solo come brainstorming:

- Posto?
- C’è Posto
- PostoOra
- TavoloOra
- FreeTable
- SeatNow
- TavoloLive
- PostoLive

Il concetto deve essere comprensibile senza spiegazione.

### Claim

> “Scopri chi ha posto. Adesso.”

oppure

> “Niente chiamate. Guarda chi ha posto.”

---

# 61. Cosa NON deve diventare

Il rischio classico è:

> “Già che ci siamo, mettiamo recensioni.”

Poi:

> “Già che ci siamo, prenotazioni.”

Poi:

> “Delivery.”

Poi:

> “Menù.”

Poi:

> “Community.”

Dopo sei mesi hai costruito un mediocre clone di cinque piattaforme.

La disciplina deve essere:

> **availability first.**

---

# 62. Moat / difendibilità

Il bottone FULL/FREE è copiabile in un weekend.

Il codice non è il moat.

I moat possibili sono:

## 1. Densità

“Quasi tutti i ristoranti della zona sono qui.”

## 2. Abitudine

“Quando cerco posto adesso, apro questa app.”

## 3. Freschezza

“I dati sono realmente aggiornati.”

## 4. Integrazioni

Aggiornamenti automatici dai gestionali.

## 5. Relazioni B2B

Ristoranti verificati, staff e workflow già attivi.

## 6. Dataset

Pattern storici di domanda/disponibilità.

---

# 63. L’automazione sarà il vero salto di qualità

La V1 è manuale.

Il prodotto maturo dovrebbe diminuire progressivamente il numero di tocchi necessari.

Possibili segnali:

- POS;
- table management;
- prenotazioni;
- numero tavoli aperti;
- check-in;
- status del gestionale.

Se il sistema sa che:

- 18/20 tavoli sono occupati;
- 2 sono riservati tra 10 min;

può suggerire:

> “Passo automaticamente a POCHI POSTI?”

L’umano conferma.

---

# 64. Non automatizzare troppo presto

Prima devi capire:

- quali ristoratori aggiornano;
- con che frequenza;
- che cosa significa FREE per loro;
- quando sbagliano;
- che dettaglio vogliono condividere.

Altrimenti automatizzi una semantica non ancora validata.

---

# 65. KPI MVP

Non guardare inizialmente i download.

Guarda:

## Supply

- ristoranti onboarded;
- % che aggiorna almeno una volta al giorno;
- aggiornamenti per servizio;
- % status non scaduti;
- retention ristoranti a 30 giorni.

## Demand

- utenti attivi;
- ricerche “adesso”;
- sessioni con almeno un ristorante FREE;
- click navigazione;
- preferiti;
- ritorno settimanale.

## Trust

- % conferme “stato corretto”;
- stale status rate;
- mismatch report.

---

# 66. KPI più importante lato ristorante

**Restaurant active-status rate**

Esempio:

> Durante gli orari di servizio, che percentuale dei ristoranti partner mostra uno stato valido aggiornato negli ultimi 30 minuti?

Se hai 100 partner ma solo 12 hanno dati freschi, in realtà hai un network di 12.

---

# 67. KPI più importante lato utente

**Successful availability session**

Percentuale di sessioni in cui l’utente trova almeno un ristorante compatibile:

- aperto;
- vicino;
- stato fresco;
- disponibile.

Se questa metrica è alta, l’app inizia a essere un’abitudine.

---

# 68. Go / no-go dopo pilot

## GO forte

Se:

- 30+ ristoranti partecipano;
- almeno 60–70% aggiorna regolarmente nei servizi principali;
- gli utenti ricontrollano spontaneamente;
- i ristoratori dichiarano riduzione chiamate / clienti incrementali;
- lo stato errato è raro;
- alcuni ristoranti chiedono feature a pagamento.

## Attenzione

Se:

- tutti dicono che l’idea è bella;
- ma nessuno aggiorna;
- gli utenti aprono una volta;
- i locali preferiscono WhatsApp/telefono;
- i dati sono quasi sempre scaduti.

Il problema non sarebbe il design.

Sarebbe il comportamento.

---

# 69. Esperimento da fare prima del business completo

## Settimana 1

Parla con 20 locali.

## Settimana 2

Costruisci mini web dashboard.

## Settimana 3

10–15 locali reali.

## Settimana 4

Porta 100–300 tester locali.

Misura.

Soltanto dopo costruisci:

- app Android completa;
- subscription;
- analytics;
- iOS.

---

# 70. Roadmap suggerita

## FASE 0 — Discovery

- interviste;
- landing page;
- brand provvisorio;
- mockup;
- raccolta adesioni.

## FASE 1 — Concierge MVP

- dashboard web;
- lista pubblica;
- status;
- timestamp;
- TTL.

## FASE 2 — Android MVP

- app;
- location;
- lista;
- ristoranti verificati;
- push;
- preferiti.

## FASE 3 — Growth

- QR;
- referrals;
- analytics;
- Premium;
- staff.

## FASE 4 — iOS

- porting;
- stesso backend;
- stessa logica.

## FASE 5 — Automation

- API;
- POS;
- table systems;
- predictive suggestions.

---

# 71. Costi tecnici iniziali

Un MVP con poche migliaia di utenti può essere relativamente economico se progettato bene.

Costi principali:

- dominio;
- backend;
- database;
- autenticazione;
- push;
- mappe/geocoding;
- store account;
- payment provider;
- email/SMS;
- eventuale monitoring.

L’uso delle mappe/geocoding e soprattutto SMS può crescere più rapidamente del semplice database.

Per questo eviterei SMS non necessari nella V1.

Push notification costa molto meno come canale principale.

---

# 72. App Store / Google Play e subscription

Le condizioni cambiano nel tempo e vanno ricontrollate prima del lancio.

Al 2026:

- Apple ha programmi per piccoli sviluppatori con commissione ridotta al 15% su paid apps e IAP in determinate condizioni;
- Google Play ha aggiornato nel 2026 la struttura delle fee in EEA/UK/US e per le sottoscrizioni ricorrenti le componenti possono arrivare a un totale equivalente intorno al 15% con Google Play Billing, a seconda del programma e delle condizioni.

Non costruire il business plan assumendo che:

> €0,99 incassati = €0,99 di ricavo.

---

# 73. La subscription ristorante potrebbe essere venduta via web

Il ristorante è un cliente B2B.

Puoi avere:

- account web;
- fatturazione;
- pagamento;
- gestione piano.

L’app mobile diventa lo strumento operativo.

Le policy degli store e le regole fiscali vanno verificate professionalmente prima del lancio commerciale, soprattutto per i flussi digitali consumer.

---

# 74. SWOT

## Strengths

- problema comprensibile;
- UX estremamente semplice;
- MVP tecnicamente fattibile;
- valore immediato;
- forte uso mobile;
- possibile riduzione chiamate;
- possibile incremento coperti;
- dati non troppo sensibili;
- facile da demo.

## Weaknesses

- aggiornamento manuale;
- network effect;
- valore basso con pochi locali;
- stato cambia rapidamente;
- monetizzazione utente difficile;
- codice facilmente copiabile.

## Opportunities

- turismo;
- walk-in;
- last minute;
- integrazioni;
- notifiche;
- hotel;
- nightlife;
- bar;
- parrucchieri/servizi in futuro;
- eventi;
- code;
- POS.

## Threats

- Google;
- TheFork;
- OpenTable;
- Dojo;
- piattaforme locali;
- ristoratori che non aggiornano;
- utenti che tornano al telefono;
- app fatigue;
- copycat.

---

# 75. Scorecard

| Area | Voto |
|---|---:|
| Chiarezza del problema | 9/10 |
| Semplicità proposta | 9/10 |
| Fattibilità tecnica MVP | 9/10 |
| Utilità potenziale utente | 8/10 |
| Utilità potenziale ristorante | 8/10 |
| Originalità assoluta | 5/10 |
| Differenziazione possibile | 8/10 |
| Difficoltà cold-start | 9/10 |
| Rischio dati stale | 9/10 |
| Monetizzazione originale €0,99 + €4,99 | 5/10 |
| Monetizzazione freemium ottimizzata | 8/10 |
| Potenziale progetto reale | 8/10 |

---

# 76. La mia modifica principale al concept

Concept iniziale:

> “App dove utenti pagano €0,99 e ristoranti €4,99 per vedere/mettere FULL o FREE.”

Concept che costruirei:

> **“Rete live di ristoranti verificati che comunica in pochi secondi dove puoi sederti adesso, senza telefonare e senza obbligo di prenotazione.”**

Ristorante:

> aggiorna con un tap.

Utente:

> consulta gratuitamente.

Premium utente:

> alert, filtri, preferiti intelligenti.

Premium ristorante:

> analytics, dettagli, staff, notifiche, integrazioni.

Questa forma ha molta più possibilità di superare il cold-start.

---

# 77. Il principale insight strategico

Non devi convincere il ristoratore a:

> “gestire un nuovo software”.

Devi convincerlo a:

> **“toccare un semaforo.”**

E non devi convincere l’utente a:

> “usare un’altra app di ristoranti”.

Devi convincerlo che:

> **“se vuoi mangiare adesso, apri questa prima di telefonare.”**

Queste due frasi dovrebbero guidare tutto il prodotto.

---

# 78. Il test più importante in assoluto

Prima di costruire 30 schermate, porta un telefono con tre pulsanti a un ristoratore durante un servizio reale.

Chiedigli:

> “Quando cambia la situazione, riusciresti realisticamente a toccare questo?”

Se la risposta pratica è sì, hai una base.

Se nessuno vuole ricordarsi di farlo, devi risolvere quello prima di qualunque altra cosa.

---

# 79. Potenziale evoluzione oltre i ristoranti

Solo in futuro.

Lo stesso motore può diventare:

- bar;
- cocktail bar;
- beach club;
- parrucchieri walk-in;
- barber shop;
- coworking;
- campi sportivi;
- parcheggi;
- locali;
- pronto servizio;
- attrazioni con coda.

Il concetto astratto è:

> **capacità disponibile adesso, dichiarata dall’operatore.**

Ma partirei solo dalla ristorazione.

---

# 80. Conclusione finale

Il progetto **può funzionare**.

Non perché FULL/FREE sia tecnicamente sofisticato.

Proprio perché non lo è.

È una proposta forte se riesci a mantenere:

- un gesto per il ristoratore;
- un secondo per capire per l’utente;
- dati freschi;
- ristoranti vicini;
- zero confusione con la prenotazione.

Le tre decisioni che prenderei subito sono:

1. **MVP con FREE / POCHI / FULL + timestamp + scadenza automatica.**
2. **Core gratuito inizialmente su entrambi i lati per costruire densità.**
3. **Pilot iperlocale con 20–40 ristoranti prima del lancio nazionale.**

La tariffa €0,99 utente e €4,99 ristorante non è sbagliata come obiettivo, ma non la userei come barriera d’ingresso iniziale.

La parte più difficile non sarà Android, iOS, database o push notification.

Sarà creare una rete in cui, quando l’utente apre alle 20:42, vede abbastanza pallini verdi/arancioni aggiornati alle 20:38 da pensare:

> **“Perfetto. Non devo telefonare a nessuno.”**

Quando ottieni quel comportamento, hai un prodotto.

---

# Fonti e benchmark consultati

Fonti consultate nell’analisi, verificate il 24 agosto 2026:

1. **FIPE – Rapporto Ristorazione 2026**  
   https://www.fipe.it/2026/04/09/primo-piano-home-page/ristorazione-consumi-a-quota-100-miliardi-di-euro-in-calo-imprese-e-lavoratori-dipendenti/

2. **TheFork Manager – prezzi e funzionalità**  
   https://www.theforkmanager.com/it/software-ristorante-prezzi

3. **TheFork Manager – gestione disponibilità**  
   https://www.theforkmanager.com/en/restaurant-booking-management

4. **OpenTable – Online Waitlist**  
   https://www.opentable.com/restaurant-solutions/products/features/opentable-waitlist/

5. **OpenTable – Availability Controls**  
   https://www.opentable.com/restaurant-solutions/products/features/availability-controls/

6. **OpenTable – 2026 Diner Trends**  
   https://www.opentable.com/restaurant-solutions/2026-diner-trends/

7. **Google Business – Popular times, live visits and wait times**  
   https://support.google.com/business/answer/6263531

8. **Dojo – last-minute restaurant availability / virtual queues**  
   https://dojo.app/

9. **SEEAT.app – FAQ**  
   https://seeat.app/en/faq

10. **Waitless – real-time restaurant occupancy**  
    https://wait-less.in/

11. **Stripe Italia – pricing**  
    https://stripe.com/it/pricing

12. **Apple Developer – App Store Small Business Program**  
    https://developer.apple.com/app-store/small-business-program/

13. **Google Play – service fees**  
    https://support.google.com/googleplay/android-developer/answer/112622

---

## Raccomandazione operativa immediata

**Non iniziare programmando il login.**

Disegna prima queste quattro schermate:

1. ristorante — FREE / POCHI / FULL;
2. utente — lista live;
3. scheda — stato + timestamp;
4. stato scaduto — DA CONFERMARE.

Poi usale per parlare con ristoratori reali.

Se la reazione è positiva, quello è il momento di trasformarle nel vero MVP.
