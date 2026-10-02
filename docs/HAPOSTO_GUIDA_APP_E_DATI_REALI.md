# HAPOSTO — L'app oggi e la strada verso dati reali e test veri

Questa guida spiega **com'è fatta l'app adesso**, **cosa è vero e cosa è simulato**, e i passi
concreti per arrivare a **locali reali** e **prove con ristoratori veri**.

Documenti collegati:

- `HAPOSTO_GUIDA_APP_TUTORIAL.md` — come si usa l'app, schermata per schermata;
- `HAPOSTO_GUIDA_TEST_PSEUDOREALISTICO.md` — ambiente DEV con 36 locali e simulatore;
- `HAPOSTO_GUIDA_AGGIORNAMENTO_DB.md` — come aggiornare Supabase;
- `HAPOSTO_ROADMAP_INTEGRATIVA.md` — ordine dei lavori fino al lancio.

---

## 1. L'app oggi, in parole semplici

```
Telefono (app Android)
   │  chiave "publishable" (pubblica, sta nell'app)
   ▼
Supabase (database Postgres in cloud)
   ├─ nearby_restaurants  → lista dei locali vicini con lo stato (+ tempo reale)
   ├─ set_restaurant_live_status → pubblica SOLO titolare/staff con verifica in due passaggi
   └─ simulatore ogni 5 min → (solo DEV) i locali di prova si aggiornano da soli
```

Le versioni dell'app sono tre (Android Studio → *Build Variants*): **Demo** (`demoDebug`, dati di
prova dentro il telefono, nessun account), **Dev** (`devDebug`, progetto Supabase DEV con account
veri) e **Prod** (produzione). Configurazione: `HAPOSTO_GUIDA_CONFIGURAZIONE_COMPLETA.md`.

### Cosa è vero e cosa è simulato oggi

| Parte | Versione Dev / Prod | Versione Demo |
|---|---|---|
| Lista, mappa, ricerca, filtro, distanze, posizione | **vera** | vera (dati nel telefono) |
| Stati dei locali | **veri**, in tempo reale | simulati |
| Locali in elenco | seed DEV o import OpenStreetMap (§3) | 10 fissi |
| Accesso ristoratore | **Google + verifica in due passaggi** | simulato |
| Approvazione della richiesta | **pannello admin** con codice dettato al telefono del locale | simulata (tasto) |
| Pubblicazione dello stato | solo titolare e staff verificati | simulata |
| Preferiti | nel telefono e, con account, sincronizzati | nel telefono |
| Notifiche, pagina pubblica, QR, statistiche, Plus, Pro | vere (dopo la configurazione di Firebase, Play, Stripe, sito) | non disponibili |

---

## 2. I tre ambienti

| | DEMO | DEV | PRODUZIONE |
|---|---|---|---|
| Dove sono i dati | nel telefono | progetto Supabase `haposto-dev` | progetto Supabase `haposto-prod` (nuovo) |
| Locali | 10 fissi | 43 inventati + eventuali "prove sul campo" | reali (OpenStreetMap + partner) |
| Chi pubblica | nessuno (solo in memoria) | simulatore + titolari/staff verificati | solo titolari e staff verificati |
| Migration | — | 0001–0013 (la 0014 è innocua ma non serve) | 0001–0014, compresa la 0005 |
| Seed e `dev/` | — | sì | **mai** |
| A cosa serve | provare le schermate | provare il prodotto, prove sul campo | pilot e lancio |

Regole d'oro:

1. **Due progetti Supabase separati**: DEV e PRODUZIONE non si mescolano mai.
2. In PRODUZIONE non si esegue niente della cartella `supabase/dev/` né `supabase/seeds/`.
3. Nell'app va **solo** la chiave `publishable`. La chiave `secret`/`service_role` non va mai nell'app,
   né in GitHub, né in chat.
4. Un progetto Supabase gratuito viene **messo in pausa dopo 7 giorni senza attività**: per il pilot
   usa il piano Pro (backup giornalieri, nessuna pausa).

---

## 3. Locali reali: importare la directory da OpenStreetMap

OpenStreetMap (OSM) è la mappa libera del mondo. Contiene gran parte dei ristoranti di Pesaro con
nome, indirizzo e posizione. Importarli dà all'utente una lista **completa** fin dal primo giorno:
i locali non partner compaiono come **"– Non collegato"** e diventano "live" quando il titolare aderisce.

Tempo: 15 minuti per città. Si può rifare ogni mese: non crea doppioni.

### 3.1 Scarica i ristoranti da Overpass Turbo

1. Apri **https://overpass-turbo.eu** dal browser.
2. Cancella il testo a sinistra e incolla (cambia `Pesaro` con il comune che vuoi):

   ```
   [out:json][timeout:90];
   area["boundary"="administrative"]["admin_level"="8"]["name"="Pesaro"]->.comune;
   nwr["amenity"="restaurant"]["name"](area.comune);
   out center tags;
   ```

   Vuoi anche pizzerie al taglio e piadinerie? Sostituisci la riga `nwr…` con:

   ```
   (
     nwr["amenity"="restaurant"]["name"](area.comune);
     nwr["amenity"="fast_food"]["cuisine"~"pizza|piadina"]["name"](area.comune);
   );
   ```

