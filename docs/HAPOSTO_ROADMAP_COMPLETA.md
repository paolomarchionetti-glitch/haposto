# HAPOSTO — Roadmap completa, da oggi alla fine del progetto

Versione del 27 settembre 2026, dopo le prove DEV pseudo-realistiche superate.
Questo documento elenca **tutte** le attività rimaste, in ordine: account reali (ristoratore
obbligatorio, utente facoltativo), termini e privacy, pagamenti, Play Store, pilot, lancio e
gestione continuativa. Sostituisce il calendario di `HAPOSTO_ROADMAP_INTEGRATIVA.md`; gli altri
documenti restano validi per i dettagli:

- modello dei piani e dei prezzi: `HAPOSTO_MODELLO_PREMIUM_E_ACCOUNT.md`;
- database già pronto: `HAPOSTO_SQL_INTEGRATIVO.md`;
- dati reali e pilot: `HAPOSTO_GUIDA_APP_E_DATI_REALI.md`.

> **Aggiornamento 29 settembre 2026 — tutta la parte 🤖 è fatta.** App (versioni Demo/Dev/Prod,
> login Google + verifica in due passaggi, area ristoratore reale con codice telefonico, pannello
> admin nascosto, QR, statistiche, mappe, tempo reale, notifiche, Plus), database 0012–0013, Edge
> Function (push, Google Play, Stripe), sito (area ristoratori Pro, pagina pubblica, pagine legali)
> e CI. Restano le attività 🧑 e ⚖️: segui **`HAPOSTO_GUIDA_CONFIGURAZIONE_COMPLETA.md`** nell'ordine
> (migration, login, chiavi, Edge Function, Play, Stripe, sito, produzione, test finali), poi le
> fasi di pubblicazione, pilot e lancio di questo documento.

**Chi fa cosa**

| Simbolo | Chi |
|---|---|
| 🧑 | tu (account, decisioni, contatti con i ristoratori, prove sul telefono) |
| 🤖 | Claude in una sessione come questa (codice Android, SQL, Edge Function, sito, test, documenti tecnici) |
| ⚖️ | un professionista (commercialista, avvocato o servizio online di documenti legali) |
| ✅ | già pronto nel database (migration 0006–0011) |
| 🆕 | da scrivere |

---

## 1. Il quadro in una pagina

| Fase | Contenuto | Chi | Durata indicativa | Dipende da |
|---|---|---|---|---|
| **A** | Chiudere le prove DEV, prova sul campo con 2–3 ristoratori veri | 🧑 | 2–3 settimane | — |
| **B** | Basi: dominio, forma giuridica, account dei servizi, sicurezza degli account | 🧑 ⚖️ | parte subito, in parallelo | — |
| **C** | Login **reale e obbligatorio** per il ristoratore (Google) e verifica | 🤖 🧑 | 2–3 settimane | B (Google Cloud) |
| **D** | Login **facoltativo** per l'utente, profilo, cancellazione account | 🤖 | 1–2 settimane | C |
| **E** | Gestione protetta del locale: stato, dati del locale, staff; versioni DEV/PROD separate | 🤖 | 2 settimane | C |
| **F** | Termini, privacy e conformità: documenti, consensi, sezione nell'app | ⚖️ 🤖 🧑 | 3–4 settimane, in parallelo a C–E | B |
| **G** | Tempo reale e notifiche (promemoria al ristoratore) | 🤖 🧑 | 2–3 settimane | E |
| **H** | Sito web, pagina pubblica del locale, QR, area amministratore | 🤖 🧑 | 2–3 settimane | B (dominio), E |
| **I** | Produzione: progetto Supabase reale, directory OpenStreetMap, test chiuso su Play | 🧑 🤖 | 3 settimane (14 giorni di test chiuso) | C–H |
| **J** | **Pilot Pesaro** con 20–40 locali veri | 🧑 | 6–8 settimane | I |
| **K** | Pagamenti dei ristoranti (Pro, Stripe sul web, fatture elettroniche) | 🧑 🤖 ⚖️ | 3–4 settimane | B (P.IVA), H |
| **L** | Pubblicazione su Google Play in produzione | 🧑 🤖 | 1–2 settimane | I, F |
| **M** | HAPOSTO Plus per gli utenti (Google Play Billing) | 🤖 🧑 | 3–4 settimane | D, G, L |
| **N** | Statistiche Pro e prenotazioni sincronizzate | 🤖 | 2–3 settimane | E |
| **O** | Fine della beta: passaggio a pagamento dei ristoranti | 🧑 | 1 mese di comunicazione | K, J |
| **P** | Espansione: altre città, mappa, iOS, Pro+ | 🤖 🧑 | a scelta | L |
| **Q** | Gestione continuativa (manutenzione, KPI, aggiornamenti, sicurezza) | 🧑 🤖 | per sempre | L |

### Traguardi

