# HAPOSTO — Guida di configurazione completa (dal codice al lancio)

Il codice è completo: app Android (versioni **Demo**, **Dev**, **Prod**), database, Edge Function e
sito. Mancano solo le operazioni che richiedono **i tuoi account e le tue chiavi**, che per
sicurezza non stanno nel repository. Questa guida le elenca **in ordine**, una alla volta.

> Regola d'oro: **tutto prima sul progetto DEV**, poi si ripete sul progetto di produzione.
> Nessuna chiave segreta va mai in GitHub, in chat o in uno screenshot. Le chiavi "publishable"
> (pubbliche) possono stare in `local.properties` e nel sito; le chiavi "secret" solo nei segreti
> di Supabase.

| Parte | Cosa | Tempo | Serve per |
|---|---|---|---|
| 1 | Database DEV: migration 0012–0013 | 10 min | tutto |
| 2 | Login: Google in Supabase + 2FA | 20 min | account, ristoratori, admin |
| 3 | Android Studio: `local.properties` e versioni | 10 min | provare l'app |
| 4 | Diventa amministratore e prova il flusso ristoratore | 20 min | pannello admin |
| 5 | Notifiche push (Firebase) — facoltativo | 20 min | avvisi Plus, promemoria da server |
| 6 | Edge Function e lavori pianificati | 20 min | push, Plus, Pro |
| 7 | Google Play: HAPOSTO Plus | 1–2 ore | abbonamento utenti |
| 8 | Stripe: Pro per i ristoranti | 1 ora | abbonamento ristoranti |
| 9 | Sito (gratis) | 20 min | privacy, termini, QR, pagamento Pro |
| 10 | Progetto di produzione | 1 ora | lancio |
| 11 | Procedure di tutti i giorni (admin, 2FA perse, sospensioni) | — | gestione |
| 12 | Test finali prima del lancio | 2–3 ore | lancio |

**Costi.** Supabase (piano Free), Firebase Cloud Messaging, MapLibre + OpenFreeMap (mappe),
Google Sign-In, Cloudflare Pages/GitHub Pages, Pub/Sub (entro la quota gratuita) sono **gratuiti**.
Si paga solo: l'iscrizione a Google Play Console (**25 $ una tantum**, obbligatoria per pubblicare
sul Play Store), le commissioni sulle vendite (Google 15% su Plus, Stripe ~1,5% + 0,25 € su Pro) e,
se lo vuoi, un dominio (~10–15 €/anno; senza dominio il sito resta su `*.pages.dev`, gratis).

---

## Parte 1 — Database DEV: migration 0012 e 0013

Prerequisito: 0001–0004 e 0006–0011 già eseguite (vedi `HAPOSTO_GUIDA_AGGIORNAMENTO_DB.md`).
Controllo di partenza (SQL Editor → **New query** → **Run**):

```sql
select
    exists (select 1 from information_schema.columns
            where table_schema = 'public' and table_name = 'restaurants' and column_name = 'slug') as fino_a_0011,
    to_regclass('public.audit_log') is not null as ha_0012,
    to_regclass('public.consent_log') is not null as ha_0013;
```

| fino_a_0011 | ha_0012 | ha_0013 | Cosa fare |
|---|---|---|---|
| true | false | false | esegui 0012 e 0013 come sotto |
| true | true | qualsiasi | già eseguita in parte: rieseguire 0012 e 0013 in ordine è sicuro |
| false | – | – | prima 0006–0011 (`HAPOSTO_GUIDA_AGGIORNAMENTO_DB.md`) |

Supabase (progetto DEV) → **SQL Editor** → **New query** → incolla il file intero → **Run**, uno alla volta.
Se compare la finestra *Potential issue detected… destructive operation* è normale (i file
sostituiscono vecchie versioni di funzioni e regole): premi **Run this query**.

| Ordine | File | Cosa aggiunge | Verifica (nuova query) | Atteso |
|---|---|---|---|---|
| 1 | `supabase/migrations/0012_security_and_admin.sql` | 2FA obbligatoria per gestire un locale, codice telefonico per le rivendicazioni, registro operazioni, blocco account, pannello admin con seconda password, limite anti-abuso | `select key from public.app_config order by key;` | compaiono `legal`, `public_links`, `security` |
| 2 | `supabase/migrations/0013_profile_consents_account.sql` | orari e dati del locale, registro attività, consensi, preferenze notifiche, coda push, cancellazione account, storico "di solito" | `select count(*) from public.consent_log;` | `0` |

