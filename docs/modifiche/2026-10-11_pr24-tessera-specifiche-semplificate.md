# 2026-10-11 — Tessera fedeltà: specifiche semplificate (versione 2)

- **Data:** 11 ottobre 2026
- **Branch:** `claude/amazing-pasteur-dull9l`
- **PR:** [#24](https://github.com/paolomarchionetti-glitch/haposto/pull/24)
- **Motivo:** leggendo la versione 1 delle specifiche (PR #23), il titolare ha chiesto dieci
  chiarimenti e una tessera più semplice. In particolare:
  - meno vincolante per i ristoranti;
  - nessuna contestazione, nessun lavoro dell'admin;
  - sanzioni automatiche e progressive solo sulla tessera, senza togliere il locale da HAPOSTO;
  - premi solo da una lista, senza alcolici né soldi;
  - niente aspetti legali troppo vincolanti.

## File modificati, aggiunti, rinominati ed eliminati

| File | Tipo |
|---|---|
| `docs/HAPOSTO_TESSERA_SPECIFICHE.md` | modificato (riscritto: versione 2) |
| `docs/HAPOSTO_PROGETTO_VISITE_E_TESSERA.md` | modificato |
| `docs/HAPOSTO_ROADMAP_DA_QUI_AL_LANCIO.md` | modificato |
| `docs/HAPOSTO_STATO_CONFIGURAZIONE.md` | modificato |
| `docs/modifiche/2026-10-11_pr24-tessera-specifiche-semplificate.md` | aggiunto (questo file) |

Nessun file rinominato o eliminato.

## Dettaglio delle modifiche

### Specifiche, versione 2 (regole T1–T51)

- **Chiusura:** preavviso di **30 giorni**, poi la tessera finisce (prima: le tessere iniziate
  andavano avanti fino a 12 mesi). Il mancato pagamento di Pro fa partire lo stesso preavviso. Se
  il locale esce da HAPOSTO la tessera finisce subito.
- **Scadenze:** i timbri si azzerano dopo **6 mesi senza visite**. Tolte la scadenza a 12 mesi dal
  primo timbro e la gestione delle ferie.
- **Premi:** solo da una **lista chiusa** di 8 prodotti del locale (caffè, dolce, antipasto,
  contorno, primo, pizza, bibita analcolica, coperto). Niente testo libero, soldi, sconti o
  alcolici.
- **Condizione del timbro:** «pasto al tavolo» o «consumazione al tavolo» (tolta la spesa minima in
  euro).
- **Validità del premio, azzeramento e preavviso:** valori unici decisi dall'admin, uguali per
  tutti i locali.
- **Contestazioni tolte.** Il premio si consegna con un tocco, come con la tessera di carta.
- **Segnalazioni:**
  - due tasti, solo per chi ha avuto un timbro in quel locale negli ultimi 60 giorni;
  - una ogni 90 giorni;
  - contano in automatico.
- **Sanzioni automatiche e progressive, solo sulla tessera:**
  - avviso a 3 segnalazioni di clienti diversi in 60 giorni;
  - tessera sospesa per 90 giorni a 5;
  - tessera tolta alla seconda sospensione in 12 mesi.

  Il locale resta sempre su HAPOSTO con il suo abbonamento. Nessuna sanzione automatica per i
  clienti: bastano i limiti tecnici.
- **Tolto l'elenco di anomalie** da controllare nel pannello: restano i tetti automatici di
  scansione.
- **Aspetti legali:** con la lista chiusa è la classica tessera timbri. Bastano poche righe in
  privacy e termini, da rileggere con gli altri documenti legali alla Tappa 5.
- **Restano:**
  - interruttore con le quattro modalità e i tester;
  - versioni immutabili;
  - QR di 60 secondi monouso con screenshot bloccati;
  - niente autotimbri né timbri a mano;
  - annullamento entro 2 minuti;
  - codice anonimo per la privacy;
  - statistiche;
  - tessera gratis;
  - idee per Plus;
  - piano in 5 PR.
- In testa al documento, la tabella «Cosa cambia rispetto alla versione 1»; in fondo, 13 valori
  iniziali da confermare.

### Altri documenti

- **Proposta:** nota aggiornata (lista chiusa, sanzioni solo sulla tessera).
- **Roadmap (Tappa 8):** invece del parere dell'avvocato, basta rileggere privacy e termini con gli
  altri documenti legali.
- **Stato:** versione 2, regole T1–T51.

## Costi

Nessuno (solo documenti).

## Verifiche

- Regole T1–T51 numerate senza buchi (controllo automatico sul file).
- Riferimenti alle regole aggiornati in stato e proposta.
- Solo documenti: nessun codice cambiato. CI su GitHub: vedi la PR.
