# HAPOSTO — Progetto «Visite e tessera fedeltà» (proposta)

**10 ottobre 2026 · stato: proposta da decidere dopo il pilot · nessun codice scritto.**

Valutazione del documento «Sistema di disponibilità ristoranti, check-in verificato e loyalty»
(scritto con ChatGPT e fornito dal titolare). Dice come si applicherebbe a HAPOSTO, se ne vale la
pena e come lo costruirei.

Legenda: 🧑 tocca al titolare · 🤖 lo fa Claude · ⚖️ serve un professionista.

---

## 0. In breve

- **Sì, vale la pena, ma in versione piccola e al momento giusto.** È una **tessera timbri
  digitale**: «ogni 10 visite, il dolce lo offre la casa», come la tessera di carta del bar.
  Il timbro si prende mostrando alla cassa un **QR temporaneo** del cliente, che il locale scansiona
  con l'app HAPOSTO. Tutto **facoltativo**, per i clienti e per i locali.
- **Non lo farei prima del pilot.** Il rischio vero di HAPOSTO è che i ristoratori aggiornino lo
  stato durante il servizio, e il documento stesso lo dice (punto 74). Prima si dimostra quello
  (Tappe 1–8), poi si aggiunge la tessera.
- **Il momento giusto è marzo–aprile 2027**, subito dopo il pilot. Così, a fine beta (30 giugno
  2027), ogni locale vede quanti clienti gli ha portato HAPOSTO. È il miglior argomento per farlo
  passare a Pro.
- **Cosa non farei** (o non subito):
  - punti in euro o credito;
  - punti validi in più locali;
  - CRM con i nomi dei clienti;
  - integrazione con le casse;
  - prezzo «a cliente»;
  - verifica col GPS.

  Danno complessità, rischi legali o incentivi alla frode, senza aiutare il pilot.

---

## 1. Cosa propone il documento di partenza

1. **Check-in verificato:** il cliente mostra un QR temporaneo e monouso, il locale lo scansiona e
   il server registra la visita. Il documento scarta giustamente il QR statico, che si può
   fotografare e riusare.
2. **Loyalty:** visite o punti verso un premio scelto dal locale; moltiplicatori nei giorni
   morti; premi riscattati con un secondo QR.
3. **Promozioni last minute** legate alla disponibilità («vieni entro 30 minuti, punti doppi»).
4. **Dashboard e attribuzione:** visite, coperti, nuovi clienti e clienti di ritorno, fatturato
   stimato con lo scontrino medio, poi integrazione con le casse.
5. **Monetizzazione:** abbonamento a tre livelli, pagamento per cliente o modello ibrido.
6. **Accesso facoltativo:** il login si chiede solo quando serve, per esempio al primo check-in.

---

## 2. Cosa HAPOSTO ha già

Buona parte del documento è **già realtà** in HAPOSTO. Mancano proprio il check-in e la tessera.

| Idea del documento | In HAPOSTO oggi |
|---|---|
| Tre stati a un tocco (37–38, 75) | ✅ C'è posto / Pochi posti / Completo, più «È ancora così: confermo» |
| Stato che scade da solo (76) | ✅ 30 minuti, poi «Da aggiornare»; promemoria al ristoratore |
| Nessun account per cercare (21–25) | ✅ Account facoltativo, solo Google |
| Avviso sul locale preferito (44) | ✅ «Avvisami quando c'è posto» (Plus) |
| Promozione last minute (13, 42) | ✅ in parte: **offerta della serata**, solo con posto, scade con lo stato |
| Previsione della disponibilità (40) | ✅ in parte: «di solito a quest'ora» (Plus) |
| Statistiche per il ristoratore (15) | ✅ in parte: visite alla scheda, indicazioni, chiamate, pagina del QR, aggiornamenti |
| Staff che usa l'app (5.6) | ✅ collaboratori (Pro, fino a 5) |
| Densità in una città (79) | ✅ pilot su Pesaro |
| Prova gratuita (80) | ✅ beta fino al 30/06/2027, poi 30 giorni di prova |
| **Check-in verificato** | ❌ |
| **Tessera fedeltà / premi** | ❌ |
| **Coperti e clienti nuovi/di ritorno** | ❌ |
| «C'era posto quando sei arrivato?» (78) | ❌ |

---

## 3. Vale la pena? Pro e contro

### Pro

