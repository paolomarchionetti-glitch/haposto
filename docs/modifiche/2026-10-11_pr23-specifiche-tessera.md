# 2026-10-11 — Specifiche della tessera fedeltà (funzione nascosta)

- **Data:** 11 ottobre 2026
- **Branch:** `claude/amazing-pasteur-dull9l`
- **PR:** [#23](https://github.com/paolomarchionetti-glitch/haposto/pull/23)
- **Motivo:** dopo la proposta della PR #22, il titolare ha deciso di realizzare subito la tessera
  come funzione **nascosta e spenta dal pannello admin**, fino all'eventuale lancio. Le richieste:
  - privacy completa;
  - nessun QR falso e nessun timbro gratis;
  - premio garantito e mai in denaro, condizioni bloccate per chi ha già iniziato;
  - sanzioni con esclusione dall'app per chi viola il patto;
  - statistiche anonime per ristoratore e admin;
  - tessera gratis per chi accede;
  - idee per i vantaggi di Plus;
  - aspetti legali da sottoporre all'avvocato.

  Prima di scrivere il codice, ha chiesto un documento con tutti i punti da seguire.

## File modificati, aggiunti, rinominati ed eliminati

| File | Tipo |
|---|---|
| `docs/HAPOSTO_TESSERA_SPECIFICHE.md` | aggiunto |
| `docs/HAPOSTO_PROGETTO_VISITE_E_TESSERA.md` | modificato |
| `docs/HAPOSTO_ROADMAP_DA_QUI_AL_LANCIO.md` | modificato |
| `docs/HAPOSTO_STATO_CONFIGURAZIONE.md` | modificato |
| `README.md` | modificato |
| `docs/modifiche/2026-10-11_pr23-specifiche-tessera.md` | aggiunto (questo file) |

Nessun file rinominato o eliminato.

## Dettaglio delle modifiche

### Specifiche (`docs/HAPOSTO_TESSERA_SPECIFICHE.md`)

59 regole numerate (**T1**–**T59**), da citare in PR e test:
- **il patto** (T1–T6): timbro solo con scansione reale; condizioni bloccate per ogni tessera;
  modifiche solo per le tessere nuove; premio garantito e mai in denaro; sospensione per chi viola;
- **interruttore** (T7–T10): modalità spenta (iniziale), test con tester scelti dall'admin, attiva,
  solo esistenti. Dopo il lancio non si spegne del tutto, per rispettare il patto;
- **programma del locale** (T11–T20): limiti, versioni immutabili, accettazione registrata in
  `consent_log` con approvazione specifica delle clausole;
- **cosa può fare il ristoratore** (T20–T27), una situazione per riga:
  - cambio delle condizioni;
  - chiusura con preavviso;
  - ferie, che allungano le scadenze;
  - mancato pagamento;
  - cessazione;
  - cancellazione dell'account;
  - sospensione;
  - cambio di gestione;
- **tessera del cliente** (T28–T33): nascita al primo timbro, scadenze, riporto del timbro doppio,
  uscita;
- **flusso veloce** (T34–T35): QR in meno di mezzo secondo; esito sul telefono del cliente entro 1
  secondo;
- **antifrode** (T36–T43): QR di 60 secondi monouso, screenshot bloccati, cornice animata, codice
  di riserva con limite di errori, un timbro ogni 4 ore, niente autotimbri, **niente timbri a
  mano**, annullamento solo entro 2 minuti, contestazione del premio entro 48 ore;
- **premio** (T44–T48): omaggio o sconto percentuale; vietati denaro e importi in euro;
- **sanzioni** (T49–T51): per il locale fino alla sospensione da HAPOSTO (sparisce da mappa ed
  elenco); per il cliente fino al blocco dell'account;
- **privacy** (T52–T57): codice anonimo per locale, QR senza dati, niente GPS, conservazione;
- **account e Plus** (T58–T59): tessera gratis con accesso Google; idee per Plus;
- **pannello admin**, **domande per l'avvocato**, **struttura tecnica**:
  - migration 0018 con 9 tabelle;
  - controlli `step22`;
  - scanner di Google senza permesso della fotocamera;
- **piano in 5 PR** (A database, B ristoratore, C cliente, D pannello, E testi legali), altre idee,
  valori iniziali da confermare.

### Altri documenti

- **Proposta:** nota in testa: si realizza come funzione nascosta; dove differisce valgono le
  specifiche (per esempio niente timbri a mano, contrariamente alla proposta).
- **Roadmap (Tappa 8):** la decisione non è più «si costruisce», ma «si accende per tutti», dopo
  l'avvocato.
- **Stato:** la decisione e il piano di lavoro.
- **README:** le specifiche nell'elenco dei documenti.

## Costi

Nessuno (solo documenti). La realizzazione prevista è a costo zero.

## Verifiche

- Riferimenti controllati sul codice:
  - `consent_log` e approvazione specifica (`accept_restaurant_terms`, 0013);
  - `app_config` leggibile da tutti (per questo la modalità la decide il server, T9);
  - ZXing già presente;
  - nessun `FLAG_SECURE` né scanner oggi nell'app;
  - sospensione del locale e blocco dell'account già esistenti nel pannello;
  - problema noto di `admin_restaurant_detail` dal SQL Editor, che si sistema nella 0018.
- Tutte le regole T1–T59 presenti e numerate senza buchi.
- Solo documenti: nessun codice cambiato. CI su GitHub: vedi la PR.
