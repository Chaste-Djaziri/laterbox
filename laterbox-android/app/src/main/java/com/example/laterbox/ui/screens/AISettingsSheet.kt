package com.example.laterbox.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import com.example.laterbox.services.*
import com.example.laterbox.ui.capture.Choice
import com.example.laterbox.ui.capture.Field
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AISettingsSheet(onDismiss: () -> Unit) {
    val context = LocalContext.current; val settings = remember { SecureSettings(context) }; val scope = rememberCoroutineScope()
    var provider by remember { mutableStateOf(settings.provider) }; var model by remember { mutableStateOf(settings.model) }; var key by remember { mutableStateOf("") }
    var message by remember { mutableStateOf<String?>(null) }; var busy by remember { mutableStateOf(false) }
    val pro by AccountService.state.collectAsState()
    ModalBottomSheet(onDismissRequest = onDismiss) {
        Column(Modifier.fillMaxWidth().padding(20.dp).imePadding(), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Text("AI models & keys", style = MaterialTheme.typography.headlineSmall)
            Choice("On-device Gemini Nano", "Free inference on supported Android devices") { provider = "device"; settings.provider = "device"; message = "On-device provider selected" }
            if (pro.pro) {
                Row { listOf("gemini", "openai", "claude").forEach { name -> FilterChip(provider == name, { provider = name; model = when(name) { "openai" -> "gpt-4o-mini"; "claude" -> "claude-haiku-4-5"; else -> "gemini-2.5-flash" } }, label = { Text(name.replaceFirstChar { it.uppercase() }) }) } }
                Text("Custom providers use your own API account and may charge you for requests. Keys stay encrypted on this device.")
                Field(model, { model = it }, "Model name")
                OutlinedTextField(key, { key = it }, label = { Text(if (settings.apiKey().isBlank()) "API key" else "Replace API key (optional)") }, visualTransformation = PasswordVisualTransformation(), modifier = Modifier.fillMaxWidth())
                Button(onClick = { settings.provider = provider; settings.model = model.trim(); if (key.isNotBlank()) settings.setApiKey(key.trim()); key = ""; message = "Settings saved" }) { Text("Save model settings") }
                TextButton(onClick = { scope.launch { busy = true; try { settings.provider = provider; settings.model = model; if (key.isNotBlank()) settings.setApiKey(key); CustomAIService.generate(context, "Reply with a short connection confirmation."); message = "Connection successful" } catch (failure: Exception) { message = failure.message } finally { busy = false } } }, enabled = !busy) { Text("Test connection") }
                TextButton(onClick = { settings.setApiKey(""); settings.provider = "device"; provider = "device"; message = "Custom key removed" }) { Text("Remove stored key") }
            } else Text("Custom model configuration requires Pro. On-device Later AI stays free.")
            if (busy) CircularProgressIndicator()
            message?.let { Text(it) }
            TextButton(onClick = onDismiss) { Text("Close") }
        }
    }
}
