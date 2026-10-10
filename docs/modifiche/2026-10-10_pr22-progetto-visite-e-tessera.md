# 2026-10-10 — Proposta «Visite e tessera fedeltà»

- **Data:** 10 ottobre 2026
- **Branch:** `claude/amazing-pasteur-dull9l`
- **PR:** [#22](https://github.com/paolomarchionetti-glitch/haposto/pull/22)
- **Motivo:** il titolare ha fornito un documento, scritto con ChatGPT, su check-in verificato e
  programma fedeltà per i ristoranti. Ha chiesto:
  - come si applicherebbe a HAPOSTO;
  - se ne vale la pena, con pro e contro;
  - come lo strutturerebbe Claude (facoltativo, con il QR sul telefono?);
  - un documento di progetto salvato su GitHub.

## File modificati, aggiunti, rinominati ed eliminati

| File | Tipo |
|---|---|
| `docs/HAPOSTO_PROGETTO_VISITE_E_TESSERA.md` | aggiunto |
| `docs/HAPOSTO_ROADMAP_DA_QUI_AL_LANCIO.md` | modificato |
| `docs/HAPOSTO_STATO_CONFIGURAZIONE.md` | modificato |
| `README.md` | modificato |
| `docs/modifiche/2026-10-10_pr22-progetto-visite-e-tessera.md` | aggiunto (questo file) |

Nessun file rinominato o eliminato. Il documento di partenza del titolare non è nel repository.

## Dettaglio delle modifiche

### Progetto (`docs/HAPOSTO_PROGETTO_VISITE_E_TESSERA.md`)

- **Verdetto:** sì, ma in versione minima («tessera timbri digitale») e solo dopo il pilot, perché
  il rischio principale resta l'aggiornamento dello stato. Momento consigliato: marzo–aprile 2027,
  così a fine beta ogni locale vede quanti clienti gli ha portato HAPOSTO.
- **Confronto** fra le idee del documento e ciò che HAPOSTO ha già: tre stati, scadenza, account
  facoltativo, avvisi, offerta, «di solito», statistiche, collaboratori.
- **Pro e contro** in tabella, con come affrontare ogni contro.
- **Scelte:** cosa si fa (V1, V1.5, V2, V3) e cosa no:
  - niente punti in euro;
  - niente punti fra locali diversi;
  - niente GPS;
  - niente CRM con i nomi;
  - niente integrazione con le casse;
  - niente prezzo per cliente.
- **Esperienza** di cliente, ristoratore/staff e admin, con le schermate a parole.
- **QR:**
  - temporaneo (2 minuti), monouso, creato dal server, senza dati personali;
  - codice di riserva di 6 caratteri;
  - perché il QR è del cliente e lo scansiona il locale.
- **Regole antifrode** proporzionate al modello ad abbonamento fisso.
- **Privacy:**
  - il locale vede solo numeri e un codice anonimo;
  - conservazione limitata;
  - nessuna posizione.
- **Premi** come sconto o omaggio del locale, con la verifica ⚖️ sulle manifestazioni a premio
  (DPR 430/2001).
- **Piani:** gratis per i clienti, dentro Pro per i ristoranti, prezzo invariato.
- **Struttura tecnica:**
  - 6 tabelle e 9 funzioni;
  - app con lo scanner di Google (senza permesso della fotocamera);
  - costo zero.
- **Fasi e tempi**, soglie per capire se funziona, decisioni da prendere.

### Roadmap, stato, README

- **Roadmap:**
  - Tappa 7: domande facoltative sulla tessera durante il pilot (fase V0);
  - Tappa 8: la decisione sulla proposta.
- **Stato:** la proposta tra i prossimi passi, senza codice scritto.
- **README:** il documento nell'elenco.

## Costi

Nessuno (solo documenti). Anche la proposta stessa è a costo zero.

## Verifiche

- Riferimenti controllati sul codice:
  - tre stati con scadenza a 30 minuti e offerta della serata (0015);
  - ruoli `OWNER` e `STAFF`;
  - funzioni dei piani e limiti di Pro (0008, 0016);
  - consenso marketing (`profiles.marketing_opt_in`);
  - statistiche esistenti (`restaurant_daily_stats`);
  - ZXing già nel progetto per generare i QR;
  - nessuno scanner né permesso della fotocamera oggi nell'app.
- Solo documenti: nessun codice cambiato. CI su GitHub: vedi la PR.
