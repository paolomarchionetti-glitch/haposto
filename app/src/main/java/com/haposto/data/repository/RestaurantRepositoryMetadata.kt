package com.haposto.data.repository

enum class RestaurantDataSource {
    LOCAL_DEMO,
    SUPABASE,
    CONFIGURATION_ERROR,
}

/**
 * Optional repository metadata used only to explain the active data source in the DEV UI.
 * It is intentionally separate from the V1 RestaurantRepository business contract.
 */
interface RestaurantRepositoryMetadata {
    val dataSource: RestaurantDataSource
}
