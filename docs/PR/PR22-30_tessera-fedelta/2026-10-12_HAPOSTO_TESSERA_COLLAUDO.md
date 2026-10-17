# HAPOSTO — Tessera fedeltà: guida di collaudo completa (DEV, un solo telefono)

**12 ottobre 2026 · da usare dopo l'unione delle PR della tessera (#26–#29) e di questa guida.**

Questa guida porta dal codice su GitHub a una tessera fedeltà provata in ogni parte sul **DEV**
con **un solo telefono** e il PC. La tessera resta **nascosta**: in modalità `TEST` la vedono solo
i locali e i clienti tester, e alla fine si rispegne.

## Prima di iniziare

**Si può fare con un solo telefono?** Sì, quasi tutto. Il trucco: il ristoratore non inquadra il
QR (non si può inquadrare lo schermo del telefono con lo stesso telefono), ma usa il **codice di
riserva di 6 caratteri** scritto sotto il QR, la strada prevista per quando un QR non si legge. Sul
telefono alterni due account: il tuo (cliente) e quello del ristoratore di prova.

Con un solo telefono **non si possono provare quattro cose**. Si provano in seguito con l'emulatore
del PC (Appendice, facoltativa):

1. la **scansione con la fotocamera** del QR del cliente (si prova solo che lo scanner si apre e
   rifiuta un QR qualsiasi);
2. l'**esito in tempo reale** sul telefono del cliente («✓ +2 timbri…» entro un secondo);
3. il **tavolo di gruppo** (per unirsi bisogna inquadrare lo schermo di un altro telefono);
4. le **notifiche** all'altro account: si controllano dal PC con una query (Parte K).

Tutto il resto è coperto: attivazione e patto, timbro, giorno doppio, annullamento, codice già
usato, premio, nuove regole, «Le mie tessere», lascia la tessera, statistiche, segnalazione e
sospensione automatica, pannello admin e «Ridai la tessera», chiusura con preavviso, modalità
«solo esistenti», spegnimento.

**Tempo:** circa 2 ore, con 14 cambi di account da un minuto l'uno. **Costi:** nessuno.

