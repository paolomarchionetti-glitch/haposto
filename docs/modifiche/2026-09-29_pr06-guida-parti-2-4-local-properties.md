# 2026-09-29 — Parti 2–4: dominio autorizzato Google, local.properties.example, password admin

- **Data:** 29 settembre 2026 (registro scritto il 2 ottobre 2026)
- **PR:** [#6](https://github.com/paolomarchionetti-glitch/haposto/pull/6)
- **Motivo:** errori trovati seguendo le Parti 2, 3 e 4 della guida.

## File modificati e aggiunti

| File | Tipo |
|---|---|
| `docs/HAPOSTO_GUIDA_CONFIGURAZIONE_COMPLETA.md` | modificato |
| `local.properties.example` | modificato |

## Dettaglio delle modifiche

- **Guida, Parte 2:** `supabase.co` non è accettato da Google tra gli *Authorized domains* (è nella
  Public Suffix List): serve `REF_DEV.supabase.co` (e `REF_PROD.supabase.co` in Parte 10). Niente
  *Authorized JavaScript origins*; link legali e URL Configuration rimandati alla Parte 9; client
  Android di produzione rimandato; SHA-1 di debug con `gradlew signingReport`; menu di Google Auth
  Platform; logo sconsigliato (obbliga alla verifica); account "ristoratore" tra i Test users.
- **`local.properties.example`:** conteneva valori finti **non vuoti** per Firebase e produzione;
  copiandolo l'app Dev inizializzava Firebase con una chiave inventata. Ora quelle righe sono
  commentate.
- **Guida, Parte 3:** passo per aggiornare il progetto (con un progetto vecchio le varianti sono
  solo debug/release); chi ha già `local.properties` aggiunge solo `GOOGLE_WEB_CLIENT_ID`.
- **Guida, Parte 4.2:** l'SQL Editor salva da solo le query: la password admin va tolta dopo
  l'uso; elenco degli errori di `admin_set_credentials`.
- **Guida, Parte 10:** il redirect e il dominio di produzione vanno aggiunti lì.

## Verifiche

- Public Suffix List controllata (`supabase.co`, `pages.dev`).
- Codice dell'app e del sito letto per login Google, nonce e lettura di `local.properties`.
- Messaggi di `admin_set_credentials` provati sul database di prova.
