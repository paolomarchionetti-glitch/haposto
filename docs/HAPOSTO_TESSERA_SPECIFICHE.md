# HAPOSTO — Tessera fedeltà: specifiche (funzione nascosta)

**Versione 2 · 11 ottobre 2026 · funzione spenta di default · nessun codice ancora scritto.**

Decisione del titolare: la tessera si **realizza subito**, ma resta **spenta e invisibile**, con
un interruttore nel pannello admin. Si può provare sul DEV in modalità test e si accende per tutti
solo se e quando si deciderà di lanciarla. Le motivazioni sono in
`HAPOSTO_PROGETTO_VISITE_E_TESSERA.md`; **dove i documenti differiscono, vale questo**.

Ogni regola ha un codice (**T1**, **T2**…) da citare nelle PR, nei test e nelle discussioni.

Legenda: 🧑 tocca al titolare · 🤖 lo fa Claude.

---

## Cosa cambia rispetto alla versione 1

La prima versione era troppo vincolante per i ristoranti e chiedeva troppo lavoro all'admin. Il
titolare ha chiesto una tessera più semplice, che funzioni da sola, «senza avvocati e leggi troppo
vincolanti».

| Versione 1 | Versione 2 |
|---|---|
| Chiudendo la tessera, quelle iniziate andavano avanti fino a 12 mesi | **Preavviso di 30 giorni**, poi la tessera finisce |
| Tessera valida 12 mesi dal primo timbro, allungata dalle ferie | I timbri **si azzerano dopo 6 mesi senza visite**; niente gestione delle ferie |
| Premio con testo libero, sconto percentuale, alcolici con avvertenza | **Solo da una lista chiusa** di prodotti del locale: niente soldi, sconti o alcolici |
| Condizione del timbro con spesa minima in euro | Solo «pasto al tavolo» o «consumazione al tavolo» |
| Contestazione del premio entro 48 ore, gestita dall'admin | **Nessuna contestazione.** Il cliente può solo segnalare, e le segnalazioni contano in automatico |
| Sanzioni decise dall'admin, fino a togliere il locale da HAPOSTO | **Sanzioni automatiche e progressive, solo sulla tessera.** Il locale resta su HAPOSTO e il suo abbonamento non cambia |
| Elenco di anomalie da controllare nel pannello | Tolto: bastano i limiti automatici |
| Otto domande per l'avvocato | Con la lista chiusa è la classica tessera timbri del bar: si citano solo nei testi legali già previsti |

---

## 0. In breve

- **Cos'è.** Una tessera timbri digitale per locale: «N timbri → un premio». Il premio si sceglie da
  una lista di prodotti del locale. Il timbro si ottiene **solo** quando il locale scansiona il QR
  del cliente.
