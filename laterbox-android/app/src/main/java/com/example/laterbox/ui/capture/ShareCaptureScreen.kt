package com.example.laterbox.ui.capture

import android.app.DatePickerDialog
import android.app.TimePickerDialog
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.OpenInNew
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.automirrored.filled.Undo
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import coil.compose.AsyncImage
import com.example.laterbox.data.DefaultDataRepository
import com.example.laterbox.data.local.AppDatabase
import com.example.laterbox.data.local.ItemEntity
import com.example.laterbox.services.AppLockService
import com.example.laterbox.services.VaultStore
import com.example.laterbox.theme.LaterboxAccent
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.jsoup.Jsoup
import java.net.URI
import java.text.SimpleDateFormat
import java.time.DayOfWeek
import java.time.Duration
import java.time.Instant
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.temporal.TemporalAdjusters
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.UUID

data class ShareChatMessage(
    val id: String = UUID.randomUUID().toString(),
    val text: String,
    val isUser: Boolean,
    val timestamp: Long = System.currentTimeMillis()
)

data class ShareOptionItem(
    val id: String = UUID.randomUUID().toString(),
    val title: String,
    val subtitle: String? = null,
    val icon: ImageVector? = null,
    val isPrimary: Boolean = false,
    val action: () -> Unit
)

data class ShareAttachmentItem(
    val name: String,
    val path: String,
    val mime: String,
    val size: Long
)