| Traguardo | Cosa vuol dire | Data indicativa |
|---|---|---|
| **M1** Login reale | un ristoratore vero entra con Google e, dopo la tua verifica, gestisce il suo locale | fine ottobre 2026 |
| **M2** Pronto per il pilot | produzione attiva, directory reale di Pesaro, notifiche, QR, documenti legali pubblicati, test chiuso avviato | metà dicembre 2026 |
| **M3** Pilot concluso | KPI misurati, decisione di proseguire | fine febbraio 2027 |
| **M4** Lancio pubblico | app su Google Play per tutti, Pesaro | marzo 2027 |
| **M5** Pagamenti attivi | Pro acquistabile sul sito; Plus acquistabile nell'app | aprile–maggio 2027 |
| **M6** Fine beta | dal 1° luglio 2027 i ristoranti pagano Pro (Basic resta gratis) | 30 giugno 2027 |
| **M7** Progetto "finito" | vedi §9: prodotto stabile in gestione continuativa | estate 2027 |

Le date dipendono soprattutto da due cose esterne: i tempi dei documenti legali/fiscali (Fase B e F)
e la disponibilità dei ristoratori per il pilot. Meglio spostarle che partire con dati vecchi.

---

## 2. Decisioni che devi prendere (e entro quando)

| # | Decisione | Opzioni | Consiglio | Entro |
|---|---|---|---|---|
| D1 | Chi è il **titolare** di HAPOSTO (privacy, contratti, fatture) | persona fisica senza P.IVA (solo per le prove); ditta individuale (forfettario); SRL/SRLS | per incassare dai ristoranti serve **P.IVA**; parlane con un commercialista: ditta individuale in forfettario è la via più semplice per partire, SRL se vuoi soci o vendere l'azienda | prima del pilot (fine novembre 2026) |
| D2 | **Dominio** | `haposto.app`, `haposto.it`, entrambi | compralo subito (serve a Google per il login, alla privacy policy, al sito e ai QR) | ottobre 2026 |
| D3 | Tipo di account **Google Play** | personale o organizzazione | organizzazione se hai P.IVA/società (serve il numero D-U-N-S, gratuito); con account personale Google impone un test chiuso con almeno 12 tester per 14 giorni | prima della Fase I |
| D4 | **Città e zone del pilot** | Pesaro centro + mare + Baia Flaminia | 2–3 zone vicine: conta la densità | inizio dicembre 2026 |
| D5 | **Prezzi definitivi** | quelli indicativi: Pro €12,90 + IVA/mese o €99 + IVA/anno; Plus €1,49/mese o €9,99/anno IVA inclusa | decidili con i numeri del pilot | marzo 2027 |
| D6 | **Fine beta** | 30/06/2027 (attuale) o altra data | cambiabile in `app_config` senza aggiornare l'app | aprile 2027 |
| D7 | Accesso ristoratori **senza account Google** | solo Google; Google + link via email | aggiungi il link via email solo se nel pilot qualcuno lo chiede | durante il pilot |
| D8 | **iOS** | no; dopo il lancio Android; mai | valuta dopo 3 mesi di lancio | estate 2027 |

---

## 3. Servizi e account da attivare

Attiva su **tutti** l'accesso a due fattori (2FA) e conserva le credenziali in un gestore di password.
Nessuna chiave segreta va mai in GitHub, nell'app o in chat.

| Servizio | A cosa serve | Quando | Costo indicativo* |
|---|---|---|---|
| Registrar del dominio (es. Cloudflare, Aruba, OVH) | dominio e caselle email (`info@`, `privacy@`) | Fase B | 15–40 €/anno |
| Google Cloud (progetto "HAPOSTO") | login con Google (credenziali OAuth) | Fase C | gratis |
| Supabase **DEV** (esiste già) | prove | ora | gratis |
| Supabase **PROD** | dati reali | Fase I | piano Pro ~25 $/mese (backup giornalieri, niente pausa per inattività) |
| Firebase (solo Cloud Messaging e Crashlytics) | notifiche push, report dei crash | Fase G | gratis |
| Hosting del sito (Cloudflare Pages, Netlify o simili) | sito, pagine legali, pagina pubblica dei locali | Fase H | gratis |
| Google Play Console | pubblicazione | Fase I | 25 $ una tantum |
| Stripe | abbonamenti Pro dei ristoranti | Fase K | ~1,5% + 0,25 € per pagamento con carta europea, più ~0,7% per la gestione abbonamenti |
| Fatturazione elettronica (es. Fatture in Cloud, Aruba, o il gestionale del commercialista) | fatture SDI ai ristoranti | Fase K | 50–150 €/anno |
| Documenti legali (avvocato o servizio online tipo iubenda) | privacy, termini, condizioni per i ristoranti | Fase F | 30–150 €/anno online; avvocato a preventivo |
| Commercialista | P.IVA, IVA, fatture, dichiarazioni | Fase B | a preventivo |
| Google Play Billing | Plus | Fase M | 15% sugli abbonamenti |

\* Prezzi indicativi a settembre 2026: verificali al momento dell'attivazione.

---

## 4. Le fasi in dettaglio

### Fase A — Chiudere le prove DEV (ora → metà ottobre 2026)

**Obiettivo:** sapere, prima di scrivere il login vero, se la dashboard funziona nelle mani di un
ristoratore durante un servizio.

1. 🧑 Completa gli scenari della guida pseudo-realistica (capitoli 6–7), anche di sera.
2. 🧑 Prova sul campo con **2–3 ristoratori amici**, 2 serate ciascuno
   (`HAPOSTO_GUIDA_APP_E_DATI_REALI.md`, capitolo 4). Annota le risposte alle 5 domande.