| # | Pro | Perché conta per HAPOSTO |
|---|---|---|
| 1 | **Prova il valore** | Oggi HAPOSTO mostra «ti hanno visto 300 persone». Con le visite registrate mostra «ti abbiamo portato 31 clienti e 74 coperti»: è la frase che fa pagare Pro |
| 2 | **I ristoranti portano utenti** | Il problema di ogni app a due lati è partire: servono clienti per convincere i locali, e locali per avere clienti. Con la tessera, il ristoratore ha un motivo per dire ai suoi clienti abituali «scarica HAPOSTO» |
| 3 | **Un motivo per riaprire l'app** | Oggi l'app si apre solo quando si cerca posto. La tessera la fa riaprire anche nei locali dove si va sempre |
| 4 | **Riempire le serate morte** | Timbro doppio il martedì: il ristoratore sposta clienti sulle sere vuote. È proprio il motivo per cui esiste HAPOSTO |
| 5 | **Dati per l'affidabilità** | La domanda «c'era posto quando sei arrivato?» misura se gli stati sono veri. È il cuore della fiducia nell'app |
| 6 | **Si appoggia a ciò che c'è** | Account Google, collaboratori, Pro, offerta, statistiche, adesivo QR, pannello admin, registro: va aggiunto poco |
| 7 | **Costo zero** | Supabase Free basta. Lo scanner di Google (ML Kit) è gratuito e non chiede il permesso della fotocamera |
| 8 | **Concetto già noto** | Tutti conoscono la tessera timbri del bar: non serve spiegarla |

### Contro

| # | Contro | Come lo affronterei |
|---|---|---|
| 1 | **Lavoro in più per lo staff** proprio quando c'è più gente | Scansione **alla cassa**, quando il cliente paga (c'è già un momento di contatto). Un gesto solo, scansioni in fila, tutto facoltativo |
| 2 | **Distrae dal problema principale** (aggiornare lo stato) | Si fa **dopo** il pilot, solo se le soglie sono raggiunte |
| 3 | **Serve l'account** del cliente | Il login si chiede solo quando tocca «Mostra il mio QR» (come suggerisce il documento). Chi non vuole, usa l'app come oggi |
| 4 | **Privacy**: dove mangia una persona è un'informazione delicata | Il locale vede numeri aggregati e un codice anonimo, mai nome ed email. Il QR non contiene dati. Conservazione limitata. Testo chiaro nella privacy |
| 5 | **Norme sui premi** (manifestazioni a premio, DPR 430/2001) | Premi solo come **sconto o omaggio del locale stesso** (la forma tipica della tessera timbri). Niente premi in denaro né offerti da HAPOSTO. Da far verificare ⚖️ prima del lancio |
| 6 | **Frodi** (timbri falsi) | Contano poco se il ristorante paga un abbonamento fisso: falsificare non gli fa guadagnare niente e i premi li paga lui. Bastano pochi controlli (§7) |
| 7 | **Sottostima**: si contano solo i clienti che mostrano il QR | Lo si dice chiaramente nelle statistiche («almeno N clienti») |
| 8 | **Assistenza** («non mi ha dato il timbro») | Regole semplici; il ristoratore può aggiungere un timbro a mano in caso di errore, con registro |
| 9 | **Concorrenza** (TheFork ha i suoi punti, ci sono app di tessere) | HAPOSTO parla di chi entra senza prenotare: per lui la tessera alla cassa è naturale e TheFork non la copre |

### Bilancio

Il pro n. 2 da solo giustifica il progetto: i locali che portano i loro clienti nell'app.
I contro sono gestibili, **tranne** il n. 2, che dipende solo dal momento in cui lo si fa.
Quindi: **sì, dopo il pilot, in versione minima, misurando se funziona.**

---

## 4. La mia scelta: cosa farei e cosa no

