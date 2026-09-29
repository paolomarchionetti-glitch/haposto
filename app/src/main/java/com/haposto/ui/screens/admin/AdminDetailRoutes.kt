package com.haposto.ui.screens.admin

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import com.haposto.data.Outcome
import com.haposto.data.admin.AdminRepository
import com.haposto.data.admin.AdminRestaurantDetail
import com.haposto.data.admin.AdminUserDetail
import com.haposto.data.admin.RestaurantEdit
import com.haposto.ui.components.BannerKind
import com.haposto.ui.components.LabeledValue
import com.haposto.ui.components.MessageBanner
import com.haposto.ui.components.SectionCard
import com.haposto.ui.components.SimpleScreen
import java.time.ZoneId
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class DetailState<T>(
    val value: T? = null,
    val busy: Boolean = false,
    val message: String? = null,
    val messageIsError: Boolean = false,
)

/** Carica un dettaglio e esegue azioni che, se riuscite, lo ricaricano. */
class AdminDetailViewModel<T>(private val loader: suspend () -> Outcome<T>) : ViewModel() {
    private val mutable = MutableStateFlow(DetailState<T>())
    val state = mutable.asStateFlow()

    init {
        reload()
    }

    fun reload() {
        viewModelScope.launch {
            when (val result = loader()) {
                is Outcome.Success -> mutable.update { it.copy(value = result.value) }
                is Outcome.Failure -> mutable.update { it.copy(message = result.message, messageIsError = true) }
            }
        }
    }

    fun act(success: String, block: suspend () -> Outcome<*>) {
        viewModelScope.launch {
            mutable.update { it.copy(busy = true, message = null) }
            val result = block()
            mutable.update {
                it.copy(
                    busy = false,
                    message = (result as? Outcome.Failure)?.message ?: success,
                    messageIsError = result is Outcome.Failure,
                )
            }
            if (result is Outcome.Success) reload()
        }
    }
}

@Composable
fun AdminRestaurantRoute(restaurantId: String, admin: AdminRepository, onBack: () -> Unit, onOpenUser: (String) -> Unit) {
    val viewModel: AdminDetailViewModel<AdminRestaurantDetail> = viewModel(
        key = "admin-restaurant-$restaurantId",
        factory = viewModelFactory { initializer { AdminDetailViewModel { admin.restaurantDetail(restaurantId) } } },
    )
    val state = viewModel.state.collectAsStateWithLifecycle().value
    val detail = state.value

    SimpleScreen(title = detail?.name ?: "Locale", onBack = onBack) {
        state.message?.let { MessageBanner(it, if (state.messageIsError) BannerKind.ERROR else BannerKind.SUCCESS) }
        if (detail == null) {
            MessageBanner("Carico…")
            return@SimpleScreen
        }
        var note by rememberSaveable { mutableStateOf("") }

        SectionCard(title = "Scheda") {
            LabeledValue("Stato", statusLabel(detail.partnershipStatus))
            LabeledValue("Piano", planLabel(detail.planCode))
            LabeledValue("Indirizzo", "${detail.address}, ${detail.city} (${detail.province})")
            LabeledValue("Telefono", "${detail.phoneNumber ?: "—"}${if (detail.phonePublic) " · pubblico" else ""}")
            LabeledValue("Fonte", detail.dataSource)
            detail.slug?.let { LabeledValue("Pagina pubblica", "/r/$it") }
            Text("Id: ${detail.restaurantId}", style = MaterialTheme.typography.bodySmall, fontFamily = FontFamily.Monospace)
        }

        OutlinedTextField(
            value = note,
            onValueChange = { note = it.take(300) },
            label = { Text("Nota per il registro (motivo dell'azione)") },
            modifier = Modifier.fillMaxWidth(),
        )

        SectionCard(title = "Stato del locale") {
            Row(Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                listOf("ACTIVE_PARTNER", "PAUSED", "SUSPENDED", "DIRECTORY_ONLY").forEach { status ->
                    FilterChip(
                        selected = detail.partnershipStatus == status,
                        enabled = !state.busy,
                        onClick = {
                            viewModel.act("✓ Stato aggiornato.") { admin.setRestaurantStatus(detail.restaurantId, status, note) }
                        },
                        label = { Text(statusLabel(status)) },
                    )
                }
            }
            Text("Sospeso = sparisce dalle ricerche e non può pubblicare.", style = MaterialTheme.typography.bodySmall)
        }

        SectionCard(title = "Regala un piano") {
            var months by rememberSaveable { mutableIntStateOf(6) }
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                listOf(1, 3, 6, 12).forEach { m ->
                    FilterChip(selected = months == m, onClick = { months = m }, label = { Text("$m mesi") })
                }
            }
            OutlinedButton(
                onClick = { viewModel.act("✓ Pro attivato per $months mesi.") { admin.grantRestaurantPlan(detail.restaurantId, "RESTAURANT_PRO", months, note) } },
                enabled = !state.busy,
                modifier = Modifier.fillMaxWidth(),
            ) { Text("Attiva Pro per $months mesi") }
        }

        SectionCard(title = "Membri") {
            detail.members.forEach { member ->
                Row {
                    Column(Modifier.weight(1f)) {
                        TextButton(onClick = { onOpenUser(member.userId) }) { Text(member.email) }
                        Text(member.role, style = MaterialTheme.typography.bodySmall)
                    }
                    TextButton(
                        onClick = { viewModel.act("✓ Membro rimosso.") { admin.removeMember(detail.restaurantId, member.userId, note) } },
                        enabled = !state.busy,
                    ) { Text("Togli") }
                }
            }
            var email by rememberSaveable { mutableStateOf("") }
            OutlinedTextField(value = email, onValueChange = { email = it.trim() }, label = { Text("Email da aggiungere") }, singleLine = true, modifier = Modifier.fillMaxWidth())
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedButton(
                    onClick = { viewModel.act("✓ Titolare aggiunto.") { admin.addMember(detail.restaurantId, email, "OWNER", note) } },
                    enabled = email.contains('@') && !state.busy,
                ) { Text("Come titolare") }
                OutlinedButton(
                    onClick = { viewModel.act("✓ Collaboratore aggiunto.") { admin.addMember(detail.restaurantId, email, "STAFF", note) } },
                    enabled = email.contains('@') && !state.busy,
                ) { Text("Come staff") }
            }
        }

        EditRestaurantSection(detail, state.busy) { edit ->
            viewModel.act("✓ Dati corretti.") { admin.updateRestaurant(detail.restaurantId, edit) }
        }

        SectionCard(title = "Ultimi stati pubblicati") {
            if (detail.recentPublishes.isEmpty()) Text("Nessuno.")
            detail.recentPublishes.take(10).forEach { publish ->
                Text(
                    "${publish.at?.let { DATE_TIME.format(it.atZone(ZoneId.systemDefault())) }.orEmpty()} · ${publish.status} · ${publish.via} ${publish.byEmail.orEmpty()}",
                    style = MaterialTheme.typography.bodySmall,
                )
            }
        }

        SectionCard(title = "Statistiche 30 giorni") {
            detail.stats30Days.forEach { (key, value) -> Text("$key: $value", style = MaterialTheme.typography.bodySmall) }
        }

        SectionCard(title = "Richieste e abbonamenti") {
            detail.claims.forEach { claim ->
                Text("Richiesta ${claim.status} · ${claim.email.orEmpty()} · ${if (claim.phoneVerified) "telefono verificato" else "non verificato"}", style = MaterialTheme.typography.bodySmall)
            }
            detail.subscriptions.forEach { sub ->
                Text("${planLabel(sub.planCode)} · ${sub.status} · ${sub.provider}", style = MaterialTheme.typography.bodySmall)
            }
        }
        Spacer(Modifier.height(16.dp))
    }
}

