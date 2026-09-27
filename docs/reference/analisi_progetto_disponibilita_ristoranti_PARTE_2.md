# Analisi progetto disponibilità ristoranti — Parte 2
## Prodotto, stack gratuito, UX, modello freemium e naming
**Working title consigliato:** HAPOSTO  
**Area di lancio:** Pesaro e provincia  
**Data:** 24 agosto 2026

---

# 1. Premessa: cosa fissiamo rispetto alla Parte 1

Questa Parte 2 continua il documento `analisi_progetto_disponibilita_ristoranti.md`.

Manteniamo i principi già definiti:

- il prodotto non deve diventare un clone di TheFork;
- il valore principale è sapere **se un ristorante può accoglierti adesso**;
- il ristorante deve aggiornare lo stato con uno o pochissimi tocchi;
- ogni stato deve avere timestamp e scadenza;
- la densità locale conta più della copertura nazionale;
- niente recensioni, chat, delivery o social;
- il dato deve essere affidabile e semplice da interpretare.

La nuova direzione è ancora più minimale:

- lancio a **Pesaro e provincia**;
- database **Supabase/PostgreSQL**;
- Android nativo;
- predisposizione iOS;
- nessuna foto;
- niente loghi dei ristoranti nella V1;
- niente menù;
- niente recensioni;
- niente chat;
- niente prenotazioni;
- niente pagamento nell'MVP;
- indirizzo, distanza e navigazione;
- telefono solo se il ristorante sceglie di mostrarlo;
- directory che distingue chiaramente ristoranti collegati al servizio e ristoranti non collegati;
- tutto il possibile a costo software iniziale pari a zero.

Questa semplificazione, secondo me, migliora il progetto.

---

# 2. Definizione aggiornata del prodotto

Il prodotto può essere descritto in una frase:

> **Una directory locale live che mostra quali ristoranti dichiarano di avere disponibilità in questo momento.**

Non garantisce una prenotazione.

Non gestisce il tavolo.

Non raccoglie recensioni.

Non vende il ristorante.

Non decide se il ristorante è buono.

Dice soltanto:

> **“Questo locale è collegato e 4 minuti fa ha dichiarato che c'è posto.”**

È una proposizione estremamente precisa.

---

# 3. Territorio: Pesaro e provincia è una scelta migliore dell'Italia

Partire da Pesaro e provincia permette di costruire densità.

Non cercherei di coprire immediatamente ogni comune.

La progressione che consiglierei è:

## Fase A — Pesaro città

Obiettivo:

- avere un numero consistente di ristoranti nel centro e nelle zone con maggiore concentrazione di locali;
- rendere utile la schermata già con pochi chilometri di raggio;
- poter parlare personalmente con i ristoratori;
- raccogliere feedback rapidamente.

## Fase B — Pesaro + Fano

Quando Pesaro funziona, estendere il modello verso Fano.

## Fase C — costa e poli turistici

Gradara, Gabicce e altre località interessanti per flusso turistico e stagionale.

## Fase D — Urbino e resto della provincia

A quel punto l'app diventa veramente provinciale.

L'obiettivo non deve essere:

> “Abbiamo 500 ristoranti nel database.”

Deve essere:

> “Se apro l'app a Pesaro alle 20:30, ci sono abbastanza ristoranti collegati da rendere la ricerca utile.”

---

# 4. Ristoranti aderenti e non aderenti

Questa è una buona evoluzione del concept.

La lista può contenere due categorie.

## A. Ristorante collegato

Il ristorante ha aderito ed è stato verificato.

Mostriamo:

- nome;
- indirizzo;
- distanza;
- eventuale telefono pubblico;
- stato live;
- timestamp;
- eventuali dettagli live;
- badge che certifica che lo stato arriva dal locale.

Esempio:

```text
Osteria Example
0,8 km · Via Example 12

🟢 C'È POSTO
Aggiornato 4 min fa

LIVE
```

## B. Ristorante non collegato

Il locale può essere presente come voce di directory, ma non pubblichiamo alcuna disponibilità.

Esempio:

```text
Trattoria Example
1,1 km · Via Example 34

⚪ DISPONIBILITÀ NON COLLEGATA
```

Evito la scritta molto netta:

> “NON ADERISCE”

perché può sembrare che il ristorante abbia rifiutato il servizio.

Preferisco:

- `Non collegato`
- `Disponibilità non collegata`
- `Stato non disponibile`

È più neutro.

---

# 5. Attenzione alla provenienza dei dati dei non aderenti

Non dobbiamo riempire il database copiando Google Maps.

Nome, indirizzo e altre informazioni fattuali possono sembrare banali, ma piattaforme e database possono avere proprie condizioni d'uso e diritti sui database.

Per l'MVP farei una di queste cose:

## Opzione 1 — database manuale

Inseriamo manualmente una piccola directory locale partendo da fonti ufficiali e controllando i dati.

È fattibile per Pesaro.

## Opzione 2 — ristoranti inseriti solo quando verificati

È la soluzione legalmente e operativamente più semplice, ma la lista inizialmente sembrerebbe vuota.

## Opzione 3 — dati OpenStreetMap

È possibile utilizzare dati OSM rispettandone licenza e attribuzione.

Non equivale però a “senza condizioni”: bisogna rispettare la licenza e le policy.

### Raccomandazione MVP

Userei una **directory minima curata manualmente**, mantenendo soltanto:

- nome;
- indirizzo;
- coordinate;
- città;
- categoria molto generale se necessaria.

Mai:

- foto prese da Google;
- recensioni;
- descrizioni copiate;
- menù;
- loghi copiati;
- rating di altre piattaforme.

Il telefono lo mostriamo soltanto quando il ristorante collegato sceglie espressamente di renderlo visibile.

