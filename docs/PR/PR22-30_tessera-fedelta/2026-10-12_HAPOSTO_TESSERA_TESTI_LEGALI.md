# HAPOSTO — Tessera fedeltà: righe per privacy e termini

**Versione 1 · 12 ottobre 2026 · BOZZA da far rileggere con gli altri documenti legali (Tappa 5).**

Queste righe completano privacy e termini quando la tessera fedeltà sarà **lanciata** (specifiche
§14). **Non sono ancora nei file legali**: privacy e termini sono gli stessi file mostrati
nell'app e pubblicati sul sito (`app/src/main/assets/legal/`). Inserirle ora renderebbe pubblica
una funzione che deve restare nascosta. Durante le prove (modalità `TEST`, solo tester scelti
dall'admin) le informazioni essenziali le dà già la schermata della privacy che l'app mostra al
primo uso della tessera (T59).

**Quando e come usarle**
1. Alla Tappa 5 della roadmap (documenti legali definitivi), consegnare questo file al
   professionista insieme agli altri documenti, con le domande del punto 4.
2. Solo se si decide di lanciare la tessera: inserire le righe (rilette) nei tre file indicati,
   aggiornare la schermata della privacy dell'app se il testo cambia
   (`LoyaltyTexts.PRIVACY_NOTICE`) e pubblicare una nuova versione dei documenti (pannello admin →
   Impostazioni → `legal`), così l'app chiede a tutti di riaccettare.
3. Poi si accende la tessera (pannello → Impostazioni → `loyalty` → `"mode": "ON"`).

I numeri (4 ore, 60 giorni, 6 mesi, 30 giorni, soglie delle segnalazioni) sono quelli di partenza
dell'impostazione `loyalty`: se l'admin li cambia, vanno cambiati anche qui.

---

## 1. Informativa sulla privacy (`privacy.md`)

### In §2 «Quali dati usiamo e perché», dopo «Se gestisci un locale»

```markdown
### Se usi la tessera fedeltà di un locale (facoltativa)
- **Codice anonimo** per ogni locale (per esempio `K4F7`): è casuale, diverso per ogni locale e
  stabile nel tempo. Il locale vede solo questo codice: **non vede** il tuo nome, la tua email, la
  foto, il telefono né le tessere che hai in altri locali.
- **Timbri e visite**: locale, data e ora di ogni timbro, numero di timbri, premi sbloccati e
  usati; per i tavoli di gruppo, quante persone erano nel gruppo.
- **QR della tessera** (personale e del tavolo): contengono solo un codice casuale che vale 60
  secondi e una volta sola. Conserviamo solo un'impronta del codice, non il codice.
- **Segnalazioni** che fai su un locale (due tipi, senza testo libero): il locale vede solo quante
  segnalazioni ha, mai chi le ha fatte.
- Per la tessera non usiamo il GPS né identificativi del telefono: la prova della visita è la
  scansione fatta dal locale.

Base giuridica: esecuzione del servizio che richiedi (art. 6.1.b GDPR); per le segnalazioni e la
prevenzione degli abusi, legittimo interesse a un servizio corretto per clienti e locali (art.
6.1.f).
```

### In §3 «Per quanto tempo», righe da aggiungere alla tabella

```markdown
| QR della tessera e tavoli di gruppo | 1 giorno |
| Timbri e visite della tessera | 24 mesi |
| Tessere e premi chiusi | 12 mesi, poi restano solo conteggi anonimi |
| Segnalazioni sui locali | 12 mesi |
```

### In §5 «I tuoi diritti», frase da aggiungere

```markdown
Puoi lasciare la tessera di un locale in ogni momento (Account → Le mie tessere → Lascia questa
tessera): timbri, premi e codice anonimo di quel locale si cancellano.
```

Fornitori: nessuno nuovo (database Supabase; avvisi con le notifiche di Firebase Cloud Messaging,
già elencati).

---

## 2. Termini d'uso (`termini.md`)

### Sezione nuova «La tessera fedeltà dei locali»

```markdown
## La tessera fedeltà dei locali

- La tessera è **gratuita e facoltativa** e richiede l'accesso con Google. Si usa solo nei locali
  che la offrono.
- Il **timbro** lo dà il locale scansionando il tuo QR (o quello del tuo tavolo), alle condizioni
  che il locale indica nella sua scheda (per esempio una spesa minima a persona). Al massimo un
  timbro ogni 4 ore per locale (due nel giorno a timbro doppio, se il locale lo prevede). Se
  dimentichi il QR, il timbro di quella visita non si recupera.
- Le **regole della tua tessera** restano quelle del giorno in cui l'hai iniziata: se il locale le
  cambia, valgono solo per chi inizia dopo.
- Raggiunti i timbri indicati si sblocca il **premio**: è offerto dal locale, è personale, non si
  converte in denaro, vale 60 giorni dallo sblocco e si usa alle condizioni indicate (da quando,
  in quali giorni, quanti per tavolo, se cumulabile con altre offerte).
- Se non torni nel locale per **6 mesi**, i timbri si azzerano; se mancano da 1 a 3 timbri al
  premio, ti avvisiamo 15 giorni prima.
- Se il locale **smette** di offrire la tessera hai 30 giorni per completarla; i premi già
  sbloccati restano validi fino alla loro scadenza. Se la tessera del locale viene sospesa per le
  segnalazioni dei clienti, o il locale non è più su HAPOSTO, le tessere in corso finiscono e ti
  avvisiamo.
- **Tavoli di gruppo**: unisciti solo a un tavolo a cui sei presente. Il QR personale e quello del
  tavolo non si cedono e non si fotografano per usarli dopo.
- Puoi **segnalare** un locale che non ha voluto timbrare o non ti ha riconosciuto il premio:
  una segnalazione per locale ogni 90 giorni, solo dopo un timbro negli ultimi 60 giorni. Segnalare
  non dà vantaggi: usala solo in buona fede.
- In caso di abuso (per esempio QR usati da lontano o accordi per timbri falsi) HAPOSTO può
  sospendere l'account.
- HAPOSTO fornisce lo strumento: il premio e la sua consegna sono un'iniziativa del locale.
```

---

## 3. Condizioni per i ristoranti (`termini-ristoranti.md`)

### Sezione nuova «Tessera fedeltà»

```markdown
## Tessera fedeltà (piano Pro)

- La tessera è facoltativa e inclusa nel piano Pro. Si attiva accettando il **patto**, registrato
  con data, versione delle regole e account:
  1. timbro ogni cliente che rispetta la condizione e mostra il QR;
  2. riconosco i premi maturati entro la loro validità, alle condizioni dichiarate;
  3. se smetto, i clienti hanno 30 giorni per completare.
- Il **premio è un'iniziativa del locale**: costo, consegna e corretta registrazione fiscale di
  sconti e buoni sono a carico del locale. Il premio è sempre personale, non convertibile in
  denaro, senza alcolici, entro i limiti dell'app.
- Le regole pubblicate **non si modificano** per chi ha già iniziato: una nuova versione vale solo
  per i clienti che iniziano dopo.
- Il timbro si dà solo scansionando il QR del cliente presente o del suo tavolo (o con il codice di
  riserva): non esistono timbri a mano. «Annulla» serve solo per un errore, entro 2 minuti. Ci sono
  limiti automatici al numero di scansioni (per esempio 60 ogni 10 minuti e 300 al giorno).
- **Dati**: il locale vede solo codici anonimi e numeri. Non deve cercare di risalire all'identità
  dei clienti né chiedere dati personali per la tessera.
- **Chiusura**: il titolare può chiudere la tessera con 30 giorni di preavviso ai clienti. Se il
  piano Pro non viene rinnovato parte lo stesso preavviso; se il locale lascia HAPOSTO la tessera
  finisce subito.
- **Segnalazioni dei clienti** (solo clienti con un timbro negli ultimi 60 giorni, una ogni 90
  giorni): con 3 segnalazioni di clienti diversi in 60 giorni il titolare riceve un avviso; con 5
  la tessera si **sospende da sola per 90 giorni** e le tessere dei clienti finiscono; una seconda
  sospensione entro 12 mesi **toglie** la tessera, che solo HAPOSTO può ridare. Il locale resta
  comunque su HAPOSTO.
```

---

## 4. Domande per il professionista

1. Le righe sopra sono sufficienti per informativa e termini (trasparenza verso il consumatore)?
2. **Sconti e buoni**: come vanno indicati su scontrino o fattura del locale? Basta che il premio
   resti un'iniziativa del locale, come scritto?
3. La tessera, con premi offerti dal locale stesso (prodotti suoi, sconti sulla sua consumazione,
   buoni da usare da lui), rientra fra le esclusioni previste dalla disciplina delle manifestazioni
   a premio (D.P.R. 430/2001), oppure serve qualche adempimento?
4. Tempi di conservazione (§1) e basi giuridiche: vanno bene così?
5. Le soglie automatiche delle segnalazioni e la sospensione della sola tessera (mai del locale)
   sono compatibili con le condizioni per i ristoranti?
