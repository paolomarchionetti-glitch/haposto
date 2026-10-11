# HAPOSTO — Tessera fedeltà: specifiche (funzione nascosta)

**Versione 3 · 11 ottobre 2026 · valori confermati dal titolare · funzione spenta di default ·
nessun codice ancora scritto.**

Decisione del titolare: la tessera si **realizza subito**, ma resta **spenta e invisibile**, con
un interruttore nel pannello admin. Si può provare sul DEV in modalità test e si accende per tutti
solo se e quando si deciderà di lanciarla. Le motivazioni sono in
`HAPOSTO_PROGETTO_VISITE_E_TESSERA.md`; **dove i documenti differiscono, vale questo**.

Ogni regola ha un codice (**T1**, **T2**…) da citare nelle PR, nei test e nelle discussioni.

Legenda: 🧑 tocca al titolare · 🤖 lo fa Claude.

---

## Storia delle versioni

| Versione | Cosa è cambiato |
|---|---|
| 1 (PR #23) | Prima stesura completa |
| 2 (PR #24) | Più semplice e automatica: preavviso di 30 giorni, azzeramento dopo 6 mesi senza visite, niente contestazioni, sanzioni automatiche solo sulla tessera |
| **3 (questa)** | Valori confermati dal titolare, più quattro novità: **timbro di gruppo** con una sola scansione; **premi** in tre tipi (omaggio da una lista ampia, sconto personale, buono per la visita dopo), con tutele per il locale; **condizione del timbro** personalizzabile; **giorno doppio** a scelta del locale (nessuno o uno a settimana) |

---

## 0. In breve

- **Cos'è.** Una tessera timbri digitale per locale: «N timbri → un premio». Il timbro si ottiene
  **solo** quando il locale scansiona un QR del cliente, da solo o del suo tavolo.
- **Per chi.** Gratis per i clienti con account Google. Per i ristoratori è una funzione di Pro
  (durante la beta e la prova ce l'hanno tutti).
- **Il locale decide:**
  - quanti timbri servono;
  - quale premio dare: omaggio, sconto personale o buono;
  - a quali condizioni si ottiene il timbro;
  - se e quando c'è il giorno doppio;
  - quando si può usare il premio.

  Sempre entro limiti che lo proteggono: tetti sugli sconti, spesa minima, giorni di utilizzo,
  numero di premi per tavolo.
- **Il patto.** Chi ha iniziato una tessera la completa alle condizioni di quel giorno. Se il locale
  cambia le regole, valgono solo per le tessere nuove. Se smette, i clienti hanno 30 giorni.
- **Gruppi.** Un tavolo di amici si unisce nell'app e lo staff fa **una sola scansione** per tutti.
- **Antifrode.** Nessun timbro gratis: QR che cambia ogni 60 secondi e vale una volta sola,
  screenshot bloccati, nessun timbro a mano, limiti automatici.
- **Privacy.** Il ristoratore non vede mai nome, email o foto del cliente: solo un codice anonimo.
- **Gestione automatica.** Nessuna contestazione da seguire. Se più clienti diversi segnalano
  problemi, la tessera del locale si sospende da sola.
- **Nascosta.** Con l'interruttore spento non c'è nessun menù né tasto, e il server rifiuta ogni
  operazione.

---

## 1. Il patto in sei regole

| | Regola |
|---|---|
| **T1** | Il **timbro** si ottiene solo con una visita reale, quando il locale scansiona il QR del cliente o del suo tavolo. Non esistono timbri a mano, regalati o recuperati |
| **T2** | Le **condizioni** (timbri, premio con le sue regole, condizione del timbro, giorno doppio) sono fissate quando la tessera del cliente inizia e **non cambiano** per quella tessera |
| **T3** | Il ristoratore può cambiare le condizioni solo **per le tessere nuove**, che partono da zero |
| **T4** | Il **premio maturato** va riconosciuto entro la sua validità, alle condizioni di utilizzo che il locale aveva dichiarato (§8.3) |
| **T5** | Il premio è **personale**: vale solo per chi l'ha maturato, non per il tavolo. Non si converte mai in denaro, non si cede, si usa una volta, solo in quel locale. **Niente alcolici** |
| **T6** | Un locale che non rispetta la tessera **perde la tessera**, in automatico e a gradi (§9). Il locale resta su HAPOSTO e il suo abbonamento non cambia |

---

## 2. L'interruttore nel pannello admin

| | Regola |
|---|---|
| **T7** | Pannello admin → **Impostazioni** → `loyalty` → **modalità**. Valore iniziale: **spenta** |
| **T8** | Le modalità sono quattro (tabella sotto) |
| **T9** | **Il server decide**: ogni funzione della tessera controlla la modalità e rifiuta con `FEATURE_DISABLED` se non è permessa. L'app nasconde i menù, ma la protezione vera è sul server |
| **T10** | **Dopo il lancio non si spegne di colpo**: da «attiva» si passa a «solo esistenti» |

| Modalità | Chi la vede | Cosa si può fare |
|---|---|---|
| **Spenta** (iniziale) | Nessuno (l'admin vede solo l'interruttore) | Niente |
| **Test** | Solo i **locali tester** e i **clienti tester** scelti dall'admin (gli admin sono sempre clienti tester) | Tutto, solo fra tester |
| **Attiva** | Tutti i clienti con account; i locali con Pro | Tutto |
| **Solo esistenti** | Chi ha già una tessera iniziata | Si completano le tessere e si usano i premi; niente tessere nuove |

- **Tester:**
  - **Locali** → il locale → «**Tester tessera**»;
  - **Utenti** → l'utente → «**Tester tessera**».

  Sul DEV: il tuo account come cliente, il «ristoratore di prova» con il suo locale come tester.
- **Con la tessera non disponibile non si vede niente:** riquadro nella scheda del locale, «Le mie
  tessere», tasto «Timbra», voce «Tessera fedeltà» in Gestisci il locale, statistiche.

---

## 3. Il programma del locale

### 3.1 Cosa sceglie il ristoratore

| | Impostazione | Scelte possibili |
|---|---|---|
| **T11** | **Timbri per il premio** | da **5** a **20** |
| **T12** | **Condizione per il timbro** (una delle tre) | **a)** spesa minima a persona di **X €** (da 5 a 50); **b)** almeno **una** consumazione fra le tipologie scelte; **c)** almeno **due** consumazioni diverse fra le tipologie scelte |
| **T13** | **Tipologie** per le condizioni b) e c) | dalla lista: antipasto, primo, secondo, pizza, piatto unico o menù, dolce, bevanda, caffè |
| **T14** | **Giorno doppio** (facoltativo) | **nessuno** oppure **un giorno** della settimana; per tutto il giorno, solo a pranzo (11–15) o solo a cena (18–23) |
| **T15** | **Premio** | uno dei tre tipi del §8, con le sue regole |

