# HAPOSTO — Roadmap da qui al lancio e alla gestione

Aggiornata al **5 ottobre 2026**. Sostituisce, per il percorso da seguire, le fasi della
`HAPOSTO_ROADMAP_COMPLETA.md`, che resta come archivio delle scelte e dei dettagli.

Legenda: 🧑 tocca a te · 🤖 lo fa Claude (codice, guide, controlli) · ⚖️ serve un professionista
(commercialista, avvocato). Costi e limiti sono **indicativi**: verificali al momento di attivarli.

---

## 0. Dove siamo oggi

**L'app è completa e collaudata sul progetto DEV** (PR #16–#19, CI verde). Cosa c'è già:

| Area | Cosa c'è già |
|---|---|
| Cliente | Lista e mappa dei locali vicini, stato con colori e simboli, scheda del locale (offerta, menù, sito, indicazioni, chiama), preferiti, Plus (avvisi, raggio più ampio), account facoltativo con Google |
| Ristoratore | Accesso Google + verifica in due passaggi, rivendicazione con codice dettato al telefono del locale, dashboard con 3 stati a un tocco, dettagli a voce, note pronte, offerta, prenotazioni di sala a voce, menù/sito/file, QR, collaboratori, statistiche, promemoria |
| Admin | Pannello nascosto con seconda password: richieste, locali, utenti, contenuti, abbonamenti, pagamenti, registro, impostazioni |
| Server | 17 migration, 7 Edge Function, 9 lavori pianificati, notifiche push, ping anti-pausa |
| Sito | Home, area ristoratori (Pro con Stripe, pronta ma non attiva), pagina pubblica `/r/…` per i QR, pagine legali, cancellazione account |
| Pagamenti | Modello deciso (prova, poi "Non collegato" senza abbonamento); codice pronto, **non attivo**: servono P.IVA, Stripe e Play |

**Cosa manca:** le cose "fuori dal codice". Decisioni, account dei servizi, documenti legali, il
progetto di produzione, Google Play, il pilot con locali veri, i pagamenti attivi.

---

## 1. Il percorso in una pagina

Le tappe vanno **in ordine**; quelle segnate "in parallelo" si possono portare avanti insieme
alle altre.

| # | Tappa | Chi | Costo | Durata indicativa | Quando |
|---|---|---|---|---|---|
| **1** | Prova sul campo sul DEV con 1–3 ristoratori amici, e correzioni | 🧑 🤖 | 0 | 2–3 settimane | ottobre 2026 |
| **2** | Decisioni di base: nome definitivo, zona del pilot, vantaggi di Plus | 🧑 | 0 | 1–2 settimane | ottobre 2026 |
| **3** | Basi legali e fiscali (in parallelo): commercialista e P.IVA, dominio, email di assistenza | 🧑 ⚖️ | dominio 15–40 €/anno; commercialista a preventivo | 3–6 settimane | ottobre–novembre |
| **4** | **Produzione** (guida, Parte 10): progetto Supabase reale, locali di Pesaro da OpenStreetMap | 🧑 🤖 | 0 (piano Free) | 1–2 ore + controllo dei locali | novembre |
| **5** | Documenti legali definitivi: privacy, termini, condizioni per i ristoranti, cookie | ⚖️ 🧑 🤖 | online 30–150 €/anno o avvocato a preventivo | 2–4 settimane | novembre–dicembre |
| **6** | Google Play: account, chiave di firma, scheda, test interno e **test chiuso** | 🧑 🤖 | 25 $ una tantum | 3 settimane (14 giorni di test chiuso) | dicembre |
| **7** | **Pilot Pesaro** con 20–40 locali veri | 🧑 | stampa di QR e volantini | 6–8 settimane | gennaio–febbraio 2027 |
| **8** | Decisione dopo il pilot e correzioni | 🧑 🤖 | 0 | 1–2 settimane | fine febbraio |
| **9** | **Lancio pubblico** su Google Play | 🧑 🤖 | 0 | 1–2 settimane | marzo 2027 |
| **10** | Pagamenti attivi: Pro sul sito (Stripe, Parte 8) e Plus nell'app (Play, Parte 7) | 🧑 🤖 ⚖️ | commissioni sui pagamenti; fatture elettroniche 50–150 €/anno | 3–4 settimane | aprile–maggio |
| **11** | Fine della beta: i locali passano a pagamento | 🧑 | 0 | 1 mese di comunicazione | giugno 2027 (beta fino al 30/06) |
| **12** | Gestione continuativa | 🧑 🤖 | 0 finché bastano i piani gratuiti | sempre | da luglio 2027 |

