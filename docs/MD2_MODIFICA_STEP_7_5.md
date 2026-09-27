# MD2 — HAPOSTO · STEP 7.5 "Veste da top di gamma"

Documento della modifica **7.5**: cosa cambia, dove, perché, e il codice completo di ogni file. Il codice è anche nello ZIP `HAPOSTO_STEP_7_5_codice.zip` con la stessa struttura di cartelle del progetto.

---

## 1. Obiettivo

Step 7 è **funzionalmente** completo: i due loop core (utente "apri → vedi → vai", ristoratore "un tap → fine") funzionano. Ma l'app è ancora "grezza": placeholder H come icona, `Typography()` vuoto, card piatte, Home affollata, nessun tema scuro, nessun onboarding.

Il 7.5 **veste** l'app senza toccarne il motore: la fa sembrare un prodotto vero, non un prototipo. Nessuna funzione entra nei due loop core; tutto ciò che aggiungo sta ai bordi.

**Regola d'oro rispettata:** la semplicità è il fossato. Il 7.5 rende l'app più bella e più chiara, non più complicata.

---

## 2. Cosa NON tocca (importante)

Il 7.5 **non modifica** repository, modelli di dominio, DTO, use-case o SQL. Quindi:

- il **contratto V1 resta congelato**;
- la guida Build/Supabase (MD1) resta valida applicando prima il 7.5;
- nessuna nuova dipendenza Gradle.

L'unica firma pubblica che cambia comportamento internamente è `statusPresentation(...)`, che diventa `@Composable` per adattarsi al tema chiaro/scuro. Tutti i suoi chiamanti (RestaurantCard, RestaurantManagerScreen) sono già dentro contesti composable, quindi **non si rompe nulla**. La schermata dettaglio non la usa direttamente.

---

## 3. File toccati

### Sostituiscono file esistenti

| File | Destinazione | Cosa cambia |
|---|---|---|
| `Color.kt` | `ui/theme/` | palette brand estesa, token light + dark (mantiene i nomi legacy) |
| `Theme.kt` | `ui/theme/` | schema chiaro **e scuro**, forme arrotondate, dynamic color opzionale |
| `Type.kt` | `ui/theme/` | scala tipografica completa (prima era `Typography()` vuoto) |
| `AvailabilityBadge.kt` | `ui/components/` | pallino disegnato, varianti Compact/Hero, colori adattivi al tema |
| `RestaurantCard.kt` | `ui/components/` | ridisegno: stato dominante, pill LIVE, anello di freschezza, dettagli live |
| `AppDestination.kt` | `ui/navigation/` | aggiunge rotta `favorites` e helper "top-level" |
| `HaPostoApp.kt` | `ui/` | onboarding al primo avvio + `Scaffold` con barra inferiore |
| `HomeScreen.kt` | `ui/screens/home/` | Home alleggerita: sintesi, toggle rapido, posizione collassabile, disclaimer ridotti |
| `ic_launcher_foreground.xml` | `res/drawable/` | icona pin + dot verde (al posto della "H") |
| `colors.xml` | `res/values/` | sfondo icona = ink brand |
| `strings.xml` | `res/values/` | stringhe brand/nav/onboarding esternalizzate (additivo) |

### File nuovi

| File | Destinazione | Cosa fa |
|---|---|---|
| `FreshnessRing.kt` | `ui/components/` | anello che consuma il TTL: freschezza a colpo d'occhio |
| `AppBottomBar.kt` | `ui/components/` | barra inferiore a 3 voci (Vicino / Preferiti / Ristoratore) |
| `OnboardingScreen.kt` | `ui/screens/onboarding/` | onboarding 3 schermate + flag "già visto" |
| `FavoritesRoute.kt` | `ui/screens/favorites/` | tab Preferiti (teaser Plus, placeholder elegante) |

---

## 4. Prima → dopo

**Design system.** Prima: colori sparsi, nessun tema scuro, `Typography()` vuoto (tutto identico e piatto). Dopo: palette brand con token chiaro/scuro, forme arrotondate coerenti (12/16/20/28dp), scala tipografica con gerarchia reale. L'app rispetta automaticamente il tema di sistema.

**Card ristorante.** Prima: testo su testo, stato poco evidente, nessun senso di "quanto è fresco". Dopo: il **nome** in evidenza, la **pill LIVE** per i partner attivi, il **badge di stato** con pallino colorato, un **anello di freschezza** che si svuota con il TTL, "Aggiornato X min fa" + "Valido ancora ~N min", i dettagli live (tavoli/attesa/nota) e la riga meta categoria · distanza. È il colpo d'occhio che rende l'app "fidata".

**Home.** Prima: header pesante, due paragrafi di disclaimer nel mezzo, pannello posizione sempre aperto. Dopo: una domanda ("Dove vuoi mangiare?"), una **riga di sintesi** ("N con posto ora · M nella zona"), un **toggle grande** "Mostra solo dove c'è posto", la **posizione collassabile** (📍 area · "Cambia"), ricerca e filtri, e i disclaimer ridotti a un piede pagina discreto.

**Navigazione.** Prima: solo stack, l'accesso ristoratore era un bottone nell'header. Dopo: **barra inferiore** con Vicino / Preferiti / Ristoratore. Preferiti è il gancio per la funzione Plus (avvisami quando torna "c'è posto"); Ristoratore apre il flusso di accesso.

**Primo avvio.** Prima: nessun onboarding, l'utente arrivava sulla lista senza contesto. Dopo: **3 schermate** che spiegano cos'è, come fidarsi (stati dichiarati, scadono in 30 min, non è prenotazione) e come impostare la zona. Compare solo la prima volta.

**Icona.** Prima: una "H" placeholder. Dopo: **pin + dot verde** su sfondo ink, coerente con logo e app. Nello ZIP trovi anche gli SVG sorgente per Store/web.

---

## 5. Note di integrazione e rischi (onesto)

1. **Scaffold annidato.** `HaPostoApp` avvolge il `NavHost` in uno `Scaffold` (per la barra inferiore) mentre Home/Preferiti hanno il proprio `Scaffold`. È un pattern valido e **non crasha**. L'unico effetto possibile è un piccolo margine extra in basso: se lo noti, aggiungi `contentWindowInsets = WindowInsets(0)` allo `Scaffold` interno.

2. **Icone barra inferiore.** Usano glifi testuali (◉ ☆ 🍴) per **non** aggiungere la dipendenza `material-icons-extended`. Se ce l'hai già, puoi passare a `Icon(Icons.Rounded.*)`.