@Composable
private fun EditRestaurantSection(detail: AdminRestaurantDetail, busy: Boolean, onSave: (RestaurantEdit) -> Unit) {
    var name by rememberSaveable(detail.restaurantId) { mutableStateOf(detail.name) }
    var category by rememberSaveable(detail.restaurantId) { mutableStateOf(detail.category) }
    var address by rememberSaveable(detail.restaurantId) { mutableStateOf(detail.address) }
    var city by rememberSaveable(detail.restaurantId) { mutableStateOf(detail.city) }
    var phone by rememberSaveable(detail.restaurantId) { mutableStateOf(detail.phoneNumber.orEmpty()) }
    var coords by rememberSaveable(detail.restaurantId) {
        mutableStateOf(if (detail.latitude != null && detail.longitude != null) "%.6f, %.6f".format(detail.latitude, detail.longitude) else "")
    }
    SectionCard(title = "Correggi i dati", subtitle = "Anche l'indirizzo e la posizione (lat, lon da Google Maps).") {
        OutlinedTextField(name, { name = it }, label = { Text("Nome") }, singleLine = true, modifier = Modifier.fillMaxWidth())
        OutlinedTextField(category, { category = it }, label = { Text("Categoria") }, singleLine = true, modifier = Modifier.fillMaxWidth())
        OutlinedTextField(address, { address = it }, label = { Text("Indirizzo") }, singleLine = true, modifier = Modifier.fillMaxWidth())
        OutlinedTextField(city, { city = it }, label = { Text("Città") }, singleLine = true, modifier = Modifier.fillMaxWidth())
        OutlinedTextField(phone, { phone = it }, label = { Text("Telefono") }, singleLine = true, modifier = Modifier.fillMaxWidth())
        OutlinedTextField(coords, { coords = it }, label = { Text("Posizione: latitudine, longitudine") }, singleLine = true, modifier = Modifier.fillMaxWidth())
        OutlinedButton(
            onClick = {
                val parts = coords.split(',').mapNotNull { it.trim().toDoubleOrNull() }
                onSave(
                    RestaurantEdit(
                        name = name.takeIf { it != detail.name },
                        category = category.takeIf { it != detail.category },
                        address = address.takeIf { it != detail.address },
                        city = city.takeIf { it != detail.city },
                        latitude = parts.getOrNull(0).takeIf { parts.size == 2 },
                        longitude = parts.getOrNull(1).takeIf { parts.size == 2 },
                        phoneNumber = phone.takeIf { it != detail.phoneNumber.orEmpty() },
                    ),
                )
            },
            enabled = !busy,
            modifier = Modifier.fillMaxWidth(),
        ) { Text("Salva correzioni") }
    }
}