@Composable
fun ShareCaptureScreen(
    initialText: String,
    attachmentsJson: String,
    isLockedInitially: Boolean,
    onClose: () -> Unit
) {
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()
    val store = remember { VaultStore(context) }
    val repository = remember { DefaultDataRepository(context, AppDatabase.getDatabase(context)) }

    var locked by remember { mutableStateOf(isLockedInitially) }

    // Draft State
    val captureId = remember { UUID.randomUUID().toString() }
    var title by remember { mutableStateOf("") }
    var content by remember { mutableStateOf(initialText) }
    var category by remember { mutableStateOf("") }
    var tags by remember { mutableStateOf<List<String>>(emptyList()) }
    var summary by remember { mutableStateOf("") }
    var resolvedType by remember { mutableStateOf("link") }
    var previewImageUrl by remember { mutableStateOf<String?>(null) }
    var siteName by remember { mutableStateOf<String?>(null) }
    var returnAt by remember { mutableStateOf<String?>(null) }

    var savedItem by remember { mutableStateOf<ItemEntity?>(null) }
    var needsReturnDate by remember { mutableStateOf(false) }
    var isLoading by remember { mutableStateOf(true) }
    var isSaving by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    var showEditSheet by remember { mutableStateOf(false) }
    var showManualInput by remember { mutableStateOf(false) }
    var manualInputText by remember { mutableStateOf("") }

    val messages = remember { mutableStateListOf<ShareChatMessage>() }
    val scrollState = rememberScrollState()

    // Parse attachments
    val attachments = remember(attachmentsJson) {
        val list = mutableListOf<ShareAttachmentItem>()
        runCatching {
            val jsonArray = JSONArray(attachmentsJson)
            for (i in 0 until jsonArray.length()) {
                val obj = jsonArray.getJSONObject(i)
                list.add(
                    ShareAttachmentItem(
                        name = obj.optString("name", "File"),
                        path = obj.optString("path", ""),
                        mime = obj.optString("mime", "application/octet-stream"),
                        size = obj.optLong("size", 0L)
                    )
                )
            }
        }
        list
    }

    // Detected URL
    val detectedUrl = remember(content) {
        Regex("https?://[^\\s]+").find(content)?.value
    }

    // Reset Function
    fun resetDraft() {
        messages.clear()
        savedItem = null
        returnAt = null
        errorMessage = null
        needsReturnDate = true
        showManualInput = false
        val tagSummary = if (tags.isEmpty()) "" else " with tags " + tags.take(3).joinToString(" ") { "#$it" }
        val prompt = "I've drafted ‘$title’$tagSummary. When would you like to see it again?"
        messages.add(ShareChatMessage(text = prompt, isUser = false))
    }

    // Initial enrichment on load
    LaunchedEffect(Unit) {
        isLoading = true
        withContext(Dispatchers.IO) {
            var rawTitle = ""
            var rawSummary = ""
            var rawKeywords: String? = null
            var rawImage: String? = null
            var rawSite: String? = null

            if (detectedUrl != null) {
                runCatching {
                    val doc = Jsoup.connect(detectedUrl).timeout(7000).maxBodySize(1024 * 1024).get()
                    val ogTitle = doc.selectFirst("meta[property=og:title]")?.attr("content")?.takeIf { it.isNotBlank() }
                    val pageTitle = doc.title().takeIf { it.isNotBlank() }
                    rawTitle = ogTitle ?: pageTitle.orEmpty()

                    rawSummary = doc.selectFirst("meta[property=og:description], meta[name=description]")?.attr("content").orEmpty()
                    rawKeywords = doc.selectFirst("meta[name=keywords]")?.attr("content")
                    rawImage = doc.selectFirst("meta[property=og:image]")?.attr("content")
                    rawSite = doc.selectFirst("meta[property=og:site_name]")?.attr("content")
                    if (rawSite.isNullOrBlank()) {
                        rawSite = runCatching { URI(detectedUrl).host?.removePrefix("www.") }.getOrNull()
                    }
                }
            }

            val fallbackTitle = when {
                rawTitle.isNotBlank() -> rawTitle
                attachments.isNotEmpty() -> attachments.first().name.substringBeforeLast('.')
                content.isNotBlank() -> content.lines().firstOrNull()?.trim()?.take(80) ?: "Shared Item"
                else -> "Shared Item"
            }

            val inferredTags = mutableListOf<String>()
            if (!rawKeywords.isNullOrBlank()) {
                val parsed = rawKeywords.split(",").map { it.trim().lowercase() }.filter { it.isNotBlank() }.distinct().take(4)
                inferredTags.addAll(parsed)
            }
            if (detectedUrl != null) {
                val host = runCatching { URI(detectedUrl).host?.lowercase().orEmpty() }.getOrDefault("")
                if (host.contains("youtube") || host.contains("youtu.be")) {
                    inferredTags.add("video")
                    inferredTags.add("youtube")
                } else if (host.contains("github")) {
                    inferredTags.add("github")
                    inferredTags.add("dev")
                } else if (host.contains("twitter") || host.contains("x.com")) {
                    inferredTags.add("social")
                }
            }
            if (attachments.isNotEmpty()) {
                inferredTags.add("file")
            }

            val inferredCategory = when {
                detectedUrl != null && (detectedUrl.contains("youtube") || detectedUrl.contains("vimeo")) -> "Video"
                detectedUrl != null && (detectedUrl.contains("medium") || detectedUrl.contains("substack")) -> "Reading"
                attachments.isNotEmpty() -> "Files"
                else -> "Inbox"
            }

            withContext(Dispatchers.Main) {
                title = fallbackTitle
                summary = rawSummary
                previewImageUrl = rawImage
                siteName = rawSite
                category = inferredCategory
                tags = inferredTags.distinct()
                resolvedType = when {
                    attachments.isNotEmpty() -> "document"
                    detectedUrl != null && (detectedUrl.contains("youtube") || detectedUrl.contains("vimeo")) -> "video"
                    detectedUrl != null -> "link"
                    else -> "note"
                }
                isLoading = false
                resetDraft()
            }
        }
    }

    // Auto-scroll when messages change
    LaunchedEffect(messages.size, isLoading, showManualInput) {
        scrollState.animateScrollTo(scrollState.maxValue)
    }

    // Schedule and Save Handler
    fun scheduleAndSave(instant: String?, optionLabel: String) {
        if (isSaving) return
        isSaving = true
        errorMessage = null

        // Add user response bubble
        messages.add(ShareChatMessage(text = optionLabel, isUser = true))

        coroutineScope.launch {
            try {
                returnAt = instant
                val draft = VaultStore.draft(
                    content = content.ifBlank { title },
                    title = title,
                    tags = tags.joinToString(", "),
                    category = category,
                    returnAt = instant,
                    attachments = attachmentsJson,
                    id = captureId,
                    type = resolvedType,
                    summary = summary
                )
                val saved = store.save(draft)
                savedItem = saved
                repository.syncNow()

                withContext(Dispatchers.IO) {
                    store.metadata(draft)
                }

                needsReturnDate = false
                val scheduleDesc = if (instant != null) " ($optionLabel)" else " with no reminder (inbox)"
                messages.add(
                    ShareChatMessage(
                        text = "Scheduled ‘${draft.title}’$scheduleDesc. Saved to your LaterBox vault.",
                        isUser = false
                    )
                )
            } catch (e: Exception) {
                errorMessage = e.message ?: "Failed to save item"
            } finally {
                isSaving = false
            }
        }
    }

    // Custom Date Picker Dialog
    fun openCustomDateTimePicker() {
        val now = Calendar.getInstance()
        DatePickerDialog(
            context,
            { _, year, month, dayOfMonth ->
                TimePickerDialog(
                    context,
                    { _, hourOfDay, minute ->
                        val chosen = Calendar.getInstance().apply {
                            set(Calendar.YEAR, year)
                            set(Calendar.MONTH, month)
                            set(Calendar.DAY_OF_MONTH, dayOfMonth)
                            set(Calendar.HOUR_OF_DAY, hourOfDay)
                            set(Calendar.MINUTE, minute)
                            set(Calendar.SECOND, 0)
                        }
                        val instantStr = chosen.toInstant().toString()
                        val formatter = SimpleDateFormat("MMM d, h:mm a", Locale.getDefault())
                        val label = formatter.format(chosen.time)
                        scheduleAndSave(instantStr, label)
                    },
                    now.get(Calendar.HOUR_OF_DAY),
                    now.get(Calendar.MINUTE),
                    false
                ).show()
            },
            now.get(Calendar.YEAR),
            now.get(Calendar.MONTH),
            now.get(Calendar.DAY_OF_MONTH)
        ).show()
    }

    // Manual Input Submit Handler
    fun handleManualInput() {
        val text = manualInputText.trim()
        if (text.isBlank() || isSaving) return
        manualInputText = ""
        showManualInput = false

        val lower = text.lowercase()
        when {
            lower.contains("10 min") || lower.contains("ten min") -> {
                val instant = Instant.now().plusSeconds(600).toString()
                scheduleAndSave(instant, "In 10 minutes")
            }
            lower.contains("1 hour") || lower.contains("one hour") || lower.contains("an hour") -> {
                val instant = Instant.now().plusSeconds(3600).toString()
                scheduleAndSave(instant, "In 1 hour")
            }
            lower.contains("tomorrow") -> {
                val instant = LocalDate.now().plusDays(1).atTime(9, 0)
                    .atZone(ZoneId.systemDefault()).toInstant().toString()
                scheduleAndSave(instant, "Tomorrow 9:00 AM")
            }
            lower.contains("weekend") -> {
                val instant = LocalDate.now().with(TemporalAdjusters.next(DayOfWeek.SATURDAY)).atTime(9, 0)
                    .atZone(ZoneId.systemDefault()).toInstant().toString()
                scheduleAndSave(instant, "This weekend")
            }
            lower.contains("next week") -> {
                val instant = LocalDate.now().plusDays(7).atTime(9, 0)
                    .atZone(ZoneId.systemDefault()).toInstant().toString()
                scheduleAndSave(instant, "Next week")
            }
            lower.contains("no reminder") || lower.contains("inbox") || lower.contains("none") -> {
                scheduleAndSave(null, "No reminder")
            }
            else -> {
                // Treated as a note or instruction
                messages.add(ShareChatMessage(text = text, isUser = true))
                if (savedItem == null) {
                    summary = if (summary.isBlank()) text else "$summary\n$text"
                    scheduleAndSave(null, text)
                } else {
                    coroutineScope.launch {
                        val current = savedItem ?: return@launch
                        val updatedNotes = if (current.notes.isBlank()) text else "${current.notes}\n$text"
                        val updated = current.copy(notes = updatedNotes, summary = updatedNotes)
                        store.edit(updated)
                        repository.syncNow()
                        savedItem = updated
                        messages.add(
                            ShareChatMessage(
                                text = "Added note to ‘${updated.title}’. Saved to your vault.",
                                isUser = false
                            )
                        )
                    }
                }
            }
        }
    }

    // Generate Active Options Dock matching iOS
    val activeOptions = remember(needsReturnDate, savedItem, isLoading) {
        if (isLoading) return@remember emptyList<ShareOptionItem>()

        if (needsReturnDate) {
            val list = mutableListOf<ShareOptionItem>()
            // In 10 Minutes
            list.add(
                ShareOptionItem(
                    title = "In 10 Minutes",
                    subtitle = "Quick return",
                    icon = Icons.Default.Timer,
                    isPrimary = true,
                    action = {
                        val instant = Instant.now().plusSeconds(600).toString()
                        scheduleAndSave(instant, "In 10 minutes")
                    }
                )
            )
            // In 1 Hour
            list.add(
                ShareOptionItem(
                    title = "In 1 Hour",
                    subtitle = "Later today",
                    icon = Icons.Default.Schedule,
                    isPrimary = false,
                    action = {
                        val instant = Instant.now().plusSeconds(3600).toString()
                        scheduleAndSave(instant, "In 1 hour")
                    }
                )
            )
            // Tomorrow
            list.add(
                ShareOptionItem(
                    title = "Tomorrow",
                    subtitle = "9:00 AM",
                    icon = Icons.Default.CalendarToday,
                    isPrimary = false,
                    action = {
                        val instant = LocalDate.now().plusDays(1).atTime(9, 0)
                            .atZone(ZoneId.systemDefault()).toInstant().toString()
                        scheduleAndSave(instant, "Tomorrow")
                    }
                )
            )
            // This Weekend
            list.add(
                ShareOptionItem(
                    title = "This Weekend",
                    subtitle = "Saturday 9 AM",
                    icon = Icons.Default.WbSunny,
                    isPrimary = false,
                    action = {
                        val instant = LocalDate.now().with(TemporalAdjusters.next(DayOfWeek.SATURDAY)).atTime(9, 0)
                            .atZone(ZoneId.systemDefault()).toInstant().toString()
                        scheduleAndSave(instant, "This weekend")
                    }
                )
            )
            // Next Week
            list.add(
                ShareOptionItem(
                    title = "Next Week",
                    subtitle = "7 days from now",
                    icon = Icons.Default.DateRange,
                    isPrimary = false,
                    action = {
                        val instant = LocalDate.now().plusDays(7).atTime(9, 0)
                            .atZone(ZoneId.systemDefault()).toInstant().toString()
                        scheduleAndSave(instant, "Next week")
                    }
                )
            )
            // No Reminder
            list.add(
                ShareOptionItem(
                    title = "No Reminder",
                    subtitle = "Inbox only",
                    icon = Icons.Default.Inbox,
                    isPrimary = false,
                    action = {
                        scheduleAndSave(null, "No reminder")
                    }
                )
            )
            // Choose Date
            list.add(
                ShareOptionItem(
                    title = "Choose Date",
                    subtitle = "Pick date & time",
                    icon = Icons.Default.Tune,
                    isPrimary = false,
                    action = {
                        openCustomDateTimePicker()
                    }
                )
            )
            if (savedItem != null) {
                list.add(
                    ShareOptionItem(
                        title = "Keep Current",
                        subtitle = "Keep schedule",
                        icon = Icons.AutoMirrored.Filled.ArrowBack,
                        isPrimary = false,
                        action = {
                            messages.add(ShareChatMessage(text = "Keep current schedule", isUser = true))
                            needsReturnDate = false
                        }
                    )
                )
            }
            list
        } else if (savedItem != null) {
            listOf(
                ShareOptionItem(
                    title = "Done",
                    subtitle = "Close LaterBox",
                    icon = Icons.Default.CheckCircle,
                    isPrimary = true,
                    action = { onClose() }
                ),
                ShareOptionItem(
                    title = "Change Return",
                    subtitle = "Reschedule date",
                    icon = Icons.Default.CalendarToday,
                    isPrimary = false,
                    action = {
                        messages.add(ShareChatMessage(text = "Change return date", isUser = true))
                        messages.add(ShareChatMessage(text = "When would you like to see it again?", isUser = false))
                        needsReturnDate = true
                    }
                ),
                ShareOptionItem(
                    title = "Edit Details",
                    subtitle = "Title & tags",
                    icon = Icons.Default.Edit,
                    isPrimary = false,
                    action = { showEditSheet = true }
                ),
                ShareOptionItem(
                    title = "Undo Save",
                    subtitle = "Remove from vault",
                    icon = Icons.AutoMirrored.Filled.Undo,
                    isPrimary = false,
                    action = {
                        messages.add(ShareChatMessage(text = "Undo save", isUser = true))
                        val toUndo = savedItem
                        if (toUndo != null) {
                            coroutineScope.launch {
                                store.undo(toUndo)
                                repository.syncNow()
                                savedItem = null
                                needsReturnDate = false
                                messages.add(
                                    ShareChatMessage(
                                        text = "Removed ‘${toUndo.title}’ from your vault. You can save again whenever you're ready.",
                                        isUser = false
                                    )
                                )
                            }
                        }
                    }
                )
            )
        } else {
            // Unsaved state (e.g. after undo)
            listOf(
                ShareOptionItem(
                    title = "Save to Vault",
                    subtitle = "Store item",
                    icon = Icons.Default.Download,
                    isPrimary = true,
                    action = {
                        messages.add(ShareChatMessage(text = "Save to vault", isUser = true))
                        messages.add(ShareChatMessage(text = "When would you like to see it again?", isUser = false))
                        needsReturnDate = true
                    }
                ),
                ShareOptionItem(
                    title = "Edit Details",
                    subtitle = "Title & tags",
                    icon = Icons.Default.Edit,
                    isPrimary = false,
                    action = { showEditSheet = true }
                ),
                ShareOptionItem(
                    title = "Done",
                    subtitle = "Close",
                    icon = Icons.Default.Close,
                    isPrimary = false,
                    action = { onClose() }
                )
            )
        }
    }

    val optionsTitle = remember(needsReturnDate, savedItem) {
        when {
            needsReturnDate -> "WHEN WOULD YOU LIKE TO RETURN?"
            savedItem != null -> "SAVED ITEM OPTIONS"
            else -> "QUICK OPTIONS"
        }
    }

    // App Lock Guard
    if (locked) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                "Unlock to save to your private vault",
                color = Color.White,
                fontWeight = FontWeight.Bold,
                fontSize = 16.sp
            )
            Button(
                onClick = {
                    AppLockService.authenticate(
                        context as androidx.fragment.app.FragmentActivity,
                        { locked = false },
                        {}
                    )
                },
                colors = ButtonDefaults.buttonColors(
                    containerColor = LaterboxAccent,
                    contentColor = Color(0xFF171711)
                )
            ) {
                Text("Unlock LaterBox", fontWeight = FontWeight.Bold)
            }
            TextButton(onClick = onClose) {
                Text("Cancel", color = Color.White.copy(alpha = 0.6f))
            }
        }
        return
    }

    // Main Share UI Layout (iOS Style AI layout popup)
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
    ) {
        Column(
            modifier = Modifier.fillMaxSize()
        ) {
            // Scrollable Body Content
            Column(
                modifier = Modifier
                    .weight(1f)
                    .verticalScroll(scrollState)
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Shared Preview Card (matches top of screenshot)
                SharePreviewCard(
                    title = title,
                    previewImageUrl = previewImageUrl,
                    siteName = siteName,
                    attachments = attachments,
                    returnAt = returnAt,
                    onClearReturn = {
                        returnAt = null
                        val currentSaved = savedItem
                        if (currentSaved != null) {
                            coroutineScope.launch {
                                val updated = currentSaved.copy(returnAt = null, status = "inbox")
                                store.edit(updated)
                                repository.syncNow()
                                savedItem = updated
                            }
                        }
                    }
                )

                // Message transcript bubbles (matches chat rows in screenshot)
                messages.forEach { msg ->
                    ShareMessageBubble(message = msg)
                }

                // Loading Indicator
                if (isLoading) {
                    Row(
                        modifier = Modifier
                            .clip(RoundedCornerShape(14.dp))
                            .background(Color(0xFF1E1E22))
                            .padding(horizontal = 14.dp, vertical = 10.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(14.dp),
                            color = LaterboxAccent,
                            strokeWidth = 2.dp
                        )
                        Text(
                            text = "Preparing draft...",
                            fontSize = 13.sp,
                            color = Color.White.copy(alpha = 0.75f)
                        )
                    }
                }

                // Error Message Banner
                errorMessage?.let { err ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(12.dp))
                            .background(Color(0xFF331515))
                            .border(1.dp, Color(0xFFE53E3E).copy(alpha = 0.4f), RoundedCornerShape(12.dp))
                            .padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.Warning,
                            contentDescription = null,
                            tint = Color(0xFFFC8181),
                            modifier = Modifier.size(18.dp)
                        )
                        Text(
                            text = err,
                            fontSize = 13.sp,
                            color = Color(0xFFFEB2B2)
                        )
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))
            }

            // Bottom Area: Options Popups Dock (matches bottom of screenshot)
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(Color.Black)
            ) {
                // Header Row: SAVED ITEM OPTIONS + Type instead
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 6.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = optionsTitle,
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.White.copy(alpha = 0.65f),
                        letterSpacing = 0.6.sp
                    )

                    Row(
                        modifier = Modifier
                            .clip(RoundedCornerShape(8.dp))
                            .clickable { showManualInput = !showManualInput }
                            .padding(horizontal = 4.dp, vertical = 2.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.Edit,
                            contentDescription = "Type instead",
                            tint = Color.White.copy(alpha = 0.55f),
                            modifier = Modifier.size(12.dp)
                        )
                        Text(
                            text = if (showManualInput) "Options" else "Type instead",
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Medium,
                            color = Color.White.copy(alpha = 0.55f)
                        )
                    }
                }

                // If "Type instead" is active, show inline input field
                if (showManualInput) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp, vertical = 6.dp)
                            .clip(RoundedCornerShape(16.dp))
                            .background(Color(0xFF1E1E22))
                            .border(1.dp, Color.White.copy(alpha = 0.12f), RoundedCornerShape(16.dp))
                            .padding(horizontal = 14.dp, vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        BasicTextField(
                            value = manualInputText,
                            onValueChange = { manualInputText = it },
                            textStyle = TextStyle(color = Color.White, fontSize = 14.sp),
                            cursorBrush = SolidColor(LaterboxAccent),
                            modifier = Modifier.weight(1f),
                            decorationBox = { inner ->
                                if (manualInputText.isEmpty()) {
                                    Text("Type instructions or schedule...", color = Color.White.copy(alpha = 0.35f), fontSize = 13.5.sp)
                                }
                                inner()
                            }
                        )

                        IconButton(
                            onClick = { handleManualInput() },
                            modifier = Modifier.size(30.dp)
                        ) {
                            Icon(
                                imageVector = Icons.AutoMirrored.Filled.Send,
                                contentDescription = "Send",
                                tint = if (manualInputText.isNotBlank()) LaterboxAccent else Color.White.copy(alpha = 0.3f),
                                modifier = Modifier.size(16.dp)
                            )
                        }
                    }
                } else {
                    // Option Pills row (exact match to screenshot)
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .horizontalScroll(rememberScrollState())
                            .padding(horizontal = 16.dp, vertical = 6.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        activeOptions.forEach { opt ->
                            Surface(
                                shape = RoundedCornerShape(18.dp),
                                color = if (opt.isPrimary) LaterboxAccent else Color(0xFF1E1E22),
                                border = BorderStroke(
                                    1.dp,
                                    if (opt.isPrimary) Color.Black.copy(alpha = 0.12f) else Color.White.copy(alpha = 0.12f)
                                ),
                                modifier = Modifier.clickable { opt.action() }
                            ) {
                                Row(
                                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 10.dp),
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                                ) {
                                    opt.icon?.let { iconVec ->
                                        Icon(
                                            imageVector = iconVec,
                                            contentDescription = null,
                                            tint = if (opt.isPrimary) Color(0xFF171711) else Color.White,
                                            modifier = Modifier.size(16.dp)
                                        )
                                    }
                                    Column(verticalArrangement = Arrangement.spacedBy(1.dp)) {
                                        Text(
                                            text = opt.title,
                                            fontSize = 14.sp,
                                            fontWeight = FontWeight.SemiBold,
                                            color = if (opt.isPrimary) Color(0xFF171711) else Color.White
                                        )
                                        opt.subtitle?.let { sub ->
                                            Text(
                                                text = sub,
                                                fontSize = 10.sp,
                                                color = if (opt.isPrimary) Color(0xFF171711).copy(alpha = 0.7f) else Color.White.copy(alpha = 0.55f)
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Disclaimer at the very bottom (exact match to screenshot)
                Text(
                    text = "Later AI can make mistakes. Verify important info.",
                    fontSize = 11.sp,
                    color = Color.White.copy(alpha = 0.35f),
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(top = 4.dp, bottom = 10.dp),
                    textAlign = androidx.compose.ui.text.style.TextAlign.Center
                )
            }
        }

        // Edit Details Dialog Sheet
        if (showEditSheet) {
            ShareEditDetailsDialog(
                initialTitle = title,
                initialContent = content,
                initialCategory = category,
                initialTags = tags,
                onDismiss = { showEditSheet = false },
                onSave = { newTitle, newContent, newCategory, newTags ->
                    title = newTitle
                    content = newContent
                    category = newCategory
                    tags = newTags
                    showEditSheet = false

                    val current = savedItem
                    if (current != null) {
                        coroutineScope.launch {
                            val updated = current.copy(
                                title = newTitle,
                                textContent = newContent,
                                category = newCategory,
                                tags = newTags.joinToString(", ")
                            )
                            store.edit(updated)
                            repository.syncNow()
                            savedItem = updated
                            messages.add(
                                ShareChatMessage(
                                    text = "Updated details for ‘$newTitle’.",
                                    isUser = false
                                )
                            )
                        }
                    } else {
                        messages.add(
                            ShareChatMessage(
                                text = "Updated details for ‘$newTitle’.",
                                isUser = false
                            )
                        )
                    }
                }
            )
        }
    }
}

// Preview Card Component matching iOS screenshot
@Composable
private fun SharePreviewCard(
    title: String,
    previewImageUrl: String?,
    siteName: String?,
    attachments: List<ShareAttachmentItem>,
    returnAt: String?,
    onClearReturn: () -> Unit
) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        // Web banner image with gradient overlay
        if (!previewImageUrl.isNullOrBlank()) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(136.dp)
                    .clip(RoundedCornerShape(16.dp))
                    .background(Color(0xFF1E1E22))
            ) {
                AsyncImage(
                    model = previewImageUrl,
                    contentDescription = null,
                    contentScale = ContentScale.Crop,
                    modifier = Modifier.fillMaxSize()
                )
                // Gradient Overlay
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(
                            Brush.verticalGradient(
                                colors = listOf(Color.Transparent, Color.Black.copy(alpha = 0.88f)),
                                startY = 40f
                            )
                        )
                )
                // Bottom content row
                Row(
                    modifier = Modifier
                        .align(Alignment.BottomStart)
                        .fillMaxWidth()
                        .padding(horizontal = 14.dp, vertical = 12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Language,
                        contentDescription = null,
                        tint = LaterboxAccent,
                        modifier = Modifier.size(16.dp)
                    )
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = title,
                            fontSize = 14.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = Color.White,
                            maxLines = 1
                        )
                        if (!siteName.isNullOrBlank()) {
                            Text(
                                text = siteName,
                                fontSize = 11.5.sp,
                                color = Color.White.copy(alpha = 0.65f),
                                maxLines = 1
                            )
                        }
                    }
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.OpenInNew,
                        contentDescription = null,
                        tint = Color.White.copy(alpha = 0.75f),
                        modifier = Modifier.size(15.dp)
                    )
                }
            }
        }

        // Attachments pills
        attachments.forEach { file ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(12.dp))
                    .background(Color(0xFF1B1B1E))
                    .border(1.dp, Color.White.copy(alpha = 0.08f), RoundedCornerShape(12.dp))
                    .padding(horizontal = 14.dp, vertical = 10.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.AttachFile,
                    contentDescription = null,
                    tint = LaterboxAccent,
                    modifier = Modifier.size(16.dp)
                )
                Text(
                    text = file.name,
                    fontSize = 13.5.sp,
                    fontWeight = FontWeight.Medium,
                    color = Color.White,
                    maxLines = 1,
                    modifier = Modifier.weight(1f)
                )
            }
        }

        // Return Countdown Badge
        if (!returnAt.isNullOrBlank()) {
            val formatted = remember(returnAt) {
                runCatching {
                    val instant = Instant.parse(returnAt)
                    val local = LocalDateTime.ofInstant(instant, ZoneId.systemDefault())
                    val dtf = DateTimeFormatter.ofPattern("MMM d, h:mm a")
                    val duration = Duration.between(Instant.now(), instant)
                    val rel = when {
                        duration.isNegative -> "Past due"
                        duration.toMinutes() < 60 -> "${duration.toMinutes()}m"
                        duration.toHours() < 24 -> "${duration.toHours()}h"
                        else -> "${duration.toDays()}d"
                    }
                    "Returning in $rel (${local.format(dtf)})"
                }.getOrDefault("Return scheduled")
            }

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(12.dp))
                    .background(Color(0xFF1B1B1E))
                    .border(1.dp, LaterboxAccent.copy(alpha = 0.25f), RoundedCornerShape(12.dp))
                    .padding(horizontal = 14.dp, vertical = 10.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.Timer,
                    contentDescription = null,
                    tint = LaterboxAccent,
                    modifier = Modifier.size(16.dp)
                )
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = "RETURN SCHEDULED",
                        fontSize = 9.sp,
                        fontWeight = FontWeight.Bold,
                        color = LaterboxAccent,
                        letterSpacing = 0.6.sp
                    )
                    Text(
                        text = formatted,
                        fontSize = 12.5.sp,
                        color = Color.White.copy(alpha = 0.9f)
                    )
                }
                Icon(
                    imageVector = Icons.Default.Close,
                    contentDescription = "Clear return date",
                    tint = Color.White.copy(alpha = 0.45f),
                    modifier = Modifier
                        .size(16.dp)
                        .clickable(onClick = onClearReturn)
                )
            }
        }
    }
}

