# 2026-10-02 — Sito, area ristoratori: account visibile nella verifica, scelta dell'account Google

- **Data:** 2 ottobre 2026
- **PR:** [#13](https://github.com/paolomarchionetti-glitch/haposto/pull/13)
- **Motivo:** nella prova 9.5 il codice veniva rifiutato: "Accedi con Google" entrava con l'account
  già collegato nel browser (admin) mentre si scriveva il codice del ristoratore, e la schermata
  non mostrava l'account.

## File modificati e aggiunti

| File | Tipo |
|---|---|
| `web/src/assets/ristoratori.js` | modificato |

## Dettaglio delle modifiche

- La schermata della verifica mostra "Account: <email>" e invita a premere *Esci* se non è quello
  giusto.
- `signInWithOAuth` con `queryParams: { prompt: "select_account" }`: Google chiede sempre quale
  account usare.
- Troppi tentativi (HTTP 429) hanno un messaggio proprio.

## Verifiche

- `node --check`, build e test del sito (4) superati.
- Chromium (Playwright) con un finto `supabase-js`: parametri dell'accesso, riga dell'account,
  messaggi per 429 e codice errato, nessun errore JavaScript.
- CI tutta verde; prova reale sul sito `haposto-test.pages.dev` riuscita.