3. Premi **Esegui**. A destra compaiono i punti sulla mappa (per Pesaro circa 200–300).
4. **Esporta** → sezione **Dati** → **dati OSM grezzi** (*raw OSM data*) → **Scarica**.
   Ottieni un file `export.json`.

### 3.2 Carica i locali in Supabase

1. Apri sul PC `supabase/ops/import_osm_overpass.sql`.
2. In alto, controlla **città e provincia di riserva** (`'Pesaro'`, `'PU'`): si usano quando OSM
   non le indica. Cambiale se importi un altro comune.
3. Apri `export.json` con Blocco note, **Ctrl+A**, **Ctrl+C**.
4. Nel file SQL seleziona la riga `INCOLLA_QUI_IL_JSON_DI_OVERPASS` e **incollaci sopra** il JSON
   (le righe `$osm$` sopra e sotto devono restare).
5. Supabase → **SQL Editor** → New query → incolla tutto il file → **Run**.
6. Risultato: una riga con `inserted` (nuovi), `updated` (aggiornati), `skipped` (partner o scartati).

Prima prova sul progetto **DEV**, guarda il risultato nell'app, poi ripeti sul progetto di produzione.

> Se vedi `invalid input syntax for type json` non hai sostituito la riga segnaposto, oppure il JSON
> è stato copiato a metà.

### 3.3 Controlla la qualità

```sql
-- Quanti locali per città
select city, count(*) as locali from public.restaurants
where data_source = 'OSM_IMPORT' group by city order by locali desc;

-- Locali senza indirizzo (in OSM manca via e civico): da completare
select name, city, category from public.restaurants
where data_source = 'OSM_IMPORT' and address = city order by city, name;

-- Possibili doppioni (stesso posto, nome simile)
select a.name as primo, a.data_source as fonte_1, b.name as secondo, b.data_source as fonte_2,
       round(extensions.st_distance(a.location, b.location)) as metri
from public.restaurants a
join public.restaurants b
  on a.id < b.id
 and extensions.st_dwithin(a.location, b.location, 40)
 and extensions.similarity(lower(a.name), lower(b.name)) > 0.4
order by metri;
```

### 3.4 Correggere e togliere locali

| Situazione | Cosa fare |
|---|---|
| Dato sbagliato in OSM | la cosa migliore è correggerlo su openstreetmap.org (serve un account gratuito): al prossimo import si aggiorna da solo |
| Vuoi correggerlo solo in HAPOSTO | modificalo in Table Editor **e** metti `data_source` = `MANUAL`: gli import successivi non lo toccano e non lo duplicano |
| Locale chiuso | `update public.restaurants set partnership_status = 'SUSPENDED' where id = 'ID';` → sparisce dalle ricerche |
| Un locale diventa partner | gli import non modificano più i suoi dati: li gestisce il titolare |

### 3.5 Licenza: obbligatorio citare OpenStreetMap

I dati OSM sono sotto licenza **ODbL**. Quando l'app o la pagina web li mostrano al pubblico serve la
scritta **"© OpenStreetMap contributors"** con link a `openstreetmap.org/copyright`, ad esempio nella
sezione "Come funziona HAPOSTO" e nel piè di pagina del sito. È nella lista di controllo del pilot (§6).
Per le prove sul progetto DEV non pubblico non serve.

---

## 4. Test veri, subito: la prova sul campo con un ristoratore amico

La cosa più utile di tutte: **vedere un ristoratore vero usare la dashboard durante un servizio**.
Si fa sul progetto **DEV**, con il login vero (Google + verifica in due passaggi).

### 4.1 Crea il suo locale nel DEV

SQL Editor del progetto DEV (cambia i valori; le coordinate le trovi in Google Maps: tasto destro sul
locale → il primo numero è la latitudine, il secondo la longitudine):

```sql
insert into public.restaurants (name, category, address, city, province, location,
                                phone_number, phone_public, partnership_status, data_source, source_ref)
values ('Trattoria Amica', 'Trattoria', 'Via Branca 1', 'Pesaro', 'PU',
        extensions.st_point(12.9138, 43.9125)::extensions.geography,   -- LONGITUDINE, LATITUDINE
        '0721 000000', true, 'ACTIVE_PARTNER', 'DEV_SEED', 'field-test:trattoria-amica')
on conflict do nothing
returning id, slug;
```

- `DEV_SEED` lo fa sparire con `dev_purge.sql` quando hai finito;
- `field-test:` dice al simulatore di **non toccarlo**: lo aggiorna solo il ristoratore.

### 4.2 Installa l'app sul suo telefono

- Collega il suo telefono al PC con il cavo, attiva *Opzioni sviluppatore → Debug USB*, e premi **Run ▶**
  in Android Studio; oppure
