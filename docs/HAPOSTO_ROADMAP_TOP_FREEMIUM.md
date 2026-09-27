# HAPOSTO — Roadmap di riposizionamento "Top di gamma & vendibile"

**Versione documento:** v2 (revisione strategica + UX + roadmap tecnica)
**Stato progetto reale:** codice allo STEP 7 scritto e congelato (contratto V1), **build e Supabase non ancora eseguiti**
**Area pilota:** Pesaro e provincia
**Nome:** HAPOSTO *(confermato — vedi §2)*
**Tagline:** *Sai dove c'è posto. Ora.*

> Questo documento non riscrive il tuo lavoro: lo **riposiziona**. Il concept e l'architettura che hai
> costruito con ChatGPT sono solidi. Qui indico, file per file, cosa cambiare per trasformare un ottimo
> MVP tecnico in un prodotto **premium, monetizzabile e cedibile**, senza tradire il principio che è già
> il tuo vero vantaggio competitivo: **la semplicità estrema**.

---

## Indice

1. Verdetto sintetico e cosa cambia
2. Nome e logo
3. Il principio non negoziabile: la semplicità è il fossato (moat)
4. Riposizionamento freemium (i tre motori di ricavo)
5. Interfaccia & brand — interventi concreti sui file
6. Funzionalità di crescita e ritenzione
7. Roadmap step-by-step rivista (tabellare)
8. Dettaglio dei nuovi step
9. KPI e metriche di successo
10. Rischi e mitigazioni
11. "Vendibile": cosa rende l'asset cedibile
12. Quick wins immediati (questa settimana)
13. Cosa NON fare (anti-roadmap)

---

## 1. Verdetto sintetico e cosa cambia

**Cosa è già forte (da tenere):**

- Concept chiaro e validato: *"apri → vedi → vai"*, tre stati + timestamp + TTL 30 min.
- Architettura pulita: dominio/dati/UI separati, contratto V1 congelato, buoni test.
- Backend professionale: PostgreSQL + PostGIS, RPC `nearby_restaurants`, RLS/grants, `security definer`,
  history, vincoli coerenti con le regole di dominio Android.
- Strategia iperlocale (densità > copertura nazionale): corretta.
- Privacy-by-design: nessun account consumer, posizione RAM-only, niente foto/storage.

**Cosa manca per essere "top di gamma e vendibile" (da aggiungere):**