**Serve:**
- il telefono con l'app **Dev** (Parte B);
- **Google Authenticator** sul telefono, con le due voci: la tua email e quella del ristoratore di
  prova (la verifica in due passaggi l'hai già attivata per entrambi);
- i due account Google già aggiunti al telefono (Impostazioni del telefono → Google / Account);
- il **PC** con Supabase (DEV) aperto nel browser;
- nome utente e password del **pannello admin**;
- **carta e penna** per annotare i codici di riserva.

**Regola:** fai una parte alla volta e controlla il risultato **Atteso**. Se qualcosa è diverso,
fermati e scrivimi cosa vedi (meglio con una foto dello schermo).

Le regole della tessera sono in `docs/PR/PR22-30_tessera-fedelta/2026-10-12_HAPOSTO_TESSERA_SPECIFICHE.md` (codici T1–T61).

## Legenda e cambio di account

- **👤 TU** = il tuo account: admin del pannello e cliente della tessera (gli admin sono sempre
  clienti tester).
- **🍴 RISTO** = l'account del **ristoratore di prova**, titolare del locale di prova.
- **🖥 PC** = Supabase nel browser.

Quando la guida dice **➜ Diventa 🍴 RISTO** oppure **➜ Diventa 👤 TU**, fai questa procedura.

### ➜ Diventa 🍴 RISTO

1. Se sei dentro una schermata (QR, scheda del locale, pannello…), tocca **Indietro** in alto a
   sinistra finché vedi la barra in basso (Vicino · Preferiti · Ristoratore · Account).
2. Barra in basso → **👤 Account** → scorri fino in fondo → **Esci**.
   ⚠️ **Non** toccare «Esci da tutti i dispositivi» né «Elimina account».
3. Nella stessa schermata → **G Accedi con Google** → nella finestra di Google scegli l'account
   del **ristoratore di prova**.
4. Barra in basso → **🍴 Ristoratore** → riquadro «Inserisci il codice di verifica» → **Inserisci
   il codice** → apri **Authenticator** → voce con l'email del **ristoratore** → scrivi le 6 cifre
   in «Codice di 6 cifre» → **Verifica**.
5. Torni all'area ristoratore: tocca il riquadro del tuo locale (**Apri ›**) → sei nella
   **dashboard** («Area ristoratore»).

### ➜ Diventa 👤 TU

1. **Indietro** fino alla barra in basso.
2. **👤 Account** → in fondo **Esci** (non «Esci da tutti i dispositivi», non «Elimina account»).
3. **G Accedi con Google** → scegli il **tuo** account.
4. Il codice di Authenticator ti verrà chiesto solo quando apri il pannello admin (procedura
   successiva).

### Aprire il pannello admin (👤 TU)

1. **👤 Account** → scorri fino al riquadro **Informazioni** → **tieni premuta per 5 secondi** la
   riga con la versione («HAPOSTO … · DEV»).
2. Se compare «Serve la verifica in due passaggi…» → **Verifica in due passaggi** → codice di
   Authenticator della voce con la **tua** email → **Verifica**.
3. «Sblocca il pannello»: **Nome utente** e **Password del pannello** → **Sblocca**. In alto vedi
   «Pannello HAPOSTO · 30 min».

### Codici di riserva

- Il codice è di **6 caratteri** (lettere maiuscole e numeri, mai I, L, O, 0, 1) ed è sotto il QR.
- Per la prova vale **5 minuti** (Parte C). Dal momento in cui lo annoti hai 5 minuti per farlo
  inserire al ristoratore: il cambio di account ne richiede uno o due.
- Se scade, il ristoratore legge «Codice sbagliato (restano N tentativi prima del blocco)»: torna a
  👤 TU e crea un codice nuovo. Dopo 10 codici sbagliati in 10 minuti l'inserimento si blocca per
  10 minuti.

---

## Parte A — Supabase DEV (🖥 PC, una volta sola)

1. Apri Supabase e controlla in alto che il progetto sia il **DEV** (non la produzione).
2. **SQL Editor** → **New query** → incolla **tutto** il file
   `supabase/migrations/0018_loyalty_card.sql` (su GitHub: apri il file → **Raw** → Ctrl+A →
   Ctrl+C) → **Run**.
   **Atteso:** in basso una riga con `modalita_tessera` = `OFF`, `tabelle_tessera` = `12`,
   `tessera_in_pro` = `true`. La migration è rieseguibile: lanciarla due volte non fa danni.
3. **SQL Editor** → **New query** → incolla tutto `supabase/ops/scheduled_jobs.sql` → **Run**.
   **Atteso:** in fondo l'elenco dei lavori pianificati, con la riga
   `haposto-loyalty-maintenance` · `40 7 * * *` · `true`.
4. **Edge Function: nessuna da ripubblicare.** Gli avvisi della tessera entrano nella stessa coda
   delle altre notifiche e li invia la funzione `push-dispatch` già pubblicata. Basta che l'invio
   ogni minuto (`push_dispatch_cron.sql`, guida Parte 6) sia già attivo.
5. **Controlli automatici:** i 209 controlli della tessera li esegue già la CI a ogni PR: sul DEV
   non servono.

## Parte B — App Dev aggiornata (🖥 PC e telefono)

1. **GitHub Desktop** → in alto **Fetch origin** → se compare **Pull origin**, cliccalo → scheda
   **History**: in cima deve esserci l'ultimo «Merge pull request #…».
2. **Android Studio** (stessa cartella) → **File → Sync Project with Gradle Files**.
3. **Build → Select Build Variant** → modulo `app` → `devDebug`.
4. Collega il telefono → sceglilo accanto a ▶ → **Run**.
   **Atteso:** l'app si apre come sempre e della tessera non c'è traccia (è spenta).

## Parte C — Preparazione (🖥 PC e 👤 TU)

1. 🖥 **SQL Editor** → **New query** → incolla ed esegui (**Run**):

   ```sql
   -- Collaudo della tessera: valori temporanei (alla Parte P si rimettono quelli di partenza).
   select public.admin_set_config('loyalty',
       (select value from public.app_config where key = 'loyalty')
       || '{"mode": "TEST", "stamps_min": 2, "token_seconds": 300,
            "report_warn": 1, "report_suspend": 1, "suspension_days": 1}'::jsonb);

   select value ->> 'mode' as modalita, value ->> 'stamps_min' as timbri_minimi,
          value ->> 'token_seconds' as secondi_codice, value ->> 'report_warn' as avviso_a,
          value ->> 'report_suspend' as sospensione_a, value ->> 'suspension_days' as giorni_sospensione,
          value ->> 'launched' as lanciata
   from public.app_config where key = 'loyalty';
   ```

   **Atteso:** `TEST` · `2` · `300` · `1` · `1` · `1` · `false`.

   | Valore | Per la prova | Perché |
   |---|---|---|
   | `mode` | `TEST` | la vedono solo i tester |
   | `stamps_min` | `2` | il ristoratore può scegliere 2 timbri: un timbro doppio basta per il premio |
   | `token_seconds` | `300` | il codice di riserva vale 5 minuti, il tempo di cambiare account |
   | `report_warn`, `report_suspend` | `1` | una segnalazione basta per la sospensione automatica |
   | `suspension_days` | `1` | la sospensione dura un giorno |

   ⚠️ **Non usare mai `"ON"`** durante il collaudo: dopo il primo `"ON"` la tessera risulta
   lanciata e non torna più a `"OFF"` o `"TEST"`.
2. 👤 Telefono: se non sei già dentro con il tuo account, **G Accedi con Google** → il tuo account.
3. 👤 Apri il pannello admin (procedura sopra) → scheda **Locali** → nel campo «Nome, città, id o
   slug» scrivi il nome del locale di prova → **Cerca** → tocca il locale.
4. Nella scheda del locale controlla:
   - **Stato**: deve essere **Partner**;
   - **Piano**: deve essere **Pro**. Se non lo è: riquadro **Regala un piano** → **3 mesi** →
     **Attiva Pro per 3 mesi**.
5. Scorri fino al riquadro **Tessera fedeltà (nascosta)** → accendi **Locale tester della
   tessera**. **Atteso:** «✓ Locale tester della tessera.».
6. **Indietro** → scheda **Tessere** (scorri le schede in alto, fra «Pagamenti» e «Registro»).
   **Atteso:** «Modalità: Prova: solo locali e clienti tester (gli admin sempre)»; il locale fra i
   **Locali tester**.

## Parte D — Il ristoratore attiva la tessera (🍴 RISTO)

**➜ Diventa 🍴 RISTO.**

1. Dashboard → **⚙ Gestisci il locale · dati, orari, QR, staff, statistiche** → scorri fino al
   riquadro **Tessera fedeltà** («Non attivata») → **Apri la tessera fedeltà** → **Attiva la
   tessera**.
2. Sei passi, con **Avanti**:
   1. timbri: con «−» e «+» porta a **3**;
   2. condizione: **Almeno una consumazione fra quelle scelte** → spunta **Pizza**;
   3. giorno doppio: **Un giorno a settimana** → il giorno di **oggi** (lun, mar, …) → **tutto il
      giorno**;
   4. premio: **🎁 Un omaggio dalla lista** → **Dolce**;
   5. da quando: **Subito, anche alla stessa visita**; il resto come proposto;
   6. riepilogo: leggi il patto → spunta **Accetto** → **Attiva la tessera** (se chiede il codice,
      Authenticator, voce del ristoratore).
3. **Atteso:** la scheda dice «Attiva», «Le regole (versione 1)» con 3 timbri e giorno doppio.
4. **Indietro** due volte fino alla dashboard. **Atteso:** sotto «Gestisci il locale» c'è il tasto
   **📷 Timbra la tessera fedeltà**.
5. *Prova dello scanner (facoltativa):* tocca **📷 Timbra la tessera fedeltà** → si apre lo scanner
   di Google (al primo uso può scaricare un modulo; non chiede il permesso della fotocamera) →
   inquadra un QR **qualsiasi** (una confezione, un volantino, il QR di un sito sul monitor del PC).
   **Atteso:** «Non è il QR della tessera HAPOSTO: chiedi al cliente di aprire «Mostra il mio QR».»
   → **Indietro**.

## Parte E — Il cliente vede la tessera e crea il codice A (👤 TU)

**➜ Diventa 👤 TU.**

1. Scheda **Vicino** → cerca il locale di prova → apri la sua scheda → scorri sotto gli orari.
   **Atteso:** riquadro **🎫 Tessera fedeltà** con «3 timbri → Omaggio: dolce», «La tessera nasce
   al primo timbro: quando paghi, mostra il QR alla cassa.» e i tasti **Mostra il mio QR**,
   **👥 Siamo in gruppo**, **Unisciti a un tavolo**.
2. Tocca **Regole della tessera ▾**. **Atteso:** timbri, condizione, giorno doppio di oggi, premio
   e come si usa. Richiudi.
3. **Mostra il mio QR** → schermata «Prima di iniziare» (cosa vede il locale, cosa conserva HAPOSTO
   e per quanto) → **Accetto e continuo**.
   **Atteso:** QR grande con la cornice che pulsa, l'orologio che scorre, il **codice di 6
   caratteri** (es. «BQM C6P»), la barra «Si rinnova da solo tra … s» (circa 300), schermo al
   massimo della luminosità.
4. Prova a fare uno screenshot. **Atteso:** viene bloccato (è voluto: niente foto del QR).
5. ✍️ **Annota il codice → codice A.** Tocca **Indietro**: il codice resta valido per 5 minuti.

## Parte F — Primo timbro e nuove regole (🍴 RISTO)

**➜ Diventa 🍴 RISTO** (entro 5 minuti dal codice A).

1. Dashboard → **📷 Timbra la tessera fedeltà** → si apre lo scanner: chiudilo con **Indietro**
   (o la ✕).
2. **Inserisci codice (se il QR non si legge)** → scrivi il **codice A** → **Timbra con il codice**.
   **Atteso:** «✓ Cliente XXXX · +2 timbri (giorno doppio) · 2 su 3», sotto «Condizione: Almeno una
   consumazione tra: pizza» e **Annulla (ancora 1:5x)**. ✍️ Annota **XXXX**: è il codice anonimo
   del cliente, l'unica cosa che il locale vede di te.
3. **Indietro** fino alla dashboard → **⚙ Gestisci il locale** → **Apri la tessera fedeltà** →
   **Cambia le regole**.
4. Passo 1: porta i timbri a **2** → **Avanti** fino al riepilogo (il resto resta uguale) →
   **Accetto** → **Attiva la tessera**.
   **Atteso:** «Le regole (versione 2)» con 2 timbri, e la nota «Le regole nuove valgono solo per
   chi inizia da oggi…».

## Parte G — Le mie tessere e «Lascia la tessera»; codici B e C (👤 TU)

**➜ Diventa 👤 TU.**

1. Scheda del locale → riquadro **🎫 Tessera fedeltà**.
   **Atteso:** «3 timbri → Omaggio: dolce» (le regole della **tua** versione, la 1), «2 su 3 timbri»
   con ●●○, «Il tuo codice per questo locale: XXXX» (uguale a quello annotato in F).
2. **👤 Account** → riquadro **Tessere fedeltà** → **🎫 Le mie tessere**.
   **Atteso:** il locale con «2 su 3 timbri», «Se non torni, i timbri si azzerano il …» (fra 6
   mesi), **Regole della tessera ▾** (versione 1), il codice e i tasti.
3. **Lascia questa tessera** → «Lasciare la tessera?» → **Lascia la tessera**.
   **Atteso:** «Tessera lasciata.» e «Non hai ancora tessere…».
4. Torna alla scheda del locale. **Atteso:** riquadro con «**2** timbri → Omaggio: dolce» (le
   regole nuove, per chi inizia da oggi), «La tessera nasce al primo timbro…» e **nessuna** riga
   «Il tuo codice…» (lasciando la tessera si cancella anche il codice anonimo).
5. **Mostra il mio QR** → ✍️ annota → **codice B** → **Indietro**.
6. **Mostra il mio QR** di nuovo → ✍️ annota → **codice C** (diverso da B) → **Indietro**.
   Hai 5 minuti per B e C.

## Parte H — Annullamento, premio, codice già usato (🍴 RISTO)

**➜ Diventa 🍴 RISTO** (entro 5 minuti da B e C).

1. **📷 Timbra la tessera fedeltà** → chiudi lo scanner → **Inserisci codice** → **codice B** →
   **Timbra con il codice**.
   **Atteso:** «✓ Cliente YYYY · +2 timbri (giorno doppio) · 2 su 2 · 🎁 premio sbloccato» (YYYY è
   un codice nuovo: hai lasciato la tessera), il riquadro **🎁 Premi da consegnare** con «Omaggio:
   dolce» e **Annulla (ancora 1:5x)**. Che tu abbia avuto un timbro poco fa non conta: lasciando la
   tessera i timbri si sono cancellati.
2. Tocca **Annulla (ancora …)**. **Atteso:** «Scansione annullata: nessun timbro è stato dato.».
3. **Inserisci codice** → **codice C** → **Timbra con il codice**.
   **Atteso:** di nuovo «✓ Cliente YYYY · +2 timbri (giorno doppio) · 2 su 2 · 🎁 premio sbloccato» e
   il premio da consegnare. ⚠️ **Non** toccare «Consegnato»: serve alla Parte I.
4. **Inserisci codice** → di nuovo il **codice B**.
   **Atteso:** «Codice sbagliato (restano 9 tentativi prima del blocco).»: un codice usato non vale
   più (B era stato usato, anche se poi annullato).

## Parte I — Il premio dalla parte del cliente; codice D (👤 TU)

**➜ Diventa 👤 TU.**

1. Scheda del locale → riquadro. **Atteso:** «🎁 Omaggio: dolce», «Si usa anche oggi: dillo alla
   cassa prima di pagare.», «Valido fino al …» (fra 60 giorni).
2. **👤 Account** → **🎫 Le mie tessere**. **Atteso:** il locale con lo stesso premio.
3. Scheda del locale → **Mostra il mio QR** → ✍️ annota → **codice D** → **Indietro**.

## Parte J — Consegna del premio e statistiche (🍴 RISTO)

**➜ Diventa 🍴 RISTO** (entro 5 minuti da D).

1. **📷 Timbra la tessera fedeltà** → chiudi lo scanner → **Inserisci codice** → **codice D**.
   **Atteso:** «Cliente YYYY · già timbrato nelle ultime 4 ore: nessun timbro» (giusto: un timbro
   ogni 4 ore) **e** il riquadro **🎁 Premi da consegnare** con il dolce.
2. Tocca **Consegnato**. **Atteso:** «✓ Consegnato».
3. **Indietro** → **⚙ Gestisci il locale** → **Apri la tessera fedeltà**. **Atteso:**
   - «Tessere attive: 0 · premi da consegnare: 0»;
   - **Statistiche della tessera** → **30 giorni**: «Visite timbrate: 3 (di cui tavoli di gruppo:
     0)», «Persone timbrate: 2 · nuove 2 · di ritorno 0», «Timbri dati: 4 (doppi: 2)», «Tessere
     iniziate: 2 · attive ora 0», «Premi: sbloccati 1 · usati 1 · scaduti 0» e «Quando arrivano: …».
     Le persone sono 2 perché, lasciando la tessera, sei diventato un cliente nuovo con un codice
     nuovo; la scansione annullata non conta;
   - **Tessere attive**: «Ancora nessuna» (la tua si è completata);
   - mai nomi o email, solo codici anonimi e numeri.

## Parte K — Segnalazione e sospensione automatica (👤 TU e 🖥 PC)

**➜ Diventa 👤 TU.**

1. **👤 Account** → **🎫 Le mie tessere**. **Atteso:** «Non hai ancora tessere…». È giusto: la
   tessera completata si è chiusa, il premio è stato consegnato e la nuova parte alla prossima
   visita.
2. Scheda del locale → riquadro. **Atteso:** «2 timbri → Omaggio: dolce», «Il tuo codice per questo
   locale: YYYY» e **Segnala un problema ▾**.
3. **Segnala un problema ▾** → **Non hanno voluto timbrare** → «Inviare la segnalazione?» →
   **Invia**.
   **Atteso:** «✓ Segnalazione inviata. Grazie: il locale non saprà chi l'ha fatta.» e il riquadro
   **sparisce**: con la soglia a 1 la tessera del locale si è sospesa da sola.
4. Apri il pannello admin → scheda **Tessere**. **Atteso:**
   - «Locali con la tessera»: «Sospesa per segnalazioni: 1»;
   - «Ultimi 30 giorni»: scansioni, persone, timbri, premi sbloccati 1, premi usati 1;
   - «Versioni, patti e segnalazioni»: 2 versioni, 2 patti, 1 segnalazione;
   - **Sanzioni automatiche**: il locale, «sospesa per segnalazioni fino al …» (domani).

   ⚠️ **Non** toccare ancora «Ridai la tessera».
5. Scheda **Registro** → nel campo scrivi `LOYALTY` → **Cerca**. **Atteso:** fra le righe
   `LOYALTY_VERSION_PUBLISHED`, `LOYALTY_SCAN_UNDONE`, `LOYALTY_AUTO_SUSPENDED`.
6. 🖥 *Avvisi (facoltativo):* con un solo telefono la notifica al ristoratore non arriva, perché in
   quel momento sul telefono c'è il tuo account. Si controlla che sia partita: SQL Editor →

   ```sql
   select created_at, title, body, sent_at
   from public.notification_outbox
   where data ->> 'type' like 'LOYALTY%'
   order by created_at desc
   limit 10;
   ```

   **Atteso:** «Tessera fedeltà sospesa» con il testo per il locale; `sent_at` pieno vuol dire
   gestita dall'invio automatico (arrivata, o chiusa perché l'account non era su nessun telefono).

