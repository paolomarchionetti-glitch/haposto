# 2026-09-30 — Notifiche: post() richiamava se stessa, nessuna notifica poteva comparire

- **Data:** 30 settembre 2026 (registro scritto il 2 ottobre 2026)
- **PR:** [#11](https://github.com/paolomarchionetti-glitch/haposto/pull/11)
- **Motivo:** nella prova 6.3 Firebase accettava la notifica (`{"sent":1}`) ma sul telefono non
  compariva nulla.

## File modificati e aggiunti

| File | Tipo |
|---|---|
| `app/src/main/java/com/haposto/platform/notifications/HaPostoNotifications.kt` | modificato |
| `app/src/androidTest/java/com/haposto/platform/notifications/HaPostoNotificationsTest.kt` | aggiunto |

## Dettaglio delle modifiche

- **`HaPostoNotifications.post()`:** il commit ba8612f ("lint notifiche") aveva sostituito ogni
  `NotificationManagerCompat.from(context).notify(...)` con `post(...)`, compresa la chiamata dentro
  `post()` stessa: ricorsione infinita, `StackOverflowError` e crash silenzioso in background.
  Nessuna notifica dell'app poteva comparire (server, promemoria locali, conferme dei tasti rapidi).
  Ora `post()` chiama di nuovo `NotificationManagerCompat.notify`, dopo il controllo del permesso.
- **Nuovo test strumentale:** concede il permesso, mostra una notifica dal server e un promemoria
  locale e verifica che compaiano tra le notifiche attive di Android.

## Verifiche

- CI su `main`: compilazione, lint e test sull'emulatore API 34 (16 test, 0 falliti, contro i 14
  di prima).
- Sul telefono (Pixel 6a): la notifica di prova arriva ad app chiusa.
