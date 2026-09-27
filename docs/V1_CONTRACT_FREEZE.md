# HAPOSTO — V1 PRE-BACKEND CONTRACT FREEZE

**Freeze:** STEP 6  
**Scopo:** definire il comportamento Android che lo STEP 7 dovrà preservare quando il repository fake verrà sostituito da Supabase.

Questo freeze non significa che il prodotto non potrà più evolvere. Significa che, durante il primo collegamento backend, non cambiamo contemporaneamente UX, modelli e persistenza: prima rendiamo Supabase compatibile con il comportamento già validato localmente.

---

## 1. Regole disponibilità V1

Sorgente di verità nel codice:

```text
domain/model/AvailabilityRules.kt
```

Valori congelati:

```text
LIVE_TTL_MINUTES = 30
MAX_AVAILABLE_TABLES = 99
MAX_ESTIMATED_WAIT_MINUTES = 240
MAX_NOTE_LENGTH = 80
```

Regole:

- stati pubblicabili dal ristorante: `AVAILABLE`, `LIMITED`, `FULL`;
- `STALE` è derivato dal tempo, non pubblicato;
- `NOT_CONNECTED` è derivato dalla partnership, non pubblicato;
- `FULL` non espone `availableTables`;
- ogni publish rinnova `updatedAt` e `validUntil`;
- `validUntil = updatedAt + 30 minuti`;
- il toggle telefono pubblico non rinnova il TTL;
- un `DIRECTORY_ONLY` non può pubblicare LIVE.

---

## 2. Modelli V1

### Restaurant

```text
id: String
name: String
category: String
address: String
city: String
location: GeoPoint
distanceKm: Double?              // valore derivato per UI
partnershipStatus: PartnershipStatus
liveAvailability: LiveAvailability?
phoneNumber: String?
phonePublic: Boolean
```

### LiveAvailability

```text
status: AVAILABLE | LIMITED | FULL
updatedAt: Instant
validUntil: Instant
availableTables: Int?            // 0..99, null se FULL
estimatedWaitMinutes: Int?       // 0..240
note: String?                    // max 80
```

### AvailabilityStatus

```text
AVAILABLE
LIMITED
FULL
STALE
NOT_CONNECTED
```

### PartnershipStatus app V1

```text
ACTIVE_PARTNER
DIRECTORY_ONLY
```

Lo schema SQL può avere stati amministrativi più ricchi, ma l'adapter pubblico Android deve ricondurli a questi due concetti finché la UI V1 non cambia esplicitamente.

---

## 3. RestaurantRepository — firma congelata

```kotlin
interface RestaurantRepository {
    fun observeRestaurants(): Flow<List<Restaurant>>
    fun findById(id: String): Restaurant?

    suspend fun publishAvailability(
        restaurantId: String,
        status: AvailabilityStatus,
        availableTables: Int? = null,
        estimatedWaitMinutes: Int? = null,
        note: String? = null,
    ): Boolean

    suspend fun setPhonePublic(
        restaurantId: String,
        isPublic: Boolean,
    ): Boolean
}
```

Semantica necessaria per STEP 7:

- `observeRestaurants()` è la sorgente condivisa consumer/manager;
- `findById()` rappresenta lo snapshot locale più recente;
- un publish riuscito deve aggiornare lo snapshot osservabile;
- il client non deve poter pubblicare stati derivati;
- la sicurezza vera verrà imposta lato database/RPC/RLS.

---

## 4. RestaurantAccessRepository — firma congelata per la shell

```kotlin
interface RestaurantAccessRepository {
    fun observeState(): Flow<RestaurantAccessState>
    fun currentState(): RestaurantAccessState
    suspend fun signInWithDemoGoogle(): RestaurantDemoAccount
    suspend fun submitClaim(restaurantId: String, contactInfo: String): Boolean
    suspend fun approvePendingClaimForDemo(): Boolean
    suspend fun signOut()
    suspend fun resetDemo()
}
```

Nota importante:

`approvePendingClaimForDemo()` e `resetDemo()` sono poteri esclusivamente fake. Lo STEP 8 dovrà rimuoverli dall'implementazione production/client oppure separarli in tooling debug. Non devono mai diventare endpoint di autorizzazione client.

La semantica da preservare è invece:

```text
signed out
→ signed in
→ claim pending
→ claim approved
→ canManage(sameRestaurantId) == true
```

---

## 5. Posizione V1

- foreground only;
- `COARSE` + `FINE`;
- nessun background location;
- coordinate device RAM-only;
- coordinate device non in `SavedStateHandle`;
- fallback manuale sempre disponibile;
- Step 7 potrà usare PostGIS server-side, ma la UI continua a ricevere una distanza in km.

---

## 6. Consumer V1

Il consumer non richiede account per:

```text
Home
search
filtri
distanza
dettaglio
INDICAZIONI
CHIAMA se phonePublic
```

Non introdurre Auth consumer durante il wiring Supabase.

---

## 7. Criterio di modifica del freeze

Se durante STEP 7 emerge che una firma deve cambiare:

1. documentare il motivo;
2. aggiornare questo file;
3. aggiornare i test di contratto;
4. modificare fake e Supabase adapter insieme;
5. evitare modifiche silenziose soltanto nell'implementazione remota.

---

## 8. Nota implementativa STEP 7

Il primo adapter Supabase preserva la firma senza fingere che il claim demo abbia autorizzazioni reali:

```text
observeRestaurants / findById
→ Supabase reale quando configurato

publishAvailability / setPhonePublic
→ overlay RAM-only nello STEP 7
→ RPC autenticato reale nello STEP 9
```

La posizione device resta non persistita, ma con Supabase configurato viene trasmessa via HTTPS come parametro temporaneo di `nearby_restaurants(...)` per la query PostGIS. Non viene scritta nelle tabelle HAPOSTO.

Lo schema SQL STEP 7 è stato riallineato ai limiti congelati di questo documento.