---

# 6. Autenticazione: non userei Firebase Auth

Se il database principale è Supabase, dividere:

```text
Database = Supabase
Auth = Firebase
```

non porta un vantaggio sufficiente per questo progetto.

Aggiunge invece:

- due console;
- due sistemi utenti;
- mapping UID;
- gestione token;
- policy RLS più complesse;
- più dipendenze;
- più punti di errore.

## Soluzione consigliata

### Utente normale

**Nessun account nell'MVP.**

Può:

- aprire;
- cercare;
- usare posizione;
- vedere stato;
- aprire navigazione;
- chiamare se il numero è pubblico.

Fine.

Questo è importantissimo.

Non dobbiamo mettere una schermata:

> “Registrati per vedere chi ha posto.”

Sarebbe frizione inutile.

### Ristoratore

**Supabase Auth.**

Per la primissima versione userei:

- Sign in with Google;

oppure, solo successivamente:

- email/password.

Supabase supporta nativamente Google OAuth su Android e iOS.

## Perché Google login è interessante per la beta

Nel 2026 il server email incorporato di Supabase è pensato soprattutto per sviluppo e ha forti limitazioni; Supabase raccomanda SMTP personalizzato per produzione.

Se vogliamo rimanere davvero a costo zero e senza aggiungere un servizio email:

> **Google Sign-In tramite Supabase Auth è la soluzione più pulita.**

L'identità Google non significa che il ristorante sia verificato.

Il flusso è:

```text
Login Google
↓
Richiesta gestione ristorante
↓
Controllo amministratore
↓
Account collegato al locale
```

Questa distinzione è fondamentale.

---

# 7. Verifica ristorante

Non basta iscriversi.

Dobbiamo sapere che chi preme FULL è autorizzato.

## MVP

1. Il ristoratore accede con Google.
2. Tocca `Gestisci un ristorante`.
3. Cerca il proprio ristorante.
4. Invia richiesta.
5. Inserisce un recapito per la verifica.
6. Noi verifichiamo manualmente.
7. L'account diventa `OWNER`.
8. Da quel momento può aggiornare lo stato.

Per 20–50 ristoranti iniziali la verifica manuale è perfetta.

Non serve costruire un sistema automatico complicato.

---

# 8. Ruoli

Bastano quattro ruoli:

```text
PUBLIC
RESTAURANT_OWNER
RESTAURANT_STAFF
ADMIN
```

## PUBLIC

Non autenticato.

Solo lettura dei dati pubblici.

## RESTAURANT_OWNER

Può:

- aggiornare stato;
- cambiare telefono pubblico;
- modificare informazioni consentite;
- aggiungere staff in futuro.

## RESTAURANT_STAFF

Può principalmente aggiornare lo stato.

## ADMIN

Può:

- creare/modificare ristoranti;
- verificare richieste;
- sospendere un account;
- correggere dati;
- vedere log tecnici.

Nella V1 potremmo addirittura non implementare ancora `STAFF`.

Owner + Admin sono sufficienti per partire.

---

# 9. Stack tecnologico consigliato

## Android

- Kotlin
- Jetpack Compose
- Material 3
- Coroutines
- Flow
- ViewModel
- Navigation Compose
- repository layer

Jetpack Compose continua a essere il toolkit moderno raccomandato da Android per UI native.

## Backend

### Supabase

Utilizziamo:

- PostgreSQL;
- Auth;
- Row Level Security;
- Realtime dove serve;
- PostGIS;
- eventuali database functions.

Non utilizziamo Storage nell'MVP perché non abbiamo foto.

Questo è un vantaggio enorme:

> niente immagini = meno banda, meno moderazione, meno storage, meno copyright.

## Push notification

**Non la metterei necessariamente nella prima build.**

Quando servirà:

- Firebase Cloud Messaging.

FCM è disponibile senza costo.

Firebase può quindi entrare eventualmente come servizio push, **non come sistema di autenticazione**.

---

# 10. Supabase Free: cosa abbiamo davvero

Al 24 agosto 2026, il piano Free di Supabase include tra le altre cose:

- PostgreSQL;
- API;
- 500 MB database per progetto;
- 50.000 MAU Auth;
- social OAuth;
- 5 GB egress;
- 1 GB storage.

Per la nostra app, senza foto, 500 MB di database sono moltissimi per un MVP locale.

Esempio:

- 1.000 ristoranti;
- qualche decina di campi;
- cronologia degli status;

sono estremamente più leggeri di una piattaforma che gestisce immagini e video.

## Limite importante

I progetti Free possono essere messi in pausa dopo un periodo di bassa attività.

Per una beta attiva non dovrebbe essere un problema frequente, ma dobbiamo sapere che il piano Free non ha le garanzie di un servizio a pagamento.

Quando l'app produrrà ricavi, pagare l'infrastruttura sarà normale.

L'obiettivo è:

> **zero costo mentre validiamo**, non promettere che l'infrastruttura resterà gratuita per sempre.

---

# 11. Posizione e distanza

La posizione dell'utente deve servire a una cosa sola:

> ordinare i locali vicini.

Non dobbiamo tracciare l'utente.

## Flusso

```text
Apri app
↓
“Usa la mia posizione”
↓
Android fornisce lat/lon
↓
Query Supabase
↓
PostGIS calcola distanza
↓
Risultati ordinati
```

Non è necessario salvare la posizione dell'utente nel database.

---

# 12. PostGIS

Supabase supporta PostGIS.

È perfetto per noi.

Ogni ristorante ha:

```text
location = POINT(longitudine latitudine)
```

Possiamo chiedere:

> Dammi i ristoranti entro 10 km, ordinati dal più vicino.

Il server restituisce direttamente:

```text
Osteria A — 0,4 km
Pizzeria B — 0,9 km
Sushi C — 1,6 km
```

Questo è molto più pulito che scaricare tutti i ristoranti sul telefono e calcolare tutto localmente.

---

# 13. La mappa: non la metterei nella V1

A prima vista sembra strano.

In realtà è coerente con il prodotto.

L'utente non ha bisogno di esplorare una mappa complessa.

Ha bisogno di:

> “Dove posso mangiare?”

La lista è più efficiente.

## Scheda ristorante

```text
Via Example 18, Pesaro

1,2 km da te

[ APRI SULLA MAPPA ]
```

Il pulsante passa la destinazione all'app di navigazione installata sul dispositivo.

### Vantaggi

- nessun costo mappe;
- nessuna API key;
- meno codice;
- meno banda;
- niente problemi di tile provider;
- app più leggera;
- UX più focalizzata.

---

# 14. Se un giorno vogliamo una mappa interna

Userei **MapLibre Native**.

È open source e supporta:

- Android;
- iOS;
- Kotlin/Java;
- Swift/Objective-C.

Ma c'è una distinzione importante:

> MapLibre è gratuito. I tile cartografici non sono automaticamente “gratuiti senza limiti”.

OpenStreetMap permette l'uso dei dati, ma i server tile pubblici hanno policy e capacità limitate e possono bloccare utilizzi problematici.

Quindi:

### MVP

nessuna mappa incorporata.

### Futuro

MapLibre + provider adeguato o infrastruttura mappe scelta quando avremo ricavi.

---

# 15. Funzioni utente V1

Farei soltanto queste.

## 1. Trova vicino a me

Richiede posizione.

## 2. Cerca località

Se non vuole fornire posizione:

```text
Pesaro
Fano
Urbino
...
```

## 3. Cerca nome ristorante

Search bar.

## 4. Lista

Ordinabile principalmente per distanza.

## 5. Filtro

Massimo pochi filtri:

- Tutti
- C'è posto
- Pochi posti
- Live

## 6. Scheda ristorante

- nome;
- indirizzo;
- distanza;
- stato;
- aggiornamento;
- telefono, se autorizzato;
- apri sulla mappa.

Nient'altro.

---

# 16. Cosa NON metterei nella V1 utente

- account consumer;
- preferiti;
- recensioni;
- stelle;
- fotografie;
- descrizioni lunghe;
- menù;
- prezzi;
- prenotazioni;
- chat;
- coupon;
- messaggi;
- feed;
- profilo pubblico;
- follower;
- AI;
- condivisione social;
- commenti;
- rating;
- “ristoranti consigliati da noi”.

Sono tutte distrazioni.

---

# 17. Home utente proposta

Una schermata molto pulita.

```text
HAPOSTO

Pesaro                         ⌖

Dove vuoi mangiare?
[ Cerca ristorante...       ]

[ Tutti ] [ C'è posto ] [ Pochi posti ] [ Live ]

Vicino a te
──────────────────────────────

Osteria Example
Italiana · 0,6 km

🟢 C'È POSTO
Aggiornato 3 min fa
──────────────────────────────

Ristorante Example
1,1 km

🟠 POCHI POSTI
Aggiornato 8 min fa
──────────────────────────────

Trattoria Example
1,4 km

⚪ NON COLLEGATO
──────────────────────────────
```

La disponibilità deve occupare molto spazio visivo.

---

# 18. Le card non devono avere immagini

È un vantaggio estetico.

Le app di ristoranti sono spesso piene di:

- foto;
- gradienti;
- stelle;
- promozioni;
- banner;
- badge;
- prezzi;
- sponsored.

La nostra può sembrare quasi un'app di mobilità.

Informazione pulita.

Una card può avere:

```text
NOME
categoria · distanza

[ STATO ]
timestamp
```

Il design diventa riconoscibile proprio perché non cerca di sembrare Instagram.

---

# 19. Stato utente: terminologia

Nella UI italiana preferirei:

## 🟢 C'È POSTO

piuttosto che:

`FREE`

È immediato.

## 🟠 POCHI POSTI

## 🔴 COMPLETO

## ⚪ DA AGGIORNARE

per un partner con stato scaduto.

## ⚪ NON COLLEGATO

per un ristorante presente in directory ma non aderente al sistema live.

Sono due cose diverse:

```text
DA AGGIORNARE
= partner, ma dato vecchio

NON COLLEGATO
= non pubblica dati live
```

La distinzione deve essere chiarissima.

---

# 20. Il timestamp

Sempre visibile.

Esempio corretto:

```text
🟢 C'È POSTO
Aggiornato 6 min fa
```

Non:

```text
🟢 C'È POSTO
```

Il timestamp non è un dettaglio.

È parte dello stato.

---

# 21. Scadenza stato

Fisserei inizialmente:

**30 minuti.**

Quando un ristorante preme:

```text
C'È POSTO
```

salviamo:

```text
status = AVAILABLE
updated_at = server_now()
valid_until = server_now() + 30 minutes
```

Dopo 30 minuti non dobbiamo necessariamente modificare il record.

Possiamo calcolare lo stato effettivo:

```text
se now > valid_until
→ STALE
```

Questo significa che non serve nemmeno un job cron per “spegnere” ogni stato.

Semplice e gratuito.

---

# 22. Dashboard ristorante

Questa è la schermata più importante dell'app.

Deve essere utilizzabile mentre il personale sta lavorando.

```text
HAPOSTO

Osteria Example

VISIBILE AGLI UTENTI

🟢 C'È POSTO
Aggiornato adesso
Valido ancora 29 min

Come siete messi?

[ 🟢 C'È POSTO ]

[ 🟠 POCHI POSTI ]

[ 🔴 COMPLETO ]

────────────────

+ Dettagli facoltativi
```