Entrambi i file sono **rieseguibili**. Se ricevi un errore, fermati e mandami la riga dell'errore.

**Verifica completa (facoltativa, consigliata).** Crea in Authentication → Users → *Add user*
(con "Auto Confirm User") anche `test-thief@haposto.test` (oltre ai 5 utenti di prova già usati),
poi esegui `supabase/tests/step18_security_admin_checks.sql`: in fondo deve comparire
**`CONTROLLI SICUREZZA SUPERATI`** (93 controlli; non lascia dati). Riesegui anche
`step8_to_17_checks.sql`: **`TUTTI I CONTROLLI SUPERATI`**.

---

## Parte 2 — Login: Google + verifica in due passaggi

L'app usa **solo "Accedi con Google"** (nessuna password da rubare) e, per chi gestisce un locale,
la **verifica in due passaggi** con un'app di autenticazione (Google Authenticator, Microsoft
Authenticator, Aegis…). Senza il codice a 6 cifre il database rifiuta ogni modifica al locale:
anche chi ruba l'account Google di un ristoratore non può pubblicare nulla.

### 2.1 Google Cloud: schermata di consenso

1. <https://console.cloud.google.com> → crea un progetto **HAPOSTO** (puoi usare lo stesso di Firebase).
2. **APIs & Services → OAuth consent screen** (o "Google Auth Platform → Branding"):
   - tipo **External**; nome app **HAPOSTO**; email di assistenza; logo (facoltativo);
   - domini autorizzati: il tuo dominio (es. `haposto.app`) e `supabase.co`;
   - link a privacy e termini: `https://TUO_SITO/privacy/` e `https://TUO_SITO/termini/`;
   - ambiti (scopes): solo `openid`, `email`, `profile` (non richiedono verifica di Google).
   - Finché l'app è "In test" aggiungi i tuoi account in **Test users**; al lancio → **Publish app**.

### 2.2 Google Cloud: ID client

**APIs & Services → Credentials → Create credentials → OAuth client ID**, tre volte:

| Tipo | Nome | Dati da inserire | A cosa serve |
|---|---|---|---|
| **Web application** | HAPOSTO Web | *Authorized JavaScript origins*: `https://TUO_SITO` · *Authorized redirect URIs*: `https://REF_DEV.supabase.co/auth/v1/callback` e `https://REF_PROD.supabase.co/auth/v1/callback` | È il `GOOGLE_WEB_CLIENT_ID` dell'app e il login del sito |
| **Android** | HAPOSTO Dev | package `com.haposto.dev` · SHA-1 del certificato di debug | fa comparire la finestra di Google nell'app Dev |
| **Android** | HAPOSTO | package `com.haposto` · SHA-1 della chiave di caricamento **e** (dopo il primo caricamento su Play) SHA-1 della chiave di firma di Google Play | app di produzione |

Come trovare lo SHA-1: Android Studio → pannello **Gradle** → `app` → Tasks → android →
**signingReport** (riga `SHA1` della variante `devDebug`). Per Play: Play Console → la tua app →
**Test and release → App integrity → App signing** → "SHA-1 certificate fingerprint".

Copia **Client ID** e **Client secret** del client *Web*: ti servono al punto 2.3.

### 2.3 Supabase: provider Google

Supabase (DEV) → **Authentication → Sign In / Providers → Google** → **Enable**:

