# HAPOSTO — Tessera fedeltà: specifiche (funzione nascosta)

**11 ottobre 2026 · stato: specifiche approvate per la realizzazione · funzione spenta di default.**

Decisione del titolare: la tessera si **realizza subito**, ma resta **spenta e invisibile**, con
un interruttore nel pannello admin. Si può provare sul DEV in modalità test e si accende per tutti
solo se e quando si deciderà di lanciarla. Questo documento sostituisce le parti operative della
proposta `HAPOSTO_PROGETTO_VISITE_E_TESSERA.md`, che resta per le motivazioni. **Dove i due
documenti differiscono, vale questo.**

Ogni regola ha un codice (**T1**, **T2**…) da citare nelle PR, nei test e nelle discussioni.

Legenda: 🧑 tocca al titolare · 🤖 lo fa Claude · ⚖️ serve un professionista.

---

## 0. In breve

- **Cos'è.** Una tessera timbri digitale per locale: «N timbri → un premio», scelto dal ristoratore
  e mai in denaro. Il timbro si ottiene **solo** quando il locale scansiona il QR del cliente.
- **Per chi.**
  - Clienti: gratis, serve solo l'accesso con Google.
  - Ristoratori: funzione di Pro. Durante la beta e la prova ce l'hanno tutti.
- **Il patto.** Quando il ristoratore attiva una tessera accetta regole che **non può peggiorare**
  per chi ha già iniziato. Ogni tessera iniziata resta valida alle condizioni di quel giorno fino
  alla sua scadenza naturale. Chi viola il patto viene sospeso dall'app.
- **Antifrode.** Nessun timbro gratis, in nessun modo:
  - QR che cambia, vale 60 secondi, una volta sola;
  - screenshot bloccati e QR "vivo" (animato), riconoscibile da una foto;
  - niente timbri a mano;
  - limiti e segnalazioni automatiche.
- **Privacy.** Il ristoratore non vede mai nome, email o foto del cliente: solo un codice anonimo.
  Niente GPS.
- **Nascosta.** Con l'interruttore spento non c'è nessun menù, nessun tasto, nessuna scritta, e il
  server rifiuta ogni operazione. Il codice è comunque nel repository pubblico: «nascosta» vuol dire
  invisibile e inutilizzabile nell'app, non segreta.

---

## 1. Il patto in sei regole

| | Regola |
|---|---|
| **T1** | Il **timbro** si ottiene solo con una visita reale, quando il locale scansiona il QR del cliente. Non esistono altri modi: niente timbri a mano, regalati o recuperati |
| **T2** | Le **condizioni** (timbri richiesti, premio, scadenze, giorni doppi) sono fissate quando la tessera del cliente inizia e **non cambiano più** per quella tessera |
| **T3** | Il ristoratore può cambiare le condizioni solo **per le tessere nuove**, che partono da zero |
| **T4** | Il **premio** maturato è un impegno del locale: va consegnato entro la sua validità, alla visita che sceglie il cliente |
| **T5** | Il premio **non è mai denaro**: niente contanti, credito, buoni, gift card, «€ X di sconto» |
| **T6** | Chi viola il patto (locale o cliente) viene **sospeso** dall'app. Il locale sparisce da mappa ed elenco, l'account del cliente viene bloccato (§9) |

---

## 2. L'interruttore nel pannello admin

| | Regola |
|---|---|
| **T7** | Pannello admin → **Impostazioni** → `loyalty` → **modalità**. Valore iniziale: **spenta** |
| **T8** | Le modalità sono quattro (tabella sotto) |
| **T9** | **Il server decide**: ogni funzione della tessera controlla la modalità e rifiuta con `FEATURE_DISABLED` se non è permessa. L'app nasconde i menù, ma la protezione vera è sul server |
| **T10** | **Dopo il lancio non si può più spegnere del tutto.** Da «attiva» si passa solo a «solo esistenti», così il patto con chi ha già timbri resta rispettato |

| Modalità | Chi la vede | Cosa si può fare |
|---|---|---|
| **Spenta** (iniziale) | Nessuno (l'admin vede solo l'interruttore e la scheda Tessere vuota) | Niente |
| **Test** | Solo i **locali tester** e i **clienti tester**, scelti dall'admin (gli admin sono sempre clienti tester) | Tutto, solo fra tester |
| **Attiva** | Tutti i clienti con account; i locali con la funzione `LOYALTY` (Pro) | Tutto |
| **Solo esistenti** | Chi ha già una tessera iniziata | Si completano le tessere e si consegnano i premi; niente tessere nuove né programmi nuovi |

