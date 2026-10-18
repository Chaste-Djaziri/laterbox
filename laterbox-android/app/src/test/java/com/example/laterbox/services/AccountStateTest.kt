package com.example.laterbox.services

import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.runTest
import org.junit.Assert.*
import org.junit.Test

class AccountStateTest {
    private val pro = AccountState(userId = "owner", pro = true)

    @Test fun `refresh keeps Pro while entitlement request is pending`() = runTest {
        val state = MutableStateFlow(pro)
        val started = CompletableDeferred<Unit>()
        val result = CompletableDeferred<Boolean>()
        val refresh = launch {
            refreshAccountState(state, pro.copy(pro = false), { "owner" }) {
                started.complete(Unit)
                result.await()
            }
        }
        started.await()
        assertEquals(pro, state.value)
        result.complete(true)
        refresh.join()
        assertEquals(pro, state.value)
    }

    @Test fun `temporary failure preserves confirmed Pro`() = runTest {
        val state = MutableStateFlow(pro)
        refreshAccountState(state, pro.copy(pro = false), { "owner" }) {
            throw java.io.IOException("Offline")
        }
        assertEquals(pro, state.value)
    }

    @Test fun `confirmed downgrade takes effect`() = runTest {
        val state = MutableStateFlow(pro)
        refreshAccountState(state, pro, { "owner" }) { false }
        assertFalse(state.value.pro)
    }

    @Test fun `different account does not inherit Pro on failure`() = runTest {
        val state = MutableStateFlow(pro)
        refreshAccountState(state, AccountState(userId = "other"), { "other" }) {
            throw java.io.IOException("Offline")
        }
        assertEquals(AccountState(userId = "other"), state.value)
    }

    @Test fun `sign out during refresh is not overwritten`() = runTest {
        val state = MutableStateFlow(pro)
        refreshAccountState(state, pro, { null }) {
            state.value = AccountState()
            true
        }
        assertEquals(AccountState(), state.value)
    }

    @Test fun `guest state clears Pro without fetching entitlement`() = runTest {
        val state = MutableStateFlow(pro)
        refreshAccountState(state, AccountState(), { null }) {
            error("Guests must not fetch entitlement")
        }
        assertEquals(AccountState(), state.value)
    }

    @Test fun `cancellation is propagated without downgrading Pro`() = runTest {
        val state = MutableStateFlow(pro)
        var cancelled = false
        try {
            refreshAccountState(state, pro, { "owner" }) { throw CancellationException() }
        } catch (_: CancellationException) {
            cancelled = true
        }
        assertTrue(cancelled)
        assertEquals(pro, state.value)
    }
}