Nessuna conferma dopo il tap.

Tap → stato aggiornato.

---

# 23. Dettagli facoltativi ristorante

Devono stare sotto una sezione chiusa.

`+ Dettagli`

Dentro:

```text
Tavoli liberi
[ - ] 2 [ + ]

Attesa indicativa
[ Nessuna ] [ 10 min ] [ 20 min ] [ 30+ ]

Nota
[ Solo tavoli all'esterno          ]
```

Ma tutte queste informazioni sono opzionali.

Il ristorante deve poter usare HAPOSTO per mesi premendo soltanto i tre pulsanti.

---

# 24. Nota testuale

La consentirei, ma cortissima.

Massimo circa:

**60–80 caratteri.**

Esempi:

- `Disponibili solo tavoli esterni`
- `Posto per coppie`
- `Cucina aperta fino alle 22:30`

Non vogliamo una mini pagina social.

Non servono:

- formattazione;
- emoji personalizzate;
- link;
- hashtag.

---

# 25. Telefono

Campo:

```text
phone_number
phone_public
```

Il ristorante decide.

Dashboard:

```text
Mostra il numero agli utenti
[ ON / OFF ]
```

Se OFF:

nessun pulsante chiamata.

Se ON:

```text
[ CHIAMA ]
```

Questo rispetta perfettamente il concept.

L'obiettivo è ridurre le telefonate, non obbligare il locale a riceverle.

---

# 26. Apertura mappe

Nella scheda:

```text
[ INDICAZIONI ]
```

Android apre l'app mappe.

Non dobbiamo sapere:

- quale navigatore usa;
- come calcolare il percorso;
- quanto traffico c'è.

Lo delega il sistema operativo.

---

# 27. UI ristorante e UI utente nella stessa app

Per l'MVP terrei una singola applicazione.

### Utente normale

Apre direttamente la lista.

In menu:

```text
Sei un ristoratore?
```

### Ristoratore autenticato

Compare:

```text
Gestisci locale
```

Quindi non abbiamo due app da mantenere.

In futuro potremo separarle.

---

# 28. Navigazione app

Bottom navigation consumer molto minimale:

```text
[ Vicino a me ]   [ Cerca ]   [ Altro ]
```

Ma potremmo fare persino senza bottom navigation.

Home + ricerca possono convivere.

Un MVP elegante potrebbe avere:

- una sola Home;
- scheda;
- area ristoratore;
- impostazioni.

Meno è meglio.

---

# 29. Stile visivo

Non farei un'app “rossa da ristorante”.

Non userei nemmeno il verde come colore principale del brand perché serve già a comunicare disponibilità.

## Direzione grafica

- sfondo chiaro leggermente caldo;
- testo antracite;
- accent principale blu petrolio / indaco scuro;
- verde esclusivamente per disponibilità;
- ambra per pochi posti;
- rosso per completo;
- grigio per dati non live.

Questo mantiene gli stati semanticamente forti.

---

# 30. Accessibilità

Non affidiamoci soltanto al colore.

Esempio:

```text
● C'È POSTO
```

non un semplice pallino verde.

Perché un utente con difficoltà nella percezione dei colori deve capire comunque.

Usiamo:

- testo;
- icona;
- colore.

---

# 31. Font e componenti

Userei un font di sistema / Material senza introdurre dipendenze inutili.

Material 3.

Card:

- bordi puliti;
- poco shadow;
- angoli non eccessivamente “giocattolo”;
- spaziatura generosa;
- animazioni molto leggere.

Niente:

- glassmorphism;
- effetti 3D;
- gradienti vistosi;
- animazioni continue.

Il prodotto deve sembrare:

> veloce, affidabile, urbano.

---

# 32. Schema database V1

## restaurants

```text
id
name
address
city
province
postal_code
latitude
longitude
phone_number
phone_public
directory_status
partnership_status
created_at
updated_at
```

## restaurant_live_status

```text
restaurant_id
status
updated_at
valid_until
available_tables
estimated_wait_minutes
note
updated_by
```

## restaurant_users

```text
restaurant_id
user_id
role
created_at
```

## restaurant_claims

```text
id
restaurant_id
user_id
status
contact_info
created_at
reviewed_at
reviewed_by
```

## status_history

```text
id
restaurant_id
status
updated_at
valid_until
updated_by
```

Per l'MVP basta.

---

# 33. Partnership status

Suggerisco:

```text
DIRECTORY_ONLY
CLAIM_PENDING
ACTIVE_PARTNER
PAUSED
SUSPENDED
```

## DIRECTORY_ONLY

Presente nella directory, nessun live.

## CLAIM_PENDING

Un ristoratore ha chiesto di gestirlo.

## ACTIVE_PARTNER

Può pubblicare lo stato.

## PAUSED

Il ristorante ha temporaneamente disattivato il servizio.

## SUSPENDED

Bloccato dall'amministrazione.

---

# 34. Stato live

```text
AVAILABLE
LIMITED
FULL
```

Lo stato visualizzato viene poi trasformato in:

```text
AVAILABLE + valido = C'È POSTO

LIMITED + valido = POCHI POSTI

FULL + valido = COMPLETO

qualunque stato + scaduto = DA AGGIORNARE
```

Per i non partner:

```text
NON COLLEGATO
```

Questo evita di salvare `STALE` nel database.

STALE è una condizione derivata dal tempo.

---

# 35. Row Level Security

Supabase RLS sarà fondamentale.

Regola concettuale:

## Pubblico

Può leggere soltanto le colonne pubbliche.

## Ristoratore

Può aggiornare solo il proprio ristorante.

## Staff

Può modificare soltanto lo stato dei ristoranti a cui è assegnato.

## Admin

Può fare tutto.

