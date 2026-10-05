package com.example.laterbox.services

import com.example.laterbox.SupabaseClient
import com.example.laterbox.data.api.LaterBoxApiService
import io.github.jan.supabase.auth.auth
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

data class AccountState(val userId: String? = null, val email: String? = null, val pro: Boolean = false)
object AccountService {
    val state = MutableStateFlow(AccountState())
    suspend fun refresh() {
        SupabaseClient.client.auth.awaitInitialization()
        val user = SupabaseClient.client.auth.currentUserOrNull()
        state.value = AccountState(user?.id, user?.email)
        if (user == null) return
        val pro = runCatching {
            NativeApi.call("${LaterBoxApiService.supabaseUrl}/rest/v1/rpc/has_pro_entitlement", "POST", JSONObject().put("target_user_id", user.id)).trim() == "true"
        }.getOrDefault(false)
        if (SupabaseClient.client.auth.currentUserOrNull()?.id == user.id) state.value = AccountState(user.id, user.email, pro)
    }
    suspend fun signOut() { SupabaseClient.client.auth.signOut(); state.value = AccountState() }
}
object NativeApi {
    suspend fun call(url: String, method: String = "GET", body: JSONObject? = null): String = withContext(Dispatchers.IO) {
        val connection = URL(url).openConnection() as HttpURLConnection
        try {
            connection.requestMethod = method
            connection.connectTimeout = 15000; connection.readTimeout = 30000
            connection.setRequestProperty("Content-Type", "application/json")
            connection.setRequestProperty("Prefer", "resolution=merge-duplicates,return=minimal")
            connection.setRequestProperty("apikey", LaterBoxApiService.supabaseAnonKey)
            SupabaseClient.client.auth.currentSessionOrNull()?.accessToken?.let { connection.setRequestProperty("Authorization", "Bearer $it") }
            if (body != null) { connection.doOutput = true; connection.outputStream.use { it.write(body.toString().toByteArray()) } }
            check(connection.responseCode in 200..299) { "Request failed (${connection.responseCode}). Please retry." }
            connection.inputStream.bufferedReader().use { it.readText() }
        } finally { connection.disconnect() }
    }
}
