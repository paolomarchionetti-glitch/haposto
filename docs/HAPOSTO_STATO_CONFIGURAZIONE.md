# HAPOSTO — Stato della configurazione (punto di ripresa)

Ultimo aggiornamento: **5 ottobre 2026** (Parte 10 in sospeso; PR #16–#19 collaudate sul DEV; percorso fino al lancio in `docs/HAPOSTO_ROADMAP_DA_QUI_AL_LANCIO.md`). Questo file dice **dove siamo
arrivati** seguendo `docs/HAPOSTO_GUIDA_CONFIGURAZIONE_COMPLETA.md` e **come si riprende** in una
nuova sessione.
Si aggiorna alla fine di ogni parte completata (nella stessa PR della parte).

> Nessun segreto, email personale o identificativo di progetto in questo file: il repository è
> pubblico. I valori veri sono in `local.properties`, nei segreti di Supabase e nel gestore di
> password del titolare.

## 1. Avanzamento della guida

| Parte | Stato | Note |
|---|---|---|
| 1 — Migration 0012–0013 (+ 0005 tempo reale) | ✅ fatta (DEV) | anche la verifica completa (step18 + step8_to_17) |
| 2 — Login Google + 2FA | ✅ fatta (DEV) | progetto Google Cloud con nome **provvisorio**; app in *Testing*; 2 account Google tra i *Test users* (admin e "ristoratore"); provider Google in Supabase; Email disattivato; TOTP attivo |
| 3 — Android Studio | ✅ fatta | variante `devDebug`; `local.properties` con le chiavi DEV, `GOOGLE_WEB_CLIENT_ID`, `FIREBASE_DEV_*`, `PUBLIC_SITE_URL` |
| 4 — Admin e prova ristoratore | ✅ fatta | credenziali del pannello create; un locale di prova rivendicato, approvato e gestito dall'account "ristoratore"; prova fatta con **un solo telefono** alternando gli account |
| 5 — Firebase (notifiche) | ✅ fatta (DEV) | piano Spark (gratis), aggiunto al progetto Google Cloud della Parte 2; app `com.haposto.dev` registrata |
| 6 — Edge Function e lavori pianificati | ✅ fatta (DEV) | **7 funzioni** pubblicate (ripubblicate il 3 ottobre dopo le PR #16–#18, chiavi nuove); segreti `HAPOSTO_CRON_SECRET`, `FIREBASE_SERVICE_ACCOUNT`; vault; `scheduled_jobs.sql` (9 lavori, avvisi di scadenza compresi), `push_dispatch_cron.sql`, `restaurant_files_cron.sql`; notifica di prova arrivata ad app chiusa (`"delivered":1`); **6.4 ping anti-pausa attivo** (segreti `SUPABASE_DEV_URL` / `SUPABASE_DEV_PUBLISHABLE_KEY`, esecuzione manuale verde) |
| 7 — Google Play / Plus | ⏸ rimandata | richiede Play Console (25 $) e una carta sul progetto Google Cloud (Pub/Sub); da fare dopo le decisioni su nome e account Play |
| 8 — Stripe / Pro | ⏸ rimandata | richiede i dati dell'attività (P.IVA); roadmap aprile 2027 |
| 9 — Sito | ✅ fatta | Cloudflare Pages, indirizzo provvisorio `haposto-test.pages.dev`, collegato al progetto **DEV**; URL Configuration di Supabase, Branding di Google, segreti `HAPOSTO_SITE_URL` / `HAPOSTO_ALLOWED_ORIGINS`, `PUBLIC_SITE_URL` fatti; login ristoratori sul sito e QR dall'app provati |
| 10 — Progetto di produzione | ⏸ **in sospeso** | decisione del 2 ottobre 2026: prima si finisce l'app sul DEV con le migliorie (sezione 3 bis), poi si crea la produzione. Guida già verificata e corretta con la PR #16 (migration 0014, chiavi delle Edge Function); passi 10.1–10.10 |
| 11 — Procedure di tutti i giorni | da leggere | nessuna azione di configurazione |
| 12 — Test finali | dopo la 10 (e la 7 per Play) | |

## 2. Decisioni prese

- **Costi zero** finché possibile: niente servizi a pagamento senza chiedere prima (le Parti 7–8 sono
  rimandate per questo).
- **Nome** non definitivo: "HAPOSTO" è provvisorio; il nome va deciso prima di dominio, Google Play
  (il package diventa definitivo) e documenti legali.
- **Sito** su Cloudflare Pages (non GitHub Pages: il sito va servito alla radice di un dominio).
- **Telefono di prova:** uno solo (Google Pixel 6a); le prove a due telefoni si fanno alternando gli
  account o con un emulatore.
- **Registro modifiche:** ogni modifica al repository ha il suo file in `docs/modifiche/`
  (regola in `CLAUDE.md`).
- **Ordine dei lavori (2 ottobre 2026):** prima l'app completa sul DEV con dati di prova e migliorie,
  poi la produzione (Parte 10).
- **Modello di pagamento (2 ottobre 2026, prezzi provvisori, IVA inclusa):**
  - ristoranti, piano unico **Pro**: 19,90 € al mese, 99,90 € per 6 mesi, 199,90 € l'anno. Dopo la
    prova si paga; chi non paga torna **"Non collegato"** (resta nella lista, senza stato e senza
    poter pubblicare);
  - prova: quella generale fino alla data `beta` (oggi 30/06/2027); chi entra dopo ha **30 giorni**,
    modificabili dal pannello admin;
  - utenti, **Plus**: 0,99 € al mese, 4,99 € per 6 mesi, 9,99 € l'anno (vantaggi da definire meglio;
    oggi: avvisi "si è liberato", preferiti illimitati, raggio esteso, storico);
  - **nell'app niente inviti né link al pagamento di Pro** (regole di Google Play): l'app informa
    (piano, data di fine, avvisi, contatto email); Pro si attiva sul sito, area ristoratori.

## 3. Cose rimaste aperte (piccole)

- [ ] Facoltativo: Cloudflare → *Preview branch* **None** (oggi le anteprime dei branch sono attive).
- [ ] Prova del **tempo reale fra due dispositivi** (stato pubblicato su uno, visibile sull'altro in
      1–2 secondi): serve un secondo telefono o l'emulatore.
- [ ] Decisioni D1–D3 della roadmap (forma giuridica, dominio, account Play) prima delle Parti 7–8.
- [ ] Prova sul campo con 1–3 ristoratori amici (Tappa 1 della roadmap da qui al lancio): prima
      aggiungere la loro email Google ai *Test users* di Google Cloud.

Fatto il 3 ottobre 2026 sul DEV (PR #16, #17, #18): migration 0014, 0015, 0016; 7 Edge Function
ripubblicate; `restaurant_files_cron.sql` e `scheduled_jobs.sql`; prova della pulizia dei file
(`{"removed":0}`) e della notifica (`"delivered":1`); ping anti-pausa; prove nell'app (dettatura,
prenotazioni, note pronte, offerta, menù/sito/file, pagina del QR, scheda **Contenuti**, "Il tuo
piano": "Gratis durante la beta"). Tutto come previsto.

Fatto il 3–5 ottobre 2026 sul DEV (PR #19): migration 0017 (`oggi_in_italia` corretto,
`funzione_nuova` = 1), app Dev aggiornata, prove delle frasi nuove della dettatura. Tutto come
previsto.

## 3 bis. Migliorie in programma (sul DEV, in quest'ordine)

Regola: poche opzioni, semplici e immediate; dettatura dove possibile, sempre correggibile a mano.

Stato: 1–3 nella PR #17, 4 nella PR #18, **tutti collaudati sul DEV il 3 ottobre 2026**; 5 nella
PR #19.

1. **Ping automatico** contro la pausa dei progetti Free (guida 6.4) e questo stato.
2. **Dettatura e prenotazioni veloci** (solo app): in *Dettagli facoltativi* un solo 🎙 che compila
   tavoli, attesa e nota, più le ultime note usate; nelle prenotazioni una frase dettata ("Rossi,
   quattro, alle venti e trenta, tavolo dodici") con compilazione intelligente, orari a un tocco,
   due punti automatici, persone a un tocco, giorno Oggi/Domani.
3. **Note pronte, link e file, offerta** (database + app + sito + pannello admin): note pronte
   salvate sul locale (le vede anche lo staff); 2 link (sito, menù) + 1 file facoltativo (foto
   ridotta dal telefono o PDF piccolo) con l'opzione "solo per oggi" (si cancella la notte dopo) e
   controllo dell'admin dopo la pubblicazione; offerta della serata facoltativa (scelte pronte o
   dettata), sotto la responsabilità del ristoratore, che scade con lo stato. Mai menù scritto a mano.
4. **Modello di pagamento** (vedi sezione 2), **PR #18**: prezzi, prova di 30 giorni modificabile,
   avvisi prima della scadenza, "Non collegato" senza piano, abbonamento semestrale su Stripe e
   Google Play.
5. **Dettatura più intelligente e date italiane** (richieste del titolare durante il collaudo),
   **PR #19**:
   - attesa "Nessuna" e "Non indicata" a voce in ogni ordine ("attesa nessuna", "attesa non
     indicata", "togli l'attesa"), comandi per svuotare tavoli, nota e offerta, stime ("una
     ventina di minuti", "un paio di tavoli", "10-15 minuti");
   - prenotazioni: qualsiasi orario ("alle 13.17", "alle 1317", "alle 13 17"), date ("il 15",
     "sabato 15 ottobre"), "una coppia", "famiglia di 4", titoli tolti dal nome;
   - l'offerta dettata a voce passa anche lei dall'avviso di responsabilità della prima volta;
   - migration 0017: "oggi" in ora italiana nelle pulizie e nel pannello; nella scheda del locale
     del pannello admin fonte e scadenza del piano e "Partner dal".

Prossimi passi: il percorso completo, in ordine, con chi fa cosa, costi e durate, è in
**`docs/HAPOSTO_ROADMAP_DA_QUI_AL_LANCIO.md`** (5 ottobre 2026): prova sul campo sul DEV, decisioni
di base (nome, zona, vantaggi di Plus), basi legali e fiscali, produzione (Parte 10), documenti
legali, Google Play, pilot, lancio, pagamenti (Parti 7–8), fine beta e gestione.

**Documenti privati del titolare** (5 ottobre 2026, **fuori dal repository**): *Accessi e chiavi*
(dove si trova ogni valore, cosa conservare, rotazione) e *Guida tecnica* (sezioni dell'app,
pannello admin, regole, valori modificabili, query di controllo). Si tengono sul PC o nel gestore
di password; il `.gitignore` esclude i file con `PRIVATO` nel nome.

## 4. Lezioni pratiche emerse nelle prove

- L'SQL Editor di Supabase **salva da solo** le query: quelle con password o segreti vanno eliminate
  (⋯ → Delete query).
- Google Authenticator ha **una voce HAPOSTO per account**, distinta dall'email: usare sempre quella
  dell'account con cui si è entrati.
- Il telefono si registra per le notifiche **solo con un account collegato** nell'app; l'app va
  chiusa scorrendola via, **non** con *Forza interruzione* o lo Stop di Android Studio.
- Sul sito, se il browser è collegato a più account Google, scegliere l'account giusto (dal 2 ottobre
  il sito lo chiede sempre e mostra l'email nella schermata del codice).
- Il messaggio di Google "Continua su `….supabase.co`" durante il login dal sito è normale.
- Nel pannello di Supabase (tabelle, risultati del SQL Editor, log) gli orari sono in **UTC**: in
  Italia sono 2 ore in più d'estate, 1 d'inverno. App, sito e pannello admin mostrano sempre l'ora
  del telefono o del browser; dove conta "il giorno italiano" il database usa `Europe/Rome`.
- **Actions → Run workflow** su GitHub: repository → scheda **Actions** → a sinistra il workflow →
  a destra il pulsante **Run workflow** → **Run workflow**.
- I progetti Supabase creati nel 2026 non hanno chiavi legacy e non danno permessi automatici sulle
  tabelle: per questo esistono la migration 0014 e la lettura di `SUPABASE_SECRET_KEYS` nelle
  funzioni (PR #16). Ogni tabella nuova deve avere i suoi `GRANT` espliciti.

## 5. Come riprendere in una nuova sessione

1. Tutte le PR della sessione precedente devono essere **unite in `main`** (la nuova sessione parte da
   `main`).
2. Nella nuova sessione incolla il messaggio di ripresa (vedi sotto). Claude legge da solo `CLAUDE.md`;
   il messaggio gli fa leggere questo file e la guida.
3. Tieni a portata (senza incollarli in chat): gestore di password, `local.properties`, accesso a
   Supabase, Google Cloud, Firebase, Cloudflare, GitHub, il telefono con Google Authenticator.

Messaggio di ripresa:

```text
Progetto HAPOSTO. Leggi CLAUDE.md, docs/HAPOSTO_STATO_CONFIGURAZIONE.md e la guida
docs/HAPOSTO_GUIDA_CONFIGURAZIONE_COMPLETA.md, poi riprendi dal punto indicato nello stato
e la roadmap docs/HAPOSTO_ROADMAP_DA_QUI_AL_LANCIO.md (tappa in corso). Una parte alla volta: dimmi cosa cliccare o
incollare e aspetta la mia conferma. Prima di darmi i passi verifica che la guida corrisponda al
codice; se trovi errori nel codice o nella guida correggili su un branch dedicato con test, CI e
registro in docs/modifiche, poi proponimi la PR. Rispondi in italiano; non chiedermi, non modificare
e non pubblicare password, token, chiavi segrete, file .env o local.properties; non lavorare su main.
```

## 6. Note tecniche per chi lavora sul codice (anche Claude)

- **CI** (`.github/workflows/android-ci.yml`): build delle tre varianti, test JVM, lint, test su
  emulatore API 34, job SQL (migration, seed, controlli step8_to_17 / step18 / dev_tools, ordine della
  guida, KPI, import OSM, pulizia DEV, note/link/file/offerta (step19), piani e prova (step20), date italiane (step21), **progetto di produzione nuovo** senza permessi automatici:
  stessi permessi del DEV, operazioni del server, controlli e import OSM) e job Deno delle Edge
  Function. Il sito ha il workflow `website.yml` e la pubblicazione su Cloudflare Pages.
- **Verifiche locali usate finora** (in un ambiente senza SDK Android, dove l'app si verifica solo in
  CI): Postgres 16 + PostGIS per replicare il job SQL (anche eseguendo i passi `run` letti
  direttamente dal workflow); immagine `supabase/postgres` 17 + Supabase Auth (gotrue) in Docker per
  provare le migration come l'SQL Editor (utente `postgres`, file intero in una richiesta); Deno da
  npm per `deno check` / `lint` / `test` delle funzioni; Supabase CLI da npm; Chromium/Playwright per
  il sito (con un finto `supabase-js`).
- **Prove sul progetto DEV vero** le fa sempre il titolare, seguendo la guida; Claude non ha accesso
  al progetto.
- **Fotografia dello schema del DEV**: `supabase/database/` (dump del 5 ottobre 2026, solo struttura,
  senza dati né permessi; da consultare, **non** da eseguire). Corrisponde alle migration
  `0001`–`0017` più `supabase/dev/dev_tools.sql`. Come rifarlo: `supabase/database/README.md`.
