package com.haposto.data.loyalty

import com.haposto.data.Outcome

/**
 * Tessera fedeltà, lato cliente (versioni DEV e PROD). Il server decide modalità, tester e
 * limiti; su un database senza la migration 0018 le chiamate falliscono e la tessera resta nascosta.
 */
interface CustomerLoyaltyRepository {
    suspend fun access(): Outcome<LoyaltyAccess>

    /** Riquadro nella scheda del locale (anche senza account). */
    suspend fun restaurantBox(restaurantId: String): Outcome<RestaurantLoyaltyBox>

    /** Nuovo QR personale da 60 secondi. */
    suspend fun createToken(restaurantId: String): Outcome<VisitToken>
    suspend fun tokenStatus(token: String): Outcome<TokenStatus>

    /** «Siamo in gruppo»: crea il tavolo e il suo primo QR. */
    suspend fun createGroup(restaurantId: String): Outcome<LoyaltyGroup>

    /** Nuovo QR del tavolo (solo il capogruppo). */
    suspend fun groupToken(groupId: String): Outcome<LoyaltyGroup>

    /** «Unisciti a un tavolo» con il codice letto dal QR del tavolo. */
    suspend fun joinGroup(token: String): Outcome<JoinedGroup>
    suspend fun leaveGroup(groupId: String): Outcome<Unit>
    suspend fun groupStatus(groupId: String): Outcome<GroupStatus>

    suspend fun myCards(): Outcome<List<MyLoyaltyCard>>

    /** T26: lasciare la tessera di un locale (timbri e codice si cancellano). */
    suspend fun leaveCard(restaurantId: String): Outcome<Unit>

    suspend fun report(restaurantId: String, kind: LoyaltyReportKind): Outcome<Unit>
}
