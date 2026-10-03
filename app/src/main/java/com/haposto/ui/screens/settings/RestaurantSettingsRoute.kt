package com.haposto.ui.screens.settings

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.FilterChip
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import com.haposto.config.AppConfig
import com.haposto.data.Outcome
import com.haposto.data.restaurant.ActivityEntry
import com.haposto.data.restaurant.DailyStat
import com.haposto.data.restaurant.ManagerInfo
import com.haposto.data.restaurant.MemberRole
import com.haposto.data.restaurant.RestaurantManagementRepository
import com.haposto.data.restaurant.RestaurantExtras
import com.haposto.data.restaurant.RestaurantMember
import com.haposto.domain.model.OpeningHours
import com.haposto.domain.model.TimeRange
import com.haposto.platform.files.PreparedFile
import com.haposto.platform.files.RestaurantFileReader
import com.haposto.platform.qr.QrCodes
import com.haposto.ui.components.BannerKind
import com.haposto.ui.components.BigActionButton
import com.haposto.ui.components.LabeledValue
import com.haposto.ui.components.MessageBanner
import com.haposto.ui.components.SectionCard
import com.haposto.ui.components.SimpleScreen
import java.time.DayOfWeek
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

data class SettingsData(
    val info: ManagerInfo? = null,
    val members: List<RestaurantMember> = emptyList(),
    val activity: List<ActivityEntry> = emptyList(),
    val stats: List<DailyStat> = emptyList(),
    val statsDays: Int = 7,
    val loading: Boolean = true,
    val busy: Boolean = false,
    /** Note pronte, link e file del locale. */
    val extras: RestaurantExtras = RestaurantExtras(),
    /** File scelto e già preparato, in attesa della risposta "vale solo per oggi?". */
    val pendingFile: PreparedFile? = null,
    val message: String? = null,
    val messageIsError: Boolean = false,
)

class RestaurantSettingsViewModel(
    private val restaurantId: String,
    private val management: RestaurantManagementRepository,
) : ViewModel() {

    private val mutable = MutableStateFlow(SettingsData())
    val state = mutable.asStateFlow()

    init {
        reload()
    }

    fun reload() {
        viewModelScope.launch {
            val infoResult = management.managerInfo(restaurantId)
            val info = infoResult.valueOrNull
            val members = if (info?.myRole == MemberRole.OWNER) management.members(restaurantId).valueOrNull.orEmpty() else emptyList()
            val activity = management.activity(restaurantId).valueOrNull.orEmpty()
            val days = mutable.value.statsDays
            val stats = management.stats(restaurantId, days).valueOrNull.orEmpty()
            val extras = management.extras(restaurantId).valueOrNull ?: RestaurantExtras()
            mutable.value = mutable.value.copy(
                info = info,
                members = members,
                activity = activity,
                stats = stats,
                extras = extras,
                loading = false,
                message = (infoResult as? Outcome.Failure)?.message,
                messageIsError = infoResult is Outcome.Failure,
            )
        }
    }

    fun loadStats(days: Int) {
        viewModelScope.launch {
            val stats = management.stats(restaurantId, days).valueOrNull.orEmpty()
            mutable.value = mutable.value.copy(stats = stats, statsDays = days)
        }
    }

    fun saveProfile(name: String, category: String, phone: String?, phonePublic: Boolean, hours: OpeningHours?) = act("✓ Dati del locale salvati.") {
        management.updateProfile(restaurantId, name, category, phone, phonePublic, hours)
    }

    fun addStaff(email: String) = act("✓ Collaboratore aggiunto: vedrà il locale nella sua area ristoratore.") {
        management.addStaff(restaurantId, email)
    }

    fun removeStaff(userId: String) = act("✓ Collaboratore rimosso.") { management.removeStaff(restaurantId, userId) }

    fun setQuickNotes(notes: List<String>) = act("✓ Note pronte aggiornate.") {
        management.setQuickNotes(restaurantId, notes)
    }

    fun saveLinks(websiteUrl: String, menuUrl: String) = act("✓ Link salvati: li vedono i clienti nella scheda del locale.") {
        management.setLinks(restaurantId, websiteUrl, menuUrl)
    }

    /** Legge e riduce il file scelto (fuori dal thread principale), poi chiede "solo per oggi?". */
    fun prepareFile(context: Context, uri: Uri) {
        viewModelScope.launch {
            mutable.value = mutable.value.copy(busy = true, message = null)
            val result = withContext(Dispatchers.IO) { RestaurantFileReader.read(context.applicationContext, uri) }
            mutable.value = when (result) {
                is RestaurantFileReader.Result.Ready -> mutable.value.copy(busy = false, pendingFile = result.file)
                is RestaurantFileReader.Result.Error -> mutable.value.copy(busy = false, message = result.message, messageIsError = true)
            }
        }
    }

    fun cancelFile() {
        mutable.value = mutable.value.copy(pendingFile = null)
    }

    fun uploadFile(todayOnly: Boolean) {
        val file = mutable.value.pendingFile ?: return
        mutable.value = mutable.value.copy(pendingFile = null)
        act(if (todayOnly) "✓ File pubblicato: domattina si cancella da solo." else "✓ File pubblicato.") {
            management.uploadFile(restaurantId, file.bytes, file.mimeType, todayOnly)
        }
    }

    fun removeFile() = act("✓ File tolto.") { management.removeFile(restaurantId) }

    fun show(text: String, error: Boolean = false) {
        mutable.value = mutable.value.copy(message = text, messageIsError = error)
    }

    private fun act(success: String, block: suspend () -> Outcome<*>) {
        viewModelScope.launch {
            mutable.value = mutable.value.copy(busy = true, message = null)
            val result = block()
            mutable.value = mutable.value.copy(
                busy = false,
                message = (result as? Outcome.Failure)?.message ?: success,
                messageIsError = result is Outcome.Failure,
            )
            if (result is Outcome.Success) reload()
        }
    }
}

