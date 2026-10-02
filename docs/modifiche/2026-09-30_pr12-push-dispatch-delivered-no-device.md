# 2026-09-30 — push-dispatch: risposta che distingue notifiche arrivate e senza telefono

- **Data:** 30 settembre 2026 (registro scritto il 2 ottobre 2026)
- **PR:** [#12](https://github.com/paolomarchionetti-glitch/haposto/pull/12)
- **Motivo:** la funzione rispondeva `{"sent":1}` anche quando l'account non aveva nessun telefono
  registrato (token tolto come non valido e app non riaperta con l'account), sembrando un invio
  riuscito.

## File modificati e aggiunti

| File | Tipo |
|---|---|
| `supabase/functions/push-dispatch/index.ts` | modificato |
| `docs/HAPOSTO_GUIDA_CONFIGURAZIONE_COMPLETA.md` | modificato |

## Dettaglio delle modifiche

- **`push-dispatch`:** la risposta riporta `delivered` (arrivate ad almeno un telefono),
  `no_device` (nessun telefono registrato, anche quando tutti i token risultano scaduti), `failed`
  e `invalid_tokens`. Nessun cambiamento a quali notifiche vengono chiuse o ritentate. Va
  ripubblicata con `npx supabase functions deploy push-dispatch --no-verify-jwt --use-api`.
- **Guida 6.3.5:** prima della prova si entra nell'app con l'account (è lì che il telefono si
  registra) e la si chiude scorrendola via, non con *Forza interruzione*; significato di
  `delivered` / `no_device`; query delle registrazioni senza mostrare il token.

## Verifiche

- Deno 2.9 in locale: `deno check`, `deno lint`, `deno test` (5 test) superati.
