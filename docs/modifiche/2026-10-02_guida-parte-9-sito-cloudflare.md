# 2026-10-02 — Guida di configurazione, Parte 9: sito su Cloudflare Pages

- **Data:** 2 ottobre 2026
- **Branch:** `claude/haposto-setup-guide-8a512c`
- **PR:** [#14](https://github.com/paolomarchionetti-glitch/haposto/pull/14)
- **Motivo:** la Parte 9 è stata provata passo passo pubblicando il sito su Cloudflare Pages
  (`haposto-test.pages.dev`, progetto Supabase DEV); la guida è stata riscritta con i passi reali.

## File modificati e aggiunti

| File | Tipo |
|---|---|
| `docs/HAPOSTO_GUIDA_CONFIGURAZIONE_COMPLETA.md` | modificato |
| `docs/modifiche/2026-10-02_guida-parte-9-sito-cloudflare.md` | aggiunto (questo file) |

## Dettaglio delle modifiche

### `docs/HAPOSTO_GUIDA_CONFIGURAZIONE_COMPLETA.md` — Parte 9 (riscritta)

- **Perché Cloudflare e non GitHub Pages:** il sito va servito alla radice di un indirizzo (link,
  pagine `/r/…` dei QR e ritorno dal login con Google partono da `/`). Su GitHub Pages senza dominio
  proprio finirebbe in `utente.github.io/haposto/` e grafica, QR e login non funzionerebbero.
  Verificato con una build di prova: i collegamenti restano `/assets/…` e la pagina dei QR riconosce
  solo `/r/…` alla radice.
- **Nuovo 9.1 — Account Cloudflare:** registrazione gratuita (piano Free, senza carta); con accesso
  tramite Google non esiste una password Cloudflare, quindi la protezione è la verifica in due
  passaggi dell'account Google.
- **Nuovo 9.2 — Progetto Pages:** scheda *Pages* (la pagina propone prima i *Workers*), app GitHub
  limitata al solo repository `haposto`, tabella delle impostazioni di build, variabili con
  `NODE_VERSION=22` e progetto **DEV** finché non esiste la produzione, controllo dell'indirizzo
  assegnato, anteprime dei branch facoltativamente disattivate (*Preview branch: None*).
- **Nuovo 9.3 — Controllo:** home, pagine legali e pagina di un locale `/r/SLUG` con la query per
  trovare gli slug.
- **Nuovo 9.4 — Collegamenti:** URL Configuration di Supabase, Branding di Google (link diretto e
  nomi dei campi in italiano), segreti `HAPOSTO_SITE_URL` / `HAPOSTO_ALLOWED_ORIGINS` delle Edge
  Function, `PUBLIC_SITE_URL` dell'app. Completa i punti rimasti in sospeso nelle Parti 2.1 e 2.4.
- **Nuovo 9.5 — Prove:** login sul sito con l'account giusto (finestra in incognito se il browser è
  collegato all'account admin), messaggi di Google da aspettarsi ("Continua su `….supabase.co`",
  "app non verificata", "accesso bloccato" se l'account non è tra i Test users), dati di
  fatturazione di prova, QR e link del locale dall'app anche con un solo telefono.
- **Dominio definitivo:** come aggiungerlo più avanti (*Custom domains*) e cosa aggiornare.
- GitHub Pages non è più presentato come alternativa equivalente: resta indicato solo con un
  dominio proprio.

### `docs/HAPOSTO_GUIDA_CONFIGURAZIONE_COMPLETA.md` — Parte 10, punto 7

- Aggiunto il passaggio del sito alla produzione: variabili `HAPOSTO_SUPABASE_URL` e
  `HAPOSTO_SUPABASE_PUBLISHABLE_KEY` del progetto di produzione su Cloudflare, nuova pubblicazione,
  poi 9.4.1 e 9.4.3 sul progetto di produzione.

## Verifiche

- Passi eseguiti sul progetto reale: sito pubblicato su `haposto-test.pages.dev`, login nell'area
  ristoratori con verifica in due passaggi, QR e link del locale dall'app.
- Solo documentazione: nessun cambiamento al codice.
