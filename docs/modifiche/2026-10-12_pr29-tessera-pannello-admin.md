# 2026-10-12 — Tessera fedeltà, PR D: pannello admin e prova sul DEV

- **Data:** 12 ottobre 2026
- **Branch:** `claude/amazing-pasteur-dull9l`
- **PR:** [#29](https://github.com/paolomarchionetti-glitch/haposto/pull/29)
- **Motivo:** quarto dei cinque passi della tessera fedeltà nascosta (specifiche v3, §11 e §13).
  Dopo database (#26), ristoratore (#27) e cliente (#28): la scheda **Tessere** del pannello admin
  (numeri, sanzioni, tester) e la **guida di prova completa sul DEV**, verificata passo per passo
  sul database locale. Il pannello è già nascosto e protetto: nell'app per gli utenti non cambia
  nulla.

## File modificati, aggiunti, rinominati ed eliminati

| File | Tipo |
|---|---|
| `app/src/main/java/com/haposto/data/admin/AdminLoyaltyTexts.kt` | aggiunto |
| `app/src/main/java/com/haposto/ui/screens/admin/AdminLoyaltyTab.kt` | aggiunto |
| `app/src/main/java/com/haposto/data/admin/AdminModels.kt` | modificato |
| `app/src/main/java/com/haposto/data/admin/AdminRepository.kt` | modificato |
| `app/src/main/java/com/haposto/data/remote/supabase/SupabaseAdminRepository.kt` | modificato |
| `app/src/main/java/com/haposto/data/Outcome.kt` | modificato |
| `app/src/main/java/com/haposto/ui/screens/admin/AdminRoute.kt` | modificato |
| `app/src/main/java/com/haposto/ui/screens/admin/AdminViewModel.kt` | modificato |
| `app/src/main/java/com/haposto/ui/screens/admin/AdminDetailRoutes.kt` | modificato |
| `app/src/main/java/com/haposto/ui/screens/loyalty/LoyaltyRestaurantBox.kt` | modificato |
| `app/src/test/java/com/haposto/data/remote/supabase/AdminLoyaltyDecodingTest.kt` | aggiunto |
| `app/src/androidTest/java/com/haposto/ui/screens/admin/AdminLoyaltyTabTest.kt` | aggiunto |
| `docs/HAPOSTO_GUIDA_CONFIGURAZIONE_COMPLETA.md` | modificato |
| `docs/HAPOSTO_TESSERA_SPECIFICHE.md` | modificato |
| `docs/HAPOSTO_STATO_CONFIGURAZIONE.md` | modificato |
| `docs/modifiche/2026-10-12_pr29-tessera-pannello-admin.md` | aggiunto (questo file) |

Nessun file rinominato o eliminato. Nessuna migration nuova: le funzioni `admin_loyalty_overview`
e `admin_loyalty_restore` esistono già dalla 0018.

## Dettaglio delle modifiche

### Pannello admin

- **Scheda «Tessere»** (fra «Pagamenti» e «Registro»), da `admin_loyalty_overview`:
  - modalità in chiaro («Prova: solo locali e clienti tester») e, se la tessera è già stata
    lanciata, il promemoria che non torna più a OFF o TEST;
  - numeri in sei riquadri: locali con la tessera per stato, tessere dei clienti (attive,
    completate, azzerate, finite), ultimi 30 giorni (scansioni, tavoli, persone, timbri, premi,
    sconti riconosciuti in euro), premi per stato, tipi di premio scelti dai locali attivi,
    versioni, patti e segnalazioni degli ultimi 60 giorni;
  - **sanzioni automatiche**: i locali sospesi o con la tessera tolta, con «Apri il locale» e
    **Ridai la tessera** (facoltativo, con un motivo che finisce nel registro);
  - **tester**: locali e clienti tester, ognuno apre la sua scheda;
  - promemoria: le operazioni sono nel Registro cercando `LOYALTY`.

  Solo numeri e l'email dei clienti tester (scelti dall'admin): mai chi ha timbrato.
- **Scheda del locale** → «Tessera fedeltà (nascosta)»: in più regole attuali in una riga
  («10 timbri → 20% sulla sua consumazione, max 10 €»), versioni, tessere attive, segnalazioni
  degli ultimi 60 giorni, date di preavviso o sospensione e, solo con la tessera sospesa o tolta,
  **Ridai la tessera (facoltativo)** con la nota della scheda come motivo.
- I testi della scheda sono logica pura (`AdminLoyaltyTexts`), provata sulla JVM; lo stato della
  tessera del locale ha ora un solo testo per pannello e scheda «Tessere».
- Messaggio nuovo per `LOYALTY_NOT_SUSPENDED` («non c'è niente da ridare»).

### App del cliente (correzione emersa dalla prova)

- Se una segnalazione fa sospendere la tessera del locale, il riquadro sparisce: prima spariva
  anche la conferma «✓ Segnalazione inviata». Ora la conferma resta; si cancella al ritorno sulla
  scheda.

### Guida (Parte 11)

- **Pannello → Tessere**: cosa mostra e dove sono le operazioni.
- **Tessera fedeltà: prova completa sul DEV** in otto passi (circa 30 minuti): preparazione con
  valori temporanei (`stamps_min` 2, soglie delle segnalazioni a 1, sospensione di 1 giorno),
  attivazione con 2 timbri e giorno doppio oggi, QR e annullamento, timbro e premio, gruppo,
  segnalazione e sospensione automatica, scheda Tessere e «Ridai la tessera», fine della prova con
  i valori di partenza e `"mode": "OFF"`.

### Specifiche e stato

- Specifiche: PR D realizzata, come (§13).
- Stato: PR D fatta; la prova completa sul DEV sostituisce le prove facoltative delle PR B e C;
  prossima PR E.

## Costi

Nessuno.

## Verifiche

- JSON veri di `admin_loyalty_overview` e della tessera in `admin_restaurant_detail` (attiva,
  sospesa, ridata) presi dal database locale con la 0018; `admin_loyalty_restore` rifiuta una
  seconda volta con `LOYALTY_NOT_SUSPENDED`.
- **Guida verificata sul database locale** (Postgres 16, migration fino alla 0018 e dati di prova),
  simulando la prova passo per passo con gli stessi valori e la stessa sequenza: 21 controlli tutti
  verdi (impostazioni accettate, procedura guidata da 2 timbri, «+2 timbri, giorno doppio, 2 su 2,
  premio sbloccato», annullamento e nuovo timbro, QR già usato rifiutato, premio da consegnare
  subito, tavolo di 2 con 1 timbrato e 1 escluso, sospensione automatica con gli avvisi, numeri
  della scheda Tessere, riattivazione dopo «Ridai la tessera», tessera invisibile con OFF). La
  simulazione ha trovato tre punti della prima stesura da correggere, ora corretti nella guida:
  dopo «Consegnato» la tessera completata sparisce da «Le mie tessere» (la nuova parte alla visita
  dopo); la segnalazione va fatta dal riquadro del locale; l'avviso «Tessera fedeltà finita» arriva
  solo a chi ha ancora una tessera o un premio aperti.
- Test JVM sulla JVM con supabase-kt 3.7.0: `AdminLoyaltyDecodingTest` (4, nuovo) più i 41 delle
  PR precedenti: **45 test su 45 passano**.
- Test su emulatore aggiunto (`AdminLoyaltyTabTest`): modalità visibile e «Ridai la tessera» solo
  per il locale sospeso.
- Le schermate Compose le compila la CI (Google Maven non raggiungibile da questo ambiente).
