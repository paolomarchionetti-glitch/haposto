# 2026-10-05 — Roadmap da qui al lancio e documenti privati fuori dal repository

- **Data:** 5 ottobre 2026
- **Branch:** `claude/amazing-pasteur-dull9l`
- **PR:** [#20](https://github.com/paolomarchionetti-glitch/haposto/pull/20)
- **Motivo:** finito il collaudo sul DEV (PR #16–#19), il titolare ha chiesto:
  - una roadmap più dettagliata e in ordine, da qui alla messa online e alla gestione, con tutto
    quello che manca spiegato;
  - due documenti **privati**, da non salvare nel repository: accessi e chiavi, e una guida
    tecnica dell'app per uso personale.

  Rileggendo i documenti è emerso che la vecchia roadmap aveva ancora il modello "Basic gratis" e
  il piano Pro di Supabase per la produzione. Inoltre la guida della prova sul campo non diceva di
  abilitare l'account Google del ristoratore tra i *Test users*.

## File modificati, aggiunti, rinominati ed eliminati

| File | Tipo |
|---|---|
| `docs/HAPOSTO_ROADMAP_DA_QUI_AL_LANCIO.md` | aggiunto |
| `docs/HAPOSTO_ROADMAP_COMPLETA.md` | modificato |
| `docs/HAPOSTO_GUIDA_APP_E_DATI_REALI.md` | modificato |
| `docs/HAPOSTO_STATO_CONFIGURAZIONE.md` | modificato |
| `README.md` | modificato |
| `CLAUDE.md` | modificato |
| `.gitignore` | modificato |
| `docs/modifiche/2026-10-05_pr20-roadmap-da-qui-al-lancio.md` | aggiunto (questo file) |

Nessun file rinominato o eliminato. I due documenti privati **non** sono nel repository.

## Dettaglio delle modifiche

### Nuova roadmap (`HAPOSTO_ROADMAP_DA_QUI_AL_LANCIO.md`)

- **Dove siamo:** cosa c'è già (cliente, ristoratore, admin, server, sito, pagamenti) e cosa manca.
- **Il percorso in una pagina:** 12 tappe in ordine, con chi fa cosa, costo, durata e periodo:
  1. prova sul campo sul DEV;
  2. decisioni di base;
  3. basi legali e fiscali;
  4. produzione (Parte 10);
  5. documenti legali;
  6. Google Play e test chiuso;
  7. pilot Pesaro;
  8. decisione dopo il pilot;
  9. lancio pubblico;
  10. pagamenti attivi;
  11. fine della beta;
  12. gestione continuativa.
- **Ogni tappa in dettaglio:**
  - perché si fa, cosa fare, quando è finita;
  - limiti del piano Free di Supabase;
  - soglie dei KPI del pilot;
  - tabella delle cose da fare ogni giorno, settimana, mese, trimestre e anno;
  - quando conviene passare a un piano a pagamento.
- **Riepilogo dei costi**, con la regola: prima di ogni voce a pagamento, Claude chiede.
- **Avviso sull'email di contatto** (Tappa 3):
  - l'app, i termini, `app_config` e il sito usano `info@haposto.app`, ma il dominio non è ancora
    del titolare;
  - prima del test chiuso: dominio con inoltro, oppure sostituzione con la Gmail di assistenza.

### Vecchia roadmap (`HAPOSTO_ROADMAP_COMPLETA.md`)

- In testa una nota: il percorso da seguire ora è nella roadmap nuova; le fasi C–H sono fatte; il
  documento resta come archivio.
- Allineata al modello di pagamento del 2 ottobre:
  - fine beta: chi non paga resta "Non collegato" (prima: "Basic resta gratis");
  - mancato pagamento: "Non collegato" invece di Basic;
  - card "Il tuo piano" senza tasti né link di acquisto (regole di Google Play);
  - messaggio di fine beta ai ristoratori riscritto di conseguenza.
- Produzione sul piano **Free** di Supabase. Il piano Pro (~25 $/mese) solo quando servirà.

### Prova sul campo (`HAPOSTO_GUIDA_APP_E_DATI_REALI.md`)

- §4.2: nuovo primo passo. Google Cloud → **Google Auth Platform → Audience → Test users → Add
  users** con l'email Google del ristoratore. Senza questo passo il login è negato, perché l'app è
  in *Testing*.
- §5.1: migration `0001`→`0017` (era `0014`).

### Stato, README, CLAUDE.md, `.gitignore`

- **Stato:**
  - 0017 e le prove della PR #19 fatte sul DEV;
  - nuova voce aperta: prova sul campo (con i *Test users*);
  - rimando alla roadmap nuova e ai documenti privati;
  - messaggio di ripresa aggiornato.
- **README:** "Cosa manca" aggiornato (le migration 0012–0013 erano fatte da tempo); roadmap nuova
  nell'elenco dei documenti.
- **CLAUDE.md:** tra i documenti da leggere per primi c'è la roadmap nuova.
- **`.gitignore`:** esclude i file con `PRIVATO` o `privato` nel nome. Se un documento privato
  finisce per sbaglio nella cartella del repository, Git non lo propone per il commit.

## Costi

Nessuno.

## Verifiche

- Riferimenti della roadmap controllati sul repository:
  - file esistenti: `supabase/ops/kpi_queries.sql`, `app/src/main/assets/legal/`, roadmap
    completa §5.2, guida Parti 7–12;
  - chiavi di `app_config` citate (`beta`, `legal`, `restaurant_trial`);
  - Crashlytics oggi non c'è nell'app: la roadmap lo dice;
  - `info@haposto.app` cercato nel codice: 9 punti nell'app (`Outcome.kt`, `PlanNotices.kt`,
    schermate Account, Area, 2FA, Impostazioni del locale), `termini.md`, `app_config` (0012),
    valore predefinito di `web/build.mjs`.
- `git check-ignore` conferma che un file `…PRIVATO….md` dentro `docs/` è ignorato.
- Solo documenti e `.gitignore`: nessun codice cambiato. La CI gira comunque sulla PR.