---

## 2. Le tappe in dettaglio

### Tappa 1 — Prova sul campo sul DEV (consigliata prima di tutto)

**Perché.** Finora l'app l'hai provata tu. La domanda vera è: *un ristoratore, durante un servizio
di sabato sera, aggiorna lo stato?* Quello che emerge si corregge facilmente sul DEV. In produzione,
con dati veri, ogni cambiamento costa di più.

**Cosa fare.**
1. 🤖 Guida pronta: `HAPOSTO_GUIDA_APP_E_DATI_REALI.md`, capitolo 4 (crea il suo locale nel DEV,
   installa l'app sul suo telefono, la prova, le 5 domande).
2. 🧑 Aggiungi l'email Google del ristoratore ai **Test users** di Google Cloud. Il login è in
   modalità "Testing" e senza quel passo non riesce ad accedere.
3. 🧑 Una cena intera; tu guardi dal tuo telefono cosa vede il cliente.
4. 🧑 Il giorno dopo: le 5 domande, risposte annotate parola per parola.
5. 🤖 Correzioni all'app (testi, ordine dei tasti, dettatura…), con PR e CI come sempre.
6. 🧑 Con l'emulatore di Android Studio (gratis), prova anche il **tempo reale fra due dispositivi**:
   pubblichi su uno e lo vedi sull'altro in 1–2 secondi.

**Fatto quando.** Almeno 1–3 ristoratori hanno usato la dashboard per una serata e le correzioni
emerse sono nell'app.

### Tappa 2 — Decisioni di base (gratis, ma vanno prese presto)

| Decisione | Perché conta | Entro |
|---|---|---|
| **Nome definitivo** ("HAPOSTO" è provvisorio) | Da qui dipendono dominio, pacchetto su Google Play (`com.haposto` diventa **definitivo** al primo caricamento), documenti legali, grafica. Cambiarlo dopo la Tappa 6 costa molto | prima della Tappa 3 (dominio) |
| **Zona del pilot** | Conta la densità: 20–40 locali vicini (es. Pesaro centro + mare) | prima della Tappa 4 (import dei locali) |
| **Vantaggi di Plus** | Oggi: avvisi "si è liberato", preferiti illimitati, raggio 100 km, "di solito a quest'ora". Da confermare o ampliare | prima della Tappa 10 |
| **Prezzi** (oggi provvisori) | Pro 19,90/99,90/199,90 €, Plus 0,99/4,99/9,99 € IVA inclusa | si confermano con i numeri del pilot (Tappa 8) |

### Tappa 3 — Basi legali e fiscali (in parallelo)

**Perché.** Per incassare dai ristoranti serve una **partita IVA**. Per i documenti legali serve
sapere **chi è il titolare** del servizio (nome, indirizzo, P.IVA). Per Google Play e il sito
serve un **indirizzo stabile**.

1. 🧑 ⚖️ **Commercialista**:
   - forma giuridica (ditta individuale in forfettario oppure SRL/SRLS);
   - codice attività;
   - IVA sugli abbonamenti venduti a ristoranti e a privati;
   - fatturazione elettronica (SDI).

   Senza P.IVA si può fare il pilot **gratuito** (beta), non vendere Pro.
2. 🧑 **Email di assistenza** (gratis): un Gmail dedicato, per esempio `haposto.assistenza@…`.
   Serve per Play, per le pagine legali e per le risposte agli utenti; separala dalla tua email
   personale. Con il dominio potrai poi inoltrare `info@` e `privacy@` a questa casella.
3. 🧑 **Dominio** (15–40 €/anno, **ti chiederò conferma prima**):
   - ✅ conviene comprarlo dopo aver deciso il nome;
   - con Cloudflare il sito già pubblicato si collega al dominio in pochi minuti
     (Parte 9 della guida, "dominio");
   - gli indirizzi `info@` e `privacy@` si inoltrano gratis alla Gmail di assistenza.

   ⚠️ **Email di contatto.** L'app scrive già `info@haposto.app`: account sospeso, verifica in due
   passaggi persa, piani, registro attività, termini. Lo stesso indirizzo è in `app_config`
   (`public_links.support_email`) e come valore predefinito del sito. Finché il dominio non è tuo,
   quella casella **non esiste**, e chi comprasse il dominio riceverebbe le email degli utenti.
   Per la prova sul campo sul DEV non conta. **Prima del test chiuso (Tappa 6)** c'è una di queste
   due strade:
   - compri il dominio e inoltri `info@` alla Gmail di assistenza;
   - 🤖 sostituisco l'indirizzo con la Gmail di assistenza (una PR, poi pannello → Impostazioni →
     `public_links` e la variabile `HAPOSTO_CONTACT_EMAIL` del sito).
