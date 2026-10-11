# 2026-10-11 — Tessera fedeltà: specifiche versione 3 (valori confermati)

- **Data:** 11 ottobre 2026
- **Branch:** `claude/amazing-pasteur-dull9l`
- **PR:** [#25](https://github.com/paolomarchionetti-glitch/haposto/pull/25)
- **Motivo:** il titolare ha confermato i valori iniziali della versione 2 (PR #24), con quattro
  richieste:
  1. giorno doppio a scelta del ristoratore: nessuno o uno a settimana;
  2. gruppi: non una scansione a testa, e niente «30 dolci in una volta»;
  3. premi più vari, con uno sconto personale (solo per chi raggiunge il premio, non per il tavolo)
     o un buono per una cena successiva, con tetti. Il ristoratore non ci deve perdere e il cliente
     deve essere invogliato;
  4. condizione del timbro personalizzabile: soglia di spesa oppure una o due tipologie di
     consumazione.

## File modificati, aggiunti, rinominati ed eliminati

| File | Tipo |
|---|---|
| `docs/HAPOSTO_TESSERA_SPECIFICHE.md` | modificato (versione 3) |
| `docs/HAPOSTO_PROGETTO_VISITE_E_TESSERA.md` | modificato |
| `docs/HAPOSTO_STATO_CONFIGURAZIONE.md` | modificato |
| `docs/modifiche/2026-10-11_pr25-tessera-specifiche-v3.md` | aggiunto (questo file) |

Nessun file rinominato o eliminato.

## Dettaglio delle modifiche

### Specifiche, versione 3 (regole T1–T61)

- **Giorno doppio** (T14): nessuno o un giorno a settimana, tutto il giorno, solo a pranzo o solo a
  cena.
- **Timbro di gruppo** (§6.2, T28–T31):
  - un cliente apre il «QR del tavolo»;
  - gli altri si uniscono inquadrandolo (fino a 20 persone, entro 10 minuti);
  - lo staff fa **una sola scansione** e ognuno riceve il suo timbro con le sue regole;
  - lo staff vede il numero di persone prima di confermare;
  - vale anche con i conti separati.
- **Condizione del timbro** (T12–T13), a scelta del ristoratore:
  - spesa minima a persona (5–50 €);
  - oppure almeno una o almeno due consumazioni diverse fra tipologie scelte da una lista.
- **Premi in tre tipi** (§8):
  - **omaggio** da una lista ampliata a 16 voci, senza alcolici;
  - **sconto personale** 5–50% sulla consumazione di chi ha il premio, mai sul tavolo, con tetto
    obbligatorio 5–50 €;
  - **buono per la visita dopo** 2–20 €, con spesa minima almeno doppia.
- **Tutele per il locale** (§8.3):
  - da quando si usa il premio: subito o dalla visita successiva;
  - in quali giorni: almeno 3 a settimana;
  - quanti premi per tavolo alla stessa visita: proposta 4, così niente «30 dolci in una volta»;
  - cumulabile o no con altre offerte;
  - validità di 60 giorni.
- **Premio personale** (T5): mai convertibile in denaro, non cedibile, una sola volta, solo in quel
  locale, niente alcolici.
- **Statistiche:**
  - tavoli di gruppo;
  - totale degli sconti riconosciuti, per sapere quanto costa la tessera;
  - giorni e orari, per scegliere il giorno doppio.
- **Struttura tecnica:**
  - nuova tabella `loyalty_groups`;
  - versioni con le regole complete del premio e della condizione;
  - funzioni del gruppo;
  - controlli SQL dei nuovi limiti.
- **Tabella §18** con i valori confermati e due voci nuove: gruppo, premi per tavolo.

### Altri documenti

- **Proposta e stato:** riferimenti alla versione 3 (T1–T61).

## Costi

Nessuno (solo documenti).

## Verifiche

- Regole T1–T61 numerate senza buchi (controllo automatico sul file).
- Riferimenti alle regole aggiornati in stato e proposta.
- Solo documenti: nessun codice cambiato. CI su GitHub: vedi la PR.