- **Tester:**
  - **Locali** → il locale → «**Tester tessera**»;
  - **Utenti** → l'utente → «**Tester tessera**».

  Sul DEV: il tuo account come cliente, il «ristoratore di prova» con il suo locale come tester.
- **Cosa resta nascosto con la tessera non disponibile:** riquadro nella scheda del locale, «Le mie
  tessere», tasto «Timbra» nella dashboard, voce «Tessera fedeltà» in Gestisci il locale,
  statistiche della tessera, righe nella pagina pubblica del sito e nell'adesivo QR.

---

## 3. Il programma del locale

### 3.1 Cosa sceglie il ristoratore (entro limiti fissati dall'admin)

| | Impostazione | Limiti (modificabili solo dall'admin) | Proposta iniziale |
|---|---|---|---|
| **T11** | Timbri per il premio | da **5** a **20** | 10 |
| **T12** | Premio | tipo + descrizione (§8) | — |
| **T13** | Validità del premio dopo lo sblocco | da **30** a **180** giorni | 60 |
| **T14** | Durata della tessera dal primo timbro | **6** o **12** mesi | 12 |
| **T15** | Giorni con timbro doppio | da 0 a **2** giorni della settimana | nessuno |
| **T16** | Condizione per il timbro | a scelta: «un pasto al tavolo», «una consumazione al tavolo», oppure «spesa minima di X €» (X da 5 a 50) | un pasto al tavolo |

La spesa minima è una **condizione** per ricevere il timbro, non un premio: non contrasta con
**T5**.

### 3.2 Il patto: attivazione e versioni

| | Regola |
|---|---|
| **T17** | **Riepilogo del patto** prima di attivare, con le scelte e gli impegni: «Mi impegno a timbrare ogni cliente che rispetta la condizione e mostra il QR; a consegnare ogni premio maturato entro la sua validità; a non chiudere la tessera prima che scadano quelle già iniziate, salvo cessazione dell'attività». Si attiva solo con la spunta **Accetto il patto**, da titolare con verifica in due passaggi |
| **T18** | L'accettazione si registra in `consent_log` (tipo `LOYALTY_PACT`) con data, versione del programma, account e versione dei termini. Le clausole onerose richiedono l'approvazione specifica (artt. 1341–1342 c.c., come per le condizioni dei ristoranti) |
| **T19** | Ogni attivazione crea una **versione** numerata. Una versione attivata **non si può modificare** (il database lo impedisce) |
| **T20** | **Modificare = pubblicare una nuova versione.** Le tessere nuove usano quella; le tessere già iniziate restano sulla loro (**T2**, **T3**) |

---

## 4. Cosa può e non può fare il ristoratore

| Situazione | Cosa succede | Regola |
|---|---|---|
| Vuole **cambiare** timbri o premio | Pubblica una nuova versione (nuovo patto). Vale **solo per chi inizia da oggi**, con timbri a zero. Chi ha 9 timbri su 10 prende il premio della versione in cui ha iniziato | **T20** |
| Vuole **smettere** | **Chiude la tessera con preavviso**: da subito nessuna tessera nuova; quelle iniziate continuano fino alla loro scadenza (massimo 12 mesi), premi compresi. Poi la tessera si chiude da sola. I clienti ricevono un avviso con la data | **T21** |
| Vuole togliere il premio a chi è a 9 su 10 | **Non può.** È proprio ciò che il patto impedisce | **T2** |
| **Ferie o chiusura temporanea** | Dichiara le date: le scadenze delle tessere e dei premi attivi si **allungano** degli stessi giorni (mai si accorciano). Max 60 giorni l'anno | **T22** |
| **Non paga più Pro** (diventa «Non collegato») | Come una chiusura con preavviso: niente tessere nuove, le iniziate si completano. Lo scanner resta disponibile solo per quelle | **T23** |
| **Chiude l'attività** (cessazione, fallimento) | Lo comunica a HAPOSTO (o lo verifica l'admin). L'admin **termina** la tessera con motivo «cessazione»; i clienti vengono avvisati. Nessuna sanzione al locale; i premi non consegnati decadono | **T24** |
| Il titolare **cancella l'account** | Come la cessazione. Se c'è un altro titolare, il patto passa a lui | **T25** |
| **Sospeso per violazione** | §9: sparisce da mappa ed elenco; la tessera viene terminata; per 12 mesi non può riattivarla | **T26** |
| Il locale **cambia titolare** (nuova gestione) | Decide l'admin caso per caso. Di norma il nuovo titolare subentra nel patto o lo termina come una cessazione, con avviso ai clienti | **T27** |