4. 🧑 **Sicurezza degli account**: verifica in due passaggi su Google, GitHub, Supabase,
   Cloudflare; un gestore di password (vedi il documento privato *Accessi e chiavi*).

### Tappa 4 — Produzione (guida, Parte 10)

**Perché.** I dati veri (locali, ristoratori, utenti) non vanno nel progetto DEV, che serve alle
prove e si può svuotare. La produzione è un **secondo progetto Supabase**, sempre **gratis**: il
piano Free ne ammette due.

**Cosa si fa** (guida, Parte 10, già verificata sul codice, circa 1–2 ore):
1. nuovo progetto `haposto-prod` (Frankfurt, Free);
2. migration 0001–0017 nel SQL Editor (**mai** seed né dati di prova);
3. import dei locali reali della zona del pilot da **OpenStreetMap**, poi controllo qualità
   (`HAPOSTO_GUIDA_APP_E_DATI_REALI.md`, capitolo 3);
4. login Google e verifica in due passaggi anche sulla produzione;
5. la versione **HAPOSTO** (`com.haposto`) sul tuo telefono, con le chiavi di produzione in
   `local.properties`;
6. le tue credenziali del pannello admin di produzione;
7. Firebase per le notifiche dell'app di produzione;
8. Edge Function e lavori pianificati di produzione;
9. il sito passa alla produzione (le pagine `/r/…` dei QR mostrano i locali veri);
10. ping anti-pausa anche per la produzione.

**Dopo:** il DEV resta per le prove; ogni modifica futura si prova **prima sul DEV**, poi si porta
in produzione (guida, Parte 11: "Aggiornare il database").

**Limiti del piano Free da tenere d'occhio** (Tappa 12):
- 500 MB di database;
- 1 GB di file;
- 5 GB di traffico al mese;
- 50.000 utenti attivi al mese;
- pausa dopo 7 giorni senza attività (la evita il ping);
- backup giornalieri non inclusi: si fanno esportazioni periodiche.

### Tappa 5 — Documenti legali definitivi

**Perché.** Prima che un utente o un ristoratore vero usi l'app servono privacy, termini,
condizioni per i ristoranti e cookie **definitivi**. Oggi sono bozze con le parti tra parentesi
quadre ([NOME], [P.IVA], [DATA FINE BETA]…).

1. ⚖️ 🧑 Revisione da un avvocato o da un servizio online. La scheda dei trattamenti è già pronta
   nella roadmap completa, §5.2.
2. 🤖 Inserimento dei dati reali nei file `app/src/main/assets/legal/` (gli stessi del sito).
3. 🧑 Pannello admin → Impostazioni → `legal`: nuova versione (es. `2026-12`). Al prossimo avvio
   l'app chiede a tutti di riaccettare.

### Tappa 6 — Google Play e test chiuso

**Perché.** Il pilot usa l'app installata da Google Play (test chiuso), non file `.apk` passati a
mano.

