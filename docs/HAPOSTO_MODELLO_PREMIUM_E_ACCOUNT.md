# HAPOSTO — Modello premium, account, registrazione e acquisti (definizione completa)

Questo documento **definisce** come funzionano account, piani gratuiti e a pagamento, registrazione
di utenti e ristoranti, acquisti e rinnovi. È coerente con `HAPOSTO_ROADMAP_TOP_FREEMIUM.md` (i tre
motori di ricavo) e con il database già pronto (migration `0007`–`0011`, vedi
`HAPOSTO_SQL_INTEGRATIVO.md`).

> Prezzi, IVA, commissioni e regole degli store vanno **ricontrollati al momento del lancio** con un
> commercialista e sulle pagine ufficiali di Google Play e Stripe: qui sono indicativi.

---

## 1. Principi che non cambiano

1. **Il loop centrale è gratis e senza account.** Aprire l'app, vedere chi ha posto, andare: sempre
   gratis, senza registrazione, per sempre.
2. **Il ristoratore prova gratis, poi paga per i vantaggi** (decisione del titolare, 2 ottobre 2026).
   Durante la beta tutti i locali hanno Pro gratis; chi entra dopo ha una prova gratuita (30 giorni,
   modificabili dal pannello admin). Finita la prova, senza abbonamento il locale **resta nella
   lista come "Non collegato"** (dati di directory, senza stato, offerta, menù e sito) e non pubblica.
   Si paga per i vantaggi, non per le statistiche: quelle essenziali restano visibili.
3. **Nessun ranking a pagamento, nessun paywall sul dato** per chi cerca. Plus vende avvisi e comodità.
4. **L'account è facoltativo** per chi cerca: serve solo per funzioni avanzate (preferiti su più
   dispositivi, avvisi, Plus).
5. **Il database decide i diritti**, non l'app: ogni funzione a pagamento è verificata lato server
   (RLS e funzioni SQL). Un'app modificata non sblocca nulla.

---

## 2. Chi usa HAPOSTO (ruoli)

| Ruolo | Account | Come ci si arriva | Cosa può fare |
|---|---|---|---|
| **Visitatore** | no | apre l'app | cercare, filtrare, dettaglio, indicazioni, chiamare, preferiti sul telefono |
| **Utente Gratis** | sì (Google) | "Accedi" dal profilo | + preferiti sincronizzati (max 5) |
| **Utente Plus** | sì + abbonamento | acquisto in app (Google Play) | + avvisi "c'è posto", preferiti illimitati, filtri avanzati, raggio esteso, storico |
| **Titolare (OWNER)** | sì | claim approvato o registrazione nuovo locale approvata | pubblicare lo stato, gestire telefono, staff, fatturazione, abbonamento |
| **Staff (STAFF)** | sì | invitato dal titolare (Pro) | pubblicare lo stato; niente pagamenti né dati fiscali |
| **Admin piattaforma** | sì + flag | impostato da te (`is_platform_admin`) | approvare richieste, regalare piani, importare directory |
| **Server pagamenti** | chiave `service_role` | solo Edge Function | registrare abbonamenti e pagamenti |

Una stessa persona può essere utente Plus **e** titolare di un locale: i diritti si sommano.

---

## 3. Piani e funzioni

### 3.1 Ristoranti (B2B)