3. **Font brand.** `Type.kt` usa il font di sistema. Per Poppins/Inter: metti i file in `res/font/` e cambia una riga in `Type.kt`. La scala resta valida.

4. **Onboarding in test.** Compare al primo avvio (flag `haposto_prefs/onboarding_seen_v1`). Per rivederlo: disinstalla o cancella i dati dell'app.

5. **Opzionale, non incluso.** In `RestaurantDetailScreen.kt` i pulsanti sono ancora in MAIUSCOLO ("INDICAZIONI"/"CHIAMA"). Per coerenza col nuovo stile puoi cambiarli in "Indicazioni"/"Chiama". È l'unica modifica manuale suggerita e non è obbligatoria.

---

## 6. Anteprima

Nel pacchetto trovi `anteprima_card.png`: la nuova card in tema chiaro e scuro.

---

## 7. Codice completo

Sotto, il contenuto integrale di ogni file del 7.5. È lo stesso presente nello ZIP.

> **Nota package:** in questo pacchetto il codice usa `com.haposto` (es. `com.haposto.ui.components`). La logica del 7.5 è identica; cambiano solo i nomi di package/import.

### com/haposto/ui/theme/Color.kt

```kotlin
package com.haposto.ui.theme

import androidx.compose.ui.graphics.Color

/* ---------------------------------------------------------------------------
 * HAPOSTO design tokens — STEP 7.5
 * Palette brand estesa con supporto tema chiaro/scuro.
 * I nomi legacy (BrandInk, AvailabilityGreen, ...) sono mantenuti per non
 * rompere i riferimenti esistenti.
 * ------------------------------------------------------------------------- */

// --- Brand ---
val BrandInk = Color(0xFF173A47)
val BrandInkDark = Color(0xFF0E2933)
val BrandGreen = Color(0xFF12A867)       // verde vivido "c'è posto" (logo/accento)
val BrandGreenBright = Color(0xFF3BE39A)

// --- Warm neutrals (light) ---
val WarmBackground = Color(0xFFF8F6F1)
val WarmSurface = Color(0xFFFFFDF8)
val WarmSurfaceVariant = Color(0xFFEBEFEC)
val TextPrimary = Color(0xFF1C2528)
val TextSecondary = Color(0xFF5D6B70)
val OutlineSoft = Color(0xFFC9D2CE)
val OutlineVariantSoft = Color(0xFFDDE2E0)

// --- Dark neutrals ---
val InkBackground = Color(0xFF0E1719)
val InkSurface = Color(0xFF15211F)
val InkSurfaceVariant = Color(0xFF29332F)
val InkTextPrimary = Color(0xFFE7ECEA)
val InkTextSecondary = Color(0xFFB4C0BC)
val InkOutline = Color(0xFF44514D)

// --- Availability (light) ---
val AvailabilityGreen = Color(0xFF1E7A4D)
val AvailabilityGreenContainer = Color(0xFFD9F3E4)
val AvailabilityAmber = Color(0xFF9A6500)
val AvailabilityAmberContainer = Color(0xFFFFE8B2)
val AvailabilityRed = Color(0xFFB43B3B)
val AvailabilityRedContainer = Color(0xFFFFDEDC)
val AvailabilityNeutral = Color(0xFF667176)
val AvailabilityNeutralContainer = Color(0xFFE8ECEA)

// --- Availability (dark) ---
val AvailabilityGreenDark = Color(0xFF7FE0AE)
val AvailabilityGreenContainerDark = Color(0xFF123A28)
val AvailabilityAmberDark = Color(0xFFF4C765)
val AvailabilityAmberContainerDark = Color(0xFF3A2E10)
val AvailabilityRedDark = Color(0xFFFF9B94)
val AvailabilityRedContainerDark = Color(0xFF3A1B1B)
val AvailabilityNeutralDark = Color(0xFFA7B2AE)
val AvailabilityNeutralContainerDark = Color(0xFF232C2A)
```

### com/haposto/ui/theme/Theme.kt

```kotlin
package com.haposto.ui.theme

import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Shapes
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp

private val LightColors = lightColorScheme(
    primary = BrandInk,
    onPrimary = WarmSurface,
    primaryContainer = Color(0xFFDCEEF2),
    onPrimaryContainer = BrandInkDark,

    secondary = Color(0xFF2E7D64),
    onSecondary = Color(0xFFFFFFFF),
    secondaryContainer = Color(0xFFDDEFE7),
    onSecondaryContainer = Color(0xFF10321F),

    tertiary = Color(0xFF9A6500),
    onTertiary = Color(0xFFFFFFFF),
    tertiaryContainer = Color(0xFFF4E6C6),
    onTertiaryContainer = Color(0xFF5B4200),

    background = WarmBackground,
    onBackground = TextPrimary,
    surface = WarmSurface,
    onSurface = TextPrimary,
    surfaceVariant = WarmSurfaceVariant,
    onSurfaceVariant = TextSecondary,

    outline = OutlineSoft,
    outlineVariant = OutlineVariantSoft,

    error = AvailabilityRed,
    onError = Color(0xFFFFFFFF),
    errorContainer = AvailabilityRedContainer,
    onErrorContainer = Color(0xFF5A1414),
)

private val DarkColors = darkColorScheme(
    primary = Color(0xFF7FC9CF),
    onPrimary = Color(0xFF06232B),
    primaryContainer = Color(0xFF1E4652),
    onPrimaryContainer = Color(0xFFCDEBEF),

    secondary = Color(0xFF8CD5B4),
    onSecondary = Color(0xFF07341F),
    secondaryContainer = Color(0xFF234034),
    onSecondaryContainer = Color(0xFFC7E7D6),

    tertiary = Color(0xFFF4C765),
    onTertiary = Color(0xFF3D2E00),
    tertiaryContainer = Color(0xFF453B22),
    onTertiaryContainer = Color(0xFFF1E2BE),

    background = InkBackground,
    onBackground = InkTextPrimary,
    surface = InkSurface,
    onSurface = InkTextPrimary,
    surfaceVariant = InkSurfaceVariant,
    onSurfaceVariant = InkTextSecondary,

    outline = InkOutline,
    outlineVariant = Color(0xFF35413D),

    error = AvailabilityRedDark,
    onError = Color(0xFF3A1B1B),
    errorContainer = Color(0xFF5A1A1A),
    onErrorContainer = Color(0xFFFFDAD5),
)

private val HaPostoShapes = Shapes(
    extraSmall = RoundedCornerShape(8.dp),
    small = RoundedCornerShape(12.dp),
    medium = RoundedCornerShape(16.dp),
    large = RoundedCornerShape(20.dp),
    extraLarge = RoundedCornerShape(28.dp),
)

/**
 * Tema HAPOSTO.
 *
 * @param darkTheme segue il sistema di default.
 * @param dynamicColor usa Material You su Android 12+ se true. Default false per
 *        mantenere l'identità brand; puoi attivarlo per un tocco personalizzato.
 */
@Composable
fun HaPostoTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = false,
    content: @Composable () -> Unit,
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }
        darkTheme -> DarkColors
        else -> LightColors
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = HaPostoTypography,
        shapes = HaPostoShapes,
        content = content,
    )
}
```

