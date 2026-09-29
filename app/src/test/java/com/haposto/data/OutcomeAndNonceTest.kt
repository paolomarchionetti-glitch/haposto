package com.haposto.data

import com.haposto.data.auth.Nonce
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class OutcomeAndNonceTest {

    @Test
    fun databaseCodesBecomeItalianMessages() = runTest {
        val outcome = outcomeOf { throw IllegalStateException("P0001: MFA_REQUIRED") }
        assertEquals(ErrorMessages.failure("MFA_REQUIRED"), outcome)
        assertTrue((outcome as Outcome.Failure).message.contains("due passaggi"))
    }

    @Test
    fun theMostSpecificCodeWins() {
        // "ACCOUNT_BLOCKED" contiene anche "LOCKED" (pannello admin bloccato): deve vincere il primo.
        assertEquals("ACCOUNT_BLOCKED", ErrorMessages.failureFor(RuntimeException("ACCOUNT_BLOCKED")).code)
        assertEquals("LOCKED", ErrorMessages.failureFor(RuntimeException("error: LOCKED")).code)
    }

    @Test
    fun theCauseIsInspectedToo() {
        val error = RuntimeException("request failed", IllegalArgumentException("RATE_LIMITED"))
        assertEquals("RATE_LIMITED", ErrorMessages.failureFor(error).code)
    }

    @Test
    fun unknownErrorsNeverLeakTechnicalText() {
        val failure = ErrorMessages.failureFor(RuntimeException("java.net.UnknownHostException: xyz.supabase.co"))
        assertEquals("UNKNOWN", failure.code)
        assertEquals(ErrorMessages.GENERIC, failure.message)
    }

    @Test
    fun mapKeepsFailuresAndTransformsValues() {
        assertEquals(Outcome.Success(4), Outcome.Success(2).map { it * 2 })
        val failure: Outcome<Int> = ErrorMessages.failure("WRONG_CODE")
        assertEquals(failure, failure.map { it * 2 })
    }

    @Test
    fun nonceHashIsTheSha256OfTheRawValue() {
        val (raw, hashed) = Nonce.generate()
        assertEquals(64, raw.length)
        assertEquals(Nonce.sha256Hex(raw), hashed)
        assertEquals(
            "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
            Nonce.sha256Hex("abc"),
        )
        assertNotEquals(raw, Nonce.generate().first)
    }
}
