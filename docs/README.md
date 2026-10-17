# HAPOSTO — Indice dei documenti

Tutti i documenti del progetto, divisi per tema. Il nome di ogni file comincia con la **data
dell'ultimo aggiornamento** (`AAAA-MM-GG_NOME.md`): quando un documento cambia, cambia anche la
data nel nome; aggiornare solo i rimandi a un altro documento non la cambia (regole in `CLAUDE.md`). Questo indice ha un nome fisso e si aggiorna insieme ai
documenti; la CI controlla che ogni documento sia elencato qui e che i riferimenti funzionino.

## Da dove partire

1. [Stato della configurazione](configurazione/2026-10-17_HAPOSTO_STATO_CONFIGURAZIONE.md) —
   dove siamo arrivati e come si riprende.
2. [Guida di configurazione completa](configurazione/2026-10-12_HAPOSTO_GUIDA_CONFIGURAZIONE_COMPLETA.md) —
   tutte le operazioni, in ordine.
3. [Roadmap da qui al lancio](roadmap/2026-10-12_HAPOSTO_ROADMAP_DA_QUI_AL_LANCIO.md) — il
   percorso da seguire ora.
4. [`modifiche/`](modifiche/) — registro di tutte le modifiche (più recenti in fondo).

## `configurazione/` — configurazione e database

| Documento | Contenuto |
|---|---|
| [2026-10-17_HAPOSTO_STATO_CONFIGURAZIONE.md](configurazione/2026-10-17_HAPOSTO_STATO_CONFIGURAZIONE.md) | **punto di ripresa**: parti della guida fatte, decisioni, cose aperte, messaggio per una nuova sessione |
| [2026-10-12_HAPOSTO_GUIDA_CONFIGURAZIONE_COMPLETA.md](configurazione/2026-10-12_HAPOSTO_GUIDA_CONFIGURAZIONE_COMPLETA.md) | tutte le operazioni dal codice al lancio (Parti 1–12): migration, login Google e 2FA, Firebase, Edge Function, Play, Stripe, sito, produzione |
| [2026-09-29_HAPOSTO_GUIDA_AGGIORNAMENTO_DB.md](configurazione/2026-09-29_HAPOSTO_GUIDA_AGGIORNAMENTO_DB.md) | aggiornare Supabase con le migration 0006–0011, passo per passo |
| [2026-09-29_HAPOSTO_SQL_INTEGRATIVO.md](configurazione/2026-09-29_HAPOSTO_SQL_INTEGRATIVO.md) | tabelle, funzioni e permessi del database completo |

## `guide/` — guide d'uso e di prova