### com/haposto/ui/theme/Type.kt

```kotlin
package com.haposto.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

/*
 * Scala tipografica HAPOSTO — STEP 7.5.
 *
 * Usa il font di sistema (SansSerif) per non introdurre dipendenze da file
 * font mancanti nel pacchetto. Quando vorrai il font brand (es. Poppins/Inter),
 * aggiungi i file in res/font/ e sostituisci `FontFamily.SansSerif` con la tua
 * FontFamily: la scala qui sotto resta valida.
 */
private val Brand = FontFamily.SansSerif

val HaPostoTypography = Typography(
    displaySmall = TextStyle(
        fontFamily = Brand, fontWeight = FontWeight.Black,
        fontSize = 34.sp, lineHeight = 40.sp, letterSpacing = (-0.5).sp,
    ),
    headlineMedium = TextStyle(
        fontFamily = Brand, fontWeight = FontWeight.Bold,
        fontSize = 26.sp, lineHeight = 32.sp, letterSpacing = (-0.3).sp,
    ),
    headlineSmall = TextStyle(
        fontFamily = Brand, fontWeight = FontWeight.Bold,
        fontSize = 22.sp, lineHeight = 28.sp, letterSpacing = (-0.2).sp,
    ),
    titleLarge = TextStyle(
        fontFamily = Brand, fontWeight = FontWeight.Bold,
        fontSize = 20.sp, lineHeight = 26.sp,
    ),
    titleMedium = TextStyle(
        fontFamily = Brand, fontWeight = FontWeight.SemiBold,
        fontSize = 17.sp, lineHeight = 22.sp,
    ),
    bodyLarge = TextStyle(
        fontFamily = Brand, fontWeight = FontWeight.Normal,
        fontSize = 16.sp, lineHeight = 24.sp,
    ),
    bodyMedium = TextStyle(
        fontFamily = Brand, fontWeight = FontWeight.Normal,
        fontSize = 14.sp, lineHeight = 20.sp,
    ),
    bodySmall = TextStyle(
        fontFamily = Brand, fontWeight = FontWeight.Normal,
        fontSize = 12.5.sp, lineHeight = 17.sp,
    ),
    labelLarge = TextStyle(
        fontFamily = Brand, fontWeight = FontWeight.SemiBold,
        fontSize = 14.sp, lineHeight = 18.sp, letterSpacing = 0.1.sp,
    ),
    labelMedium = TextStyle(
        fontFamily = Brand, fontWeight = FontWeight.Medium,
        fontSize = 12.sp, lineHeight = 16.sp,
    ),
    labelSmall = TextStyle(
        fontFamily = Brand, fontWeight = FontWeight.Medium,
        fontSize = 11.sp, lineHeight = 14.sp,
    ),
)
```

### com/haposto/ui/components/AvailabilityBadge.kt

```kotlin
package com.haposto.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.haposto.domain.model.AvailabilityStatus
import com.haposto.ui.theme.AvailabilityAmber
import com.haposto.ui.theme.AvailabilityAmberContainer
import com.haposto.ui.theme.AvailabilityAmberContainerDark
import com.haposto.ui.theme.AvailabilityAmberDark
import com.haposto.ui.theme.AvailabilityGreen
import com.haposto.ui.theme.AvailabilityGreenContainer
import com.haposto.ui.theme.AvailabilityGreenContainerDark
import com.haposto.ui.theme.AvailabilityGreenDark
import com.haposto.ui.theme.AvailabilityNeutral
import com.haposto.ui.theme.AvailabilityNeutralContainer
import com.haposto.ui.theme.AvailabilityNeutralContainerDark
import com.haposto.ui.theme.AvailabilityNeutralDark
import com.haposto.ui.theme.AvailabilityRed
import com.haposto.ui.theme.AvailabilityRedContainer
import com.haposto.ui.theme.AvailabilityRedContainerDark
import com.haposto.ui.theme.AvailabilityRedDark

enum class BadgeSize { Compact, Hero }

@Composable
fun AvailabilityBadge(
    status: AvailabilityStatus,
    modifier: Modifier = Modifier,
    size: BadgeSize = BadgeSize.Compact,
) {
    val presentation = statusPresentation(status)
    val dot = presentation.foreground
    val hero = size == BadgeSize.Hero

    Surface(
        modifier = modifier.semantics {
            contentDescription = "Disponibilità: ${presentation.label}"
        },
        color = presentation.container,
        contentColor = presentation.foreground,
        shape = MaterialTheme.shapes.small,
    ) {
        Row(
            modifier = Modifier.padding(
                horizontal = if (hero) 16.dp else 11.dp,
                vertical = if (hero) 11.dp else 7.dp,
            ),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(if (hero) 10.dp else 8.dp),
        ) {
            Canvas(Modifier.size(if (hero) 14.dp else 10.dp)) {
                drawCircle(color = dot)
            }
            Text(
                text = presentation.label,
                style = if (hero) MaterialTheme.typography.titleMedium else MaterialTheme.typography.labelLarge,
                fontWeight = FontWeight.Bold,
            )
        }
    }
}

data class StatusPresentation(
    val label: String,
    val foreground: Color,
    val container: Color,
)

/**
 * Colori/etichetta per uno stato, adattati al tema chiaro/scuro.
 * Resta valida per i call site esistenti (RestaurantCard, RestaurantManagerScreen).
 */
@Composable
fun statusPresentation(status: AvailabilityStatus): StatusPresentation {
    val dark = isSystemInDarkTheme()
    return when (status) {
        AvailabilityStatus.AVAILABLE -> StatusPresentation(
            label = "C'è posto",
            foreground = if (dark) AvailabilityGreenDark else AvailabilityGreen,
            container = if (dark) AvailabilityGreenContainerDark else AvailabilityGreenContainer,
        )
        AvailabilityStatus.LIMITED -> StatusPresentation(
            label = "Pochi posti",
            foreground = if (dark) AvailabilityAmberDark else AvailabilityAmber,
            container = if (dark) AvailabilityAmberContainerDark else AvailabilityAmberContainer,
        )
        AvailabilityStatus.FULL -> StatusPresentation(
            label = "Completo",
            foreground = if (dark) AvailabilityRedDark else AvailabilityRed,
            container = if (dark) AvailabilityRedContainerDark else AvailabilityRedContainer,
        )
        AvailabilityStatus.STALE -> StatusPresentation(
            label = "Da aggiornare",
            foreground = if (dark) AvailabilityNeutralDark else AvailabilityNeutral,
            container = if (dark) AvailabilityNeutralContainerDark else AvailabilityNeutralContainer,
        )
        AvailabilityStatus.NOT_CONNECTED -> StatusPresentation(
            label = "Non collegato",
            foreground = if (dark) AvailabilityNeutralDark else AvailabilityNeutral,
            container = if (dark) AvailabilityNeutralContainerDark else AvailabilityNeutralContainer,
        )
    }
}
```