3. 🤖 Correzioni all'interfaccia emerse dalle prove (piccole: testi, dimensioni, ordine).

**Fatto quando:** almeno 3 ristoratori hanno usato la dashboard per una serata e le correzioni
emerse sono nell'app.

---

### Fase B — Basi: dominio, forma giuridica, account (parallela, da subito)

1. 🧑 Compra il **dominio** (D2) e crea le caselle `info@` e `privacy@`.
2. 🧑 ⚖️ Appuntamento con un **commercialista** (D1): P.IVA, regime fiscale, codice attività,
   fatturazione elettronica, IVA sugli abbonamenti venduti a ristoranti e a privati.
3. 🧑 Crea il progetto **Google Cloud** "HAPOSTO" con la tua email di lavoro.
4. 🧑 Attiva la **2FA** su GitHub, Google, Supabase (e poi Stripe e Play Console).
5. 🧑 Crea un **keystore di rilascio** in Android Studio (Build → Generate Signed App Bundle →
   Create new) e salvalo in **due** posti sicuri fuori dal progetto, con la password nel gestore di
   password. Se lo perdi non puoi più aggiornare l'app (con Play App Signing si può recuperare solo
   tramite l'assistenza Google).

**Fatto quando:** dominio attivo, decisione D1 presa, progetto Google Cloud creato, keystore al sicuro.

---

### Fase C — Login reale e obbligatorio per il ristoratore (Step 8a)

**Obiettivo:** solo chi ha un account verificato può gestire un locale.

**Configurazione (🧑, con istruzioni passo passo che 🤖 scrive in un documento dedicato):**

1. Google Cloud → *Schermata di consenso OAuth*: nome HAPOSTO, email di supporto, logo, link a
   privacy e termini (bastano le bozze pubblicate sul dominio), permessi solo `email`, `profile`,
   `openid`.
