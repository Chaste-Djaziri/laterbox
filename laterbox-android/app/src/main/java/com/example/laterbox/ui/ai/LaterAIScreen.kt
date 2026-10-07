package com.example.laterbox.ui.ai

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.automirrored.filled.Article
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
import androidx.compose.ui.platform.LocalDensity
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
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null
            ) { /* Absorb clicks to prevent click-through to underlying views */ }
            .statusBarsPadding()
            .windowInsetsPadding(WindowInsets.safeDrawing.only(WindowInsetsSides.Bottom))
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
    var guided by rememberSaveable { mutableStateOf(false) }
    var input by rememberSaveable { mutableStateOf(initial) }
    var capturedInput by rememberSaveable { mutableStateOf(initial) }
    var saving by remember { mutableStateOf(false) }
    var busy by remember { mutableStateOf(false) }
    var suggestGuided by remember { mutableStateOf(false) }
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

    fun save(item: ItemEntity) {
        if (saving) return
        saving = true
        busy = true
        suggestGuided = false
        scope.launch {
            try {
                saved = store.save(item)
                guided = false
                clarify = false
                returnQuestion = item.returnAt == null
                messages.add("Saved ‘${saved?.title}’ to your vault." to false)
                onSaved()
                scope.launch { saved?.let { store.metadata(it); onSaved() } }
            } catch (_: Exception) {
                messages.add("Something went wrong on our end. Please use Guided capture to save your content." to false)
                suggestGuided = true
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
        suggestGuided = false
        matches = emptyList()
        input = ""
        scope.launch {
            try {
                val action = ai.respond(original, items, messages.takeLast(4).joinToString("\n") { it.first })
                when (action.intent) {
                    "capture" -> {
                        val exact = action.content.takeIf { it.isNotBlank() && original.contains(it) } ?: original
                        val cleanTitle = action.title.ifBlank { original.lines().firstOrNull()?.take(50) ?: "Saved Note" }
                        var draft = VaultStore.draft(exact, cleanTitle, action.tags, action.category, action.returnAt, attachments, captureID)
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
                        messages.add(action.reply.ifBlank { "Would you like to save this or just chat?" } to false)
                    }
                    else -> {
                        messages.add(action.reply to false)
                    }
                }
            } catch (failure: Exception) {
                android.util.Log.e("LaterAI", "AI response failed", failure)
                messages.add("Something went wrong on our end. Please use Guided capture to save your content." to false)
                suggestGuided = true
            } finally {
                if (!saving) busy = false
            }
        }
    }

    val isImeVisible = WindowInsets.ime.getBottom(LocalDensity.current) > 0

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(start = 20.dp, end = 20.dp, top = 12.dp, bottom = if (isImeVisible) 8.dp else 12.dp),
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
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 4.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Surface(
                    shape = RoundedCornerShape(14.dp),
                    color = Color(0xFF1B1B1E),
                    border = BorderStroke(1.dp, Color.White.copy(alpha = 0.12f))
                ) {
                    Row(
                        modifier = Modifier.padding(3.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(2.dp)
                    ) {
                        // Later AI mode tab
                        Box(
                            modifier = Modifier
                                .clip(RoundedCornerShape(10.dp))
                                .background(if (!guided) LaterboxAccent else Color.Transparent)
                                .clickable { guided = false }
                                .padding(horizontal = 9.dp, vertical = 5.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(4.dp)
                            ) {
                                Icon(
                                    imageVector = Icons.Default.AutoAwesome,
                                    contentDescription = null,
                                    tint = if (!guided) LaterboxDarkSurface else Color.White.copy(alpha = 0.6f),
                                    modifier = Modifier.size(13.dp)
                                )
                                Text(
                                    text = "Later AI",
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = if (!guided) LaterboxDarkSurface else Color.White.copy(alpha = 0.7f)
                                )
                            }
                        }

                        // Guided Capture mode tab
                        Box(
                            modifier = Modifier
                                .clip(RoundedCornerShape(10.dp))
                                .background(if (guided) LaterboxAccent else Color.Transparent)
                                .clickable {
                                    guided = true
                                    capturedInput = input
                                }
                                .padding(horizontal = 9.dp, vertical = 5.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(4.dp)
                            ) {
                                Icon(
                                    imageVector = Icons.AutoMirrored.Filled.Article,
                                    contentDescription = null,
                                    tint = if (guided) LaterboxDarkSurface else Color.White.copy(alpha = 0.6f),
                                    modifier = Modifier.size(13.dp)
                                )
                                Text(
                                    text = "Guided",
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = if (guided) LaterboxDarkSurface else Color.White.copy(alpha = 0.7f)
                                )
                            }
                        }
                    }
                }

                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    if (messages.isNotEmpty()) {
                        TextButton(onClick = { messages.clear(); saved = null; matches = emptyList(); clarify = false; suggestGuided = false }) {
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

            Text(
                text = if (guided) {
                    "Step-by-step structured capture"
                } else if (AccountService.state.value.pro) {
                    val customKey = SecureSettings(context).apiKey()
                    if (customKey.isNotBlank()) {
                        "${SecureSettings(context).provider.replaceFirstChar { it.uppercase() }} · Pro enabled"
                    } else {
                        "Gemini AI · Pro enabled"
                    }
                } else {
                    "Later Assistant · Standard"
                },
                color = Color(0xFFA1A1AA),
                fontSize = 11.sp,
                modifier = Modifier.padding(start = 2.dp)
            )
        }

        if (guided && saved == null) {
            key(captureID) {
                GuidedCapture(
                    initial = capturedInput,
                    attachments = attachments,
                    dark = true,
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxWidth(),
                    onSave = ::save
                )
            }
        } else {
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

                if (busy) {
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
                            text = "Thinking…",
                            color = Color.White.copy(alpha = 0.6f),
                            fontSize = 12.sp
                        )
                    }
                }

                if (suggestGuided) {
                    Choice("Switch to Guided capture", "Keep your input and save step-by-step", dark = true) {
                        guided = true
                        suggestGuided = false
                    }
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
                                } catch (_: Exception) {
                                    messages.add("Something went wrong on our end. Please use Guided capture to save your content." to false)
                                    suggestGuided = true
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
                                } catch (_: Exception) {
                                    messages.add("Something went wrong on our end. Please use Guided capture to save your content." to false)
                                    suggestGuided = true
                                }
                            }
                        }
                        Choice("Save another", dark = true) {
                            saved = null
                            captureID = UUID.randomUUID().toString()
                            capturedInput = ""
                            input = ""
                            suggestGuided = false
                        }
                    }
                }
            }

            // Bottom Chat Input Composer (iOS Style) with floating suggestions above keyboard
            if (!guided && saved == null) {
            Column(
                modifier = Modifier.fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                if (messages.isEmpty()) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .horizontalScroll(rememberScrollState()),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        promptSuggestions.forEach { prompt ->
                            Surface(
                                shape = RoundedCornerShape(26.dp),
                                color = Color(0xFF1C1C1E),
                                border = BorderStroke(1.dp, Color.White.copy(alpha = 0.12f)),
                                modifier = Modifier
                                    .clip(RoundedCornerShape(26.dp))
                                    .clickable { send(prompt) }
                            ) {
                                Row(
                                    modifier = Modifier.padding(horizontal = 14.dp, vertical = 8.dp),
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                                ) {
                                    Text(
                                        text = prompt,
                                        fontSize = 12.sp,
                                        fontWeight = FontWeight.Medium,
                                        color = Color.White.copy(alpha = 0.85f)
                                    )
                                    Icon(
                                        imageVector = Icons.AutoMirrored.Filled.ArrowForward,
                                        contentDescription = null,
                                        tint = LaterboxAccent,
                                        modifier = Modifier.size(12.dp)
                                    )
                                }
                            }
                        }
                    }
                }

                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(26.dp),
                    color = Color(0xFF1C1C1E),
                    border = BorderStroke(1.dp, Color.White.copy(alpha = 0.12f))
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(start = 16.dp, end = 6.dp, top = 6.dp, bottom = 6.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .padding(vertical = 6.dp),
                            contentAlignment = Alignment.CenterStart
                        ) {
                            BasicTextField(
                                value = input,
                                onValueChange = { input = it },
                                singleLine = false,
                                maxLines = 4,
                                textStyle = TextStyle(
                                    fontSize = 15.sp,
                                    lineHeight = 20.sp,
                                    color = Color.White
                                ),
                                cursorBrush = SolidColor(LaterboxAccent),
                                modifier = Modifier.fillMaxWidth(),
                                decorationBox = { innerTextField ->
                                    Box(contentAlignment = Alignment.CenterStart) {
                                        if (input.isEmpty()) {
                                            Text(
                                                text = "Message Later AI…",
                                                fontSize = 15.sp,
                                                lineHeight = 20.sp,
                                                color = Color.White.copy(alpha = 0.4f)
                                            )
                                        }
                                        innerTextField()
                                    }
                                }
                            )
                        }

                        Box(
                            modifier = Modifier
                                .size(36.dp)
                                .clip(CircleShape)
                            .background(
                                if (!busy && input.isNotBlank()) LaterboxAccent else Color.White.copy(alpha = 0.1f)
                            )
                            .clickable(enabled = !busy && input.isNotBlank()) { send() },
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = Icons.Default.ArrowUpward,
                                contentDescription = "Send",
                                tint = if (!busy && input.isNotBlank()) LaterboxDarkSurface else Color.White.copy(alpha = 0.35f),
                                modifier = Modifier.size(18.dp)
                            )
                        }
                    }
                }
            }
        }
    }

    }

    if (edit && saved != null) {
        ItemDetailSheet(saved!!, onDismiss = { edit = false }, onChanged = { onSaved() })
    }
}
