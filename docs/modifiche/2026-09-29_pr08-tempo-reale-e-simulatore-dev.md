# 2026-09-29 — Tempo reale (migration 0005) e simulatore DEV che non tocca i locali rivendicati

- **Data:** 29 settembre 2026 (registro scritto il 2 ottobre 2026)
- **PR:** [#8](https://github.com/paolomarchionetti-glitch/haposto/pull/8) (la
  [#7](https://github.com/paolomarchionetti-glitch/haposto/pull/7) era solo un allineamento di
  `main` sul branch, senza file modificati)
- **Motivo:** prima della prova con due account (Parte 4.3) sono emersi due problemi che l'avrebbero
  falsata.

## File modificati e aggiunti

| File | Tipo |
|---|---|
| `supabase/migrations/0005_realtime_future.sql` | modificato |
| `supabase/dev/dev_tools.sql` | modificato |
| `supabase/tests/dev_tools_checks.sql` | aggiunto |
| `.github/workflows/android-ci.yml` | modificato |
| `docs/HAPOSTO_GUIDA_CONFIGURAZIONE_COMPLETA.md` | modificato |
| `docs/HAPOSTO_GUIDA_AGGIORNAMENTO_DB.md` | modificato |
| `docs/HAPOSTO_SQL_INTEGRATIVO.md` | modificato |

## Dettaglio delle modifiche

- **Tempo reale:** l'app si iscrive ai cambi di `restaurant_live_status`, ma la 0005 (publication
  `supabase_realtime`) non veniva mai eseguita né dalla guida né dalla CI. La 0005 ora è
  rieseguibile (aggiunge la tabella solo se manca); la guida la include nella Parte 1 e nella
  Parte 10; la CI la applica e controlla che la tabella sia pubblicata una sola volta.
- **Simulatore DEV:** dopo l'approvazione un locale di prova diventa `ACTIVE_PARTNER` e il
  simulatore ne sovrascriveva lo stato ogni 5 minuti; anche `dev_publish_live_status` (senza login)
  poteva scriverci. Ora entrambi ignorano i locali con un titolare o uno staff veri.
- **Nuovo test `dev_tools_checks.sql`** (transazione annullata) e nuovo passo in CI.
- **Guide:** 4.3 con il rilancio di `dev_tools.sql` e l'emulatore come secondo telefono; guida
  aggiornamento DB e SQL integrativo allineati sulla 0005.

## Verifiche

- Test nuovo fallito con il `dev_tools.sql` precedente e superato con quello corretto (alle 20:40,
  simulatore attivo).
- Immagine `supabase/postgres` 17: 0005 eseguita due volte come `postgres`, UPDATE sugli stati
  possibili con la tabella pubblicata, `dev_tools.sql` rieseguito con un solo job pianificato.
