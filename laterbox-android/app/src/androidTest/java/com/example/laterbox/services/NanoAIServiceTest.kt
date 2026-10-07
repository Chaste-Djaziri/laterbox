package com.example.laterbox.services

import android.util.Log
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import kotlinx.coroutines.runBlocking
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class NanoAIServiceTest {
    @Test fun guestAndFreeAssistantWorkWithoutCloudAccess() = runBlocking {
        val original = AccountService.state.value
        try {
            val ready = NanoAIService.refresh()
            Log.i("NanoVerification", "Device result: ${NanoAIService.status.value}")
            if (ready) {
                val generated = NanoAIService.generate("Reply with the word Hello.")
                assertFalse("Ready Nano must produce text", generated.isNullOrBlank())
            }
            for (account in listOf(AccountState(), AccountState(userId = "free-test", pro = false))) {
                AccountService.state.value = account
                val response = LaterAIService(ApplicationProvider.getApplicationContext()).respond("hello", emptyList())
                assertEquals("chat", response.intent)
                assertTrue(response.reply.isNotBlank())
                assertFalse(AccountService.state.value.pro)
            }
        } finally { AccountService.state.value = original }
    }
}