Esempi di condizioni:
- «Spesa minima di 15 € a persona»;
- «Almeno una consumazione tra: pizza, primo, secondo»;
- «Almeno due consumazioni diverse tra: antipasto, primo, secondo, dolce».

La condizione la verifica lo staff alla cassa, come oggi con la tessera di carta. L'app la mostra al
cliente e allo staff.

**Valori uguali per tutti** (decisi dall'admin):
- validità del premio: **60 giorni**;
- azzeramento: dopo **6 mesi** senza visite;
- preavviso di chiusura: **30 giorni**.

### 3.2 Il patto: attivazione e versioni

| | Regola |
|---|---|
| **T16** | **Riepilogo** prima di attivare: le scelte fatte e il patto in tre righe: «Timbro ogni cliente che rispetta la condizione e mostra il QR. Riconosco i premi maturati entro la loro validità, alle condizioni dichiarate. Se smetto, i clienti hanno 30 giorni per completare». Si attiva con **Accetto**, da titolare con verifica in due passaggi |
| **T17** | L'accettazione si registra in `consent_log` (tipo `LOYALTY_PACT`) con data, versione del programma e account |
| **T18** | Ogni attivazione crea una **versione** numerata, che **non si può modificare** (il database lo impedisce) |
| **T19** | **Modificare = pubblicare una nuova versione.** Le tessere nuove usano quella; le tessere già iniziate restano sulla loro (**T2**, **T3**) |

---

## 4. Cosa può fare il ristoratore

| Situazione | Cosa succede | Regola |
|---|---|---|
| **Cambiare** qualcosa (timbri, premio, condizione, giorno doppio) | Pubblica una nuova versione. Vale **solo per chi inizia da oggi**, con timbri a zero. Chi ha già timbri completa con le condizioni di prima | **T19** |
| **Smettere** | **Chiude con 30 giorni di preavviso**. Da subito nessuna tessera nuova. Per 30 giorni chi ha una tessera può continuare a timbrare; i premi già sbloccati restano validi fino alla loro scadenza. Poi è finita | **T20** |
| **Non paga più Pro** (diventa «Non collegato») | Parte da solo lo stesso preavviso di 30 giorni | **T21** |
| **Esce da HAPOSTO** (cessazione, account cancellato, locale sospeso per altri motivi) | La tessera finisce subito, con un avviso ai clienti | **T22** |

---

## 5. La tessera del cliente

| | Regola |
|---|---|
| **T23** | La tessera **nasce al primo timbro**, legata alla versione attiva quel giorno. Al massimo **una tessera attiva per locale** per cliente |
| **T24** | **Azzeramento:** se il cliente non torna per **6 mesi**, i timbri si azzerano. Avviso gratuito 15 giorni prima, solo se mancano 1–3 timbri |
| **T25** | Arrivato a N timbri si **sblocca il premio**, valido **60 giorni**, e parte una tessera nuova alla visita dopo. Un timbro in più (giorno doppio) passa alla tessera nuova, se il locale ne accetta ancora |
| **T26** | Il cliente può **lasciare** una tessera (i timbri si cancellano). Con la cancellazione dell'account sparisce tutto |
| **T27** | Il cliente vede sempre le **regole della sua tessera**, cioè quelle della sua versione: timbri, condizione, giorno doppio, premio e come si usa |

---

## 6. Timbrare: il flusso veloce

### 6.1 Da soli

**Il cliente** (alla cassa, quando paga):
1. scheda del locale (o «Le mie tessere») → **Mostra il mio QR**. Senza account: «Accedi con Google
   per raccogliere i timbri», una volta sola;
2. il QR compare **subito** (meno di mezzo secondo), con:
   - luminosità al massimo e cornice animata;
   - un codice di riserva di 6 caratteri;
   - un conto alla rovescia di 60 secondi, con rinnovo automatico;
3. appena il locale scansiona, entro 1 secondo la schermata mostra **«✓ +1 timbro · 4 su 10»**
   (o «+2, giorno doppio», o «🎁 Premio sbloccato»).

**Il locale** (titolare o collaboratore con verifica in due passaggi):
1. dashboard → **📷 Timbra**: si apre all'istante lo scanner di Google, che non chiede il permesso
   della fotocamera all'app;
2. dopo la scansione, in meno di 1 secondo compare l'esito:

   ```
   ✓ Cliente K4F7 · +1 timbro · 4 su 10
   Condizione: almeno una consumazione tra pizza, primo, secondo
   🎁 Premio da usare: 20% sulla sua consumazione (max 10 €)   [ Applicato ]
   [ Annulla (entro 2 minuti) ]     [ Timbra il prossimo ]
   ```

3. **Inserisci codice** se il QR non si legge.

### 6.2 In gruppo: una sola scansione per il tavolo

Per un tavolo di amici che usano tutti HAPOSTO, lo staff non deve scansionare un QR a testa.

1. **Uno del tavolo** apre il suo QR e tocca **👥 Siamo in gruppo**: compare un **QR del tavolo**.
2. **Gli altri** aprono HAPOSTO → **Unisciti a un tavolo** e lo inquadrano (scanner di Google, senza
   permessi). Sul telefono del primo si vede «Tavolo: 4 persone ✓».
3. Alla cassa **lo staff scansiona solo il QR del tavolo**. Esito:
   «Tavolo di 4 · 4 timbri (1 già timbrato oggi: escluso)». Ognuno vede il suo timbro sul proprio
   telefono.

| | Regola |
|---|---|
| **T28** | Gruppo fino a **20 persone**. Ci si unisce entro **10 minuti** inquadrando il QR del tavolo, che vale 60 secondi e si rinnova. Si sta in un solo gruppo alla volta |
| **T29** | Ogni membro riceve **il suo timbro**, con le sue regole (un timbro ogni 4 ore per locale, versione della sua tessera). Chi non le rispetta viene escluso da solo |
| **T30** | Lo staff vede **quante persone** sono nel gruppo prima di confermare: se al tavolo sono di meno, tocca **Annulla** |
| **T31** | La condizione del timbro (**T12**) vale **per ogni persona**: per esempio «spesa minima di 15 € a persona» |

Il gruppo serve anche con i **conti separati**: una scansione, ognuno ha il suo timbro.

### 6.3 Regole comuni

| | Regola |
|---|---|
| **T32** | Ogni scansione aggiorna **subito** il database: tessere, timbri, premi, statistiche |
| **T33** | **Annulla** serve solo per un errore dello staff: cliente sbagliato, doppia scansione, gruppo più numeroso del tavolo. Vale **solo nei 2 minuti** dopo la scansione ed è registrato |
| **T34** | La dashboard resta com'è: il tasto **Timbra** è secondario e compare solo se il locale ha la tessera attiva o in preavviso |

---

## 7. QR e antifrode: nessun timbro gratis

Tutte le difese sono **automatiche**: nessuno deve controllare niente.

| Tentativo | Difesa | Regola |
|---|---|---|
| Foto o screenshot del QR da riusare | Il QR vale **60 secondi** e **una volta sola**; la schermata **blocca gli screenshot**; la cornice animata fa riconoscere allo staff una foto statica | **T35** |
| Unirsi a un tavolo da lontano | Il QR del tavolo vale 60 secondi, blocca gli screenshot e va inquadrato dal vivo. Lo staff vede il numero del gruppo (**T30**) | **T35**, **T30** |
| Inventare un QR o un codice | Codice casuale creato solo dal server: 128 bit nel QR, ~900 milioni di combinazioni per il codice di riserva. Dopo 10 codici sbagliati in 10 minuti, l'inserimento si blocca per 10 minuti | **T36** |
| Più timbri nella stessa visita | **1 timbro ogni 4 ore** per locale e per persona (2 nel giorno doppio) | **T37** |
| Il titolare o lo staff timbrano la propria tessera | Chi gestisce un locale usa HAPOSTO anche come cliente, con lo stesso account. **Il sistema lo impedisce**: chi gestisce un locale non può avere la tessera di quel locale, nemmeno dentro un gruppo | **T38** |
| Timbri a mano | **Non esistono** (**T1**). Se il cliente dimentica il QR, il timbro di quella visita si perde, come con la tessera di carta | **T1** |
| Il locale timbra in massa clienti inesistenti | **Tetto automatico**: max **60 scansioni ogni 10 minuti** e **300 al giorno** per locale. Una scansione di gruppo conta come una | **T39** |

Il GPS non serve: il locale che scansiona è già la prova della presenza.

---

## 8. Il premio

Il premio deve invogliare il cliente a tornare e a mostrare il QR, ma **il locale non ci deve
perdere**. Per questo il ristoratore sceglie fra tre tipi, ognuno con regole che lo proteggono.

### 8.1 I tre tipi di premio

| | Tipo | Cosa sceglie il ristoratore | Limiti fissi |
|---|---|---|---|
| **T40** | **🎁 Omaggio** | un prodotto dalla lista del §8.2 | solo prodotti del locale, niente alcolici |
| **T41** | **％ Sconto personale** | percentuale (dal **5** al **50%**) sulla **consumazione di chi ha il premio**, con un **tetto massimo** in euro (da **5** a **50 €**, obbligatorio) e, se vuole, una spesa minima | solo sulla consumazione della persona, **mai sul tavolo**; non si converte in denaro |
| **T42** | **🎟 Buono per la visita dopo** | importo da **2** a **20 €** e spesa minima per usarlo | spesa minima **almeno il doppio** del buono (es. 5 € su almeno 10 €); si usa **solo dalla visita successiva**; non dà resto |

Esempi: «Dolce offerto»; «20% sulla tua consumazione, max 10 €»; «5 € di sconto sulla prossima
visita, con una spesa di almeno 15 €».

### 8.2 Lista degli omaggi

Caffè · Dolce · Gelato o sorbetto · Frutta · Antipasto · Stuzzichino o bruschetta · Contorno · Primo
piatto · Secondo piatto · Pizza · Piatto del giorno · Menù bambini · Bibita analcolica · Acqua ·
Aperitivo analcolico · Coperto.

La lista si amplia solo con una nuova versione dell'app. **Niente alcolici.**

### 8.3 Come si usa il premio (tutele per il locale)

| | Regola | Scelta del ristoratore |
|---|---|---|
| **T43** | **Da quando** si usa | «subito, alla stessa visita» oppure «dalla visita successiva». Il buono (**T42**) è sempre dalla visita successiva. Usarlo alla visita dopo è un motivo in più per tornare |
| **T44** | **In quali giorni** si usa | tutti i giorni, oppure solo i giorni scelti (almeno 3 a settimana), per esempio «non il venerdì e il sabato sera». Così i premi riempiono le sere più vuote |
| **T45** | **Quanti per tavolo** alla stessa visita | da 1 a 10, oppure senza limite (proposta: 4). Se in un tavolo ci sono più premi, gli altri restano validi per un'altra visita. Nessun «30 dolci in una volta» |
| **T46** | **Cumulabile** con l'offerta della serata o altre promozioni | sì oppure no (proposta: no) |
| **T47** | **Validità** | 60 giorni dallo sblocco, uguale per tutti |

**Consegna:** alla scansione lo staff vede i premi disponibili di quella persona o del tavolo, con le
regole, e tocca **Consegnato** o **Applicato** per ognuno. Il cliente può dire «la prossima volta».
Nessuna conferma e nessuna contestazione, come con la tessera di carta.

**Il cliente** vede sempre, sulla sua tessera, il premio e come si usa: da quando, in quali giorni,
fino a quando, se è cumulabile.

---

## 9. Segnalazioni e sanzioni automatiche

| | Regola |
|---|---|
| **T48** | **Chi può segnalare:** solo un cliente che ha avuto **almeno un timbro in quel locale negli ultimi 60 giorni**. Due tasti, senza testo: «Non hanno voluto timbrare», «Non mi hanno riconosciuto il premio». **Una segnalazione per cliente per locale ogni 90 giorni.** Segnalando non si ottiene niente |
| **T49** | **Livello 1, avviso:** **3** segnalazioni di clienti diversi in 60 giorni → avviso automatico al titolare, nella dashboard e con una notifica. Nessuna conseguenza |
| **T50** | **Livello 2, tessera sospesa:** **5** segnalazioni di clienti diversi in 60 giorni → la tessera del locale si **sospende da sola per 90 giorni**; le tessere dei clienti finiscono, con un avviso. Dopo 90 giorni il locale può riattivarla accettando di nuovo il patto |
| **T51** | **Livello 3, tessera tolta:** una seconda sospensione entro 12 mesi → la tessera viene **tolta**. Solo l'admin può ridargliela |
| **T52** | **Il locale non viene mai tolto da HAPOSTO** per la tessera: resta in mappa ed elenco, con il suo stato e il suo abbonamento |
| **T53** | Il locale vede quante segnalazioni ha (es. «2 negli ultimi 60 giorni; la tessera si sospende a 5»), senza sapere chi le ha fatte |
| **T54** | **Clienti:** nessuna sanzione automatica; i limiti del §7 rendono inutile imbrogliare. Per i casi gravi l'admin può sempre bloccare un account, come oggi |

Le soglie sono impostazioni dell'admin. L'admin può togliere una sospensione a mano, ma **non deve**
fare niente perché il sistema funzioni.

---

## 10. Privacy

| | Regola |
|---|---|
| **T55** | **Il locale vede solo un codice anonimo** (es. `K4F7`): casuale, diverso per ogni locale, stabile nel tempo. Mai nome, email, foto, telefono, altre tessere. Nei gruppi vede solo i codici e il numero di persone |
| **T56** | **I QR non contengono dati**: solo codici casuali. Il server conserva solo le impronte |
| **T57** | **Niente GPS, niente impronta del dispositivo** |
| **T58** | **Conservazione:** codici QR e gruppi 1 giorno; timbri e visite 24 mesi; tessere e premi chiusi 12 mesi, poi resta solo il conteggio anonimo; segnalazioni 12 mesi |
| **T59** | **Al primo uso** il cliente vede una schermata breve: cosa vede il locale, cosa conserva HAPOSTO, per quanto. Poi accetta |

---

## 11. Statistiche

**Per il ristoratore** (Gestisci il locale → Statistiche → Tessera; le vedono anche i collaboratori;
mai dati personali):
- ultimi 7 / 30 / 90 giorni:
  - visite timbrate e persone timbrate;
  - tavoli di gruppo;
  - clienti nuovi e di ritorno;
  - tessere iniziate;
  - timbri normali e doppi;
- **premi**: sbloccati, usati, scaduti; per gli sconti e i buoni, il totale degli sconti riconosciuti
  (dichiarati dallo staff con «Applicato»), per sapere quanto costa la tessera;
- **clienti vicini al premio** (quanti a N−1, N−2), senza sapere chi sono;
- **giorni e orari** in cui arrivano i clienti con la tessera (per scegliere il giorno doppio);
- elenco delle tessere con **codice anonimo**: timbri, inizio, ultima visita;
- segnalazioni ricevute e soglie (**T53**).

**Per l'admin** (pannello → nuova scheda **Tessere**, solo da consultare):
- totali di locali con tessera, tessere, timbri e premi;
- tipi di premio scelti dai locali;
- versioni e patti accettati;
- segnalazioni e sospensioni automatiche;
- impostazioni e tester.

---

## 12. Account, Gratis e Plus

| | Regola |
|---|---|
| **T60** | **La tessera è gratis** per chi accede con Google, gruppi e avvisi compresi |
| **T61** | **L'accesso si chiede solo quando serve** (alla prima «Mostra il mio QR» o «Unisciti a un tavolo») |

**Plus (0,99 €/mese)** oggi comprende avvisi «si è liberato», preferiti sincronizzati, raggio di
100 km e «di solito». Proposte da decidere alla Tappa 2, senza togliere nulla al Gratis:

| Idea | La mia scelta |
|---|---|
| **Filtri avanzati** (cucina, aperto ora, con offerta, con tessera) | ✅ sì |
| **Avviso a orario** («avvisami se stasera dalle 20 c'è posto da X») | ✅ sì |
| **Widget sulla schermata Home** del telefono | ✅ sì |
| Liste personali, storico personale | 🟡 forse |
| Timbri in più per chi ha Plus | ❌ no: la tessera è uguale per tutti |

---

## 13. Pannello admin

- **Impostazioni** → `loyalty`:
  - modalità;
  - limiti (timbri, percentuali, tetti, importi dei buoni, gruppo);
  - validità del premio, azzeramento, preavviso;
  - finestra delle 4 ore e tetti di scansione;
  - soglie delle segnalazioni.
- **Locali** → il locale: «Tester tessera»; versioni; statistiche; eventuale sospensione da
  togliere o tessera da ridare (facoltativo).
- **Utenti** → l'utente: «Tester tessera».
- **Tessere** (scheda nuova): i numeri del §11, solo da leggere.
- **Registro:** attivazioni, versioni, chiusure, sospensioni automatiche, annullamenti.

---

## 14. Aspetti legali

La tessera con premi offerti dal locale stesso (omaggi dei suoi prodotti, sconti sulla sua
consumazione, buoni da usare da lui) è la forma comune delle tessere fedeltà di bar e ristoranti.
Le regole del §8 tengono il premio sempre **personale**, **non convertibile in denaro** e
**limitato**. Non serve un lavoro legale dedicato; basta aggiungere poche righe ai testi già
previsti:
- **privacy:** cosa vede il locale (codice anonimo), cosa conserva HAPOSTO e per quanto (§10);
- **termini per gli utenti:** come funzionano timbri, gruppi, azzeramento, premi e la chiusura con
  preavviso;
- **termini per i ristoratori:** il patto in tre righe (**T16**); il premio è un'iniziativa del
  locale; sospensione automatica della tessera (§9).

Queste righe si fanno rileggere insieme agli altri documenti legali alla Tappa 5 della roadmap,
senza costi in più. Nella stessa occasione si fa confermare il trattamento di sconti e buoni.
La modalità **test** si può usare anche prima.

---

## 15. Struttura tecnica

### 15.1 Database (migration `0018`, rieseguibile, con controlli in CI)

| Tabella | Contenuto |
|---|---|
| `loyalty_programs` | uno per locale: stato (`NONE`, `ACTIVE`, `CLOSING`, `SUSPENDED`, `REMOVED`, `ENDED`), versione attiva, tester sì/no, fine del preavviso, sospeso fino a |
| `loyalty_program_versions` | versioni **immutabili** (un trigger blocca le modifiche): numero, timbri, condizione (tipo, spesa minima, tipologie), giorno doppio (giorno e fascia), premio (tipo, omaggio, percentuale, tetto, importo, spesa minima, da quando, giorni di utilizzo, max per tavolo, cumulabile), accettata da / quando |
| `loyalty_members` | locale + cliente → **codice anonimo** casuale (**T55**) |
| `loyalty_cards` | tessera: versione, timbri, inizio, ultima visita, stato |
| `loyalty_groups` | tavolo di gruppo: capogruppo, membri, creato, scade (10 minuti), usato |
| `loyalty_stamps` | ogni timbro: tessera, gruppo (se c'è), chi ha scansionato, quando, timbri (1 o 2), annullato sì/no |
| `loyalty_rewards` | premio: regole copiate dalla versione, sbloccato, utilizzabile da, scade, usato da / quando, sconto dichiarato |
| `visit_tokens` | impronta del QR (personale o del tavolo) e del codice di riserva, cliente o gruppo, scadenza (60 s), usato da / quando, esito |
| `loyalty_reports` | segnalazioni: cliente, locale, tipo, data |

Più:
- `app_config` → `loyalty`: modalità, limiti e soglie (`admin_set_config` la valida);
- `profiles.loyalty_tester`;
- funzione del piano `LOYALTY` aggiunta a Pro.

**Funzioni principali** (tutte sul server, con verifica della modalità **T9**):
- **cliente:**
  - `loyalty_access`, `create_visit_token`, `visit_token_status`;
  - `create_loyalty_group`, `join_loyalty_group`;
  - `my_loyalty_cards`, `leave_loyalty_card`, `report_loyalty_problem`;
- **locale:**
  - `register_stamp` (QR personale, QR del tavolo o codice), `undo_stamp`, `use_reward`;
  - `publish_loyalty_version` (patto), `close_loyalty_program`;
  - `restaurant_loyalty_stats`, `restaurant_loyalty_cards`;
- **admin:** impostazioni, tester, togliere una sospensione o ridare la tessera, statistiche.

**Lavori pianificati:**
- azzeramento e avvisi;
- scadenza dei premi;
- fine del preavviso;
- soglie delle segnalazioni;
- pulizia.

Nella stessa migration si sistema anche `admin_restaurant_detail` dal SQL Editor (problema già
annotato).

### 15.2 App

- **Cliente:**
  - riquadro nella scheda del locale (timbri, premio e come si usa);
  - QR personale con screenshot bloccati (`FLAG_SECURE`), cornice animata e rinnovo ogni 60 s;
  - **Siamo in gruppo** (QR del tavolo) e **Unisciti a un tavolo** (scanner di Google);
  - Le mie tessere, segnalazioni, schermata della privacy al primo uso;
  - tutto nascosto senza accesso alla funzione.
- **Ristoratore:**
  - Gestisci il locale → Tessera fedeltà: procedura guidata (timbri, condizione, giorno doppio,
    premio e regole di utilizzo, riepilogo e patto), nuova versione, chiusura;
  - tasto **Timbra** con lo scanner di Google (`play-services-code-scanner`, gratuito, senza
    permesso della fotocamera);
  - esito singolo o di gruppo con i premi da consegnare;
  - inserimento del codice, statistiche.
- **Pannello admin:** §13.

### 15.3 Verifiche

- **SQL** (`step22_loyalty_checks.sql` in CI): un controllo per ogni regola verificabile dal
  database, in particolare:
  - modalità e tester;
  - immutabilità delle versioni;
  - limiti dei premi (percentuale, tetto, buono almeno metà della spesa minima, solo dalla visita
    dopo, giorni ≥ 3, max per tavolo);
  - gruppo (20 persone, 10 minuti, un gruppo alla volta, autotimbro escluso);
  - token monouso, 4 ore, annullamento entro 2 minuti, tetti di scansione;
  - preavviso, azzeramento, soglie;
  - privacy: il locale non legge mai email e nomi.
- **Kotlin:** test della logica (riepiloghi, regole del premio, conti alla rovescia) e della
  visibilità a funzione spenta.
- **Costi:** nessuno (Supabase Free, scanner gratuito).

---

## 16. Piano di lavoro

| PR | Contenuto | Visibile? |
|---|---|---|
| **A** | Database 0018, controlli SQL, impostazione `loyalty` (spenta) e tester nel pannello admin | No |
| **B** | App del ristoratore: procedura guidata e patto, Timbra (singolo e gruppo), premi, statistiche | Solo ai tester in modalità test |
| **C** | App del cliente: QR, gruppo, Le mie tessere, segnalazioni, avvisi | Solo ai tester |
| **D** | Pannello admin: scheda Tessere; guida di prova sul DEV | Admin |
| **E** | Righe da aggiungere a privacy e termini (§14) | — |

Dopo ogni PR, come sempre:
- 🧑 migration sul DEV;
- prova con due account (tu come cliente, il «ristoratore di prova» come locale; per il gruppo
  serve un terzo account o l'emulatore), in modalità **test**;
- registro e stato aggiornati.

---

## 17. Altre idee (facoltative, dopo la prima versione)

- **«C'era posto quando sei arrivato?»** dopo il timbro: misura l'affidabilità degli stati.
- **Serata a timbro doppio** collegata all'offerta della serata (solo a favore del cliente).
- **Riga sulla tessera** nella pagina pubblica `/r/…` e sull'adesivo in vetrina, a funzione accesa.
- **Avviso al locale** «hai 3 clienti a un timbro dal premio», senza dire chi sono.

---

## 18. Valori iniziali (confermati dal titolare l'11 ottobre 2026)

| # | Valore | Deciso |
|---|---|---|
| 1 | Timbri per il premio (scelta del ristoratore) | da 5 a 20 |
| 2 | Validità del premio dopo lo sblocco | 60 giorni |
| 3 | Azzeramento dei timbri per inattività | 6 mesi senza visite |
| 4 | Preavviso quando il locale smette o non paga più | 30 giorni |
| 5 | Tempo minimo fra due timbri nello stesso locale | 4 ore |
| 6 | Durata del QR | 60 secondi, rinnovo automatico |
| 7 | Annullamento di un timbro sbagliato | entro 2 minuti |
| 8 | Giorno doppio | a scelta del locale: **nessuno o uno** a settimana (tutto il giorno, pranzo o cena) |
| 9 | Tetti di scansione per locale | 60 ogni 10 minuti, 300 al giorno (una scansione di gruppo conta come una) |
| 10 | Soglie delle segnalazioni | avviso a 3, sospensione a 5 (clienti diversi, in 60 giorni); sospensione di 90 giorni; tessera tolta alla seconda sospensione in 12 mesi |
| 11 | Premi | tre tipi: omaggio dalla lista del §8.2; sconto personale 5–50% con tetto 5–50 €; buono 2–20 € con spesa minima almeno doppia, dalla visita dopo. Regole di utilizzo scelte dal locale (§8.3) |
| 12 | Condizione del timbro | a scelta del locale: spesa minima a persona (5–50 €), oppure almeno una o almeno due consumazioni fra le tipologie scelte |
| 13 | Nome nell'app | «Tessera» |
| 14 | Gruppo | fino a 20 persone, unione entro 10 minuti |
| 15 | Premi per tavolo alla stessa visita (proposta, il locale la cambia) | 4 |
