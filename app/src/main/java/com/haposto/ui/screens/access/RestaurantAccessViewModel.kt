package com.haposto.ui.screens.access

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.createSavedStateHandle
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import com.haposto.data.repository.RestaurantAccessRepository
import com.haposto.data.repository.RestaurantRepository
import com.haposto.domain.model.PartnershipStatus
import com.haposto.domain.model.RestaurantClaimStatus
import java.util.Locale
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

class RestaurantAccessViewModel(
    private val restaurantRepository: RestaurantRepository,
    private val accessRepository: RestaurantAccessRepository,
    private val savedStateHandle: SavedStateHandle,
) : ViewModel() {

    private val searchQuery = savedStateHandle.getStateFlow(KEY_SEARCH, "")
    private val selectedRestaurantId = savedStateHandle.getStateFlow<String?>(KEY_SELECTED_ID, null)
    private val contactInfo = MutableStateFlow("")
    private val isBusy = MutableStateFlow(false)
    private val message = MutableStateFlow<String?>(null)

    private val draft = combine(
        searchQuery,
        selectedRestaurantId,
        contactInfo,
        isBusy,
        message,
    ) { query, selectedId, contact, busy, messageValue ->
        DraftState(query, selectedId, contact, busy, messageValue)
    }

    val uiState = combine(
        accessRepository.observeState(),
        restaurantRepository.observeRestaurants(),
        draft,
    ) { access, restaurants, draftState ->
        val claimRestaurant = access.claim?.restaurantId?.let { id ->
            restaurants.firstOrNull { it.id == id }
        }
        val selectedRestaurant = draftState.selectedId?.let { id ->
            restaurants.firstOrNull { it.id == id }
        }

        val normalizedQuery = draftState.query.trim().lowercase(Locale.ROOT)
        val candidates = restaurants
            .asSequence()
            .filter { it.partnershipStatus == PartnershipStatus.ACTIVE_PARTNER }
            .filter { restaurant ->
                normalizedQuery.isBlank() || listOf(
                    restaurant.name,
                    restaurant.city,
                    restaurant.category,
                ).any { it.lowercase(Locale.ROOT).contains(normalizedQuery) }
            }
            .take(8)
            .toList()

        val phase = when {
            access.account == null -> RestaurantAccessPhase.SIGNED_OUT
            access.claim?.status == RestaurantClaimStatus.PENDING -> RestaurantAccessPhase.PENDING
            access.claim?.status == RestaurantClaimStatus.APPROVED -> RestaurantAccessPhase.APPROVED
            selectedRestaurant != null -> RestaurantAccessPhase.CLAIM_FORM
            else -> RestaurantAccessPhase.SEARCH
        }

        RestaurantAccessUiState(
            phase = phase,
            account = access.account,
            claim = access.claim,
            claimRestaurant = claimRestaurant,
            searchQuery = draftState.query,
            candidates = candidates,
            selectedRestaurant = selectedRestaurant,
            contactInfo = draftState.contact,
            isBusy = draftState.busy,
            message = draftState.message,
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = RestaurantAccessUiState(
            searchQuery = savedStateHandle[KEY_SEARCH] ?: "",
            contactInfo = "",
        ),
    )

    fun signInDemoGoogle() {
        viewModelScope.launch {
            isBusy.value = true
            message.value = null
            accessRepository.signInWithDemoGoogle()
            isBusy.value = false
            message.value = "Identità demo caricata. Nessun login reale è stato eseguito."
        }
    }

    fun onSearchQueryChange(value: String) {
        savedStateHandle[KEY_SEARCH] = value.take(80)
    }

    fun selectRestaurant(restaurantId: String) {
        savedStateHandle[KEY_SELECTED_ID] = restaurantId
        val restaurant = restaurantRepository.findById(restaurantId)
        contactInfo.value = restaurant?.phoneNumber.orEmpty()
        message.value = null
    }

    fun cancelSelection() {
        savedStateHandle[KEY_SELECTED_ID] = null
        contactInfo.value = ""
        message.value = null
    }

    fun onContactInfoChange(value: String) {
        contactInfo.value = value.take(120)
    }

    fun submitClaim() {
        val restaurantId = selectedRestaurantId.value ?: return
        viewModelScope.launch {
            isBusy.value = true
            message.value = null
            val success = accessRepository.submitClaim(
                restaurantId = restaurantId,
                contactInfo = contactInfo.value,
            )
            isBusy.value = false
            if (success) {
                savedStateHandle[KEY_SELECTED_ID] = null
                contactInfo.value = ""
                message.value = "Richiesta demo inviata. In produzione sarà verificata manualmente."
            } else {
                message.value = "Impossibile inviare la richiesta demo. Controlla il recapito."
            }
        }
    }

    fun approvePendingClaimForDemo() {
        viewModelScope.launch {
            isBusy.value = true
            message.value = null
            val success = accessRepository.approvePendingClaimForDemo()
            isBusy.value = false
            message.value = if (success) {
                "Approvazione demo completata. Ora la dashboard è accessibile."
            } else {
                "Nessuna richiesta pending da approvare."
            }
        }
    }

    fun signOut() {
        viewModelScope.launch {
            accessRepository.signOut()
            savedStateHandle[KEY_SELECTED_ID] = null
            contactInfo.value = ""
            message.value = null
        }
    }

    fun resetDemo() {
        viewModelScope.launch {
            accessRepository.resetDemo()
            savedStateHandle[KEY_SEARCH] = ""
            savedStateHandle[KEY_SELECTED_ID] = null
            contactInfo.value = ""
            message.value = null
        }
    }

    private data class DraftState(
        val query: String,
        val selectedId: String?,
        val contact: String,
        val busy: Boolean,
        val message: String?,
    )

    companion object {
        private const val KEY_SEARCH = "access.search"
        private const val KEY_SELECTED_ID = "access.selectedRestaurantId"
    }
}

fun RestaurantAccessViewModelFactory(
    restaurantRepository: RestaurantRepository,
    accessRepository: RestaurantAccessRepository,
): ViewModelProvider.Factory = viewModelFactory {
    initializer {
        RestaurantAccessViewModel(
            restaurantRepository = restaurantRepository,
            accessRepository = accessRepository,
            savedStateHandle = createSavedStateHandle(),
        )
    }
}