// Chat Message Bubble Component matching iOS screenshot
@Composable
private fun ShareMessageBubble(message: ShareChatMessage) {
    val isUser = message.isUser
    val timeFormatted = remember(message.timestamp) {
        SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date(message.timestamp))
    }

    if (!isUser) {
        // Assistant Message with Sparkles Circle Avatar on the left
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.Start,
            verticalAlignment = Alignment.Top
        ) {
            // Sparkles Avatar circle
            Box(
                modifier = Modifier
                    .size(32.dp)
                    .clip(CircleShape)
                    .background(Color(0xFF26262A)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.AutoAwesome,
                    contentDescription = null,
                    tint = LaterboxAccent,
                    modifier = Modifier.size(14.dp)
                )
            }

            Spacer(modifier = Modifier.width(12.dp))

            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                Text(
                    text = message.text,
                    fontSize = 15.sp,
                    lineHeight = 22.sp,
                    color = Color.White
                )
                Text(
                    text = timeFormatted,
                    fontSize = 11.sp,
                    color = Color.White.copy(alpha = 0.40f)
                )
            }
        }
    } else {
        // User Message: Right aligned dark rounded bubble
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.End
        ) {
            Surface(
                shape = RoundedCornerShape(18.dp),
                color = Color(0xFF2C2C2E),
                modifier = Modifier.widthIn(max = 280.dp)
            ) {
                Text(
                    text = message.text,
                    fontSize = 15.sp,
                    color = Color.White,
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 10.dp)
                )
            }
        }
    }
}