@Composable
fun RestaurantSettingsRoute(
    restaurantId: String,
    management: RestaurantManagementRepository,
    onBack: () -> Unit,
    onOpenMfa: () -> Unit,
) {
    val viewModel: RestaurantSettingsViewModel = viewModel(
        key = "settings-$restaurantId",
        factory = viewModelFactory { initializer { RestaurantSettingsViewModel(restaurantId, management) } },
    )
    val state = viewModel.state.collectAsStateWithLifecycle().value
    val info = state.info

    SimpleScreen(title = "Gestisci il locale", onBack = onBack) {
        state.message?.let { MessageBanner(it, if (state.messageIsError) BannerKind.ERROR else BannerKind.SUCCESS) }
        when {
            state.loading -> MessageBanner("Carico i dati del locale…")
            info == null -> MessageBanner("Non riesco a caricare il locale. Riprova tra poco.", BannerKind.ERROR)
            else -> {
                Text(info.name, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Black)
                if (!info.mfaOk) {
                    MessageBanner("Per vedere e modificare i dati serve il codice della verifica in due passaggi.", BannerKind.ERROR)
                    BigActionButton(text = "Inserisci il codice", onClick = onOpenMfa)
                }
                PlanSection(info)
                QrSection(info)
                val owner = info.myRole == MemberRole.OWNER
                if (owner) ProfileSection(info, state.busy, viewModel)
                if (info.mfaOk) QuickNotesSection(state.extras, state.busy, viewModel)
                if (owner && info.mfaOk) LinksAndFileSection(state, viewModel)
                StatsSection(state, viewModel::loadStats)
                if (owner) StaffSection(info, state, viewModel)
                ActivitySection(state.activity)
                if (!owner) {
                    MessageBanner("Sei collaboratore: puoi pubblicare lo stato. I dati del locale li cambia il titolare.")
                }
            }
        }
        Spacer(Modifier.height(16.dp))
    }
}

