package com.example.laterbox.ui.ai

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.example.laterbox.data.DataRepository
import com.example.laterbox.data.local.ItemEntity
import com.example.laterbox.services.*
import com.example.laterbox.theme.LaterboxAccent
import com.example.laterbox.ui.capture.*
import com.example.laterbox.ui.screens.ItemDetailSheet
import com.google.mlkit.genai.common.FeatureStatus
import kotlinx.coroutines.launch
import org.json.JSONArray
import java.util.UUID

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LaterAIScreen(repository: DataRepository, onDismiss: () -> Unit) {
    val items by repository.items.collectAsState(initial = emptyList())
    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true), containerColor = Color.Black) {
        LaterAIContent(items, onDismiss = onDismiss, onSaved = { repository.syncNow() })
    }
}
@Composable
fun LaterAIContent(items: List<ItemEntity>, initial: String = "", attachments: String = "[]", onDismiss: () -> Unit, onSaved: () -> Unit = {}) {
    val context = LocalContext.current
    val store = remember { VaultStore(context) }
    val ai = remember { LaterAIService(context) }
    val scope = rememberCoroutineScope()
    var status by remember { mutableIntStateOf(FeatureStatus.UNAVAILABLE) }
    var checking by remember { mutableStateOf(true) }
    var guided by rememberSaveable { mutableStateOf(false) }
    var input by rememberSaveable { mutableStateOf(initial) }
    var capturedInput by rememberSaveable { mutableStateOf(initial) }
    var busy by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    var saved by remember { mutableStateOf<ItemEntity?>(null) }
    var edit by remember { mutableStateOf(false) }
    var clarify by remember { mutableStateOf(false) }
    var returnQuestion by remember { mutableStateOf(false) }
    var matches by remember { mutableStateOf<List<ItemEntity>>(emptyList()) }
    val messages = remember { mutableStateListOf<Pair<String, Boolean>>() }
    var captureID by rememberSaveable { mutableStateOf(UUID.randomUUID().toString()) }
    DisposableEffect(ai) { onDispose { ai.close() } }
    LaunchedEffect(ai) { status = runCatching { ai.status() }.getOrDefault(FeatureStatus.UNAVAILABLE); checking = false; guided = status != FeatureStatus.AVAILABLE }
    fun save(item: ItemEntity) {
        if (busy) return
        busy = true; error = null
        scope.launch {
            try {
                saved = store.save(item); guided = false; clarify = false; returnQuestion = item.returnAt == null
                messages.add("Saved ‘${saved?.title}’ to your vault." to false)
                onSaved()
                scope.launch { saved?.let { store.metadata(it); onSaved() } }
            } catch (failure: Exception) { error = failure.message ?: "Save failed. Your content is still here." }
            finally { busy = false }
        }
    }
    fun send() {
        if (input.isBlank() || busy) return
        val original = input; capturedInput = original
        messages.add(original to true); busy = true; error = null; matches = emptyList()
        scope.launch {
            try {
                val action = ai.respond(original, items, messages.takeLast(4).joinToString("\n") { it.first })
                when (action.intent) {
                    "capture" -> {
                        val exact = action.content.takeIf { it.isNotBlank() && original.contains(it) } ?: original
                        var draft = VaultStore.draft(exact, action.title, action.tags, action.category, action.returnAt, attachments, captureID)
                        draft = draft.copy(summary = action.summary, formattedContent = action.formatted)
                        busy = false; save(draft); input = ""
                    }
                    "search" -> { matches = LocalSearch.search(action.query.ifBlank { original }, items); messages.add("Found ${matches.size} saved items." to false); input = "" }
                    "clarify" -> { clarify = true; messages.add("Would you like to save this or just chat?" to false) }
                    else -> { messages.add(action.reply to false); input = "" }
                }
            } catch (failure: Exception) { error = failure.message ?: "The local model failed. Retry or continue manually." }
            finally { busy = false }
        }
    }
    Column(Modifier.fillMaxSize().background(Color.Black).padding(20.dp).imePadding(), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            Column { Text("✦ Later AI", color = Color.White, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold); Text(if (status == FeatureStatus.AVAILABLE) "On-device · Private & free" else "Guided capture", color = Color.LightGray, style = MaterialTheme.typography.bodySmall) }
            TextButton(onClick = onDismiss) { Text("Close", color = LaterboxAccent) }
        }
        Column(Modifier.weight(1f).verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            if (attachments != "[]") {
                val files = runCatching { JSONArray(attachments) }.getOrNull()
                files?.let { values -> for (index in 0 until values.length()) Choice("📎 ${values.getJSONObject(index).optString("name", "Shared file")}", "Attached to this capture", true) {} }
            }
            messages.forEach { (text, user) -> Text(text, color = Color.White, modifier = Modifier.fillMaxWidth().background(if (user) Color(0xFF242424) else Color.Black, RoundedCornerShape(18.dp)).padding(12.dp)) }
            if (checking || busy) CircularProgressIndicator(color = LaterboxAccent)
            if (status == FeatureStatus.DOWNLOADABLE && !busy) Choice("Download on-device model", "Enable free Later AI on this device", true) {
                scope.launch { busy = true; try { ai.download { error = it }; status = ai.status(); guided = status != FeatureStatus.AVAILABLE; error = null } catch (failure: Exception) { error = failure.message } finally { busy = false } }
            }
            error?.let {
                Text(it, color = Color(0xFFFFB4AB))
                if (status == FeatureStatus.AVAILABLE) Choice("Retry", dark = true) { input = capturedInput; send() }
                Choice("Continue manually", "Keep your content and attachments", true) { guided = true }
            }
            if (guided && saved == null && !checking) key(captureID) { GuidedCapture(capturedInput, attachments, true, ::save) }
            if (clarify) {
                Choice("Save this", dark = true) { save(VaultStore.draft(capturedInput, attachments = attachments, id = captureID)) }
                Choice("Just chatting", dark = true) { clarify = false; input = "" }
            }
            matches.forEach { item -> Choice(item.title.orEmpty(), item.summary, true) { saved = item; edit = true; returnQuestion = false } }
            saved?.let { item ->
                if (returnQuestion) { Text("When would you like to see it again?", color = Color.White); ReturnChoices(true) { date -> scope.launch { try { val updated = item.copy(returnAt = date, status = if (date == null) "inbox" else "deferred"); store.edit(updated); saved = updated; returnQuestion = false; onSaved() } catch (failure: Exception) { error = failure.message } } } }
                else {
                    Choice("Edit", "Review saved content and metadata", true) { edit = true }
                    Choice("Undo save", "Remove this capture", true) { scope.launch { try { store.undo(item); saved = null; captureID = UUID.randomUUID().toString(); guided = true; onSaved() } catch (failure: Exception) { error = failure.message } } }
                    Choice("Save another", dark = true) { saved = null; captureID = UUID.randomUUID().toString(); capturedInput = ""; input = ""; guided = status != FeatureStatus.AVAILABLE }
                }
            }
            if (messages.isEmpty() && !guided && !checking) Text("How can I help you today?\nPaste a link, save a thought, or search your vault.", color = Color.White, style = MaterialTheme.typography.headlineSmall)
        }
        if (!guided && saved == null && status == FeatureStatus.AVAILABLE) {
            Field(input, { input = it }, "Message Later AI…", true)
            Button(onClick = ::send, enabled = !busy && input.isNotBlank(), colors = ButtonDefaults.buttonColors(containerColor = LaterboxAccent, contentColor = Color.Black), modifier = Modifier.fillMaxWidth()) { Text("Send") }
            TextButton(onClick = { capturedInput = input; guided = true }) { Text("Guided capture", color = LaterboxAccent) }
        }
    }
    if (edit && saved != null) ItemDetailSheet(saved!!, onDismiss = { edit = false }, onChanged = { onSaved() })
}
