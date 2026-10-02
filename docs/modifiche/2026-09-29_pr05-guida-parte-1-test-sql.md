# 2026-09-29 — Parte 1: test SQL con l'utente test-thief, controllo di partenza nella guida

- **Data:** 29 settembre 2026 (registro scritto il 2 ottobre 2026)
- **PR:** [#5](https://github.com/paolomarchionetti-glitch/haposto/pull/5)
- **Motivo:** provando la Parte 1 della guida (migration 0012–0013 sul DEV) il controllo
  facoltativo `step8_to_17_checks.sql` sarebbe fallito.

## File modificati e aggiunti

| File | Tipo |
|---|---|
| `supabase/tests/step8_to_17_checks.sql` | modificato |
| `.github/workflows/android-ci.yml` | modificato |
| `docs/HAPOSTO_GUIDA_CONFIGURAZIONE_COMPLETA.md` | modificato |

## Dettaglio delle modifiche

- **`step8_to_17_checks.sql`:** il controllo "ogni utente registrato ha un profilo" contava tutti
  gli utenti `test-%@haposto.test` e si aspettava 5; la guida fa creare anche
  `test-thief@haposto.test` (sesto utente), quindi falliva. Ora conta solo i 5 utenti creati dallo
  script.
- **CI (`android-ci.yml`):** nuovo passo "Checks in the setup guide order" che riproduce l'ordine
  della guida (6 utenti di prova, poi step18 e step8_to_17 sullo stesso database).
- **Guida, Parte 1:** query di controllo di partenza (fino a 0011 / 0012 / 0013) e nota sulla
  finestra *Potential issue detected… destructive operation* dell'SQL Editor (si conferma con
  *Run this query*).

## Verifiche

- Replica locale del job SQL della CI: errore riprodotto con il test vecchio, superato con quello
  nuovo.
- Immagine ufficiale `supabase/postgres` 17 con lo schema `auth` di Supabase Auth: 0012–0013
  applicate due volte sopra uno stato 0001–0011 + seed + strumenti DEV, 59 + 93 controlli superati.
