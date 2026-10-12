# HAPOSTO — Tessera fedeltà: guida di collaudo completa (DEV)

**12 ottobre 2026 · da usare dopo l'unione delle PR A–E della tessera (#26–#30).**

Questa guida porta dal codice su GitHub a una tessera fedeltà provata in ogni parte sul **DEV**:
Supabase, app del ristoratore, app del cliente, pannello admin. La tessera resta **nascosta**: in
modalità `TEST` la vedono solo i locali e i clienti tester, e alla fine si rispegne.

- **Tempo:** circa 1 ora e mezza (più un'attesa facoltativa per il codice di riserva).
- **Costi:** nessuno.
- **Serve:**
  - due telefoni, oppure un telefono e l'emulatore di Android Studio (guida, Parte 4.3);
  - il **tuo account** (admin: è sempre cliente tester) e quello del **ristoratore di prova**
    (titolare del locale di prova, con la verifica in due passaggi);
  - per il gruppo, un **terzo account Google** usato come secondo cliente (facoltativo, ma
    consigliato: si può aggiungere sull'emulatore).
- **Regola:** fai una parte alla volta e controlla il risultato atteso. Se qualcosa è diverso,
  fermati e scrivimi cosa vedi (meglio con una foto dello schermo).

Le regole della tessera sono in `docs/HAPOSTO_TESSERA_SPECIFICHE.md` (codici T1–T61).

---

## Parte A — Supabase DEV (una volta sola)

1. Apri Supabase e controlla in alto che il progetto sia il **DEV** (non la produzione).
2. **SQL Editor** → **New query** → incolla tutto il file
   `supabase/migrations/0018_loyalty_card.sql` (da GitHub: apri il file → **Raw** → seleziona
   tutto → copia) → **Run**.
   **Atteso:** in basso una riga con `modalita_tessera` = `OFF`, `tabelle_tessera` = `12`,
   `tessera_in_pro` = `true`. La migration è rieseguibile: se la lanci due volte non succede nulla
   di male.
3. **SQL Editor** → **New query** → incolla tutto `supabase/ops/scheduled_jobs.sql` → **Run**.
   **Atteso:** in fondo l'elenco dei lavori pianificati, con la riga
   `haposto-loyalty-maintenance` · `40 7 * * *` · `true` (ogni giorno alle 9:40 circa: preavvisi,
   azzeramenti, premi scaduti, pulizia dei QR vecchi).
4. **Edge Function:** **nessuna da ripubblicare.** Gli avvisi della tessera (chiusura, fine,
   sospensione, azzeramento) entrano nella stessa coda delle altre notifiche e li invia la funzione
   `push-dispatch` già pubblicata, che li manda così come sono. Basta che l'invio ogni minuto
   (`push_dispatch_cron.sql`, guida Parte 6) sia già attivo, come per le altre notifiche.
5. **Controlli automatici:** i 209 controlli della tessera (`step22_loyalty_checks.sql`) li esegue
   già la CI a ogni PR su un database pulito: sul DEV non servono.

## Parte B — App Dev aggiornata (su tutti e due i dispositivi)

1. Android Studio → **Git → Pull…** (ramo `main`) → **File → Sync Project with Gradle Files**.
2. **Build Variants** → `devDebug`.
3. Scegli il telefono accanto a ▶ → **Run**; poi scegli l'emulatore (o il secondo telefono) →
   **Run**. **Atteso:** l'app si apre come sempre; nessuna traccia della tessera (è spenta).

## Parte C — Preparazione della prova (pannello admin, dal tuo telefono)

Per provare tutto in poco tempo si abbassano **per la sola prova** alcuni numeri; alla Parte N si
rimettono come prima.

1. **Account** → tieni premuta 5 secondi la versione in fondo → sblocca il pannello.
2. **Impostazioni** → riquadro `loyalty` → nel testo cambia solo questi valori (gli altri restano
   come sono):

   | Trova | Sostituisci con | Perché |
   |---|---|---|
   | `"mode": "OFF"` | `"mode": "TEST"` | la vedono solo i tester |
   | `"stamps_min": 5` | `"stamps_min": 2` | premio con soli 2 timbri |
   | `"report_warn": 3` | `"report_warn": 1` | avviso alla prima segnalazione |
   | `"report_suspend": 5` | `"report_suspend": 1` | sospensione alla prima segnalazione |
   | `"suspension_days": 90` | `"suspension_days": 1` | sospensione di un giorno |

   → **Salva**. **Atteso:** «✓ Impostazione salvata». ⚠️ **Non scrivere mai `"ON"`** durante il
   collaudo: dopo il primo `"ON"` la tessera risulta lanciata e non torna più a `"OFF"` o
   `"TEST"`.
3. **Locali** → cerca il locale del ristoratore di prova → aprilo → riquadro **Tessera fedeltà
   (nascosta)** → accendi **Locale tester della tessera**.
4. Nella stessa scheda del locale controlla **Piano**: la tessera è inclusa in **Pro**. Se non è
   Pro, riquadro **Regala un piano** → **3 mesi** → **Attiva Pro per 3 mesi**. Lo stato del locale
   deve essere **Partner**.
5. Se usi il terzo account: **Utenti** → cercalo → aprilo → **Cliente tester della tessera** acceso.
6. **Scheda «Tessere»** (fra «Pagamenti» e «Registro»). **Atteso:** «Modalità: Prova: solo locali e
   clienti tester (gli admin sempre)», il locale fra i **locali tester** e il terzo account fra i
   **clienti tester**.

## Parte D — Il ristoratore attiva la tessera (dispositivo del ristoratore)

1. Dashboard del locale → **Gestisci il locale** → riquadro **Tessera fedeltà** («Non attivata») →
   **Apri la tessera fedeltà** → **Attiva la tessera**.
2. Sei passi, con «Avanti»:
   1. timbri: con «−» porta a **2**;
   2. condizione: una qualsiasi (per esempio «Almeno una consumazione fra quelle scelte» → pizza);
   3. giorno doppio: **Un giorno a settimana** → il giorno di **oggi** → **tutto il giorno**;
   4. premio: **🎁 Un omaggio dalla lista** → **Dolce**;
   5. come si usa: **Subito, anche alla stessa visita**; il resto come proposto;
   6. riepilogo: spunta **Accetto** sul patto → **Attiva la tessera** (se chiede il codice della
      verifica in due passaggi, inseriscilo).
3. **Atteso:** la scheda mostra «Attiva», le regole (versione 1) e la data del patto; tornando alla
   dashboard compare il tasto **📷 Timbra la tessera fedeltà**.

## Parte E — Cliente: QR, annullamento, timbro e premio

1. **Tuo telefono** → cerca il locale di prova → apri la scheda. **Atteso:** sotto gli orari il
   riquadro **🎫 Tessera fedeltà** con «2 timbri → Omaggio: dolce», «La tessera nasce al primo
   timbro…» e i tasti.
2. **Mostra il mio QR** → schermata della privacy (cosa vede il locale, cosa conserva HAPOSTO) →
   **Accetto e continuo**. **Atteso:** QR grande con cornice che pulsa, orologio che scorre, codice
   di 6 caratteri, barra «Si rinnova da solo tra … s», schermo al massimo della luminosità. Prova a
   fare uno screenshot: **viene bloccato** (è voluto).
3. **Ristoratore** → **📷 Timbra la tessera fedeltà** → si apre lo scanner di Google (al primo uso
   può scaricare un modulo) → inquadra il QR. **Atteso:** «✓ Cliente XXXX · +2 timbri (giorno
   doppio) · 2 su 2 · 🎁 premio sbloccato», la condizione, il premio da consegnare e
   **Annulla (ancora 1:5x)**. Sul tuo telefono, entro un secondo: «✓ +2 timbri, giorno doppio · 2
   su 2 · 🎁 Premio sbloccato».
4. Il ristoratore tocca **Annulla**. **Atteso:** «Scansione annullata: nessun timbro è stato dato».
   Sul tuo telefono la schermata dell'esito **non cambia**: è la fotografia del momento della
   scansione (limite noto). Il dato vero è nel riquadro del locale: dopo **Fatto** e indietro, il
   riquadro torna come prima del timbro.
5. **Tuo telefono:** tocca di nuovo **Mostra il mio QR** (il primo QR è già usato). **Ristoratore:** **📷 Timbra il prossimo** → inquadra. **Atteso sul tuo telefono, entro un
   secondo:** «✓ +2 timbri, giorno doppio · 2 su 2 · 🎁 Premio sbloccato» → **Fatto**.
6. **Prima** che il ristoratore tocchi «Consegnato»: sul tuo telefono **Account** → riquadro
   **Tessere fedeltà** → **🎫 Le mie tessere**. **Atteso:** il locale con «🎁 Omaggio: dolce», «Si
   usa anche oggi», la validità, il tuo codice e i tasti.
7. **Ristoratore:** nel riquadro **🎁 Premi da consegnare** tocca **Consegnato**. **Atteso:**
   «✓ Consegnato». Sul tuo telefono, riaprendo «Le mie tessere»: «Non hai ancora tessere…». È
   giusto: la tessera completata si chiude e la nuova parte alla prossima visita.

## Parte F — Tavolo di gruppo (con il terzo account)

1. **Tuo telefono** → scheda del locale → riquadro → **👥 Siamo in gruppo**. **Atteso:** «Tavolo: 1
   persona ✓», il QR del tavolo e le istruzioni con l'orario entro cui unirsi.
2. **Terzo account** (sull'emulatore o su un altro telefono, con l'app Dev) → scheda del locale →
   riquadro → **Unisciti a un tavolo** → privacy → **Accetto e continuo** → si apre lo scanner →
   inquadra il QR del tavolo. **Atteso:** «✓ Sei nel tavolo · 2 persone»; sul tuo telefono
   «Tavolo: 2 persone ✓».
3. **Ristoratore** → **📷 Timbra il prossimo** → inquadra il **QR del tavolo**. **Atteso:** «✓ Tavolo
   di 2 · 1 timbrato (1 già timbrato oggi)» e il premio da consegnare per il terzo account. **Non**
   toccare «Consegnato».
4. **Atteso sui telefoni dei clienti:** terzo account «✓ +2 timbri, giorno doppio · 🎁 Premio
   sbloccato»; tu «Hai già avuto un timbro qui nelle ultime 4 ore: questa volta niente timbro»
   (giusto: un timbro ogni 4 ore per locale).
5. **Terzo account** → **Account** → **🎫 Le mie tessere**: c'è il premio da usare. Tocca **Lascia
   questa tessera** → conferma. **Atteso:** «Tessera lasciata.» e l'elenco vuoto (timbri, premio e
   codice di quel locale cancellati).

## Parte G — Codice di riserva (facoltativo, dopo 4 ore)

Dopo 4 ore dall'ultimo timbro: **Mostra il mio QR**; il ristoratore tocca **Inserisci codice (se il
QR non si legge)**, scrive i 6 caratteri sotto il QR → **Timbra con il codice**. **Atteso:** lo
stesso esito della scansione. Un codice sbagliato risponde «Codice sbagliato (restano N tentativi
prima del blocco)».

