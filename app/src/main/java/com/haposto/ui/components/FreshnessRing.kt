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