2. Google Cloud → *Credenziali*:
   - un client **Web** (il suo ID va in Supabase e nell'app);
   - un client **Android** con pacchetto `com.haposto` e l'impronta **SHA-1** del keystore di debug e
     di quello di rilascio (più avanti anche quella di Play App Signing).
3. Supabase → Authentication → Providers → **Google**: attiva e inserisci l'ID del client Web.
4. `local.properties`: nuova riga `GOOGLE_WEB_CLIENT_ID=…` (non è segreta ma resta fuori da GitHub
   come le altre).

**App (🤖):**

1. Librerie: Supabase Auth (`auth-kt`), Credential Manager e Google ID.
2. Accesso con **Credential Manager** ("Accedi con Google", la finestrella standard di Android), con
   *nonce* generato dall'app, e sessione Supabase salvata e rinnovata da sola.
3. Tab **Ristoratore**:
   - non hai fatto l'accesso → schermata "Accedi con Google" con spiegazione in 2 righe;
   - primo accesso → **accettazione dei termini per i ristoratori** (`accept_terms`) ✅;
   - hai già un locale approvato → **dashboard** diretta (`my_restaurants`) ✅;
   - nessun locale → **cerca il tuo locale** in tutta la directory, anche quelli "Non collegati"
     (`nearby_restaurants` con testo) ✅ → **Questo è il mio locale** → `submit_restaurant_claim` ✅;
   - **Il mio locale non c'è** → modulo breve (nome, indirizzo con posizione sulla mappa, telefono) →
     `register_new_restaurant` ✅;
   - richiesta in attesa → schermata "Verifica in corso" con cosa succede adesso e **Ritira
     richiesta** (`cancel_my_claim`) ✅.
4. Tolti dalla versione di rilascio: "Simula approvazione admin", "Azzera percorso demo", identità demo
   (restano solo nella versione DEV).
5. Messaggi d'errore in italiano per i codici del database (`HAPOSTO_SQL_INTEGRATIVO.md` §6).
6. Test automatici del percorso con un finto servizio di login.

**Verifica (🧑):** approvi le richieste dal SQL Editor (`HAPOSTO_GUIDA_AGGIORNAMENTO_DB.md` §4)
finché non c'è l'area admin (Fase H). Regola: **chiami il numero pubblico del locale**, mai solo quello
scritto nella richiesta.

**Database:** ✅ tutto pronto.

**Fatto quando (traguardo M1):** un ristoratore vero, dal suo telefono, entra con Google, trova il suo
locale, invia la richiesta; dopo la tua approvazione vede la dashboard; un secondo account non vede e
non può modificare quel locale.

---

### Fase D — Login facoltativo per l'utente, profilo e cancellazione (Step 8b)

**Principio:** cercare e vedere gli stati **non richiederà mai** un account.

**App (🤖):**

1. Icona **Account** in alto nella Home (o in fondo alla tab Preferiti): "Accedi per ritrovare i
   preferiti su tutti i tuoi telefoni". Mai finestre che interrompono la ricerca.
2. Primo accesso: termini e privacy per gli utenti (`accept_terms`) ✅, consenso **separato e
   facoltativo** alle comunicazioni (`marketing_opt_in`) ✅.
3. Preferiti: quando l'utente accede, i preferiti del telefono vengono copiati nel suo account
   (`favorites`, fino a 5 con il piano Gratis) ✅; senza account restano sul telefono come oggi.
4. Schermata **Il mio account**: nome, email, piano (Gratis/Plus), consensi modificabili, **Esci**,
   **Elimina account**.
5. **Elimina account** nell'app (obbligatorio per Google Play) e pagina web equivalente
   `haposto.app/cancella-account` (Fase H).

**Server (🤖):** Edge Function `delete-account` che, con la chiave di servizio, elimina l'utente da
Supabase Auth. Effetti già previsti dal database: profilo, preferiti, avvisi, token e abbonamenti Plus
cancellati ✅; i **pagamenti restano** ma senza collegamento alla persona, perché le registrazioni
contabili vanno conservate 10 anni ✅.

**Database:** 🆕 migration `0012` (vedi §7): se chi si cancella è l'unico titolare di un locale, il
locale torna "Non collegato" invece di restare senza gestore; registro dei consensi.

**Fatto quando:** un utente può accedere, sincronizzare i preferiti, uscire e cancellarsi; dopo la
cancellazione non restano suoi dati personali tranne quelli fiscali anonimizzati.

---

### Fase E — Gestione protetta del locale e versioni DEV/PROD (Step 9)

**App (🤖):**

1. La dashboard pubblica con `set_restaurant_live_status` ✅ (solo titolare e staff); la scrittura DEV
   resta solo nella versione DEV.
2. **Dati del locale** modificabili dal titolare: nome, categoria, telefono, telefono visibile sì/no,
   **orari di apertura** (servono ai promemoria). 🆕 funzione in `0012`.
3. **Staff** (Pro): "Aggiungi collaboratore" con l'email con cui ha fatto l'accesso
   (`add_restaurant_staff`) ✅, elenco e rimozione ✅. Lo staff vede solo i tasti di stato.
4. **Due versioni dell'app** (in gergo *product flavor*):
   - **DEV**: collegata a Supabase DEV, etichetta "SUPABASE DEV", strumenti di prova;
   - **PROD**: collegata a Supabase PROD, nessuna etichetta, nessuno strumento di prova, testi
     definitivi ("attività fittizie" sparisce), attribuzione **© OpenStreetMap contributors**.
   Chiavi separate in `local.properties` (`SUPABASE_DEV_…`, `SUPABASE_PROD_…`).
5. Firma di rilascio letta da `local.properties` (mai in GitHub), R8 attivo, numero di versione
   crescente.
6. Richiesta di aggiornamento quando la versione è sotto `min_supported_app_version` ✅.

**Fatto quando:** con due account reali e due telefoni, lo stato pubblicato da A compare su B; un
account estraneo riceve "Non hai i permessi"; la versione PROD non contiene nulla di DEV.

---

### Fase F — Termini, privacy e conformità (parallela a C–E)

Dettaglio dei documenti in §5. Sequenza:

1. 🧑 ⚖️ Scegli come produrre i documenti: **avvocato** (consigliato almeno per le condizioni dei
   ristoranti) oppure **servizio online** di generazione e aggiornamento (più economico per privacy e
   cookie).
2. 🤖 Prepara la **scheda tecnica per il professionista**: quali dati tratta HAPOSTO, dove, per quanto,
   con quali fornitori (base già in §5.2). Evita che il documento legale descriva un'app diversa da
   quella reale.
3. ⚖️ Redazione: informativa privacy utenti, informativa ristoratori, termini d'uso utenti,
   condizioni di servizio per i ristoranti, cookie policy del sito.
4. 🧑 Pubblicazione sul sito (Fase H): `/privacy`, `/termini`, `/termini-ristoranti`, `/cookie`,
   `/cancella-account`, con data e **numero di versione** (es. `2026-11`).
5. 🤖 Nell'app:
   - sezione **Informazioni** (Home → ⓘ): privacy, termini, licenze open source, attribuzione OSM,
     versione dell'app, contatti;
   - accettazione al primo accesso con la versione dei termini (`accept_terms('2026-11')`) ✅;
   - se esce una versione nuova dei termini, all'accesso successivo si chiede di riaccettare;
   - testo della richiesta di posizione già conforme ("resta sul telefono") ✅.
6. 🧑 Registro dei trattamenti (un foglio di calcolo: modello fornito dal professionista).
7. 🧑 Accetta gli accordi sul trattamento dei dati (DPA) dei fornitori: Supabase, Google/Firebase,
   Stripe, hosting.

**Fatto quando:** documenti pubblicati e raggiungibili dall'app, dal sito e dalla scheda Play;
accettazione registrata nel database.

---

### Fase G — Tempo reale e notifiche (Step 10–11)

**Configurazione (🧑):** progetto Firebase collegato allo stesso progetto Google Cloud; si scarica
`google-services.json` (resta fuori da GitHub come `local.properties`); si carica in Supabase, come
**secret delle Edge Function**, la chiave di servizio per l'invio delle notifiche.

**App (🤖):**

1. **Tempo reale**: si esegue `0005_realtime_future.sql` ✅ e la lista si aggiorna in 1–2 secondi; il
   controllo ogni minuto resta come riserva.
2. **Permesso notifiche** (Android 13+) chiesto solo al ristoratore, solo dopo il primo accesso, con
   spiegazione ("Ti avvisiamo quando il tuo stato sta per scadere").
3. Registrazione del telefono (`register_push_token`) ✅.
4. Notifica **"Il tuo stato scade tra 5 minuti: è ancora così?"** con tre azioni direttamente nella
   notifica (C'è posto / Pochi posti / Completo): pubblicano senza aprire l'app.
5. Notifica **"Inizia il servizio: come siete messi?"** all'orario di apertura (usa gli orari della Fase E).
6. Impostazioni notifiche nel profilo (accese/spente, fasce orarie).

**Server (🤖):** Edge Function `push-dispatch` che legge `notification_outbox` ✅ e invia con
Firebase Cloud Messaging; si attiva `ops/scheduled_jobs.sql` ✅ (promemoria ogni 5 minuti, pulizie
notturne).

**Fatto quando:** durante una serata di prova, i promemoria arrivano e il tasto nella notifica
aggiorna lo stato visto dall'altro telefono.

---

### Fase H — Sito, pagina pubblica, QR e area amministratore (Step 12)

**Sito (🤖, 🧑 pubblica):** pagine statiche veloci, niente cookie di profilazione (così non serve il
banner dei cookie):

| Pagina | Contenuto |
|---|---|
| `/` | cos'è HAPOSTO in 3 righe, link a Google Play |
| `/ristoratori` | come funziona, piani e prezzi, contatto |
| `/<slug>` | **pagina pubblica del locale**: nome, stato grande, "aggiornato N min fa", Indicazioni, Chiama (`public_restaurant_page`) ✅ |
| `/privacy`, `/termini`, `/termini-ristoranti`, `/cookie` | documenti della Fase F |
| `/cancella-account` | richiesta di cancellazione (obbligatoria per Play) |
| `/.well-known/assetlinks.json` | fa aprire l'app (se installata) quando si tocca un link del locale |

**App (🤖):**

1. Dashboard → **Il tuo QR**: QR del link del locale e adesivo A6 "Prima di chiamare, guarda se c'è
   posto" da stampare (PDF generato sul telefono).
2. Pulsante **Condividi** nella scheda del locale (`track_restaurant_event(…, 'SHARE')`) ✅.
3. **Area admin** visibile solo a te (`is_platform_admin`) ✅: richieste da verificare con
   **Approva / Rifiuta** e nota (`admin_pending_claims`, `admin_review_claim`) ✅, **regala piano**
   (`admin_grant_restaurant_plan`) ✅, **sospendi locale** 🆕.

**Fatto quando:** un QR stampato apre la pagina del locale con lo stato attuale; approvi le richieste
dal telefono senza SQL.

---

### Fase I — Produzione e test chiuso (Step 13a e 15)

1. 🧑 Progetto **Supabase PROD** (regione Europa, Frankfurt), piano Pro.
2. 🧑 Migration `0001`–`0004` e `0006`–`0012` (e successive). **Mai** seed né cartella `dev/`.
3. 🧑 Import OpenStreetMap delle zone del pilot (`HAPOSTO_GUIDA_APP_E_DATI_REALI.md` §3) e controllo
   qualità.
4. 🧑 Google Auth, Edge Function e job pianificati configurati anche su PROD.
5. 🧑 Il tuo utente diventa amministratore su PROD.
6. 🧑 🤖 **Google Play Console**:
   - crea l'app, attiva **Play App Signing**, aggiungi lo SHA-1 di Play al client Android di Google
     Cloud;
   - **Sicurezza dei dati** (🤖 prepara le risposte): posizione raccolta ed elaborata solo al momento
     (non conservata), email e nome per chi crea un account, identificativi per le notifiche, report
     dei crash; nessuna vendita di dati; cancellazione disponibile;
   - classificazione dei contenuti, pubblico di destinazione (non destinata ai bambini), privacy policy;
   - **accesso per i revisori Google**: un account ristoratore di prova con locale di prova, perché
     l'area ristoratore richiede il login;
   - **test interno** (tu e pochi altri), poi **test chiuso** (almeno 12 tester per 14 giorni se
     l'account è personale: amici e ristoratori della Fase A).
7. 🤖 Report dei crash (Crashlytics) attivo solo nella versione PROD.

**Fatto quando (traguardo M2):** l'app PROD dal test chiuso mostra i locali reali di Pesaro, un
ristoratore di prova pubblica e un altro telefono vede.

---

### Fase J — Pilot Pesaro (Step 13)

**Kit (🤖 prepara, 🧑 stampa):** foglio A4 "HAPOSTO in 1 minuto" per il ristoratore, adesivo QR,
copione della visita (2 minuti), modulo di consenso per il telefono pubblico.

**Per ogni locale (🧑):**

1. Visita o telefonata; il titolare installa l'app dal link di test e accede con Google.
2. Trova il suo locale e invia la richiesta; tu chiami il **numero pubblico del locale** e approvi.
3. Pro gratis durante la beta (automatico) o per 6 mesi con `admin_grant_restaurant_plan` ✅.
4. Attacchi l'adesivo QR (vetrina, cassa).

**Ogni lunedì (🧑):** query KPI 1–3 di `supabase/ops/kpi_queries.sql`; telefonata ai locali
"silenziosi".

**Soglie per proseguire (traguardo M3):**

| KPI | Soglia |
|---|---|
| Partner con stato valido alle 20:30 | ≥ 60% |
| Partner che aggiornano almeno 4 servizi su 7 | ≥ 50% |
| Utenti che tornano entro 7 giorni | ≥ 25% |
| Ristoratori attivi che "lo pagherebbero" | ≥ 30% |

Se le prime due soglie non sono raggiunte non si passa ai pagamenti: si lavora su promemoria e
semplicità (🤖) e si ripete il pilot per 4 settimane.

---

### Fase K — Pagamenti dei ristoranti: Pro (Step 14)

**Regola:** Pro si compra **sul sito**, non nell'app. Nell'app il ristoratore vede solo lo stato del
suo piano (niente pulsanti o link di acquisto, per rispettare le regole di Google Play sui pagamenti;
da riverificare al momento del lancio).

**Prerequisiti (🧑 ⚖️):** P.IVA (D1); conto Stripe verificato con IBAN; condizioni di servizio per i
ristoranti (Fase F); scelta dello strumento per le **fatture elettroniche** SDI (obbligatorie verso le
aziende).

**Flusso:**

```
Ristoratore (sito /ristoratori) → accede con Google (stesso account dell'app)
  → sceglie Pro mensile o annuale → inserisce i dati di fatturazione (P.IVA, SDI o PEC)
  → Stripe Checkout (pagina di pagamento di Stripe)
  → Stripe avvisa il nostro server (webhook)
  → Edge Function stripe-webhook: verifica la firma, registra l'evento una volta sola,
    aggiorna abbonamento e pagamento nel database ✅
  → nell'app il piano diventa Pro subito
```

**Da costruire (🤖):**

1. Pagina `/ristoratori/pro` sul sito con accesso Google.
2. Edge Function `create-checkout` (crea il pagamento legato al locale) e `stripe-webhook` (usa
   `billing_log_event`, `billing_upsert_restaurant_subscription`, `billing_record_payment`) ✅.
3. Portale clienti di Stripe per cambiare carta o disdire.
4. Dati di fatturazione nel database (`restaurant_billing_profiles`) ✅, con controllo di P.IVA e
   codice SDI.
5. **Fatture elettroniche**: all'inizio (fino a ~30 clienti) le emette il commercialista o tu con il
   gestionale, partendo dall'elenco mensile dei pagamenti (query KPI 8); oltre, collegamento
   automatico tra Stripe e il servizio di fatturazione.
6. Nell'app: card **Il tuo piano** (`restaurant_entitlements`) ✅ con piano, scadenza e "per
   modificarlo vai su haposto.app/ristoratori".
7. Mancato pagamento: 3 giorni di tolleranza, poi Basic ✅; email automatiche di Stripe.

**Collaudo:** tutto in **modalità test** di Stripe con le carte di prova: pagamento, rinnovo,
pagamento rifiutato, disdetta, rimborso. Poi un pagamento reale di 1 mese su un tuo locale di prova,
con fattura.

**Fatto quando (traguardo M5, parte ristoranti):** un ristoratore paga sul sito, ha Pro nell'app entro
un minuto e riceve la fattura corretta.

---

### Fase L — Pubblicazione su Google Play (Step 15)

1. 🤖 Scheda dello store: nome, descrizione breve (80 caratteri) e lunga, parole chiave naturali
   ("posto ristorante Pesaro", "tavolo libero adesso"), screenshot dalla versione PROD, grafica
   1024×500, icona 512.
2. 🧑 Controllo finale con la lista di `HAPOSTO_GUIDA_APP_E_DATI_REALI.md` §6.
3. 🧑 Pubblicazione **graduale** (10% → 50% → 100% in una settimana) guardando i crash.
4. 🧑 Comunicazione locale: adesivi nei locali partner, social dei locali, stampa locale.

**Fatto quando (traguardo M4):** HAPOSTO è scaricabile da tutti e i crash restano sotto l'1% delle
sessioni.

---

### Fase M — HAPOSTO Plus per gli utenti (Step 16)

**Configurazione (🧑):** in Play Console l'abbonamento `haposto_plus` ✅ (nome già previsto nel
database) con piano mensile e annuale, eventuale prova gratuita; account di servizio Google con accesso
alle API di Play, caricato come secret delle Edge Function; notifiche in tempo reale di Play (RTDN)
verso il nostro server.

**App (🤖):**

1. Schermata **Plus**: cosa include, prezzo IVA inclusa, **Abbonati** (Google Play Billing).
2. Dopo l'acquisto l'app manda la ricevuta al server; il server la verifica con Google, attiva Plus e
   **conferma l'acquisto entro 3 giorni** (altrimenti Google lo rimborsa da solo).
3. **Ripristina acquisti** su un telefono nuovo.
4. Funzioni Plus:
   - **Avvisami quando c'è posto** sulla scheda di un locale Completo o Pochi posti ✅
     (`availability_alerts`), con notifica;
   - preferiti illimitati sincronizzati ✅;
   - raggio di ricerca esteso ✅ (`consumer_limit`);
   - filtri avanzati (es. "solo con tavoli per 4");
   - storico: "di solito il sabato alle 21 è completo" 🆕 (funzione in `0012`).
5. Disdetta: link alla gestione abbonamenti di Google Play.

**Server (🤖):** Edge Function `play-verify` e `play-rtdn` → `billing_upsert_consumer_subscription` ✅.

**Regola invariata:** cercare resta gratis e senza account; Plus aggiunge comodità, non toglie nulla
a chi non paga.

**Fatto quando (traguardo M5, parte utenti):** acquisto, rinnovo, disdetta e ripristino funzionano con
gli account di test di Play.

---

### Fase N — Statistiche Pro e prenotazioni sincronizzate (Step 17)

1. 🤖 L'app conta in modo anonimo aperture scheda, indicazioni, chiamate, condivisioni
   (`track_restaurant_event`) ✅.
2. 🤖 Dashboard → **Quante persone ti hanno visto**: tre numeri grandi (oggi, 7 giorni; 90 con Pro)
   (`restaurant_stats`) ✅.
3. 🤖 Prenotazioni di sala sincronizzate tra i telefoni dello staff (Pro) (`reservations`) ✅,
   funzionanti anche senza rete e allineate al ritorno della connessione.
4. 🤖 Riepilogo mensile via email al titolare (facoltativo).

---

### Fase O — Fine della beta (maggio–giugno 2027)

1. 🧑 Decidi D5 e D6 con i dati del pilot e del lancio.
2. 🧑 **30 giorni prima** della fine: email e avviso nella dashboard: "Dal 1° luglio Pro costa X; Basic
   resta gratis; non ti addebitiamo nulla se non scegli tu di abbonarti".
3. 🧑 Offerta per i partner del pilot (es. primo anno scontato), con `admin_grant_restaurant_plan` o
   coupon Stripe.
4. Il 1° luglio chi non si è abbonato passa a **Basic** in automatico ✅: non perde lo stato live,
   perde solo i dettagli Pro.

---

### Fase P — Espansione (dopo il lancio, a scelta)

| Attività | Quando ha senso |
|---|---|
| Fano, poi Urbino e Gabicce | quando Pesaro supera il 60% di stati validi a cena |
| Vista **mappa** (MapLibre + OSM) | quando in una zona ci sono più di ~50 partner |
| **iOS** | dopo 3 mesi di lancio Android con KPI stabili |
| **Pro+** (più locali, integrazione con casse e prenotazioni esterne) | quando arriva una catena o un gruppo |
| Inglese | per le zone turistiche d'estate |

---

### Fase Q — Gestione continuativa

| Frequenza | Attività | Chi |
|---|---|---|
| ogni settimana | KPI, locali silenziosi, richieste da verificare | 🧑 |
| ogni mese | import OSM, costi, crash, fatture | 🧑 |
| ogni mese | aggiornamento librerie Android e controllo sicurezza | 🤖 |
| ogni 3 mesi | prova del ripristino da backup su un progetto di prova | 🧑 🤖 |
| ogni anno (agosto) | aggiornamento del livello Android richiesto da Google Play | 🤖 |
| ogni anno | revisione di privacy e termini, rinnovo dominio | ⚖️ 🧑 |
| a ogni modifica | la CI deve essere verde prima di unire | 🤖 |

---

## 5. Termini e privacy in dettaglio

### 5.1 Documenti

| Documento | Per chi | Contenuti essenziali |
|---|---|---|
| **Informativa privacy utenti** | chi usa l'app | titolare e contatti; dati: posizione (usata al momento, non conservata), account facoltativo (email, nome), preferiti e avvisi, token notifiche, dati d'uso anonimi, crash; basi giuridiche; conservazione; fornitori; trasferimenti fuori UE; diritti e come esercitarli; età minima 14 anni |
| **Informativa privacy ristoratori** | titolari e staff | come sopra più: dati del locale, recapito per la verifica, telefono pubblico solo con consenso, dati di fatturazione, storico degli stati |
| **Termini d'uso utenti** | chi usa l'app | lo stato è un'indicazione del locale, **non una prenotazione**; nessuna garanzia di posto; uso corretto; Plus: prezzo, rinnovo, disdetta da Google Play, diritto di recesso e sua perdita con l'uso immediato |
| **Condizioni di servizio ristoranti** | chi gestisce un locale | obbligo di stati veritieri; responsabilità sui contenuti pubblicati (nota); verifica e sospensione; staff; piani, prezzi, rinnovo, disdetta, mancato pagamento; fine beta senza addebiti automatici; limitazione di responsabilità; legge e foro. Le clausole più onerose vanno **accettate separatamente** (doppia accettazione) |
| **Cookie policy** | visitatori del sito | solo cookie tecnici se non usi analisi con cookie |
| **Registro dei trattamenti** | interno | tabella di §5.2 |
| **Procedura violazione dati** | interno | chi avvisare e in quanto tempo (Garante entro 72 ore se serve) |

### 5.2 Scheda dei trattamenti (base per il professionista)

| Dato | Da dove | Perché | Dove sta | Per quanto |
|---|---|---|---|---|
| Posizione del telefono | app, se l'utente la concede | ordinare per distanza | solo nella richiesta al server, **non salvata** | istante della ricerca |
| Email, nome, id Google | accesso facoltativo (obbligatorio per i ristoratori) | account | Supabase Auth (UE) | finché l'account esiste |
| Accettazione termini, consensi | primo accesso | prova del consenso | `profiles` 🆕 registro consensi | durata account + termini di legge |
| Preferiti, avvisi | utente con account | funzioni richieste | Supabase (UE) | finché l'utente li tiene |
| Token notifiche | telefono | inviare notifiche | Supabase; invio tramite Firebase (Google) | finché l'app è installata |
| Dati del locale, stati, note | ristoratore | servizio | Supabase (UE) | durata del rapporto; storico 90 giorni per le statistiche |
| Dati di fatturazione | ristoratore | fatture | Supabase; Stripe; gestionale fatture | 10 anni (obbligo contabile) |
| Pagamenti | Stripe, Google Play | abbonamenti | Supabase (riferimenti), Stripe/Google (dati carta: mai da noi) | 10 anni |
| Contatori anonimi | app | statistiche dei locali | Supabase | 2 anni |
| Report dei crash | app PROD | stabilità | Firebase Crashlytics | 90 giorni |

Fornitori da citare: Supabase (database e login), Google (login, notifiche, crash, Play), Stripe
(pagamenti), hosting del sito, gestionale fatture.

### 5.3 Nell'app

- Informazioni → Privacy, Termini, Termini ristoratori, Licenze, © OpenStreetMap contributors,
  contatti.
- Consensi modificabili dal profilo; **Elimina account**.
- Richieste di copia dei dati (art. 15/20 GDPR): all'inizio via email a `privacy@`, esportazione con
  una query preparata da 🤖.

---

## 6. Pagamenti in sintesi

| | Ristoranti — Pro | Utenti — Plus |
|---|---|---|
| Dove si compra | sito (Stripe) | app (Google Play) |
| Prezzo indicativo | €12,90 + IVA/mese, €99 + IVA/anno | €1,49/mese, €9,99/anno IVA inclusa |
| Chi incassa e trattiene | Stripe (~1,5% + 0,25 € + ~0,7%) | Google (15%) |
| Fattura | elettronica SDI, emessa da HAPOSTO | ricevuta di Google (Google è il venditore verso l'utente per le regole IVA dello store) |
| Conferma al nostro database | webhook Stripe → Edge Function ✅ | verifica ricevuta + RTDN → Edge Function ✅ |
| Disdetta | portale Stripe dal sito | Google Play → Abbonamenti |
| Se il pagamento fallisce | 3 giorni poi Basic ✅ | periodo di tolleranza di Google, poi Gratis ✅ |
| Prova | modalità test Stripe | tester con licenza in Play Console |

---

## 7. Modifiche al database ancora da scrivere

| Migration | Contenuto | Fase |
|---|---|---|
| `0012_profile_hours_consents.sql` | modifica dati del locale da parte del titolare; orari di apertura; registro storico dei consensi; locale che torna "Non collegato" quando l'ultimo titolare cancella l'account; sospensione di un locale dall'area admin; storico disponibilità per Plus; pulizia automatica di storico stati e contatori oltre i periodi dichiarati nella privacy | C–E, F, M |
| `0013_notification_prefs.sql` | preferenze notifiche per utente (accese, fasce orarie) | G |
| `0014_billing_invoices.sql` | numero e stato della fattura elettronica collegati al pagamento | K |

Ogni migration nuova arriva con controlli automatici nella CI, come le 0006–0011.

---

## 8. Calendario indicativo

| Mese | Lavori |
|---|---|
| **Ottobre 2026** | A (prove sul campo) · B (dominio, commercialista, Google Cloud, keystore) · C (login ristoratore) |
| **Novembre 2026** | D (login utente) · E (gestione protetta, DEV/PROD) · F (documenti legali) · G (notifiche) |
| **Dicembre 2026** | H (sito, QR, admin) · I (produzione, directory Pesaro, test interno e chiuso) · reclutamento pilot |
| **Gennaio – febbraio 2027** | J (pilot, 6–8 settimane) · N (statistiche) |
| **Marzo 2027** | decisione sul pilot · L (pubblicazione su Play) · K in modalità test |
| **Aprile – maggio 2027** | K reale (Pro sul sito) · M (Plus) |
| **Giugno 2027** | O (comunicazione fine beta, 30 giugno) |
| **Da luglio 2027** | Pro a pagamento · P (espansione) · Q (gestione continuativa) |

---

## 9. Quando il progetto è "finito"

Il progetto passa da **costruzione** a **gestione** quando tutte queste condizioni sono vere:

- [ ] app su Google Play in produzione, versione PROD senza strumenti di prova;
- [ ] login reale: ristoratori verificati, utenti facoltativi, cancellazione account funzionante;
- [ ] privacy, termini e condizioni per i ristoranti pubblicati e accettati nell'app;
- [ ] Pesaro con directory completa e almeno 30 partner attivi, di cui almeno il 60% con stato valido a cena;
- [ ] notifiche ai ristoratori attive;
- [ ] Pro acquistabile sul sito con fatture elettroniche corrette; Plus acquistabile nell'app;
- [ ] backup verificati, 2FA su tutti gli account, keystore al sicuro;
- [ ] routine della Fase Q avviata.

Da lì in poi il lavoro è: tenere alta la freschezza degli stati, aggiungere zone, e far crescere i
partner paganti.