## Parte H — Statistiche del ristoratore

**Ristoratore** → **Gestisci il locale** → **Apri la tessera fedeltà**. **Atteso:** tessere attive e
premi da consegnare, **Statistiche della tessera** a 7/30/90 giorni (scansioni, persone, timbri,
premi, giorni e orari) e **Tessere attive** con i soli codici anonimi: mai nomi o email.

## Parte I — Nuove regole (nuova versione)

1. **Ristoratore** → scheda della tessera → **Cambia le regole** → timbri **3** → avanti fino al
   riepilogo → **Accetto** → **Attiva la tessera**. **Atteso:** «Le regole (versione 2)».
2. **Tuo telefono** → scheda del locale. **Atteso:** il riquadro dice «3 timbri → Omaggio: dolce»
   (chi inizia da oggi ha le regole nuove; chi aveva già una tessera iniziata resta con le sue).

## Parte J — Segnalazione e sospensione automatica

1. **Tuo telefono** → scheda del locale → riquadro → **Segnala un problema ▾** → **Non hanno voluto
   timbrare** → **Invia**. **Atteso:** «✓ Segnalazione inviata…» e il riquadro sparisce: con la
   soglia a 1 la tessera del locale si è **sospesa da sola**.
2. **Ristoratore:** arriva la notifica «Tessera fedeltà sospesa»; nella scheda della tessera
   «Sospesa per le segnalazioni dei clienti fino al …»; il tasto **Timbra** non c'è più.