- **Client IDs**: il Client ID *Web* (una sola riga);
- **Client Secret**: il secret del client *Web*;
- **Skip nonce check**: **disattivato** (l'app manda il nonce: è una protezione in più);
- **Save**.

Sempre in **Sign In / Providers**: disattiva **Email** (e ogni altro provider) — in HAPOSTO si
entra solo con Google, così non esistono password deboli da indovinare.

### 2.4 Supabase: verifica in due passaggi e indirizzi

- **Authentication → Multi-Factor**: *TOTP (App Authenticator)* **Enabled**; *Phone* disattivato.
- **Authentication → URL Configuration**: *Site URL* `https://TUO_SITO`; *Redirect URLs*:
  `https://TUO_SITO/ristoratori/` (e, per provare il sito sul PC, `http://localhost:8080/ristoratori/`).
- **Authentication → Rate Limits**: lascia i valori predefiniti.

---

## Parte 3 — Android Studio: chiavi e versioni

1. Copia `local.properties.example` in `local.properties` (stessa cartella; il file **non** va su
   GitHub) e compila almeno:
   ```properties
   SUPABASE_DEV_URL=https://REF_DEV.supabase.co
   SUPABASE_DEV_PUBLISHABLE_KEY=sb_publishable_...
   GOOGLE_WEB_CLIENT_ID=....apps.googleusercontent.com
   ```
   La chiave è in Supabase → **Project Settings → API Keys → Publishable key** (mai la *secret*).
2. **File → Sync Project with Gradle Files**.
3. **Build → Select Build Variant** (pannello *Build Variants*) → modulo `app`:

| Variante | Nome sul telefono | Server | Per cosa |
|---|---|---|---|
| `demoDebug` | HAPOSTO Demo | nessuno (dati nel telefono) | provare l'interfaccia, test automatici |
| `devDebug` | HAPOSTO Dev | Supabase DEV | tutte le prove con account veri |
| `prodDebug` / `prodRelease` | HAPOSTO | Supabase produzione | collaudo finale e pubblicazione |

Le tre versioni si installano **insieme** sullo stesso telefono. In alto a destra la Home mostra
`DEMO` o `DEV`; la versione di produzione non mostra etichette.

Se in Home compare un errore di configurazione, la chiave o l'indirizzo in `local.properties` sono
mancanti o sbagliati: correggi, *Sync*, e reinstalla.

---

## Parte 4 — Diventa amministratore e prova il flusso ristoratore

### 4.1 Primo accesso e 2FA

1. App **HAPOSTO Dev** → tab **Account** → **Accedi con Google** → accetta termini e privacy.
2. Account → **Verifica in due passaggi** → *Attiva* → aggiungi HAPOSTO all'app di autenticazione
   (tasto "Apri l'app di autenticazione" o codice manuale) → scrivi il codice a 6 cifre.

### 4.2 Credenziali del pannello admin (seconda password)

Il pannello admin è nascosto e richiede, oltre all'account Google con 2FA, **nome utente e password
separati**. Si creano solo dal SQL Editor (l'app non può farlo):

```sql
select public.admin_set_credentials('LA_TUA_EMAIL_GOOGLE', 'nome.utente', 'una-password-lunga-almeno-12-caratteri');
```

- L'email deve aver già fatto l'accesso all'app almeno una volta (punto 4.1).
- Nome utente: 4–32 caratteri tra lettere minuscole, numeri, `.` `_` `-`. Password: almeno 12
  caratteri (meglio una frase). Salvala in un gestore di password: nel database c'è solo l'impronta
  (bcrypt), nessuno può leggerla.
- Per cambiarla riesegui la stessa riga con la nuova password.

**Aprire il pannello.** Tab **Account** → sezione *Informazioni*, in fondo → **tieni premuto per 5
secondi** sul testo della versione (es. "HAPOSTO 0.9.0-dev (9) · DEV"; non c'è nessun segno
visibile) → compare "Area riservata" → nome utente e password.
Dopo 5 tentativi sbagliati il pannello si blocca per 15 minuti. La sessione del pannello dura
30 minuti ed è legata al telefono (un'altra sessione dello stesso account non la eredita).

Nel pannello: **Panoramica**, **Richieste** (rivendicazioni con codice telefonico), **Locali**
(modifica, sospensione, piano Pro regalato, membri), **Utenti** (sospensione, Plus regalato),
**Abbonamenti**, **Pagamenti**, **Registro** (tutte le operazioni sensibili), **Impostazioni**
(beta, sicurezza, versioni dei documenti legali).

### 4.3 Prova con due account (la prova più importante)

Ti servono un secondo account Google (il "ristoratore") e, se possibile, un secondo telefono.

1. Ristoratore: tab **Ristoratore** → accede con Google → accetta le condizioni per i ristoranti →
   attiva la 2FA (**Attiva adesso**) → cerca il locale → scrive telefono o email di lavoro →
   **È il mio locale: invia la richiesta**.
2. Tu (admin): pannello → **Richieste** → la richiesta → **Genera codice** → compare un codice a 6
   cifre. **Chiama il numero pubblico del locale** (non quello scritto nella richiesta!) e detta il
   codice. In prova, usa il tuo telefono.
3. Ristoratore: tab Ristoratore → la sua richiesta → campo *Codice ricevuto al telefono del locale*
   → **Conferma il codice**.
4. Admin: **Approva** con una nota. (Solo in casi eccezionali, es. verifica di persona: spunta
   *Approvo senza codice telefonico* e scrivi il motivo; resta nel registro.)
5. Ristoratore: tab Ristoratore → il locale → pubblica "C'è posto". Sul telefono del cliente (o
   nella versione Dev dello stesso telefono, tab Vicino) lo stato compare **subito** (tempo reale).
6. Prova di sicurezza: accedi con lo stesso account Google del ristoratore su un altro telefono
   e **non** inserire il codice a 6 cifre → la dashboard mostra l'avviso "serve la verifica in due
   passaggi" e ogni pubblicazione viene rifiutata dal server (`MFA_REQUIRED`).

Altre prove utili: dashboard → **Gestisci il locale** (piano, QR, adesivo PDF, orari, statistiche,
collaboratori, registro attività); tab Ristoratore → **Il mio locale non c'è: aggiungilo** (dati +
posizione sulla mappa → richiesta all'admin); Account → **Elimina account** con un account
di prova.

---

## Parte 5 — Notifiche push con Firebase (facoltativo)

Senza Firebase l'app funziona: i promemoria "come siete messi?" al ristoratore partono dal telefono
stesso. Firebase serve per gli **avvisi Plus** ("si è liberato un tavolo") e per le notifiche
mandate dal server.

1. <https://console.firebase.google.com> → **Aggiungi progetto** (piano Spark, gratuito; Analytics
   non necessario).
2. **Aggiungi app → Android**: package `com.haposto.dev` (poi di nuovo per `com.haposto`).
   Scarica `google-services.json` ma **non** metterlo nel progetto: ti servono solo 4 valori.
3. Da quel file (o da Impostazioni progetto → Le tue app) copia in `local.properties`:

   | `local.properties` | Dove si trova in `google-services.json` |
   |---|---|
   | `FIREBASE_DEV_APP_ID` | `client[].client_info.mobilesdk_app_id` |
   | `FIREBASE_DEV_API_KEY` | `client[].api_key[].current_key` |
   | `FIREBASE_DEV_PROJECT_ID` | `project_info.project_id` |
   | `FIREBASE_DEV_SENDER_ID` | `project_info.project_number` |

   (Per la produzione le stesse chiavi con `FIREBASE_PROD_…`.) Poi cancella il file scaricato.
4. **Impostazioni progetto → Account di servizio → Genera nuova chiave privata**: scarica il JSON
   (è un **segreto**). Lo userai solo al punto 6.2 e poi lo cancelli dal PC.

---

## Parte 6 — Edge Function e lavori pianificati

Le Edge Function sono in `supabase/functions/`. Ognuna verifica da sé chi la chiama (sessione
utente, segreto condiviso o firma di Stripe), quindi si pubblicano tutte con `--no-verify-jwt`.

| Funzione | Chi la chiama | Serve per |
|---|---|---|
| `push-dispatch` | pg_cron, ogni minuto | inviare la coda di notifiche con FCM |
| `play-verify` | l'app dopo un acquisto Plus | verificare l'acquisto con Google e attivare Plus |
| `play-rtdn` | Google Play (Pub/Sub) | rinnovi, disdette, rimborsi di Plus |
| `stripe-checkout` | il sito (titolare con 2FA) | pagina di pagamento Pro |
| `billing-portal` | il sito (titolare con 2FA) | cambiare carta, fatture, disdetta |
| `stripe-webhook` | Stripe | registrare abbonamenti e pagamenti Pro |

### 6.1 Pubblicazione (una volta, poi a ogni aggiornamento delle funzioni)

Serve Node.js (<https://nodejs.org>, versione LTS). Da un terminale nella cartella del progetto:

```bash
npx supabase login
npx supabase link --project-ref REF_DEV
npx supabase functions deploy push-dispatch --no-verify-jwt --use-api
npx supabase functions deploy play-verify --no-verify-jwt --use-api
npx supabase functions deploy play-rtdn --no-verify-jwt --use-api
npx supabase functions deploy stripe-checkout --no-verify-jwt --use-api
npx supabase functions deploy billing-portal --no-verify-jwt --use-api
npx supabase functions deploy stripe-webhook --no-verify-jwt --use-api
```

(`--use-api` evita di dover installare Docker.) Il riferimento `REF_DEV` è la parte iniziale
dell'indirizzo `https://REF_DEV.supabase.co`.

### 6.2 Segreti delle funzioni

Supabase → **Edge Functions → Secrets** (oppure `npx supabase secrets set NOME=valore`). Per i
valori casuali usa un generatore: PowerShell `-join ((48..57)+(97..102) | Get-Random -Count 48 | % {[char]$_})`
oppure <https://www.random.org/strings/>.

| Segreto | Valore | Serve a |
|---|---|---|
| `HAPOSTO_CRON_SECRET` | stringa casuale lunga (≥ 40 caratteri) | push-dispatch |
| `FIREBASE_SERVICE_ACCOUNT` | **tutto il contenuto** del JSON del punto 5.4 | push-dispatch |
| `HAPOSTO_SITE_URL` | `https://TUO_SITO` | Stripe (ritorno dal pagamento) |
| `HAPOSTO_ALLOWED_ORIGINS` | `https://TUO_SITO` (più origini separate da virgola) | sito → funzioni |
| `PLAY_PACKAGE_NAME` | `com.haposto.dev` in DEV, `com.haposto` in produzione | Plus |
| `PLAY_SERVICE_ACCOUNT` | JSON dell'account di servizio Play (Parte 7) | Plus |
| `PLAY_RTDN_TOKEN` | stringa casuale lunga | Plus |
| `STRIPE_SECRET_KEY` | chiave segreta Stripe (Parte 8) | Pro |
| `STRIPE_WEBHOOK_SECRET` | `whsec_…` (Parte 8) | Pro |
| `STRIPE_TAX_RATE_ID` | `txr_…` IVA 22% (facoltativo, Parte 8) | Pro |

Se il tuo progetto usa **solo** le nuove chiavi API (chiavi legacy disattivate), aggiungi anche
`HAPOSTO_SECRET_KEY` = la *secret key* (`sb_secret_…`) e `HAPOSTO_PUBLISHABLE_KEY` = la
*publishable key*. `SUPABASE_URL` e le chiavi legacy le fornisce Supabase da sé.

### 6.3 Lavori pianificati (pg_cron) e invio push

1. **Database → Extensions**: attiva `pg_cron` e `pg_net`.
2. SQL Editor, **una volta**, con i tuoi valori (non salvare questa query):
   ```sql
   select vault.create_secret('https://REF_DEV.supabase.co', 'haposto_project_url');
   select vault.create_secret('LO_STESSO_VALORE_DI_HAPOSTO_CRON_SECRET', 'haposto_cron_secret');
   ```
3. Esegui `supabase/ops/scheduled_jobs.sql` (promemoria, pulizie, scadenze, conservazione dati).
4. Esegui `supabase/ops/push_dispatch_cron.sql` (invio notifiche ogni minuto).
5. Prova: pubblica uno stato da un locale di cui un utente Plus di prova ha attivato l'avviso →
   entro un minuto arriva la notifica. Diagnosi: le query in fondo a `push_dispatch_cron.sql`.

---

## Parte 7 — Google Play: HAPOSTO Plus

1. **Play Console** (<https://play.google.com/console>, 25 $ una tantum) → **Crea app**: nome
   HAPOSTO, app gratuita. Carica una prima versione `prodRelease` firmata nel canale **Test interno**
   (Build → Generate Signed App Bundle; la chiave `.jks` conservala in 2 posti sicuri, **mai** su GitHub).
   Per provare Plus in DEV crea allo stesso modo un'app separata `com.haposto.dev` (facoltativo:
   puoi provare Plus direttamente sulla versione di produzione in Test interno).
2. **Monetizza → Prodotti → Abbonamenti → Crea abbonamento**: ID prodotto **`haposto_plus`**
   (esattamente così). Aggiungi due **piani base**: `mensile` (rinnovo automatico ogni mese,
   1,49 €) e `annuale` (ogni anno, 9,99 €). Facoltativo: un'offerta con prova gratuita di 7 giorni.
   Attiva i piani.
3. **Google Cloud** (stesso progetto del punto 2.1) → **APIs & Services → Library** → abilita
   **Google Play Android Developer API**.
4. **IAM & Admin → Service Accounts → Create**: nome `haposto-play`, nessun ruolo → apri l'account →
   **Keys → Add key → JSON** → il contenuto va nel segreto `PLAY_SERVICE_ACCOUNT` (poi cancella il file).
5. Play Console → **Utenti e autorizzazioni → Invita nuovi utenti** → l'email dell'account di
   servizio → autorizzazioni dell'app HAPOSTO: *Visualizzare dati finanziari* e *Gestire ordini e
   abbonamenti*.
6. **Notifiche in tempo reale** (rinnovi, disdette, rimborsi):
   - Google Cloud → **Pub/Sub → Topics → Create** `haposto-play-rtdn`; nel topic → **Permissions →
     Add principal** `google-play-developer-notifications@system.gserviceaccount.com` con ruolo
     **Pub/Sub Publisher**;
   - nel topic → **Create subscription** → tipo **Push** → endpoint
     `https://REF.supabase.co/functions/v1/play-rtdn?token=VALORE_DI_PLAY_RTDN_TOKEN`;
   - Play Console → **Monetizza → Configurazione della monetizzazione** → *Notifiche in tempo reale
     per lo sviluppatore* → nome del topic `projects/ID_PROGETTO_GCP/topics/haposto-play-rtdn` →
     **Invia notifica di prova** (la funzione risponde `ok: test`).
7. **Tester**: Play Console → **Impostazioni → Test delle licenze** → aggiungi i tuoi account Gmail:
   gli acquisti di prova non costano nulla e si rinnovano ogni pochi minuti.
8. Prova: installa l'app dal link del Test interno → Account → **HAPOSTO Plus** → abbonati → dopo
   la conferma compare "✓ Hai HAPOSTO Plus" (raggio 100 km, avvisi, "di solito"). Poi disdici da Play →
   Abbonamenti: alla scadenza Plus si spegne da solo.

---

## Parte 8 — Stripe: Pro per i ristoranti

Pro **si compra sul sito**, non nell'app (regole di Google Play sui pagamenti). Prima in
**modalità test** (interruttore "Test mode" in Stripe), poi dal vivo con gli stessi passi.

1. <https://dashboard.stripe.com> → crea l'account (gratis) e completa i dati dell'attività.
2. **Catalogo prodotti → Aggiungi prodotto** "HAPOSTO Pro" con due prezzi ricorrenti in EUR,
   comportamento fiscale **IVA esclusa**: 12,90 €/mese e 99 €/anno. Copia i due ID `price_…` e
   salvali nel database (SQL Editor):
   ```sql
   update public.plans
   set stripe_price_month = 'price_MENSILE', stripe_price_year = 'price_ANNUALE'
   where code = 'RESTAURANT_PRO';
   ```
3. **IVA**: Catalogo prodotti → *Aliquote fiscali* → nuova "IVA 22%", Italia, esclusa → copia
   `txr_…` nel segreto `STRIPE_TAX_RATE_ID`. (Casi particolari come clienti esteri: chiedi al
   commercialista.)
4. **Impostazioni → Fatturazione → Portale clienti**: attiva aggiornamento metodo di pagamento,
   cronologia fatture, **cancellazione a fine periodo**; inserisci i link a termini e privacy.
5. **Sviluppatori → Chiavi API**: crea una **chiave con restrizioni** (consigliato) con permessi di
   scrittura su *Customers*, *Checkout Sessions*, *Customer portal* e lettura su *Subscriptions*,
   *Invoices* → segreto `STRIPE_SECRET_KEY`.
6. **Sviluppatori → Webhook → Aggiungi endpoint**: URL
   `https://REF.supabase.co/functions/v1/stripe-webhook`, eventi `checkout.session.completed`,
   `customer.subscription.created`, `customer.subscription.updated`,
   `customer.subscription.deleted`, `invoice.paid`, `invoice.payment_failed` → copia il
   *Signing secret* `whsec_…` nel segreto `STRIPE_WEBHOOK_SECRET`.
7. Prova (modalità test), dal sito → area ristoratori, con un titolare con 2FA:
   dati di fatturazione → **Attiva Pro mensile** → carta `4242 4242 4242 4242`, data futura, CVC
   qualsiasi → torni sul sito → entro un minuto l'app mostra **Pro**. Poi prova
   `4000 0000 0000 0341` (pagamento rifiutato al rinnovo) e la disdetta da *Gestisci abbonamento*.
   Nel pannello admin → **Pagamenti** e **Abbonamenti** trovi tutto registrato.

Fatture elettroniche: all'inizio le emetti tu o il commercialista dall'elenco mensile dei pagamenti
(pannello admin → Pagamenti, oppure `supabase/ops/kpi_queries.sql`), con i dati di fatturazione del
locale (SDI o PEC).

---

## Parte 9 — Sito (gratis)

Il sito è in `web/`: home, **/ristoratori/** (login Google + 2FA, dati di fatturazione, Pro),
**/r/nome-del-locale** (pagina pubblica per i QR), **/privacy/**, **/termini/**,
**/termini-ristoranti/**, **/cookie/**, **/licenze/**, **/cancella-account/** (richiesta da Google
Play). Le pagine legali si generano dagli **stessi file** mostrati nell'app
(`app/src/main/assets/legal/`): si modifica un testo una volta sola.

**Cloudflare Pages (consigliato: gratis, funziona anche con repository privato):**

1. <https://dash.cloudflare.com> → **Workers & Pages → Create → Pages → Connect to Git** → il
   repository HAPOSTO, branch `main`.
2. *Build command* `node web/build.mjs` · *Build output directory* `web/dist`.
3. *Environment variables* (tutte **pubbliche**):
   `HAPOSTO_SITE_URL` (es. `https://haposto.pages.dev` o il tuo dominio),
   `HAPOSTO_SUPABASE_URL` (progetto di **produzione**), `HAPOSTO_SUPABASE_PUBLISHABLE_KEY`
   (**publishable**, mai la secret: la build si rifiuta di proseguire con una chiave segreta),
   `HAPOSTO_CONTACT_EMAIL`, `HAPOSTO_PLAY_URL` (quando l'app è sul Play Store).
4. **Custom domains** → il tuo dominio (facoltativo).
5. Aggiorna `PUBLIC_SITE_URL` in `local.properties` con lo stesso indirizzo (serve ai QR e ai link
   di condivisione) e gli indirizzi nei punti 2.1, 2.2, 2.4 e 6.2.

**In alternativa GitHub Pages** (repository pubblico): Settings → Pages → Source **GitHub Actions**;
Settings → Secrets and variables → Actions → **Variables**: le stesse variabili del punto 3 più
`HAPOSTO_DEPLOY_PAGES` = `true`. Il workflow `Website` pubblica a ogni modifica su `main`.

Prova in locale: `node web/build.mjs` e poi `npx serve web/dist -l 8080` → <http://localhost:8080>.

---

## Parte 10 — Progetto di produzione

1. Supabase → **New project** (regione UE, es. Frankfurt), password del database in un gestore
   di password.
2. SQL Editor: migration **0001–0004 e 0006–0013** in ordine (0005 no). **Non** caricare i seed di
   prova (`900_…`, `910_…`) né `supabase/dev/*`.
3. Directory dei locali reali: `supabase/ops/import_osm_overpass.sql` (istruzioni nel file).
4. Parte 2.3–2.4 sul progetto di produzione (stesso client Google Web: il redirect di produzione è
   già nella lista del punto 2.2).
5. Parte 4.2 (le tue credenziali admin sul progetto di produzione, **diverse** da quelle del DEV).
6. Parte 6 con `npx supabase link --project-ref REF_PROD` e i segreti di produzione
   (`PLAY_PACKAGE_NAME=com.haposto`, chiavi Stripe **live**, nuovo `HAPOSTO_CRON_SECRET`).
7. `local.properties`: `SUPABASE_PROD_URL`, `SUPABASE_PROD_PUBLISHABLE_KEY`, `FIREBASE_PROD_…`.
8. Beta: finché vuoi Pro gratis per tutti i locali, nel pannello admin → Impostazioni → `beta` →
   `restaurants_all_pro_until` con la data di fine beta.
9. Backup: con il piano gratuito esporta periodicamente le tabelle principali (Table Editor →
   Export CSV); con il piano Pro i backup sono giornalieri.

---

## Parte 11 — Procedure di tutti i giorni

**Approvare un ristoratore.** Pannello → Richieste → *Genera codice* → chiami il numero pubblico del
locale (Google Maps, sito del locale, insegna; **mai** quello scritto nella richiesta) → il
ristoratore inserisce il codice → *Approva*. Il codice vale 48 ore e 5 tentativi.

**Un ristoratore ha perso il telefono con l'app di autenticazione.** Verifica l'identità (telefonata
al numero pubblico del locale), poi SQL Editor:

```sql
-- toglie la 2FA: al prossimo accesso la riattiverà
delete from auth.mfa_factors where user_id = (select id from auth.users where email = 'EMAIL_DEL_RISTORATORE');
-- chiude tutte le sessioni aperte (telefono perso o rubato)
delete from auth.sessions where user_id = (select id from auth.users where email = 'EMAIL_DEL_RISTORATORE');
```

**Account sospetto o rubato.** Pannello → Utenti → l'utente → **Sospendi** (con motivo): non può più
pubblicare né gestire nulla; poi chiudi le sue sessioni con la seconda query qui sopra. Il registro
operazioni mostra cosa ha fatto e quando.

**Locale conteso o stati falsi.** Pannello → Locali → il locale → **Sospendi** (sparisce dall'app) o
togli il membro in questione.

**Hai modificato termini o privacy.** Aggiorna i file in `app/src/main/assets/legal/`, pubblica app e
sito, poi pannello → Impostazioni → `legal` → nuova versione (es. `2027-03`): al prossimo avvio
l'app chiede a tutti di riaccettare.

**Credenziali admin dimenticate.** Riesegui `admin_set_credentials` (punto 4.2) dal SQL Editor.

---

## Parte 12 — Test finali prima del lancio

Da fare sulla versione **prodRelease** installata dal canale Test interno di Google Play, con il
progetto di produzione.

**Cliente**
- [ ] Primo avvio: onboarding, permesso posizione (sì e no), zona manuale.
- [ ] Lista e **mappa**: pallini colorati, tocco su un locale → scheda; nessun locale "fantasma".
- [ ] Scheda: stato, orari, "di solito" (Plus), Indicazioni, Chiama, Condividi (link `/r/…` funziona).
- [ ] Preferiti senza account; con account si sincronizzano su un secondo telefono.
- [ ] Offline: messaggio chiaro, nessun blocco.

**Ristoratore**
- [ ] Rivendicazione con codice telefonico, approvazione, pubblicazione dei 3 stati, dettagli (Pro).
- [ ] Senza codice 2FA non si pubblica; con account sospeso nemmeno.
- [ ] Promemoria dopo 25 minuti con i tasti rapidi (funzionano a telefono bloccato).
- [ ] QR: PNG e adesivo PDF stampato, scansione → pagina pubblica con lo stato giusto.
- [ ] Orari, collaboratore aggiunto e rimosso, registro attività, statistiche.

**Pagamenti**
- [ ] Plus: acquisto di prova, rinnovo, disdetta, ripristino su un altro telefono.
- [ ] Pro: pagamento (carta di prova, poi un pagamento reale di 1 mese), portale, disdetta,
      rinnovo fallito → dopo 3 giorni torna Basic.

**Admin e sicurezza**
- [ ] Gesto segreto, blocco dopo 5 password sbagliate, scadenza dopo 30 minuti.
- [ ] Un secondo account **non** vede né modifica i locali altrui: la sua richiesta su un locale già
      gestito resta in attesa e, senza il codice dettato al telefono del locale, non viene approvata.
- [ ] Cancellazione account dall'app e richiesta dal sito `/cancella-account/`.

**Pubblicazione**
- [ ] Privacy, termini, condizioni ristoranti, cookie **rivisti da un avvocato** e con i dati
      reali al posto delle parti tra parentesi quadre.
- [ ] Scheda Play: *Data safety* coerente con la privacy (posizione approssimativa non salvata,
      email e id account, acquisti, token notifiche), link di cancellazione account, classificazione.
- [ ] CI verde su `main`; versione (`versionCode`/`versionName`) aumentata a ogni caricamento.
