package com.haposto.data.network

import kotlinx.coroutines.flow.Flow

/**
 * Minimal connectivity boundary. STEP 5–6 use it only to communicate uncertainty to the user.
 * It does not make network requests and does not change the fake repository behaviour.
 */
interface NetworkMonitor {
    val isOnline: Flow<Boolean>
}
