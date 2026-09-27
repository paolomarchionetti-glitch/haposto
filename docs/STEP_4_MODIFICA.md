# HAPOSTO — STEP 4 MODIFICA

**Data:** 24 agosto 2026  
**Versione Android:** `0.4.0-step4`  
**Obiettivo:** costruire il percorso ristoratore di identità + claim + verifica prima della dashboard, senza attivare alcun backend.

---

# 1. Perché esiste questo step

Negli Step 1–3 la dashboard ristoratore era raggiungibile direttamente tramite il pulsante `Sei un ristoratore?`.

Era utile per validare il gesto operativo, ma non rappresentava il flusso reale previsto dal progetto.

La Parte 2 definisce invece:

```text
Login Google
↓
Richiesta gestione ristorante
↓
Controllo amministratore
↓
Account collegato al locale
↓
Dashboard
```

STEP 4 implementa questa UX in locale mantenendo Auth, claim e approvazione completamente fittizi.

---

# 2. Vincolo principale

Non deve sembrare che il prototipo autentichi davvero una persona.

Per questo:

- il bottone Google riporta esplicitamente `DEMO LOCALE`;
- non viene caricato alcun SDK Google;
- non viene eseguito OAuth;
- non viene prodotto alcun token;
- l'identità è `Titolare Demo`;
- l'email usa il dominio `.invalid`;
- il claim vive solo in RAM;
- l'approvazione admin è un comando chiaramente marcato come simulazione.

---

# 3. Nuovo domain model

Aggiunto:

```text
domain/model/RestaurantAccessState.kt
```

Contiene:

```text
RestaurantDemoAccount
RestaurantClaimStatus
RestaurantClaim
RestaurantAccessState
```

Stati claim locali persistibili nel prototipo:

```text
PENDING
APPROVED
```

L'autorizzazione manager è derivata da:

```text
account != null
AND claim.restaurantId == requestedRestaurantId
AND claim.status == APPROVED
```

---

# 4. Nuovo repository boundary

Aggiunto:

```text
data/repository/RestaurantAccessRepository.kt
```

Contratto:

```text
observeState()
currentState()
signInWithDemoGoogle()
submitClaim()
approvePendingClaimForDemo()
signOut()
resetDemo()
```

La futura implementazione Supabase potrà sostituire la fake mantenendo invariato il flusso Compose.

## Importante

`approvePendingClaimForDemo()` è intenzionalmente una capacità **solo prototipo**.

Non deve mai diventare un endpoint o un potere del client di produzione.

L'approvazione reale sarà amministrativa/server-side.

---

# 5. FakeRestaurantAccessRepository

Aggiunto:

```text
data/fake/FakeRestaurantAccessRepository.kt
```

Comportamento:

1. parte signed-out;
2. crea un'identità demo in RAM;
3. accetta un claim soltanto per un partner demo esistente;
4. crea `PENDING`;
5. non autorizza la dashboard durante `PENDING`;
6. la simulazione admin passa il claim ad `APPROVED`;
7. autorizza esclusivamente il restaurant id del claim;
8. `signOut()` rimuove la sessione ma mantiene il claim RAM-only per simulare un recupero sessione;
9. `resetDemo()` cancella tutto.

I locali `DIRECTORY_ONLY` non sono claimable in questa shell locale. Il backend reale dovrà supportarne onboarding + attivazione dopo verifica.

---

# 6. Nuova UI area ristoratore

Nuova cartella:

```text
ui/screens/access/
```

File:

```text
RestaurantAccessUiState.kt
RestaurantAccessViewModel.kt
RestaurantAccessRoute.kt
RestaurantAccessScreen.kt
```

Fasi:

```text
SIGNED_OUT
SEARCH
CLAIM_FORM
PENDING
APPROVED
```

## SIGNED_OUT

Mostra:

- spiegazione area ristoratore;
- bottone `CONTINUA CON GOOGLE · DEMO LOCALE`;
- disclosure che non viene eseguito alcun login reale.