| Idea | Decisione | Perché |
|---|---|---|
| QR temporaneo del cliente scansionato dal locale | ✅ **V1** | Il cliente non può convalidarsi da solo; non serve un tablet; al cliente non serve la fotocamera |
| Tessera a timbri (N visite → 1 premio) | ✅ **V1** | Semplice, la conoscono tutti, nessun calcolo |
| Premio consegnato con la stessa scansione | ✅ **V1** | Niente secondo QR: alla scansione lo staff vede «premio disponibile» → **Consegnato** |
| Coperti (persone al tavolo) | ✅ **V1** | Il numero che interessa al ristoratore (documento, punto 50) |
| Clienti nuovi / di ritorno | ✅ **V1** | Si calcola dalle visite, senza dati in più |
| Codice di riserva sotto il QR | ✅ **V1** | Se la fotocamera non va, lo staff scrive 6 caratteri |
| «C'era posto quando sei arrivato?» | ✅ **V1.5** | Misura l'affidabilità degli stati (il cuore di HAPOSTO) |
| Scontrino medio → valore stimato | ✅ **V1.5** | Un solo numero inserito dal ristoratore, dichiarato come stima |
| Timbro doppio in giorni o serate scelti | 🟡 **V2** | Ottimo per le sere vuote; si collega all'offerta della serata |
| Filtro «con offerta» nella Home | 🟡 **V2** | Il «last minute» del documento, senza una sezione nuova |
| Avvisi a chi non torna da tempo | 🟡 **V3** | Solo con consenso marketing, mandati da HAPOSTO senza dare i nomi al locale |
| Punti al posto dei timbri | ❌ | Complicano senza un vantaggio chiaro per il cliente |
| Credito in euro (es. «€20 di credito») | ❌ | Somiglia a un buono, crea problemi legali e fiscali |
| Punti validi in più locali | ❌ | Diventa una manifestazione a premio di HAPOSTO (⚖️, cauzione, regolamento) |
| Verifica col GPS | ❌ | Il locale che scansiona è già la prova; il GPS chiede permessi e conserva posizioni |
| Impronta del dispositivo | ❌ | Invadente, inutile con i controlli del §7 |
| CRM con nomi e dati dei clienti | ❌ | Il ristoratore diventerebbe titolare di dati personali; troppo per questa fase |
| Integrazione con le casse | ❌ | Costosa e diversa per ogni cassa |
| Prezzo per cliente o ibrido | ❌ | Fattura variabile e incentivo a falsificare; resta Pro a prezzo fisso |
| Referral (invita un amico) | ❌ (per ora) | Da riconsiderare dopo il lancio |
| Notifiche «3 ristoranti liberi vicino a te» | ❌ | Invadenti; c'è già l'avviso sul singolo locale |

---

## 5. Come funzionerebbe

### 5.1 Il cliente

1. Nella **scheda del locale**, se il locale ha la tessera attiva, compare un riquadro:

   ```
   🎟 Tessera di Trattoria Amica
   ●●●○○○○○○○  3 timbri su 10
   Premio: dolce offerto
   [ Mostra il mio QR ]
   ```

2. Tocca **Mostra il mio QR**. Se non ha l'account: «Accedi con Google per raccogliere i timbri»
   (una volta sola, poi resta collegato).
3. Schermata del QR: luminosità al massimo, QR grande, **scade tra 2:00** e si rinnova da solo.
   Sotto c'è il codice di riserva (es. `K7P-4QX`) e la scritta «Mostralo alla cassa».
4. Appena il locale scansiona, la schermata cambia da sola: **«✓ Timbro aggiunto! 4 su 10»**.
5. Al decimo timbro: **«🎁 Premio sbloccato: dolce offerto. Valido fino al …»**. Il premio lo
   consegna il locale alla visita successiva, con la stessa scansione.
6. **Account → Le mie tessere**: tutte le tessere con timbri, premi da ritirare e scadenze.
7. **V1.5:** un'ora dopo la visita, una domanda con due tasti: «Quando sei arrivato c'era posto
   come diceva HAPOSTO? Sì / No».

### 5.2 Il ristoratore e lo staff

**Attivare la tessera** (Gestisci il locale → **Tessera fedeltà**, solo titolare):
- interruttore **Attiva**;
- **timbri per il premio**: da 5 a 20 (proposta: 10);
- **premio**: testo breve, max 60 caratteri, con esempi pronti («dolce offerto», «caffè e amaro
  offerti», «10% di sconto sul conto»);
- **validità del premio**: 60 giorni (modificabile);
- regola fissa mostrata al cliente: un timbro per persona per servizio (pranzo o cena).

**Durante il servizio** (dashboard, sotto i tre tasti dello stato, solo se la tessera è attiva):
- un tasto secondario **📷 Registra visita**, che apre lo scanner di Google: non chiede il permesso
  della fotocamera all'app;
- dopo la scansione compare un riquadro per 5 secondi, poi lo scanner è pronto per il prossimo:

  ```
  ✓ Visita registrata · cliente A7F3 · 4ª visita
  Persone al tavolo:  [−]  2  [+]
  🎁 Premio da consegnare: dolce offerto   [ Consegnato ]
  ```

