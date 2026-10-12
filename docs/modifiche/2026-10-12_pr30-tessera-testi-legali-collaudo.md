# 2026-10-12 — Tessera fedeltà, PR E: testi legali e guida di collaudo

- **Data:** 12 ottobre 2026
- **Branch:** `claude/amazing-pasteur-dull9l`
- **PR:** [#30](https://github.com/paolomarchionetti-glitch/haposto/pull/30)
- **Motivo:** ultimo dei cinque passi della tessera fedeltà nascosta (specifiche §14), più la
  guida completa per il collaudo finale chiesta dal titolare: «faremo tutti i test alla fine di
  collaudo con istruzioni precise su tutto l'argomento tessere […] mi darai la guida completa
  comprensiva di supabase edge function se ce n'è bisogno e tutto il resto».

## File modificati, aggiunti, rinominati ed eliminati

| File | Tipo |
|---|---|
| `docs/HAPOSTO_TESSERA_TESTI_LEGALI.md` | aggiunto |
| `docs/HAPOSTO_TESSERA_COLLAUDO.md` | aggiunto |
| `docs/HAPOSTO_GUIDA_CONFIGURAZIONE_COMPLETA.md` | modificato |
| `docs/HAPOSTO_TESSERA_SPECIFICHE.md` | modificato |
| `docs/HAPOSTO_ROADMAP_DA_QUI_AL_LANCIO.md` | modificato |
| `docs/HAPOSTO_STATO_CONFIGURAZIONE.md` | modificato |
| `README.md` | modificato |
| `docs/modifiche/2026-10-12_pr30-tessera-testi-legali-collaudo.md` | aggiunto (questo file) |

Nessun file rinominato o eliminato. Nessuna modifica al codice, al database o alle Edge Function.

## Dettaglio delle modifiche

### Testi legali (`HAPOSTO_TESSERA_TESTI_LEGALI.md`)

- Righe pronte da incollare, ognuna con il punto esatto in cui va:
  - **privacy**: dati della tessera (codice anonimo per locale, timbri e visite, QR solo come
    impronta, segnalazioni, niente GPS), basi giuridiche, quattro righe per la tabella dei tempi
    di conservazione (T58), come lasciare una tessera;
  - **termini d'uso**: timbri, regole che non cambiano per chi ha iniziato, premi personali e non
    convertibili, azzeramento dopo 6 mesi, chiusura con preavviso, gruppi, segnalazioni, abusi;
  - **condizioni per i ristoranti**: il patto in tre righe, il premio come iniziativa del locale
    (costo e aspetti fiscali), regole immutabili, niente timbri a mano, dati solo anonimi,
    chiusura, soglie automatiche delle segnalazioni.
- Cinque domande per il professionista, fra cui sconti e buoni su scontrino e fattura e la
  disciplina delle manifestazioni a premio (D.P.R. 430/2001).
- **Scelta:** le righe **non** entrano ora in `app/src/main/assets/legal/`, perché quei file li
  mostra l'app e li pubblica il sito: renderebbero pubblica una funzione che il titolare vuole
  nascosta. Si inseriscono solo con la decisione di lancio, prima di `"mode": "ON"`; durante le
  prove basta la schermata della privacy al primo uso (T59). Il file spiega come fare.

### Guida di collaudo (`HAPOSTO_TESSERA_COLLAUDO.md`)

- **Parte A, Supabase DEV:** migration 0018 con il risultato atteso (`OFF`, `12`, `true`),
  `scheduled_jobs.sql` con il lavoro `haposto-loyalty-maintenance`. **Edge Function: nessuna da
  ripubblicare**: gli avvisi della tessera entrano nella coda delle notifiche (`kind` `SYSTEM`) e
  `push-dispatch` li invia senza filtri per tipo (controllato nel codice di `push-dispatch` e di
  `claim_notification_batch`). I 209 controlli `step22` li esegue già la CI.
- **Parte B:** app Dev aggiornata su entrambi i dispositivi.
- **Parti C–M:** preparazione con valori temporanei e l'avviso di non usare mai `"ON"`; controllo
  del piano Pro del locale; attivazione del ristoratore; QR, annullamento, timbro e premio; tavolo
  di gruppo con un terzo account e «Lascia questa tessera»; codice di riserva; statistiche; nuova
  versione delle regole; segnalazione e sospensione automatica; pannello → Tessere, Registro e
  «Ridai la tessera»; chiusura con preavviso; modalità `EXISTING_ONLY`. Ogni passo ha il risultato
  atteso con i testi esatti dell'app.
- **Parte N:** valori di partenza e `"mode": "OFF"`, con i controlli che la tessera sia di nuovo
  invisibile.
- **Parte O:** come portare la 0018 in produzione **senza accendere** la tessera, e cosa serve per
  accenderla al lancio.
- Riepilogo finale: cosa c'è e in quale PR.

### Altri documenti

- Guida generale (Parte 11): la «prova completa» della PR D è sostituita da un rimando alla guida
  di collaudo, così le istruzioni sono in un posto solo.
- Specifiche: tutte le PR realizzate; §14 rimanda ai testi legali e spiega perché non sono ancora
  pubblicati.
- Roadmap: Tappa 5 (consegnare anche i testi della tessera al professionista) e decisione di lancio
  (i passi per accenderla).
- Stato: PR E fatta, tessera completa; un'unica voce da fare, il collaudo finale.
- README: i due documenti nuovi nell'elenco.

## Costi

Nessuno.

## Verifiche

- **Guida di collaudo verificata sul database locale** (Postgres 16, migration fino alla 0018 e
  dati di prova), con due simulazioni con gli stessi valori e la stessa sequenza della guida:
  - Parti C–K (21 controlli): impostazioni accettate, procedura guidata da 2 timbri, timbro doppio
    con premio, annullamento e nuovo timbro, QR già usato rifiutato, premio da consegnare,
    «Le mie tessere» prima e dopo «Consegnato», tavolo di 2 con 1 timbrato e 1 escluso,
    sospensione automatica con gli avvisi, numeri della scheda Tessere, «Ridai la tessera» e
    riattivazione, tessera invisibile con OFF;
  - Parti F, I, L, M e N (13 controlli): «Lascia questa tessera» (codice cancellato, si può
    ricominciare), nuova versione che vale solo per chi inizia, chiusura con preavviso (avviso,
    data nel riquadro, niente tessere nuove), `EXISTING_ONLY` partito da `TEST` senza segnare il
    lancio (chi ha la tessera la vede, chi non l'ha no, regole bloccate), ritorno a `OFF`.

  Tutti i 34 controlli sono verdi.
- I testi attesi della guida (tasti, messaggi, esiti) sono stati confrontati con il codice dell'app
  (`LoyaltyTexts`, schermate di ristoratore, cliente e pannello). Così sono emersi e sono stati
  scritti nella guida due comportamenti: dopo «Annulla» la schermata dell'esito del cliente resta
  com'era (il dato vero è nel riquadro del locale); in preavviso il ristoratore legge «In chiusura
  fino al …».
- Nessun file dell'app cambia: la CI deve restare verde come sulla PR #29.