| Funzione | Codice | Senza piano ("Non collegato") | Pro | Pro+ |
|---|---|:-:|:-:|:-:|
| Il locale resta nella lista con i dati di directory | – | ✓ | ✓ | ✓ |
| Stato live con un tap (C'è posto / Pochi posti / Completo) | `LIVE_STATUS` | – | ✓ | ✓ |
| Telefono pubblico e tasto Chiama | `PHONE_PUBLIC` | – | ✓ | ✓ |
| Pagina pubblica + QR "Prima di chiamare" con lo stato | `PUBLIC_PAGE_QR` | – | ✓ | ✓ |
| Statistiche base (ultimi 7 giorni) | `ANALYTICS_BASIC` | ✓ | ✓ | ✓ |
| Tavoli liberi, attesa, nota breve, offerta della serata, menù/sito/file | `LIVE_DETAILS` | – | ✓ | ✓ |
| Statistiche complete (90 giorni: visite, indicazioni, chiamate) | `ANALYTICS` | – | ✓ | ✓ (365 gg) |
| Account staff (fino a 5) | `STAFF_ACCOUNTS` | – | ✓ | ✓ (50) |
| Promemoria "come siete messi?" | `REMINDERS` | – | ✓ | ✓ |
| Notifica ai follower quando si libera | `FOLLOWER_NOTIFICATIONS` | – | ✓ | ✓ |
| Prenotazioni di sala sincronizzate tra dispositivi | `RESERVATIONS_CLOUD` | – | ✓ | ✓ |
| Più sedi, API, integrazione cassa/gestionale | `MULTI_LOCATION`, `API_ACCESS`, `POS_INTEGRATION` | – | – | ✓ |

| Prezzo (provvisorio, IVA inclusa) | Pro | Pro+ |
|---|---|---|
| Mensile | **€19,90** | su richiesta |
| Semestrale | **€99,90** | su richiesta |
| Annuale | **€199,90** | su richiesta |

I prezzi stanno nella tabella `plans` (migration 0016) e il sito li legge da lì.

- **Beta**: fino alla data in `app_config.beta` (oggi 30/06/2027) **tutti i locali hanno Pro gratis**.
- **Prova**: ogni locale ha `app_config.restaurant_trial.days` giorni (30 all'avvio, pannello admin →
  Impostazioni) da quando diventa partner (`restaurants.partner_since`, la prima volta soltanto);
  chi entra poco prima della fine della beta ha comunque i suoi giorni.
- **Avvisi**: 7 giorni e 1 giorno prima della fine (prova, beta, mesi regalati, Stripe disdetto) il
  titolare riceve una notifica (`enqueue_plan_expiry_notices`, ogni giorno alle 08:00 UTC).
- **Pilot**: i primi partner possono ricevere Pro gratis per 6–12 mesi (`admin_grant_restaurant_plan`).
- Il **registro prenotazioni sul telefono** resta gratuito per tutti: Pro aggiunge la sincronizzazione.

### 3.2 Utenti (consumer)

| Funzione | Codice | Senza account | Gratis (account) | Plus |
|---|---|:-:|:-:|:-:|
| Cerca, stato live, distanza, indicazioni, chiama | `SEARCH_LIVE` | ✓ | ✓ | ✓ |
| Preferiti sul telefono | – | ✓ | ✓ | ✓ |
| Preferiti sincronizzati | `FAVORITES_SYNC` | – | max 5 | illimitati |
| **Avvisami quando c'è posto** | `AVAILABILITY_ALERTS` | – | – | ✓ (10 attivi) |
| Filtri avanzati (es. "per 4 persone", "senza attesa") | `ADVANCED_FILTERS` | – | – | ✓ |
| Raggio di ricerca esteso | `EXTENDED_RADIUS` | 60 km | 60 km | 100 km |
| Storico: a che ora di solito c'è posto | `AVAILABILITY_HISTORY` | – | – | ✓ |

| Prezzo (provvisorio) | Gratis | Plus |
|---|---|---|
| Mensile | €0 | **€0,99 IVA inclusa** |
| Semestrale | €0 | **€4,99 IVA inclusa** |
| Annuale | €0 | **€9,99 IVA inclusa** |

I vantaggi di Plus sono ancora da definire meglio (decisione del titolare).

Plus **non** toglie nulla ai gratuiti: è un'aggiunta per chi esce spesso.

---

## 4. Registrazione dell'utente (facoltativa)

**Quando la proponiamo:** solo nel momento in cui serve, mai all'apertura. Esempi:
tocca "Avvisami quando c'è posto" → "Per avvisarti serve un account. Accedi con Google (10 secondi)".

**Come (Step 8):**

1. Tasto **Continua con Google** (Android Credential Manager → token Google → Supabase Auth).
   Nessuna password da ricordare. Email facoltativa come alternativa (link magico).
2. Il database crea da solo il **profilo** (`profiles`) con il nome Google.
3. Schermata unica con: accettazione **Termini e Privacy** (registrata con versione e data,
   `accept_terms`), consenso **facoltativo** a comunicazioni (`marketing_opt_in`, spento di default).
4. Fine: l'utente torna esattamente dove era.

**Dati raccolti:** email, nome visualizzato, preferiti, avvisi, token notifiche. **Mai** la posizione
salvata, mai la cronologia delle ricerche.

**Cancellazione account:** voce "Elimina account" nel profilo → Edge Function che cancella l'utente
da Supabase Auth; profilo, preferiti, avvisi, token e membership si cancellano a cascata. I
pagamenti B2B restano per obblighi fiscali (vedi §8).

---

## 5. Registrazione del ristorante

### 5.1 Percorso A — il locale è già in HAPOSTO (directory)

1. Tab **Ristoratore** → **Accedi con Google**.
2. **Passo 2 di 3 — Trova il tuo locale**: cerca per nome/città → "Questo è il mio locale".
3. Inserisci un **recapito per la verifica** (telefono del locale o email aziendale) → invia.
   Il database registra la richiesta (`submit_restaurant_claim`); il locale risulta "in verifica".
4. **Passo 3 di 3 — Verifica**: un amministratore controlla (vedi 5.3) e approva
   (`admin_review_claim`). Il richiedente diventa **titolare** e il locale **partner attivo**.
5. Notifica "Sei abilitato" (Step 11) → apre la dashboard: tre tasti, fine.

### 5.2 Percorso B — il locale non c'è

Nel passo 2: **"Non trovo il mio locale"** → modulo breve: nome, tipo di cucina, indirizzo (con
posizione sulla mappa o "usa la mia posizione"), telefono, recapito per la verifica.
Il database crea il locale come "solo directory" + richiesta (`register_new_restaurant`);
dopo l'approvazione è identico al percorso A.

### 5.3 Come si verifica un ristoratore (checklist admin, 5 minuti)

1. Chiamare il **numero fisso del locale** (non quello indicato dal richiedente) e chiedere conferma.
2. In alternativa: email dal dominio del locale, oppure scheda Google Business con lo stesso recapito.
3. Nel dubbio: visita di persona durante il pilot (è anche un'occasione di formazione).
4. Annotare l'esito nella nota della revisione (`review_note`).

Mai approvare solo perché "il nome coincide": chi controlla lo stato controlla la reputazione del locale.

### 5.4 Staff (Pro)

Il titolare, dalla dashboard → **Staff** → inserisce l'email del cameriere (che deve aver fatto
accesso almeno una volta) → `add_restaurant_staff`. Lo staff pubblica lo stato ma non vede
pagamenti né dati fiscali. Rimozione con un tap (`remove_restaurant_staff`).

---

## 6. Acquisto di Pro (ristoranti) — Stripe, sul web

**Perché sul web e non nell'app:** è un servizio B2B con fattura elettronica, prezzo annuale e
commissioni più basse (Stripe ≈ 1,5% + €0,25 per carte UE, contro la quota degli store).

**Flusso (Step 14):**

```
Dashboard app → avviso "La prova finisce il …" / "Non collegato"  (solo informativo)
        │
        ▼
haposto.app/pro  (pagina web, login con lo stesso account Google)
        │  scelta mensile/semestrale/annuale + dati di fatturazione (P.IVA, SDI o PEC)
        ▼
Stripe Checkout  ──pagamento──►  Stripe
                                   │ webhook firmato
                                   ▼
                  Supabase Edge Function "stripe-webhook" (service_role)
                  1. verifica firma Stripe
                  2. billing_log_event()  → se già visto, stop (idempotenza)
                  3. billing_upsert_restaurant_subscription()
                  4. billing_record_payment()  (+ numero fattura)
                                   │
                                   ▼
            L'app legge restaurant_entitlements() → "Pro attivo fino al …"
```

Eventi Stripe da gestire: `checkout.session.completed`, `customer.subscription.created/updated/deleted`,
`invoice.paid`, `invoice.payment_failed`.

Regole:

- **Mancato rinnovo**: lo stato passa a `PAST_DUE`; Pro resta attivo **3 giorni** di tolleranza,
  poi il locale torna **"Non collegato"** senza perdere dati: con un nuovo abbonamento torna tutto.
- **Disdetta**: resta Pro fino a fine periodo pagato (`cancel_at_period_end`).
- **Fattura elettronica**: Stripe non invia allo SDI. Serve un servizio italiano (es. un software di
  fatturazione con API) chiamato dalla stessa Edge Function con i dati di `restaurant_billing_profiles`.
- **Nell'app Android non mettere pulsanti "Acquista Pro" né link al pagamento esterno**: le regole
  Google Play sui pagamenti per funzioni digitali usate nell'app sono restrittive (in UE esistono
  programmi di fatturazione alternativa). Nell'app si mostra solo il piano attivo; la vendita avviene
  via web, email o di persona. **Da verificare sulla policy vigente prima del lancio.**