## SEARCH

Mostra:

- identità demo;
- search per nome/città/categoria;
- partner demo collegati;
- CTA `QUESTO È IL MIO LOCALE`.

## CLAIM_FORM

Mostra:

- locale selezionato;
- recapito verifica;
- copy sul controllo manuale;
- invio richiesta demo.

## PENDING

Mostra:

- `RICHIESTA IN VERIFICA`;
- locale;
- recapito;
- spiegazione della verifica reale;
- `SIMULA APPROVAZIONE ADMIN` solamente per test.

## APPROVED

Mostra:

- `GESTIONE ABILITATA`;
- locale;
- ruolo demo OWNER;
- timestamp approvazione demo;
- CTA dashboard;
- logout/reset.

---

# 7. Access guard dashboard

`RestaurantManagerRoute` ora riceve anche:

```text
RestaurantAccessRepository
```

Prima di creare il manager ViewModel verifica `canManage(restaurantId)`.

Se false:

```text
RestaurantManagerAccessDeniedScreen
```

Se true:

```text
RestaurantManagerScreen
```

Questa scelta evita che la UI sviluppi la cattiva abitudine di considerare il restaurant id della route come autorizzazione sufficiente.

Resta comunque una guardia client e **non è sicurezza reale**.

---

# 8. Navigazione aggiornata

Aggiunta destinazione:

```text
restaurant-access
```

Nuovo flusso:

```text
HOME
↓
RESTAURANT_ACCESS
↓
RESTAURANT_MANAGER/{restaurantId}
```

Il dettaglio consumer resta separato.

---

# 9. Disclosure beta

L'area ristoratore riporta:

> HAPOSTO sarà gratuito durante la fase beta. Il servizio LIVE per i ristoranti potrà diventare a pagamento al termine della beta. Nessun costo verrà applicato automaticamente senza accettazione.

Questo mantiene la promessa commerciale definita nella Parte 2 senza implementare billing.

---

# 10. Consumer invariato

Non è stato introdotto alcun account consumer.

La Home continua ad aprirsi senza login.

Posizione, search, filtri, detail e call/map intent restano disponibili direttamente.

---

# 11. Supabase

Ancora completamente OFF.

Non eseguire migration.

Non configurare Auth.

Non configurare Google OAuth.

Non aggiungere chiavi.

L'attivazione rimane allo STEP 7.

---

# 12. File principali aggiunti

```text
app/src/main/java/it/haposto/app/domain/model/RestaurantAccessState.kt
app/src/main/java/it/haposto/app/data/repository/RestaurantAccessRepository.kt
app/src/main/java/it/haposto/app/data/fake/FakeRestaurantAccessRepository.kt
app/src/main/java/it/haposto/app/ui/screens/access/RestaurantAccessUiState.kt
app/src/main/java/it/haposto/app/ui/screens/access/RestaurantAccessViewModel.kt
app/src/main/java/it/haposto/app/ui/screens/access/RestaurantAccessRoute.kt
app/src/main/java/it/haposto/app/ui/screens/access/RestaurantAccessScreen.kt
app/src/main/java/it/haposto/app/ui/screens/restaurant/RestaurantManagerAccessDeniedScreen.kt
app/src/test/java/it/haposto/app/data/fake/FakeRestaurantAccessRepositoryTest.kt
```

Modificati:

```text
AppDependencies.kt
HaPostoApp.kt
AppDestination.kt
RestaurantManagerRoute.kt
app/build.gradle.kts
README.md
docs/ARCHITECTURE.md
docs/ROADMAP.md
supabase/README.md
```

---

# 13. Step successivo preannunciato

## STEP 5 — Robustezza Android locale

Prima del backend verranno consolidati:

- loading;
- empty state;
- error state;
- offline copy;
- permission rationale/settings;
- accessibilità;
- layout responsive/adaptive;
- state restoration dove utile;
- UI test principali;
- revisione copy;
- controllo permessi.

Supabase resterà ancora OFF.
