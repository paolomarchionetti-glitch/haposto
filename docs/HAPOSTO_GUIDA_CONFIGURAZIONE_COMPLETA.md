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
| 1 | Database DEV: migration 0012–0013 e tempo reale (0005) | 10 min | tutto |
| 2 | Login: Google in Supabase + 2FA | 20 min | account, ristoratori, admin |
| 3 | Android Studio: `local.properties` e versioni | 10 min | provare l'app |
| 4 | Diventa amministratore e prova il flusso ristoratore | 20 min | pannello admin |
| 5 | Notifiche push (Firebase) — facoltativo | 20 min | avvisi Plus, promemoria da server |
| 6 | Edge Function e lavori pianificati | 20 min | push, Plus, Pro |
| 7 | Google Play: HAPOSTO Plus | 1–2 ore | abbonamento utenti |
| 8 | Stripe: Pro per i ristoranti | 1 ora | abbonamento ristoranti |
| 9 | Sito (gratis) | 20 min | privacy, termini, QR, pagamento Pro |
| 10 | Progetto di produzione | 1–2 ore | lancio |
| 11 | Procedure di tutti i giorni (admin, 2FA perse, sospensioni) | — | gestione |
| 12 | Test finali prima del lancio | 2–3 ore | lancio |

**Costi.** Supabase (piano Free), Firebase Cloud Messaging, MapLibre + OpenFreeMap (mappe),
Google Sign-In, Cloudflare Pages/GitHub Pages, Pub/Sub (entro la quota gratuita) sono **gratuiti**.
Si paga solo: l'iscrizione a Google Play Console (**25 $ una tantum**, obbligatoria per pubblicare
sul Play Store), le commissioni sulle vendite (Google 15% su Plus, Stripe ~1,5% + 0,25 € su Pro) e,
se lo vuoi, un dominio (~10–15 €/anno; senza dominio il sito resta su `*.pages.dev`, gratis).

---

## Parte 1 — Database DEV: migration 0012, 0013 e tempo reale (0005)

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
| 3 | `supabase/migrations/0005_realtime_future.sql` | **tempo reale**: gli stati pubblicati compaiono sugli altri telefoni in 1–2 secondi (senza, entro 1 minuto) | `select tablename from pg_publication_tables where pubname = 'supabase_realtime';` | `restaurant_live_status` |

I tre file sono **rieseguibili**. Se ricevi un errore, fermati e mandami la riga dell'errore.

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

`REF_DEV` è la parte iniziale dell'indirizzo del progetto DEV (`https://REF_DEV.supabase.co`,
lo trovi anche nell'indirizzo del browser nella dashboard di Supabase).

1. <https://console.cloud.google.com> → crea un progetto **HAPOSTO** (puoi usare lo stesso di Firebase).
2. **Google Auth Platform** (menu ☰ → *APIs & Services → OAuth consent screen* porta lì) → **Get started**:
   nome app **HAPOSTO**, email di assistenza, pubblico **External**, email di contatto → **Create**.
