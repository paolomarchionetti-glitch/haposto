# 2026-10-02 — Registro delle modifiche passate, CLAUDE.md e stato della configurazione

- **Data:** 2 ottobre 2026
- **Branch:** `claude/haposto-setup-guide-8a512c`
- **PR:** da aggiornare all'apertura
- **Motivo:** richiesta del titolare: registrare in `docs/modifiche/` ogni modifica (anche quelle già
  fatte), scrivere la regola in `CLAUDE.md` e preparare il passaggio a una nuova sessione senza
  perdere il filo.

## File modificati, aggiunti e rinominati

| File | Tipo |
|---|---|
| `CLAUDE.md` | aggiunto |
| `docs/HAPOSTO_STATO_CONFIGURAZIONE.md` | aggiunto |
| `README.md` | modificato |
| `docs/modifiche/2026-09-29_pr05-guida-parte-1-test-sql.md` | aggiunto |
| `docs/modifiche/2026-09-29_pr06-guida-parti-2-4-local-properties.md` | aggiunto |
| `docs/modifiche/2026-09-29_pr08-tempo-reale-e-simulatore-dev.md` | aggiunto |
| `docs/modifiche/2026-09-30_pr09-guida-parte-5-firebase.md` | aggiunto |
| `docs/modifiche/2026-09-30_pr10-guida-parte-6-segreti-e-notifiche.md` | aggiunto |
| `docs/modifiche/2026-09-30_pr11-notifiche-post-ricorsivo.md` | aggiunto |
| `docs/modifiche/2026-09-30_pr12-push-dispatch-delivered-no-device.md` | aggiunto |
| `docs/modifiche/2026-10-02_pr13-sito-account-nella-verifica.md` | aggiunto |
| `docs/modifiche/2026-10-02_guida-parte-9-sito-cloudflare.md` → `docs/modifiche/2026-10-02_pr14-guida-parte-9-sito-cloudflare.md` | rinominato (nome uniformato agli altri) |
| `docs/modifiche/2026-10-02_pr15-registro-claude-md-stato.md` | aggiunto (questo file) |

## Dettaglio delle modifiche

- **`CLAUDE.md`** (letto in automatico da Claude Code all'inizio di ogni sessione): documenti da
  leggere per primi, regole di lavoro (italiano, nessun segreto né identificativo nel repository
  pubblico, mai su `main`, verifica con test e CI, **registro obbligatorio in `docs/modifiche/`**,
  guida una parte alla volta con verifica sul codice, costo zero, aggiornamento dello stato) e
  comandi utili.
- **`docs/HAPOSTO_STATO_CONFIGURAZIONE.md`:** avanzamento parte per parte (1–6 e 9 fatte, 7–8
  rimandate, 10 prossima), decisioni prese, piccole cose aperte, lezioni pratiche emerse nelle prove,
  procedura e messaggio per riprendere in una nuova sessione, note tecniche sulle verifiche.
- **`README.md`:** nella sezione "Stato attuale", riferimento allo stato della configurazione, al
  registro delle modifiche e a `CLAUDE.md`.
- **Registro retroattivo:** un file per ciascuna PR #5, #6, #8, #9, #10, #11, #12, #13 (la #7 era
  solo un allineamento di `main` sul branch, senza file, ed è citata nel file della #8), con file
  toccati, dettaglio e verifiche ricostruiti dalla cronologia Git e dalle descrizioni delle PR.
- **Rinomina** del registro della PR #14 con `pr14` nel nome, come gli altri; aggiornato il
  riferimento interno al proprio nome.

## Verifiche

- Elenco dei file per ogni PR ricavato con `git diff --name-status` sui commit di unione di `main`.
- Controllato che nessun file aggiunto contenga segreti, email personali o identificativi dei
  progetti Supabase.
- Solo documentazione: nessun cambiamento al codice.
