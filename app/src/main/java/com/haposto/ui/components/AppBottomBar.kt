package com.haposto.ui.components

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import com.haposto.R
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
            label = { Text(stringResource(R.string.nav_nearby)) },
        )
        NavigationBarItem(
            selected = currentRoute == AppDestination.FAVORITES,
            onClick = onSelectFavorites,
            icon = { Text("☆", style = MaterialTheme.typography.titleMedium) },
            label = { Text(stringResource(R.string.nav_favorites)) },
        )
        NavigationBarItem(
            selected = false,
            onClick = onSelectRestaurateur,
            icon = { Text("🍴", style = MaterialTheme.typography.titleMedium) },
            label = { Text(stringResource(R.string.nav_restaurateur)) },
        )
    }
}
