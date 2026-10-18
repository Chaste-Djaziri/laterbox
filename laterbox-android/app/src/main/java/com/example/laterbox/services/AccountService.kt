package com.example.laterbox.services

import com.example.laterbox.SupabaseClient
import com.example.laterbox.data.api.LaterBoxApiService
import io.github.jan.supabase.auth.auth
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.withContext
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.jsonPrimitive
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

data class AccountState(val userId: String? = null, val email: String? = null, val displayName: String? = null, val pro: Boolean = false, val googleLinked: Boolean = false)
// Keep the last confirmed plan for this account while checking the server. A failed
// request is not a confirmed downgrade, and another account must never inherit Pro.
internal suspend fun refreshAccountState(
    state: MutableStateFlow<AccountState>,
    account: AccountState,
    currentUserId: () -> String?,
    fetchPro: suspend () -> Boolean
) {
    val previous = state.value
    val pending = account.copy(pro = previous.userId == account.userId && previous.pro)
    state.value = pending
    if (account.userId == null) return
    val pro = try {
        fetchPro()
    } catch (cancelled: CancellationException) {
        throw cancelled
    } catch (_: Exception) {
        return
    }
    if (currentUserId() == account.userId) state.value = pending.copy(pro = pro)
}

object AccountService {
    private val refreshMutex = Mutex()
    val state = MutableStateFlow(AccountState())
    suspend fun refresh() = refreshMutex.withLock {
        SupabaseClient.client.auth.awaitInitialization()
        val user = SupabaseClient.client.auth.currentUserOrNull()
        val metaName = user?.userMetadata?.let { meta ->
            meta["display_name"]?.jsonPrimitive?.contentOrNull
                ?: meta["name"]?.jsonPrimitive?.contentOrNull
                ?: meta["full_name"]?.jsonPrimitive?.contentOrNull
                ?: meta["user_name"]?.jsonPrimitive?.contentOrNull
        }?.takeIf { it.isNotBlank() }

        refreshAccountState(
        state = state,
        account = AccountState(user?.id, user?.email, metaName, googleLinked = user?.identities?.any { it.provider == "google" } == true),
            currentUserId = { SupabaseClient.client.auth.currentUserOrNull()?.id }
        ) {
            val response = NativeApi.call(
                "${LaterBoxApiService.supabaseUrl}/rest/v1/rpc/has_pro_entitlement",
                "POST",
                JSONObject().put("target_user_id", requireNotNull(user).id)
            ).trim()
            when (response) {
                "true" -> true
                "false" -> false
                else -> error("Invalid entitlement response")
            }
        }
    }

    suspend fun signOut() { SupabaseClient.client.auth.signOut(); state.value = AccountState() }
    suspend fun deleteAccount(context: android.content.Context) {
        val user = SupabaseClient.client.auth.currentUserOrNull() ?: throw IllegalStateException("Not authenticated")
        val uid = user.id
        val token = SupabaseClient.client.auth.currentSessionOrNull()?.accessToken ?: throw IllegalStateException("Not authenticated")

        val serverDeleted = LaterBoxApiService.deleteAccount(token)
        if (!serverDeleted) {
            throw IllegalStateException("Account deletion could not finish on cloud. Please try again.")
        }

        withContext(Dispatchers.IO) {
            val db = com.example.laterbox.data.local.AppDatabase.getDatabase(context)
            db.itemMetadataDao().deleteByUserId(uid)
            db.itemDao().deleteByUserId(uid)
            db.collectionDao().deletePermanentlyByUserId(uid)

            val capturesDir = java.io.File(context.filesDir, "captures")
            if (capturesDir.exists()) {
                capturesDir.deleteRecursively()
            }
        }

        signOut()
    }
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