---

## 5. La tessera del cliente

| | Regola |
|---|---|
| **T28** | La tessera **nasce al primo timbro**, legata alla versione attiva quel giorno. Massimo **una tessera attiva per locale** per cliente |
| **T29** | **Scadenza della tessera:** primo timbro + durata della versione (6 o 12 mesi), allungata dalle ferie (**T22**). Scaduta senza premio: i timbri decadono. Avvisi gratuiti 30 e 7 giorni prima, se mancano 1–3 timbri |
| **T30** | Arrivato a N timbri si **sblocca il premio** (validità della versione) e la tessera è completata. Un timbro in più (giorno doppio) passa alla tessera successiva, se il locale ne accetta di nuove |
| **T31** | **Premio:** «🎁 da ritirare entro il …». Si consegna alla visita che sceglie il cliente (§8). Avviso gratuito 7 giorni prima della scadenza |
| **T32** | Il cliente può **lasciare** una tessera (Le mie tessere → Esci): i suoi timbri si cancellano. Con la cancellazione dell'account sparisce tutto |
| **T33** | Il cliente vede sempre le **regole della sua tessera**: timbri, premio, scadenze, giorni doppi, condizione, data del patto. Sono quelle della sua versione, anche se il locale ne ha pubblicata una nuova |

---

## 6. Timbrare: il flusso veloce

**Il cliente** (alla cassa, quando paga):
1. scheda del locale (o «Le mie tessere») → **Mostra il mio QR**. Senza account: «Accedi con Google
   per raccogliere i timbri» (una volta sola);
2. il QR compare **subito**: il codice si crea mentre la schermata si apre, in meno di mezzo
   secondo. Luminosità al massimo, cornice animata, codice di riserva di 6 caratteri, conto alla
   rovescia di 60 secondi con **rinnovo automatico**;
3. appena il locale scansiona, entro 1 secondo la schermata mostra **«✓ +1 timbro · 4 su 10»**
   (o «+2, giorno doppio», o «🎁 Premio sbloccato»).

**Il locale** (titolare o collaboratore con verifica in due passaggi):
1. dashboard → **📷 Timbra**: lo scanner di Google si apre all'istante, senza permesso della
   fotocamera per l'app;
2. inquadra → in meno di 1 secondo il riquadro dell'esito:

   ```
   ✓ Cliente K4F7 · +1 timbro · 4 su 10
   Persone al tavolo: [−] 2 [+]
   🎁 Premio da consegnare: dolce offerto   [ Consegna ora ]
   [ Annulla (entro 2 minuti) ]     [ Timbra il prossimo ]
   ```

3. **Inserisci codice** se il QR non si legge;
4. **Annulla** solo entro 2 minuti e solo per un errore (persona sbagliata, doppia scansione).
   Resta nel registro; troppi annullamenti generano una segnalazione all'admin.

| | Regola |
|---|---|
| **T34** | Ogni scansione aggiorna **subito** il database: tessera, timbri, premio, statistiche. Il telefono del cliente lo vede entro 1 secondo |
| **T35** | La dashboard resta com'è: il tasto **Timbra** è secondario e compare solo se il locale ha una tessera attiva o in chiusura |

---

## 7. QR e antifrode: nessun timbro gratis