## Parte L — Il ristoratore vede la sospensione (🍴 RISTO)

**➜ Diventa 🍴 RISTO.**

1. Dashboard. **Atteso:** il tasto **📷 Timbra la tessera fedeltà** non c'è più.
2. **⚙ Gestisci il locale** → riquadro **Tessera fedeltà**: «Sospesa per le segnalazioni dei
   clienti fino al …» → **Apri la tessera fedeltà**. **Atteso:** lo stesso stato; in **Segnalazioni
   dei clienti** «0 negli ultimi 60 giorni. Avviso a 1; a 1 la tessera si sospende da sola…»: dopo
   una sospensione il conteggio riparte da zero.

## Parte M — «Ridai la tessera» dal pannello (👤 TU)

**➜ Diventa 👤 TU.**

1. Pannello admin → **Tessere** → **Sanzioni automatiche** → sotto il locale **Ridai la tessera** →
   «Motivo»: `collaudo` → **Ridai la tessera**.
   **Atteso:** «✓ Fatto: il locale può riattivare la tessera accettando di nuovo il patto.» e
   «Nessun locale sospeso o con la tessera tolta.».
2. **Locali** → il locale → riquadro **Tessera fedeltà (nascosta)**. **Atteso:** «Tessera del locale:
   finita», «Versioni: 2 · tessere attive: 0 · segnalazioni (60 giorni): 1».

