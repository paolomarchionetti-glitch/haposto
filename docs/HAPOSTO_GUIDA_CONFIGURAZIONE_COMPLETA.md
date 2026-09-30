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
| 10 | Progetto di produzione | 1 ora | lancio |
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
| Parte 7/10 | **Android** | HAPOSTO | package `com.haposto` · SHA-1 della chiave di caricamento **e** (dopo il primo caricamento su Play) SHA-1 della chiave di firma di Google Play | app di produzione |

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
```

- `login` apre il browser: accedi a Supabase e conferma. Se `link` chiede la password del database
  premi **Invio** (non serve per le funzioni).
- `--use-api` evita di dover installare Docker. `REF_DEV` è la parte iniziale dell'indirizzo
  `https://REF_DEV.supabase.co`.
- Si possono pubblicare tutte subito: finché mancano i loro segreti (Parti 7–9) ogni funzione
  rifiuta le chiamate.
- Controllo: Supabase → **Edge Functions** → compaiono le 6 funzioni.

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

`SUPABASE_URL` e le chiavi del server le fornisce Supabase da sé. Controlla solo Supabase →
**Project Settings → API Keys** → scheda delle chiavi *legacy* (`anon`, `service_role`): se sono
attive non serve altro; se sono **disattivate** aggiungi anche `HAPOSTO_SECRET_KEY` = la *secret
key* (`sb_secret_…`) e `HAPOSTO_PUBLISHABLE_KEY` = la *publishable key*.

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
   comparire `haposto-push-dispatch` con `active = true`. Tutti e due i file sono rieseguibili.
5. Prova, con l'app chiusa e il tuo indirizzo email:
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
   `sent_at` compilato = inviata. Nelle risposte: `401 UNAUTHORIZED` = i due valori del segreto
   (funzione e vault) sono diversi; `500 NOT_CONFIGURED` = manca un segreto della funzione;
   `500 DATABASE_ERROR` = chiavi del server (vedi la fine del 6.2); `502 GOOGLE_AUTH_FAILED` =
   JSON di Firebase non valido o incompleto.

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
2. SQL Editor: migration **0001–0013** in ordine (compresa la 0005, tempo reale). **Non** caricare i seed di
   prova (`900_…`, `910_…`) né `supabase/dev/*`.
3. Directory dei locali reali: `supabase/ops/import_osm_overpass.sql` (istruzioni nel file).
4. Google Cloud, stesso client *Web* del punto 2.2: aggiungi `https://REF_PROD.supabase.co/auth/v1/callback`
   agli *Authorized redirect URIs* e `REF_PROD.supabase.co` agli *Authorized domains* (2.1); poi
   Parte 2.3–2.4 sul progetto di produzione.
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
