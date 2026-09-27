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
