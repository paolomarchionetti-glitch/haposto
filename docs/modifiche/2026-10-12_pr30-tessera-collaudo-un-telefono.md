# 2026-10-12 — Tessera fedeltà: guida di collaudo per un solo telefono

- **Data:** 12 ottobre 2026
- **Branch:** `claude/amazing-pasteur-dull9l`
- **PR:** [#30](https://github.com/paolomarchionetti-glitch/haposto/pull/30)
- **Motivo:** richiesta del titolare: «È possibile fare tutto il test della tessera con un unico
  cellulare? In caso rifammi la guida intera al collaudo in questa versione ultradettagliata». La
  guida della #29 presupponeva due dispositivi, perché il ristoratore inquadra il QR del cliente.

## File modificati, aggiunti, rinominati ed eliminati

| File | Tipo |
|---|---|
| `docs/HAPOSTO_TESSERA_COLLAUDO.md` | modificato (riscritto) |
| `docs/HAPOSTO_GUIDA_CONFIGURAZIONE_COMPLETA.md` | modificato |
| `docs/HAPOSTO_STATO_CONFIGURAZIONE.md` | modificato |
| `README.md` | modificato |
| `docs/modifiche/2026-10-12_pr30-tessera-collaudo-un-telefono.md` | aggiunto (questo file) |

Nessun file rinominato o eliminato. Nessuna modifica al codice, al database o alle Edge Function.

## Dettaglio delle modifiche

### Come si fa con un solo telefono

- Il ristoratore usa il **codice di riserva di 6 caratteri** sotto il QR («Inserisci codice»), la
  strada prevista per i QR che non si leggono, al posto della fotocamera.
- Sul telefono si alternano due account: **👤 TU** (admin e cliente) e **🍴 RISTO** (ristoratore di
  prova). La procedura di cambio (Esci, Accedi con Google, codice di Authenticator per l'area
  ristoratore o per il pannello) è scritta una volta all'inizio e richiamata a ogni parte.
- Durante la prova il codice vale **5 minuti** (`token_seconds` 300, il massimo ammesso), il tempo
  per cambiare account. Alla fine torna a 60 secondi.
- Le impostazioni della prova si cambiano e si rimettono dal **SQL Editor** con due comandi da
  copiare (con la verifica dei valori), invece di modificare a mano un testo lungo sul telefono.
  `admin_set_config` dal SQL Editor è permesso (nessun utente collegato) e finisce nel registro.
- Le regole sono pensate per non dover aspettare le 4 ore fra due timbri:
  - versione 1 con **3 timbri** (un timbro doppio dà «2 su 3»: si vedono la tessera in corso, la
    data di azzeramento e le regole della propria versione);
  - poi «Cambia le regole» a **2 timbri** (versione 2, solo per chi inizia);
  - «Lascia questa tessera» cancella i timbri, quindi si può timbrare subito di nuovo: un timbro
    doppio completa la tessera e sblocca il premio;
  - il premio si consegna con una seconda scansione («già timbrato» ma premio da consegnare).

### La guida (parti A–Q e appendice)

- **A** Supabase DEV (0018, `scheduled_jobs.sql`, nessuna Edge Function).
- **B** app Dev con GitHub Desktop e Android Studio.
- **C** preparazione: SQL Editor, locale tester, controllo di Partner e Pro, scheda Tessere.
- **D–J** il percorso con codici A, B, C, D:
  - attivazione;
  - primo timbro e nuove regole;
  - «Le mie tessere» e «Lascia la tessera»;
  - annullamento, premio e codice già usato;
  - premio visto dal cliente;
  - consegna e statistiche, con i numeri attesi.
- **K–O** sospensione e chiusura:
  - segnalazione e sospensione automatica, pannello, Registro, controllo degli avvisi dal SQL
    Editor;
  - sospensione vista dal ristoratore;
  - «Ridai la tessera»;
  - riattivazione e chiusura con preavviso;
  - cliente in preavviso e modalità `EXISTING_ONLY`.
- **P** fine: valori di partenza e `OFF`, con i controlli.
- **Q** produzione senza accendere.
- **Appendice** (facoltativa): le quattro prove che con un solo telefono non si possono fare,
  con l'emulatore del PC come secondo dispositivo:
  - scansione con la fotocamera;
  - esito in tempo reale sul telefono del cliente;
  - tavolo di gruppo;
  - notifiche all'altro account.

### Altri documenti

- Guida generale (Parte 11): il rimando dice che il collaudo si fa con un solo telefono.
- Stato: voce del collaudo aggiornata (circa 2 ore, parti A–P) e nota su questa PR.
- README: descrizione della guida aggiornata.

## Costi

Nessuno.

## Verifiche

- **Percorso simulato sul database locale** (Postgres 16, migration fino alla 0018 e dati di
  prova) con gli stessi valori, la stessa sequenza e i codici di riserva al posto dei QR: **21
  controlli verdi**. Fra questi:
  - codice valido 5 minuti;
  - «2 su 3» con le regole della versione 1 dopo il passaggio alla versione 2;
  - «Le mie tessere» con la data di azzeramento;
  - dopo «Lascia la tessera» si timbra subito e il codice anonimo cambia;
  - annullamento e nuovo timbro con premio;
  - un codice già usato risponde «Codice sbagliato (restano 9 tentativi…)»;
  - «già timbrato» ma premio da consegnare, poi consegnato;
  - statistiche (3 visite, 2 persone, 4 timbri di cui 2 doppi, 1 premio sbloccato e usato);
  - sospensione automatica con l'avviso al ristoratore in coda;
  - «Ridai la tessera», riattivazione (versione 3) e chiusura con preavviso;
  - `EXISTING_ONLY` partito da `TEST` senza segnare il lancio;
  - ritorno a `OFF`.
- **I quattro comandi SQL della guida** (preparazione, avvisi, `EXISTING_ONLY`, fine) eseguiti
  sul database locale **copiati così come sono**: risultati uguali agli «Atteso».
- Testi attesi confrontati con il codice dell'app. Correzioni emerse e già scritte nella guida:
  - l'etichetta della condizione è «Pizza» con la maiuscola;
  - i nomi esatti delle righe delle statistiche;
  - dopo una sospensione il ristoratore vede il conteggio delle segnalazioni ripartito da zero,
    mentre il pannello admin mostra 1.