## Parte N — Riattivazione e chiusura con preavviso (🍴 RISTO)

**➜ Diventa 🍴 RISTO.**

1. **⚙ Gestisci il locale** → **Apri la tessera fedeltà**. **Atteso:** «Finita» e il tasto
   **Attiva la tessera**.
2. **Attiva la tessera** → **Avanti** fino al riepilogo (regole proposte uguali alla versione 2) →
   **Accetto** → **Attiva la tessera**. **Atteso:** «Attiva», «Le regole (versione 3)».
3. **Chiudi la tessera** → «Chiudere la tessera?» → **Chiudi con preavviso**.
   **Atteso:** «In chiusura fino al …» (fra 30 giorni).
4. **Indietro** alla dashboard. **Atteso:** **📷 Timbra la tessera fedeltà** c'è ancora (serve a chi
   deve completare la tessera durante il preavviso).

## Parte O — Il cliente durante il preavviso; modalità «solo esistenti» (👤 TU e 🖥 PC)

**➜ Diventa 👤 TU.**

1. Scheda del locale. **Atteso:** il riquadro della tessera **non c'è**: in preavviso il locale
   non apre tessere nuove e tu non ne hai una in corso. (Chi ne ha una riceve l'avviso «La tessera
   sta per finire» e nel riquadro vede «Il locale chiude la tessera: puoi completarla entro il …».)
