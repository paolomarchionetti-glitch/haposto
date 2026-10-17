# Guida all'icona di HAPOSTO

## In breve: non devi fare nulla per vederla

L'icona è **già configurata** nel progetto come *adaptive icon* Android. Quando installi l'app, il telefono la compone da due pezzi:

- **primo piano** (il pin bianco con il dot verde): `app/src/main/res/drawable/ic_launcher_foreground.xml`
- **sfondo** (ink brand): il colore `launcher_background` in `app/src/main/res/values/colors.xml`

Il "collante" che li unisce è l'adaptive icon:

```
app/src/main/res/mipmap-anydpi/ic_launcher.xml
app/src/main/res/mipmap-anydpi/ic_launcher_round.xml
app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml
app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml
```

e nel `AndroidManifest.xml`:

```xml
android:icon="@mipmap/ic_launcher"
android:roundIcon="@mipmap/ic_launcher_round"
```

Quindi: fai il build e l'icona nuova compare in launcher. Fine.

> Se dopo l'installazione vedi ancora la vecchia icona, disinstalla l'app e reinstalla: alcuni launcher tengono in cache la vecchia.

---

## Se vuoi verificarla o rigenerarla in Android Studio (opzionale)

1. Tasto destro su `app/src/main/res` → **New → Image Asset**.
2. *Icon Type*: **Launcher Icons (Adaptive and Legacy)**.
3. *Foreground Layer*: scegli **Asset Type = Image** e seleziona il file
   `brand/haposto_icon_1024.png` (oppure lascia il vector già presente).
4. *Background Layer*: **Color** e imposta `#173A47` (ink).
5. Regola lo *Resize* del primo piano finché il pin sta nella zona sicura.
6. **Next → Finish**. Android Studio genera i mipmap PNG per tutte le densità.

Non è necessario per far funzionare l'app: serve solo se vuoi anche i PNG per densità o un ritocco fine.

---

## Icona per il Google Play Store (512×512)

Play Console richiede un'icona **512×512 PNG** separata (non l'adaptive icon). È già pronta:

```
brand/haposto_icon_512.png     ← caricala nella scheda Play Store
brand/haposto_icon_1024.png    ← versione grande, per ritagli/marketing
```

---

## Sorgenti brand (vettoriali)

```
brand/haposto_appicon.svg       ← icona app sorgente (modificabile)
brand/haposto_logo_lockup.svg   ← logo orizzontale: pin + "haposto" + tagline
```

Da questi SVG puoi esportare qualsiasi dimensione PNG ti serva (social, sito, stampa).

---

## Palette icona

| Elemento | Colore |
|---|---|
| Sfondo (ink) | `#173A47` → `#0E2933` |
| Pin | bianco caldo `#FDFBF4` |
| Dot "c'è posto" | verde `#12A867` |