- **Per chi.** Gratis per i clienti con account Google. Per i ristoratori è una funzione di Pro
  (durante la beta e la prova ce l'hanno tutti).
- **Il patto, semplice.**
  - Chi ha iniziato una tessera la completa alle condizioni di quel giorno.
  - Se il locale cambia le regole, valgono solo per le tessere nuove.
  - Se smette, i clienti hanno 30 giorni per completare.
- **Antifrode.** Nessun timbro gratis: QR che cambia ogni 60 secondi e vale una volta sola,
  screenshot bloccati, nessun timbro a mano, limiti automatici.
- **Privacy.** Il ristoratore non vede mai nome, email o foto del cliente: solo un codice anonimo.
  Niente GPS.
- **Gestione automatica.** Nessuna contestazione da seguire. Se più clienti diversi segnalano
  problemi, la tessera del locale si sospende da sola. L'admin non deve fare niente.
- **Nascosta.** Con l'interruttore spento non c'è nessun menù né tasto, e il server rifiuta ogni
  operazione. Il codice è nel repository pubblico: «nascosta» vuol dire invisibile e inutilizzabile
  nell'app, non segreta.

---

## 1. Il patto in sei regole

| | Regola |
|---|---|
| **T1** | Il **timbro** si ottiene solo con una visita reale, quando il locale scansiona il QR del cliente. Non esistono timbri a mano, regalati o recuperati |
| **T2** | Le **condizioni** (timbri richiesti, premio, giorni doppi) sono fissate quando la tessera del cliente inizia e **non cambiano** per quella tessera |
| **T3** | Il ristoratore può cambiare le condizioni solo **per le tessere nuove**, che partono da zero |
| **T4** | Il **premio maturato** va consegnato entro la sua validità, alla visita che sceglie il cliente |
| **T5** | Il premio si sceglie **solo dalla lista** del §8: prodotti del locale, **mai soldi, sconti o alcolici** |
| **T6** | Un locale che non rispetta la tessera **perde la tessera**, in automatico e a gradi (§9). Il locale resta su HAPOSTO e il suo abbonamento non cambia |

---

## 2. L'interruttore nel pannello admin

| | Regola |
|---|---|
| **T7** | Pannello admin → **Impostazioni** → `loyalty` → **modalità**. Valore iniziale: **spenta** |
| **T8** | Le modalità sono quattro (tabella sotto) |
| **T9** | **Il server decide**: ogni funzione della tessera controlla la modalità e rifiuta con `FEATURE_DISABLED` se non è permessa. L'app nasconde i menù, ma la protezione vera è sul server |
| **T10** | **Dopo il lancio non si spegne di colpo.** Da «attiva» si passa a «solo esistenti», così chi ha timbri può completare |

| Modalità | Chi la vede | Cosa si può fare |
|---|---|---|
| **Spenta** (iniziale) | Nessuno (l'admin vede solo l'interruttore) | Niente |
| **Test** | Solo i **locali tester** e i **clienti tester** scelti dall'admin (gli admin sono sempre clienti tester) | Tutto, solo fra tester |
| **Attiva** | Tutti i clienti con account; i locali con Pro | Tutto |
| **Solo esistenti** | Chi ha già una tessera iniziata | Si completano le tessere e si consegnano i premi; niente tessere nuove |

- **Tester:**
  - **Locali** → il locale → «**Tester tessera**»;
  - **Utenti** → l'utente → «**Tester tessera**».

  Sul DEV: il tuo account come cliente, il «ristoratore di prova» con il suo locale come tester.
- **Con la tessera non disponibile non si vede niente:** riquadro nella scheda del locale, «Le mie
  tessere», tasto «Timbra», voce «Tessera fedeltà» in Gestisci il locale, statistiche.

---

## 3. Il programma del locale

### 3.1 Cosa sceglie il ristoratore (entro limiti fissati dall'admin)

| | Impostazione | Scelta |
|---|---|---|
| **T11** | Timbri per il premio | da **5** a **20** |
| **T12** | Premio | **uno** dalla lista del §8 |
| **T13** | Condizione per il timbro | «un pasto al tavolo» oppure «una consumazione al tavolo» |
| **T14** | Giorni con timbro doppio (facoltativo) | da 0 a **2** giorni della settimana |

Sono valori fissati dall'admin, uguali per tutti:
- la **validità del premio** (es. 60 giorni);
- l'**azzeramento per inattività** (es. 6 mesi senza visite);
- il **preavviso di chiusura** (30 giorni).

Così ogni tessera funziona allo stesso modo e il cliente non deve leggere regole diverse in ogni
locale.

### 3.2 Il patto: attivazione e versioni

| | Regola |
|---|---|
| **T15** | **Riepilogo** prima di attivare, in tre righe: «Timbro ogni cliente che rispetta la condizione e mostra il QR. Consegno i premi maturati entro la loro validità. Se smetto, i clienti hanno 30 giorni per completare». Si attiva con **Accetto**, da titolare con verifica in due passaggi |
| **T16** | L'accettazione si registra in `consent_log` (tipo `LOYALTY_PACT`) con data, versione del programma e account |
| **T17** | Ogni attivazione crea una **versione** numerata, che **non si può modificare** (il database lo impedisce) |
| **T18** | **Modificare = pubblicare una nuova versione.** Le tessere nuove usano quella; le tessere già iniziate restano sulla loro (**T2**, **T3**) |

---

## 4. Cosa può fare il ristoratore

| Situazione | Cosa succede | Regola |
|---|---|---|
| **Cambiare** timbri, premio o giorni doppi | Pubblica una nuova versione. Vale **solo per chi inizia da oggi**, con timbri a zero. Chi ha già timbri completa con le condizioni di prima | **T18** |
| **Smettere** | **Chiude con 30 giorni di preavviso**. Da subito nessuna tessera nuova. Per 30 giorni chi ha una tessera può continuare a timbrare; i premi già sbloccati restano validi fino alla loro scadenza. Poi è finita. Chi è a 1 su 10 perde i timbri; chi è a 9 su 10 ha 30 giorni per l'ultima visita | **T19** |
| **Non paga più Pro** (diventa «Non collegato») | Succede da solo quello che succede quando smette: parte il preavviso di 30 giorni | **T20** |
| **Esce da HAPOSTO** (cessazione, account cancellato, locale sospeso per altri motivi) | La tessera finisce subito: non c'è più nessuno che possa timbrare. I clienti ricevono un avviso | **T21** |

Il massimo a cui un locale si impegna smettendo, quindi, è il preavviso di 30 giorni più la
validità dei premi già sbloccati.

---

## 5. La tessera del cliente

| | Regola |
|---|---|
| **T22** | La tessera **nasce al primo timbro**, legata alla versione attiva quel giorno. Al massimo **una tessera attiva per locale** per cliente |
| **T23** | **Azzeramento per inattività:** se il cliente non torna per **6 mesi** (valore dell'admin), i timbri si azzerano. È l'unica «scadenza», facile da spiegare: «I timbri valgono finché torni almeno una volta ogni 6 mesi». Avviso gratuito 15 giorni prima, solo se mancano 1–3 timbri |
| **T24** | Arrivato a N timbri si **sblocca il premio**, valido **60 giorni** (valore dell'admin). La tessera è completata e alla visita dopo ne parte una nuova. Un timbro in più (giorno doppio) passa alla tessera nuova, se il locale ne accetta ancora |
| **T25** | Il cliente può **lasciare** una tessera (i timbri si cancellano). Con la cancellazione dell'account sparisce tutto |
| **T26** | Il cliente vede sempre le **regole della sua tessera** (timbri, premio, giorni doppi, condizione): sono quelle della sua versione |

---

## 6. Timbrare: il flusso veloce

**Il cliente**, alla cassa quando paga:
1. scheda del locale (o «Le mie tessere») → **Mostra il mio QR**. Senza account: «Accedi con Google
   per raccogliere i timbri», una volta sola;
2. il QR compare **subito** (meno di mezzo secondo), con:
   - luminosità al massimo e cornice animata;
   - un codice di riserva di 6 caratteri;
   - un conto alla rovescia di 60 secondi, con rinnovo automatico;
3. appena il locale scansiona, la schermata mostra entro 1 secondo **«✓ +1 timbro · 4 su 10»**
   (o «+2, giorno doppio», o «🎁 Premio sbloccato»).

**Il locale** (titolare o collaboratore con verifica in due passaggi):
1. dashboard → **📷 Timbra**: si apre all'istante lo scanner di Google, che non chiede il permesso
   della fotocamera all'app;
2. dopo la scansione, in meno di 1 secondo compare l'esito:

   ```
   ✓ Cliente K4F7 · +1 timbro · 4 su 10
   Persone al tavolo: [−] 2 [+]
   🎁 Premio da consegnare: dolce offerto   [ Consegna ora ]
   [ Annulla (entro 2 minuti) ]     [ Timbra il prossimo ]
   ```

3. **Inserisci codice** se il QR non si legge.

| | Regola |
|---|---|
| **T27** | Ogni scansione aggiorna **subito** il database: tessera, timbri, premio, statistiche |
| **T28** | **Annulla** serve solo per un errore dello staff: cliente sbagliato, stessa persona scansionata due volte. Toglie quel timbro ed è possibile **solo nei 2 minuti** dopo la scansione. Dopo, il timbro resta. Ogni annullamento è registrato |
| **T29** | La dashboard resta com'è: il tasto **Timbra** è secondario e compare solo se il locale ha la tessera attiva o in preavviso |

---

## 7. QR e antifrode: nessun timbro gratis

Tutte le difese sono **automatiche**: nessuno deve controllare niente.

| Tentativo | Difesa | Regola |
|---|---|---|
| Foto o screenshot del QR da riusare | Il QR vale **60 secondi** e **una volta sola**; la schermata **blocca gli screenshot**; la cornice animata fa riconoscere allo staff una foto statica | **T30** |
| QR mandato a un amico che è al ristorante | Come sopra; in più il timbro va sempre al titolare dell'account del QR, che ne prende al massimo uno ogni 4 ore per locale | **T30**, **T32** |
| Inventare un QR o un codice | Codice casuale creato solo dal server: 128 bit nel QR, ~900 milioni di combinazioni per il codice di riserva. Dopo 10 codici sbagliati in 10 minuti, l'inserimento si blocca per 10 minuti | **T31** |
| Più timbri nella stessa visita | **1 timbro ogni 4 ore** per locale (2 nei giorni doppi) | **T32** |
| Il titolare o lo staff timbrano la propria tessera | Chi gestisce un locale usa HAPOSTO anche come cliente, con lo stesso account. Potrebbe timbrarsi da solo e prendersi i premi. **Il sistema glielo impedisce**: chi gestisce un locale non può avere la tessera di quel locale | **T33** |
| Timbri a mano | **Non esistono** (**T1**). Se il cliente dimentica il QR, il timbro di quella visita si perde, come con la tessera di carta lasciata a casa | **T1** |
| Il locale timbra in massa clienti inesistenti | **Tetto automatico**: max 60 scansioni ogni 10 minuti e 300 al giorno per locale. Oltre, lo scanner risponde «limite raggiunto». Nessun controllo manuale | **T34** |

Il GPS non serve: il locale che scansiona è già la prova della presenza.

---

## 8. Il premio: solo da una lista

| | Regola |
|---|---|
| **T35** | Il ristoratore sceglie **un** premio da questa lista, senza testo libero |
| **T36** | **Niente soldi, sconti, buoni, credito o alcolici.** La lista non li contiene e il server accetta solo le voci della lista |
| **T37** | **Consegna:** alla scansione lo staff vede il premio disponibile e tocca **Consegna ora** quando il cliente lo vuole usare. Il cliente può dire «la prossima volta». Nessuna conferma e nessuna contestazione: com'è con la tessera di carta |

**Lista dei premi** (modificabile solo con una nuova versione dell'app):

| Premio | Testo che vede il cliente |
|---|---|
| Caffè | «Caffè offerto» |
| Dolce | «Dolce offerto» |
| Antipasto | «Antipasto offerto» |
| Contorno | «Contorno offerto» |
| Primo piatto | «Primo piatto offerto» |
| Pizza | «Pizza offerta» |
| Bibita analcolica | «Bibita analcolica offerta» |
| Coperto | «Coperto offerto» |

Sono tutti prodotti o servizi del locale stesso, consegnati in quel locale. È la forma della
classica tessera timbri del bar («ogni 10 caffè, uno offerto»), che non richiede regolamenti o
pratiche particolari (§14).

---

## 9. Segnalazioni e sanzioni automatiche

Non ci sono contestazioni né decisioni da prendere. C'è solo un modo semplice per dire «questo locale
non ha rispettato la tessera»; se lo dicono **più clienti diversi**, la tessera del locale si ferma
da sola.

| | Regola |
|---|---|
| **T38** | **Chi può segnalare:** solo un cliente che ha avuto **almeno un timbro in quel locale negli ultimi 60 giorni**. Le scelte sono due tasti, senza testo: «Non hanno voluto timbrare» e «Non mi hanno dato il premio». **Una segnalazione per cliente per locale ogni 90 giorni.** Il cliente non ottiene niente segnalando, quindi non ha motivo di accanirsi |
| **T39** | **Livello 1, avviso:** **3** segnalazioni di clienti diversi in 60 giorni → avviso automatico al titolare, nella dashboard e con una notifica: «Alcuni clienti segnalano problemi con la tessera». Nessuna conseguenza |
| **T40** | **Livello 2, tessera sospesa:** **5** segnalazioni di clienti diversi in 60 giorni → la tessera del locale si **sospende da sola per 90 giorni**. Le tessere dei clienti finiscono, con un avviso. Dopo 90 giorni il locale può riattivarla accettando di nuovo il patto |
| **T41** | **Livello 3, tessera tolta:** una seconda sospensione entro 12 mesi → la tessera viene **tolta**. Solo l'admin può ridargliela, se vuole |
| **T42** | **Il locale non viene mai tolto da HAPOSTO** per la tessera: resta in mappa ed elenco, con il suo stato e il suo abbonamento. Perde solo la tessera |
| **T43** | Il locale vede nelle statistiche quante segnalazioni ha (es. «2 negli ultimi 60 giorni; la tessera si sospende a 5»), senza sapere chi le ha fatte |
| **T44** | **Clienti:** nessuna sanzione automatica. I limiti tecnici del §7 rendono inutile imbrogliare. Per i casi gravi l'admin può sempre bloccare un account dal pannello, come oggi |

Le soglie (3, 5, 60 e 90 giorni, 12 mesi) sono impostazioni dell'admin. L'admin può anche togliere
una sospensione a mano, se la ritiene ingiusta, ma **non deve** fare niente perché il sistema
funzioni.

---

## 10. Privacy

| | Regola |
|---|---|
| **T45** | **Il locale vede solo un codice anonimo** (es. `K4F7`): casuale, diverso per ogni locale, stabile nel tempo. Così il locale distingue i clienti abituali senza sapere chi sono. Mai nome, email, foto, telefono, altre tessere |
| **T46** | **Il QR non contiene dati**: solo un codice casuale. Il server conserva solo l'impronta |
| **T47** | **Niente GPS, niente impronta del dispositivo** |
| **T48** | **Conservazione:** codici QR 1 giorno; timbri e visite 24 mesi; tessere e premi chiusi 12 mesi, poi resta solo il conteggio anonimo; segnalazioni 12 mesi |
| **T49** | **Al primo uso** il cliente vede una schermata breve: cosa vede il locale, cosa conserva HAPOSTO, per quanto. Poi accetta |

---

## 11. Statistiche

**Per il ristoratore** (Gestisci il locale → Statistiche → Tessera; le vedono anche i collaboratori;
mai dati personali):
- ultimi 7 / 30 / 90 giorni:
  - visite timbrate, coperti, clienti nuovi e di ritorno;
  - tessere iniziate, timbri (normali e doppi);
  - premi sbloccati, consegnati, scaduti;
- **clienti vicini al premio** (quanti a N−1, N−2), senza sapere chi sono;
- **giorni e orari** in cui arrivano i clienti con la tessera;
- elenco delle tessere con **codice anonimo**: timbri, inizio, ultima visita;
- segnalazioni ricevute e soglie (**T43**).

**Per l'admin** (pannello → nuova scheda **Tessere**, solo da consultare):
- totali: locali con tessera, tessere attive, timbri e premi di oggi, della settimana e del mese;
- per locale: versioni e patti accettati, segnalazioni, sospensioni automatiche;
- impostazioni e tester.

---

## 12. Account, Gratis e Plus

| | Regola |
|---|---|
| **T50** | **La tessera è gratis** per chi accede con Google, avvisi sulle proprie tessere compresi |
| **T51** | **L'accesso si chiede solo quando serve** (alla prima «Mostra il mio QR»). Chi non vuole accedere usa HAPOSTO come oggi |

**Plus (0,99 €/mese)** oggi comprende avvisi «si è liberato», preferiti sincronizzati, raggio di
100 km e «di solito». Proposte per arricchirlo senza togliere nulla al Gratis (si decide alla
Tappa 2):

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
  - modalità (**T7**–**T10**);
  - limiti di **T11** e **T14**;
  - validità del premio, azzeramento per inattività, preavviso;
  - finestra delle 4 ore e tetti di scansione;
  - soglie delle segnalazioni (**T39**–**T41**).
- **Locali** → il locale: «Tester tessera»; versioni; statistiche; eventuale sospensione da
  togliere o tessera da ridare (facoltativo).
- **Utenti** → l'utente: «Tester tessera».
- **Tessere** (scheda nuova): i numeri del §11, solo da leggere.
- **Registro:** attivazioni, versioni, chiusure, sospensioni automatiche, annullamenti.

---

## 14. Aspetti legali

Con la **lista chiusa di premi** (prodotti del locale, niente soldi, sconti o alcolici) la tessera è
la stessa cosa della tessera timbri di carta che molti bar e ristoranti usano già. Non serve un
lavoro legale dedicato: basta aggiungere poche righe ai testi già previsti.
- **Privacy:** cosa vede il locale (codice anonimo), cosa conserva HAPOSTO e per quanto (§10).
- **Termini per gli utenti:** come funzionano timbri, azzeramento, premio, chiusura con preavviso.
- **Termini per i ristoratori:** il patto in tre righe (**T15**); il premio è un'iniziativa del
  locale; sospensione automatica della tessera (§9).

Queste righe si fanno rileggere **insieme agli altri documenti legali** alla Tappa 5 della roadmap,
senza costi in più. La modalità **test** fra tester si può usare anche prima.

---

## 15. Struttura tecnica

### 15.1 Database (migration `0018`, rieseguibile, con controlli in CI)

| Tabella | Contenuto |
|---|---|
| `loyalty_programs` | uno per locale: stato (`NONE`, `ACTIVE`, `CLOSING`, `SUSPENDED`, `REMOVED`, `ENDED`), versione attiva, tester sì/no, fine del preavviso, sospeso fino a |
| `loyalty_program_versions` | versioni **immutabili** (un trigger blocca le modifiche): numero, timbri, premio (codice della lista), condizione, giorni doppi, accettata da / quando |
| `loyalty_members` | locale + cliente → **codice anonimo** casuale (**T45**) |
| `loyalty_cards` | tessera: versione, timbri, inizio, ultima visita, stato |
| `loyalty_stamps` | ogni timbro: tessera, chi ha scansionato, quando, timbri (1 o 2), persone, annullato sì/no |
| `loyalty_rewards` | premio: codice della lista, sbloccato, scade, consegnato da / quando |
| `visit_tokens` | impronta del QR e del codice di riserva, cliente, scadenza (60 s), usato da / quando, esito |
| `loyalty_reports` | segnalazioni: cliente, locale, tipo, data |

Più:
- `app_config` → `loyalty`: modalità, limiti e soglie (`admin_set_config` la valida);
- `profiles.loyalty_tester`;
- funzione del piano `LOYALTY` aggiunta a Pro.

**Funzioni principali** (tutte sul server, con verifica della modalità **T9**):
- **cliente:** `loyalty_access`, `create_visit_token`, `visit_token_status`, `my_loyalty_cards`,
  `leave_loyalty_card`, `report_loyalty_problem`;
- **locale:** `register_stamp` (scansione o codice), `undo_stamp`, `redeem_reward`,
  `publish_loyalty_version` (patto), `close_loyalty_program`, `restaurant_loyalty_stats`,
  `restaurant_loyalty_cards`;
- **admin:** impostazioni, tester, togliere una sospensione o ridare la tessera, statistiche.

**Lavori pianificati:**
- azzeramento per inattività e avvisi (**T23**);
- scadenza dei premi;
- fine del preavviso (**T19**, **T20**);
- soglie delle segnalazioni (**T39**–**T41**);
- pulizia (**T48**).

Nella stessa migration si sistema anche `admin_restaurant_detail`, che dalla 0017 non funziona dal
SQL Editor (problema già annotato).

### 15.2 App

- **Cliente:**
  - riquadro nella scheda del locale;
  - schermata del QR (ZXing, già nel progetto) con screenshot bloccati (`FLAG_SECURE`), cornice
    animata, rinnovo ogni 60 secondi ed esito letto ogni secondo;
  - Le mie tessere, i due tasti di segnalazione, schermata della privacy al primo uso;
  - tutto nascosto senza accesso alla funzione.
- **Ristoratore:**
  - Gestisci il locale → Tessera fedeltà: scelte (timbri, premio dalla lista, condizione, giorni
    doppi) e patto;
  - nuova versione, chiusura con preavviso;
  - tasto **Timbra** con lo scanner di Google (`play-services-code-scanner`, gratuito, senza
    permesso della fotocamera), riquadro dell'esito, inserimento del codice;
  - statistiche.
- **Pannello admin:** §13.

### 15.3 Verifiche

- **SQL** (`step22_loyalty_checks.sql` in CI): un controllo per ogni regola verificabile dal
  database, in particolare:
  - modalità e tester;
  - immutabilità delle versioni;
  - lista dei premi;
  - token monouso e scaduti, finestra delle 4 ore, autotimbro, annullamento oltre i 2 minuti;
  - tetti di scansione;
  - preavviso e azzeramento;
  - soglie delle segnalazioni;
  - privacy: il locale non legge mai email e nomi.
- **Kotlin:** test della logica e della visibilità a funzione spenta.
- **Costi:** nessuno (Supabase Free, scanner gratuito).

---

## 16. Piano di lavoro

| PR | Contenuto | Visibile? |
|---|---|---|
| **A** | Database 0018, controlli SQL, impostazione `loyalty` (spenta) e tester nel pannello admin | No |
| **B** | App del ristoratore: scelte e patto, Timbra, esito, statistiche | Solo ai tester in modalità test |
| **C** | App del cliente: QR, Le mie tessere, segnalazioni, avvisi | Solo ai tester |
| **D** | Pannello admin: scheda Tessere; guida di prova sul DEV | Admin |
| **E** | Righe da aggiungere a privacy e termini (§14) | — |

Dopo ogni PR, come sempre:
- 🧑 migration sul DEV;
- prova con i due account (tu come cliente, il «ristoratore di prova» come locale), in modalità
  **test**;
- registro e stato aggiornati.

---

## 17. Altre idee (facoltative, dopo la prima versione)

- **«C'era posto quando sei arrivato?»** dopo il timbro: misura l'affidabilità degli stati.
- **Serata a timbro doppio** collegata all'offerta della serata (solo a favore del cliente).
- **Riga sulla tessera** nella pagina pubblica `/r/…` e sull'adesivo in vetrina, a funzione accesa.
- **Avviso al locale** «hai 3 clienti a un timbro dal premio», senza dire chi sono.

---

## 18. Valori iniziali da confermare (🧑)

| # | Valore | Proposta |
|---|---|---|
| 1 | Timbri per il premio (limiti per il ristoratore) | da 5 a 20 |
| 2 | Validità del premio dopo lo sblocco | 60 giorni |
| 3 | Azzeramento dei timbri per inattività | 6 mesi senza visite |
| 4 | Preavviso quando il locale smette o non paga più | 30 giorni |
| 5 | Tempo minimo fra due timbri nello stesso locale | 4 ore |
| 6 | Durata del QR | 60 secondi, rinnovo automatico |
| 7 | Annullamento di un timbro sbagliato | entro 2 minuti |
| 8 | Giorni con timbro doppio | max 2 a settimana (o toglierli del tutto) |
| 9 | Tetti di scansione per locale | 60 ogni 10 minuti, 300 al giorno |
| 10 | Soglie delle segnalazioni | avviso a 3, sospensione a 5 (clienti diversi, in 60 giorni); sospensione di 90 giorni; tessera tolta alla seconda sospensione in 12 mesi |
| 11 | Lista dei premi | caffè, dolce, antipasto, contorno, primo, pizza, bibita analcolica, coperto (aggiungere o togliere?) |
| 12 | Condizione del timbro | «un pasto al tavolo» o «una consumazione al tavolo» |
| 13 | Nome nell'app | «Tessera» |
