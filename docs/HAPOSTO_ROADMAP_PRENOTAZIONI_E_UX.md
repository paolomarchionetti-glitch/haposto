# HAPOSTO — Roadmap ragionata: prenotazioni, info locale e UX

*Questo documento traccia i pezzi che richiedono più tempo e decisioni prima di scrivere codice. Il 7.6 (interfaccia essenziale) è già fatto; qui ragioniamo su ciò che viene dopo, in ordine di quanto pensiero serve.*

Principio che governa tutto: **la semplicità è il fossato.** Ogni idea qui sotto passa un test: *entra nei due loop core (utente "apri→vedi→vai", ristoratore "un tap→fine") o resta ai bordi?* Se tocca i loop core, o si scarta o si progetta con estrema cautela.

---

## 1. Prenotazioni — la decisione più delicata

L'idea "gestire facilmente le ultime prenotazioni o tutte, per chi vuole abbandonare carta e penna" è ottima, ma nasconde **due prodotti diversi** dietro la stessa parola. Vanno separati, perché uno è compatibile col fossato e l'altro può ucciderlo.

### 1a. Registro interno (compatibile — da fare per primo)

Un **quaderno digitale delle prenotazioni** che il ristoratore riceve come sempre (telefono, di persona, WhatsApp) e annota nell'app invece che su carta. Il cliente non prenota tramite HAPOSTO, non vede nulla di tutto questo.

Perché è compatibile col fossato:
- **non tocca i due loop core**: è un modulo opt-in nell'area ristoratore;
- **non intacca la promessa "non è una prenotazione"** verso il cliente consumer;
- risolve un dolore reale (carta e penna) e diventa una **leva PRO** (motivo per pagare).

Cosa serve (in ordine):
1. **Auth reale (Step 8)** come prerequisito: senza sapere *chi* è il ristoratore non si può proteggere il suo registro.
2. **Schema + RLS** per una nuova tabella `reservations` (una migration dopo la 0005): campi minimi `restaurant_id`, `datetime`, `party_size`, `name`, `phone`, `note`, `status` (attesa/seduti/no-show/annullata), `source` (telefono/persona/…). RLS: solo gli utenti autenticati di *quel* locale leggono/scrivono le proprie righe.
3. **UI CRUD essenziale**: lista di oggi/prossime, aggiungi in 3 campi (nome, persone, ora), azioni rapide (seduti / no-show / annulla). Coerente col 7.6: tasti grandi, testo minimo.
4. **Offline-first leggero**: durante il servizio la rete balla. Le annotazioni devono restare anche offline e sincronizzarsi dopo. Questo è il pezzo tecnicamente più impegnativo e va progettato con cura (coda locale + risoluzione conflitti last-write-wins, come già facciamo per lo stato).

**Sinergia elegante (ma da maneggiare):** il registro potrebbe *suggerire* lo stato live — "hai 20 coperti prenotati alle 21, vuoi segnare Completo per quella fascia?". Deve restare un **suggerimento**, mai un automatismo: la fiducia dell'app si regge sul fatto che lo stato lo dichiara un umano. Automatizzarlo romperebbe il patto. Da mettere in cantiere solo dopo che il registro è solido.

**Stima onesta:** è un modulo da più step (Auth → schema/RLS → CRUD → offline/sync → eventuale sinergia). Non è un pomeriggio. È però la direzione giusta per il "carta e penna".

### 1b. Prenotazione dal cliente (rischiosa — molto dopo, o mai)

Il cliente prenota un tavolo *tramite* HAPOSTO. Qui si entra dritti nei loop core e si diventa un concorrente di TheFork, con tutto ciò che comporta: conferme, no-show, cauzioni, aspettative di garanzia. **Contraddice frontalmente "non è una prenotazione"** e appesantisce i due gesti che sono il fossato.

Se un giorno si farà, va fatto:
- come **modulo separato e opzionale**, non come default;
- probabilmente come **"richiesta di posto"** (non prenotazione garantita), per non promettere ciò che non si controlla;
- solo **dopo** aver vinto la battaglia della disponibilità live e con massa critica in città;
- con una **decisione strategica esplicita**, perché cambia l'identità del prodotto.

Raccomandazione: **fare 1a, congelare 1b.** Tenerlo come opzione futura, non come prossimo passo.

---

## 2. Modifica completa "Info locale" (media difficoltà)

Nel 7.6 la card "Info locale" è già il punto d'ingresso, ma per ora gestisce solo la visibilità del telefono. La modifica reale di nome, categoria, orari, foto:
- **dipende da Auth + scrittura reale (Step 8–9)**: prima non ha senso, perché oggi le scritture sono overlay in RAM;
- richiede validazioni (nome non vuoto, telefono valido, ecc.) già in parte codificate nel database del contratto V1;
- è un **editor form** semplice: quando c'è la scrittura reale, è lavoro lineare, non concettuale.

**Stima:** modesta, ma *bloccata* fino allo Step 9. Da non anticipare.

---

## 3. Sistema aiuti a scomparsa (piccolo — quasi fatto)

`InfoDisclosure` è già il mattone. Rimane da:
- passarci **tutti** i restanti testi lunghi sparsi nelle schermate (detail, access), per uniformare;
- valutare un interruttore globale "modalità esperto" che nasconde di default anche gli "ⓘ" per chi non li vuole proprio.

**Stima:** piccola, incrementale. Nessun ragionamento profondo.

---

## 4. Punti minori che però vanno decisi

- **Accessibilità dei tasti:** i tasti da 72dp aiutano, ma serve verificare i target touch e i contrasti anche in tema scuro (WCAG). Veloce ma da non saltare.
- **Icone della barra inferiore:** oggi sono glifi testuali (◉ ☆ 🍴). Per un look "top di gamma" valutare `material-icons-extended` o un set custom. Scelta estetica, non urgente.
- **Test di strumentazione:** 7.5 e 7.6 hanno cambiato testi/struttura. Gli UI test Compose che cercavano stringhe vecchie vanno aggiornati. Lavoro meccanico, da pianificare prima del pilot.
- **Font brand:** passare da SansSerif a Poppins/Inter (già predisposto in `Type.kt`). Estetico, 30 minuti.

---

## 5. Priorità suggerita (dove va il tempo)

1. **Step 8 — Auth reale.** Sblocca tutto: scritture live vere, registro prenotazioni, modifica info. È il collo di bottiglia. *(molto tempo)*
2. **Step 9 — Scritture LIVE reali.** Il manager scrive davvero su Supabase. *(medio)*
3. **Registro prenotazioni interno (1a).** Schema+RLS → CRUD → offline/sync. *(molto tempo, ma alto valore PRO)*
4. **Modifica info locale reale.** Dopo lo Step 9, lineare. *(poco)*
5. **Rifiniture aiuti/accessibilità/icone/font/test.** *(piccole, distribuite)*
6. **Prenotazione dal cliente (1b).** Solo come decisione strategica futura. *(congelato)*

---

## 6. Cosa NON fare

- Non infilare la prenotazione dal cliente nei due loop core "per completezza".
- Non automatizzare lo stato live dal registro: resta un suggerimento.
- Non anticipare la modifica info o il registro prima di Auth: si costruirebbe su RAM.
- Non aggiungere campi al registro "perché potrebbero servire": partire con 5 campi e crescere solo su richiesta reale dei ristoratori del pilot.

Il filo conduttore: **ogni cosa nuova sta ai bordi.** Il centro — apri, guarda, vai; un tap, fine — resta intoccato. È quello che rende HAPOSTO diverso da un gestionale.
