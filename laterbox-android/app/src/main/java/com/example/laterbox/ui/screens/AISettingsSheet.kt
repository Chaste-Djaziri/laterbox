package com.example.laterbox.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import com.example.laterbox.services.*
import com.example.laterbox.ui.capture.Field
import kotlinx.coroutines.launch

private val commonModels = mapOf(
    "gemini" to listOf("Gemini 3.5 Flash-Lite" to "gemini-3.5-flash-lite", "Gemini 2.5 Flash" to "gemini-2.5-flash", "Gemini 2.5 Flash-Lite" to "gemini-2.5-flash-lite"),
    "openai" to listOf("GPT-4.1 mini" to "gpt-4.1-mini", "GPT-4o mini" to "gpt-4o-mini", "GPT-4.1" to "gpt-4.1"),
    "claude" to listOf("Claude Haiku 4.5" to "claude-haiku-4-5", "Claude Sonnet 4.6" to "claude-sonnet-4-6")
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AISettingsSheet(onDismiss: () -> Unit) {
    val context = LocalContext.current
    val settings = remember { SecureSettings(context) }
    val scope = rememberCoroutineScope()
    var provider by remember { mutableStateOf(settings.provider) }
    var model by remember { mutableStateOf(settings.model) }
    var key by remember { mutableStateOf("") }
    var message by remember { mutableStateOf<String?>(null) }
    var busy by remember { mutableStateOf(false) }
    val account by AccountService.state.collectAsState()
    val nanoStatus by NanoAIService.status.collectAsState()
    LaunchedEffect(Unit) { NanoAIService.refresh() }
    fun save() {
        check(AccountService.state.value.pro) { "Model configuration requires Pro." }
        require(model.isNotBlank()) { "Choose a model or enter a model name." }
        if (settings.provider != provider) settings.setApiKey("")
        settings.provider = provider
        settings.model = model.trim()
        if (key.isNotBlank()) settings.setApiKey(key.trim())
        key = ""
    }
    ModalBottomSheet(onDismissRequest = onDismiss) {
        Column(Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(20.dp).imePadding(), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Text("AI model", style = MaterialTheme.typography.headlineSmall)
            Text("Free on-device assistant", style = MaterialTheme.typography.titleMedium)
            Text(nanoStatus)
            Text("Guests and free members use Gemini Nano when available, with a local keyword assistant as fallback. Cloud models and enhanced search require Pro.")
            if (nanoStatus == "Gemini Nano download available") TextButton(onClick = {
                scope.launch {
                    busy = true
                    try { NanoAIService.download() }
                    catch (cancelled: kotlinx.coroutines.CancellationException) { throw cancelled }
                    catch (_: Exception) { message = "Download could not finish. Check your connection and try again."; NanoAIService.refresh() }
                    finally { busy = false }
                }
            }, enabled = !busy) { Text("Download Gemini Nano") }
            TextButton(onClick = { scope.launch { NanoAIService.refresh() } }, enabled = !busy) { Text("Check device support") }
            Text("Your selected cloud model is used for Pro Later AI and enhanced search on this device.")
            if (account.pro) {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    commonModels.keys.forEach { name ->
                        FilterChip(provider == name, {
                            provider = name; model = commonModels.getValue(name).first().second; key = ""
                        }, enabled = !busy, label = { Text(if (name == "openai") "OpenAI" else name.replaceFirstChar { it.uppercase() }) })
                    }
                }
                Text("Common models", style = MaterialTheme.typography.titleMedium)
                commonModels.getValue(provider).forEach { (label, id) ->
                    FilterChip(selected = model == id, onClick = { model = id }, enabled = !busy, label = { Text(label) }, modifier = Modifier.fillMaxWidth())
                }
                Field(model, { model = it }, "Model name (or enter a custom name)")
                Text(if (provider == "gemini") "Gemini can use LaterBox's configured key. An optional personal key replaces it." else "This provider requires your own API key.")
                Text("Personal API accounts may charge for requests. Keys stay encrypted on this device. Switching providers removes the previous provider's key.")
                OutlinedTextField(key, { key = it }, label = { Text("API key (optional for Gemini)") }, visualTransformation = PasswordVisualTransformation(), modifier = Modifier.fillMaxWidth(), enabled = !busy)
                Button(onClick = { runCatching { save() }.onSuccess { message = "Model saved for Later AI and search." }.onFailure { message = it.message } }, enabled = !busy && model.isNotBlank()) { Text("Save model") }
                TextButton(onClick = {
                    scope.launch {
                        busy = true
                        try {
                            save()
                            CustomAIService.generate(context, "Reply with a short connection confirmation.")
                            message = "Connection successful. Model saved for Later AI and search."
                        } catch (failure: Exception) { message = failure.message }
                        finally { busy = false }
                    }
                }, enabled = !busy && model.isNotBlank()) { Text("Save & test connection") }
                TextButton(onClick = { if (AccountService.state.value.pro) { settings.setApiKey(""); key = ""; message = "Personal API key removed." } }, enabled = !busy) { Text("Remove stored key") }
            } else Text("Model selection and enhanced AI search require Pro. Your local keyword assistant and local search stay free.")
            if (busy) CircularProgressIndicator()
            message?.let { Text(it) }
            TextButton(onClick = onDismiss) { Text("Close") }
        }
    }
}
