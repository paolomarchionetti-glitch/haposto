# HAPOSTO — Roadmap aggiornata

**Pilot futuro:** Pesaro e provincia  
**Decisione corrente:** STEP 7 attiva Supabase per directory consumer e PostGIS. Auth/claim reale arriva nello STEP 8, le scritture LIVE nello STEP 9 e Realtime nello STEP 10.

## STEP 0 — Fondazione Android ✅

- [x] progetto Android Studio;
- [x] Kotlin + Compose;
- [x] Material 3;
- [x] package/namespace;
- [x] version catalog;
- [x] configurazione secret-safe;
- [x] scaffold Supabase e SQL mantenuti inattivi;
- [x] documentazione iniziale.

---

## STEP 1 — Consumer UI con repository fake ✅

- [x] Home/List;
- [x] card senza foto;
- [x] ricerca;
- [x] filtri minimi;
- [x] record fittizi;
- [x] stato + timestamp;
- [x] TTL 30 minuti;
- [x] detail screen;
- [x] Navigation Compose;
- [x] unit test freshness/search/filter;
- [x] Intent mappe/dialer con dati demo.

---

## STEP 2 — Posizione e distanza reale, ancora offline/local ✅

- [x] runtime permission posizione solo su azione utente;
- [x] precise/approximate;
- [x] nessun background location;
- [x] posizione solo in memoria;
- [x] fallback manuale;
- [x] coordinate fake;
- [x] Haversine;
- [x] ordinamento vicino a me;
- [x] selezione area;
- [x] Home/detail coerenti;
- [x] test geo.

---

## STEP 3 — Dashboard ristoratore locale ✅

- [x] entry point `Sei un ristoratore?`;
- [x] area ristoratore demo;
- [x] C'È POSTO / POCHI POSTI / COMPLETO;
- [x] update con un tap;
- [x] timestamp;
- [x] TTL 30 minuti;
- [x] tavoli/attesa/nota opzionali;
- [x] telefono pubblico;
- [x] stato condiviso con consumer;
- [x] test repository.

---

## STEP 4 — Claim/Auth UX shell, senza backend ✅

- [x] schermata ingresso area ristoratore;
- [x] login Google visuale/simulato e dichiarato DEMO;
- [x] repository account/claim separato;
- [x] ricerca attività simulata;
- [x] selezione attività;
- [x] recapito verifica;
- [x] richiesta gestione;
- [x] `CLAIM_PENDING` UI;
- [x] copy verifica manuale;
- [x] scenario approvato demo;
- [x] accesso dashboard soltanto dopo approved;
- [x] guard sul restaurant id associato;
- [x] logout/reset demo;
- [x] disclosure beta gratuita / LIVE potenzialmente a pagamento;
- [x] test access/claim core;
- [x] nessun provider Auth reale.

**Supabase: ancora OFF.**

---

## STEP 5 — Robustezza Android locale ✅

- [x] loading/empty/error/offline design;
- [x] permission rationale/settings path;
- [x] accessibilità;
- [x] responsive/adaptive layout;
- [x] state restoration dove utile;
- [x] UI test principali;
- [x] revisione copy;
- [x] controllo permessi finali pre-backend;
- [x] revisione access guard e back stack.

---

## STEP 6 — Demo completa pre-backend ✅

- [x] percorso consumer completo;
- [x] percorso ristoratore completo simulato;
- [x] loop manager → repository → consumer testato localmente;
- [x] business rules centralizzate;
- [x] freeze modelli/repository V1 documentato;
- [x] acceptance checklist;
- [x] test matrix multi-device preparata;
- [x] fix integrazione route/network monitor;
- [x] test UI aggiuntivi preparati.

**Nota:** l'esecuzione fisica della matrice multi-device richiede Android Studio/emulatore/device e non viene dichiarata come eseguita nell'ambiente di generazione.

**Gate raggiunto lato codice/documentazione:** STEP 7 è il primo step autorizzato ad attivare Supabase, dopo Build/Make Project e checklist device.

---

## STEP 7 — Supabase database + directory reale ✅

- [x] guida creazione progetto Supabase DEV inclusa;
- [x] migration riallineate al V1 freeze;
- [x] `0001_extensions.sql` pronto per esecuzione su progetto DEV;
- [x] `0002_schema.sql` pronto per esecuzione su progetto DEV;
- [x] `0003_functions.sql` pronto per esecuzione su progetto DEV;
- [x] `0004_rls_and_grants.sql` pronto per esecuzione su progetto DEV;
- [x] `local.properties.example` + validator publishable key;
- [x] `SupabaseRestaurantRepository`;
- [x] RPC con `search_text` fuzzy predisposto e smoke-testato via SQL; UI Step 7 mantiene anche filtro locale sullo snapshot;
- [x] PostGIS RPC per distanza/ordinamento;
- [x] gestione rete/errori + config error esplicito;

**Nota operativa:** creazione progetto, esecuzione SQL, Gradle Sync/Build e test contro il progetto reale vanno eseguiti sul PC seguendo `STEP_7_SETUP_SUPABASE.md` e `STEP_7_BUILD_AND_TEST.md`; l'ambiente di generazione non possiede le tue credenziali/Android SDK.

---

## STEP 8 — Supabase Auth + claim reale ⏭️

- [ ] Google OAuth / PKCE;
- [ ] session handling;
- [ ] sostituire fake access repository;
- [ ] claim reale;
- [ ] approvazione manuale;
- [ ] owner membership;
- [ ] rimuovere `approvePendingClaimForDemo()` dal client production;
- [ ] test RLS.

---

## STEP 9 — Dashboard LIVE backend

- [ ] update RPC;
- [ ] history;
- [ ] TTL server;
- [ ] telefono pubblico;
- [ ] dettagli opzionali;
- [ ] protezioni concorrenti.

---

## STEP 10 — Realtime

- [ ] attivare publication;
- [ ] eseguire `0005_realtime_future.sql` soltanto qui;
- [ ] subscription client;
- [ ] aggiornamento lista senza refresh;
- [ ] reconnect.

---

## STEP 11 — Pilot Pesaro

- [ ] directory reale con provenienza dati controllata;
- [ ] 20–30 partner target;
- [ ] onboarding;
- [ ] active-status rate;
- [ ] stale rate;
- [ ] feedback ristoratori/utenti.

---

## STEP 12 — Reminder / FCM, solo se il pilot lo richiede

- [ ] Firebase Cloud Messaging;
- [ ] reminder stato;
- [ ] deep link dashboard;
- [ ] nessun Firebase Auth/database.

---

## STEP 13 — Monetizzazione

Solo dopo massa critica.

- [ ] fine beta comunicata in anticipo;
- [ ] directory gratuita;
- [ ] LIVE B2B a pagamento;
- [ ] eventuale consumer Plus;
- [ ] billing/fiscalità/policy verificati al momento.

---

## Fuori scope salvo nuova decisione

- foto;
- recensioni;
- chat;
- feed;
- delivery;
- prenotazione completa;
- pagamenti conto;
- ranking pay-to-win;
- posizione background;
- mappa embedded nell'MVP.