2. 🖥 *Modalità «solo tessere già iniziate» (facoltativa):* SQL Editor →

   ```sql
   select public.admin_set_config('loyalty',
       (select value from public.app_config where key = 'loyalty') || '{"mode": "EXISTING_ONLY"}'::jsonb);
   select value ->> 'mode' as modalita, value ->> 'launched' as lanciata
   from public.app_config where key = 'loyalty';
   ```

   **Atteso:** `EXISTING_ONLY` · `false` (partendo da `TEST` non risulta lanciata, si torna
   indietro). Poi **➜ Diventa 🍴 RISTO** → **⚙ Gestisci il locale** → **Apri la tessera
   fedeltà**. **Atteso:** il messaggio «In questo periodo la tessera accetta solo le tessere già
   iniziate: le regole non si cambiano.». Poi **➜ Diventa 👤 TU**.

## Parte P — Fine del collaudo (🖥 PC e 👤 TU)

1. 🖥 SQL Editor → **New query** → incolla ed esegui:

   ```sql
   -- Fine del collaudo: valori di partenza e tessera spenta.
   select public.admin_set_config('loyalty',
       (select value from public.app_config where key = 'loyalty')
       || '{"mode": "OFF", "stamps_min": 5, "token_seconds": 60,
            "report_warn": 3, "report_suspend": 5, "suspension_days": 90}'::jsonb);

   select value ->> 'mode' as modalita, value ->> 'stamps_min' as timbri_minimi,
          value ->> 'token_seconds' as secondi_codice, value ->> 'report_warn' as avviso_a,
          value ->> 'report_suspend' as sospensione_a, value ->> 'suspension_days' as giorni_sospensione,
          value ->> 'launched' as lanciata
   from public.app_config where key = 'loyalty';
   ```

   **Atteso:** `OFF` · `5` · `60` · `3` · `5` · `90` · `false`.