### com/haposto/ui/components/FreshnessRing.kt (NUOVO)

```kotlin
package com.haposto.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.size
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/**
 * Anello sottile che rappresenta la freschezza residua di uno stato LIVE.
 *
 * @param fraction 1f = appena aggiornato, 0f = TTL scaduto.
 * @param color colore dell'arco pieno (di solito il colore dello stato).
 */
@Composable
fun FreshnessRing(
    fraction: Float,
    color: Color,
    modifier: Modifier = Modifier,
    diameter: Dp = 26.dp,
    stroke: Dp = 3.dp,
) {
    val safe = fraction.coerceIn(0f, 1f)
    val track = MaterialTheme.colorScheme.outlineVariant

    Canvas(modifier.size(diameter)) {
        val s = stroke.toPx()
        val inset = s / 2f
        val arcSize = Size(size.width - s, size.height - s)
        // traccia di fondo
        drawArc(
            color = track,
            startAngle = 0f,
            sweepAngle = 360f,
            useCenter = false,
            topLeft = androidx.compose.ui.geometry.Offset(inset, inset),
            size = arcSize,
            style = Stroke(width = s, cap = StrokeCap.Round),
        )
        // arco residuo (parte dall'alto, in senso orario)
        drawArc(
            color = color,
            startAngle = -90f,
            sweepAngle = 360f * safe,
            useCenter = false,
            topLeft = androidx.compose.ui.geometry.Offset(inset, inset),
            size = arcSize,
            style = Stroke(width = s, cap = StrokeCap.Round),
        )
    }
}
```

### com/haposto/ui/components/RestaurantCard.kt

```kotlin
package com.haposto.ui.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.haposto.domain.model.AvailabilityStatus
import com.haposto.domain.model.PartnershipStatus
import com.haposto.domain.model.Restaurant
import com.haposto.domain.usecase.AvailabilityResolver
import java.time.Duration
import java.time.Instant
import java.util.Locale

@Composable
fun RestaurantCard(
    restaurant: Restaurant,
    now: Instant,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val effective = AvailabilityResolver.resolve(restaurant, now)
    val presentation = statusPresentation(effective.status)
    val updateLabel = AvailabilityResolver.relativeUpdateLabel(effective, now)
    val distanceLabel = formatDistance(restaurant.distanceKm)
    val isPartner = restaurant.partnershipStatus == PartnershipStatus.ACTIVE_PARTNER
    val isLive = effective.status in LIVE_STATUSES

    val fraction: Float? = if (isLive && effective.updatedAt != null && effective.validUntil != null) {
        val total = Duration.between(effective.updatedAt, effective.validUntil).seconds.toFloat()
        val remaining = Duration.between(now, effective.validUntil).seconds.toFloat()
        if (total > 0f) (remaining / total).coerceIn(0f, 1f) else null
    } else null

    val remainingMin: Long? = if (isLive && effective.validUntil != null) {
        (Duration.between(now, effective.validUntil).seconds.coerceAtLeast(0) + 59) / 60
    } else null

    Card(
        modifier = modifier
            .fillMaxWidth()
            .semantics(mergeDescendants = true) {
                contentDescription = buildString {
                    append(restaurant.name); append(". ")
                    append(restaurant.category); append(". ")
                    append(distanceLabel); append(". Disponibilità: ")
                    append(presentation.label); append(". ")
                    append(updateLabel)
                }
            }
            .clickable(onClick = onClick),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        shape = MaterialTheme.shapes.large,
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            // Riga titolo + eventuale pill LIVE
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.Top,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                Text(
                    text = restaurant.name,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.weight(1f),
                )
                if (isPartner) LivePill()
            }

            // Riga stato: badge + anello freschezza
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                AvailabilityBadge(status = effective.status)
                if (fraction != null) {
                    FreshnessRing(fraction = fraction, color = presentation.foreground)
                }
                Column(Modifier.weight(1f)) {
                    Text(
                        text = updateLabel,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                    if (remainingMin != null) {
                        Text(
                            text = if (remainingMin == 1L) "Valido ancora ~1 min" else "Valido ancora ~$remainingMin min",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                }
            }

            // Dettagli opzionali live compatti
            val detail = buildLiveDetail(effective)
            if (detail != null) {
                Text(
                    text = detail,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurface,
                )
            }

            // Meta: categoria · distanza (+ città se diversa da Pesaro)
            Text(
                text = buildString {
                    append(restaurant.category); append(" · "); append(distanceLabel)
                    if (restaurant.city.isNotBlank() && restaurant.city != "Pesaro") {
                        append(" · "); append(restaurant.city)
                    }
                },
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

@Composable
private fun LivePill() {
    Surface(
        color = MaterialTheme.colorScheme.secondaryContainer,
        contentColor = MaterialTheme.colorScheme.onSecondaryContainer,
        shape = MaterialTheme.shapes.small,
    ) {
        Text(
            text = "LIVE",
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp),
            style = MaterialTheme.typography.labelSmall,
            fontWeight = FontWeight.Bold,
        )
    }
}

private val LIVE_STATUSES = setOf(
    AvailabilityStatus.AVAILABLE,
    AvailabilityStatus.LIMITED,
    AvailabilityStatus.FULL,
)

private fun buildLiveDetail(e: com.haposto.domain.model.EffectiveAvailability): String? {
    val parts = mutableListOf<String>()
    e.availableTables?.let { if (e.status != AvailabilityStatus.FULL) parts += "$it tavoli liberi" }
    e.estimatedWaitMinutes?.let { if (it > 0) parts += "attesa ~$it min" }
    e.note?.takeIf { it.isNotBlank() }?.let { parts += it }
    return parts.takeIf { it.isNotEmpty() }?.joinToString(" · ")
}

fun formatDistance(distanceKm: Double?): String = when {
    distanceKm == null -> "Distanza n/d"
    distanceKm < 1.0 -> "${(distanceKm * 1000).toInt()} m"
    else -> String.format(Locale.ITALY, "%.1f km", distanceKm)
}
```

