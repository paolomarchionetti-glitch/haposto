package com.haposto.ui.screens.restaurant

import android.Manifest
import android.content.Context
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.core.content.edit
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.haposto.data.auth.AuthRepository
import com.haposto.data.auth.AuthState
import com.haposto.data.network.NetworkMonitor
import com.haposto.data.repository.RestaurantAccessRepository
import com.haposto.data.repository.RestaurantRepository
import com.haposto.data.restaurant.PlanNotices
import com.haposto.data.restaurant.RestaurantManagementRepository
import com.haposto.data.restaurant.SharedPrefsRecentNotesStore
import com.haposto.platform.notifications.HaPostoNotifications
import com.haposto.platform.notifications.Reminders
import java.time.Instant
import kotlinx.coroutines.launch

/**
 * Dashboard del locale.
 * - DEMO: accesso simulato ([accessRepository]).
 * - DEV/PROD ([management] non nullo): accesso reale, verificato sul server (my_restaurants);
 *   ogni pubblicazione è comunque ricontrollata dal database (ruolo + 2FA).
 */
@Composable
fun RestaurantManagerRoute(
    restaurantId: String,
    repository: RestaurantRepository,
    accessRepository: RestaurantAccessRepository,
    networkMonitor: NetworkMonitor,
    onBack: () -> Unit,
    onGoToAccess: () -> Unit,
    onOpenReservations: () -> Unit,
    management: RestaurantManagementRepository? = null,
    auth: AuthRepository? = null,
    onOpenSettings: () -> Unit = {},
    onOpenMfa: () -> Unit = {},
) {
    val isOnline = networkMonitor.isOnline
        .collectAsStateWithLifecycle(initialValue = true)
        .value

    val canManage: Boolean? = if (management == null) {
        accessRepository.observeState()
            .collectAsStateWithLifecycle(initialValue = accessRepository.currentState())
            .value
            .canManage(restaurantId)
    } else {
        produceState<Boolean?>(initialValue = null, management, restaurantId) {
            value = management.myRestaurants().valueOrNull?.any { it.restaurantId == restaurantId } ?: false
        }.value
    }

    when (canManage) {
        null -> {
            CircularProgressIndicator(Modifier.fillMaxSize().wrapContentSize())
            return
        }
        false -> {
            RestaurantManagerAccessDeniedScreen(onBack = onBack, onGoToAccess = onGoToAccess)
            return
        }
        true -> Unit
    }

    val context = LocalContext.current.applicationContext
    val viewModel: RestaurantManagerViewModel = viewModel(
        factory = RestaurantManagerViewModelFactory(
            restaurantId = restaurantId,
            repository = repository,
            onPublished = { status ->
                val name = repository.findById(restaurantId)?.name ?: "Il tuo locale"
                Reminders.scheduleAfterPublish(context, restaurantId, name, status)
            },
            recentNotesStore = SharedPrefsRecentNotesStore(context, restaurantId),
        ),
    )
    val uiState = viewModel.uiState.collectAsStateWithLifecycle().value
    val serverSaysMfa = viewModel.needsMfa.collectAsStateWithLifecycle().value
    val authState = auth?.state?.collectAsStateWithLifecycle()?.value
    val mfaMissing = management != null &&
        (serverSaysMfa || (authState as? AuthState.SignedIn)?.mfa?.verified == false)

    // Promemoria: il permesso notifiche si chiede una volta, alla prima apertura della dashboard.
    var asked by rememberSaveable { mutableStateOf(false) }
    val launcher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { }
    val needsPermission = remember { !HaPostoNotifications.canPost(context) }
    LaunchedEffect(needsPermission) {
        if (needsPermission && !asked && Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            asked = true
            launcher.launch(Manifest.permission.POST_NOTIFICATIONS)
        }
    }

    // Note pronte del locale (solo con account vero): le vede e le usa anche lo staff.
    val scope = rememberCoroutineScope()
    var quickNotes by remember(restaurantId) { mutableStateOf(emptyList<String>()) }
    // Piano in scadenza o finito: avviso in cima alla dashboard (solo con account vero).
    var planWarning by remember(restaurantId) { mutableStateOf<String?>(null) }
    LaunchedEffect(management, restaurantId) {
        if (management != null) {
            management.extras(restaurantId).valueOrNull?.let { quickNotes = it.quickNotes }
            management.managerInfo(restaurantId).valueOrNull?.let { info ->
                planWarning = PlanNotices.warning(info.plan, Instant.now())
            }
        }
    }
    val prefs = remember { context.getSharedPreferences(PREFS, Context.MODE_PRIVATE) }
    var offerTermsAccepted by remember { mutableStateOf(prefs.getBoolean(KEY_OFFER_TERMS, false)) }

    RestaurantManagerScreen(
        uiState = uiState,
        isOnline = isOnline,
        onBack = onBack,
        onStatusSelected = viewModel::publishStatus,
        onDecrementTables = viewModel::decrementTables,
        onIncrementTables = viewModel::incrementTables,
        onWaitSelected = viewModel::setWait,
        onNoteChange = viewModel::setNote,
        onRefreshCurrentStatus = viewModel::refreshCurrentStatus,
        onPhonePublicChange = viewModel::setPhonePublic,
        onOpenReservations = onOpenReservations,
        onOpenSettings = if (management != null) onOpenSettings else null,
        mfaMissing = mfaMissing,
        onOpenMfa = onOpenMfa,
        onDictateDetails = viewModel::applyDictation,
        onOfferChange = viewModel::setOffer,
        offerTermsAccepted = offerTermsAccepted,
        onAcceptOfferTerms = {
            offerTermsAccepted = true
            prefs.edit { putBoolean(KEY_OFFER_TERMS, true) }
        },
        quickNotes = quickNotes,
        canSaveQuickNotes = management != null,
        planWarning = planWarning,
        onSaveQuickNote = { note ->
            if (management != null) {
                scope.launch {
                    management.setQuickNotes(restaurantId, quickNotes + note).valueOrNull?.let { quickNotes = it }
                }
            }
        },
    )
}

private const val PREFS = "restaurant_manager"
private const val KEY_OFFER_TERMS = "offer_terms_accepted"