2. 👤 Telefono: chiudi e riapri l'app. **Atteso:**
   - nella scheda del locale nessun riquadro della tessera;
   - in **Account** nessun riquadro «Tessere fedeltà»;
   - pannello → **Tessere**: «Spenta: nessuno la vede».
3. *Facoltativo:* **➜ Diventa 🍴 RISTO** → dashboard senza **Timbra** e, in «Gestisci il locale»,
   nessun riquadro della tessera.
4. Scrivimi l'esito: aggiorno lo stato (`docs/configurazione/2026-10-17_HAPOSTO_STATO_CONFIGURAZIONE.md`) e, se è emerso
   qualcosa, correggo codice o guida. I dati della prova restano solo sul DEV e, con la tessera
   spenta, nessuno li vede.

## Parte Q — Produzione (quando vuoi, senza accendere niente)

Quando la produzione sarà pronta (guida, Parte 10), sul progetto di **produzione**:

1. controlla in alto il nome del progetto di **produzione**;
2. SQL Editor → `0018_loyalty_card.sql` → **Run** (atteso: `OFF`, `12`, `true`);
3. SQL Editor → `scheduled_jobs.sql` → **Run** (atteso: `haposto-loyalty-maintenance` attivo);
4. nessuna Edge Function da pubblicare per la tessera.