### com/haposto/ui/components/AppBottomBar.kt (NUOVO)

```kotlin
package com.haposto.ui.components

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import com.haposto.ui.navigation.AppDestination

/**
 * Barra inferiore a 3 voci (STEP 7.5).
 * Le icone usano glifi testuali per non introdurre dipendenze da material-icons.
 * Se hai `androidx.compose.material:material-icons-extended`, puoi sostituirle
 * con Icon(Icons.Rounded.*) senza cambiare la struttura.
 */
@Composable
fun AppBottomBar(
    currentRoute: String?,
    onSelectNearby: () -> Unit,
    onSelectFavorites: () -> Unit,
    onSelectRestaurateur: () -> Unit,
) {
    NavigationBar {
        NavigationBarItem(
            selected = currentRoute == AppDestination.HOME,
            onClick = onSelectNearby,
            icon = { Text("◉", style = MaterialTheme.typography.titleMedium) },
            label = { Text("Vicino") },
        )
        NavigationBarItem(
            selected = currentRoute == AppDestination.FAVORITES,
            onClick = onSelectFavorites,
            icon = { Text("☆", style = MaterialTheme.typography.titleMedium) },
            label = { Text("Preferiti") },
        )
        NavigationBarItem(
            selected = false,
            onClick = onSelectRestaurateur,
            icon = { Text("🍴", style = MaterialTheme.typography.titleMedium) },
            label = { Text("Ristoratore") },
        )
    }
}
```

### com/haposto/ui/navigation/AppDestination.kt

```kotlin
package com.haposto.ui.navigation

object AppDestination {
    const val HOME = "home"
    const val FAVORITES = "favorites"
    const val RESTAURANT_DETAIL = "restaurant/{restaurantId}"
    const val RESTAURANT_ACCESS = "restaurant-access"
    const val RESTAURANT_MANAGER = "restaurant-manager/{restaurantId}"

    /** Destinazioni che mostrano la barra inferiore. */
    val TOP_LEVEL = setOf(HOME, FAVORITES)

    fun isTopLevel(route: String?): Boolean = route in TOP_LEVEL

    fun restaurantDetail(restaurantId: String): String = "restaurant/$restaurantId"
    fun restaurantManager(restaurantId: String): String = "restaurant-manager/$restaurantId"
}
```

### com/haposto/ui/HaPostoApp.kt

```kotlin
package com.haposto.ui

import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.haposto.AppDependencies
import com.haposto.ui.components.AppBottomBar
import com.haposto.ui.navigation.AppDestination
import com.haposto.ui.screens.access.RestaurantAccessRoute
import com.haposto.ui.screens.detail.RestaurantDetailRoute
import com.haposto.ui.screens.favorites.FavoritesRoute
import com.haposto.ui.screens.home.HomeRoute
import com.haposto.ui.screens.onboarding.OnboardingPrefs
import com.haposto.ui.screens.onboarding.OnboardingScreen
import com.haposto.ui.screens.restaurant.RestaurantManagerRoute
import com.haposto.ui.theme.HaPostoTheme

@Composable
fun HaPostoApp() {
    val context = LocalContext.current.applicationContext
    var showOnboarding by remember { mutableStateOf(!OnboardingPrefs.hasSeen(context)) }

    HaPostoTheme {
        if (showOnboarding) {
            OnboardingScreen(onFinish = {
                OnboardingPrefs.markSeen(context)
                showOnboarding = false
            })
        } else {
            MainNavigation()
        }
    }
}

@Composable
private fun MainNavigation() {
    val navController = rememberNavController()
    val context = LocalContext.current.applicationContext
    val repository = AppDependencies.restaurantRepository
    val accessRepository = AppDependencies.restaurantAccessRepository
    val locationSession = AppDependencies.locationSession
    val deviceLocationProvider = remember(context) { AppDependencies.deviceLocationProvider(context) }
    val networkMonitor = remember(context) { AppDependencies.networkMonitor(context) }

    val backStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = backStackEntry?.destination?.route

    Scaffold(
        bottomBar = {
            if (AppDestination.isTopLevel(currentRoute)) {
                AppBottomBar(
                    currentRoute = currentRoute,
                    onSelectNearby = {
                        navController.navigate(AppDestination.HOME) {
                            popUpTo(AppDestination.HOME) { inclusive = false }
                            launchSingleTop = true
                        }
                    },
                    onSelectFavorites = {
                        navController.navigate(AppDestination.FAVORITES) {
                            launchSingleTop = true
                        }
                    },
                    onSelectRestaurateur = {
                        navController.navigate(AppDestination.RESTAURANT_ACCESS) {
                            launchSingleTop = true
                        }
                    },
                )
            }
        },
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = AppDestination.HOME,
            modifier = Modifier.padding(innerPadding),
        ) {
            composable(AppDestination.HOME) {
                HomeRoute(
                    repository = repository,
                    deviceLocationProvider = deviceLocationProvider,
                    locationSession = locationSession,
                    networkMonitor = networkMonitor,
                    onRestaurantClick = { restaurantId ->
                        navController.navigate(AppDestination.restaurantDetail(restaurantId))
                    },
                    onRestaurantAreaClick = {
                        navController.navigate(AppDestination.RESTAURANT_ACCESS) {
                            launchSingleTop = true
                        }
                    },
                )
            }
            composable(AppDestination.FAVORITES) {
                FavoritesRoute()
            }
            composable(AppDestination.RESTAURANT_DETAIL) { entry ->
                RestaurantDetailRoute(
                    restaurantId = entry.arguments?.getString("restaurantId").orEmpty(),
                    repository = repository,
                    locationSession = locationSession,
                    onBack = navController::navigateUp,
                )
            }
            composable(AppDestination.RESTAURANT_ACCESS) {
                RestaurantAccessRoute(
                    restaurantRepository = repository,
                    accessRepository = accessRepository,
                    networkMonitor = networkMonitor,
                    onBack = navController::navigateUp,
                    onOpenDashboard = { restaurantId ->
                        navController.navigate(AppDestination.restaurantManager(restaurantId)) {
                            launchSingleTop = true
                            popUpTo(AppDestination.RESTAURANT_ACCESS) { inclusive = false }
                        }
                    },
                )
            }
            composable(AppDestination.RESTAURANT_MANAGER) { entry ->
                RestaurantManagerRoute(
                    restaurantId = entry.arguments?.getString("restaurantId").orEmpty(),
                    repository = repository,
                    accessRepository = accessRepository,
                    networkMonitor = networkMonitor,
                    onBack = navController::navigateUp,
                    onGoToAccess = {
                        navController.navigate(AppDestination.RESTAURANT_ACCESS) {
                            popUpTo(AppDestination.RESTAURANT_ACCESS) { inclusive = false }
                            launchSingleTop = true
                        }
                    },
                )
            }
        }
    }
}
```

