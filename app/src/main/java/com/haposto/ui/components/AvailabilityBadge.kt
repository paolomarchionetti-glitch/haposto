package com.haposto.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
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
import com.haposto.ui.theme.OnStatusDark
import com.haposto.ui.theme.OnStatusLight

enum class BadgeSize { Compact, Hero }

@Composable
fun AvailabilityBadge(
    status: AvailabilityStatus,
    modifier: Modifier = Modifier,
    size: BadgeSize = BadgeSize.Compact,
) {
    val presentation = statusPresentation(status)
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
                horizontal = if (hero) 14.dp else 10.dp,
                vertical = if (hero) 10.dp else 6.dp,
            ),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(if (hero) 10.dp else 8.dp),
        ) {
            StatusSymbol(presentation = presentation, diameter = if (hero) 26.dp else 20.dp)
            Text(
                text = presentation.label,
                style = if (hero) MaterialTheme.typography.titleMedium else MaterialTheme.typography.labelLarge,
                fontWeight = FontWeight.Bold,
            )
        }
    }
}

/**
 * Cerchio pieno con il simbolo dello stato (✓ ! ✕ ? –): lo stato si capisce anche senza
 * distinguere i colori (daltonismo, schermo al sole).
 */
@Composable
fun StatusSymbol(
    presentation: StatusPresentation,
    modifier: Modifier = Modifier,
    diameter: Dp = 20.dp,
    inverted: Boolean = false,
) {
    Box(
        modifier = modifier
            .size(diameter)
            .clip(CircleShape)
            .background(if (inverted) presentation.onStrong else presentation.strong),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = presentation.symbol,
            color = if (inverted) presentation.strong else presentation.onStrong,
            fontWeight = FontWeight.Black,
            fontSize = (diameter.value * 0.6f).sp,
            lineHeight = (diameter.value * 0.6f).sp,
        )
    }
}

data class StatusPresentation(
    val label: String,
    /** Testo/icone sul fondo tenue [container]. */
    val foreground: Color,
    /** Fondo tenue per badge e card. */
    val container: Color,
    /** Simbolo che non dipende dal colore. */
    val symbol: String,
    /** Colore pieno "semaforo" per tasti grandi e simbolo. */
    val strong: Color,
    /** Testo leggibile sopra [strong] (contrasto ≥ 4.5:1). */
    val onStrong: Color,
)

/**
 * Colori/etichetta/simbolo per uno stato, adattati al tema chiaro/scuro.
 */
@Composable
fun statusPresentation(status: AvailabilityStatus): StatusPresentation {
    val dark = isSystemInDarkTheme()
    val onStrong = if (dark) OnStatusDark else OnStatusLight
    return when (status) {
        AvailabilityStatus.AVAILABLE -> StatusPresentation(
            label = "C'è posto",
            foreground = if (dark) AvailabilityGreenDark else AvailabilityGreen,
            container = if (dark) AvailabilityGreenContainerDark else AvailabilityGreenContainer,
            symbol = "✓",
            strong = if (dark) AvailabilityGreenDark else AvailabilityGreen,
            onStrong = onStrong,
        )
        AvailabilityStatus.LIMITED -> StatusPresentation(
            label = "Pochi posti",
            foreground = if (dark) AvailabilityAmberDark else AvailabilityAmber,
            container = if (dark) AvailabilityAmberContainerDark else AvailabilityAmberContainer,
            symbol = "!",
            strong = if (dark) AvailabilityAmberDark else AvailabilityAmber,
            onStrong = onStrong,
        )
        AvailabilityStatus.FULL -> StatusPresentation(
            label = "Completo",
            foreground = if (dark) AvailabilityRedDark else AvailabilityRed,
            container = if (dark) AvailabilityRedContainerDark else AvailabilityRedContainer,
            symbol = "✕",
            strong = if (dark) AvailabilityRedDark else AvailabilityRed,
            onStrong = onStrong,
        )
        AvailabilityStatus.STALE -> StatusPresentation(
            label = "Da aggiornare",
            foreground = if (dark) AvailabilityNeutralDark else AvailabilityNeutral,
            container = if (dark) AvailabilityNeutralContainerDark else AvailabilityNeutralContainer,
            symbol = "?",
            strong = if (dark) AvailabilityNeutralDark else AvailabilityNeutral,
            onStrong = onStrong,
        )
        AvailabilityStatus.NOT_CONNECTED -> StatusPresentation(
            label = "Non collegato",
            foreground = if (dark) AvailabilityNeutralDark else AvailabilityNeutral,
            container = if (dark) AvailabilityNeutralContainerDark else AvailabilityNeutralContainer,
            symbol = "–",
            strong = if (dark) AvailabilityNeutralDark else AvailabilityNeutral,
            onStrong = onStrong,
        )
    }
}