| Tentativo | Difesa | Regola |
|---|---|---|
| Fotografare o fare lo screenshot del QR e riusarlo | Il QR vale **60 secondi** e **una volta sola**; la schermata **blocca gli screenshot** (`FLAG_SECURE`); la cornice animata e l'orologio fanno riconoscere allo staff una foto statica | **T36** |
| Mandare il QR a un amico che è al ristorante (timbro senza esserci) | Come sopra; in più il timbro va sempre al **titolare dell'account** del QR, che al massimo ottiene un timbro per locale ogni 4 ore. Le segnalazioni automatiche intercettano gli schemi ripetuti | **T36**, **T38** |
| Inventare un QR o un codice | Il codice è casuale (128 bit nel QR, 6 caratteri di riserva su ~900 milioni di combinazioni) e lo crea solo il server. I codici di riserva sbagliati sono limitati: al decimo errore in 10 minuti lo scanner si blocca per 10 minuti | **T37** |
| Più timbri nella stessa visita | **1 timbro per tessera ogni 4 ore** per locale (valore dell'admin), 2 nei giorni doppi | **T38** |
| Il titolare o lo staff timbrano se stessi | Chi gestisce un locale non può avere la tessera di quel locale | **T39** |
| Timbri a mano, regali, «recuperi» | **Non esistono** (**T1**). Errori del cliente (QR non mostrato): il timbro di quella visita si perde, come con la tessera di carta dimenticata a casa | **T1** |
| Il locale crea clienti finti | Account Google veri, limite di scansioni (max 60 ogni 10 minuti e 300 al giorno per locale), segnalazioni automatiche (stessi clienti timbrati spesso dallo stesso collaboratore, account nuovi con timbri in un solo locale, premi consegnati subito dopo lo sblocco) | **T40** |
| Il locale annulla il decimo timbro per non dare il premio | L'annullamento vale solo 2 minuti ed è registrato; il cliente vede subito il timbro e l'annullamento e può segnalare | **T41** |
| Il locale segna «premio consegnato» senza darlo | Il cliente vede subito «premio consegnato» e ha **48 ore** per segnalare «non l'ho ricevuto» | **T42** |
| Cliente con più account | Ogni account ha le sue tessere, ma ogni timbro richiede comunque una visita scansionata. Gli account duplicati evidenti si sospendono (§9) | **T43** |

Il GPS non serve: il locale che scansiona è già la prova della presenza. Si potrà aggiungere solo se
emergesse un abuso reale, con il consenso del cliente.

---

## 8. Il premio

| | Regola |
|---|---|
| **T44** | **Tipi ammessi.** **Omaggio**: un prodotto o servizio del locale (es. «dolce offerto», «antipasto per il tavolo», «caffè e digestivo»). **Sconto percentuale** sul conto di quella visita, dal 5% al 50% |
| **T45** | **Vietati:** denaro, credito, buoni, gift card, prodotti di terzi, importi in euro. Il server rifiuta descrizioni con «€», «euro» o importi |
| **T46** | **Bevande alcoliche:** consentite solo come parte di un omaggio, con la dicitura «solo maggiorenni» (⚖️ da confermare; vedi §14) |
| **T47** | **Consegna.** Alla scansione lo staff vede il premio disponibile e tocca **Consegna ora** quando il cliente lo vuole usare. Il cliente può dire «la prossima volta» |
| **T48** | **Contestazione:** «Non l'ho ricevuto» entro 48 ore (**T42**). Si gestisce dal pannello (§9) |

---

## 9. Segnalazioni e sanzioni

**Come si segnala:**
- **il cliente**, da Le mie tessere → **Segnala un problema**:
  - «non hanno voluto timbrare»;
  - «premio non consegnato»;
  - «premio diverso da quello promesso»;
  - altro, con una nota breve;
- **il locale**, dal riquadro dell'esito o dalle statistiche → **Segnala**: «uso sospetto del QR»,
  «cliente scorretto».

La segnalazione arriva all'admin con i dati della tessera: codice anonimo, date, versione del patto.
L'admin vede anche gli account, quindi può verificare.

| | Regola |
|---|---|
| **T49** | **Sanzioni per il locale** (decide l'admin, dopo una telefonata al locale): **1)** richiamo scritto (registro); **2)** **tessera sospesa**: niente tessere nuove, le esistenti restano valide; **3)** **locale sospeso da HAPOSTO**: sparisce da mappa, elenco e sito, la tessera viene terminata, per 12 mesi non può riattivarla. Le segnalazioni di più clienti diversi pesano di più |
| **T50** | **Sanzioni per il cliente:** **1)** richiamo; **2)** **azzeramento** della tessera in quel locale; **3)** **account sospeso**: niente timbri, niente premi, niente funzioni con account. Segnalare il falso per avere premi vale come violazione |
| **T51** | Ogni sanzione resta nel **registro** del pannello con motivo e autore. Locale e cliente possono chiedere un riesame scrivendo all'assistenza |