La tessera resta **spenta** anche lì. Si accende solo con la decisione di lancio (roadmap da qui al
lancio, fine pilot): prima le righe di privacy e termini (`docs/PR/PR22-30_tessera-fedelta/2026-10-12_HAPOSTO_TESSERA_TESTI_LEGALI.md`),
poi `"mode": "ON"`.

---

## Appendice — Le quattro prove con un secondo dispositivo (facoltativa, circa 30 minuti)

Serve l'**emulatore** di Android Studio sul PC come «secondo telefono» (guida, Parte 4.3: Device
Manager → Pixel con immagine Google Play → avvialo → aggiungi un account Google → ▶ **Run** con
`devDebug`). Il telefono inquadra lo schermo del PC. Fai l'appendice **fra la Parte J e la Parte K**
(serve la tessera attiva), con la stessa preparazione della Parte C.

1. **Scansione vera ed esito in tempo reale.** Emulatore: entra come 👤 TU → scheda del locale →
   **Mostra il mio QR** (il QR compare sul monitor). Telefono: 🍴 RISTO → **📷 Timbra la tessera
   fedeltà** → inquadra il QR sul monitor. **Atteso:** sul telefono l'esito; sull'emulatore, entro
   un secondo, «Hai già avuto un timbro qui nelle ultime 4 ore…» (oppure «✓ +2 timbri…» se sono
   passate 4 ore).
