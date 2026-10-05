package com.example.laterbox.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.example.laterbox.data.local.ItemEntity
import com.example.laterbox.services.*
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun OrganizerSheet(items: List<ItemEntity>, onDismiss: () -> Unit, onChanged: () -> Unit) {
    val context = LocalContext.current; val scope = rememberCoroutineScope()
    var suggestions by remember { mutableStateOf<List<Pair<ItemEntity, AIAction>>>(emptyList()) }
    var error by remember { mutableStateOf<String?>(null) }; var busy by remember { mutableStateOf(false) }
    ModalBottomSheet(onDismissRequest = onDismiss) {
        Column(Modifier.fillMaxWidth().padding(20.dp).verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text("AI Inbox Organizer", style = MaterialTheme.typography.headlineSmall)
            Text("Review suggested tags and collections before applying them. Reminder dates stay unchanged.")
            if (!AccountService.state.value.pro) Text("LaterBox Pro is required.")
            else if (suggestions.isEmpty()) Button(onClick = { scope.launch {
                busy = true; error = null
                val ai = LaterAIService(context)
                try {
                    val result = mutableListOf<Pair<ItemEntity, AIAction>>()
                    for (item in items.filter { it.status == "inbox" }.take(20)) result.add(item to ai.respond("Suggest tags and category only for this saved content: ${item.title}\n${item.textContent.orEmpty().take(3000)}", emptyList()))
                    suggestions = result
                } catch (failure: Exception) { error = failure.message ?: "On-device organizer is unavailable." }
                finally { ai.close(); busy = false }
            } }, enabled = !busy) { Text("Suggest organization") }
            if (busy) CircularProgressIndicator()
            error?.let { Text(it, color = MaterialTheme.colorScheme.error) }
            suggestions.forEach { (item, action) ->
                Text(item.title.orEmpty(), style = MaterialTheme.typography.titleMedium)
                Text("${action.category} · ${action.tags}")
                Row {
                    TextButton(onClick = { scope.launch { try { check(AccountService.state.value.pro); VaultStore(context).edit(item.copy(tags = action.tags, category = action.category)); suggestions = suggestions.filterNot { it.first.id == item.id }; onChanged() } catch (failure: Exception) { error = failure.message } } }) { Text("Accept") }
                    TextButton(onClick = { suggestions = suggestions.filterNot { it.first.id == item.id } }) { Text("Skip") }
                }
            }
            TextButton(onClick = onDismiss) { Text("Close") }
        }
    }
}