Un ristoratore non deve poter inviare:

```text
restaurant_id = ID_DI_UN_ALTRO_LOCALE
status = FULL
```

e modificare il concorrente.

La sicurezza deve stare nel database, non soltanto nell'interfaccia.

---

# 36. Realtime

Supabase Realtime può essere utile.

Scenario:

1. ristorante passa da FULL a C'È POSTO;
2. Supabase aggiorna il record;
3. un utente che sta guardando la lista riceve l'aggiornamento;
4. la card cambia senza refresh.

È perfettamente coerente con l'idea “live”.

Ma non è necessario costruire un sistema websocket personalizzato.

---

# 37. Cache

La lista può essere cacheata sul telefono per qualche minuto.

Se internet manca:

```text
Ultimi dati disponibili
```

e non dobbiamo presentarli come live.

Esempio:

```text
Offline
Ultimo aggiornamento lista: 19:42
```

In questo prodotto è meglio dichiarare l'incertezza che mostrare falsi dati live.

---

# 38. Freemium: che modello userei

Qui distinguerei due fasi.

# FASE BETA

## Utenti

Gratis.

## Ristoranti

Gratis.

Ma sin dal primo onboarding scriviamo chiaramente:

> **HAPOSTO è gratuito durante la fase beta. Il servizio per i ristoranti potrà diventare a pagamento al termine della beta. Nessun costo verrà applicato automaticamente senza accettazione.**

Questo è importante.

Non vogliamo dare l'impressione:

> “gratis per sempre”

e poi cambiare improvvisamente.

---

# 39. Dopo il raggiungimento della massa critica

Quando la rete ha valore:

## Utente BASIC — gratuito

- ricerca;
- disponibilità live;
- distanza;
- indicazioni;
- telefono pubblico;
- filtri base.

Questo dovrebbe restare gratuito.

## Utente PLUS — futuro, circa €0,99/mese

Possibili funzioni:

- preferiti;
- notifiche;
- `Avvisami quando torna disponibile`;
- filtri avanzati;
- watchlist dei ristoranti.

Non implementarlo finché gli utenti non chiedono realmente qualcosa del genere.

---

# 40. Ristorante dopo la beta

Qui il modello può diventare a pagamento.

## DIRECTORY — €0

Rimane nella directory:

```text
Disponibilità non collegata
```

Nessun accesso allo stato live.

## LIVE — ipotesi €4,99/mese

- C'È POSTO;
- POCHI POSTI;
- COMPLETO;
- timestamp;
- telefono opzionale;
- nota;
- tavoli opzionali;
- dashboard;
- badge LIVE.

In futuro:

## PRO — €9,99 / €14,99

- staff;
- notifiche;
- analytics;
- storico;
- integrazioni;
- funzionalità avanzate.

---

# 41. È freemium?

Per l'utente:

**sì.**

Per il ristorante:

è più precisamente:

> **free directory + paid live service**

Durante la beta:

> **free beta.**

Questa terminologia è più corretta.

---

# 42. Come passare dal gratuito al pagamento senza distruggere il network

Non farei:

> “Da domani paghi €4,99.”

Farei:

### Giorno -30

Messaggio:

```text
La beta gratuita termina il 30 novembre.

Dal 1° dicembre:
HAPOSTO Live €4,99/mese.

Se non vuoi aderire al piano Live, il tuo ristorante resterà gratuitamente nella directory senza disponibilità live.
```

### Giorno 0

Chi accetta:

`ACTIVE_PAID`

Chi non accetta:

`DIRECTORY_ONLY`

Nessun addebito automatico non autorizzato.

---

# 43. Founding restaurants

Potrebbe essere intelligente riconoscere chi ha aiutato nella beta.

Esempio:

```text
Prezzo standard futuro: €6,99
Founding restaurant: €4,99
```

finché rimane abbonato.

Questo crea:

- gratitudine;
- retention;
- incentivo ad aderire presto.

Non fisserei però ora il prezzo definitivo.

Prima dobbiamo capire il valore reale.

---

# 44. La monetizzazione non va implementata subito nel codice

Nel database possiamo predisporre:

```text
plan_code
billing_status
beta_access
```

Ma nessun pagamento nella V1.

Quando arriverà il momento:

- valutiamo store billing;
- fatturazione B2B;
- Stripe o altro;
- fiscalità.

Prima dobbiamo verificare:

> i ristoranti aggiornano davvero?

---

# 45. Costi: cosa può essere davvero €0

## Gratis nello sviluppo

- Android Studio;
- Kotlin;
- Jetpack Compose;
- Git;
- repository Git privato/pubblico a seconda del provider;
- Supabase Free;
- PostgreSQL;
- PostGIS;
- Supabase Auth entro quota;
- MapLibre come libreria, se un giorno servirà;
- Firebase Cloud Messaging;
- testing locale.

## Non completamente gratuito

### Google Play Console

**25 USD una tantum** per l'account sviluppatore.

### Apple Developer Program

**99 USD/anno** quando pubblicheremo iOS.

### Dominio

Opzionale, ma un dominio professionale costa.

Possiamo inizialmente evitarlo.

Quindi la formula corretta è:

> **MVP senza costi infrastrutturali ricorrenti iniziali, esclusa la pubblicazione sugli store.**

---

# 46. Firebase: dove eventualmente rimane

Io non eliminerei Firebase come possibilità.

Lo terrei soltanto per servizi che fa bene e gratuitamente.

## Potenziale futuro

- Firebase Cloud Messaging;
- Crashlytics.

Non serve Firebase Database.

Non serve Firebase Storage.

Non serve Firebase Auth.

Backend principale:

> Supabase.

---

# 47. Notifiche: non subito

Il reminder al ristorante è molto utile, ma possiamo implementarlo in seconda iterazione.

