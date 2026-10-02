# 2026-09-30 — Parte 6: generatore di segreti corretto, prova delle notifiche, diagnosi

- **Data:** 30 settembre 2026 (registro scritto il 2 ottobre 2026)
- **PR:** [#10](https://github.com/paolomarchionetti-glitch/haposto/pull/10)

## File modificati e aggiunti

| File | Tipo |
|---|---|
| `docs/HAPOSTO_GUIDA_CONFIGURAZIONE_COMPLETA.md` | modificato |

## Dettaglio delle modifiche

- **Generatore di segreti (6.2):** il comando PowerShell `Get-Random -Count 48` su 16 caratteri
  pesca senza ripetizioni e dava solo 16 caratteri. Sostituito con `RandomNumberGenerator`
  (48 caratteri esadecimali, compatibile con Windows PowerShell 5.1); tolto il generatore online.
- **6.1:** terminale di Android Studio, login dal browser, password del database non necessaria a
  `link`; tutte le funzioni si possono pubblicare subito (senza segreti rifiutano le chiamate).
- **6.2:** colonna "Quando" per i segreti; come capire se servono `HAPOSTO_SECRET_KEY` e
  `HAPOSTO_PUBLISHABLE_KEY`.
- **6.3:** indirizzo senza `/` finale, query col segreto da eliminare dall'editor, come cambiare un
  valore del vault, prova con una notifica in coda, significato delle risposte della funzione.

## Verifiche

- PowerShell 7: comando vecchio 16 caratteri, nuovo 48.
- Supabase CLI 2.118: `link` e `functions deploy --use-api` funzionano senza `supabase/config.toml`.
- Immagine `supabase/postgres` 17 con `pg_cron`, `pg_net` e vault: script pianificati eseguiti due
  volte, ogni comando pianificato eseguito, chiamata a `push-dispatch` costruita dal vault.
