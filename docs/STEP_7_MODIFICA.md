# STEP 7 — Modifiche introdotte

## Obiettivo

Attivare il primo backend reale senza saltare direttamente a Auth/Realtime.

## Implementato

- Supabase PostgREST reale per directory consumer;
- `SupabaseRestaurantRepository`;
- PostGIS RPC `nearby_restaurants`;
- 60 km DEV radius;
- mapping DTO → domain;
- `SUPABASE DEV` badge;
- fallback fake quando non configurato;
- errore esplicito per config parziale/errata;
- `local.properties.example`;
- publishable-key-only validator;
- RLS/grants riallineati alle linee guida attuali;
- schema database riallineato al V1 contract freeze;
- category nel database;
- query fuzzy server-side predisposta;
- campi LIVE esposti dal RPC soltanto per `ACTIVE_PARTNER`;
- raggio RPC normalizzato e limitato a massimo 100 km;
- seed fittizio completo;
- SQL smoke read-only;
- copy privacy posizione corretto: invio RPC senza persistenza;
- manager Step 7 mantenuto RAM-only;
- Auth ancora demo;
- Realtime ancora OFF.

## Compatibilità AGP 9 / Kotlin

AGP 9 usa Kotlin integrato. Il build root aggiunge esplicitamente `org.jetbrains.kotlin:kotlin-gradle-plugin:2.4.10` al build classpath, in modo che il compilatore Kotlin usato da AGP resti allineato ai plugin Compose e Serialization 2.4.10. Non viene applicato `org.jetbrains.kotlin.android`.

## Dipendenze runtime Step 7

Attive:

```text
postgrest-kt
ktor-client-okhttp
```

Auth e Realtime restano dichiarabili nel version catalog ma non sono dipendenze runtime del modulo app nello Step 7.

## Contratto V1

`RestaurantRepository` non è stato cambiato.

Il backend adapter rispetta lo stesso boundary congelato nello Step 6.

La parte write del contratto rimane local overlay nello Step 7 e verrà collegata all'RPC autenticato nello Step 9.

## Hardening aggiuntivo del confine pubblico

Lo STEP 7 non si limita a "mettere RLS". La funzione pubblica `nearby_restaurants` normalizza il raggio richiesto a `0..100000` metri, non espone campi LIVE per ristoranti non `ACTIVE_PARTNER` e la policy diretta su `restaurant_live_status` permette lettura client soltanto quando il ristorante padre è partner attivo.

Queste regole riducono la superficie pubblica prima ancora di introdurre Auth nello STEP 8.