---

## 7. Acquisto di Plus (utenti) — Google Play, nell'app

**Perché Google Play:** è una funzione digitale usata dentro l'app: per le regole dello store va
venduta con **Google Play Billing**.

**Flusso (Step 16):**

```
Tocco su "Avvisami quando c'è posto" (utente senza Plus)
        │
        ▼
Foglio "HAPOSTO Plus"  (vantaggi in 3 righe, prezzo, "Prova 7 giorni gratis")
        │  se non ha account → prima "Continua con Google"
        ▼
Google Play Billing  (prodotto "haposto_plus", piani base mensile e annuale)
        │  acquisto riuscito → purchaseToken
        ▼
Edge Function "play-verify" (service_role)
  1. verifica il token con Google Play Developer API
  2. billing_upsert_consumer_subscription(user, CONSUMER_PLUS, ACTIVE, GOOGLE_PLAY, token, scadenza)
  3. conferma (acknowledge) l'acquisto a Google entro 3 giorni
        │
        ▼
my_entitlements() → Plus attivo → l'avviso viene creato
```

Rinnovi, disdette e rimborsi arrivano come **Real-time developer notifications** (Pub/Sub →
stessa Edge Function). Con Google Play è Google a incassare e gestire l'IVA per l'utente finale.

Regole: prova gratuita 7 giorni (una volta per utente), disdetta sempre dal Play Store, niente
funzione Plus che blocchi il dato principale.

