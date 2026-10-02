# 2026-09-30 — Parte 5 (Firebase) con verifica, chiave segreta rimandata, 4.3 con un solo telefono

- **Data:** 30 settembre 2026 (registro scritto il 2 ottobre 2026)
- **PR:** [#9](https://github.com/paolomarchionetti-glitch/haposto/pull/9)

## File modificati e aggiunti

| File | Tipo |
|---|---|
| `docs/HAPOSTO_GUIDA_CONFIGURAZIONE_COMPLETA.md` | modificato |

## Dettaglio delle modifiche

- **Parte 5:** progetto Firebase aggiunto al progetto Google Cloud della Parte 2; procedura guidata
  Android senza plugin/SDK (l'app usa i 4 valori di `local.properties`); aspetto dei 4 valori;
  verifica con `device_push_tokens` e messaggio di prova dalla console Firebase.
- **Chiave dell'account di servizio** (segreto): non più creata in Parte 5 ma al punto 6.2, dove
  serve.
- **Parte 4.3:** prova con due account anche su un solo telefono, alternando gli account.

## Verifiche

- Letti `PushMessaging`, `AppDependencies.startBackgroundServices` e la tabella
  `device_push_tokens` usata nella query della guida. Solo documentazione.
