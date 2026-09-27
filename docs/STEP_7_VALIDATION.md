# STEP 7 — Validazione eseguita nell'ambiente di generazione

## Verificato

- ZIP sorgente Step 6 SHA-256 corretto;
- version bump Step 7;
- AGP 9 built-in Kotlin mantenuto; KGP 2.4.10 aggiunto esplicitamente al build classpath per allineare Compose/Serialization;
- SQL order 0001→0004;
- 0005 ancora marcato Step 10 only;
- vincoli V1 presenti lato SQL;
- RLS abilitato da migration;
- revoke + grant espliciti;
- nessuna secret/service_role/password in source;
- validator Android accetta solo `sb_publishable_...`;
- no background location;
- posizione non persistita;
- Supabase provider installa solo Postgrest nello Step 7;
- manager writes documentati RAM-only;
- seed fittizio;
- smoke SQL read-only incluso;
- XML/TOML/static checks;
- pure Kotlin/domain checks dove eseguibili;
- adapter Supabase/PostgREST compilato staticamente contro stub compatibili: `STEP7_SUPABASE_STUB_COMPILE_OK`;
- mapping RPC DTO → domain smoke-testato: `STEP7_REMOTE_MAPPING_SMOKE_OK`;
- policy LIVE pubblica limitata ai soli `ACTIVE_PARTNER`;
- RPC geo limitato a massimo 100 km;
- ZIP CRC finale.

## Non verificabile qui

L'ambiente di generazione non dispone di:

- Android SDK completo;
- emulator/device;
- accesso al tuo progetto Supabase;
- credenziali client;
- Gradle 9.5 installato;
- official `gradle-wrapper.jar` recuperabile dalla rete.

Quindi non viene dichiarato come eseguito:

```text
Gradle Sync reale
assembleDebug reale
unit test Gradle reale
connectedDebugAndroidTest
RPC contro il tuo progetto Supabase
```

Questi controlli sono intenzionalmente spostati sul tuo PC seguendo `STEP_7_BUILD_AND_TEST.md`, in modo che gli errori reali possano essere raccolti e corretti nel passo successivo.