### com/haposto/ui/screens/home/HomeScreen.kt

```kotlin
package com.haposto.ui.screens.home

import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.haposto.domain.model.AvailabilityStatus
import com.haposto.domain.model.DistanceOrigin
import com.haposto.domain.model.DistanceOriginType
import com.haposto.domain.model.ManualArea
import com.haposto.domain.model.RestaurantFilter
import com.haposto.domain.usecase.AvailabilityResolver
import com.haposto.ui.components.AppStatePanel
import com.haposto.ui.components.OfflineBanner
import com.haposto.ui.components.RestaurantCard
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    uiState: HomeUiState,
    onSearchQueryChange: (String) -> Unit,
    onFilterSelected: (RestaurantFilter) -> Unit,
    onManualAreaSelected: (ManualArea) -> Unit,
    onUseDeviceLocation: () -> Unit,
    onConfirmLocationRationale: () -> Unit,
    onOpenAppSettings: () -> Unit,
    onRetry: () -> Unit = {},
    onRestaurantClick: (String) -> Unit,
    onRestaurantAreaClick: () -> Unit,
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text(
                            text = "HAPOSTO",
                            fontWeight = FontWeight.Black,
                            color = MaterialTheme.colorScheme.primary,
                        )
                        Text(
                            text = "Sai dove c'è posto. Ora.",
                            style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                },
                actions = {
                    Surface(
                        color = MaterialTheme.colorScheme.tertiaryContainer,
                        contentColor = MaterialTheme.colorScheme.onTertiaryContainer,
                        shape = MaterialTheme.shapes.small,
                        modifier = Modifier.padding(end = 12.dp),
                    ) {
                        Text(
                            text = if (uiState.isSupabaseBacked) "SUPABASE DEV" else "DEMO",
                            modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                            style = MaterialTheme.typography.labelMedium,
                            fontWeight = FontWeight.Bold,
                        )
                    }
                },
            )
        },
    ) { innerPadding ->
        BoxWithConstraints(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding),
            contentAlignment = Alignment.TopCenter,
        ) {
            val contentMaxWidth = if (maxWidth >= 840.dp) 960.dp else maxWidth

            LazyColumn(
                modifier = Modifier
                    .widthIn(max = contentMaxWidth)
                    .fillMaxSize(),
                state = rememberLazyListState(),
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 12.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                item {
                    HomeControls(
                        uiState = uiState,
                        onSearchQueryChange = onSearchQueryChange,
                        onFilterSelected = onFilterSelected,
                        onManualAreaSelected = onManualAreaSelected,
                        onUseDeviceLocation = onUseDeviceLocation,
                        onConfirmLocationRationale = onConfirmLocationRationale,
                        onOpenAppSettings = onOpenAppSettings,
                    )
                }

                if (!uiState.isOnline) {
                    item { OfflineBanner() }
                }

                when {
                    uiState.isInitialLoading && uiState.restaurants.isEmpty() -> {
                        item {
                            AppStatePanel(
                                title = "Caricamento ristoranti",
                                body = "Preparo la directory locale e gli stati di disponibilità.",
                                showProgress = true,
                            )
                        }
                    }
                    uiState.errorMessage != null && uiState.restaurants.isEmpty() -> {
                        item {
                            AppStatePanel(
                                title = "Non riesco a caricare i ristoranti",
                                body = uiState.errorMessage,
                                actionLabel = "Riprova",
                                onAction = onRetry,
                                isError = true,
                            )
                        }
                    }
                    !uiState.hasResults -> {
                        item { EmptyResults(uiState.emptyReason) }
                    }
                    else -> {
                        items(items = uiState.restaurants, key = { it.id }) { restaurant ->
                            RestaurantCard(
                                restaurant = restaurant,
                                now = uiState.now,
                                onClick = { onRestaurantClick(restaurant.id) },
                            )
                        }
                    }
                }

                item {
                    Spacer(Modifier.height(8.dp))
                    Text(
                        text = "Stati dichiarati dai locali · scadono in 30 min · non è una prenotazione.",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                    Text(
                        text = if (uiState.isSupabaseBacked) {
                            "Backend DEV Supabase · il seed usa attività fittizie."
                        } else {
                            "Fallback locale · nomi, indirizzi e disponibilità dimostrativi."
                        },
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                    Spacer(Modifier.height(8.dp))
                }
            }
        }
    }
}

@Composable
private fun HomeControls(
    uiState: HomeUiState,
    onSearchQueryChange: (String) -> Unit,
    onFilterSelected: (RestaurantFilter) -> Unit,
    onManualAreaSelected: (ManualArea) -> Unit,
    onUseDeviceLocation: () -> Unit,
    onConfirmLocationRationale: () -> Unit,
    onOpenAppSettings: () -> Unit,
) {
    var locationExpanded by remember { mutableStateOf(false) }

    val liveCount = remember(uiState.restaurants, uiState.now) {
        uiState.restaurants.count {
            AvailabilityResolver.resolve(it, uiState.now).status in
                setOf(AvailabilityStatus.AVAILABLE, AvailabilityStatus.LIMITED)
        }
    }

    Column(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text(
            text = "Dove vuoi mangiare?",
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.semantics { heading() },
        )

        // Riga di sintesi "in crescita"
        val summary = if (uiState.hasResults) {
            "$liveCount con posto ora · ${uiState.restaurants.size} nella zona"
        } else {
            "Nessun locale in questa zona per ora"
        }
        Text(
            text = summary,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.secondary,
            fontWeight = FontWeight.SemiBold,
        )

        // Toggle rapido "Solo con posto"
        val onlyAvailable = uiState.selectedFilter == RestaurantFilter.AVAILABLE
        FilledTonalButton(
            onClick = {
                onFilterSelected(if (onlyAvailable) RestaurantFilter.ALL else RestaurantFilter.AVAILABLE)
            },
            modifier = Modifier.fillMaxWidth(),
        ) {
            Text(if (onlyAvailable) "Mostro solo dove c'è posto ✓" else "Mostra solo dove c'è posto")
        }

        // Posizione compatta e collassabile
        Surface(
            modifier = Modifier.fillMaxWidth(),
            color = MaterialTheme.colorScheme.surfaceVariant,
            shape = MaterialTheme.shapes.medium,
        ) {
            Column(Modifier.padding(horizontal = 14.dp, vertical = 10.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = "📍 ${uiState.distanceOrigin.label}",
                        style = MaterialTheme.typography.labelLarge,
                        fontWeight = FontWeight.SemiBold,
                        modifier = Modifier.weight(1f),
                    )
                    TextButton(onClick = { locationExpanded = !locationExpanded }) {
                        Text(if (locationExpanded) "Chiudi" else "Cambia")
                    }
                }
                if (locationExpanded) {
                    LocationPanel(
                        origin = uiState.distanceOrigin,
                        isLocating = uiState.isLocating,
                        notice = uiState.locationNotice,
                        onUseDeviceLocation = onUseDeviceLocation,
                        onConfirmLocationRationale = onConfirmLocationRationale,
                        onOpenAppSettings = onOpenAppSettings,
                        onManualAreaSelected = onManualAreaSelected,
                        isSupabaseBacked = uiState.isSupabaseBacked,
                    )
                }
            }
        }

        OutlinedTextField(
            value = uiState.searchQuery,
            onValueChange = onSearchQueryChange,
            modifier = Modifier.fillMaxWidth(),
            singleLine = true,
            label = { Text("Cerca ristorante o cucina") },
            placeholder = { Text("Es. pizza") },
        )

        Row(
            modifier = Modifier
                .fillMaxWidth()
                .horizontalScroll(rememberScrollState()),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            RestaurantFilter.entries.forEach { filter ->
                FilterChip(
                    selected = uiState.selectedFilter == filter,
                    onClick = { onFilterSelected(filter) },
                    label = { Text(filter.label) },
                )
            }
        }
    }
}

@Composable
private fun LocationPanel(
    origin: DistanceOrigin,
    isLocating: Boolean,
    notice: LocationNotice?,
    onUseDeviceLocation: () -> Unit,
    onConfirmLocationRationale: () -> Unit,
    onOpenAppSettings: () -> Unit,
    onManualAreaSelected: (ManualArea) -> Unit,
    isSupabaseBacked: Boolean,
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 10.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        if (origin.type == DistanceOriginType.DEVICE) {
            val precisionText = if (origin.isPrecise == true) {
                "posizione precisa consentita"
            } else {
                "posizione approssimativa consentita"
            }
            val accuracyText = origin.accuracyMeters?.let {
                " · accuratezza ~${formatAccuracy(it)}"
            }.orEmpty()
            Text(
                text = precisionText + accuracyText,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        } else {
            Text(
                text = "Riferimento manuale: nessun dato di posizione personale viene usato.",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }

        if (isLocating) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(10.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                CircularProgressIndicator()
                Text("Cerco la posizione del dispositivo…")
            }
        } else {
            Button(onClick = onUseDeviceLocation, modifier = Modifier.fillMaxWidth()) {
                Text(
                    if (origin.type == DistanceOriginType.DEVICE) "Aggiorna la mia posizione"
                    else "Usa la mia posizione",
                )
            }
        }

        LocationNoticeContent(
            notice = notice,
            onConfirmLocationRationale = onConfirmLocationRationale,
            onOpenAppSettings = onOpenAppSettings,
        )

        Text(
            text = "Oppure scegli un'area",
            style = MaterialTheme.typography.labelLarge,
            fontWeight = FontWeight.SemiBold,
        )
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .horizontalScroll(rememberScrollState()),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            ManualArea.entries.forEach { area ->
                val selected = origin.type == DistanceOriginType.MANUAL_AREA &&
                    origin.label == area.label
                FilterChip(
                    selected = selected,
                    onClick = { onManualAreaSelected(area) },
                    label = { Text(area.label.substringBefore(" centro")) },
                )
            }
        }

        Text(
            text = if (isSupabaseBacked) {
                "La posizione resta sul telefono; viene inviata solo alla funzione geo Supabase per questa ricerca e non salvata nelle tabelle HAPOSTO."
            } else {
                "La posizione resta solo in memoria: non viene salvata o ripristinata dopo la chiusura."
            },
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

@Composable
private fun LocationNoticeContent(
    notice: LocationNotice?,
    onConfirmLocationRationale: () -> Unit,
    onOpenAppSettings: () -> Unit,
) {
    when (notice) {
        LocationNotice.RATIONALE_REQUIRED -> AppStatePanel(
            title = "Perché chiediamo la posizione",
            body = "Serve solo per ordinare i ristoranti per distanza. Puoi concedere anche la posizione approssimativa e puoi continuare scegliendo una città manualmente.",
            actionLabel = "Continua",
            onAction = onConfirmLocationRationale,
        )
        LocationNotice.PERMISSION_DENIED -> Text(
            text = "Permesso non concesso. Puoi continuare usando una delle aree manuali.",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.error,
        )
        LocationNotice.PERMISSION_DENIED_PERMANENT -> AppStatePanel(
            title = "Posizione non autorizzata",
            body = "Android non può mostrare di nuovo automaticamente la richiesta. Puoi abilitarla dalle impostazioni dell'app oppure continuare con una città manuale.",
            actionLabel = "Apri impostazioni app",
            onAction = onOpenAppSettings,
            isError = true,
        )
        LocationNotice.SERVICES_DISABLED -> Text(
            text = "Servizi di localizzazione disattivati. Resta attivo il riferimento manuale.",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.error,
        )
        LocationNotice.UNAVAILABLE -> Text(
            text = "Non è stato possibile ottenere una posizione recente. Resta attivo il riferimento manuale.",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.error,
        )
        null -> Unit
    }
}

private fun formatAccuracy(accuracyMeters: Float): String = when {
    accuracyMeters < 1000f -> "${accuracyMeters.toInt()} m"
    else -> String.format(Locale.ITALY, "%.1f km", accuracyMeters / 1000f)
}

@Composable
private fun EmptyResults(reason: HomeEmptyReason?) {
    val title: String
    val body: String
    when (reason) {
        HomeEmptyReason.DIRECTORY_EMPTY -> {
            title = "Directory ancora vuota"
            body = "Non ci sono ristoranti nella sorgente corrente. Durante il pilot mostreremo quanti locali sono LIVE e quanti solo in directory."
        }
        HomeEmptyReason.NO_MATCHES, null -> {
            title = "Nessun risultato"
            body = "Prova a cambiare ricerca, filtro oppure area di riferimento."
        }
    }
    AppStatePanel(title = title, body = body)
}
```

