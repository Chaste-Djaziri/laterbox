package com.example.laterbox.ui.screens

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.example.laterbox.services.AccountService
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PlansSheet(onDismiss: () -> Unit) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val account by AccountService.state.collectAsState()
    var message by remember { mutableStateOf<String?>(null) }
    var busy by remember { mutableStateOf(false) }
    ModalBottomSheet(onDismissRequest = onDismiss) {
        Column(Modifier.fillMaxWidth().padding(20.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text("LaterBox Pro", style = MaterialTheme.typography.headlineLarge)
            Text("Cloud sync and AI Inbox Organizer. Local capture, local search, and on-device Later AI are free.")
            Text(if (account.pro) "Manage or cancel your subscription on LaterBox Web." else "Subscribe on LaterBox Web to enable cloud sync on Android.")
            Text(account.email?.let { "Sign in on the web with $it, the same account you use here." }
                ?: "Sign in on the web, then sign in to the same account on Android to access Pro.")
            Button(onClick = {
                runCatching {
                    context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://app.laterbox.dev/login?next=%2Fplans")))
                }.onFailure { message = "Could not open your browser. Visit app.laterbox.dev/plans to subscribe or manage your plan." }
            }, modifier = Modifier.fillMaxWidth()) {
                Text(if (account.pro) "Manage subscription on web" else "Get Pro on web")
            }
            OutlinedButton(onClick = {
                scope.launch {
                    busy = true
                    try {
                        AccountService.refresh()
                        message = when {
                            AccountService.state.value.userId == null -> "Sign in to your subscription account on Android first."
                            AccountService.state.value.pro -> "Pro is active. Cloud sync is enabled."
                            else -> "No active Pro access found. Check your web subscription and try again."
                        }
                    } catch (_: Exception) { message = "Could not refresh your subscription. Please try again." }
                    finally { busy = false }
                }
            }, enabled = !busy, modifier = Modifier.fillMaxWidth()) { Text("Refresh subscription") }
            if (busy) CircularProgressIndicator()
            message?.let { Text(it) }
            TextButton(onClick = onDismiss) { Text("Close") }
        }
    }
}
