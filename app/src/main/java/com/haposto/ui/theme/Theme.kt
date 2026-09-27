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
