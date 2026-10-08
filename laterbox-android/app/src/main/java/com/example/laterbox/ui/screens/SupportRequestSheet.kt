package com.example.laterbox.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.laterbox.BuildConfig
import com.example.laterbox.SupabaseClient
import com.example.laterbox.data.api.LaterBoxApiService
import com.example.laterbox.services.AccountService
import com.example.laterbox.theme.*
import io.github.jan.supabase.auth.auth
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

private val supportCategories = listOf(
    "problem" to "Report a problem",
    "help" to "I need help",
    "feedback" to "Feedback or suggestion",
    "other" to "Something else",
)
private val emailPattern = Regex("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$")

private sealed interface SupportResult {
    data class Sent(val id: String) : SupportResult
    data class Failed(val message: String) : SupportResult
}

private suspend fun sendSupportRequest(payload: JSONObject): SupportResult = withContext(Dispatchers.IO) {
    val connection = URL("${LaterBoxApiService.webBaseUrl}/api/support").openConnection() as HttpURLConnection
    try {
        connection.requestMethod = "POST"
        connection.connectTimeout = 15000; connection.readTimeout = 30000
        connection.doOutput = true
        connection.setRequestProperty("Content-Type", "application/json")
        connection.setRequestProperty("Accept", "application/json")
        SupabaseClient.client.auth.currentSessionOrNull()?.accessToken?.let { connection.setRequestProperty("Authorization", "Bearer $it") }
        connection.outputStream.use { it.write(payload.toString().toByteArray()) }
        val code = connection.responseCode
        val text = (if (code in 200..299) connection.inputStream else connection.errorStream)?.bufferedReader()?.use { it.readText() }.orEmpty()
        val json = runCatching { JSONObject(text) }.getOrNull()
        val id = json?.optString("id").orEmpty()
        if (code == 201 && id.isNotEmpty()) SupportResult.Sent(id)
        else SupportResult.Failed(json?.optString("error")?.takeIf { it.isNotBlank() } ?: "We could not send your request. Please try again.")
    } catch (_: Exception) {
        SupportResult.Failed("We could not send your request. Check your connection and try again.")
    } finally { connection.disconnect() }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SupportRequestSheet(onDismiss: () -> Unit) {
    val scope = rememberCoroutineScope()
    val account by AccountService.state.collectAsState()
    var email by remember { mutableStateOf(account.email.orEmpty()) }
    var category by remember { mutableStateOf("problem") }
    var categoryMenu by remember { mutableStateOf(false) }
    var subject by remember { mutableStateOf("") }
    var message by remember { mutableStateOf("") }
    var sending by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    var reference by remember { mutableStateOf<String?>(null) }
    val valid = emailPattern.matches(email.trim()) && email.trim().length <= 254 &&
        subject.trim().length in 3..160 && message.trim().length in 10..5000

    ModalBottomSheet(onDismissRequest = { if (!sending) onDismiss() }, containerColor = LaterboxBg) {
        Column(
            Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(horizontal = 20.dp).padding(bottom = 28.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text("Help & Report a Problem", fontSize = 22.sp, fontWeight = FontWeight.Bold, color = LaterboxTextPrimary)
            val sent = reference
            if (sent != null) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Icon(Icons.Default.CheckCircle, null, tint = LaterboxEmerald)
                    Text("Request received", fontWeight = FontWeight.SemiBold, color = LaterboxTextPrimary)
                }
                Text("We can reply to ${email.trim()}.", fontSize = 14.sp, color = LaterboxTextSecondary)
                Text("Reference: $sent", fontSize = 12.sp, color = LaterboxTextSecondary)
                Button(onClick = { reference = null }, modifier = Modifier.fillMaxWidth()) { Text("Send another request") }
                TextButton(onClick = onDismiss, modifier = Modifier.fillMaxWidth()) { Text("Close") }
            } else {
                Text("Tell us what happened or how we can help. Include steps to reproduce a problem. Please leave out passwords and sensitive information.", fontSize = 13.sp, color = LaterboxTextSecondary)
                ExposedDropdownMenuBox(expanded = categoryMenu, onExpandedChange = { if (!sending) categoryMenu = it }) {
                    OutlinedTextField(
                        value = supportCategories.first { it.first == category }.second, onValueChange = {}, readOnly = true,
                        label = { Text("What do you need?") },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = categoryMenu) },
                        modifier = Modifier.fillMaxWidth().menuAnchor(MenuAnchorType.PrimaryNotEditable), enabled = !sending
                    )
                    ExposedDropdownMenu(expanded = categoryMenu, onDismissRequest = { categoryMenu = false }) {
                        supportCategories.forEach { (value, label) ->
                            DropdownMenuItem(text = { Text(label) }, onClick = { category = value; categoryMenu = false })
                        }
                    }
                }
                OutlinedTextField(
                    value = email, onValueChange = { email = it.take(254) }, label = { Text("Reply email") }, singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email), enabled = !sending, modifier = Modifier.fillMaxWidth()
                )
                OutlinedTextField(
                    value = subject, onValueChange = { subject = it.take(160) }, label = { Text("Subject") }, singleLine = true,
                    enabled = !sending, modifier = Modifier.fillMaxWidth()
                )
                OutlinedTextField(
                    value = message, onValueChange = { message = it.take(5000) }, label = { Text("Message") },
                    minLines = 5, enabled = !sending, modifier = Modifier.fillMaxWidth(),
                    supportingText = { Text("${message.length}/5,000 characters · At least 10 characters") }
                )
                Text("Your email, message, platform, and app version are saved with this request.", fontSize = 11.sp, color = LaterboxTextSecondary)
                error?.let { Text(it, fontSize = 13.sp, color = LaterboxRose) }
                Button(
                    onClick = {
                        scope.launch {
                            sending = true; error = null
                            val payload = JSONObject()
                                .put("email", email.trim()).put("category", category)
                                .put("subject", subject.trim()).put("message", message.trim())
                                .put("platform", "android")
                                .put("appVersion", "${BuildConfig.VERSION_NAME} (${BuildConfig.VERSION_CODE})")
                            when (val result = sendSupportRequest(payload)) {
                                is SupportResult.Sent -> { reference = result.id; subject = ""; message = "" }
                                is SupportResult.Failed -> error = result.message
                            }
                            sending = false
                        }
                    },
                    enabled = valid && !sending, modifier = Modifier.fillMaxWidth()
                ) {
                    if (sending) { CircularProgressIndicator(Modifier.size(16.dp), strokeWidth = 2.dp); Spacer(Modifier.width(8.dp)) }
                    Text(if (sending) "Sending…" else "Send request")
                }
            }
        }
    }
}