Esempio:

```text
Il tuo stato scade tra 5 minuti.

[ CONFERMA C'È POSTO ]
[ POCHI POSTI ]
[ COMPLETO ]
```

FCM non ha costo.

Ma prima facciamo funzionare:

> apri → tap → aggiorna.

---

# 48. Admin panel

Non costruirei subito un'app admin sofisticata.

Per la beta possiamo gestire molte operazioni direttamente dalla dashboard Supabase.

Esempio:

- creare ristorante;
- correggere indirizzo;
- approvare claim;
- sospendere account.

Quando diventa scomodo, creiamo un piccolo pannello web admin.

Non prima.

---

# 49. Inserimento ristoranti beta

Workflow operativo:

1. Creiamo database iniziale.
2. Inseriamo ristoranti selezionati di Pesaro.
3. Li contattiamo.
4. Chi accetta crea/collega account.
5. Verifichiamo.
6. Diventa `ACTIVE_PARTNER`.
7. Gli mostriamo i tre pulsanti.
8. Osserviamo se li usa.

Questo è il test vero.

---

# 50. Nessun account utente = grande vantaggio privacy

Se il consumer non si registra e noi non salviamo la sua posizione:

abbiamo pochissimi dati personali.

Il progetto diventa molto più semplice rispetto a un social network.

Possiamo comunque raccogliere analytics tecnici anonimizzati/aggregati in seguito, facendo le verifiche GDPR necessarie.

Ma la V1 può essere estremamente sobria.

---

# 51. Search

La ricerca deve tollerare errori.

Supabase/Postgres dispone di strumenti adatti per ricerca testuale e fuzzy matching.

Esempio:

utente scrive:

```text
rossin
```

e trova:

```text
Ristorante Rossini
```

Non serve Elasticsearch.

---

# 52. Ordinamento

Default:

```text
1. stato live
2. distanza
3. freschezza
```

Ma ci ragionerei.

Una proposta semplice:

## filtro “Tutti”

ordina per distanza.

## filtro “C'è posto”

ordina per:

1. stato valido;
2. distanza;
3. aggiornamento recente.

Non serve un algoritmo opaco.

---

# 53. Non monetizzare il ranking

Almeno all'inizio.

Non venderei:

> “Paga e compari sopra un ristorante più vicino.”

Rischia di rendere poco credibile la directory.

Se un giorno ci saranno sponsorizzazioni:

devono essere chiaramente etichettate.

La disponibilità non deve mai essere falsata.

---

# 54. Interfaccia “senza foto” come identità

Questa potrebbe diventare una caratteristica del brand.

Mentre tutti mostrano piatti:

HAPOSTO mostra informazioni.

Il messaggio implicito diventa:

> “Non siamo qui per convincerti dove mangiare. Siamo qui per dirti dove puoi andare.”

È molto coerente.

---

# 55. Naming

Nel documento precedente erano emersi nomi descrittivi come:

- Posto?
- C'è Posto
- PostoOra
- TavoloOra
- TavoloLive.

Sono chiari, ma difficili da trasformare in un brand distintivo.

Per questa seconda fase cercherei un nome:

- massimo 2–3 sillabe;
- facile da pronunciare in italiano;
- leggibile su icona;
- collegato indirettamente al concetto;
- non troppo legato alla prenotazione;
- possibilmente utilizzabile anche fuori dalla sola città di lancio.

---

# 56. Nome consigliato: HAPOSTO

Scrittura:

# **HAPOSTO**

Pronuncia naturale:

> “Ha posto?”

È esattamente la domanda che il prodotto elimina.

## Perché funziona

### 1. È la domanda reale

Quando telefoni a un ristorante:

> “Buonasera, avete posto?”

Il brand condensa quella situazione.

### 2. Contiene POSTO

Il significato si capisce anche senza spiegazione.

### 3. È meno generico di “Posto”

`Posto` da solo è molto difficile da possedere come identità.

`HAPOSTO` è più caratteristico.

### 4. È ottimo nei testi

```text
Controlla HAPOSTO.
```

```text
Se ha posto, lo sai.
```

```text
Ha posto?
HAPOSTO.
```

### 5. È visivamente semplice

Sei lettere.

Funziona bene come wordmark.

---

# 57. Limite del nome HAPOSTO

In italiano `ha posto` può anche essere interpretato grammaticalmente come:

> “ha collocato / ha posto una domanda”.

Ma nel contesto food e con il claim corretto l'interpretazione è immediata.

È un gioco linguistico.

Prima di registrare definitivamente il nome dobbiamo fare:

- ricerca marchi italiani;
- ricerca EUIPO;
- ricerca App Store;
- ricerca Google Play;
- controllo dominio;
- controllo social handle.

La ricerca web preliminare effettuata per questa analisi non ha mostrato un'app evidentemente omonima nel settore, ma **non equivale a una verifica legale del marchio**.

---

# 58. Alternative naming

## SEDORA

Da:

> siedi + ora.

Più astratto.

Pro:
- brandabile;
- richiama immediatezza.

Contro:
- significato non immediato;
- può sembrare un nome di persona/prodotto.

## ORAQUI

Da:

> ora + qui.

Pro:
- immediato;
- potrebbe funzionare anche per altre categorie future.

Contro:
- non comunica cibo/posto;
- più generico.

## POSTO?

Molto forte come concept.

Pro:
- nessuno deve capirlo;
- memorabile.

Contro:
- estremamente generico;
- più difficile da proteggere e cercare.

## HAPOSTO

Rimane la mia scelta numero uno.

---

# 59. Nome da evitare: TAVORA

Durante la ricerca attuale emerge già un servizio italiano chiamato Tavora che propone:

- gestione ristorante;
- prenotazioni;
- disponibilità coperti in tempo reale;
- lista d'attesa;
- dashboard.

Quindi:

> **TAVORA è escluso.**

È troppo vicino al nostro settore.

---

# 60. Claim

Con HAPOSTO funzionano bene:

## Opzione A

> **Sai dove c'è posto. Ora.**

## Opzione B

> **Scopri chi ha posto. Adesso.**

## Opzione C

> **Ha posto? Guardalo prima di chiamare.**

## Opzione D

> **Meno chiamate. Più posti trovati.**

Per il consumer preferisco:

> **Sai dove c'è posto. Ora.**

Per il ristorante:

> **Un tap invece di dieci chiamate.**

---

# 61. Logo concept

Non lo disegnerei ancora definitivamente.

Direzione:

- wordmark `HAPOSTO`;
- simbolo molto semplice;
- eventualmente una sedia/tavolo astratta;
- oppure una `H` costruita con due sedute;
- piccolo punto status.

Eviterei:

- forchetta e coltello classici;
- cappello da chef;
- piatto fumante;
- campanella;
- pin mappa standard.

Sono cliché.

Il brand dovrebbe sembrare più vicino a:

> una utility urbana

che a:

> un'app di ricette.

---

# 62. Icona app

Idea molto minimale:

```text
H
•
```

oppure un simbolo geometrico che ricorda due sedie attorno a un tavolo.

Il colore del brand non deve essere il verde live.

Altrimenti:

- logo verde;
- stato verde;

si confondono.

---

# 63. Primo prototipo da costruire

Quando passeremo al codice, non partirei da login.

Ordine:

## Build 1

Lista fake locale.

Dati hardcoded:

- 10 ristoranti;
- 4 live;
- 3 full;
- 3 non collegati.

Serve per fissare UI.

## Build 2

Supabase.

Leggiamo lista reale.

## Build 3

PostGIS + posizione.

## Build 4

Supabase Auth ristoratore.

## Build 5

Dashboard status.

## Build 6

RLS.

## Build 7

Realtime.

## Build 8

Claim/verification.

Questo ordine riduce molto il rischio.

---

# 64. Architecture V1

```text
ANDROID APP
   │
   ├── Public UI
   │     ├── Nearby
   │     ├── Search
   │     └── Restaurant detail
   │
   ├── Restaurant UI
   │     ├── Google Login
   │     ├── Claim
   │     └── Live dashboard
   │
   ▼
SUPABASE
   │
   ├── Auth
   ├── PostgreSQL
   ├── PostGIS
   ├── RLS
   └── Realtime
```

Futuro:

```text
FCM
```

solo per notifiche.

---

# 65. Per iOS

Il backend è già predisposto.

Quando arriveremo a iOS possiamo scegliere:

## SwiftUI

UI nativa iPhone.

Oppure:

## Kotlin Multiplatform

Condividere:

- data models;
- repository;
- networking;
- logica status.

Per adesso non dobbiamo decidere.

La decisione importante è:

> il database e le API non devono conoscere Android.

Supabase risolve già gran parte del problema.

---

# 66. Cosa significa “professionale” in questo progetto

Non significa avere tante feature.

Significa:

- loading ben fatto;
- errori comprensibili;
- dati freschi;
- stati coerenti;
- niente schermate rotte;
- posizione gestita correttamente;
- privacy minima;
- design coerente;
- accessibilità;
- sicurezza lato database;
- nessuna informazione ingannevole.

Un'app con cinque schermate perfette sembra più professionale di una con trenta schermate mediocri.

---

# 67. Messaggi di errore

Esempi.

## Posizione negata

```text
Posizione non disponibile

Puoi comunque scegliere una città o cercare un ristorante.
```

## Nessun ristorante live

```text
Nessun locale collegato ha comunicato disponibilità vicino a te.

Mostra tutti i ristoranti
```

## Stato scaduto

```text
Ultimo stato troppo vecchio per considerarlo affidabile.
```

## Internet assente

```text
Sei offline.
Gli stati live potrebbero non essere aggiornati.
```

Questo aumenta la fiducia.

---

# 68. Empty states

Se Pesaro inizialmente ha pochi partner non dobbiamo mostrare una pagina “vuota”.

Esempio:

```text
3 ristoranti stanno comunicando disponibilità live.

Altri 27 sono presenti nella directory.
```

Questo spiega il network in crescita.

---

# 69. Possibile CTA sui ristoranti non collegati

Con prudenza:

```text
Gestisci questo ristorante?
Richiedi collegamento
```

Non metterei:

> “Invita il ristorante”

nella V1.

Potrebbe generare spam.

---

# 70. Analytics iniziali

Possiamo evitare analytics pesanti.

Ci servono solo KPI di prodotto.

Nel nostro database possiamo contare:

- query;
- visualizzazioni scheda;
- click indicazioni;
- click telefono;
- numero aggiornamenti status.

Ma prima di raccogliere telemetria dettagliata dobbiamo definire bene privacy e necessità.

Nell'MVP tecnico possiamo partire persino senza analytics consumer avanzati.

---

# 71. Metriche vere del pilot

Più importanti dei download:

## Ristoranti

- quanti aggiornano ogni giorno;
- aggiornamenti per servizio;
- % status ancora freschi;
- quanti smettono dopo una settimana.

## Utenti

- quanti trovano almeno un locale live;
- quanti aprono indicazioni;
- ritorno nell'app.

## Qualità

- tempo medio dall'ultimo aggiornamento;
- % partner con stato valido durante cena.

---

# 72. Obiettivo beta locale

Non punterei a migliaia di installazioni subito.

Una beta utile potrebbe essere:

- 20–30 ristoranti collegati;
- buona concentrazione;
- un numero limitato di tester;
- 2–4 settimane di utilizzo reale.

