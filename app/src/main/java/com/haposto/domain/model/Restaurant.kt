package com.haposto.domain.model

data class Restaurant(
    val id: String,
    val name: String,
    val category: String,
    val address: String,
    val city: String,
    val location: GeoPoint,
    val distanceKm: Double? = null,
    val partnershipStatus: PartnershipStatus,
    val liveAvailability: LiveAvailability? = null,
    val phoneNumber: String? = null,
    val phonePublic: Boolean = false,
) {
    init {
        require(id.isNotBlank())
        require(name.isNotBlank())
        require(address.isNotBlank())
        require(distanceKm == null || distanceKm >= 0.0)
        require(!phonePublic || !phoneNumber.isNullOrBlank()) {
            "A public phone requires a phone number."
        }
    }
}
