# 2026-10-02 — Note pronte, menù/sito/file del locale e offerta della serata

- **Data:** 2 ottobre 2026
- **Branch:** `claude/amazing-pasteur-dull9l`
- **PR:** [#17](https://github.com/paolomarchionetti-glitch/haposto/pull/17)
- **Motivo:** richieste del titolare per i ristoratori, sempre con poche opzioni semplici:
  - **note pronte** create e memorizzate per locale, da scegliere con un tocco;
  - **due link** (sito e menù) e **un file facoltativo** (foto o PDF piccolo), con limite di
    dimensione imposto dal database, foto "solo per oggi" che si cancellano da sole e
    **controllo dell'admin**; mai un menù scritto a mano nell'app;
  - **offerta della serata** facoltativa, scelta tra poche proposte o dettata, sotto la
    responsabilità del ristoratore.
  Tutto restando nel piano Free di Supabase (1 GB di spazio, 5 GB di traffico al mese).

## File modificati, aggiunti ed eliminati

| File | Tipo |
|---|---|
| `supabase/migrations/0015_notes_links_file_offer.sql` | aggiunto |
| `supabase/migrations/0011_public_page_stats_import.sql` | modificato |
| `supabase/migrations/0013_profile_consents_account.sql` | modificato |
| `supabase/tests/step19_notes_links_file_offer_checks.sql` | aggiunto |
| `supabase/ops/restaurant_files_cron.sql` | aggiunto |
| `supabase/functions/_shared/files.ts` | aggiunto |
| `supabase/functions/_shared/files_test.ts` | aggiunto |
| `supabase/functions/restaurant-file/index.ts` | aggiunto |
| `.github/workflows/android-ci.yml` | modificato |
| `.gitignore` | modificato |
| `app/src/main/java/com/haposto/domain/model/AvailabilityRules.kt` | modificato |
| `app/src/main/java/com/haposto/domain/model/LiveAvailability.kt` | modificato |
| `app/src/main/java/com/haposto/domain/model/EffectiveAvailability.kt` | modificato |
| `app/src/main/java/com/haposto/domain/usecase/AvailabilityResolver.kt` | modificato |
| `app/src/main/java/com/haposto/domain/voice/DetailsDictation.kt` | modificato |
| `app/src/main/java/com/haposto/data/Outcome.kt` | modificato |
| `app/src/main/java/com/haposto/data/repository/RestaurantRepository.kt` | modificato |
| `app/src/main/java/com/haposto/data/remote/supabase/NearbyRestaurantDto.kt` | modificato |
| `app/src/main/java/com/haposto/data/remote/supabase/SupabaseRestaurantRepository.kt` | modificato |
| `app/src/main/java/com/haposto/data/remote/supabase/SupabaseManagementRepository.kt` | modificato |
| `app/src/main/java/com/haposto/data/remote/supabase/SupabaseConsumerRepository.kt` | modificato |
| `app/src/main/java/com/haposto/data/remote/supabase/SupabaseAdminRepository.kt` | modificato |
| `app/src/main/java/com/haposto/data/restaurant/RestaurantManagementRepository.kt` | modificato |
| `app/src/main/java/com/haposto/data/restaurant/ManagementModels.kt` | modificato |
| `app/src/main/java/com/haposto/data/consumer/ConsumerRepository.kt` | modificato |
| `app/src/main/java/com/haposto/data/admin/AdminModels.kt` | modificato |
| `app/src/main/java/com/haposto/data/admin/AdminRepository.kt` | modificato |
| `app/src/main/java/com/haposto/platform/files/RestaurantFileReader.kt` | aggiunto |
| `app/src/main/java/com/haposto/ui/components/RestaurantCard.kt` | modificato |
| `app/src/main/java/com/haposto/ui/util/ExternalActions.kt` | modificato |
| `app/src/main/java/com/haposto/ui/screens/detail/RestaurantDetailRoute.kt` | modificato |
| `app/src/main/java/com/haposto/ui/screens/detail/RestaurantDetailScreen.kt` | modificato |
| `app/src/main/java/com/haposto/ui/screens/restaurant/RestaurantManagerRoute.kt` | modificato |
| `app/src/main/java/com/haposto/ui/screens/restaurant/RestaurantManagerScreen.kt` | modificato |
| `app/src/main/java/com/haposto/ui/screens/restaurant/RestaurantManagerUiState.kt` | modificato |
| `app/src/main/java/com/haposto/ui/screens/restaurant/RestaurantManagerViewModel.kt` | modificato |
| `app/src/main/java/com/haposto/ui/screens/settings/RestaurantSettingsRoute.kt` | modificato |
| `app/src/main/java/com/haposto/ui/screens/admin/AdminRoute.kt` | modificato |
| `app/src/main/java/com/haposto/ui/screens/admin/AdminViewModel.kt` | modificato |
| `app/src/test/java/com/haposto/domain/AvailabilityResolverTest.kt` | modificato |
| `app/src/test/java/com/haposto/domain/voice/DetailsDictationTest.kt` | modificato |
| `app/src/test/java/com/haposto/data/remote/supabase/SupabaseRestaurantRepositoryTest.kt` | modificato |
| `app/src/test/java/com/haposto/ui/screens/restaurant/RestaurantManagerViewModelTest.kt` | modificato |
| `app/src/main/java/com/haposto/data/restaurant/SharedPrefsRecentNotesStore.kt` | modificato (`edit { }`) |
| `web/src/404.html` | modificato |
| `web/src/assets/style.css` | modificato |
| `docs/HAPOSTO_GUIDA_CONFIGURAZIONE_COMPLETA.md` | modificato |
| `docs/HAPOSTO_GUIDA_APP_TUTORIAL.md` | modificato |
| `docs/HAPOSTO_STATO_CONFIGURAZIONE.md` | modificato |
| `README.md` | modificato |
| `docs/modifiche/2026-10-02_pr17-dettatura-e-prenotazioni-veloci.md` | rinominato (era `…_pr18-…`: la parte A è entrata nella PR #17) |
| `docs/modifiche/2026-10-02_pr17-note-pronte-link-file-offerta.md` | aggiunto (questo file) |

Nessun file eliminato.

## Dettaglio delle modifiche

### Database (migration 0015, rieseguibile)

- **Locali**: nuove colonne `quick_notes` (al massimo 8 note da 1–80 caratteri), `website_url` e
  `menu_url` (solo `http://`/`https://`, al massimo 300 caratteri), `file_path`, `file_mime`,
  `file_bytes`, `file_expires_at` e le date di modifica e di controllo admin. Vincoli nel database:
  solo JPEG/WebP fino a 1 MB o PDF fino a 2 MB, percorso del file legato all'id del locale.
- **Contenitore `restaurant-files`** (Supabase Storage): pubblico in lettura, limite 2 MB, solo
  JPEG/WebP/PDF. Nessuno scrive direttamente: solo la Edge Function con la chiave del server.
- **Offerta**: colonna `offer` (60 caratteri) sullo stato pubblicato e nello storico. Si salva solo
  con il piano che include i dettagli e mai con lo stato **Completo**; scade con lo stato.
  `set_restaurant_live_status` ha una versione a 6 argomenti; quella a 5 resta e chiama la nuova:
  le app già installate continuano a pubblicare.
- **Letture pubbliche**: `nearby_restaurants`, `restaurant_public_details` e `public_restaurant_page`
  restituiscono anche offerta, link e file (ricreate perché cambiano le colonne). Nella 0011 e nella
  0013 un `drop function if exists` prima della ricreazione, così rieseguire le migration in ordine
  funziona anche dopo la 0015.
- **Funzioni nuove**: `restaurant_extras` (lettura per lo staff), `set_restaurant_quick_notes`
  (titolare e staff; spazi e doppioni tolti), `set_restaurant_links` (solo titolare; `https://`
  aggiunto se manca), `restaurant_file_check`, `restaurant_file_attach`, `restaurant_file_detach`,
  `restaurant_files_cleanup` (solo il server), `admin_list_restaurant_extras` e
  `admin_review_restaurant_extras` (Visto / Togli link / Togli file / Togli tutto). Ogni modifica
  finisce nel registro operazioni. Un locale tornato "solo directory" perde note, link e file.
- **Controlli** `supabase/tests/step19_notes_links_file_offer_checks.sql` (45 controlli), eseguiti
  dalla CI anche sul "nuovo progetto di produzione".

### Edge Function `restaurant-file`

- **Caricamento** (titolare con 2FA di un locale partner attivo): controlla il contenuto vero del
  file (non il nome): JPEG, WebP o PDF; foto al massimo 1 MB e 2000 px per lato, PDF al massimo
  2 MB; poi lo salva, lo collega al locale e cancella il file precedente.
- **Rimozione** (titolare) e **pulizia notturna** (pg_cron con il segreto condiviso, file
  `supabase/ops/restaurant_files_cron.sql`): toglie le foto "solo per oggi" dopo le 4 del mattino
  e cancella dal contenitore i file che nessun locale usa più.
- Codice comune e test in `_shared/files.ts` / `files_test.ts`.

### App

- **Dashboard, Dettagli facoltativi**: note pronte del locale con un tocco e tasto **＋ Salva questa
  nota tra le note pronte**; ultime note del telefono (senza ripetere quelle pronte); **Offerta della
  serata** con quattro proposte (−10%, −20%, Dolce offerto, Calice offerto) o testo libero o dettato
  («offerta …»), avviso di responsabilità la prima volta, mai inviata con **Completo**.
- **Gestisci il locale**: sezione **Note pronte** (titolare e staff) e **Menù, sito e file** (solo
  titolare con 2FA): due link, un file; la foto la riduce il telefono (lato massimo 1600 px,
  rotazione corretta, sotto i 900 KB), il PDF fino a 2 MB; domanda **Vale solo per oggi?**.
- **Clienti**: nella scheda del locale la riga "🏷 Offerta di stasera" e i tasti **Menù e sito**;
  nella lista il simbolo 🏷. Si aprono solo indirizzi `http`/`https`.
- **Pannello admin**: nuova scheda **Contenuti** (da controllare / tutti) con link apribili e tasti
  Visto / Togli link / Togli file.
- Messaggi d'errore in italiano per i nuovi codici (nota troppo lunga, link non valido, file troppo
  grande o di tipo non ammesso…).

### Sito

- Pagina pubblica del locale (`/r/…`): offerta (non con Completo) e tasti Menù / Menù (PDF) / Sito
  del locale, solo con indirizzi `http`/`https`.

### Documenti e altro

- Guida: funzione `restaurant-file` nella Parte 6 (tabella, pubblicazione, 7 funzioni), pulizia
  notturna al punto 6.3, migration fino alla 0015 al punto 10.2 (con controllo del contenitore),
  pubblicazione e pulizia in produzione al punto 10.8; nella Parte 11 il controllo dei contenuti e
  la procedura per ogni nuova migration (prima DEV, poi produzione).
- Tutorial: punti 3.3, 4.4 e nuovo 4.5 bis.
- Stato della configurazione: passi da fare sul DEV dopo l'unione (migration 0015, funzione
  `restaurant-file`, pulizia notturna, ping, prova dell'app); README con i numeri aggiornati.
- `.gitignore`: i file `.log` che il job SQL della CI scrive nella cartella principale quando lo si
  replica in locale.

## Costi

Nessuno. Il contenitore dei file sta nel piano Free: con file al massimo da 1–2 MB, uno per locale,
300 locali occupano al massimo 600 MB. Le trasformazioni delle immagini di Supabase (a
pagamento) non servono: le foto le riduce il telefono e la funzione rifiuta quelle troppo grandi.

## Verifiche

Eseguite in locale prima dell'invio (l'SDK Android qui non si scarica: build, lint e test su
emulatore li fa la CI).

