package com.example.laterbox.ui.ai

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.ArrowUpward
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.laterbox.data.DataRepository
import com.example.laterbox.data.local.ItemEntity
import com.example.laterbox.services.*
import com.example.laterbox.theme.LaterboxAccent
import com.example.laterbox.theme.LaterboxDarkSurface
import com.example.laterbox.ui.capture.*
import com.example.laterbox.ui.screens.ItemDetailSheet
import com.google.mlkit.genai.common.FeatureStatus
import kotlinx.coroutines.launch
import org.json.JSONArray
import java.util.UUID

@Composable
fun LaterAIScreen(
    repository: DataRepository,
    onDismiss: () -> Unit
) {
    val items by repository.items.collectAsState(initial = emptyList())
    BackHandler(onBack = onDismiss)

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF0C0C0D))
            .statusBarsPadding()
            .navigationBarsPadding()
            .imePadding()
    ) {
        LaterAIContent(
            items = items,
            onDismiss = onDismiss,
            onSaved = { repository.syncNow() }
        )
    }
}

@Composable
fun LaterAIContent(
    items: List<ItemEntity>,
    initial: String = "",
    attachments: String = "[]",
    onDismiss: () -> Unit,
    onSaved: () -> Unit = {}
) {
    val context = LocalContext.current
    val store = remember { VaultStore(context) }
    val ai = remember { LaterAIService(context) }
    val scope = rememberCoroutineScope()
    var status by remember { mutableIntStateOf(FeatureStatus.UNAVAILABLE) }
    var checking by remember { mutableStateOf(true) }
    var guided by rememberSaveable { mutableStateOf(false) }
    var input by rememberSaveable { mutableStateOf(initial) }
    var capturedInput by rememberSaveable { mutableStateOf(initial) }
    var saving by remember { mutableStateOf(false) }
    var busy by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    var saved by remember { mutableStateOf<ItemEntity?>(null) }
    var edit by remember { mutableStateOf(false) }
    var clarify by remember { mutableStateOf(false) }
    var returnQuestion by remember { mutableStateOf(false) }
    var matches by remember { mutableStateOf<List<ItemEntity>>(emptyList()) }
    val messages = remember { mutableStateListOf<Pair<String, Boolean>>() }
    var captureID by rememberSaveable { mutableStateOf(UUID.randomUUID().toString()) }

    val promptSuggestions = remember {
        listOf(
            "Summarize my unsorted inbox",
            "Which items have return dates this week?",
            "Find saved articles and guides",
            "Help me clean up old bookmarks"
        )
    }

    DisposableEffect(ai) { onDispose { ai.close() } }
    LaunchedEffect(ai) {
        status = runCatching { ai.status() }.getOrDefault(FeatureStatus.UNAVAILABLE)
        checking = false
        guided = status != FeatureStatus.AVAILABLE
    }

    fun save(item: ItemEntity) {
        if (saving) return
        saving = true
        busy = true
        error = null
        scope.launch {
            try {
                saved = store.save(item)
                guided = false
                clarify = false
                returnQuestion = item.returnAt == null
                messages.add("Saved ‘${saved?.title}’ to your vault." to false)
                onSaved()
                scope.launch { saved?.let { store.metadata(it); onSaved() } }
            } catch (failure: Exception) {
                error = failure.message ?: "Save failed. Your content is still here."
            } finally {
                saving = false
                busy = false
            }
        }
    }

    fun send(promptText: String = input) {
        if (promptText.isBlank() || busy) return
        val original = promptText
        capturedInput = original
        messages.add(original to true)
        busy = true
        error = null
        matches = emptyList()
        input = ""
        scope.launch {
            try {
                val action = ai.respond(original, items, messages.takeLast(4).joinToString("\n") { it.first })
                when (action.intent) {
                    "capture" -> {
                        val exact = action.content.takeIf { it.isNotBlank() && original.contains(it) } ?: original
                        var draft = VaultStore.draft(exact, action.title, action.tags, action.category, action.returnAt, attachments, captureID)
                        draft = draft.copy(summary = action.summary, formattedContent = action.formatted)
                        busy = false
                        save(draft)
                    }
                    "search" -> {
                        matches = LocalSearch.search(action.query.ifBlank { original }, items)
                        messages.add("Found ${matches.size} saved items." to false)
                    }
                    "clarify" -> {
                        clarify = true
                        messages.add("Would you like to save this or just chat?" to false)
                    }
                    else -> {
                        messages.add(action.reply to false)
                    }
                }
            } catch (failure: Exception) {
                error = failure.message ?: "The local model failed. Retry or continue manually."
            } finally {
                if (!saving) busy = false
            }
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 20.dp, vertical = 12.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        // Top Drag Handle (iOS style)
        Box(
            modifier = Modifier.fillMaxWidth(),
            contentAlignment = Alignment.Center
        ) {
            Box(
                modifier = Modifier
                    .width(38.dp)
                    .height(4.dp)
                    .background(Color(0xFF38383A), RoundedCornerShape(2.dp))
            )
        }

        // Header Bar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 4.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text(
                    text = "✦ Later AI",
                    color = Color.White,
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = if (status == FeatureStatus.AVAILABLE) {
                        if (SecureSettings(context).provider != "device" && AccountService.state.value.pro) {
                            "${SecureSettings(context).provider.replaceFirstChar { it.uppercase() }} · Your API key"
                        } else {
                            "On-device · Private & free"
                        }
                    } else {
                        "Guided capture"
                    },
                    color = Color(0xFFA1A1AA),
                    fontSize = 12.sp
                )
            }

            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                if (messages.isNotEmpty()) {
                    TextButton(onClick = { messages.clear(); saved = null; matches = emptyList(); clarify = false }) {
                        Text("Clear", color = Color(0xFFA1A1AA), fontSize = 13.sp)
                    }
                }
                IconButton(
                    onClick = onDismiss,
                    modifier = Modifier
                        .size(32.dp)
                        .background(Color.White.copy(alpha = 0.08f), CircleShape)
                ) {
                    Icon(
                        imageVector = Icons.Default.Close,
                        contentDescription = "Close",
                        tint = Color.White,
                        modifier = Modifier.size(16.dp)
                    )
                }
            }
        }

        // Main Scrollable Area
        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            if (attachments != "[]") {
                val files = runCatching { JSONArray(attachments) }.getOrNull()
                files?.let { values ->
                    for (index in 0 until values.length()) {
                        Choice("📎 ${values.getJSONObject(index).optString("name", "Shared file")}", "Attached to this capture", true) {}
                    }
                }
            }

            // Empty State (Glowing Brand Orb + Prompts like iOS)
            if (messages.isEmpty() && saved == null && !guided && !checking) {
                Spacer(modifier = Modifier.height(16.dp))

                Box(
                    modifier = Modifier.fillMaxWidth(),
                    contentAlignment = Alignment.Center
                ) {
                    Box(
                        modifier = Modifier
                            .size(120.dp)
                            .background(
                                Brush.radialGradient(
                                    listOf(LaterboxAccent.copy(alpha = 0.35f), Color.Transparent)
                                ),
                                CircleShape
                            ),
                        contentAlignment = Alignment.Center
                    ) {
                        Box(
                            modifier = Modifier
                                .size(68.dp)
                                .background(Color(0xFF1C1C1E), CircleShape)
                                .border(1.dp, Color.White.copy(alpha = 0.12f), CircleShape),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = Icons.Default.AutoAwesome,
                                contentDescription = null,
                                tint = LaterboxAccent,
                                modifier = Modifier.size(28.dp)
                            )
                        }
                    }
                }

                Text(
                    text = "How can I help you today?",
                    color = Color.White,
                    fontSize = 22.sp,
                    fontWeight = FontWeight.SemiBold,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth()
                )

                Text(
                    text = "Ask about your saved items, upcoming return dates, or organize your vault.",
                    color = Color.White.copy(alpha = 0.6f),
                    fontSize = 14.sp,
                    textAlign = TextAlign.Center,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 24.dp)
                )

                Spacer(modifier = Modifier.height(8.dp))

                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    promptSuggestions.forEach { prompt ->
                        Surface(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(14.dp))
                                .clickable { send(prompt) },
                            shape = RoundedCornerShape(14.dp),
                            color = Color(0xFF171717),
                            border = BorderStroke(1.dp, Color.White.copy(alpha = 0.08f))
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(horizontal = 16.dp, vertical = 14.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = prompt,
                                    fontSize = 14.sp,
                                    color = Color.White.copy(alpha = 0.9f),
                                    modifier = Modifier.weight(1f)
                                )
                                Icon(
                                    imageVector = Icons.AutoMirrored.Filled.ArrowForward,
                                    contentDescription = null,
                                    tint = Color.White.copy(alpha = 0.4f),
                                    modifier = Modifier.size(14.dp)
                                )
                            }
                        }
                    }
                }
            }

            // Messages List
            messages.forEach { (text, user) ->
                Box(
                    modifier = Modifier.fillMaxWidth(),
                    contentAlignment = if (user) Alignment.CenterEnd else Alignment.CenterStart
                ) {
                    Surface(
                        shape = RoundedCornerShape(16.dp),
                        color = if (user) Color(0xFF242424) else Color(0xFF141416),
                        border = if (user) null else BorderStroke(1.dp, Color.White.copy(alpha = 0.06f)),
                        modifier = Modifier.widthIn(max = 300.dp)
                    ) {
                        Text(
                            text = text,
                            color = Color.White,
                            fontSize = 14.sp,
                            modifier = Modifier.padding(14.dp)
                        )
                    }
                }
            }

            if (checking || busy) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    modifier = Modifier.padding(vertical = 4.dp)
                ) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(14.dp),
                        color = LaterboxAccent,
                        strokeWidth = 2.dp
                    )
                    Text(
                        text = if (checking) "Checking model…" else "Thinking…",
                        color = Color.White.copy(alpha = 0.6f),
                        fontSize = 12.sp
                    )
                }
            }

            if (status == FeatureStatus.DOWNLOADABLE && !busy) {
                Choice("Download on-device model", "Enable free Later AI on this device", true) {
                    scope.launch {
                        busy = true
                        try {
                            ai.download { error = it }
                            status = ai.status()
                            guided = status != FeatureStatus.AVAILABLE
                            error = null
                        } catch (failure: Exception) {
                            error = failure.message
                        } finally {
                            busy = false
                        }
                    }
                }
            }

            error?.let {
                Text(it, color = Color(0xFFFFB4AB))
                if (status == FeatureStatus.AVAILABLE) {
                    Choice("Retry", dark = true) { input = capturedInput; send() }
                }
                Choice("Continue manually", "Keep your content and attachments", true) { guided = true }
            }

            if (guided && saved == null && !checking) {
                key(captureID) { GuidedCapture(capturedInput, attachments, true, ::save) }
            }

            if (clarify) {
                Choice("Save this", dark = true) { save(VaultStore.draft(capturedInput, attachments = attachments, id = captureID)) }
                Choice("Just chatting", dark = true) { clarify = false; input = "" }
            }

            matches.forEach { item ->
                Choice(item.title.orEmpty(), item.summary, true) {
                    saved = item
                    edit = true
                    returnQuestion = false
                }
            }

            saved?.let { item ->
                if (returnQuestion) {
                    Text("When would you like to see it again?", color = Color.White)
                    ReturnChoices(true) { date ->
                        scope.launch {
                            try {
                                val updated = item.copy(returnAt = date, status = if (date == null) "inbox" else "deferred")
                                store.edit(updated)
                                saved = updated
                                returnQuestion = false
                                onSaved()
                            } catch (failure: Exception) {
                                error = failure.message
                            }
                        }
                    }
                } else {
                    Choice("Edit", "Review saved content and metadata", true) { edit = true }
                    Choice("Undo save", "Remove this capture", true) {
                        scope.launch {
                            try {
                                store.undo(item)
                                saved = null
                                captureID = UUID.randomUUID().toString()
                                guided = true
                                onSaved()
                            } catch (failure: Exception) {
                                error = failure.message
                            }
                        }
                    }
                    Choice("Save another", dark = true) {
                        saved = null
                        captureID = UUID.randomUUID().toString()
                        capturedInput = ""
                        input = ""
                        guided = status != FeatureStatus.AVAILABLE
                    }
                }
            }
        }

        // Bottom Chat Input Composer (iOS Style)
        if (!guided && saved == null) {
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(26.dp),
                color = Color(0xFF1C1C1E),
                border = BorderStroke(1.dp, Color.White.copy(alpha = 0.12f))
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 14.dp, vertical = 6.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    BasicTextField(
                        value = input,
                        onValueChange = { input = it },
                        singleLine = false,
                        maxLines = 4,
                        textStyle = TextStyle(
                            fontSize = 15.sp,
                            color = Color.White
                        ),
                        cursorBrush = SolidColor(LaterboxAccent),
                        modifier = Modifier.weight(1f),
                        decorationBox = { innerTextField ->
                            if (input.isEmpty()) {
                                Text(
                                    text = "Message Later AI…",
                                    fontSize = 15.sp,
                                    color = Color.White.copy(alpha = 0.4f)
                                )
                            }
                            innerTextField()
                        }
                    )

                    IconButton(
                        onClick = { send() },
                        enabled = !busy && input.isNotBlank(),
                        modifier = Modifier
                            .size(36.dp)
                            .background(
                                if (!busy && input.isNotBlank()) LaterboxAccent else Color.White.copy(alpha = 0.1f),
                                CircleShape
                            )
                    ) {
                        Icon(
                            imageVector = Icons.Default.ArrowUpward,
                            contentDescription = "Send",
                            tint = if (!busy && input.isNotBlank()) LaterboxDarkSurface else Color.White.copy(alpha = 0.3f),
                            modifier = Modifier.size(18.dp)
                        )
                    }
                }
            }

            if (status != FeatureStatus.AVAILABLE) {
                TextButton(
                    onClick = { capturedInput = input; guided = true },
                    modifier = Modifier.align(Alignment.CenterHorizontally)
                ) {
                    Text("Guided capture", color = LaterboxAccent, fontSize = 13.sp)
                }
            }
        }
    }

    if (edit && saved != null) {
        ItemDetailSheet(saved!!, onDismiss = { edit = false }, onChanged = { onSaved() })
    }
}
