# HAPOSTO — Stato della configurazione (punto di ripresa)

Ultimo aggiornamento: **2 ottobre 2026**. Questo file dice **dove siamo arrivati** seguendo
`docs/HAPOSTO_GUIDA_CONFIGURAZIONE_COMPLETA.md` e **come si riprende** in una nuova sessione.
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
| 6 — Edge Function e lavori pianificati | ✅ fatta (DEV) | 6 funzioni pubblicate; segreti `HAPOSTO_CRON_SECRET`, `FIREBASE_SERVICE_ACCOUNT`; vault, `scheduled_jobs.sql`, `push_dispatch_cron.sql`; notifica di prova arrivata ad app chiusa |
| 7 — Google Play / Plus | ⏸ rimandata | richiede Play Console (25 $) e una carta sul progetto Google Cloud (Pub/Sub); da fare dopo le decisioni su nome e account Play |
| 8 — Stripe / Pro | ⏸ rimandata | richiede i dati dell'attività (P.IVA); roadmap aprile 2027 |
| 9 — Sito | ✅ fatta | Cloudflare Pages, indirizzo provvisorio `haposto-test.pages.dev`, collegato al progetto **DEV**; URL Configuration di Supabase, Branding di Google, segreti `HAPOSTO_SITE_URL` / `HAPOSTO_ALLOWED_ORIGINS`, `PUBLIC_SITE_URL` fatti; login ristoratori sul sito e QR dall'app provati |
| 10 — Progetto di produzione | ▶ **prossima** | secondo progetto Supabase sul piano Free |
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

## 3. Cose rimaste aperte (piccole)

- [ ] Ripubblicare `push-dispatch` dopo la PR #12, se non già fatto:
      `npx supabase functions deploy push-dispatch --no-verify-jwt --use-api`
      (la risposta deve contenere `delivered` / `no_device`).
- [ ] Facoltativo: Cloudflare → *Preview branch* **None** (oggi le anteprime dei branch sono attive).
- [ ] Prova del **tempo reale fra due dispositivi** (stato pubblicato su uno, visibile sull'altro in
      1–2 secondi): serve un secondo telefono o l'emulatore.
- [ ] Decisioni D1–D3 della roadmap (forma giuridica, dominio, account Play) prima delle Parti 7–8.

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
docs/HAPOSTO_GUIDA_CONFIGURAZIONE_COMPLETA.md, poi riprendi la configurazione dalla prossima parte
indicata nello stato (Parte 10, progetto di produzione). Una parte alla volta: dimmi cosa cliccare o
incollare e aspetta la mia conferma. Prima di darmi i passi verifica che la guida corrisponda al
codice; se trovi errori nel codice o nella guida correggili su un branch dedicato con test, CI e
registro in docs/modifiche, poi proponimi la PR. Rispondi in italiano; non chiedermi, non modificare
e non pubblicare password, token, chiavi segrete, file .env o local.properties; non lavorare su main.
```

## 6. Note tecniche per chi lavora sul codice (anche Claude)

- **CI** (`.github/workflows/android-ci.yml`): build delle tre varianti, test JVM, lint, test su
  emulatore API 34, job SQL (migration, seed, controlli step8_to_17 / step18 / dev_tools, ordine della
  guida, KPI, import OSM, pulizia DEV) e job Deno delle Edge Function. Il sito ha il workflow
  `website.yml` e la pubblicazione su Cloudflare Pages.
- **Verifiche locali usate finora** (in un ambiente senza SDK Android, dove l'app si verifica solo in
  CI): Postgres 16 + PostGIS per replicare il job SQL; immagine `supabase/postgres` 17 + Supabase Auth
  (gotrue) in Docker per provare le migration come l'SQL Editor (utente `postgres`, file intero in una
  richiesta); Deno da npm per `deno check` / `lint` / `test` delle funzioni; Supabase CLI da npm;
  Chromium/Playwright per il sito (con un finto `supabase-js`).
- **Prove sul progetto DEV vero** le fa sempre il titolare, seguendo la guida; Claude non ha accesso
  al progetto.