2. **Tavolo di gruppo.** Serve un **terzo account Google** reso cliente tester (pannello → **Utenti**
   → l'account → **Cliente tester della tessera**).
   - Emulatore, con il terzo account: scheda del locale → **👥 Siamo in gruppo** (il QR del tavolo e
     il suo codice compaiono sul monitor).
   - Telefono, con 👤 TU: scheda del locale → **Unisciti a un tavolo** → inquadra il QR del tavolo
     sul monitor. **Atteso:** «✓ Sei nel tavolo · 2 persone»; sull'emulatore «Tavolo: 2 persone ✓».
   - Telefono: **➜ Diventa 🍴 RISTO** → **📷 Timbra** → chiudi lo scanner → **Inserisci codice** con
     il codice scritto sotto il QR del tavolo sull'emulatore. **Atteso:** «Tavolo di 2 · 1 timbrato
     (1 già timbrato oggi)»; sull'emulatore «✓ +2 timbri, giorno doppio · 🎁 Premio sbloccato».
3. **Notifiche all'altro account.** Con 🍴 RISTO sul telefono e 👤 TU sull'emulatore, fai la Parte K
   (punto 3) dall'emulatore. **Atteso:** sul telefono, entro un minuto circa, la notifica «Tessera
   fedeltà sospesa».

---

## Riepilogo: cosa c'è e dove

| Parte | Dove | PR |
|---|---|---|
| Database, regole, controlli automatici, lavoro pianificato | `supabase/migrations/0018_loyalty_card.sql`, `supabase/tests/step22_loyalty_checks.sql`, `supabase/ops/scheduled_jobs.sql` | #26 |
| App del ristoratore: attivazione, patto, Timbra, premi, statistiche | Gestisci il locale → Tessera fedeltà; dashboard → Timbra | #27 |
| App del cliente: riquadro, QR, gruppo, Le mie tessere, segnalazioni, privacy | scheda del locale; Account → Le mie tessere | #28 |
| Pannello admin: scheda Tessere, tester, «Ridai la tessera»; testi legali | pannello → Tessere; Locali → il locale; `docs/PR/PR22-30_tessera-fedelta/2026-10-12_HAPOSTO_TESSERA_TESTI_LEGALI.md` | #29 |
| Questa guida (un solo telefono) | `docs/PR/PR22-30_tessera-fedelta/2026-10-12_HAPOSTO_TESSERA_COLLAUDO.md` | #30 |