---

## 10. Privacy

| | Regola |
|---|---|
| **T52** | **Il locale vede solo un codice anonimo** (es. `K4F7`): casuale, diverso per ogni locale, stabile nel tempo, così il locale distingue i clienti abituali senza sapere chi sono. Mai nome, email, foto, telefono, altre tessere |
| **T53** | **Il QR non contiene dati**: solo un codice casuale. Il server conserva solo l'impronta del codice |
| **T54** | **Niente GPS, niente impronta del dispositivo.** La posizione del cliente non viene mai chiesta per la tessera |
| **T55** | **Conservazione:** codici QR 1 giorno; timbri e visite 24 mesi; tessere e premi chiusi 12 mesi dopo la chiusura, poi resta solo il conteggio anonimo; segnalazioni 24 mesi |
| **T56** | **Al primo uso** il cliente legge una schermata breve: cosa vede il locale, cosa conserva HAPOSTO, per quanto. Poi accetta (versione dei termini). Base giuridica: contratto, cioè il servizio chiesto dal cliente |
| **T57** | Da aggiornare: informativa privacy, termini per utenti e per ristoranti, scheda «Sicurezza dei dati» di Google Play |

---

## 11. Statistiche

**Per il ristoratore** (Gestisci il locale → Statistiche → Tessera; consultabili anche dallo staff;
mai dati personali):
- ultimi 7 / 30 / 90 giorni:
  - visite timbrate, coperti, clienti nuovi e di ritorno;
  - tessere iniziate, timbri dati (normali e doppi);
  - premi sbloccati, consegnati, scaduti;
- **clienti vicini al premio** (quanti a N−1, N−2), senza sapere chi sono;
- **per giorno della settimana e fascia oraria**: quando vengono i clienti con la tessera;
- elenco delle tessere con **codice anonimo**: timbri, inizio, ultima visita, scadenza.

Con la tessera spenta non si vede nulla.

**Per l'admin** (pannello → nuova scheda **Tessere**):
- totali: programmi attivi, tessere attive, timbri e premi del giorno, della settimana e del mese;
- per locale: versione attiva e storico delle versioni con i patti accettati;
- segnalazioni aperte e da gestire;
- **segnali automatici** (**T40**, **T41**);
- impostazioni e tester.

Tutto si legge anche con le query di controllo della guida tecnica privata.

---

## 12. Account, Gratis e Plus

| | Regola |
|---|---|
| **T58** | **La tessera è gratis** per chi accede con Google: nessun abbonamento richiesto, nemmeno per gli avvisi sulle proprie tessere |
| **T59** | **L'accesso si chiede solo quando serve** (alla prima «Mostra il mio QR»). Chi non vuole accedere usa HAPOSTO come oggi |

**Plus (0,99 €/mese).** Oggi comprende avvisi «si è liberato», preferiti sincronizzati, raggio di
100 km e «di solito». Idee per renderlo più interessante, senza togliere nulla al Gratis:

| Idea | La mia scelta |
|---|---|
| **Filtri avanzati** (cucina, aperto ora, con offerta, con tessera) — già previsti nel piano, non realizzati | ✅ sì |
| **Avviso a orario** («avvisami se stasera dalle 20 c'è posto da X») | ✅ sì |
| **Widget sulla schermata Home** del telefono («c'è posto vicino a te») | ✅ sì |
| **Liste personali** («pizzerie del sabato») | 🟡 forse |
| **Storico personale** (dove sono stato, quante volte) | 🟡 forse |
| Avvisi «un locale della tua zona ha posto» | ❌ invadente |
| Timbri doppi per gli abbonati Plus | ❌ no: la tessera resta uguale per tutti e non dipende da un pagamento |

I vantaggi di Plus si decidono alla Tappa 2 della roadmap (decisioni di base); questa tabella è una
proposta.

---

## 13. Pannello admin

- **Impostazioni** → `loyalty`:
  - modalità (**T7**–**T10**);
  - limiti di **T11**, **T13**–**T16**;
  - finestra di 4 ore (**T38**);
  - limiti di scansione (**T40**);
  - errori del codice di riserva (**T37**);
  - massimo di giorni di ferie (**T22**).
- **Locali** → il locale: «Tester tessera»; versione attiva e storico; statistiche; **Sospendi la
  tessera**, **Termina (cessazione)**.
- **Utenti** → l'utente: «Tester tessera»; le sue tessere (nell'admin si vedono, servono per le
  contestazioni); **Azzera la tessera di un locale**.
- **Tessere** (scheda nuova): §11, segnalazioni con **Prendi in carico → Decidi** (richiamo,
  sospensione, archivia).
- **Registro:** ogni azione della tessera e ogni sanzione.

---

## 14. Aspetti legali da sottoporre all'avvocato ⚖️

Da portare insieme ai documenti legali (roadmap, Tappa 5), **prima** di accendere la tessera per il
pubblico. La modalità «test» fra tester si può usare anche prima.

1. **Manifestazioni a premio (DPR 430/2001):**
   - la tessera con premi decisi e pagati dal singolo locale, come omaggio di suoi prodotti o sconto
     percentuale sul suo conto, rientra nelle esclusioni (art. 6)?
   - serve un regolamento o una comunicazione al Ministero?
   - chi è il promotore: il locale o HAPOSTO?
2. **Ruolo di HAPOSTO:** fornitore dello strumento, non promotore né garante dei premi. Come
   scriverlo nei termini.
3. **Il patto e le sanzioni nei termini per i ristoranti:**
   - immodificabilità per le tessere iniziate, chiusura con preavviso, sospensione;
   - quali clausole richiedono l'approvazione specifica (artt. 1341–1342 c.c.);
   - cosa succede in caso di cessazione o fallimento.
4. **Codice del Consumo:** chiarezza delle condizioni per il cliente; decadenza dei timbri alla
   scadenza; nessuna clausola vessatoria.
5. **Privacy:**
   - il codice anonimo dato al locale è un dato pseudonimo: il locale diventa titolare o
     responsabile di un trattamento?
   - serve una valutazione d'impatto (DPIA)?
   - tempi di conservazione del §10.
6. **Alcolici come premio:** ammessi solo con «solo maggiorenni» o meglio vietarli?
7. **Sconto percentuale:** limite massimo e indicazione del prezzo; aspetti fiscali per il locale
   (con il commercialista).
8. **Spesa minima come condizione del timbro:** va bene indicarla in euro?

---

## 15. Struttura tecnica

### 15.1 Database (migration `0018`, rieseguibile, con controlli in CI)

| Tabella | Contenuto |
|---|---|
| `loyalty_programs` | uno per locale: stato (`NONE`, `ACTIVE`, `CLOSING`, `SUSPENDED`, `TERMINATED`), versione attiva, tester sì/no, sospeso fino a, motivo |
| `loyalty_program_versions` | versioni **immutabili** (un trigger blocca le modifiche): numero, timbri, tipo e testo del premio, percentuale, validità del premio, durata della tessera, giorni doppi, condizione, accettata da / quando, versione dei termini |
| `loyalty_members` | locale + cliente → **codice anonimo** casuale (**T52**) |
| `loyalty_cards` | tessera: versione, timbri, inizio, scadenza, stato |
| `loyalty_stamps` | ogni timbro: tessera, chi ha scansionato, quando, timbri (1 o 2), persone, annullato da / quando |
| `loyalty_rewards` | premio: testo copiato dalla versione, sbloccato, scade, consegnato da / quando, contestato |
| `visit_tokens` | impronta del QR e del codice di riserva, cliente, scade (60 s), usato da / quando, esito |
| `loyalty_reports` | segnalazioni: chi, tipo, tessera, nota, stato, decisione |
| `loyalty_holidays` | ferie dichiarate (date) |

Più:
- `app_config` → `loyalty`: modalità e limiti (`admin_set_config` la valida);
- `profiles.loyalty_tester`;
- funzione del piano `LOYALTY` aggiunta a Pro.

**Funzioni principali** (tutte sul server, con verifica della modalità **T9**):
- **cliente:** `loyalty_access`, `create_visit_token`, `visit_token_status`, `my_loyalty_cards`,
  `leave_loyalty_card`, `report_loyalty_problem`;
- **locale:**
  - `register_stamp` (scansione o codice), `undo_stamp`, `redeem_reward`;
  - `publish_loyalty_version` (patto), `close_loyalty_program`, `declare_loyalty_holidays`;
  - `restaurant_loyalty_stats`, `restaurant_loyalty_cards`;
- **admin:** impostazioni, tester, sospensione e terminazione, azzeramento, segnalazioni,
  statistiche.

**Lavori pianificati:**
- scadenze di tessere e premi;
- avvisi (**T29**, **T31**);
- chiusura automatica a fine preavviso;
- pulizia dei codici QR e conservazione (**T55**).

Nella stessa migration si sistema anche `admin_restaurant_detail`, che dalla 0017 non funziona dal
SQL Editor (problema già annotato).

### 15.2 App

- **Cliente:**
  - riquadro nella scheda del locale;
  - schermata del QR (ZXing, già nel progetto) con `FLAG_SECURE`, cornice animata, rinnovo ogni
    60 s ed esito letto ogni secondo;
  - Le mie tessere, Segnala, schermata della privacy al primo uso;
  - tutto nascosto senza accesso alla funzione.
- **Ristoratore:**
  - Gestisci il locale → Tessera fedeltà: procedura in 3 passi (scelte → regole → patto);
  - versioni, chiusura, ferie;
  - tasto **Timbra** con lo scanner di Google (`play-services-code-scanner`, gratuito, senza
    permesso della fotocamera) e il riquadro dell'esito;
  - inserimento del codice; statistiche.
- **Pannello admin:** §13.

### 15.3 Verifiche

- **SQL** (`step22_loyalty_checks.sql` in CI): ogni regola **T** controllabile dal database ha il
  suo controllo, in particolare:
  - modalità e tester;
  - immutabilità delle versioni;
  - limiti;
  - token monouso e scaduti;
  - finestra delle 4 ore;
  - autotimbro;
  - annullamento oltre i 2 minuti;
  - premio vietato in euro;
  - chiusura con preavviso;
  - ferie;
  - sanzioni;
  - privacy (il locale non legge mai email e nomi).
- **Kotlin:** test della logica (stati, testi, conti alla rovescia) e della visibilità a funzione
  spenta.
- **Costi:** nessuno (Supabase Free, scanner gratuito).

---

## 16. Piano di lavoro

| PR | Contenuto | Visibile? |
|---|---|---|
| **A** | Database 0018, controlli SQL, impostazione `loyalty` (spenta) e tester nel pannello admin | No |
| **B** | App del ristoratore: procedura del patto, Timbra, esito, statistiche | Solo ai tester in modalità test |
| **C** | App del cliente: QR, Le mie tessere, segnalazioni, avvisi | Solo ai tester |
| **D** | Pannello admin: scheda Tessere, segnalazioni, sanzioni; guida di prova sul DEV | Admin |
| **E** | Bozze dei testi legali da far rivedere (privacy, termini, patto) | — |

Dopo ogni PR, come sempre:
- 🧑 migration sul DEV;
- prova con i due account: tu come cliente, il «ristoratore di prova» come locale, modalità
  **test**;
- registro e stato aggiornati.

La modalità **attiva** si accende solo dopo l'avvocato (§14) e la decisione di lancio (Tappa 8).

---

## 17. Altre idee (facoltative, dopo la V1)

- **«C'era posto quando sei arrivato?»** dopo il timbro: misura l'affidabilità degli stati.
- **Serata a timbro doppio** collegata all'offerta della serata. Annunciata almeno 24 ore prima e
  non revocabile una volta annunciata; vale per tutte le tessere attive (solo a favore del cliente).
- **Riga sulla tessera** nella pagina pubblica `/r/…` e sull'adesivo in vetrina, a funzione accesa.
- **Avviso al locale** «hai 3 clienti a un timbro dal premio», senza dire chi sono.
- **Valore stimato** con lo scontrino medio dichiarato dal locale.

---

## 18. Valori iniziali da confermare (🧑)

| Valore | Proposta |
|---|---|
| Timbri per il premio (limiti) | 5–20, proposta 10 |
| Validità del premio (limiti) | 30–180 giorni, proposta 60 |
| Durata della tessera | 6 o 12 mesi, proposta 12 |
| Finestra fra due timbri nello stesso locale | 4 ore |
| Giorni doppi | max 2 a settimana |
| QR | 60 secondi, rinnovo automatico |
| Annullamento | entro 2 minuti |
| Contestazione del premio | entro 48 ore |
| Ferie che allungano le scadenze | max 60 giorni l'anno |
| Sospensione del locale per violazione | 12 mesi senza tessera |
| Nome nell'app | «Tessera» |