## Parte K — Pannello → Tessere e «Ridai la tessera»

1. **Tuo telefono** → pannello → **Tessere**. **Atteso:** «Sospesa per segnalazioni: 1» fra i locali,
   scansioni, timbri e premi degli ultimi 30 giorni, «Segnalazioni negli ultimi 60 giorni: 1», due
   versioni e due patti, il locale fra le **Sanzioni automatiche**.
2. **Registro** → cerca `LOYALTY`. **Atteso:** attivazione e versioni, scansione annullata,
   sospensione automatica.
3. **Tessere** → sotto il locale sospeso → **Ridai la tessera** → motivo (per esempio «collaudo») →
   **Ridai la tessera**. **Atteso:** «✓ Fatto: il locale può riattivare la tessera accettando di
   nuovo il patto»; il locale sparisce dalle sanzioni.
4. **Ristoratore** → scheda della tessera: «Finita» e il tasto **Attiva la tessera** → riattivala
   (stesse regole o altre) accettando il patto.

## Parte L — Chiusura con preavviso

1. **Ristoratore** → scheda della tessera → **Chiudi la tessera** → **Chiudi con preavviso**.
   **Atteso:** «In chiusura fino al …» (fra 30 giorni); il tasto **Timbra** resta, per chi deve
   completare la tessera.
