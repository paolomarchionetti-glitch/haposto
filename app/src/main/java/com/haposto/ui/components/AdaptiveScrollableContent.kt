package com.haposto.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/**
 * Low-dependency responsive container used before the backend phase.
 * It caps readable line length on tablets / desktop windows while keeping compact layouts full-width.
 */
@Composable
fun AdaptiveScrollableContent(
    innerPadding: PaddingValues,
    modifier: Modifier = Modifier,
    maxContentWidth: Dp = 900.dp,
    horizontalPadding: Dp = 20.dp,
    verticalPadding: Dp = 16.dp,
    verticalArrangement: Arrangement.Vertical = Arrangement.spacedBy(16.dp),
    content: @Composable ColumnScope.() -> Unit,
) {
    BoxWithConstraints(
        modifier = modifier
            .fillMaxSize()
            .padding(innerPadding),
        contentAlignment = Alignment.TopCenter,
    ) {
        val targetMaxWidth = if (maxWidth >= 840.dp) maxContentWidth else maxWidth
        Column(
            modifier = Modifier
                .widthIn(max = targetMaxWidth)
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = horizontalPadding, vertical = verticalPadding),
            verticalArrangement = verticalArrangement,
            content = content,
        )
    }
}
