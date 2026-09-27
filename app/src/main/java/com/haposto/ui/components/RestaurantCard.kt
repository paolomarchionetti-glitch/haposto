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
    e.availableTables?.let {
        if (e.status != AvailabilityStatus.FULL) parts += if (it == 1) "1 tavolo libero" else "$it tavoli liberi"
    }
    e.estimatedWaitMinutes?.let { if (it > 0) parts += "attesa ~$it min" }
    e.note?.takeIf { it.isNotBlank() }?.let { parts += it }
    return parts.takeIf { it.isNotEmpty() }?.joinToString(" · ")
}

fun formatDistance(distanceKm: Double?): String = when {
    distanceKm == null -> "Distanza n/d"
    distanceKm < 1.0 -> "${(distanceKm * 1000).toInt()} m"
    else -> String.format(Locale.ITALY, "%.1f km", distanceKm)
}
