# HAPOSTO — STEP 5 MODIFICA

**Data:** 24 agosto 2026  
**Versione Android:** `0.5.0-step5`  
**Obiettivo:** consolidare il prototipo Android locale prima della demo finale pre-backend.

---

# 1. Scope

STEP 5 non aggiunge business feature nuove.

Aggiunge robustezza a ciò che esiste già:

- loading;
- empty;
- error;
- offline;
- permission rationale;
- app settings path;
- accessibilità;
- layout adattivo;
- state restoration;
- UI test;
- back stack review;
- copy audit;
- permission audit.

Supabase resta OFF.

---

# 2. Home state model

`HomeUiState` ora include:

```text
isInitialLoading
errorMessage
isOnline
totalRestaurantCount
emptyReason
```

`emptyReason` distingue:

```text
DIRECTORY_EMPTY
NO_MATCHES
```

Quindi una directory senza dati non viene comunicata come se fosse semplicemente una ricerca sbagliata.

---

# 3. Loading e error handling

`HomeViewModel` avvolge il repository flow con:

```text
onStart → Loading
map → Content
catch → Error
```

È stato aggiunto anche un retry trigger che forza una nuova sottoscrizione alla sorgente.

Il fake repository normalmente non genera errori, ma la UI è già pronta per il futuro repository Supabase.

---

# 4. Offline monitor

Nuovi file:

```text
data/network/NetworkMonitor.kt
data/network/AndroidNetworkMonitor.kt
```

L'implementazione Android usa:

```text
ConnectivityManager
NetworkCapabilities.NET_CAPABILITY_INTERNET
NetworkCapabilities.NET_CAPABILITY_VALIDATED
```

Nuovo permesso normale:

```xml
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

Non vengono effettuate richieste di rete.

La Home mostra un banner offline senza nascondere i dati demo.

La dashboard ristoratore specifica che l'update locale in RAM non equivale a una sincronizzazione server reale.

---

# 5. Permission rationale

Il prompt posizione resta user-driven.

Nuovi stati:

```text
RATIONALE_REQUIRED
PERMISSION_DENIED
PERMISSION_DENIED_PERMANENT
SERVICES_DISABLED
UNAVAILABLE
```

Se Android consiglia un rationale:

```text
rationale HAPOSTO
↓
CONTINUA
↓
prompt Android
```

Se il prompt non può più essere riproposto automaticamente:

```text
APRI IMPOSTAZIONI APP
```

tramite:

```text
Settings.ACTION_APPLICATION_DETAILS_SETTINGS
```

---

# 6. State restoration

Sono stati convertiti i factory principali all'approccio:

```text
viewModelFactory
initializer
createSavedStateHandle()
```

## Home

Salva:

```text
search query
filter
manual area
```

Non salva coordinate device.

## Access/claim

Salva:

```text
search query
selected restaurant id
```

Account e claim restano RAM-only.

## Manager

Salva draft UI:

```text
available tables
wait minutes
note
```

Lo stato LIVE resta RAM-only.

---

# 7. Responsive/adaptive

Nuovo componente:

```text
AdaptiveScrollableContent.kt
```

Usa `BoxWithConstraints` e `widthIn` per mantenere contenuti centrati e leggibili su finestre ampie.

Applicato a:

- access/claim;
- manager dashboard;
- restaurant detail.

La Home applica direttamente la stessa strategia alla `LazyColumn`.

---

# 8. Accessibilità

Aggiornamenti:

- restaurant card con semantica aggregata;
- stato pronunciabile come testo;
- distanza e freshness incluse nella descrizione della card;
- heading semantico sulla domanda principale;
- badge `DEMO` e `PARTNER DEMO` non più componenti cliccabili vuoti;
- componenti Material per mantenere touch target standard;
- error/offline copy non dipendente dal solo colore.

---

# 9. External actions

`ExternalActions` ora restituisce `Boolean`.

Il dettaglio ristorante può quindi mostrare errori se il sistema non trova:

- app mappe;
- dialer.

Aggiunto:

```text
openAppSettings()
```

per il permission settings path.

---

# 10. Back stack

Dashboard:

```text
launchSingleTop = true
popUpTo(RESTAURANT_ACCESS) { inclusive = false }
```

Il ritorno dalla guard all'area accesso evita duplicati inutili.

La guard continua a verificare:

```text
account != null
claim.status == APPROVED
claim.restaurantId == requested restaurantId
```

---

# 11. UI test

Aggiunte dipendenze Compose test tramite BOM:

```text
ui-test-junit4
ui-test-manifest
```

Nuovi androidTest:

```text
HomeScreenTest.kt
RestaurantManagerAccessDeniedScreenTest.kt
```

Coprono:

- loading;
- filtered empty;
- offline banner;
- access guard copy.

---

# 12. Permessi finali Step 5

Presenti:

```text
INTERNET
ACCESS_NETWORK_STATE
ACCESS_COARSE_LOCATION
ACCESS_FINE_LOCATION
```

Assente:

```text
ACCESS_BACKGROUND_LOCATION
```

Non sono stati aggiunti camera, storage, contatti, notifiche o altri permessi.

---

# 13. File principali aggiunti

```text
app/src/main/java/it/haposto/app/data/network/NetworkMonitor.kt
app/src/main/java/it/haposto/app/data/network/AndroidNetworkMonitor.kt
app/src/main/java/it/haposto/app/ui/components/AppStatePanel.kt
app/src/main/java/it/haposto/app/ui/components/AdaptiveScrollableContent.kt
app/src/androidTest/java/it/haposto/app/ui/screens/home/HomeScreenTest.kt
app/src/androidTest/java/it/haposto/app/ui/screens/restaurant/RestaurantManagerAccessDeniedScreenTest.kt
```

Modificati tra gli altri:

```text
AndroidManifest.xml
AppDependencies.kt
HaPostoApp.kt
HomeUiState.kt
HomeViewModel.kt
HomeRoute.kt
HomeScreen.kt
RestaurantAccessViewModel.kt
RestaurantAccessScreen.kt
RestaurantManagerViewModel.kt
RestaurantManagerRoute.kt
RestaurantManagerScreen.kt
RestaurantDetailScreen.kt
RestaurantCard.kt
ExternalActions.kt
app/build.gradle.kts
gradle/libs.versions.toml
```

---

# 14. Supabase

Ancora OFF.

Le migration SQL non vengono eseguite né modificate.

---

# 15. Step successivo

## STEP 6 — Demo completa pre-backend

Obiettivo:

- percorrere consumer end-to-end;
- percorrere ristoratore end-to-end;
- acceptance checklist;
- test manuale su più classi di device;
- freeze modelli V1;
- revisione finale SQL contro i modelli congelati;
- gate definitivo prima di Supabase.