@Composable
private fun PlanSection(info: ManagerInfo) {
    val plan = info.plan
    SectionCard(title = "Il tuo piano") {
        LabeledValue("Piano", plan.name)
        val source = when (plan.source) {
            "BETA" -> "Gratis durante la beta"
            "STRIPE" -> "Abbonamento attivo"
            "MANUAL" -> "Attivato da HAPOSTO"
            else -> "Gratuito"
        }
        LabeledValue("Stato", source)
        plan.validUntil?.let { LabeledValue("Valido fino al", DATE.format(it.atZone(ZoneId.systemDefault()))) }
        Text(
            if (plan.isPro) {
                "Incluso: dettagli (tavoli, attesa, nota), collaboratori, promemoria, statistiche fino a ${plan.analyticsDays} giorni."
            } else {
                "Basic: stato con un tocco, telefono pubblico, QR, statistiche di 7 giorni. Con Pro: dettagli, collaboratori, promemoria e statistiche complete."
            },
            style = MaterialTheme.typography.bodyMedium,
        )
        Text(
            "Per informazioni sui piani scrivi a info@haposto.app.",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

@Composable
private fun QrSection(info: ManagerInfo) {
    val context = LocalContext.current
    val slug = info.slug ?: return
    val url = AppConfig.publicRestaurantUrl(slug)
    val qr = remember(url) { QrCodes.bitmap(url, 600).asImageBitmap() }
    SectionCard(
        title = "QR e link del locale",
        subtitle = "Stampalo e mettilo in vetrina: chi lo inquadra vede subito se c'è posto, anche senza l'app.",
    ) {
        Image(
            bitmap = qr,
            contentDescription = "QR della pagina pubblica del locale",
            modifier = Modifier
                .size(200.dp)
                .align(Alignment.CenterHorizontally),
        )
        Text(url.removePrefix("https://"), style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
        BigActionButton(
            text = "🖨  Crea l'adesivo da stampare (PDF)",
            onClick = { context.startActivity(QrCodes.stickerPdf(context, "haposto-$slug", info.name, url)) },
        )
        OutlinedButton(
            onClick = { context.startActivity(QrCodes.sharePng(context, "haposto-qr-$slug", url)) },
            modifier = Modifier.fillMaxWidth(),
        ) { Text("Condividi il QR (immagine)") }
        OutlinedButton(
            onClick = {
                val send = Intent(Intent.ACTION_SEND).apply {
                    type = "text/plain"
                    putExtra(Intent.EXTRA_TEXT, "Guarda se c'è posto da ${info.name}: $url")
                }
                context.startActivity(Intent.createChooser(send, null))
            },
            modifier = Modifier.fillMaxWidth(),
        ) { Text("Condividi il link (WhatsApp, social…)") }
    }
}

@Composable
private fun ProfileSection(info: ManagerInfo, busy: Boolean, viewModel: RestaurantSettingsViewModel) {
    var name by rememberSaveable(info.restaurantId) { mutableStateOf(info.name) }
    var category by rememberSaveable(info.restaurantId) { mutableStateOf(info.category) }
    var phone by rememberSaveable(info.restaurantId) { mutableStateOf(info.phoneNumber.orEmpty()) }
    var phonePublic by rememberSaveable(info.restaurantId) { mutableStateOf(info.phonePublic) }
    val hoursText = remember(info.restaurantId) {
        mutableStateMapOf<DayOfWeek, String>().apply {
            DayOfWeek.entries.forEach { day ->
                val ranges = info.openingHours?.days?.get(day)
                put(day, when {
                    ranges == null -> ""
                    ranges.isEmpty() -> "chiuso"
                    else -> ranges.joinToString(", ") { it.label().replace('–', '-') }
                })
            }
        }
    }

    SectionCard(title = "Dati del locale") {
        OutlinedTextField(name, { name = it.take(160) }, label = { Text("Nome") }, singleLine = true, modifier = Modifier.fillMaxWidth())
        OutlinedTextField(category, { category = it.take(100) }, label = { Text("Tipo di cucina") }, singleLine = true, modifier = Modifier.fillMaxWidth())
        OutlinedTextField(
            phone,
            { phone = it.take(24) },
            label = { Text("Telefono del locale") },
            singleLine = true,
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone),
            modifier = Modifier.fillMaxWidth(),
        )
        Row(Modifier.fillMaxWidth().heightIn(min = 48.dp), verticalAlignment = Alignment.CenterVertically) {
            Text("Mostra il numero e il tasto Chiama", style = MaterialTheme.typography.bodyMedium, modifier = Modifier.weight(1f))
            Switch(checked = phonePublic, onCheckedChange = { phonePublic = it }, enabled = phone.isNotBlank())
        }
        Text("L'indirizzo lo corregge HAPOSTO su richiesta (info@haposto.app).", style = MaterialTheme.typography.bodySmall)

        HorizontalDivider()
        Text("Orari", style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
        Text(
            "Scrivi le fasce separate da virgola, es. 12-14.30, 19-23.30. Scrivi «chiuso» per il giorno di riposo. Vuoto = non indicato.",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        DayOfWeek.entries.forEach { day ->
            OutlinedTextField(
                value = hoursText[day].orEmpty(),
                onValueChange = { hoursText[day] = it.take(60) },
                label = { Text(OpeningHours.ITALIAN_SHORT.getValue(day)) },
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
            )
        }
        BigActionButton(
            text = if (busy) "Salvo…" else "Salva i dati del locale",
            enabled = !busy && name.trim().length >= 2 && category.trim().length >= 2,
            onClick = {
                val hours = parseHours(hoursText)
                if (hours == null) {
                    viewModel.show("Orari non validi: usa il formato 12-14.30, 19-23.30 oppure «chiuso».", true)
                } else {
                    viewModel.saveProfile(name, category, phone.ifBlank { null }, phonePublic && phone.isNotBlank(), hours.takeUnless { it.isEmpty })
                }
            },
        )
    }
}

/** "12-14.30, 19-23.30" → fasce; "chiuso" → giorno di chiusura; vuoto → non indicato. */
private fun parseHours(texts: Map<DayOfWeek, String>): OpeningHours? = runCatching {
    OpeningHours(
        texts.mapNotNull { (day, raw) ->
            val text = raw.trim().lowercase()
            when {
                text.isEmpty() -> null
                text == "chiuso" -> day to emptyList()
                else -> day to text.split(',').map { range ->
                    val parts = range.split('-', '–')
                    require(parts.size == 2)
                    TimeRange(OpeningHours.parseTime(parts[0]), OpeningHours.parseTime(parts[1]))
                }
            }
        }.toMap(),
    )
}.getOrNull()

@Composable
private fun StatsSection(state: SettingsData, onDays: (Int) -> Unit) {
    val stats = state.stats
    SectionCard(title = "Quante persone ti hanno visto") {
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            listOf(7, 30, 90).forEach { days ->
                FilterChip(selected = state.statsDays == days, onClick = { onDays(days) }, label = { Text("$days giorni") })
            }
        }
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            BigNumber("Schede aperte", stats.sumOf { it.detailViews })
            BigNumber("Indicazioni", stats.sumOf { it.directionsTaps })
            BigNumber("Chiamate", stats.sumOf { it.callTaps })
        }
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            BigNumber("Pagina QR", stats.sumOf { it.publicPageViews })
            BigNumber("Condivisioni", stats.sumOf { it.shares })
            BigNumber("Aggiornamenti", stats.sumOf { it.liveUpdates })
        }
        if (stats.isNotEmpty()) {
            Text("Schede aperte per giorno", style = MaterialTheme.typography.labelLarge)
            val values = stats.sortedBy { it.day }.map { it.detailViews }
            val max = (values.maxOrNull() ?: 0).coerceAtLeast(1)
            val barColor = MaterialTheme.colorScheme.primary
            Canvas(Modifier.fillMaxWidth().height(90.dp)) {
                val barWidth = size.width / values.size
                values.forEachIndexed { index, value ->
                    val h = size.height * value / max
                    drawRect(
                        color = barColor,
                        topLeft = Offset(index * barWidth + barWidth * 0.15f, size.height - h),
                        size = Size(barWidth * 0.7f, h),
                    )
                }
            }
        } else {
            Text("Ancora nessun dato: i numeri crescono quando i clienti aprono la tua scheda.", style = MaterialTheme.typography.bodySmall)
        }
    }
}

@Composable
private fun BigNumber(label: String, value: Int) {
    Column(Modifier.width(96.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Text(value.toString(), style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Black)
        Text(label, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

@Composable
private fun StaffSection(info: ManagerInfo, state: SettingsData, viewModel: RestaurantSettingsViewModel) {
    var email by rememberSaveable { mutableStateOf("") }
    var confirmRemove by remember { mutableStateOf<RestaurantMember?>(null) }
    val staffCount = state.members.count { it.role == MemberRole.STAFF }
    SectionCard(
        title = "Collaboratori",
        subtitle = "Camerieri e soci che possono pubblicare lo stato con il loro account. Possono solo cambiare lo stato.",
    ) {
        state.members.forEach { member ->
            Row(verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(1f)) {
                    Text(member.displayName ?: member.email, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
                    Text(
                        "${member.email} · ${if (member.role == MemberRole.OWNER) "Titolare" else "Collaboratore"}",
                        style = MaterialTheme.typography.bodySmall,
                    )
                }
                if (member.role == MemberRole.STAFF) {
                    TextButton(onClick = { confirmRemove = member }) { Text("Togli") }
                }
            }
        }
        if (!info.plan.has("STAFF_ACCOUNTS")) {
            Text("I collaboratori sono una funzione Pro.", style = MaterialTheme.typography.bodySmall)
        } else {
            Text("Usati $staffCount di ${info.plan.staffLimit}.", style = MaterialTheme.typography.bodySmall)
            OutlinedTextField(
                value = email,
                onValueChange = { email = it.trim().take(120) },
                label = { Text("Email Google del collaboratore") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email),
                modifier = Modifier.fillMaxWidth(),
            )
            Text(
                "Prima deve aprire HAPOSTO e accedere una volta con quell'email.",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            OutlinedButton(
                onClick = {
                    viewModel.addStaff(email)
                    email = ""
                },
                enabled = email.contains('@') && !state.busy,
                modifier = Modifier.fillMaxWidth(),
            ) { Text("Aggiungi collaboratore") }
        }
    }
    confirmRemove?.let { member ->
        androidx.compose.material3.AlertDialog(
            onDismissRequest = { confirmRemove = null },
            title = { Text("Togliere ${member.displayName ?: member.email}?") },
            text = { Text("Non potrà più pubblicare lo stato del locale.") },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.removeStaff(member.userId)
                    confirmRemove = null
                }) { Text("Togli") }
            },
            dismissButton = { TextButton(onClick = { confirmRemove = null }) { Text("Annulla") } },
        )
    }
}

@Composable
private fun ActivitySection(entries: List<ActivityEntry>) {
    var shown by remember { mutableIntStateOf(10) }
    SectionCard(
        title = "Registro attività",
        subtitle = "Chi ha pubblicato cosa e quando. Se vedi qualcosa di strano, scrivi subito a info@haposto.app.",
    ) {
        if (entries.isEmpty()) {
            Text("Nessuna attività ancora.", style = MaterialTheme.typography.bodySmall)
        }
        entries.take(shown).forEach { entry ->
            Column {
                Text(entry.summary, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
                Text(
                    "${entry.at?.atZone(ZoneId.systemDefault())?.let(DATE_TIME::format).orEmpty()} · ${entry.actor}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
        if (entries.size > shown) {
            TextButton(onClick = { shown += 20 }) { Text("Mostra altre") }
        }
    }
}

private val DATE: DateTimeFormatter = DateTimeFormatter.ofPattern("dd/MM/yyyy")
private val DATE_TIME: DateTimeFormatter = DateTimeFormatter.ofPattern("dd/MM HH:mm")

@Composable
private fun QuickNotesSection(extras: RestaurantExtras, busy: Boolean, viewModel: RestaurantSettingsViewModel) {
    var newNote by rememberSaveable { mutableStateOf("") }
    SectionCard(title = "Note pronte") {
        Text(
            "Frasi che usi spesso nella nota dello stato: nella dashboard le scegli con un tocco. Le vede anche lo staff. Al massimo ${RestaurantExtras.MAX_QUICK_NOTES}.",
            style = MaterialTheme.typography.bodySmall,
        )
        extras.quickNotes.forEach { note ->
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(note, style = MaterialTheme.typography.bodyMedium, modifier = Modifier.weight(1f))
                TextButton(onClick = { viewModel.setQuickNotes(extras.quickNotes - note) }, enabled = !busy) { Text("Togli") }
            }
        }
        if (extras.quickNotes.size < RestaurantExtras.MAX_QUICK_NOTES) {
            OutlinedTextField(
                value = newNote,
                onValueChange = { newNote = it.take(80) },
                label = { Text("Nuova nota pronta") },
                placeholder = { Text("Es. Solo tavoli all'aperto") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
            )
            OutlinedButton(
                onClick = {
                    viewModel.setQuickNotes(extras.quickNotes + newNote.trim())
                    newNote = ""
                },
                enabled = newNote.isNotBlank() && !busy,
            ) { Text("Aggiungi") }
        }
    }
}

@Composable
private fun LinksAndFileSection(state: SettingsData, viewModel: RestaurantSettingsViewModel) {
    val extras = state.extras
    val context = LocalContext.current
    var website by rememberSaveable(extras.websiteUrl) { mutableStateOf(extras.websiteUrl.orEmpty()) }
    var menu by rememberSaveable(extras.menuUrl) { mutableStateOf(extras.menuUrl.orEmpty()) }
    val picker = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        if (uri != null) viewModel.prepareFile(context, uri)
    }

    SectionCard(title = "Menù, sito e file") {
        Text(
            "Li vedono i clienti nella scheda del locale e nella pagina del QR. HAPOSTO li controlla e può toglierli se non sono adatti.",
            style = MaterialTheme.typography.bodySmall,
        )
        OutlinedTextField(
            value = website,
            onValueChange = { website = it.take(300) },
            label = { Text("Sito del locale (facoltativo)") },
            placeholder = { Text("www.tuolocale.it") },
            singleLine = true,
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Uri),
            modifier = Modifier.fillMaxWidth(),
        )
        OutlinedTextField(
            value = menu,
            onValueChange = { menu = it.take(300) },
            label = { Text("Link al menù (facoltativo)") },
            placeholder = { Text("Sito, Instagram, Google Drive…") },
            singleLine = true,
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Uri),
            modifier = Modifier.fillMaxWidth(),
        )
        OutlinedButton(
            onClick = { viewModel.saveLinks(website, menu) },
            enabled = !state.busy && (website != extras.websiteUrl.orEmpty() || menu != extras.menuUrl.orEmpty()),
        ) { Text("Salva i link") }

        HorizontalDivider()
        val file = extras.file
        Text(
            text = when {
                file == null -> "Foto o PDF: nessun file."
                else -> buildString {
                    append(if (file.isPdf) "PDF" else "Foto")
                    append(" · ").append((file.bytes + 1023) / 1024).append(" KB")
                    if (file.todayOnly) append(" · solo per oggi")
                }
            },
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.SemiBold,
        )
        OutlinedButton(
            onClick = { picker.launch(arrayOf("image/*", "application/pdf")) },
            enabled = !state.busy,
        ) { Text(if (file == null) "Scegli foto o PDF" else "Sostituisci con un'altra foto o PDF") }
        if (file != null) {
            TextButton(onClick = viewModel::removeFile, enabled = !state.busy) { Text("Togli il file") }
        }
        Text(
            "Un file solo: quello nuovo sostituisce il vecchio. Le foto le riduce il telefono; PDF fino a 2 MB.",
            style = MaterialTheme.typography.bodySmall,
        )
    }

    state.pendingFile?.let { pending ->
        AlertDialog(
            onDismissRequest = viewModel::cancelFile,
            title = { Text("Vale solo per oggi?") },
            text = {
                Text(
                    (if (pending.isPdf) "PDF pronto" else "Foto pronta") +
                        ". Per il menù del giorno scegli «Solo oggi»: domattina si cancella da solo.",
                )
            },
            confirmButton = { TextButton(onClick = { viewModel.uploadFile(todayOnly = true) }) { Text("Solo oggi") } },
            dismissButton = { TextButton(onClick = { viewModel.uploadFile(todayOnly = false) }) { Text("No, resta") } },
        )
    }
}
