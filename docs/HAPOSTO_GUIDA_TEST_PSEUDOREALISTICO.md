# HAPOSTO — Come provare l'app in modalità "pseudo-realistica"

Questa guida porta l'app da **DEMO** (dati finti dentro il telefono, sempre uguali) a un
**ambiente di prova che si comporta come una vera serata**:

- 36 locali inventati ma credibili tra Pesaro, Fano, Urbino e Gabicce Mare;
- i loro stati cambiano da soli durante il giorno (pranzo e cena più affollati, venerdì e sabato
  ancora di più, di notte gli stati scadono);
- alcuni locali sono "pigri" e lasciano scadere lo stato, così vedi anche "Da aggiornare";
- **due telefoni vedono la stessa cosa**: su uno fai il ristoratore, sull'altro il cliente.

Tempo necessario: circa 30–40 minuti la prima volta.

> I dati sono tutti **inventati** (nomi, telefoni, stati). Le vie esistono, solo per realismo.
> Non pubblicare mai questo ambiente: è il progetto Supabase **DEV**.

---

## 0. I tre livelli di prova

| Livello | Dove sono i dati | Cosa vedi nell'app | A cosa serve |
|---|---|---|---|
| **DEMO** | nel telefono | badge **DEMO**, 10 locali fissi | provare le schermate senza internet |
| **DEV pseudo-realistico** (questa guida) | Supabase DEV + simulatore | badge **SUPABASE DEV**, 43 locali che cambiano | provare il prodotto come in una serata vera, anche con 2 telefoni |
| **Pilot reale** | Supabase di produzione | locali veri, gestiti dai titolari | test con ristoratori e clienti veri (vedi `HAPOSTO_GUIDA_APP_E_DATI_REALI.md`) |

---

## 1. Cosa ti serve

- Il progetto Supabase **DEV** già creato, con le migration 0001–0004 eseguite (lo hai fatto allo Step 7).
  Se non l'hai ancora fatto: `docs/STEP_7_SETUP_SUPABASE.md`.