@Composable
fun AdminUserRoute(userId: String, admin: AdminRepository, onBack: () -> Unit, onOpenRestaurant: (String) -> Unit) {
    val viewModel: AdminDetailViewModel<AdminUserDetail> = viewModel(
        key = "admin-user-$userId",
        factory = viewModelFactory { initializer { AdminDetailViewModel { admin.userDetail(userId) } } },
    )
    val state = viewModel.state.collectAsStateWithLifecycle().value
    val user = state.value

    SimpleScreen(title = user?.email ?: "Utente", onBack = onBack) {
        state.message?.let { MessageBanner(it, if (state.messageIsError) BannerKind.ERROR else BannerKind.SUCCESS) }
        if (user == null) {
            MessageBanner("Carico…")
            return@SimpleScreen
        }
        var reason by rememberSaveable { mutableStateOf("") }

        SectionCard(title = "Account") {
            LabeledValue("Email", user.email)
            user.displayName?.let { LabeledValue("Nome", it) }
            LabeledValue("Registrato", user.createdAt?.let { DATE.format(it.atZone(ZoneId.systemDefault())) } ?: "—")
            LabeledValue("Ultimo accesso", user.lastSignInAt?.let { DATE_TIME.format(it.atZone(ZoneId.systemDefault())) } ?: "—")
            LabeledValue("Piano", planLabel(user.consumerPlan))
            LabeledValue("Termini accettati", user.acceptedTermsVersion ?: "no")
            LabeledValue("Preferiti / avvisi attivi", "${user.favorites} / ${user.activeAlerts}")
            if (user.isAdmin) MessageBanner("Questo account è amministratore.")
            Text("Id: ${user.userId}", style = MaterialTheme.typography.bodySmall, fontFamily = FontFamily.Monospace)
        }

        SectionCard(title = "Sospensione") {
            if (user.blockedAt != null) {
                MessageBanner("Sospeso dal ${DATE.format(user.blockedAt.atZone(ZoneId.systemDefault()))}${user.blockedReason?.let { ": $it" }.orEmpty()}", BannerKind.ERROR)
                OutlinedButton(
                    onClick = { viewModel.act("✓ Account riattivato.") { admin.setUserBlocked(user.userId, false, null) } },
                    enabled = !state.busy,
                    modifier = Modifier.fillMaxWidth(),
                ) { Text("Riattiva l'account") }
            } else {
                OutlinedTextField(reason, { reason = it.take(300) }, label = { Text("Motivo (lo vede l'utente)") }, modifier = Modifier.fillMaxWidth())
                OutlinedButton(
                    onClick = { viewModel.act("✓ Account sospeso: non può più fare nulla nell'app.") { admin.setUserBlocked(user.userId, true, reason) } },
                    enabled = reason.trim().length >= 3 && !state.busy && !user.isAdmin,
                    modifier = Modifier.fillMaxWidth(),
                ) { Text("Sospendi l'account", color = MaterialTheme.colorScheme.error) }
            }
        }

        SectionCard(title = "HAPOSTO Plus omaggio") {
            var months by rememberSaveable { mutableIntStateOf(1) }
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                listOf(1, 3, 6, 12).forEach { m -> FilterChip(selected = months == m, onClick = { months = m }, label = { Text("$m mesi") }) }
            }
            OutlinedButton(
                onClick = { viewModel.act("✓ Plus attivato per $months mesi.") { admin.grantPlus(user.userId, months, reason.ifBlank { null }) } },
                enabled = !state.busy,
                modifier = Modifier.fillMaxWidth(),
            ) { Text("Regala Plus per $months mesi") }
        }

        SectionCard(title = "Locali") {
            if (user.restaurants.isEmpty()) Text("Nessuno.")
            user.restaurants.forEach { restaurant ->
                TextButton(onClick = { onOpenRestaurant(restaurant.restaurantId) }) {
                    Text("${restaurant.name} · ${restaurant.city} · ${restaurant.role}")
                }
            }
        }

        SectionCard(title = "Attività recente") {
            user.recentActivity.forEach { activity ->
                Column {
                    Text(activity.action, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold, fontFamily = FontFamily.Monospace)
                    Text(
                        "${activity.at?.let { DATE_TIME.format(it.atZone(ZoneId.systemDefault())) }.orEmpty()} · ${activity.actorKind}",
                        style = MaterialTheme.typography.bodySmall,
                    )
                }
            }
        }
        Spacer(Modifier.height(16.dp))
    }
}
