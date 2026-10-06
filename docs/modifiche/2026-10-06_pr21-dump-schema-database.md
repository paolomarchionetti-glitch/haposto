# 2026-10-06 — Dump dello schema del database DEV

- **Data:** 6 ottobre 2026
- **Branch:** `claude/amazing-pasteur-dull9l`
- **PR:** [#21](https://github.com/paolomarchionetti-glitch/haposto/pull/21)
- **Motivo:** il titolare ha estratto il 5 ottobre 2026 il dump completo dello schema del progetto
  DEV e ha chiesto di aggiungerlo al repository, in una nuova cartella `supabase/database`.

## File modificati, aggiunti, rinominati ed eliminati

| File | Tipo |
|---|---|
| `supabase/database/2026_10_05_-_haposto_schema.sql` | aggiunto |
| `supabase/database/README.md` | aggiunto |
| `docs/HAPOSTO_STATO_CONFIGURAZIONE.md` | modificato |
| `docs/modifiche/2026-10-06_pr21-dump-schema-database.md` | aggiunto (questo file) |

Nessun file rinominato o eliminato.

## Dettaglio delle modifiche

### Dump dello schema (`supabase/database/2026_10_05_-_haposto_schema.sql`)

- È il file fornito dal titolare, senza modifiche al contenuto:
  - 11.978 righe;
  - database PostgreSQL 17.6, `pg_dump` 18.4;
  - solo struttura, senza proprietari né permessi.

  Git normalizza le fine riga (regola `* text=auto` del `.gitattributes`).
- **Contiene:**
  - schemi, 70 tabelle (25 in `public`), indici, vincoli;
  - 166 funzioni (118 in `public`), 23 trigger;
  - regole RLS e 27 policy;
  - le pubblicazioni del tempo reale.
- **Non contiene:** dati, `GRANT`, lavori pianificati, segreti del vault.

### Guida alla cartella (`supabase/database/README.md`)

- Cosa contiene il dump e cosa no.
- A cosa serve: consultazione e confronto con le migration.
- Perché **non** va eseguito:
  - contiene gli schemi interni di Supabase e i comandi `\restrict` di `pg_dump` 18;
  - per creare o aggiornare un progetto valgono solo le migration.
- Come rifarlo con la stringa di connessione del *Session pooler*, senza mai pubblicare la password.
- Cosa controllare prima di aggiungere un dump nuovo.

### Stato

`docs/HAPOSTO_STATO_CONFIGURAZIONE.md`, sezione 6: nuova voce sulla fotografia dello schema.

## Costi

Nessuno.

## Verifiche

- **Contenuto del file letto prima della pubblicazione** (il repository è pubblico). Risultati
  delle ricerche:
  - nessuna email personale (l'unica è `info@haposto.app`, già nel codice);
  - nessun indirizzo `….supabase.co` né identificativo del progetto;
  - nessuna chiave (`sb_secret_`, `sb_publishable_`, `eyJ…`, `AIza…`, `GOCSPX-`, `whsec_`, chiavi
    Stripe, chiavi private);
  - nessun dato (`COPY`, `INSERT INTO`);
  - nessun numero di telefono o indirizzo IP.
- **Allineamento con il repository:**
  - le 118 funzioni di `public` nel dump sono esattamente quelle definite dalle migration
    `0001`–`0017` e da `supabase/dev/dev_tools.sql` (nessuna in più, nessuna in meno);
  - le 25 tabelle di `public` sono le stesse delle migration.
- Il file sta fuori dalle cartelle che usa la CI (`supabase/migrations`, `supabase/tests`,
  `supabase/functions`): la CI non lo esegue. CI su GitHub: vedi la PR.