- **Inserisci codice** se il QR non si legge;
- lo usano titolare e collaboratori (con la verifica in due passaggi, come per lo stato);
- **la dashboard resta quella di oggi**: lo stato rimane la cosa più grande dello schermo.

**Statistiche** (Gestisci il locale → Statistiche, nuova sezione):

```
ULTIMI 30 GIORNI · clienti arrivati con HAPOSTO (almeno)
Visite registrate          31
Coperti                    74
Clienti nuovi              18   ·   di ritorno 13
Premi consegnati            3
Valore stimato (V1.5)   €2.368   (74 coperti × €32 di scontrino medio)
«C'era posto?» (V1.5)      94% sì
```

### 5.3 L'admin

- Scheda del locale nel pannello: tessera attiva, visite e premi dei 30 giorni, eventuali
  segnalazioni (§7).
- Registro: attivazione e modifica della tessera, timbri aggiunti a mano, premi consegnati.

---

## 6. Il QR: com'è fatto e perché in questo verso

**Perché il QR è del cliente e lo scansiona il locale** (come consiglia il documento):

| Scelta | Pro | Contro | Verdetto |
|---|---|---|---|
| QR del cliente, scansionato dal locale | Il cliente non può convalidarsi da solo; il cliente non deve inquadrare niente; basta il telefono dello staff | Lo staff fa un gesto | ✅ |
| QR del locale che cambia ogni 30 s, scansionato dal cliente | Lo staff non fa niente | Serve uno schermo sempre acceso alla cassa (tablet), e il cliente deve aprire la fotocamera | ❌ per i locali piccoli |
| QR fisso in vetrina (quello che c'è già) | Zero lavoro | Si fotografa e si riusa: non prova niente | ❌ per i timbri; resta per la pagina del locale |

**Com'è fatto il QR:**
- contiene solo un **codice casuale** (`HAPOSTO-V1:` + 22 caratteri casuali), **nessun dato
  personale**;
- lo crea il **server** quando il cliente apre la schermata, e nel database ne resta solo
  l'impronta;
- vale **2 minuti** e **una volta sola**;
- il codice di riserva a 6 caratteri è legato allo stesso token e scade insieme;
- lo verifica solo il server: cliente valido, locale valido, staff autorizzato, regole del §7.

---

## 7. Regole e antifrode (leggere, ma sufficienti)

Con un abbonamento fisso, il ristoratore non guadagna niente a creare visite false: i premi li paga
lui. Basta quindi impedire gli errori e gli abusi evidenti.

| Regola | Valore proposto |
|---|---|
| Un timbro per cliente, per locale, per servizio | max 1 ogni 4 ore (pranzo e cena contano separati) |
| Token | 2 minuti, monouso, generato dal server |
| Chi può scansionare | solo titolare e collaboratori **di quel locale**, con la verifica in due passaggi |
| Niente autotimbri | chi gestisce il locale non può timbrare la propria tessera in quel locale |
| Limite di velocità | max 60 scansioni ogni 10 minuti per locale (modificabile dal pannello) |
| Timbro a mano | il titolare può aggiungere 1 timbro per correggere un errore, max 5 al mese, con registro |
| Account sospesi | niente timbri né premi |
| Segnalazioni all'admin | stesso cliente timbrato spesso dallo stesso membro dello staff; molti timbri a mano; picchi fuori orario |

---

## 8. Privacy e aspetti legali

**Privacy (GDPR):**
- il locale vede solo **numeri aggregati** e un **codice cliente anonimo** diverso per ogni locale
  (es. `A7F3`): mai nome, email o foto. Così non diventa titolare di dati personali dei clienti;
- HAPOSTO conserva: chi, dove, quando, quante persone. Servono a dare il servizio richiesto dal
  cliente (base giuridica: contratto);
- **conservazione**:
  - visite 24 mesi, come statistiche e registro;
  - timbri di una tessera ferma da 12 mesi: si azzerano;
  - token: cancellati dopo un giorno;
- con la cancellazione dell'account sparisce tutto (cancellazione a cascata, come per le altre tabelle);
- nessuna posizione GPS e nessuna impronta del dispositivo;
- serve aggiornare l'informativa privacy, la scheda «Sicurezza dei dati» di Google Play e i
  termini per ristoranti e utenti.

**Premi (⚖️ da verificare con il professionista della Tappa 5):**
- in Italia i premi legati agli acquisti possono rientrare nelle **manifestazioni a premio** (DPR
  430/2001), che richiedono regolamento, comunicazioni e cauzione;
- la stessa norma esclude, tra l'altro, gli sconti e gli omaggi di prodotti dello stesso genere
  di quelli acquistati: è la forma della tessera timbri del bar;
- **proposta di progetto per restare in quel caso:**
  - il premio lo decide, lo offre e lo paga **il ristorante**;
  - deve essere uno **sconto o un omaggio nel suo locale**;
  - HAPOSTO fornisce solo lo strumento (la tessera digitale), senza premi propri, senza denaro e
    senza punti fra locali diversi;
- nei termini per i ristoranti: il premio è un impegno del locale verso il cliente; HAPOSTO non
  risponde se il locale non lo consegna (ma può disattivargli la tessera).

---

## 9. Piani e prezzi

| Chi | Cosa | Perché |
|---|---|---|
| **Clienti** | Tessere **gratis** per tutti (serve solo l'accesso con Google) | Se costasse, nessuno la userebbe e il pro n. 2 sparirebbe. Plus resta com'è |
| **Ristoranti** | Tessera e statistiche delle visite **dentro Pro** (nuova funzione `LOYALTY`) | Durante la beta e la prova l'hanno tutti; poi è un motivo in più per pagare Pro |
| Prezzo | **Invariato** (19,90 €/mese) | Il prezzo si decide con i numeri del pilot (Tappa 8), come già previsto |
| Pagamento per cliente | **No** | Fattura imprevedibile, incentivo a falsificare, più lavoro di fatturazione |

---

## 10. Cosa misuriamo (e cosa no)

- **Visite registrate** e **coperti**: «almeno N», perché contano solo i clienti che mostrano il QR.
- **Clienti nuovi o di ritorno**: prima visita registrata in quel locale oppure no.
- **«Arrivato con HAPOSTO»** (V1.5): il telefono del cliente sa se ha aperto la scheda del locale
  nelle 3 ore prima. Al momento del QR manda solo «sì/no»: la cronologia di navigazione **resta sul
  telefono**.
- **Affidabilità** (V1.5): percentuale di «c'era posto: sì». All'inizio la vede solo il ristoratore
  (e l'admin). Più avanti si può valutare un badge pubblico, con attenzione a non penalizzare chi
  aggiorna onestamente.
- **Non misuriamo** lo speso reale: il valore è una stima dichiarata (coperti × scontrino medio).

---

## 11. Struttura tecnica

### 11.1 Database (una migration nuova, rieseguibile, con i suoi controlli in CI)

| Tabella | Contenuto |
|---|---|
| `loyalty_programs` | uno per locale: attiva, timbri per il premio (5–20), testo del premio (≤ 60), giorni di validità del premio, giorni con timbro doppio (V2) |
| `visit_tokens` | impronta del token, cliente, creato, scade, usato da / quando, codice di riserva (impronta). Pulizia ogni notte |
| `visits` | locale, cliente, chi ha scansionato, quando, persone (1–30), timbri dati (1 o 2), «arrivato con HAPOSTO» (V1.5), timbro a mano sì/no |
| `loyalty_cards` | locale + cliente: timbri attuali, visite totali, ultima visita |
| `loyalty_rewards` | premio sbloccato: testo (copiato al momento), sbloccato il, scade il, consegnato il, da chi |
| `visit_feedback` (V1.5) | visita, «c'era posto»: sì/no |

Funzioni (tutte `SECURITY DEFINER`, con permessi espliciti come dalla 0014):

| Funzione | Chi la usa | Cosa fa |
|---|---|---|
| `create_visit_token()` | cliente con account | Crea token e codice di riserva, validi 2 minuti |
| `visit_token_status(token)` | cliente | La schermata del QR sa se è stato scansionato e con quale esito |
| `register_visit(locale, token o codice, persone)` | titolare o staff con 2FA, funzione `LOYALTY` | Controlla le regole del §7, registra la visita, aggiorna la tessera, sblocca il premio, restituisce l'esito |
| `redeem_reward(locale, premio)` | titolare o staff | Segna il premio come consegnato |
| `set_loyalty_program(...)` | titolare | Attiva e modifica la tessera |
| `add_manual_stamp(...)` | titolare | Timbro a mano, con limite e registro |
| `my_loyalty_cards()` | cliente | Le mie tessere |
| `restaurant_loyalty_stats(locale, giorni)` | titolare e staff | Le statistiche del §5.2 |
| `admin_*` | pannello | Vista e disattivazione della tessera di un locale |

Più: lavori pianificati per la pulizia (token ogni notte; tessere ferme da 12 mesi ogni domenica),
conservazione aggiunta a `purge_operational_data`, voce `loyalty` in `app_config` per i limiti.

### 11.2 App

- **Cliente:**
  - riquadro tessera nella scheda del locale;
  - schermata del QR (ZXing, già nel progetto per gli adesivi);
  - «Le mie tessere» in Account;
  - domanda del giorno dopo (V1.5).
- **Ristoratore:**
  - tasto «Registra visita» con lo **scanner di codici di Google** (ML Kit, gratuito, senza
    permesso della fotocamera);
  - riquadro dell'esito con persone e premio;
  - impostazioni della tessera;
  - statistiche.
- **Sito:** la pagina pubblica `/r/…` dice «Qui c'è la tessera HAPOSTO: N timbri = premio» (fa da
  invito a scaricare l'app).
- **Adesivo QR** in vetrina: una riga in più, «Tessera fedeltà su HAPOSTO».

### 11.3 Costi

Nessuno. Il traffico è minimo (una chiamata per QR e una per scansione) e resta nel piano Free di
Supabase.

---

## 12. Fasi e tempi

| Fase | Quando | Cosa | Chi |
|---|---|---|---|
| **V0 — Chiedere prima di costruire** | Prova sul campo e pilot (Tappe 1 e 7) | Due domande in più ai ristoratori: «Useresti una tessera timbri digitale nell'app? Che premio daresti?». Ai clienti: «La useresti?» | 🧑 |
| **Decisione** | Tappa 8 (fine febbraio 2027) | Se le soglie del pilot sono raggiunte **e** almeno metà dei ristoratori la vuole → si fa | 🧑 |
| ⚖️ **Verifica legale** | Insieme ai documenti legali (Tappa 5) o alla decisione | Premi come sconto/omaggio del locale (§8); testi privacy e termini | ⚖️ |
| **V1 — Tessera e visite** | marzo–aprile 2027 (3–4 settimane) | Database, app cliente e ristoratore, statistiche base, pannello. Prova sul DEV, poi produzione | 🤖 🧑 |
| **V1.5 — Fiducia e valore** | maggio 2027 | «C'era posto?», «arrivato con HAPOSTO», scontrino medio e valore stimato | 🤖 |
| **Fine beta** | giugno 2027 | Nel messaggio ai ristoratori: «In questi mesi HAPOSTO ti ha portato almeno N clienti e M coperti» | 🧑 |
| **V2 — Serate vuote** | dopo il lancio | Timbro doppio in giorni o serate scelti, collegato all'offerta; filtro «con offerta» | 🤖 |
| **V3 — Ritorno dei clienti** | solo se richiesto | Avvisi a chi è vicino al premio o non torna da tempo, con consenso, senza dare i nomi ai locali | 🤖 ⚖️ |

---

## 13. Come capiremo se funziona

Dopo **8 settimane** dalla V1, con i partner attivi:

| Indicatore | Soglia per continuare |
|---|---|
| Partner Pro che attivano la tessera | ≥ 40% |
| Locali con tessera che registrano almeno 10 visite al mese | ≥ 50% |
| Clienti con almeno 2 timbri nello stesso locale | ≥ 30% di chi ha almeno un timbro |
| Nuovi account nati da «Mostra il mio QR» | in crescita mese su mese |
| **Aggiornamenti dello stato nei locali con tessera** | **non devono calare** (se calano, la tessera sta distraendo: si semplifica o si toglie) |
| «C'era posto?» (V1.5) | ≥ 85% sì (sotto: lavorare sugli stati, non sulla tessera) |

Se le soglie non sono raggiunte, la tessera si può **spegnere dal pannello** senza toccare il resto
dell'app.

---

## 14. Decisioni da prendere (🧑)

1. Inserire le domande della **V0** nella prova sul campo e nel pilot (consigliato, costo zero).
2. Dopo il pilot (Tappa 8): **si fa / non si fa** la V1.
3. Valori iniziali:
   - timbri per il premio (proposta 10);
   - validità del premio (proposta 60 giorni);
   - un timbro per servizio (proposta: ogni 4 ore).
4. Nome nell'app: «Tessera», «Timbri», «Fedeltà»… (proposta: **Tessera**).
5. Includere la tessera in Pro senza cambiare prezzo (consigliato) oppure valutare un prezzo
   diverso con i numeri del pilot.