| Gap | Impatto | Dove intervenire |
|---|---|---|
| Nessuna identità visiva / logo placeholder | L'app "sembra" un prototipo | §2, §5 |
| Design system generico (Material di default, tutto MAIUSCOLO, muri di testo) | Percezione "non premium" | §5 |
| Nessuna navigazione a livello app (no menu/bottom bar) | Difficile far crescere le funzioni | §5.4 |
| Nessun dark theme | Standard atteso in un'app 2026 | §5.1 |
| Nessun onboarding | Il valore e i disclaimer si perdono | §5.6 |
| Freemium solo abbozzato, "monetizza dopo" | Non è ancora un business | §4 |
| Nessun motore di crescita virale attivato (pagina pubblica + QR è solo descritta) | Cold-start irrisolto | §4, §6, Step 12 |
| Reminder ristoratore assente (rischio #1: dato vecchio) | Il prodotto muore se il dato è stale | §6, Step 11 |
| Nessuna strumentazione KPI / crash reporting | Non puoi dimostrare trazione a un acquirente | §9, Step 15 |

**In una frase:** hai un motore ben costruito. Ora servono **carrozzeria (brand+UX)**, **benzina (crescita:
pagina pubblica/QR + reminder)** e **cruscotto (KPI + monetizzazione)**.

---

## 2. Nome e logo

### Nome: **HAPOSTO** — confermato

**Pro:** immediato in italiano ("ha posto?"), memorabile, descrive esattamente il valore, dominio/handle
probabilmente reperibili, nessuna collisione forte nota (a differenza di alternative tipo *Tavora* già citate
nell'analisi). Funziona benissimo per il lancio Pesaro/Italia.

**Unico limite:** è italiano-only. Per un'eventuale espansione estera non si traduce. **Non è un problema
ora:** il lancio è iperlocale italiano. Suggerimento: registra fin da subito il dominio e gli handle social,
e tieni `haposto.app` / `haposto.it` come pagina pubblica dei ristoranti (vedi Step 12). Se un giorno servirà
un brand internazionale, HAPOSTO può restare il brand Italia.

**Azione:** aggiorna `strings.xml` per esternalizzare tutte le stringhe (oggi contiene solo `app_name`), così
un eventuale rebrand o localizzazione futura costa poco.

### Logo (allegato)

Ti ho creato due asset vettoriali pronti:

- **`haposto_appicon.svg`** — icona app: pin su fondo *brand ink* con gradiente, dito verde ("c'è posto")
  come fulcro. Il verde è il segnale emotivo del prodotto: apri l'app *sperando di vedere verde*.
- **`haposto_logo_lockup.svg`** — logo orizzontale (pin + wordmark `haposto` + tagline) per store, pagina web,
  materiali marketing.

**Razionale di design:** il pin fonde *luogo* + *disponibilità adesso* in un solo segno ownable. Nessun
richiamo a forchette/piatti (troppo "food generico"); il pin dice "vai qui, ora".

**Note di produzione:**
- Il wordmark usa uno stack geometrico (Poppins/Montserrat). In produzione **converti il testo in tracciati**
  (outline) per indipendenza dai font.
- Per l'adaptive icon Android: usa il pin come `ic_launcher_foreground` (dentro la safe-zone 66%) e il fondo
  ink come `ic_launcher_background`, sostituendo gli attuali `ic_launcher*.xml` placeholder.
- Palette brand estesa proposta in §5.1.

---

## 3. Il principio non negoziabile: la semplicità è il fossato

Il rischio numero uno nel "renderla top di gamma" è **aggiungere schermate**. Non farlo.

**Regola d'oro:** ogni nuova funzione deve stare **ai bordi**, mai nel loop centrale.

- Loop centrale consumer: `apri → vedi lista live → tocca → indicazioni`. **Intoccabile.**
- Loop centrale ristoratore: `apri → tocca verde/arancio/rosso → fine`. **Intoccabile.**
- Tutto il resto (preferiti, alert, analytics, mappa, Plus…) vive dietro un tap, in un tab dedicato o
  in una tendina — **mai** in mezzo ai due loop sopra.

Un'app "top di gamma" non è quella con più funzioni: è quella dove le funzioni giuste sono **invisibili
finché non servono**. La tua UX minimale è un asset di marketing, non un limite.

---

## 4. Riposizionamento freemium (i tre motori di ricavo)

L'analisi attuale dice "beta gratis → monetizza dopo". Giusto come sequenza, ma va **disegnata adesso** per
non doverla ritagliare a forza più tardi. Ecco i tre motori, in ordine di importanza economica.

### Motore 1 — B2B ristoratori (ricavo principale)

Questo è il vero business. Struttura a tre livelli:

| Piano | Prezzo indicativo* | Cosa include |
|---|---|---|
| **BASIC** | €0 | Directory, stato C'È POSTO/POCHI/COMPLETO con 1 tap, TTL, **pagina pubblica + QR**, telefono pubblico opzionale |
| **PRO** | €9,90–14,90/mese o ~€99/anno | Tempo d'attesa e tavoli, **analytics** (visualizzazioni, click indicazioni/telefono, streak aggiornamenti), account **staff** multipli, **notifiche ai follower**, badge/widget per sito, nota persistente |
| **PRO+** *(futuro)* | da definire | Aggiornamento automatico (integrazione POS/gestionale), API, gruppi/catene, analytics avanzati |

*I prezzi vanno verificati al lancio insieme a fee store, Stripe e IVA (già correttamente segnalato nei tuoi
documenti). Il **BASIC gratuito è acquisition infrastructure**, non ricavo perso: più ristoranti visibili →
più utenti → più conversioni a PRO.

**Chiave di vendita PRO:** non "un'altra app", ma *"meno telefonate durante il servizio + più coperti nei
tavoli vuoti, dimostrati con i numeri"*. Gli analytics PRO **sono** l'argomento di vendita: mostrano il ROI.

### Motore 2 — Consumer Plus (secondario, non barriera)

Il dato principale resta **gratis** finché la rete non è forte (altrimenti la persona telefona e basta).
Plus è un "power user upgrade", non un paywall.

| Piano | Prezzo indicativo | Cosa include |
|---|---|---|
| **FREE** | €0 | Ricerca, stato live, distanza, scheda, indicazioni, chiamata |
| **PLUS** | €0,99–1,99/mese | **"Avvisami quando torna C'È POSTO"**, preferiti + alert preferiti, filtri avanzati, raggio maggiore, storico disponibilità, esperienza senza eventuali promo |

### Motore 3 — Distribuzione che si autofinanzia (riduce la CAC a ~0)

Non è un piano a pagamento, è il **canale** che rende gli altri due sostenibili:

- **Pagina pubblica per ogni ristorante** (`haposto.app/osteria-x`): mostra stato live + "aggiornato N min fa",
  usabile **senza installare l'app**. Il ristorante la mette su Instagram, Google Business, bio, sito.
- **QR "Prima di chiamare"**: sticker all'ingresso/vetrina. Il ristorante diventa il tuo canale di acquisizione.

Questo è ciò che rende HAPOSTO **vendibile**: un motore di crescita organico, locale, a costo marginale zero.

---

## 5. Interfaccia & brand — interventi concreti sui file

Qui sta la parte "migliora interfaccia, menù, tutto". Ogni intervento indica il file reale toccato.

### 5.1 Design system e dark theme — `Color.kt`, `Theme.kt`, `Type.kt`

**Problema oggi:** solo `lightColorScheme`, palette buona ma incompleta (mancano `secondary`, `error`,
`surfaceVariant` espliciti, container coerenti), nessun tema scuro Compose.

**Interventi:**

1. **Estendi la palette** in `Color.kt` con: brand green vivido per accenti/logo (`#12A867`/`#3BE39A`),
   set completo error/secondary/tertiary, tonalità surface per elevazione.
2. **Aggiungi `darkColorScheme`** in `Theme.kt` e passa lo schema in base a `isSystemInDarkTheme()`.
   (Il `values-night/themes.xml` esiste già lato sistema: allinea Compose.)
3. **Valuta il dynamic color** (Material You) su Android 12+ come opzione, con fallback al brand.
4. **Tipografia** (`Type.kt`): definisci una scala coerente e un font brand (es. Poppins/Inter via
   `androidx.compose ... fontResource`). Oggi la gerarchia è affidata a `FontWeight` sparsi.
5. **Forme:** definisci `Shapes` (angoli 12–20dp) per un look morbido/premium coerente su card e bottoni.

### 5.2 La card è il prodotto — `RestaurantCard.kt`, `AvailabilityBadge.kt`

La card è ciò che l'utente guarda per 1 secondo. Deve **gridare lo stato** e sussurrare il resto.

**Oggi:** nome + "categoria · distanza" + badge testuale piccolo + "aggiornato X" in coda. Tutto grigio,
molto testo, il badge non domina.

**Ridisegno proposto:**

- **Lo stato diventa l'elemento dominante:** pill colorata grande a sinistra o barra colore laterale;
  il pallino `●` diventa un vero indicatore (colore pieno, non testo).
- **Freschezza visiva:** accanto a "aggiornato 4 min fa" aggiungi un **anello/barra sottile che consuma il
  TTL** (30 min → 0). Comunica fiducia a colpo d'occhio senza leggere.
- **Badge LIVE** per i partner attivi (distingue partner da directory-only, come da analisi §4 Parte 2).
- **Gerarchia:** Nome (bold) → stato (pill grande) → "aggiornato + valido ancora" → distanza/categoria (secondari).
- **Tocco:** mantieni `contentDescription` (accessibilità già buona) ma alleggerisci il testo visibile.
- **`AvailabilityBadge`:** aggiungi varianti dimensione (`compact` per la card, `hero` per il dettaglio) e
  smetti di usare il carattere `●` come Text: usa una `Canvas`/`Box` colorata per nitidezza.

### 5.3 Home più leggera — `HomeScreen.kt`, `HomeViewModel.kt`

**Oggi:** header + pannello posizione ingombrante + chip filtri + lista + **due blocchi di disclaimer testuali**
in coda e dentro il pannello. Molto denso.

**Interventi:**

1. **Sintesi in cima:** una riga viva tipo *"4 locali con posto vicino a te · 12 in directory"*
   (empty state "in crescita" già suggerito nell'analisi §68 Parte 2). Trasforma un elenco in un segnale.
2. **Toggle rapido "Solo C'È POSTO"** ben visibile (è il filtro che l'utente vuole il 90% delle volte).
3. **Pannello posizione compatto:** portalo in un **bottom sheet** o in un chip in alto ("📍 Pesaro centro ▾")
   che apre le opzioni. Oggi occupa mezza schermata sopra i risultati.
4. **Disclaimer una volta sola:** sposta "dati dimostrativi / non è una prenotazione" nell'onboarding e in una
   voce "Info" del menu, togliendoli dal flusso principale. In Home basta un piccolo "ⓘ".
5. **Skeleton loading** al posto del testo "Caricamento…": più premium.
6. **Pull-to-refresh** esplicito (in attesa del Realtime allo Step 10).

### 5.4 Navigazione a livello app — nuovo, coordina `HaPostoApp.kt`, `AppDestination.kt`

**Oggi:** non c'è un menu; si entra nell'area ristoratore da un link. Per far crescere le funzioni serve una
struttura, **minima**:

- **Bottom navigation a 2–3 voci** (non di più all'inizio):
  - **Vicino** (la Home lista live) — default
  - **Preferiti** (Plus; per i free mostra un teaser elegante, non un muro)
  - **Ristoratore** (entry area gestore / "Gestisci un ristorante")
- Il **profilo/impostazioni** (info, tema, privacy, upgrade Plus) sta in un'icona in alto a destra, non in un tab.
- **NON** aggiungere un tab "Mappa" ora: la mappa arriva come *toggle lista/mappa dentro "Vicino"* (Step 18),
  non come sezione separata.

Questo è il "menù migliorato" richiesto: dà spazio alle funzioni freemium **senza** appesantire i due loop core.

### 5.5 Schermata dettaglio — `RestaurantDetailScreen.kt`

- **Stato "hero"** in cima (badge grande + "aggiornato" + anello TTL), poi indirizzo, distanza, e i due bottoni
  d'azione primari: **INDICAZIONI** e **CHIAMA** (se `phonePublic`).
- Aggiungi **★ Preferito** (gancio per Plus/alert) e **Condividi** (condivide il link pubblico → crescita).
- Per i non-partner: stato neutro "Disponibilità non collegata" + CTA prudente *"Gestisci questo ristorante?"*
  (come da analisi §69 Parte 2).

### 5.6 Onboarding — nuovo (3 schermate)

Prima apertura, 3 tappe che poi non si rivedono:

1. *"Scopri dove c'è posto adesso"* (valore).
2. *"Gli stati sono dichiarati dai locali e scadono in 30 minuti"* (fiducia + disclaimer "non è prenotazione", **una volta sola**).
3. *"Attiva la posizione o scegli una zona"* (chiede il permesso nel contesto giusto → tasso di consenso più alto).

### 5.7 Area ristoratore — `RestaurantManagerScreen.kt`

La UX del gestore è già ottima (bottoni enormi, un tap, dettagli opzionali collassabili). Migliorie:

- **Riduci il testo tecnico** ("overlay RAM-only", "Step 7…"): sposta le note-dev fuori dalla UI di produzione
  (oggi sono in schermata; vanno dietro un "debug info" o rimosse allo Step 9).
- **Feedback tattile/animato** al tap dello stato (micro-animazione + haptic) → sensazione "premium" e conferma.
- **Countdown TTL** già presente: rendilo un anello visivo coerente con la card consumer.
- **Reminder integrato** (Step 11): banner "Sono passati 25 min: confermi C'È POSTO?" con azioni rapide.

### 5.8 Copy e stringhe — `strings.xml`

**Oggi:** contiene solo `app_name`; tutte le altre stringhe sono hardcoded nei Composable.
**Interventi:** esternalizza **tutte** le stringhe in `strings.xml` (indispensabile per localizzazione, A/B del
copy e futuro rebrand). Rivedi il tono: caldo, brevissimo, mai MAIUSCOLO sui bottoni (usa Title Case; il
MAIUSCOLO diffuso oggi abbassa la percezione di qualità).

---

## 6. Funzionalità di crescita e ritenzione

In ordine di impatto sul successo del prodotto:

1. **Reminder ristoratore (push/in-app)** — *attacca il rischio #1*: il dato vecchio. Notifica "Come siete
   messi?" a inizio servizio e "Confermi ancora?" dopo ~25 min, con azioni rapide dalla notifica. → **Step 11**.
2. **Pagina pubblica + QR** — motore di acquisizione a costo ~0. → **Step 12**.
3. **Preferiti + "Avvisami quando torna C'È POSTO"** — killer feature consumer Plus e ritenzione. → **Step 16**.
4. **Analytics ristoratore** — l'argomento di vendita del PRO (ROI dimostrato). → **Step 17**.
5. **Condivisione** dello stato live (link pubblico) — loop virale leggero. → con Step 12.
6. **Notifiche ai follower** (il locale annuncia "abbiamo appena liberato tavoli") — PRO, potentissima ma da
   dosare per non spammare. → dopo pilot.
7. **Smart TTL adattivo** (sabato sera 15 min, lunedì 45 min) — qualità del dato v2. → post-pilot.

---

## 7. Roadmap step-by-step rivista (tabellare)

Legenda priorità: 🔴 critica · 🟠 alta · 🟡 media · 🟢 opzionale/futura

| Step | Titolo | Obiettivo | Priorità | Dipende da |
|---|---|---|---|---|
| **7 (completa)** | Build + Supabase reale | Eseguire ciò che è già scritto: creare progetto Supabase, girare le migration, wrapper Gradle, primo build/test su device | 🔴 | — |
| **7.5** | Brand & UX uplift | Logo/icona, design system, dark theme, card ridisegnata, Home alleggerita, bottom nav, onboarding, copy | 🔴 | 7 |
| **8** | Auth + claim reale | Supabase Auth (Google OAuth/PKCE), sessione, sostituire fake access repo, claim reale, approvazione, membership, test RLS | 🔴 | 7 |
| **9** | Scritture LIVE backend | `set_restaurant_live_status` RPC autenticato, history, TTL server, rimuovere overlay RAM-only e poteri demo | 🔴 | 8 |
| **10** | Realtime | Publication, `0005_realtime_future.sql`, subscription client, lista che si aggiorna sola, reconnect | 🟠 | 9 |
| **11** | Reminder / FCM *(anticipato)* | Notifiche "come siete messi?"/"confermi?" con azioni rapide; deep link dashboard. **Anticipato perché difende il dato** | 🟠 | 9 |
| **12** | Pagina pubblica + QR | Web statica/edge che legge la RPC; slug per ristorante; generatore QR/sticker; badge/widget | 🟠 | 9 |
| **13** | Pilot Pesaro | 20–40 partner, onboarding, misurare active/stale rate, feedback | 🔴 | 9–12 |
| **14** | Monetizzazione | Definire prezzi/tiers, billing B2B (Stripe web) per PRO, gate PRO nell'app, fatturazione/IVA | 🟠 | 13 |
| **15** | Store readiness + KPI | Play listing/ASO, privacy policy, Data Safety, crash reporting, analytics privacy-friendly, QA multi-device | 🔴 | 7.5 |
| **16** | Consumer Plus | Preferiti, alert "torna C'È POSTO", filtri avanzati, raggio, storico; billing IAP | 🟡 | 11, 14 |
| **17** | Analytics ristoratore (PRO) | Viste, click indicazioni/telefono, streak, coperti stimati; dashboard PRO | 🟡 | 9, 13 |
| **18** | Vista mappa (opzionale) | Toggle lista/mappa dentro "Vicino" con MapLibre + OSM (rispettando licenze/tile policy) | 🟢 | 13 |
| **19** | iOS | Porting stesso backend/logica | 🟢 | stabilità Android |

> **Modifica chiave alla tua roadmap:** ho **inserito lo Step 7.5 (brand/UX)** e **anticipato i reminder
> (Step 11)** rispetto al "solo se il pilot lo richiede". Motivo: brand e freschezza del dato sono ciò che
> distingue un prototipo da un prodotto **premium e credibile** davanti a ristoratori e a un eventuale acquirente.
> Ho inoltre reso lo **Store readiness + KPI (Step 15)** un binario che parte presto e corre in parallelo.

---

## 8. Dettaglio dei nuovi step

### Step 7 (completamento) — quello che ti manca ORA

Il codice c'è; manca l'esecuzione fisica (che l'ambiente di generazione non poteva fare):

1. Crea progetto Supabase **DEV**; esegui in ordine `0001`→`0004` (**non** `0005`).
2. Carica seed `900_example_fictional_data.sql` e lo smoke `step7_manual_smoke.sql`.
3. Copia `local.properties.example` → `local.properties` con `SUPABASE_URL` + `sb_publishable_…`
   (**mai** `service_role`/secret nell'APK — già correttamente documentato).
4. Genera il wrapper Gradle mancante: `gradle wrapper --gradle-version 9.5.0`.
5. Gradle Sync → Make Project → unit test → run su device/emulatore → smoke Supabase → instrumentation test.
6. Verifica: Home mostra "SUPABASE DEV" e legge la directory reale; con config assente resta il fake; con
   config errata mostra errore (niente fallback silenzioso). Segui `STEP_7_BUILD_AND_TEST.md`.

### Step 7.5 — Brand & UX uplift

Tutti gli interventi §5. Ordine consigliato: design system+dark theme → card → Home+bottom nav → onboarding →
icona/logo → copy in `strings.xml`. Fallo **prima del pilot**: i ristoratori giudicano in 5 secondi.

### Step 8 — Auth reale

Segui la tua roadmap: Google OAuth/PKCE via Supabase Auth (niente Firebase Auth, come deciso). Sostituisci
`FakeRestaurantAccessRepository`, **rimuovi** `approvePendingClaimForDemo()`/`resetDemo()` dal client di
produzione (o isolali in tooling debug), abilita RLS reale e testala.

### Step 9 — Scritture LIVE

Collega la dashboard alla RPC `set_restaurant_live_status` (già scritta e sicura: `is_restaurant_member`
+ partner attivo + vincoli). Elimina l'overlay RAM-only dello Step 7. Aggiorna `V1_CONTRACT_FREEZE.md` §8.

### Step 11 — Reminder / FCM (anticipato)

FCM (niente Firebase Auth/DB). Trigger: inizio fascia servizio + a ~25 min dall'ultimo update. Azioni rapide
in notifica (C'È POSTO / POCHI / COMPLETO) con deep link. È **prodotto**, non nice-to-have: senza, il dato
invecchia e l'app perde fiducia.

### Step 12 — Pagina pubblica + QR

Sito statico o edge function che chiama la stessa RPC in sola lettura. Uno **slug** per ristorante
(`haposto.app/osteria-x`). Generatore di **QR + sticker "Prima di chiamare"** e badge/widget per i siti dei
locali. Questo è il tuo canale di crescita organica e un forte argomento in una due diligence.

### Step 14 — Monetizzazione

Definisci i prezzi durante/dopo il pilot (dati alla mano). B2B PRO via **Stripe web** (evita la fee store sul
B2B); annuale ~€99 per ammortizzare il costo fisso Stripe e ridurre churn. Consumer Plus via IAP store.
Verifica IVA, fee store e policy **al momento del lancio** (già segnalato nei tuoi documenti).

### Step 15 — Store readiness + KPI (binario parallelo, parte presto)

- Play Console ($25 una tantum), listing + **ASO** (keyword "posto ristorante Pesaro", "tavolo last minute"…).
- **Privacy policy** + modulo **Data Safety** + gestione permessi posizione conforme.
- **Crash reporting** (es. Sentry free tier) e **analytics privacy-friendly**: query, viste scheda, click
  indicazioni/telefono, update per servizio, % stati freschi (i KPI di §9).
- QA su matrice multi-device (già preparata nei tuoi doc; qui va **eseguita**).

---

## 9. KPI e metriche di successo

Più dei download, monitora la **salute del dato** e il **loop a due lati**:

**Qualità del dato (il KPI esistenziale):**
- % di partner con stato **valido** durante la cena (target pilot: >60%).
- Tempo medio dall'ultimo aggiornamento nelle fasce di punta.
- Aggiornamenti per servizio per ristorante.

**Ristoratori:**
- Attivi giornalieri / settimanali; retention a 7 e 30 giorni.
- Quanti aggiornano **senza** essere sollecitati (segnale forte di product-market fit locale).
- Conversione BASIC → PRO (dopo Step 14).

**Utenti:**
- % sessioni in cui l'utente trova ≥1 locale live vicino.
- Click "Indicazioni"/"Chiama" per sessione.
- Ritorno (D1/D7).

**Business (per la vendibilità):**
- MRR e ARPU ristorante; CAC (idealmente ~0 grazie a QR/pagina pubblica); churn.
- Densità per zona (locali live entro X km all'ora di cena) — è la metrica che *crea* valore.

---

## 10. Rischi e mitigazioni

| Rischio | Gravità | Mitigazione |
|---|---|---|
| Il ristoratore non aggiorna → dato stale | Esistenziale | Reminder (Step 11), 1 tap, TTL onesto, stato STALE trasparente |
| Cold-start (pochi locali → pochi utenti) | Alta | Iperlocale (densità), BASIC gratis, QR/pagina pubblica, pilot 20–40 partner |
| Percezione "prototipo" | Alta | Step 7.5 brand/UX prima del pilot |
| Provenienza dati directory (non-partner) | Legale | Directory curata manualmente o OSM con attribuzione; **mai** copiare foto/recensioni/menu (già nei tuoi doc) |
| Fee store / IVA erodono micro-prezzi | Media | B2B via Stripe web, annuale, prezzi verificati al lancio |
| Copiabilità dell'idea | Media | Il fossato è la **densità locale + fiducia nel dato**, non il codice |
| Fatica da notifiche | Media | Reminder dosati, opt-in, frequenza intelligente |

---

## 11. "Vendibile": cosa rende l'asset cedibile

Un acquirente (o un investitore) compra tre cose, in quest'ordine:

1. **Trazione dimostrabile** → per questo servono KPI e crash-free rate (Step 15) e una densità reale a Pesaro.
2. **Un motore di crescita ripetibile** → la coppia *pagina pubblica + QR* (Step 12) è replicabile città per città.
3. **Un asset pulito** → codice ordinato (già ✔), contratto congelato (✔), backend sicuro (✔), **documentazione**
   (✔, ottima). Aggiungi: brand registrabile, dominio/handle, privacy policy, e separazione netta demo/produzione
   (rimozione poteri fake allo Step 8/9).

In pratica: **densità a Pesaro + numeri + un canale duplicabile = storia vendibile.** Le funzioni fighe da sole
non lo sono; la ripetibilità sì.

---

## 12. Quick wins immediati (questa settimana)

Cose ad alto impatto e basso sforzo, da fare subito:

1. **Sblocca lo Step 7**: crea Supabase DEV, gira `0001`–`0004`, genera il wrapper, primo build su device. *(Sei fermo qui.)*
2. **Metti l'icona/logo** che ti ho fornito al posto dei placeholder → l'app smette di "sembrare" un test.
3. **Esternalizza le stringhe** in `strings.xml` e **togli il MAIUSCOLO** dai bottoni.
4. **Aggiungi il dark theme** (poche righe in `Theme.kt`).
5. **Alleggerisci la Home**: sposta i disclaimer fuori dal flusso, aggiungi la riga di sintesi "N locali con posto".
6. Registra **dominio + handle** `haposto`.

---

## 13. Cosa NON fare (anti-roadmap)

Per non distruggere il concept:

- ❌ Recensioni, foto utente, feed social, chat, delivery, loyalty, pagamento del conto.
- ❌ Prenotazione completa (diventa un altro prodotto: quello è TheFork/OpenTable).
- ❌ Ranking pay-to-win (i partner non "comprano" la vetta dei risultati).
- ❌ Account obbligatorio per il consumer.
- ❌ Posizione in background.
- ❌ Mappa embedded nell'MVP (arriva come toggle, Step 18).
- ❌ Aggiungere un tab per ogni idea: il menu resta a 2–3 voci finché i numeri non giustificano di più.

---

### Chiusura

Hai già la parte difficile: un motore semplice, ben architettato e documentato. Le tre mosse che spostano
davvero l'ago sono, in ordine:

1. **Farlo girare** (Step 7 completo) e **vestirlo** (Step 7.5 brand/UX).
2. **Difendere il dato** (Step 11 reminder) e **farlo crescere da solo** (Step 12 pagina pubblica + QR).
3. **Dimostrarlo con i numeri** (Step 15 KPI) per renderlo **monetizzabile e vendibile**.

Tutto il resto è subordinato al loop: *l'utente apre alle 20:42, vede abbastanza verde aggiornato alle 20:38,
e pensa "perfetto, non devo telefonare a nessuno".* Quando ottieni quel comportamento a Pesaro, hai un prodotto —
e una storia che si vende.