1. 🧑 **Account Play Console** (25 $ una tantum):
   - *organizzazione* se hai P.IVA o società (serve il numero D-U-N-S, gratuito);
   - *personale* altrimenti: Google impone un **test chiuso con almeno 12 tester per 14 giorni**
     prima della pubblicazione.
2. 🧑 **Chiave di caricamento** (keystore):
   - Android Studio → *Build → Generate Signed App Bundle* → *Create new*;
   - il file `.jks` va in **due posti sicuri** fuori dal PC, la password nel gestore. Se la perdi
     non puoi più aggiornare l'app finché Google non la sostituisce.
3. 🤖 🧑 **Scheda dello store**:
   - *Sicurezza dei dati* (🤖 preparo le risposte);
   - classificazione dei contenuti, pubblico, link alla privacy e alla cancellazione dell'account;
   - **account di prova per i revisori Google**: l'area ristoratore richiede il login.
4. 🧑 **Google Cloud** (schermata di consenso):
   - il client Android con lo SHA-1 della chiave di caricamento e di quella di Play;
   - poi **Publish app**: da "Testing" a "In production", senza verifica perché l'app chiede solo
     email e profilo.
5. 🧑 **Test interno** (tu), poi **test chiuso** (amici e ristoratori della Tappa 1).

### Tappa 7 — Pilot Pesaro

**Perché.** È la prova che decide se HAPOSTO funziona: locali veri, clienti veri, sere vere.