- **Build → Build App Bundle(s) / APK(s) → Build APK(s)**, invia il file `.apk` e fallo installare
  (Android chiederà di consentire l'installazione da questa fonte).

Installa la versione **Dev** (`devDebug`). Nell'app: tab **Ristoratore** → accede con il suo
account Google → accetta le condizioni → attiva la verifica in due passaggi → cerca il nome →
**È il mio locale: invia la richiesta**. Tu, dal pannello admin → **Richieste** → *Genera codice* →
glielo detti al telefono del locale → lui lo inserisce → **Approva**. Da quel momento vede la
dashboard (procedura completa: guida di configurazione, Parte 4.3).

> Se il suo telefono non ha il Google Play Services aggiornato o un'app di autenticazione, aiutalo
> a installare Google Authenticator prima della serata.

### 4.3 La prova

1. Spiega in 1 minuto la **regola dei tre momenti** (tutorial §4.3). Non di più: vuoi vedere se è chiaro da solo.
2. Lascialo usare l'app per **una cena intera**. Tu, dal tuo telefono, guardi cosa vede il cliente.
3. Il giorno dopo guarda i numeri:

   ```sql
   select h.status, h.updated_via, h.updated_at at time zone 'Europe/Rome' as quando
   from public.status_history h
   join public.restaurants r on r.id = h.restaurant_id
   where r.source_ref = 'field-test:trattoria-amica'
   order by h.updated_at;
   ```

4. Cinque domande, risposte da annotare parola per parola:
   1. In quali momenti ti sei ricordato di aggiornare? Quando te ne sei dimenticato?
   2. C'è stato un tasto o una scritta che non era chiaro?
   3. Quanto tempo ti è costato, in tutta la sera?
   4. Se domani un cliente ti dicesse "vi ho trovato su HAPOSTO", cosa penseresti?
   5. Lo useresti tutte le sere? Cosa te lo farebbe usare di più?

Obiettivo: almeno **3 ristoratori** e **2 serate** ciascuno prima del lancio.
Quello che emerge qui vale più di qualsiasi funzione nuova.

---

## 5. Test chiuso e pilot

### 5.1 Progetto di produzione (una volta sola)

1. Supabase → **New project** `haposto-prod`, regione **Europa (Frankfurt)**, password del database
   salvata nel tuo gestore di password.
2. SQL Editor: `0001`→`0014` in ordine, compresa la `0005` (procedura completa e verifica: guida di
   configurazione, Parte 10.2). **Niente seed, niente `dev/`.**
3. Import OpenStreetMap delle zone del pilot (§3).
4. Login Google, 2FA, credenziali admin, Edge Function e sito: guida di configurazione, Parte 10.
5. Controllo finale:

   ```sql
   select count(*) as dati_di_prova from public.restaurants where data_source = 'DEV_SEED';  -- deve essere 0
   ```

### 5.2 Test chiuso su Google Play

1. Play Console → crea l'app → **Test interno** (fino a 100 tester, subito disponibile).
2. Poi **Test chiuso**: per un account sviluppatore personale Google richiede almeno 12 tester per
   14 giorni prima di poter pubblicare in produzione. Coinvolgi amici e i ristoratori del §4.

### 5.3 Pilot

Segui `HAPOSTO_ROADMAP_INTEGRATIVA.md`, Step 13. Per ogni ristoratore:

1. visita o telefonata, spiegazione in 2 minuti, adesivo QR;
2. lui accede con Google e chiede la gestione del suo locale;
3. tu verifichi **chiamando il numero del locale** (non quello indicato nella richiesta) e approvi;
4. Pro gratis per il pilot: `admin_grant_restaurant_plan('ID', 'RESTAURANT_PRO', 6, 'Pilot Pesaro')`
   (oppure lascia valere la beta in `app_config`);
5. ogni lunedì: query KPI 1, 2, 3 di `supabase/ops/kpi_queries.sql` e telefonata ai "silenziosi".

---

## 6. Lista di controllo prima di mostrare l'app al pubblico

| Voce | Dove |
|---|---|
| Login Google reale, 2FA e approvazione con codice telefonico funzionanti | guida configurazione, Parte 4 |
| Pubblicazione solo da titolare/staff verificati (nella versione Prod non esistono tasti demo) | database 0012 + versione `prod` |
| La versione Prod non mostra etichette "DEMO"/"DEV" né testi sulle attività fittizie | automatico nella variante `prod` |
| Scritta "© OpenStreetMap contributors" se si usano dati OSM | Home ("Come funziona HAPOSTO") e sito |
| Privacy policy pubblica e modulo "Sicurezza dei dati" compilato | Play Console, Step 15 |
| Termini e condizioni ristoratori accettati al primo accesso (con approvazione specifica) | app, Account e tab Ristoratore |
| Progetto di produzione su piano Pro con backup | Supabase |
| Nessun dato `DEV_SEED` in produzione | query §5.1 |
| `min_supported_app_version` aggiornato | `app_config` |