---

## 8. Aspetti legali e fiscali (checklist)

| Tema | Cosa serve | Dove nel sistema |
|---|---|---|
| Termini di servizio e Privacy | testi con versione; accettazione registrata | `profiles.accepted_terms_version/at`, `accept_terms()` |
| Condizioni B2B Pro | contratto/abbonamento con recesso chiaro | pagina web Pro + Stripe |
| Fatture ai ristoranti | fattura elettronica SDI | `restaurant_billing_profiles`, `payments.invoice_number` |
| Conservazione documenti contabili | 10 anni | `payments` non si cancella (un locale con pagamenti non si elimina) |
| Dati personali dei clienti nel registro prenotazioni | minimizzazione | cancellazione automatica dopo 30 giorni, solo sul telefono o solo membri del locale |
| Posizione dell'utente | mai salvata | già così (solo in memoria / parametro della ricerca) |
| Cancellazione account | entro 30 giorni dalla richiesta | cascata su profilo, preferiti, avvisi, token |
| Dati OpenStreetMap | attribuzione "© OpenStreetMap contributors" (ODbL) | `data_source = 'OSM_IMPORT'`; mostrare l'attribuzione nell'app |
| Data safety Google Play | dichiarare email, token notifiche, acquisti | scheda Play Console (Step 15) |

---

## 9. Schermate da realizzare (specifica per gli Step 8–16)

Tutte seguono la regola "a prova di errore": un'azione principale per schermata, tasti grandi,
niente testo tecnico, aiuti dietro "ⓘ".

1. **Profilo** (icona in alto a destra nella Home): Accedi con Google · I miei preferiti · HAPOSTO Plus
   · Privacy e termini · Elimina account.
2. **Foglio Plus**: titolo "Avvisami quando c'è posto", 3 vantaggi, prezzo mensile/annuale, tasto
   unico "Prova 7 giorni gratis", link "Non ora".
3. **Dashboard ristoratore → card "Il tuo piano"**: "Gratis durante la beta" / "Prova gratuita"
   con la data di fine, avviso negli ultimi 7 giorni e quando il locale è "Non collegato", con il
   contatto email (solo testo: nell'app niente inviti né link al pagamento).
4. **Dashboard → Staff** (Pro): elenco, "+ Aggiungi per email", rimuovi.
5. **Dashboard → Statistiche**: tre numeri grandi (Visite · Indicazioni · Chiamate) oggi e 7/90 giorni.
6. **Pagina pubblica web** `haposto.app/<slug>`: nome, stato grande, "aggiornato N min fa",
   Indicazioni, Chiama; QR scaricabile dalla dashboard.
7. **Pannello admin** (web o app interna): richieste da verificare con tasti Approva/Rifiuta, locali,
   regala piano.

---

## 10. Cosa è già pronto e cosa manca

| Pezzo | Stato |
|---|---|
| Tabelle, regole di accesso e funzioni per account, claim, piani, pagamenti, Plus, avvisi, statistiche, pagina pubblica | ✅ pronto (migration 0006–0011, 58 controlli automatici) |
| App: preferiti sul telefono, dashboard a prova di errore, indicatore passi | ✅ pronto |
| Login Google reale nell'app (Credential Manager + Supabase Auth) | Step 8 |
| Pubblicazione autenticata dall'app (`set_restaurant_live_status`) | Step 9 |
| Edge Function notifiche (FCM) + promemoria | Step 11 |
| Pagina pubblica web + generatore QR | Step 12 |
| Edge Function Stripe + pagina web Pro + fatturazione SDI | Step 14 |
| Google Play Billing + Edge Function di verifica | Step 16 |
