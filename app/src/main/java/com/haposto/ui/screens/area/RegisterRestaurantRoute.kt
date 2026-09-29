package com.haposto.ui.screens.area

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.haposto.data.Outcome
import com.haposto.data.location.LocationSession
import com.haposto.data.restaurant.NewRestaurantForm
import com.haposto.data.restaurant.RestaurantManagementRepository
import com.haposto.domain.model.GeoPoint
import com.haposto.platform.map.LocationPickerMap
import com.haposto.ui.components.BannerKind
import com.haposto.ui.components.BigActionButton
import com.haposto.ui.components.MessageBanner
import com.haposto.ui.components.SectionCard
import com.haposto.ui.components.SimpleScreen
import kotlinx.coroutines.launch

/**
 * Locale non ancora in HAPOSTO: il ristoratore lo aggiunge in due passi (dati, poi posizione sulla
 * mappa) e parte subito la richiesta di gestione, con la stessa verifica telefonica.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RegisterRestaurantRoute(
    management: RestaurantManagementRepository,
    locationSession: LocationSession,
    onDone: () -> Unit,
    onBack: () -> Unit,
) {
    val origin = locationSession.origin.collectAsStateWithLifecycle().value
    var step by rememberSaveable { mutableIntStateOf(1) }
    var name by rememberSaveable { mutableStateOf("") }
    var category by rememberSaveable { mutableStateOf("") }
    var address by rememberSaveable { mutableStateOf("") }
    var city by rememberSaveable { mutableStateOf("") }
    var province by rememberSaveable { mutableStateOf("PU") }
    var phone by rememberSaveable { mutableStateOf("") }
    var contact by rememberSaveable { mutableStateOf("") }
    var latitude by rememberSaveable { mutableStateOf(origin.point.latitude) }
    var longitude by rememberSaveable { mutableStateOf(origin.point.longitude) }
    var busy by rememberSaveable { mutableStateOf(false) }
    var error by rememberSaveable { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()

    val formReady = name.trim().length >= 2 && address.trim().length >= 3 && city.trim().length >= 2 &&
        contact.trim().length >= 3

    if (step == 1) {
        SimpleScreen(title = "Aggiungi il tuo locale", onBack = onBack) {
            SectionCard(title = "Passo 1 di 2 · Dati del locale") {
                Field("Nome del locale", name) { name = it.take(160) }
                Field("Tipo di cucina (es. Trattoria, Pizzeria)", category) { category = it.take(100) }
                Field("Indirizzo (via e numero)", address) { address = it.take(240) }
                Field("Città", city) { city = it.take(100) }
                Field("Provincia (sigla)", province) { province = it.uppercase().take(2) }
                Field("Telefono pubblico del locale", phone, KeyboardType.Phone) { phone = it.take(24) }
                Field("Il tuo telefono o email di lavoro", contact) { contact = it.take(120) }
                Text(
                    "Per la verifica HAPOSTO chiamerà comunque il numero pubblico del locale.",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            BigActionButton(text = "Avanti: indica dov'è", enabled = formReady, onClick = { step = 2 })
        }
        return
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Passo 2 di 2 · Dov'è?", fontWeight = FontWeight.Bold) },
                navigationIcon = { TextButton(onClick = { step = 1 }) { Text("Indietro") } },
            )
        },
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding),
        ) {
            Text(
                "Sposta la mappa finché il segnaposto 📍 è esattamente sopra il locale.",
                style = MaterialTheme.typography.bodyMedium,
                modifier = Modifier.padding(16.dp),
            )
            LocationPickerMap(
                initial = GeoPoint(latitude, longitude),
                onCenterChanged = { point ->
                    latitude = point.latitude
                    longitude = point.longitude
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f),
            )
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                error?.let { MessageBanner(it, BannerKind.ERROR) }
                BigActionButton(
                    text = if (busy) "Invio…" else "Conferma la posizione e invia la richiesta",
                    enabled = !busy,
                    onClick = {
                        scope.launch {
                            busy = true
                            error = null
                            val result = management.registerNewRestaurant(
                                NewRestaurantForm(
                                    name = name,
                                    category = category.ifBlank { "Ristorante" },
                                    address = address,
                                    city = city,
                                    province = province.ifBlank { "PU" },
                                    location = GeoPoint(latitude, longitude),
                                    phoneNumber = phone,
                                    contactInfo = contact,
                                ),
                            )
                            busy = false
                            when (result) {
                                is Outcome.Success -> onDone()
                                is Outcome.Failure -> error = result.message
                            }
                        }
                    },
                )
            }
        }
    }
}

@Composable
private fun Field(label: String, value: String, keyboardType: KeyboardType = KeyboardType.Text, onChange: (String) -> Unit) {
    OutlinedTextField(
        value = value,
        onValueChange = onChange,
        label = { Text(label) },
        singleLine = true,
        keyboardOptions = KeyboardOptions(keyboardType = keyboardType),
        modifier = Modifier.fillMaxWidth(),
    )
}