2. **Tuo telefono** (senza tessera in corso) → scheda del locale. **Atteso:** il riquadro non c'è
   più: in preavviso il locale non apre tessere nuove. Chi ha una tessera in corso riceve l'avviso
   «La tessera sta per finire» e nel riquadro vede «Il locale chiude la tessera: puoi completarla
   entro il …».

## Parte M — Modalità «solo tessere già iniziate» (facoltativa)

1. Pannello → **Impostazioni** → `loyalty` → `"mode": "TEST"` → `"mode": "EXISTING_ONLY"` →
   **Salva**. **Atteso:** chi non ha una tessera non vede niente; il ristoratore che prova a
   cambiare le regole legge «In questo periodo la tessera accetta solo le tessere già iniziate».
2. Rimetti `"mode": "TEST"` (con `EXISTING_ONLY` partito da `TEST` si torna indietro senza
   problemi).

## Parte N — Fine del collaudo

1. Pannello → **Impostazioni** → `loyalty` → rimetti i valori di partenza:

   | Trova | Sostituisci con |
   |---|---|
   | `"stamps_min": 2` | `"stamps_min": 5` |
   | `"report_warn": 1` | `"report_warn": 3` |
   | `"report_suspend": 1` | `"report_suspend": 5` |
   | `"suspension_days": 1` | `"suspension_days": 90` |
   | `"mode": "TEST"` | `"mode": "OFF"` |

   → **Salva**.
2. **Atteso:** nella scheda del locale non c'è più il riquadro, in Account non c'è «Le mie
   tessere», nella dashboard non c'è **Timbra**; la scheda **Tessere** dice «Spenta: nessuno la
   vede». I dati della prova restano solo sul DEV e non danno fastidio: con la tessera spenta
   nessuno li vede.
3. Scrivimi l'esito: aggiorno lo stato (`docs/HAPOSTO_STATO_CONFIGURAZIONE.md`) e, se è emerso
   qualcosa, correggo codice o guida.

## Parte O — Produzione (quando vuoi, senza accendere niente)

Quando la produzione sarà pronta (guida, Parte 10), sullo stesso progetto di **produzione**:

1. controlla in alto il nome del progetto di **produzione**;
2. SQL Editor → `0018_loyalty_card.sql` → **Run** (atteso: `OFF`, `12`, `true`);
3. SQL Editor → `scheduled_jobs.sql` → **Run** (atteso: `haposto-loyalty-maintenance` attivo);
4. nessuna Edge Function da pubblicare per la tessera.

La tessera resta **spenta** anche lì. Si accende solo con la decisione di lancio (roadmap da qui al
lancio, fine pilot): prima le righe di privacy e termini (`docs/HAPOSTO_TESSERA_TESTI_LEGALI.md`),
poi `"mode": "ON"`.

---

## Riepilogo: cosa c'è e dove

| Parte | Dove | PR |
|---|---|---|
| Database, regole, controlli automatici, lavoro pianificato | `supabase/migrations/0018_loyalty_card.sql`, `supabase/tests/step22_loyalty_checks.sql`, `supabase/ops/scheduled_jobs.sql` | #26 |
| App del ristoratore: attivazione, patto, Timbra, premi, statistiche | Gestisci il locale → Tessera fedeltà; dashboard → Timbra | #27 |
| App del cliente: riquadro, QR, gruppo, Le mie tessere, segnalazioni, privacy | scheda del locale; Account → Le mie tessere | #28 |
| Pannello admin: scheda Tessere, tester, «Ridai la tessera» | pannello → Tessere; Locali → il locale | #29 |
| Righe per privacy e termini (da inserire al lancio), questa guida | `docs/HAPOSTO_TESSERA_TESTI_LEGALI.md`, `docs/HAPOSTO_TESSERA_COLLAUDO.md` | #30 |