| Documento | Contenuto |
|---|---|
| [2026-10-05_HAPOSTO_GUIDA_APP_E_DATI_REALI.md](guide/2026-10-05_HAPOSTO_GUIDA_APP_E_DATI_REALI.md) | cosa è reale e cosa simulato, import dei locali da OpenStreetMap, prove sul campo, pilot |
| [2026-10-03_HAPOSTO_GUIDA_APP_TUTORIAL.md](guide/2026-10-03_HAPOSTO_GUIDA_APP_TUTORIAL.md) | come si usa l'app, per utenti e ristoratori |
| [2026-09-29_HAPOSTO_GUIDA_TEST_PSEUDOREALISTICO.md](guide/2026-09-29_HAPOSTO_GUIDA_TEST_PSEUDOREALISTICO.md) | provare l'app con 36 locali che cambiano da soli, anche con due telefoni |
| [2026-09-27_MD1_GUIDA_BUILD_E_SUPABASE.md](guide/2026-09-27_MD1_GUIDA_BUILD_E_SUPABASE.md) | guida a build e Supabase dei primi step (settembre 2026: dalla cartella estratta all'app collegata al DEV) |
| [2026-09-27_MD3_HAPOSTO_SPIEGATO_SEMPLICE.md](guide/2026-09-27_MD3_HAPOSTO_SPIEGATO_SEMPLICE.md) | il progetto spiegato in parole semplici |
| [2026-09-27_ICONA_GUIDA.md](guide/2026-09-27_ICONA_GUIDA.md) | l'icona dell'app (adaptive icon): dove sono i file e come cambiarla |

## `roadmap/` — percorso e piani

| Documento | Contenuto |
|---|---|
| [2026-10-12_HAPOSTO_ROADMAP_DA_QUI_AL_LANCIO.md](roadmap/2026-10-12_HAPOSTO_ROADMAP_DA_QUI_AL_LANCIO.md) | **il percorso da seguire ora**: tappe dalla prova sul campo al lancio e alla gestione, con chi fa cosa, costi e durate |
| [2026-10-05_HAPOSTO_ROADMAP_COMPLETA.md](roadmap/2026-10-05_HAPOSTO_ROADMAP_COMPLETA.md) | archivio delle scelte e dei dettagli (fasi, decisioni, scheda dei trattamenti per la privacy) |
| [2026-09-27_HAPOSTO_ROADMAP_INTEGRATIVA.md](roadmap/2026-09-27_HAPOSTO_ROADMAP_INTEGRATIVA.md) | cosa ha aggiunto lo Step 7.9 |
| [2026-09-27_HAPOSTO_ROADMAP_PRENOTAZIONI_E_UX.md](roadmap/2026-09-27_HAPOSTO_ROADMAP_PRENOTAZIONI_E_UX.md) | roadmap ragionata: prenotazioni, informazioni del locale e UX |
| [2026-09-27_HAPOSTO_ROADMAP_TOP_FREEMIUM.md](roadmap/2026-09-27_HAPOSTO_ROADMAP_TOP_FREEMIUM.md) | riposizionamento «top di gamma e vendibile» |
| [2026-09-27_ROADMAP.md](roadmap/2026-09-27_ROADMAP.md) | roadmap degli step 0–10 (settembre 2026) |

## `progetto/` — architettura e modello

| Documento | Contenuto |
|---|---|
| [2026-10-03_HAPOSTO_MODELLO_PREMIUM_E_ACCOUNT.md](progetto/2026-10-03_HAPOSTO_MODELLO_PREMIUM_E_ACCOUNT.md) | piani Pro (prova, poi «Non collegato») e Gratis/Plus, registrazione, acquisti |
| [2026-09-27_ARCHITECTURE.md](progetto/2026-09-27_ARCHITECTURE.md) | architettura dell'app Android (Step 7) |
| [2026-09-27_V1_CONTRACT_FREEZE.md](progetto/2026-09-27_V1_CONTRACT_FREEZE.md) | comportamento dell'app da preservare nel collegamento a Supabase (regole di disponibilità e modelli della versione 1) |

## `PR/` — documenti di una serie di PR

Una cartella per ogni serie di PR che ha i suoi documenti (progetto, specifiche, collaudo): il nome
dice i numeri delle PR e il tema (`PRxx-yy_tema`).

### [`PR22-30_tessera-fedelta/`](PR/PR22-30_tessera-fedelta/) — tessera fedeltà (PR #22–#30)

| Documento | Contenuto |
|---|---|
| [2026-10-11_HAPOSTO_PROGETTO_VISITE_E_TESSERA.md](PR/PR22-30_tessera-fedelta/2026-10-11_HAPOSTO_PROGETTO_VISITE_E_TESSERA.md) | motivazioni: pro e contro, confronto con il documento di partenza (PR #22) |
| [2026-10-12_HAPOSTO_TESSERA_SPECIFICHE.md](PR/PR22-30_tessera-fedelta/2026-10-12_HAPOSTO_TESSERA_SPECIFICHE.md) | **specifiche** (versione 3, regole T1–T61): patto, QR e antifrode, privacy, sanzioni, struttura tecnica, piano A–E (PR #23–#29) |
| [2026-10-12_HAPOSTO_TESSERA_TESTI_LEGALI.md](PR/PR22-30_tessera-fedelta/2026-10-12_HAPOSTO_TESSERA_TESTI_LEGALI.md) | righe per privacy e termini, da inserire solo al lancio, con le domande per il professionista (PR #29) |
| [2026-10-12_HAPOSTO_TESSERA_COLLAUDO.md](PR/PR22-30_tessera-fedelta/2026-10-12_HAPOSTO_TESSERA_COLLAUDO.md) | **collaudo completo sul DEV con un solo telefono** (Parti A–Q e appendice con l'emulatore) (PR #29–#30) |

## `step/` — storico degli step di sviluppo (settembre 2026)

Una cartella per step, con le modifiche fatte e le verifiche di quel passo. Sono documenti
storici: per lo stato attuale valgono quelli di `configurazione/` e `roadmap/`.

| Step | Documenti |
|---|---|
| [`STEP_0/`](step/STEP_0/) | [modifica](step/STEP_0/2026-09-27_STEP_0_MODIFICA.md) — fondazione del progetto |
| [`STEP_1/`](step/STEP_1/) | [modifica](step/STEP_1/2026-09-27_STEP_1_MODIFICA.md), [verifica](step/STEP_1/2026-09-27_STEP_1_VALIDATION.md) |
| [`STEP_2/`](step/STEP_2/) | [modifica](step/STEP_2/2026-09-27_STEP_2_MODIFICA.md), [verifica](step/STEP_2/2026-09-27_STEP_2_VALIDATION.md) |
| [`STEP_3/`](step/STEP_3/) | [modifica](step/STEP_3/2026-09-27_STEP_3_MODIFICA.md), [verifica](step/STEP_3/2026-09-27_STEP_3_VALIDATION.md) |
| [`STEP_4/`](step/STEP_4/) | [modifica](step/STEP_4/2026-09-27_STEP_4_MODIFICA.md), [verifica](step/STEP_4/2026-09-27_STEP_4_VALIDATION.md) |
| [`STEP_5/`](step/STEP_5/) | [modifica](step/STEP_5/2026-09-27_STEP_5_MODIFICA.md), [verifica](step/STEP_5/2026-09-27_STEP_5_VALIDATION.md) |
| [`STEP_6/`](step/STEP_6/) | [modifica](step/STEP_6/2026-09-27_STEP_6_MODIFICA.md), [verifica](step/STEP_6/2026-09-27_STEP_6_VALIDATION.md), [collaudo](step/STEP_6/2026-09-27_STEP_6_ACCEPTANCE.md) |
| [`STEP_7/`](step/STEP_7/) | [modifica](step/STEP_7/2026-09-27_STEP_7_MODIFICA.md), [verifica](step/STEP_7/2026-09-27_STEP_7_VALIDATION.md), [setup Supabase DEV](step/STEP_7/2026-09-27_STEP_7_SETUP_SUPABASE.md), [build e test](step/STEP_7/2026-09-27_STEP_7_BUILD_AND_TEST.md), [problemi frequenti](step/STEP_7/2026-09-27_STEP_7_TROUBLESHOOTING.md) |
| [`STEP_7_5/`](step/STEP_7_5/) | [«Veste da top di gamma»](step/STEP_7_5/2026-09-27_MD2_MODIFICA_STEP_7_5.md) |
| [`STEP_7_6/`](step/STEP_7_6/) | [«Interfaccia essenziale»](step/STEP_7_6/2026-09-27_HAPOSTO_STEP_7_6_INTERFACCIA.md) |
| [`STEP_7_7/`](step/STEP_7_7/) | [correzioni della build e prenotazioni di sala](step/STEP_7_7/2026-09-27_HAPOSTO_STEP_7_7_PRENOTAZIONI.md) |
| [`STEP_7_8/`](step/STEP_7_8/) | [rifinitura visiva, guida di prova e Supabase](step/STEP_7_8/2026-09-27_HAPOSTO_STEP_7_8_INTERFACCIA.md) |

## Cartelle e file con regole proprie

- [`modifiche/`](modifiche/) — registro delle modifiche: un file per PR, `AAAA-MM-GG_prNN-titolo-breve.md`.
  I file del registro **non si modificano** dopo l'unione della loro PR: citano i nomi dei
  documenti di allora.
- [`reference/`](reference/) — analisi di partenza del progetto, nomi originali.
- [`POPPINS_OFL.txt`](POPPINS_OFL.txt) — licenza del font Poppins (non è un documento).
