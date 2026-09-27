# HAPOSTO — STEP 6 Acceptance Checklist

Questa checklist è il gate pre-backend. I controlli automatici disponibili nell'ambiente di generazione sono accompagnati da una matrice manuale da eseguire in Android Studio/emulatore/device prima di iniziare il pilot reale.

---

## A. Consumer flow

- [x] Home avviabile senza account consumer.
- [x] fallback area manuale disponibile.
- [x] richiesta posizione solo dopo azione utente.
- [x] ricerca e filtri convivono con ordinamento per distanza.
- [x] `AVAILABLE / LIMITED / FULL / STALE / NOT_CONNECTED` risolti dalla stessa logica.
- [x] timestamp/freshness sempre parte dello stato.
- [x] detail osserva lo stesso repository della Home.
- [x] telefono visibile solo con `phonePublic=true`.
- [x] indicazioni delegate a intent esterno.
- [x] offline dichiarato senza fingere dati server aggiornati.

---

## B. Restaurant flow

- [x] entry point dalla Home.
- [x] login esplicitamente demo, non presentato come Google reale.
- [x] ricerca attività demo.
- [x] claim PENDING non abilita dashboard.
- [x] approvazione demo abilita soltanto lo stesso restaurant id.
- [x] dashboard protetta dalla guard locale.
- [x] tre stati one-tap.
- [x] nessun popup di conferma sul cambio stato.
- [x] dettagli facoltativi.
- [x] telefono pubblico separato dalla freshness.
- [x] logout revoca la guard client.
- [x] nessun potere demo descritto come sicurezza reale.

---

## C. Loop consumer ↔ manager

Test automatico:

```text
PreBackendDemoAcceptanceTest
```

Copre:

```text
consumer legge AVAILABLE
→ sign-in demo
→ claim PENDING
→ dashboard ancora bloccata
→ approvazione demo
→ canManage true
→ manager pubblica FULL
→ consumer repository legge FULL
→ TTL = 30 minuti
→ FULL non espone tavoli liberi
→ telefono OFF non modifica updatedAt
→ logout blocca manager
→ nuovo sign-in demo ripristina claim RAM
```

---

## D. Errori/robustezza

- [x] Home loading.
- [x] Home error + retry contract.
- [x] directory empty distinta da no matches.
- [x] offline banner.
- [x] permission rationale.
- [x] settings path per permission non richiedibile.
- [x] detail not-found.
- [x] manager access denied.
- [x] claim offline disclosure.
- [x] map/dialer intent failure visibile.

---

## E. Privacy pre-backend

- [x] nessuna chiave reale nel repository.
- [x] nessuna posizione background.
- [x] coordinate device non persistite.
- [x] recapito claim non persistito nel SavedState.
- [x] consumer senza account.
- [x] account/claim fake RAM-only.
- [x] nessun analytics consumer aggiunto.

---

## F. Form factor / device matrix da eseguire manualmente

L'ambiente di generazione non dispone di Android SDK/emulator farm, quindi questa sezione è **preparata ma non dichiarata come eseguita fisicamente**.

### Minimo consigliato prima di STEP 7

| Profilo | Android | Orientamento/finestra | Controllo |
|---|---:|---|---|
| telefono compact | API 26 | portrait | avvio, Home, detail, manager |
| telefono moderno | API 35+ | portrait | permission precise/approx |
| telefono moderno | API 35+ | landscape | layout e scrolling |
| tablet | API 35+ | large width | max width/adaptive |
| resize desktop/emulator | API 35+ | finestra ampia | centratura e leggibilità |

### Su almeno un device reale

- posizione negata una volta;
- posizione negata permanentemente / apertura Settings;
- posizione approssimativa;
- rete OFF durante Home;
- rete OFF durante dashboard;
- intent INDICAZIONI;
- intent CHIAMA.

---

## G. Gate Supabase

STEP 7 può iniziare quando:

1. il progetto esegue `Gradle Sync` e `Build > Make Project` in Android Studio;
2. i test JVM passano;
3. gli instrumentation test disponibili passano su almeno un emulatore;
4. la matrice manuale minima sopra non evidenzia blocker;
5. le migration SQL vengono riesaminate contro `V1_CONTRACT_FREEZE.md`.