- Android Studio con il progetto aggiornato (ultima versione di `main`).
- Uno o due telefoni Android (o un telefono + l'emulatore).

---

## 2. Aggiorna il database DEV (una volta sola)

Segui **`docs/HAPOSTO_GUIDA_AGGIORNAMENTO_DB.md`**, capitoli 2 e 3: esegui in ordine le migration
`0006` → `0011`. Servono anche al pseudo-realistico (colonna `data_source`, statistiche, ecc.).

---

## 3. Carica i 36 locali pseudo-realistici

1. Supabase → **SQL Editor** → **New query**.
2. Apri sul PC il file `supabase/seeds/910_pseudo_realistic_dev_seed.sql`, copia **tutto** e incollalo.
3. Premi **Run**.
4. Risultato atteso: `Success. No rows returned`.

Controllo veloce (nuova query):

```sql
select city, count(*) as locali
from public.restaurants
where data_source = 'DEV_SEED'
group by city order by locali desc;
```

Devi vedere Pesaro, Fano, Urbino e Gabicce Mare (in tutto 43 locali: i 36 nuovi + i 7 "Demo" dello Step 7).

---

## 4. Accendi il simulatore

### 4.1 Attiva pg_cron (serve per farlo girare da solo ogni 5 minuti)

Supabase → **Database** → **Extensions** → cerca **pg_cron** → interruttore **Enable**.

### 4.2 Installa gli strumenti DEV

1. SQL Editor → New query.
2. Incolla tutto `supabase/dev/dev_tools.sql` → **Run**.
3. Risultato atteso: una tabellina `locali_aggiornati_ora` con un numero (0 di notte, 5–25 di giorno)
   e il messaggio *"Simulatore pianificato ogni 5 minuti"*.

Da questo momento:

- ogni 5 minuti il simulatore aggiorna i locali di prova come farebbero i titolari;
- l'app può **scrivere davvero** lo stato dei locali di prova (solo quelli `DEV_SEED`).

Per forzare subito un giro (utile di sera per vedere cambiamenti):

```sql
select public.dev_simulate_live_activity();
```

Il simulatore segue l'**ora italiana**:

| Fascia | Comportamento |
|---|---|
| 10:30–11:30 e 14:45–18:45 | quasi tutti "C'è posto" |
| 11:30–14:45 (pranzo) | misto, qualche "Completo" |
| 18:45–23:00 (cena) | molti "Pochi posti" e "Completo"; venerdì e sabato ancora di più |
| 23:00–10:30 (notte) | nessun aggiornamento: gli stati scadono e diventano "Da aggiornare" |

---

## 5. Collega l'app al database DEV

1. Nella cartella del progetto apri (o crea) `local.properties` e scrivi, senza virgolette:
   ```
   SUPABASE_URL=https://IL_TUO_REF.supabase.co
   SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
   ```
   (li trovi in Supabase → **Project Settings** → **API**. Mai la chiave `secret`/`service_role`.)
2. Android Studio: **File → Sync Project with Gradle Files**, poi **Run ▶** sul telefono.
3. In alto nella Home deve comparire il badge **SUPABASE DEV**.

L'app ricarica la lista **da sola ogni minuto** e subito dopo ogni tua pubblicazione.

---

## 6. Scenari di prova

### 6.1 Un telefono — il cliente

| # | Cosa fai | Cosa deve succedere |
|---|---|---|
| 1 | Apri l'app | Badge SUPABASE DEV, lista di locali di Pesaro ordinati per distanza |
| 2 | Tocca **Mostra solo dove c'è posto** | Restano solo i locali ✓ "C'è posto" |
| 3 | Riga 📍 → **Cambia** → **Fano** | Lista e distanze cambiano, in cima i locali di Fano |
| 4 | Aspetta 5–10 minuti con l'app aperta | Alcuni stati cambiano da soli (il simulatore ha lavorato) |
| 5 | Apri **Ristorante Tre Porte** o **Pasta Fresca Villa Fastiggi** (Pesaro): sono locali "pigri" che il simulatore aggiorna di rado | Il più delle volte: **? Da aggiornare** |
| 6 | Apri un locale "Non collegato" (es. **Locanda del Foglia**) | Stato "– Non collegato", nessun tasto di stato |
| 7 | Nel dettaglio tocca **☆ Salva nei preferiti**, poi tab **Preferiti** | Il locale compare con il suo stato live |
| 8 | Metti il telefono offline | Banner "Sei offline", la lista resta visibile |
| 9 | Torna online | Dopo al massimo un minuto la lista si aggiorna da sola |

### 6.2 Due telefoni — ristoratore e cliente (la prova più importante)

Telefono **A** = ristoratore, telefono **B** = cliente. Entrambi con l'app collegata a DEV.

1. **A**: tab **Ristoratore** → *Continua con Google · demo locale* → cerca **Osteria del Fanale Verde**
   → *Questo è il mio locale* → invia → *Simula approvazione admin* → **Apri dashboard**.
2. **B**: Home su *Pesaro centro*, trova **Osteria del Fanale Verde**.
3. **A**: tocca il tasto rosso **✕ Completo**.
4. **B**: entro 1 minuto (o cambiando area avanti e indietro) vede **✕ Completo**, "aggiornato ora".
5. **A**: tocca **✓ È ancora così: confermo** → su **B** l'orario torna "aggiornato ora".
6. **A**: apri *Dettagli facoltativi* → tavoli 3, attesa 10 min → *Aggiorna dettagli e riconferma*
   → **B** vede "3 tavoli liberi · attesa ~10 min".
7. Aspetta: il simulatore **non tocca** per 3 ore un locale aggiornato a mano dall'app.

> Nota: in questo ambiente il login ristoratore è ancora **dimostrativo** (Step 4–7). Il login Google
> vero e la scrittura protetta arrivano con gli Step 8–9: le funzioni SQL sono già pronte (0007–0008).

> Vuoi far provare la dashboard a un **ristoratore vero**, con il suo locale, durante una cena?
> Si fa già adesso su questo ambiente: `HAPOSTO_GUIDA_APP_E_DATI_REALI.md`, capitolo 4.
> Il simulatore non tocca quel locale.

### 6.3 Prove di "serata"

- Fai le prove alle **20:30** di un venerdì: vedrai molti "Completo" e "Pochi posti".
- Fai le prove alle **8:00**: quasi tutto "Da aggiornare" (è notte per il simulatore). Realistico:
  la mattina nessuno aggiorna.
- Vuoi vedere subito un cambio? `select public.dev_simulate_live_activity();` e attendi il refresh.

---

## 7. Guardare cosa succede nel database

```sql
-- Stato attuale dei locali di prova, dal più recente
select r.name, r.city, s.status, s.available_tables, s.estimated_wait_minutes, s.note,
       s.updated_via, s.updated_at at time zone 'Europe/Rome' as aggiornato,
       s.valid_until > now() as ancora_valido
from public.restaurants r
join public.restaurant_live_status s on s.restaurant_id = r.id
where r.data_source = 'DEV_SEED'
order by s.updated_at desc;

-- Ultime 20 pubblicazioni (simulatore = DEV_SIMULATOR, app = DEV_APP)
select r.name, h.status, h.updated_via, h.updated_at at time zone 'Europe/Rome' as quando
from public.status_history h join public.restaurants r on r.id = h.restaurant_id
order by h.updated_at desc limit 20;

-- Quante volte ha girato il simulatore
select jobname, status, start_time from cron.job_run_details
order by start_time desc limit 10;
```

---

## 8. Problemi comuni

| Problema | Causa probabile | Soluzione |
|---|---|---|
| Badge **DEMO** invece di SUPABASE DEV | `local.properties` non letto | controlla i nomi delle due righe, Sync, Clean, Rebuild |
| "Configurazione Supabase incompleta" | manca una delle due righe | mettile entrambe |
| Gli stati non cambiano mai | pg_cron non attivo o è notte | attiva pg_cron, riesegui `dev_tools.sql`, prova `select public.dev_simulate_live_activity();` |
| Il telefono B non vede le modifiche di A | strumenti DEV non installati o spenti | riesegui `dev_tools.sql`; controlla `select value from public.app_config where key='dev_tools_enabled';` → `true` |
| Tutto "Da aggiornare" | sei di notte (23:00–10:30) | normale; oppure forza un giro del simulatore |
| Errore `NOT_A_DEV_PARTNER` nei log | stai modificando un locale non di prova | si possono pubblicare solo i locali `DEV_SEED` partner |

---

## 9. Ripulire tutto

Quando vuoi ripartire da zero, o **sempre prima di passare in produzione**:

1. SQL Editor → incolla `supabase/dev/dev_purge.sql` → **Run**.
2. Effetto: simulatore fermato, strumenti DEV cancellati, tutti i locali `DEV_SEED` eliminati.
   Gli account e i locali reali non vengono toccati.

Per rimettere i dati di prova: ripeti i passi 3 e 4.