3. **Branding**:
   - logo: **per ora no** (caricare un logo obbliga a far verificare l'app da Google);
   - *Authorized domains*: `REF_DEV.supabase.co` (in Parte 10 anche `REF_PROD.supabase.co`).
     **Non** `supabase.co`: è un dominio condiviso tra tutti i progetti e Google lo rifiuta;
   - home page, link a privacy e termini e dominio del sito: **quando il sito esiste** (Parte 9):
     `https://TUO_SITO/`, `https://TUO_SITO/privacy/`, `https://TUO_SITO/termini/`, e il dominio tra
     gli *Authorized domains* (es. `haposto.app`; senza dominio tuo l'indirizzo completo
     `haposto.pages.dev`, perché anche `pages.dev` è condiviso).
4. **Data Access**: non serve aggiungere nulla: l'app chiede solo `openid`, `email`, `profile`
   (non richiedono verifica di Google).
5. **Audience**: finché l'app è in *Testing* possono entrare **solo** gli account elencati in
   **Test users** → **Add users**: il tuo Gmail e quello che userai come "ristoratore" di prova
   (Parte 4). Al lancio → **Publish app**.

### 2.2 Google Cloud: ID client

**Google Auth Platform → Clients → Create client** (oppure *APIs & Services → Credentials →
Create credentials → OAuth client ID*):

| Quando | Tipo | Nome | Dati da inserire | A cosa serve |
|---|---|---|---|---|
| ora | **Web application** | HAPOSTO Web | *Authorized redirect URIs*: `https://REF_DEV.supabase.co/auth/v1/callback` (è la *Callback URL* mostrata da Supabase al punto 2.3; in Parte 10 aggiungi `https://REF_PROD.supabase.co/auth/v1/callback`). *Authorized JavaScript origins*: nessuna (il sito passa da Supabase) | È il `GOOGLE_WEB_CLIENT_ID` dell'app e il login del sito |
| ora | **Android** | HAPOSTO Dev | package `com.haposto.dev` · SHA-1 del certificato di debug | fa comparire la finestra di Google nell'app Dev |
| Parte 10 | **Android** | HAPOSTO (debug) | package `com.haposto` · lo stesso SHA-1 di debug di *HAPOSTO Dev* | la versione `prodDebug` sul tuo telefono |
| Parte 7 | **Android** | HAPOSTO | package `com.haposto` · SHA-1 della chiave di caricamento **e** (dopo il primo caricamento su Play, un altro client) SHA-1 della chiave di firma di Google Play | app di produzione pubblicata |

Come trovare lo SHA-1 di debug: Android Studio → **Terminal** (in basso) → `.\gradlew signingReport`
su Windows (`./gradlew signingReport` su Mac/Linux) → nel blocco `Variant: devDebug` la riga `SHA1:`
(tutte le varianti debug usano lo stesso certificato del PC). Per Play: Play Console → la tua app →
**Test and release → App integrity → App signing** → "SHA-1 certificate fingerprint".

Del client *Web* ti servono **Client ID** e **Client secret** (punto 2.3). Il secret compare solo
alla creazione: copialo subito in Supabase o nel gestore di password, mai in chat o su GitHub.

### 2.3 Supabase: provider Google

Supabase (DEV) → **Authentication → Sign In / Providers → Google** → **Enable Sign in with Google**:

- **Client IDs**: il Client ID *Web* (una sola riga);
- **Client Secret (for OAuth)**: il secret del client *Web*;
- **Skip nonce checks**: **disattivato** (l'app manda il nonce: è una protezione in più);
- **Callback URL (for OAuth)**: è l'indirizzo da mettere tra gli *Authorized redirect URIs* (2.2);
- **Save**.

Sempre in **Sign In / Providers**: disattiva **Email** (e ogni altro provider) — in HAPOSTO si
entra solo con Google, così non esistono password deboli da indovinare. Gli utenti di prova
`test-…@haposto.test` restano: servono solo agli script di controllo, che non fanno accessi.

### 2.4 Supabase: verifica in due passaggi e indirizzi

- **Authentication → Multi-Factor**: *TOTP (App Authenticator)* **Enabled**; *Phone* disattivato.
- **Authentication → URL Configuration** (serve solo al sito, l'app non la usa): **quando il sito
  esiste** (Parte 9) *Site URL* `https://TUO_SITO` e tra le *Redirect URLs*
  `https://TUO_SITO/ristoratori/`; per provare il sito sul PC anche `http://localhost:8080/ristoratori/`.
- **Authentication → Rate Limits**: lascia i valori predefiniti.

---

## Parte 3 — Android Studio: chiavi e versioni

0. Progetto aggiornato: Android Studio → **Git → Pull…** (ramo `main`), oppure scarica di nuovo lo
   ZIP da GitHub in una cartella nuova e **copia lì il tuo `local.properties`**. Se in
   *Build Variants* vedi solo `debug` e `release` il progetto è vecchio: mancano le versioni
   demo/dev/prod.
1. `local.properties` è nella cartella principale del progetto (in Android Studio: vista
   **Android** → *Gradle Scripts* → `local.properties (SDK Location)`); **non** va su GitHub.
   - **Se esiste già** (con `sdk.dir` e, dallo Step 7, `SUPABASE_URL` / `SUPABASE_PUBLISHABLE_KEY`):
     **non** sovrascriverlo con l'esempio. Le due chiavi vecchie valgono ancora per la versione Dev;
     aggiungi solo la riga del client *Web* della Parte 2:
     ```properties
     GOOGLE_WEB_CLIENT_ID=....apps.googleusercontent.com
     ```
   - **Se non esiste**: copia `local.properties.example` in `local.properties` e compila:
     ```properties
     SUPABASE_DEV_URL=https://REF_DEV.supabase.co
     SUPABASE_DEV_PUBLISHABLE_KEY=sb_publishable_...
     GOOGLE_WEB_CLIENT_ID=....apps.googleusercontent.com
     ```
     Le righe con `#` davanti (produzione, Firebase, firma) restano così finché non arrivi alle
     rispettive parti: un valore inventato è peggio di un valore mancante.

   La chiave è in Supabase → **Project Settings → API Keys → Publishable key** (mai la *secret*).
   Valori senza virgolette e senza spazi.
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
- L'SQL Editor **salva da solo** ogni query nell'elenco a sinistra (*Private*): dopo il *Run*
  cancella la password dal testo o elimina la query (**⋯ → Delete query**).
- Errori possibili: `USER_NOT_REGISTERED` (quell'email non ha ancora fatto l'accesso all'app, punto
  4.1), `INVALID_USERNAME`, `PASSWORD_TOO_SHORT`, `CONSOLE_ONLY` (in alto a destra nell'editor il
  ruolo dev'essere `postgres`, non un utente).

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

Ti servono un secondo account Google (il "ristoratore", presente nei *Test users* del punto 2.1) e,
se possibile, un secondo telefono. Sul DEV con il simulatore attivo riesegui prima
`supabase/dev/dev_tools.sql`: la versione aggiornata non tocca più i locali rivendicati da un
account vero, così lo stato che pubblichi resta il tuo.

**Un solo telefono?** Il secondo telefono può essere un emulatore di Android Studio (gratis):
**Tools → Device Manager → +** → un Pixel con immagine **Google Play** (API 34 o 35) → avvialo →
Impostazioni → *Google* / *Account* → aggiungi l'account del ristoratore → in alto scegli
l'emulatore accanto a ▶ e premi **Run** con `devDebug` (stessa firma di debug del PC: il client
Android della Parte 2 vale anche lì). Il QR della verifica in due passaggi compare sullo schermo
del PC: inquadralo con Authenticator del tuo telefono. Telefono = admin, emulatore = ristoratore.
Senza emulatore si fa tutto sullo stesso telefono alternando gli account: **Account → Esci** e
rientra con l'altro (non toccare *Elimina account*, subito sotto). A ogni rientro l'app chiede il
codice di Authenticator della voce con **quell'email** e il pannello admin va riaperto; solo il
tempo reale fra due telefoni resta da provare con un secondo dispositivo.

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
   nella versione Dev dello stesso telefono, tab Vicino) lo stato compare in 1–2 secondi (tempo
   reale, migration 0005 della Parte 1; senza, entro 1 minuto).
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

1. <https://console.firebase.google.com> → crea un progetto e, in fondo alla prima schermata,
   scegli **Aggiungi Firebase a un progetto Google Cloud** → il progetto della Parte 2 (così login,
   notifiche e Play restano nello stesso progetto). Piano **Spark** (gratuito); Google Analytics
   **disattivato** (non serve).
2. **Panoramica del progetto → + Aggiungi app → Android**: package `com.haposto.dev`, nickname
   `HAPOSTO Dev`, SHA-1 facoltativo → **Registra app** → scarica `google-services.json` ma **non**
   metterlo nel progetto: ti servono solo 4 valori. I passi successivi della procedura guidata
   (plugin e SDK) saltali con **Avanti**: l'app li ha già. (L'app `com.haposto` si aggiunge in Parte 10.)
3. Apri `google-services.json` con il Blocco note e copia in `local.properties`
   (se hai usato l'esempio, togli il `#` davanti alle righe `FIREBASE_DEV_…`):

   | `local.properties` | Dove si trova in `google-services.json` | Aspetto |
   |---|---|---|
   | `FIREBASE_DEV_APP_ID` | `client[].client_info.mobilesdk_app_id` | `1:123…:android:abc…` |
   | `FIREBASE_DEV_API_KEY` | `client[].api_key[].current_key` | `AIza…` |
   | `FIREBASE_DEV_PROJECT_ID` | `project_info.project_id` | l'ID del progetto |
   | `FIREBASE_DEV_SENDER_ID` | `project_info.project_number` | solo cifre |

   (Per la produzione le stesse chiavi con `FIREBASE_PROD_…`.) Poi cancella il file scaricato.
   **Sync** e **▶ Run** con `devDebug`.
4. Verifica:
   - telefono → Impostazioni → App → **HAPOSTO Dev** → **Notifiche**: consentite;
   - nell'app esci e rientra con il tuo account; poi Supabase → SQL Editor:
     `select platform, app_version, last_seen_at from public.device_push_tokens order by last_seen_at desc limit 3;`
     → una riga con l'ora di adesso (il telefono è registrato per le notifiche);
   - prova di consegna (facoltativa): Table Editor → `device_push_tokens` → copia il `token` →
     Firebase → **Messaging** → nuova campagna **Notifiche** → titolo e testo → **Invia messaggio
     di prova** → incolla il token → **Prova**, con l'app chiusa: la notifica arriva in pochi secondi.
5. La chiave dell'account di servizio (un **segreto**) **non** crearla ora: serve solo al punto 6.2.

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
| `restaurant-file` | l'app (titolare con 2FA) e pg_cron, ogni notte | foto o PDF del menù: controllo, caricamento, pulizia |

### 6.1 Pubblicazione (una volta, poi a ogni aggiornamento delle funzioni)

Serve Node.js (<https://nodejs.org>, versione LTS). Dal terminale nella cartella del progetto (in
Android Studio: **Terminal**, in basso, è già nella cartella giusta):

```bash
npx supabase login
npx supabase link --project-ref REF_DEV
npx supabase functions deploy push-dispatch --no-verify-jwt --use-api
npx supabase functions deploy play-verify --no-verify-jwt --use-api
npx supabase functions deploy play-rtdn --no-verify-jwt --use-api
npx supabase functions deploy stripe-checkout --no-verify-jwt --use-api
npx supabase functions deploy billing-portal --no-verify-jwt --use-api
npx supabase functions deploy stripe-webhook --no-verify-jwt --use-api
npx supabase functions deploy restaurant-file --no-verify-jwt --use-api
```

- `login` apre il browser: accedi a Supabase e conferma. Se `link` chiede la password del database
  premi **Invio** (non serve per le funzioni).
- `--use-api` evita di dover installare Docker. `REF_DEV` è la parte iniziale dell'indirizzo
  `https://REF_DEV.supabase.co`.
- Si possono pubblicare tutte subito: finché mancano i loro segreti (Parti 7–9) ogni funzione
  rifiuta le chiamate.
- Controllo: Supabase → **Edge Functions** → compaiono le 7 funzioni.
- Dopo un aggiornamento del repository che tocca `supabase/functions/` ripubblica le funzioni
  cambiate (rieseguire il comando di una funzione già pubblicata la sostituisce; nel dubbio
  ripubblicale tutte).

### 6.2 Segreti delle funzioni

Supabase → **Edge Functions → Secrets** (oppure `npx supabase secrets set NOME=valore`). Per i
valori casuali usa il generatore del gestore di password (48 caratteri, solo lettere e numeri)
oppure PowerShell, che scrive 48 caratteri esadecimali presi dal generatore crittografico di Windows:

```powershell
$b = New-Object byte[] 24; [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($b); -join ($b | ForEach-Object { $_.ToString('x2') })
```

| Segreto | Valore | Serve a | Quando |
|---|---|---|---|
| `HAPOSTO_CRON_SECRET` | stringa casuale lunga (≥ 40 caratteri) | push-dispatch | ora |
| `FIREBASE_SERVICE_ACCOUNT` | **tutto il contenuto** del JSON scaricato da Firebase → Impostazioni progetto → **Account di servizio** → **Genera nuova chiave privata** (poi cancella il file dal PC) | push-dispatch | ora |
| `HAPOSTO_SITE_URL` | `https://TUO_SITO` | Stripe (ritorno dal pagamento) | Parte 9 |
| `HAPOSTO_ALLOWED_ORIGINS` | `https://TUO_SITO` (più origini separate da virgola) | sito → funzioni | Parte 9 |
| `PLAY_PACKAGE_NAME` | `com.haposto.dev` in DEV, `com.haposto` in produzione | Plus | Parte 7 |
| `PLAY_SERVICE_ACCOUNT` | JSON dell'account di servizio Play (Parte 7) | Plus | Parte 7 |
| `PLAY_RTDN_TOKEN` | stringa casuale lunga | Plus | Parte 7 |
| `STRIPE_SECRET_KEY` | chiave segreta Stripe (Parte 8) | Pro | Parte 8 |
| `STRIPE_WEBHOOK_SECRET` | `whsec_…` (Parte 8) | Pro | Parte 8 |
| `STRIPE_TAX_RATE_ID` | `txr_…` IVA 22% (facoltativo, Parte 8) | Pro | Parte 8 |

`SUPABASE_URL` e le chiavi del server le fornisce Supabase da sé, anche nei progetti senza chiavi
*legacy* (`anon`, `service_role`): le funzioni usano la *secret key* `default` che Supabase passa
loro. **Non** copiare la *secret key* nei segreti. (`HAPOSTO_SECRET_KEY` / `HAPOSTO_PUBLISHABLE_KEY`,
se li avevi aggiunti, restano validi e hanno la precedenza; non servono più.)

### 6.3 Lavori pianificati (pg_cron) e invio push

1. **Database → Extensions**: attiva `pg_cron` e `pg_net`.
2. SQL Editor, **una volta**, con i tuoi valori (indirizzo **senza** `/` finale):
   ```sql
   select vault.create_secret('https://REF_DEV.supabase.co', 'haposto_project_url');
   select vault.create_secret('LO_STESSO_VALORE_DI_HAPOSTO_CRON_SECRET', 'haposto_cron_secret');
   ```
   Poi elimina la query dall'elenco a sinistra (**⋯ → Delete query**): l'editor la salva da solo e
   contiene il segreto. Per cambiare un valore: `select vault.update_secret(id, 'nuovo valore')`
   con l'`id` preso da `select id, name from vault.secrets;`.
3. Esegui `supabase/ops/scheduled_jobs.sql` (promemoria, pulizie, scadenze, conservazione dati).
4. Esegui `supabase/ops/push_dispatch_cron.sql` (invio notifiche ogni minuto): in fondo deve
   comparire `haposto-push-dispatch` con `active = true`.
5. Esegui `supabase/ops/restaurant_files_cron.sql` (ogni notte toglie le foto "solo per oggi"
   scadute e i file che nessun locale usa più): in fondo deve comparire
   `haposto-restaurant-files-cleanup` con `active = true`. Serve la funzione `restaurant-file`
   pubblicata (6.1) e la migration 0015. I tre file sono rieseguibili.
6. Prova. Prima apri **HAPOSTO Dev** ed entra con il tuo account: il telefono si registra per le
   notifiche solo quando nell'app c'è un account collegato. Poi chiudi l'app **scorrendola via dalle
   app recenti** (non con *Forza interruzione* né con lo Stop di Android Studio: un'app "fermata"
   non riceve notifiche finché non la riapri). Infine, con il tuo indirizzo email:
   ```sql
   insert into public.notification_outbox (user_id, kind, title, body)
   select id, 'CLAIM_UPDATE', 'Prova HAPOSTO', 'Le notifiche dal server funzionano'
   from auth.users where email = 'LA_TUA_EMAIL';
   ```
   Entro un minuto arriva la notifica. Controllo e diagnosi:
   ```sql
   select kind, attempts, sent_at, last_error from public.notification_outbox order by id desc limit 5;
   select status_code, content, created from net._http_response order by created desc limit 5;
   ```
   `sent_at` compilato = notifica chiusa (non per forza arrivata). Nelle risposte:
   `"delivered":1` = arrivata al telefono; `"no_device":1` = per quell'account non c'è nessun
   telefono registrato (apri l'app ed entra con quell'account, poi riprova); `401 UNAUTHORIZED` =
   i due valori del segreto (funzione e vault) sono diversi; `500 NOT_CONFIGURED` = manca un
   segreto della funzione; `500 DATABASE_ERROR` = permessi del database (migration 0014, Parte
   10.2) o chiavi del server (fine del 6.2); `502 GOOGLE_AUTH_FAILED` = JSON di Firebase non valido
   o incompleto. Registrazioni del telefono per un account (senza mostrare il token):
   ```sql
   select t.platform, t.app_version, t.last_seen_at
   from public.device_push_tokens t join auth.users u on u.id = t.user_id
   where u.email = 'LA_TUA_EMAIL';
   ```

### 6.4 Ping automatico contro la pausa (GitHub Actions, gratis)

Un progetto Supabase Free senza attività per 7 giorni va in pausa. Il workflow
`.github/workflows/supabase-keepalive.yml` fa ogni mattina una lettura su ogni progetto configurato
(un piano pubblico, con la chiave *publishable*: nessun dato personale, nessuna scrittura). Il
workflow parte solo dopo che il file è su `main`.

1. GitHub → repository `haposto` → **Settings → Secrets and variables → Actions** → scheda
   **Secrets** → **New repository secret**, una volta per riga:

   | Name | Secret |
   |---|---|
   | `SUPABASE_DEV_URL` | `https://REF_DEV.supabase.co` |
   | `SUPABASE_DEV_PUBLISHABLE_KEY` | la *publishable key* del DEV (Supabase → **Project Settings → API Keys**) |

   Usa **Secrets**, non *Variables*: così l'indirizzo del progetto non compare nei registri pubblici.
2. Prova subito: **Actions** → **Supabase keep-alive** → **Run workflow** → **Run workflow**. Dopo un
   minuto compare il segno verde; aprendo l'esecuzione c'è la riga `DEV: ok`.
3. Per la produzione (Parte 10) aggiungi anche `SUPABASE_PROD_URL` e `SUPABASE_PROD_PUBLISHABLE_KEY`.

- Se la lettura non riesce (progetto già in pausa, chiave sbagliata) il workflow diventa rosso e
  GitHub manda un'email: Supabase → il progetto → **Restore project**.
- GitHub spegne i workflow pianificati dopo 60 giorni senza modifiche al repository (avvisa per
  email): **Actions → Supabase keep-alive → Enable workflow**.
- È una pratica diffusa, non una funzione ufficiale di Supabase: se un giorno non bastasse, il
  progetto si riattiva comunque gratis e senza perdere dati.

---

## Parte 7 — Google Play: HAPOSTO Plus

1. **Play Console** (<https://play.google.com/console>, 25 $ una tantum) → **Crea app**: nome
   HAPOSTO, app gratuita. Carica una prima versione `prodRelease` firmata nel canale **Test interno**
   (Build → Generate Signed App Bundle; la chiave `.jks` conservala in 2 posti sicuri, **mai** su GitHub).
   Per provare Plus in DEV crea allo stesso modo un'app separata `com.haposto.dev` (facoltativo:
   puoi provare Plus direttamente sulla versione di produzione in Test interno).
2. **Monetizza → Prodotti → Abbonamenti → Crea abbonamento**: ID prodotto **`haposto_plus`**
   (esattamente così). Aggiungi tre **piani base** (prezzi IVA inclusa, decisi il 2 ottobre 2026 e
   uguali a quelli nel database): `mensile` (rinnovo automatico ogni mese, 0,99 €), `semestrale`
   (ogni 6 mesi, 4,99 €) e `annuale` (ogni anno, 9,99 €). L'app mostra da sola i piani attivi.
   Facoltativo: un'offerta con prova gratuita di 7 giorni. Attiva i piani.
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
2. **Catalogo prodotti → Aggiungi prodotto** "HAPOSTO Pro" con tre prezzi ricorrenti in EUR,
   comportamento fiscale **IVA inclusa** (gli stessi della migration 0016): 19,90 € ogni mese,
   99,90 € ogni **6 mesi** (periodo personalizzato: ogni 6 mesi) e 199,90 € ogni anno. Copia i tre
   ID `price_…` e salvali nel database (SQL Editor):
   ```sql
   update public.plans
   set stripe_price_month = 'price_MENSILE', stripe_price_semester = 'price_SEMESTRALE',
       stripe_price_year = 'price_ANNUALE'
   where code = 'RESTAURANT_PRO';
   ```
   Se un giorno cambi i prezzi, crea prezzi nuovi su Stripe, aggiorna gli ID qui sopra e gli
   importi in `public.plans` (`price_month_cents`, `price_semester_cents`, `price_year_cents`):
   il sito li legge da lì. Chi è già abbonato resta al prezzo vecchio finché non cambia piano.
3. **IVA**: Catalogo prodotti → *Aliquote fiscali* → nuova "IVA 22%", Italia, **inclusa nel
   prezzo** → copia `txr_…` nel segreto `STRIPE_TAX_RATE_ID`. (Casi particolari come clienti
   esteri: chiedi al commercialista.)
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

Il sito va servito alla **radice** di un indirizzo (`https://indirizzo/`): link, pagine `/r/…` dei
QR e ritorno dal login con Google partono da `/`. Per questo si usa **Cloudflare Pages**
(`nome.pages.dev`, gratis, senza carta, anche con repository privato). GitHub Pages va bene solo con
un **dominio tuo**: senza, il sito finirebbe in `utente.github.io/haposto/` e grafica, QR e login
non funzionerebbero.

Finché il progetto di produzione non esiste (Parte 10) il sito usa il progetto **DEV**; poi si
cambiano due variabili. L'indirizzo `.pages.dev` può essere provvisorio (es. `haposto-test`): il
dominio definitivo si aggiunge dopo.

### 9.1 Account Cloudflare

1. <https://dash.cloudflare.com/sign-up> → email e password, oppure **Sign up with Google** → conferma
   l'email dal link ricevuto. Piano **Free**: se compare una richiesta di pagamento, fermati.
2. Proposte di "aggiungere un dominio": salta.
3. Sicurezza: se entri con Google non esiste una password Cloudflare; basta la **verifica in due
   passaggi dell'account Google** (<https://myaccount.google.com/security>). Con email e password
   attiva invece la 2FA di Cloudflare: profilo → **Autenticazione** → *App per dispositivi mobili*.

### 9.2 Progetto Pages collegato a GitHub

1. **Workers & Pages** (a volte dentro *Compute (Workers)*) → **Create**: la pagina propone prima i
   *Workers*; scegli la scheda **Pages** (o il link *Looking to deploy Pages? Get started*) →
   **Import an existing Git repository** → **Connect GitHub**.
2. Su GitHub l'app *Cloudflare Workers and Pages*: **Only select repositories** → `haposto` →
   **Install & Authorize**. Poi su Cloudflare scegli il repository → **Begin setup**.
3. Impostazioni:

   | Campo | Valore |
   |---|---|
   | Project name | es. `haposto-test` (diventa `haposto-test.pages.dev`) |
   | Production branch | `main` |
   | Framework preset | **None** |
   | Build command | `node web/build.mjs` |
   | Build output directory | `web/dist` |
   | Root directory | vuoto |

4. **Environment variables** (tutte **pubbliche**: finiscono nelle pagine del sito):

   | Variabile | Valore |
   |---|---|
   | `NODE_VERSION` | `22` |
   | `HAPOSTO_SITE_URL` | `https://haposto-test.pages.dev` (l'indirizzo del sito) |
   | `HAPOSTO_SUPABASE_URL` | `https://REF_DEV.supabase.co` (in Parte 10: produzione) |
   | `HAPOSTO_SUPABASE_PUBLISHABLE_KEY` | chiave **publishable** dello stesso progetto (mai la secret: la build si rifiuta) |
   | `HAPOSTO_CONTACT_EMAIL` | email di assistenza, **visibile** sul sito |
   | `HAPOSTO_PLAY_URL` | link a Google Play, quando l'app ci sarà |

5. **Save and Deploy** → dopo circa un minuto "Success". Controlla l'indirizzo assegnato: se il nome
   era preso Cloudflare aggiunge delle lettere; in quel caso correggi `HAPOSTO_SITE_URL`
   (**Settings → Variables and Secrets**) e **Deployments → ⋯ → Retry deployment**.
6. Facoltativo: **Settings → Builds → Branch control** → *Preview branch* **None**. Altrimenti ogni
   branch di lavoro crea un'anteprima pubblica (`nome-branch.haposto-test.pages.dev`) e il bot di
   Cloudflare la segnala nelle PR.

Da qui il sito si ripubblica da solo a ogni modifica unita su `main`.

### 9.3 Controllo

- `https://haposto-test.pages.dev` → home; in fondo **Privacy** e **Termini** (gli stessi testi dell'app).
- Pagina di un locale: SQL Editor
  `select name, slug from public.restaurants where partnership_status = 'ACTIVE_PARTNER' order by name limit 3;`
  → `https://haposto-test.pages.dev/r/SLUG` → nome e stato del locale.

### 9.4 Collegamenti con il resto

1. **Supabase → Authentication → URL Configuration**: *Site URL* `https://haposto-test.pages.dev`;
   *Redirect URLs* → **Add URL** → `https://haposto-test.pages.dev/ristoratori/`.
2. **Google Cloud → Branding** (<https://console.cloud.google.com/auth/branding>, progetto della
   Parte 2; in italiano: *Piattaforma di autenticazione Google → Branding*): *Home page
   dell'applicazione* `https://haposto-test.pages.dev/`, *Link alle norme sulla privacy*
   `…/privacy/`, *Link ai Termini di servizio* `…/termini/`; *Domini autorizzati* → **Aggiungi
   dominio** `haposto-test.pages.dev` (il dominio `….supabase.co` resta) → **Salva**.
3. **Supabase → Edge Functions → Secrets**: `HAPOSTO_SITE_URL` e `HAPOSTO_ALLOWED_ORIGINS` =
   `https://haposto-test.pages.dev` (servono a Pro, Parte 8).
4. **App**: `PUBLIC_SITE_URL=https://haposto-test.pages.dev` in `local.properties` → **Sync** →
   **▶ Run** (QR, condivisione e link legali puntano al sito).

### 9.5 Prove

1. **Area ristoratori**: `https://haposto-test.pages.dev/ristoratori/` → **Accedi con Google** →
   scegli l'account del **ristoratore** (Google chiede sempre quale usare; con un solo browser
   collegato al tuo account admin si può usare una finestra in incognito).
   - "Continua su `….supabase.co`" è normale: il login del sito passa dal progetto Supabase.
   - "Google non ha verificato questa app" → **Continua** (app in prova). "Accesso bloccato" = l'account
     non è tra i *Test users* (Parte 2.1).
   - Codice di Authenticator della voce con **l'email mostrata** sulla pagina ("Account: …").
   - Compaiono il locale, il piano, le condizioni e i dati di fatturazione. Prova facoltativa: salva
     dati di fatturazione di prova (Partita IVA di 11 cifre, codice SDI di 7 caratteri). **Non**
     attivare Pro prima della Parte 8. Con un account senza locali: "Nessun locale di cui sei titolare".
2. **QR dall'app**: app Dev come ristoratore → **Gestisci il locale** → *QR e link del locale*:
   sotto il QR `haposto-test.pages.dev/r/…`. **Condividi il link** → Chrome → pagina del locale con lo
   stato attuale. Con un solo telefono, **Condividi il QR (immagine)** → aprila sullo schermo del PC
   e inquadrala con la fotocamera. **Crea l'adesivo da stampare (PDF)** apre l'adesivo.

**Dominio definitivo** (quando avrai il nome): Cloudflare → progetto → **Custom domains**, poi
aggiorna lo stesso indirizzo in `HAPOSTO_SITE_URL`, nei punti 9.4.1–9.4.4 e nei QR già stampati.

Prova in locale: `node web/build.mjs` e poi `npx serve web/dist -l 8080` → <http://localhost:8080>.

---

## Parte 10 — Progetto di produzione

Il progetto di produzione è un **secondo progetto Supabase**, sempre sul piano **Free** (gratis: il
piano Free ammette due progetti attivi, DEV e produzione). Si rifà quello che hai fatto sul DEV,
**senza** dati di prova. `REF_PROD` è la parte iniziale dell'indirizzo del nuovo progetto
(`https://REF_PROD.supabase.co`). Le chiavi e i segreti di produzione sono **nuovi** (mai quelli del
DEV); restano gli stessi solo il client Google *Web*, il progetto Google Cloud/Firebase e il sito.

> Novità di Supabase per i progetti creati nel 2026, già gestite dal codice: **niente chiavi
> legacy** (`anon`, `service_role`: ci sono solo *publishable* e *secret*) e tabelle **non più
> aperte in automatico** alle API. La migration 0014 dà i permessi in modo esplicito e le Edge
> Function usano da sole la *secret key*: non devi copiarla da nessuna parte.

### 10.1 Crea il progetto

1. <https://supabase.com/dashboard> → la stessa organizzazione del DEV → **New project**:

   | Campo | Valore |
   |---|---|
   | Project name | `haposto-prod` |
   | Database password | **Generate a password** → copiala nel gestore di password (voce "Supabase haposto-prod – database"); non serve altrove |
   | Region | Europa: **Central EU (Frankfurt)** (se c'è solo la scelta generale: *Europe*) |
   | Opzioni di sicurezza / Data API (se compaiono) | *Data API* **attiva**, schema **public** (non lo schema API dedicato); *Automatically expose new tables* e la RLS automatica: **lascia come sono** (funziona in entrambi i casi) |

   Piano **Free**: se compare un costo mensile o la richiesta di una carta, **fermati**.
2. **Create new project** → attendi un paio di minuti che il progetto sia pronto.
3. **Project Settings → API Keys**: c'è la *publishable key* (`sb_publishable_…`, pubblica: andrà
   nell'app e nel sito). La *secret key* non va copiata. È normale che le chiavi *legacy* manchino.

### 10.2 Database: migration 0001–0016

Supabase (**produzione**: controlla il nome del progetto in alto) → **SQL Editor** → **New query** →
incolla il file intero → **Run**, **uno alla volta, in ordine**: `supabase/migrations/0001_extensions.sql`
… `0016_paid_plans_and_trial.sql` (16 file, compresa la 0005). Se compare *Potential issue detected…
destructive operation* premi **Run this query**. Se un file dà errore, fermati e mandami la riga.

Verifica (nuova query):

```sql
select
    (select count(*) from public.restaurants) as locali,
    (select string_agg(key, ', ' order by key) from public.app_config) as impostazioni,
    (select count(*) from public.plans) as piani,
    (select count(*) from pg_publication_tables
     where pubname = 'supabase_realtime' and tablename = 'restaurant_live_status') as tempo_reale,
    (select count(*) from pg_class c join pg_namespace n on n.oid = c.relnamespace
     where n.nspname = 'public' and c.relkind = 'r'
       and not has_table_privilege('service_role', c.oid, 'UPDATE')) as tabelle_senza_permessi_del_server,
    (select count(*) from storage.buckets where id = 'restaurant-files') as contenitore_file;
```

Atteso: `locali` 0 · `impostazioni` `beta, dev_tools_enabled, legal, min_supported_app_version,
public_links, restaurant_trial, security` · `piani` 5 · `tempo_reale` 1 · `tabelle_senza_permessi_del_server` 0 ·
`contenitore_file` 1.

In produzione **mai**: `supabase/seeds/*`, `supabase/dev/*`, `supabase/tests/*`. (Sul DEV la 0014
non serve, ha già quei permessi; eseguirla è innocuo.)

### 10.3 Directory reale (OpenStreetMap)

`HAPOSTO_GUIDA_APP_E_DATI_REALI.md`, capitoli 3.1–3.3, sul progetto di **produzione**: Overpass
Turbo → `export.json` → incollato in `supabase/ops/import_osm_overpass.sql` → **Run**. Il risultato
`inserted` è il numero di locali creati. Controllo:
`select city, count(*) from public.restaurants where data_source = 'OSM_IMPORT' group by city;`
Dopo l'incolla il file SQL contiene il JSON: non salvarlo nel progetto (o rimetti la riga
`INCOLLA_QUI_IL_JSON_DI_OVERPASS`) ed elimina la query salvata dall'editor.

### 10.4 Login: Google e verifica in due passaggi

1. Google Cloud → **Google Auth Platform → Clients** (*Client*) → **HAPOSTO Web** → *Authorized
   redirect URIs* (*URI di reindirizzamento autorizzati*) → **Add URI** →
   `https://REF_PROD.supabase.co/auth/v1/callback` (quello del DEV resta) → **Save**.
2. **Branding** → *Authorized domains* (*Domini autorizzati*) → **Add domain**
   `REF_PROD.supabase.co` → **Save**.
3. Supabase (produzione) → **Authentication → Sign In / Providers → Google** → **Enable Sign in with
   Google**: *Client IDs* e *Client Secret* **dello stesso client Web** usato per il DEV (dal gestore
   di password); *Skip nonce checks* disattivato → **Save**. Secret perso? Nel client Web → **Add
   secret** crea un secondo secret (quello del DEV resta valido).
4. Sempre in **Sign In / Providers**: **Email** → disattiva → **Save** (nei progetti nuovi è attivo).
5. **Authentication → Multi-Factor**: *TOTP (App Authenticator)* **Enabled**; *Phone* disattivato.

### 10.5 L'app di produzione sul telefono

1. Google Cloud → **Clients** → apri **HAPOSTO Dev** e copia lo *SHA-1*. Poi **Create client** →
   **Android** → nome `HAPOSTO (debug)`, package `com.haposto`, lo stesso SHA-1 → **Create**.
2. `local.properties`: togli il `#` dalle righe di produzione (o aggiungile) e compila:
   ```properties
   SUPABASE_PROD_URL=https://REF_PROD.supabase.co
   SUPABASE_PROD_PUBLISHABLE_KEY=sb_publishable_...
   ```
   (la *publishable key* del progetto di **produzione**, punto 10.1.3).
3. **Sync** → *Build Variants* → `prodDebug` → **▶ Run**. Si installa **HAPOSTO** (senza etichetta
   DEV), accanto a HAPOSTO Dev. In Home compaiono i locali importati, come "Non collegato".
4. App HAPOSTO → **Account** → **Accedi con Google** → accetta termini e privacy → **Verifica in due
   passaggi** → *Attiva*. In Authenticator compare una **seconda** voce "HAPOSTO" con la stessa
   email: rinominala subito (tieni premuto sulla voce → ✏️) in `HAPOSTO PROD`. Da qui, nell'app di
   produzione si usa solo quella.

### 10.6 Credenziali admin di produzione

Come al punto 4.2, nel SQL Editor del progetto di **produzione**, con nome utente e password
**diversi** da quelli del DEV (salvali nel gestore di password), poi **⋯ → Delete query**:

```sql
select public.admin_set_credentials('LA_TUA_EMAIL_GOOGLE', 'nome.utente', 'una-password-lunga-almeno-12-caratteri');
```

Prova: app HAPOSTO → Account → tieni premuto 5 secondi sulla versione → "Area riservata".

### 10.7 Notifiche: Firebase per l'app di produzione

1. Firebase (stesso progetto del DEV) → ⚙ **Impostazioni progetto** → *Le tue app* → **Aggiungi
   app** → **Android**: package `com.haposto`, nickname `HAPOSTO` → **Registra app** → scarica
   `google-services.json` (non metterlo nel progetto) → salta i passi successivi con **Avanti**.
2. `local.properties`, come al punto 5.3 ma con `FIREBASE_PROD_…` (togli il `#`): `APP_ID` e
   `API_KEY` dal blocco `client` di **`com.haposto`** (nel file c'è anche `com.haposto.dev`);
   `PROJECT_ID` e `SENDER_ID` uguali a quelli del DEV. Cancella il file scaricato.
3. **Sync** → **▶ Run** con `prodDebug` → nell'app esci e rientra con il tuo account (il telefono si
   registra per le notifiche).

### 10.8 Edge Function e lavori pianificati di produzione

1. Terminale di Android Studio (se chiede l'accesso: `npx supabase login`):
   ```bash
   npx supabase link --project-ref REF_PROD
   npx supabase functions deploy push-dispatch --no-verify-jwt --use-api
   npx supabase functions deploy play-verify --no-verify-jwt --use-api
   npx supabase functions deploy play-rtdn --no-verify-jwt --use-api
   npx supabase functions deploy stripe-checkout --no-verify-jwt --use-api
   npx supabase functions deploy billing-portal --no-verify-jwt --use-api
   npx supabase functions deploy stripe-webhook --no-verify-jwt --use-api
   npx supabase functions deploy restaurant-file --no-verify-jwt --use-api
   ```
   Da qui la CLI lavora sulla **produzione**: per ripubblicare sul DEV rifai prima
   `npx supabase link --project-ref REF_DEV`. Il progetto collegato è quello con ● in
   `npx supabase projects list`.
2. Supabase (produzione) → **Edge Functions → Secrets**:

   | Segreto | Valore |
   |---|---|
   | `HAPOSTO_CRON_SECRET` | **nuovo** valore casuale (generatore del punto 6.2), salvato nel gestore di password |
   | `FIREBASE_SERVICE_ACCOUNT` | Firebase → Impostazioni progetto → **Account di servizio** → **Genera nuova chiave privata** (una chiave nuova, solo per la produzione) → tutto il JSON; poi cancella il file |
   | `HAPOSTO_SITE_URL`, `HAPOSTO_ALLOWED_ORIGINS` | l'indirizzo del sito, es. `https://haposto-test.pages.dev` |

   Play (`PLAY_…`) e Stripe **live** (`STRIPE_…`) arriveranno con le Parti 7 e 8. Nessuna chiave del
   server da aggiungere.
3. Come al punto 6.3, ma sul progetto di **produzione**: **Database → Extensions** → `pg_cron` e
   `pg_net`; nel vault `https://REF_PROD.supabase.co` e il **nuovo** `HAPOSTO_CRON_SECRET` (poi
   **⋯ → Delete query**); `supabase/ops/scheduled_jobs.sql`; `supabase/ops/push_dispatch_cron.sql`;
   `supabase/ops/restaurant_files_cron.sql`.
4. Prova come al punto 6.3.6 con l'app **HAPOSTO** (chiusa scorrendola via): nella risposta deve
   comparire `"delivered":1`.

### 10.9 Il sito passa alla produzione

Da qui il sito (`/r/…` dei QR e area ristoratori) legge il progetto di **produzione**: i QR creati
con l'app Dev non si aprono più sul sito. Le prove dell'app Dev continuano come prima.

1. Cloudflare → **Workers & Pages** → il progetto del sito → **Settings → Variables and Secrets**:
   `HAPOSTO_SUPABASE_URL` = `https://REF_PROD.supabase.co`, `HAPOSTO_SUPABASE_PUBLISHABLE_KEY` = la
   *publishable key* di produzione → **Save** → **Deployments** → sull'ultima pubblicazione
   **⋯ → Retry deployment**.
2. Supabase (produzione) → **Authentication → URL Configuration**: *Site URL*
   `https://haposto-test.pages.dev`; *Redirect URLs* → **Add URL** →
   `https://haposto-test.pages.dev/ristoratori/`.
3. Prove: SQL Editor `select name, slug from public.restaurants where slug is not null order by name limit 3;`
   → `https://haposto-test.pages.dev/r/SLUG` mostra il locale ("non collegato");
   `https://haposto-test.pages.dev/ristoratori/` → accedi con il tuo account → codice della voce
   `HAPOSTO PROD` → "Nessun locale di cui sei titolare" (normale: in produzione non ci sono ancora
   partner).

### 10.10 Beta, backup e pausa del progetto

- **Beta**: dalla migration 0006 tutti i locali hanno Pro gratis fino al **30 giugno 2027**
  (`restaurants_all_pro_until`). Per cambiare la data: pannello admin → **Impostazioni** → `beta`.
- **Backup**: con il piano Free esporta periodicamente le tabelle principali (Table Editor →
  **Export → CSV**); con il piano Pro (a pagamento) i backup sono giornalieri.
- **Pausa**: un progetto Free senza attività per 7 giorni viene messo in pausa (succederebbe alla
  produzione finché non ci sono utenti). Lo evita il ping automatico del punto 6.4: aggiungi i due
  segreti `SUPABASE_PROD_…`. Se succede lo stesso: Dashboard → il progetto → **Restore project**,
  gratis, i dati restano (entro 90 giorni dalla pausa).

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

**Durata della prova gratuita dei locali.** Pannello → Impostazioni → `restaurant_trial` →
`{"days": 30}` (da 0 a 365) → **Salva**. Vale per ogni locale da quando è diventato partner, anche
per chi è già in prova; durante la beta (`beta`) tutti hanno comunque Pro. Finita la prova, senza
abbonamento il locale appare **"Non collegato"** e non pubblica lo stato; il titolare riceve un
avviso 7 giorni e 1 giorno prima (lavoro pianificato `haposto-plan-expiry-notices`).

**Regalare mesi di Pro a un locale.** Pannello → Locali → il locale → **Regala un piano** → 1, 3,
6 o 12 mesi → **Attiva Pro per … mesi**: utile per prolungare la prova di un singolo locale.

**Link e file dei locali.** Pannello → **Contenuti**: compaiono i locali che hanno cambiato link o
file e che non hai ancora guardato (**Tutti** per vederli tutti). Tocca i link per aprirli; poi
**Visto** se va bene, oppure **Togli link** / **Togli file** (l'operazione resta nel registro
operazioni; il file tolto si cancella nella notte). Il titolare può rimetterli: li rivedrai tra
quelli da controllare; se insiste, sospendi il locale.

**Aggiornare il database (nuova migration).** Quando una PR aggiunge un file in
`supabase/migrations/`:
1. prima sul **DEV**: SQL Editor → incolla il file nuovo → **Run** (le migration sono rieseguibili:
   se non ricordi quali hai già eseguito, eseguile tutte in ordine dalla prima mancante);
2. se la PR cambia `supabase/functions/` o `supabase/ops/`, ripubblica le funzioni (6.1) ed
   esegui i file `ops` indicati nella PR;
3. prova con l'app **Dev** quello che la PR descrive;
4. solo dopo, la stessa cosa sulla **produzione** (controlla il nome del progetto in alto).

Le versioni dell'app già installate continuano a funzionare con il database aggiornato: i
campi nuovi che non conoscono vengono ignorati.

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