1. 🤖 Kit, che 🧑 stampi:
   - foglio A4 "HAPOSTO in 1 minuto";
   - adesivo QR (si crea già dall'app);
   - copione della visita di 2 minuti.
2. 🧑 Per ogni locale:
   - visita;
   - il titolare installa l'app dal test chiuso e accede;
   - invia la richiesta;
   - tu chiami il **numero pubblico del locale** e approvi;
   - adesivo QR in vetrina.
3. **Pro è gratis** per tutti durante la beta (automatico).
4. 🧑 **Ogni lunedì**:
   - query KPI (`supabase/ops/kpi_queries.sql`);
   - telefonata ai locali "silenziosi".
5. 🧑 Facoltativo, costo zero: due domande in più ai ristoratori e ai clienti sulla **tessera
   fedeltà digitale** (`HAPOSTO_PROGETTO_VISITE_E_TESSERA.md`, fase V0).

**Soglie per proseguire:**

| KPI | Soglia |
|---|---|
| Partner con stato valido alle 20:30 | ≥ 60% |
| Partner che aggiornano almeno 4 servizi su 7 | ≥ 50% |
| Utenti che tornano entro 7 giorni | ≥ 25% |
| Ristoratori che "lo pagherebbero" | ≥ 30% |

### Tappa 8 — Decisione dopo il pilot

- **Soglie raggiunte** → lancio (Tappa 9) e conferma dei prezzi.
- **Soglie mancate** → 🤖 lavoro su promemoria e semplicità, e altre 4 settimane di pilot. Non si
  passa ai pagamenti con dati deboli.
- **Proposta «Visite e tessera fedeltà»** (`HAPOSTO_PROGETTO_VISITE_E_TESSERA.md`):
  - si decide qui, solo con soglie raggiunte e se almeno metà dei ristoratori la vuole;
  - se sì, la V1 si costruisce in marzo–aprile 2027 (3–4 settimane, costo zero);
  - a fine beta ogni locale vedrà quanti clienti gli ha portato HAPOSTO.

### Tappa 9 — Lancio pubblico

1. 🧑 Play Console → **produzione** (dal test chiuso).
2. 🧑 Comunicazione locale: ristoratori del pilot, QR in vetrina, social.
3. 🤖 Se vuoi vedere gli errori che capitano sui telefoni degli utenti, aggiungo i **report dei
   crash** di Firebase (Crashlytics, gratis; oggi l'app non li ha).

### Tappa 10 — Pagamenti attivi

**Pro (ristoranti) sul sito, con Stripe** (guida, Parte 8), dopo la P.IVA:
- account Stripe, tre prezzi IVA inclusa, aliquota IVA, webhook, portale clienti;
- fatture elettroniche, da emettere con un servizio (50–150 €/anno) o dal commercialista;
- prova con carta di prova, poi un pagamento reale di un mese.

**Plus (utenti) nell'app, con Google Play** (guida, Parte 7):
- abbonamento `haposto_plus` con i tre piani base;
- notifiche in tempo reale di Google (Pub/Sub);
- ⚠️ Pub/Sub richiede una **carta** sul progetto Google Cloud: costo previsto zero con questi
  volumi, ma **te lo chiederò prima**.

**Commissioni:**
- Stripe circa 1,5% + 0,25 € per pagamento europeo, più circa 0,7% per gli abbonamenti;
- Google 15% sugli abbonamenti Plus.

### Tappa 11 — Fine della beta (30 giugno 2027)

1. 🧑 Un mese prima: messaggio ai ristoratori (email e telefonata). L'app manda da sola gli avvisi
   7 giorni e 1 giorno prima.
2. **Dal 1° luglio:**
   - chi si abbona resta collegato;
   - chi non si abbona resta in lista come "Non collegato" e può abbonarsi quando vuole;
   - i locali nuovi hanno 30 giorni di prova (modificabili dal pannello).
3. 🧑 La data si cambia dal pannello (Impostazioni → `beta`), senza aggiornare l'app.

### Tappa 12 — Gestione continuativa

| Ogni… | Cosa fare | Dove |
|---|---|---|
| giorno (5 minuti) | Richieste di rivendicazione da verificare al telefono; scheda **Contenuti** (link e file nuovi) | Pannello admin |
| settimana | KPI; locali "silenziosi"; email di GitHub se il ping anti-pausa fallisce | `kpi_queries.sql`, Gmail |
| mese | Esportazione di backup delle tabelle principali (piano Free); controllo dello spazio usato | Supabase |
| mese | Elenco dei pagamenti per le fatture (dopo la Tappa 10) | Pannello → Pagamenti |
| ogni modifica | Nuova migration prima sul DEV, poi in produzione; Edge Function ripubblicate se cambiano | Guida, Parte 11 |
| 3 mesi | Verifica in due passaggi e codici di recupero ancora validi; chiavi e segreti al loro posto | Documento privato *Accessi e chiavi* |
| anno | Rinnovo del dominio; revisione dei documenti legali; prezzi | — |

**Quando passare a piani a pagamento** (sempre chiedendo prima):
- **Supabase Pro**, circa 25 $/mese: quando servono backup giornalieri automatici, o si avvicinano i
  limiti del Free (molti utenti, molto traffico), o una pausa non è accettabile;
- tutto il resto (Firebase, Cloudflare Pages, GitHub) resta gratuito anche con molti utenti.

**Il progetto è "in gestione"** quando:
- app su Google Play;
- documenti legali pubblicati;
- almeno 30 partner attivi a Pesaro;
- notifiche ai ristoratori attive;
- Pro e Plus acquistabili;
- backup e verifica in due passaggi in ordine.

---

## 3. Riepilogo dei costi

| Voce | Quando | Costo |
|---|---|---|
| Supabase DEV + produzione (Free) | ora | 0 |
| Firebase, Cloudflare Pages, GitHub, OpenStreetMap, OpenFreeMap | ora | 0 |
| Gmail di assistenza | Tappa 3 | 0 |
| Dominio | Tappa 3 | 15–40 €/anno |
| Commercialista e P.IVA | Tappa 3 | a preventivo |
| Documenti legali | Tappa 5 | 30–150 €/anno online, o avvocato a preventivo |
| Google Play Console | Tappa 6 | 25 $ una tantum |
| Stampa di QR e volantini | Tappa 7 | pochi euro |
| Stripe | Tappa 10 | solo commissioni sui pagamenti |
| Fatture elettroniche | Tappa 10 | 50–150 €/anno |
| Google Play Billing (Plus) | Tappa 10 | 15% sugli abbonamenti |
| Supabase Pro (facoltativo) | Tappa 12 | circa 25 $/mese |

Regola del progetto: **costo zero finché possibile**. Prima di ogni voce a pagamento Claude lo dice
chiaramente e chiede.