Il segnale forte è:

> i ristoratori aggiornano senza che dobbiamo ricordarglielo continuamente.

Se succede, abbiamo qualcosa.

---

# 73. Il rischio principale resta invariato

Non è Supabase.

Non è Android.

Non è il nome.

È:

> **il ristoratore si ricorderà di aggiornare lo stato?**

Tutto il design deve essere costruito attorno a quella domanda.

Se il dato è corretto, l'app ha valore.

Se il dato è vecchio, anche un'app bellissima non serve.

---

# 74. Decisioni che considero già abbastanza mature

Io fisserei da subito:

### Prodotto
- availability-only.

### Territorio
- Pesaro → provincia per densità.

### Android
- Kotlin + Jetpack Compose.

### Backend
- Supabase.

### Auth
- Supabase Auth.

### Consumer auth
- nessun account.

### Restaurant login MVP
- Google OAuth via Supabase.

### Mappe
- nessuna mappa interna V1.

### Distanza
- PostGIS.

### Foto
- nessuna.

### Storage
- non usato.

### Stato
- C'È POSTO / POCHI POSTI / COMPLETO.

### TTL
- 30 minuti.

### Non partner
- NON COLLEGATO.

### Monetizzazione
- beta gratuita → live B2B a pagamento in futuro;
- consumer basic gratuito;
- consumer premium soltanto successivamente.

### Working name
- HAPOSTO.

---

# 75. Decisioni che NON serve prendere ancora

- prezzo definitivo;
- Stripe;
- Apple billing;
- email SMTP;
- notifiche push;
- staff multiutente;
- analytics avanzati;
- mappa interna;
- iOS architecture precisa;
- subscription utente;
- domini;
- logo definitivo;
- integrazione POS.

Le decideremo quando hanno un motivo reale.

---

# 76. Stack zero-cost MVP finale

```text
IDE
Android Studio                    €0

LINGUAGGIO
Kotlin                            €0

UI
Jetpack Compose / Material 3      €0

DATABASE
Supabase PostgreSQL               €0 entro Free Tier

GEO
PostGIS                           €0 dentro Supabase

AUTH RISTORANTE
Supabase Auth + Google OAuth      €0 entro quota

AUTH UTENTE
Nessuno                           €0

IMMAGINI
Nessuna                           €0

MAPPA EMBEDDED
Nessuna                           €0

NAVIGAZIONE
Intent verso app mappe            €0

PUSH FUTURO
Firebase Cloud Messaging          €0

VERSION CONTROL
Git                               €0

ANDROID PUBLISHING
Google Play                       $25 una tantum

IOS FUTURO
Apple Developer Program           $99/anno
```

Questo è probabilmente uno degli stack più economici possibili mantenendo una struttura professionale.

---

# 77. Nota su Supabase email Auth

C'è una ragione ulteriore per preferire Google Sign-In nella beta.

La documentazione Supabase 2026 specifica che il server SMTP predefinito:

- è pensato per test;
- ha forti rate limit;
- non è pensato come servizio email production completo;
- Supabase raccomanda custom SMTP per produzione.

Quindi:

```text
Google OAuth
```

ci permette di non introdurre ora:

```text
Resend / SendGrid / SMTP / email verification infrastructure
```

Meno servizi = meno problemi.

---

# 78. Fonti tecniche verificate per questa Parte 2

## Supabase Pricing
https://supabase.com/pricing

## Supabase Auth — Google
https://supabase.com/docs/guides/auth/social-login/auth-google

## Supabase Kotlin
https://supabase.com/docs/reference/kotlin/initializing

## Supabase PostGIS
https://supabase.com/docs/guides/database/extensions/postgis

## Supabase Production/Auth email limits
https://supabase.com/docs/guides/deployment/going-into-prod

## Supabase custom SMTP
https://supabase.com/docs/guides/auth/auth-smtp

## Firebase pricing / Cloud Messaging
https://firebase.google.com/pricing

## MapLibre Native
https://maplibre.org/projects/native/

## OpenStreetMap Tile Usage Policy
https://operations.osmfoundation.org/policies/tiles/

## Android / Jetpack Compose
https://developer.android.com/develop/ui/compose

## Google Play developer registration
https://support.google.com/googleplay/android-developer/answer/6112435

## Apple Developer Program
https://developer.apple.com/programs/whats-included/

## Tavora — competitor/naming collision
https://tavora-app.com/

---

# 79. Conclusione

La versione che sta emergendo è migliore di quella iniziale perché sta togliendo complessità anziché aggiungerla.

Il prodotto potrebbe essere:

# HAPOSTO
### Sai dove c'è posto. Ora.

L'utente:

```text
APRE
↓
VEDE
↓
VA
```

Il ristoratore:

```text
APRE
↓
TOCCA VERDE / ARANCIO / ROSSO
↓
FINE
```

Tutto il resto deve essere subordinato a questo.

La scelta tecnica che farei oggi è:

> **Android nativo + Kotlin + Compose + Supabase completo + PostGIS, nessun account consumer, Google login Supabase solo per ristoratori, niente Firebase Auth, niente mappe interne e niente foto.**

È una base molto semplice, professionale e predisposta a crescere.

E la scelta commerciale sarebbe:

> **beta gratuita dichiarata esplicitamente come beta; quando la rete avrà valore, il ristorante potrà restare gratuitamente in directory oppure pagare per continuare a pubblicare lo stato LIVE.**

Questo evita sia il problema del cold start sia la promessa implicita di gratuità eterna.

Il prossimo passo, quando decidiamo di iniziare davvero, non dovrebbe essere ancora il codice del login.

Dovrebbe essere:

> **definire le 4–5 schermate esatte e il database V1, poi costruire il primo progetto Android Studio.**