- **Job "Supabase SQL" della CI** replicato per intero su Postgres 16 + PostGIS (passi letti dal
  workflow): migration 0001–0015 e loro riesecuzione, controlli step8_to_17, step18 e **step19
  (45 controlli nuovi)**, ordine della guida, KPI, import OSM, strumenti e pulizia DEV, **nuovo
  progetto di produzione** senza permessi automatici (stessi permessi del DEV, step19 compreso):
  tutto verde.
- **Edge Function** (Deno 2): `deno check */index.ts`, `deno lint`, `deno test --allow-env`
  (13 test, compresi quelli nuovi sul riconoscimento dei file) e `deno fmt --check` sui file nuovi.
- **Kotlin** (2.4.10, progetti JVM di prova con gli stessi file dell'app):
  - tutto il dominio: 60 test verdi (resolver con l'offerta, dettatura con «offerta …»);
  - tutto il livello dati compilato contro supabase-kt 3.7.0 (repository Supabase compresi:
    caricamento del file con `functions.invoke`, note pronte, link, pannello admin): 42 test verdi,
    compreso il nuovo `theOfferTravelsWithTheStatus_butNeverWithFull`;
  - ViewModel della dashboard (con piccoli sostituti di `androidx.lifecycle`): 6 test verdi, due
    nuovi sull'offerta (pubblicata con lo stato, mai con Completo, tagliata a 60 caratteri).
- **Schermate Compose** (non compilabili qui) rilette una per una: corretti un riferimento a
  funzione locale (ora lambda), le preferenze scritte con `edit { }` di core-ktx come nel resto
  dell'app e il filtro **Tutti** della scheda Contenuti, che dopo "Visto" tornava a "Da controllare".
- **Sito**: `node web/build.mjs`, `node --test web/tests/*.test.mjs` (4 test) e prova in Chromium
  della pagina `/r/…` con un finto Supabase: offerta e tasti Menù (PDF) / Sito del locale; un link
  `javascript:` viene scartato; con **Completo** nessuna offerta e nessun "null".
- CI su GitHub: vedi la PR.
