# 2026-10-02 — Ping anti-pausa dei progetti Supabase e piano delle migliorie

- **Data:** 2 ottobre 2026
- **Branch:** `claude/amazing-pasteur-dull9l`
- **PR:** [#17](https://github.com/paolomarchionetti-glitch/haposto/pull/17)
- **Motivo:** il titolare ha deciso di finire prima l'app sul progetto DEV (dati di prova e
  migliorie) e di creare la produzione (Parte 10) solo dopo. Ha chiesto un modo, nel codice, per
  evitare che Supabase metta in pausa i progetti del piano Free dopo 7 giorni senza attività, e di
  annotare le decisioni prese sul modello di pagamento e sulle migliorie.

## File modificati, aggiunti e rinominati

| File | Tipo |
|---|---|
| `.github/workflows/supabase-keepalive.yml` | aggiunto |
| `docs/HAPOSTO_GUIDA_CONFIGURAZIONE_COMPLETA.md` | modificato |
| `docs/HAPOSTO_STATO_CONFIGURAZIONE.md` | modificato |
| `docs/modifiche/2026-10-02_pr17-ping-anti-pausa-e-piano-migliorie.md` | aggiunto (questo file) |

## Dettaglio delle modifiche

- **`supabase-keepalive.yml`:** workflow GitHub Actions che ogni giorno (06:17 UTC, e a mano con
  *Run workflow*) legge un piano pubblico (`/rest/v1/plans?select=code&limit=1`) con la chiave
  *publishable* di ogni progetto configurato nei segreti del repository (`SUPABASE_DEV_URL`,
  `SUPABASE_DEV_PUBLISHABLE_KEY`, e più avanti `SUPABASE_PROD_…`). Nessun dato personale, nessuna
  scrittura, nessun permesso del token GitHub (`permissions: {}`). Un progetto senza segreti viene
  saltato; tre tentativi per progetto; se la lettura non riesce il workflow diventa rosso (GitHub
  manda un'email). Gratis per i repository pubblici.
- **Guida:** nuovo punto **6.4** (segreti da aggiungere, prova con *Run workflow*, cosa fare se
  diventa rosso, limite dei 60 giorni di GitHub, natura non ufficiale del metodo); il punto 10.10
  rimanda al 6.4 per la produzione.
- **Stato:** Parte 10 **in sospeso** per decisione del titolare; nella Parte 6 il 6.4 da fare;
  decisioni sull'ordine dei lavori e sul modello di pagamento (prezzi provvisori IVA inclusa: Pro
  19,90 € al mese, 99,90 € per 6 mesi, 199,90 € l'anno; Plus 0,99 €, 4,99 €, 9,99 €; prova di 30
  giorni modificabile dal pannello admin; chi non paga torna "Non collegato"); nuova sezione **3 bis**
  con le migliorie in programma, in ordine; messaggio di ripresa aggiornato.

## Verifiche

- Script del workflow eseguito in locale, estratto dal file YAML, contro un finto server Supabase:
  progetto configurato e raggiungibile → `DEV: ok`, uscita 0; progetto con chiave sbagliata → tre
  tentativi, errore, uscita 1; nessun progetto configurato → avviso, uscita 0; server irraggiungibile
  → tre tentativi con HTTP 000, uscita 1.
- Controllato nel database che la lettura usata sia permessa al ruolo `anon` (grant e policy
  `plans_public_read` della migration 0008).
- Nessun segreto, email personale o identificativo di progetto nei file.