// Edit Details Dialog Sheet
@Composable
private fun ShareEditDetailsDialog(
    initialTitle: String,
    initialContent: String,
    initialCategory: String,
    initialTags: List<String>,
    onDismiss: () -> Unit,
    onSave: (String, String, String, List<String>) -> Unit
) {
    var editTitle by remember { mutableStateOf(initialTitle) }
    var editContent by remember { mutableStateOf(initialContent) }
    var editCategory by remember { mutableStateOf(initialCategory) }
    var editTagsStr by remember { mutableStateOf(initialTags.joinToString(", ")) }

    Dialog(onDismissRequest = onDismiss) {
        Surface(
            shape = RoundedCornerShape(20.dp),
            color = Color(0xFF18181C),
            border = BorderStroke(1.dp, Color.White.copy(alpha = 0.12f)),
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 16.dp)
        ) {
            Column(
                modifier = Modifier
                    .padding(20.dp)
                    .verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Edit Details",
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.White
                    )
                    TextButton(onClick = onDismiss) {
                        Text("Cancel", color = Color.White.copy(alpha = 0.6f))
                    }
                }

                // Title Field
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text("TITLE", fontSize = 10.5.sp, fontWeight = FontWeight.Bold, color = Color.White.copy(alpha = 0.5f))
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(10.dp))
                            .background(Color(0xFF222226))
                            .padding(12.dp)
                    ) {
                        BasicTextField(
                            value = editTitle,
                            onValueChange = { editTitle = it },
                            textStyle = TextStyle(color = Color.White, fontSize = 14.sp),
                            cursorBrush = SolidColor(LaterboxAccent),
                            modifier = Modifier.fillMaxWidth()
                        )
                    }
                }

                // Content Field
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text("CONTENT OR LINK", fontSize = 10.5.sp, fontWeight = FontWeight.Bold, color = Color.White.copy(alpha = 0.5f))
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .heightIn(min = 60.dp, max = 120.dp)
                            .clip(RoundedCornerShape(10.dp))
                            .background(Color(0xFF222226))
                            .padding(12.dp)
                    ) {
                        BasicTextField(
                            value = editContent,
                            onValueChange = { editContent = it },
                            textStyle = TextStyle(color = Color.White, fontSize = 14.sp),
                            cursorBrush = SolidColor(LaterboxAccent),
                            modifier = Modifier.fillMaxSize()
                        )
                    }
                }

                // Category Field
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text("CATEGORY", fontSize = 10.5.sp, fontWeight = FontWeight.Bold, color = Color.White.copy(alpha = 0.5f))
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(10.dp))
                            .background(Color(0xFF222226))
                            .padding(12.dp)
                    ) {
                        BasicTextField(
                            value = editCategory,
                            onValueChange = { editCategory = it },
                            textStyle = TextStyle(color = Color.White, fontSize = 14.sp),
                            cursorBrush = SolidColor(LaterboxAccent),
                            modifier = Modifier.fillMaxWidth()
                        )
                    }
                }

                // Tags Field
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text("TAGS (COMMA SEPARATED)", fontSize = 10.5.sp, fontWeight = FontWeight.Bold, color = Color.White.copy(alpha = 0.5f))
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(10.dp))
                            .background(Color(0xFF222226))
                            .padding(12.dp)
                    ) {
                        BasicTextField(
                            value = editTagsStr,
                            onValueChange = { editTagsStr = it },
                            textStyle = TextStyle(color = Color.White, fontSize = 14.sp),
                            cursorBrush = SolidColor(LaterboxAccent),
                            modifier = Modifier.fillMaxWidth()
                        )
                    }
                }

                // Done Button
                Button(
                    onClick = {
                        val parsedTags = editTagsStr.split(",")
                            .map { it.trim().removePrefix("#") }
                            .filter { it.isNotBlank() }
                        onSave(editTitle.trim(), editContent.trim(), editCategory.trim(), parsedTags)
                    },
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = LaterboxAccent,
                        contentColor = Color(0xFF171711)
                    ),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Text("Done", fontWeight = FontWeight.Bold, fontSize = 15.sp)
                }
            }
        }
    }
}
