# Fotografia dello schema del database

Questa cartella contiene il **dump dello schema** del progetto Supabase, cioè la "fotografia" di
com'è fatto il database in un certo giorno. Serve **solo da consultare**: non si esegue.

| File | Data | Progetto | Versioni |
|---|---|---|---|
| `2026_10_05_-_haposto_schema.sql` | 5 ottobre 2026 | DEV | database PostgreSQL 17.6 · `pg_dump` 18.4 |

## Cosa contiene e cosa no

| Contiene | Non contiene |
|---|---|
| Schemi, tabelle, colonne, vincoli, indici | **Dati** (nessuna riga di nessuna tabella) |
| Funzioni e trigger (`public` e quelli interni di Supabase: `auth`, `storage`, `realtime`…) | **Permessi** (`GRANT`) e proprietari: il dump è fatto senza |
| Regole di sicurezza (RLS) e policy | **Lavori pianificati** (`cron.job` sono dati) |
| Pubblicazione del tempo reale (`supabase_realtime`) | **Segreti** del vault, chiavi, password, identificativo del progetto |

Controllo del 6 ottobre 2026: le 118 funzioni e le 25 tabelle di `public` sono esattamente quelle
delle migration `0001`–`0017` più gli strumenti DEV (`supabase/dev/dev_tools.sql`). Il progetto DEV
era quindi allineato al codice.

## A cosa serve

- Cercare com'è scritta **davvero** una funzione o una tabella sul progetto, senza aprire Supabase.
- **Confrontare** il progetto con le migration del repository (per esempio dopo un aggiornamento o
  prima della Parte 10).
- Avere un riferimento storico: con Git si vede cosa è cambiato da un dump all'altro.

## ⚠️ Non eseguirlo

- **Non** incollarlo nel SQL Editor e **non** usarlo per creare un progetto: contiene gli schemi
  interni di Supabase (che esistono già) e i comandi `\restrict` / `\unrestrict` di `pg_dump` 18,
  che l'SQL Editor rifiuta.
- Per creare o aggiornare un progetto si usano **solo le migration**, nell'ordine della guida
  (`docs/HAPOSTO_GUIDA_CONFIGURAZIONE_COMPLETA.md`, Parte 10.2 e Parte 11).

## Come rifare il dump (quando serve)

1. Supabase → il progetto → pulsante **Connect** in alto → **Session pooler** → copia la stringa di
   connessione e sostituisci `[YOUR-PASSWORD]` con la password del database (dal gestore di
   password). **La stringa con la password non va mai nel repository né in chat.**
2. Dal terminale del PC, con `pg_dump` versione 17 o successiva:

   ```bash
   pg_dump "STRINGA_DI_CONNESSIONE" --schema-only --no-owner --no-privileges -f AAAA_MM_GG_-_haposto_schema.sql
   ```

3. Prima di aggiungerlo qui, controlla nel file (Blocco note → **Trova**) che non ci siano:
   `COPY ` o `INSERT INTO` (dati), `supabase.co` (identificativo del progetto), `sb_secret_`,
   `password` con un valore, email personali.
4. Metti il file nuovo in questa cartella al posto di quello vecchio (Git conserva la storia),
   aggiorna la tabella in cima a questo file e il registro in `docs/modifiche/`.