### com/haposto/ui/screens/onboarding/OnboardingScreen.kt (NUOVO)

```kotlin
package com.haposto.ui.screens.onboarding

import android.content.Context
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp

private data class OnbPage(val title: String, val body: String)

private val PAGES = listOf(
    OnbPage(
        "Scopri dove c'è posto adesso",
        "Apri, guarda i pallini verdi e vai. Niente telefonate, niente prenotazioni.",
    ),
    OnbPage(
        "Dati freschi, di cui fidarti",
        "Gli stati sono dichiarati dai locali e scadono dopo 30 minuti. Non è una prenotazione: la disponibilità può cambiare.",
    ),
    OnbPage(
        "Vicino a te",
        "Attiva la posizione oppure scegli una zona di Pesaro e provincia.",
    ),
)

/** Persistenza minima del "già visto" tramite SharedPreferences. */
object OnboardingPrefs {
    private const val PREFS = "haposto_prefs"
    private const val KEY_SEEN = "onboarding_seen_v1"

    fun hasSeen(context: Context): Boolean =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getBoolean(KEY_SEEN, false)

    fun markSeen(context: Context) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putBoolean(KEY_SEEN, true).apply()
    }
}

@Composable
fun OnboardingScreen(onFinish: () -> Unit) {
    var index by remember { mutableIntStateOf(0) }
    val page = PAGES[index]
    val isLast = index == PAGES.lastIndex

    Surface(color = MaterialTheme.colorScheme.background) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(28.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
                TextButton(onClick = onFinish) { Text("Salta") }
            }

            Spacer(Modifier.height(24.dp))

            // Marchio: pin + dot verde stilizzati
            BrandMark()

            Spacer(Modifier.weight(1f))

            Text(
                text = page.title,
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center,
            )
            Spacer(Modifier.height(12.dp))
            Text(
                text = page.body,
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center,
            )

            Spacer(Modifier.weight(1f))

            // Indicatori pagina
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                PAGES.indices.forEach { i ->
                    val selected = i == index
                    Box(
                        Modifier
                            .size(if (selected) 10.dp else 8.dp)
                            .clip(CircleShape)
                            .background(
                                if (selected) MaterialTheme.colorScheme.primary
                                else MaterialTheme.colorScheme.outlineVariant,
                            ),
                    )
                }
            }

            Spacer(Modifier.height(20.dp))

            Button(
                onClick = { if (isLast) onFinish() else index++ },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(54.dp),
            ) {
                Text(
                    text = if (isLast) "Inizia" else "Avanti",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                )
            }
        }
    }
}

@Composable
private fun BrandMark() {
    Box(
        modifier = Modifier
            .size(96.dp)
            .clip(MaterialTheme.shapes.extraLarge)
            .background(MaterialTheme.colorScheme.primary),
        contentAlignment = Alignment.Center,
    ) {
        Box(
            Modifier
                .size(34.dp)
                .clip(CircleShape)
                .background(com.haposto.ui.theme.BrandGreen),
        )
    }
}
```

### com/haposto/ui/screens/favorites/FavoritesRoute.kt (NUOVO)

```kotlin
package com.haposto.ui.screens.favorites

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

/**
 * Preferiti — placeholder STEP 7.5.
 *
 * Funzione consumer Plus: qui arriveranno i locali salvati e l'alert
 * "avvisami quando torna C'è posto" (Step 16). Per ora mostra un teaser
 * elegante invece di un tab vuoto.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FavoritesRoute(modifier: Modifier = Modifier) {
    Scaffold(
        modifier = modifier,
        topBar = {
            TopAppBar(title = { Text("Preferiti", fontWeight = FontWeight.Bold) })
        },
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Surface(
                color = MaterialTheme.colorScheme.secondaryContainer,
                contentColor = MaterialTheme.colorScheme.onSecondaryContainer,
                shape = MaterialTheme.shapes.large,
                modifier = Modifier.fillMaxWidth(),
            ) {
                Column(
                    modifier = Modifier.padding(20.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    Text("Presto disponibile", style = MaterialTheme.typography.labelLarge, fontWeight = FontWeight.Bold)
                    Text(
                        "Salva i tuoi locali preferiti e ricevi un avviso quando tornano \u201CC'è posto\u201D.",
                        style = MaterialTheme.typography.bodyMedium,
                    )
                    Text(
                        "Sarà parte di HAPOSTO Plus.",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
        }
    }
}
```

### res/drawable/ic_launcher_foreground.xml

```xml
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <!-- Pin (nella safe-zone centrale dell'adaptive icon) -->
    <path
        android:fillColor="#FDFBF4"
        android:pathData="M54,24 C66.7,24 77,34 77,47 C77,60 62,74 54,84 C46,74 31,60 31,47 C31,34 41.3,24 54,24 Z" />
    <!-- Dot verde "c'è posto" -->
    <path
        android:fillColor="#12A867"
        android:pathData="M42,45 a12,12 0 1 0 24,0 a12,12 0 1 0 -24,0 Z" />
</vector>
```

### res/values/colors.xml

```xml
<resources>
    <!-- Sfondo dell'icona adattiva: ink brand per far risaltare pin e dot verde -->
    <color name="launcher_background">#173A47</color>
</resources>
```

### res/values/strings.xml

```xml
<resources>
    <string name="app_name">HAPOSTO</string>
    <string name="app_tagline">Sai dove c\'è posto. Ora.</string>

    <!-- Navigazione -->
    <string name="nav_nearby">Vicino</string>
    <string name="nav_favorites">Preferiti</string>
    <string name="nav_restaurateur">Ristoratore</string>

    <!-- Onboarding (per uso futuro / localizzazione) -->
    <string name="onb1_title">Scopri dove c\'è posto adesso</string>
    <string name="onb1_body">Apri, guarda i pallini verdi e vai. Niente telefonate, niente prenotazioni.</string>
    <string name="onb2_title">Dati freschi, di cui fidarti</string>
    <string name="onb2_body">Gli stati sono dichiarati dai locali e scadono dopo 30 minuti. Non è una prenotazione: la disponibilità può cambiare.</string>
    <string name="onb3_title">Vicino a te</string>
    <string name="onb3_body">Attiva la posizione oppure scegli una zona di Pesaro e provincia.</string>
    <string name="onb_start">Inizia</string>
    <string name="onb_next">Avanti</string>
    <string name="onb_skip">Salta</string>
</resources>
```
