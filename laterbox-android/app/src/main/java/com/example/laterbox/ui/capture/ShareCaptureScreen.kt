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
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Density
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
import org.json.JSONObject
import org.jsoup.Jsoup
import java.io.File
import java.net.HttpURLConnection
import java.net.URI
import java.net.URL
import java.net.URLEncoder
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

private data class EnrichedLinkData(
    val title: String? = null,
    val author: String? = null,
    val description: String? = null,
    val previewImageUrl: String? = null,
    val siteName: String? = null,
    val keywords: List<String> = emptyList()
)

private fun isGenericTitle(title: String?): Boolean {
    if (title.isNullOrBlank()) return true
    val lower = title.trim().lowercase()
    val junk = listOf(
        "instagram", "login • instagram", "instagram.com", "youtube", "- youtube",
        "x", "twitter", "x.com", "facebook", "log in", "sign in", "reddit",
        "tiktok", "vimeo", "shared item", "web", "untitled", "video playlist",
        "watch", "watch video", "spotify", "soundcloud", "before you continue to youtube"
    )
    return lower in junk ||
        lower.startsWith("login") ||
        lower.startsWith("sign in") ||
        lower.startsWith("watch |") ||
        (lower.endsWith("youtube") && lower.length <= 14) ||
        lower.startsWith("http://") ||
        lower.startsWith("https://")
}

private fun cleanTitle(title: String?): String? {
    if (title.isNullOrBlank()) return null
    var cleaned = title.trim()
    for (suffix in listOf(
        " - YouTube", " | YouTube", " – YouTube", " — YouTube",
        " - Vimeo", " | Vimeo", " on Spotify", " • Instagram photos and videos",
        " / X", " on X", " | Twitter"
    )) {
        if (cleaned.endsWith(suffix, ignoreCase = true)) {
            cleaned = cleaned.substring(0, cleaned.length - suffix.length).trim()
        }
    }
    return if (isGenericTitle(cleaned)) null else cleaned
}

private fun isGenericDescription(desc: String?): Boolean {
    if (desc.isNullOrBlank()) return true
    val lower = desc.trim().lowercase()
    return lower.contains("enjoy the videos and music you love") ||
        lower.contains("upload original content") ||
        lower.contains("share it all with friends, family")
}

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
        Regex("https?://[^\\s]+").find(content)?.value?.trim()
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

    // Enrichment Pipeline
    LaunchedEffect(Unit) {
        isLoading = true
        withContext(Dispatchers.IO) {
            var rawTitle: String? = null
            var rawSummary: String? = null
            var rawKeywords = mutableListOf<String>()
            var rawImage: String? = null
            var rawSite: String? = null

            // Check if local attachments have an image
            val localImage = attachments.firstOrNull {
                it.mime.startsWith("image/") || it.name.endsWith(".jpg", true) ||
                it.name.endsWith(".png", true) || it.name.endsWith(".webp", true) ||
                it.name.endsWith(".jpeg", true)
            }
            if (localImage != null && File(localImage.path).exists()) {
                rawImage = localImage.path
                rawSite = "Photo"
            }

            if (detectedUrl != null) {
                val host = runCatching { URI(detectedUrl).host?.lowercase().orEmpty() }.getOrDefault("")

                // Tier 1: YouTube / Vimeo oEmbed
                if (host.contains("youtube.com") || host == "youtu.be" || host.contains("vimeo.com")) {
                    rawSite = if (host.contains("vimeo")) "Vimeo" else "YouTube"
                    val oembedEndpoint = if (host.contains("vimeo")) {
                        "https://vimeo.com/api/oembed.json?url=${URLEncoder.encode(detectedUrl, "UTF-8")}"
                    } else {
                        "https://www.youtube.com/oembed?url=${URLEncoder.encode(detectedUrl, "UTF-8")}&format=json"
                    }
                    runCatching {
                        val conn = URL(oembedEndpoint).openConnection() as HttpURLConnection
                        conn.connectTimeout = 4000
                        conn.readTimeout = 4000
                        conn.setRequestProperty("User-Agent", "Mozilla/5.0")
                        if (conn.responseCode == 200) {
                            val resp = conn.inputStream.bufferedReader().use { it.readText() }
                            val json = JSONObject(resp)
                            val oTitle = json.optString("title", "").trim()
                            if (oTitle.isNotBlank()) rawTitle = cleanTitle(oTitle) ?: oTitle
                            val author = json.optString("author_name", "").trim()
                            if (author.isNotBlank()) rawSummary = "Video by $author on $rawSite"
                            val thumb = json.optString("thumbnail_url", "").trim()
                            if (thumb.isNotBlank() && rawImage == null) {
                                rawImage = thumb.replace("/hqdefault.jpg", "/mqdefault.jpg")
                                    .replace("/sddefault.jpg", "/mqdefault.jpg")
                            }
                        }
                    }
                }

                // Tier 2: Laterbox Dedicated Enrich API
                runCatching {
                    val conn = URL("https://laterbox.dev/api/enrich").openConnection() as HttpURLConnection
                    conn.requestMethod = "POST"
                    conn.connectTimeout = 6000
                    conn.readTimeout = 6000
                    conn.doOutput = true
                    conn.setRequestProperty("Content-Type", "application/json")
                    val body = JSONObject().put("url", detectedUrl).toString()
                    conn.outputStream.use { it.write(body.toByteArray()) }
                    if (conn.responseCode in 200..299) {
                        val resp = conn.inputStream.bufferedReader().use { it.readText() }
                        val json = JSONObject(resp)
                        val apiTitle = json.optString("title", "").trim()
                        val cleanedApiTitle = cleanTitle(apiTitle)
                        if (rawTitle == null || isGenericTitle(rawTitle)) {
                            if (cleanedApiTitle != null) rawTitle = cleanedApiTitle
                            else if (apiTitle.isNotBlank() && !isGenericTitle(apiTitle)) rawTitle = apiTitle
                        }
                        val apiSite = json.optString("siteName", json.optString("site_name", "")).trim()
                        if (rawSite == null && apiSite.isNotBlank()) rawSite = apiSite
                        val apiDesc = json.optString("description", "").trim()
                        if (rawSummary == null && apiDesc.isNotBlank() && !isGenericDescription(apiDesc)) rawSummary = apiDesc
                        val apiImg = json.optString("previewImageUrl", json.optString("preview_image_url", "")).trim()
                        if (rawImage == null && apiImg.isNotBlank()) {
                            rawImage = apiImg.replace("/hqdefault.jpg", "/mqdefault.jpg")
                        }
                        val kwArr = json.optJSONArray("keywords")
                        if (kwArr != null) {
                            for (i in 0 until kwArr.length()) {
                                kwArr.optString(i).trim().takeIf { it.isNotBlank() }?.let { rawKeywords.add(it) }
                            }
                        }
                    }
                }

                // Tier 3: Jsoup Mobile Scraper
                if (rawTitle == null || isGenericTitle(rawTitle) || rawImage == null) {
                    runCatching {
                        val doc = Jsoup.connect(detectedUrl)
                            .userAgent("Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1")
                            .header("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8")
                            .timeout(5000)
                            .maxBodySize(2 * 1024 * 1024)
                            .get()

                        val ogTitle = doc.selectFirst("meta[property=og:title], meta[name=twitter:title]")?.attr("content")?.trim()
                        val pageTitle = doc.title().trim()
                        val candidate = ogTitle?.takeIf { it.isNotBlank() } ?: pageTitle.takeIf { it.isNotBlank() }
                        val cleaned = cleanTitle(candidate)
                        if (rawTitle == null || isGenericTitle(rawTitle)) {
                            if (cleaned != null) rawTitle = cleaned
                            else if (!candidate.isNullOrBlank() && !isGenericTitle(candidate)) rawTitle = candidate
                        }
                        if (rawSummary == null) {
                            val ogDesc = doc.selectFirst("meta[property=og:description], meta[name=description]")?.attr("content")?.trim()
                            if (!ogDesc.isNullOrBlank() && !isGenericDescription(ogDesc)) rawSummary = ogDesc
                        }
                        if (rawImage == null) {
                            val ogImg = doc.selectFirst("meta[property=og:image], meta[name=twitter:image]")?.attr("content")?.trim()
                            if (!ogImg.isNullOrBlank()) rawImage = ogImg
                        }
                        if (rawSite == null) {
                            val ogSite = doc.selectFirst("meta[property=og:site_name]")?.attr("content")?.trim()
                            if (!ogSite.isNullOrBlank()) rawSite = ogSite
                        }
                    }
                }

                if (rawSite.isNullOrBlank()) {
                    rawSite = when {
                        host.contains("youtube") -> "YouTube"
                        host.contains("instagram") -> "Instagram"
                        host.contains("twitter") || host == "x.com" -> "X"
                        host.contains("reddit") -> "Reddit"
                        host.contains("tiktok") -> "TikTok"
                        host.contains("github") -> "GitHub"
                        host.contains("medium") -> "Medium"
                        else -> host.removePrefix("www.")
                    }
                }
            }

            // Fallback Title Resolution
            val fallbackTitle = when {
                !rawTitle.isNullOrBlank() && !isGenericTitle(rawTitle) -> rawTitle
                attachments.isNotEmpty() -> attachments.first().name.substringBeforeLast('.')
                content.isNotBlank() -> {
                    val withoutUrl = content.replace(Regex("https?://[^\\s]+"), "").trim()
                    if (withoutUrl.isNotBlank()) {
                        withoutUrl.lines().firstOrNull()?.trim()?.take(70) ?: "Shared Item"
                    } else if (!rawSummary.isNullOrBlank()) {
                        rawSummary.take(70)
                    } else if (!rawSite.isNullOrBlank()) {
                        if (detectedUrl?.contains("/reel/") == true) "$rawSite Reel"
                        else if (detectedUrl?.contains("/p/") == true) "$rawSite Post"
                        else "$rawSite Link"
                    } else "Shared Item"
                }
                else -> rawSite ?: "Shared Item"
            }

            // Inferred Tags
            val inferredTags = mutableListOf<String>()
            rawKeywords.forEach { kw ->
                kw.split(",").map { it.trim().lowercase() }.filter { it.length in 2..30 }.forEach { inferredTags.add(it) }
            }
            // Detect hashtags in content or title
            val fullText = "$fallbackTitle $content"
            Regex("#([\\p{L}\\d_-]+)").findAll(fullText).forEach { match ->
                val tag = match.groupValues[1].lowercase()
                if (tag.length in 2..30) inferredTags.add(tag)
            }
            if (detectedUrl != null) {
                val host = runCatching { URI(detectedUrl).host?.lowercase().orEmpty() }.getOrDefault("")
                if (host.contains("youtube") || host.contains("youtu.be") || host.contains("vimeo")) {
                    inferredTags.add("video")
                } else if (host.contains("instagram")) {
                    inferredTags.add("social")
                } else if (host.contains("github")) {
                    inferredTags.add("dev")
                } else if (host.contains("medium") || host.contains("substack")) {
                    inferredTags.add("reading")
                }
            }
            if (localImage != null) {
                inferredTags.add("photo")
            } else if (attachments.isNotEmpty()) {
                inferredTags.add("document")
            }

            val cleanTags = inferredTags.distinct().filter {
                it !in listOf("http", "https", "www", "untitled", "share", "video playlist", "playlist")
            }

            val inferredCategory = when {
                detectedUrl != null && (detectedUrl.contains("youtube") || detectedUrl.contains("vimeo")) -> "Watch Later"
                detectedUrl != null && (detectedUrl.contains("medium") || detectedUrl.contains("substack")) -> "Reading"
                localImage != null -> "Photos"
                attachments.isNotEmpty() -> "Documents"
                else -> "Inbox"
            }

            withContext(Dispatchers.Main) {
                title = fallbackTitle
                summary = rawSummary.orEmpty()
                previewImageUrl = rawImage
                siteName = rawSite
                category = inferredCategory
                tags = cleanTags
                resolvedType = when {
                    localImage != null -> "image"
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

    // Auto-scroll on changes
    LaunchedEffect(messages.size, isLoading, showManualInput) {
        scrollState.animateScrollTo(scrollState.maxValue)
    }

    // Schedule and Save Handler
    fun scheduleAndSave(instant: String?, optionLabel: String) {
        if (isSaving) return
        isSaving = true
        errorMessage = null

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

    // Manual Input Handler
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

    // Active Options Dock
    val activeOptions = remember(needsReturnDate, savedItem, isLoading) {
        if (isLoading) return@remember emptyList<ShareOptionItem>()

        if (needsReturnDate) {
            val list = mutableListOf<ShareOptionItem>()
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

    // Compact font scale provider to guarantee small, proportional text on zoomed displays
    val currentDensity = LocalDensity.current
    val compactDensity = remember(currentDensity.density, currentDensity.fontScale) {
        Density(
            density = currentDensity.density,
            fontScale = currentDensity.fontScale.coerceIn(0.85f, 1.02f)
        )
    }

    CompositionLocalProvider(LocalDensity provides compactDensity) {
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
                    fontSize = 15.sp
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
            return@CompositionLocalProvider
        }

        // Main Share UI Layout (iOS Style AI popup)
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Color.Black)
        ) {
            Column(
                modifier = Modifier.fillMaxSize()
            ) {
                // Scrollable Content
                Column(
                    modifier = Modifier
                        .weight(1f)
                        .verticalScroll(scrollState)
                        .padding(horizontal = 16.dp, vertical = 12.dp),
                    verticalArrangement = Arrangement.spacedBy(14.dp)
                ) {
                    // Shared Preview Card (shows banner if image/URL, or rich link/note preview)
                    SharePreviewCard(
                        title = title,
                        previewImageUrl = previewImageUrl,
                        siteName = siteName,
                        detectedUrl = detectedUrl,
                        content = content,
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

                    // Message transcript bubbles
                    messages.forEach { msg ->
                        ShareMessageBubble(message = msg)
                    }

                    // Loading Indicator
                    if (isLoading) {
                        Row(
                            modifier = Modifier
                                .clip(RoundedCornerShape(14.dp))
                                .background(Color(0xFF1E1E22))
                                .padding(horizontal = 14.dp, vertical = 8.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(13.dp),
                                color = LaterboxAccent,
                                strokeWidth = 2.dp
                            )
                            Text(
                                text = "Preparing draft...",
                                fontSize = 12.sp,
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
                            .padding(10.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.Warning,
                                contentDescription = null,
                                tint = Color(0xFFFC8181),
                                modifier = Modifier.size(16.dp)
                            )
                            Text(
                                text = err,
                                fontSize = 12.sp,
                                color = Color(0xFFFEB2B2)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(14.dp))
                }

                // Bottom Popups Options Dock
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
                            fontSize = 10.5.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color.White.copy(alpha = 0.65f),
                            letterSpacing = 0.5.sp
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
                                fontSize = 11.5.sp,
                                fontWeight = FontWeight.Medium,
                                color = Color.White.copy(alpha = 0.55f)
                            )
                        }
                    }

                    // Manual Type bar or Horizontal option pills
                    if (showManualInput) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 16.dp, vertical = 6.dp)
                                .clip(RoundedCornerShape(16.dp))
                                .background(Color(0xFF1E1E22))
                                .border(1.dp, Color.White.copy(alpha = 0.12f), RoundedCornerShape(16.dp))
                                .padding(horizontal = 12.dp, vertical = 8.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            BasicTextField(
                                value = manualInputText,
                                onValueChange = { manualInputText = it },
                                textStyle = TextStyle(color = Color.White, fontSize = 13.5.sp),
                                cursorBrush = SolidColor(LaterboxAccent),
                                modifier = Modifier.weight(1f),
                                decorationBox = { inner ->
                                    if (manualInputText.isEmpty()) {
                                        Text("Type instructions or schedule...", color = Color.White.copy(alpha = 0.35f), fontSize = 13.sp)
                                    }
                                    inner()
                                }
                            )

                            IconButton(
                                onClick = { handleManualInput() },
                                modifier = Modifier.size(28.dp)
                            ) {
                                Icon(
                                    imageVector = Icons.AutoMirrored.Filled.Send,
                                    contentDescription = "Send",
                                    tint = if (manualInputText.isNotBlank()) LaterboxAccent else Color.White.copy(alpha = 0.3f),
                                    modifier = Modifier.size(15.dp)
                                )
                            }
                        }
                    } else {
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
                                        modifier = Modifier.padding(horizontal = 15.dp, vertical = 9.dp),
                                        verticalAlignment = Alignment.CenterVertically,
                                        horizontalArrangement = Arrangement.spacedBy(7.dp)
                                    ) {
                                        opt.icon?.let { iconVec ->
                                            Icon(
                                                imageVector = iconVec,
                                                contentDescription = null,
                                                tint = if (opt.isPrimary) Color(0xFF171711) else Color.White,
                                                modifier = Modifier.size(15.dp)
                                            )
                                        }
                                        Column(verticalArrangement = Arrangement.spacedBy(1.dp)) {
                                            Text(
                                                text = opt.title,
                                                fontSize = 12.5.sp,
                                                fontWeight = FontWeight.SemiBold,
                                                color = if (opt.isPrimary) Color(0xFF171711) else Color.White
                                            )
                                            opt.subtitle?.let { sub ->
                                                Text(
                                                    text = sub,
                                                    fontSize = 9.5.sp,
                                                    color = if (opt.isPrimary) Color(0xFF171711).copy(alpha = 0.7f) else Color.White.copy(alpha = 0.55f)
                                                )
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Disclaimer at the very bottom
                    Text(
                        text = "Later AI can make mistakes. Verify important info.",
                        fontSize = 10.sp,
                        color = Color.White.copy(alpha = 0.35f),
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(top = 4.dp, bottom = 8.dp),
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
}

// Preview Card Component matching iOS screenshot
@Composable
private fun SharePreviewCard(
    title: String,
    previewImageUrl: String?,
    siteName: String?,
    detectedUrl: String?,
    content: String,
    attachments: List<ShareAttachmentItem>,
    returnAt: String?,
    onClearReturn: () -> Unit
) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        // 1. Web or Photo Banner Image with Gradient Overlay
        if (!previewImageUrl.isNullOrBlank()) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(132.dp)
                    .clip(RoundedCornerShape(14.dp))
                    .background(Color(0xFF1E1E22))
            ) {
                AsyncImage(
                    model = previewImageUrl,
                    contentDescription = null,
                    contentScale = ContentScale.Crop,
                    modifier = Modifier.fillMaxSize()
                )
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(
                            Brush.verticalGradient(
                                colors = listOf(Color.Transparent, Color.Black.copy(alpha = 0.88f)),
                                startY = 36f
                            )
                        )
                )
                Row(
                    modifier = Modifier
                        .align(Alignment.BottomStart)
                        .fillMaxWidth()
                        .padding(horizontal = 12.dp, vertical = 10.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Icon(
                        imageVector = if (previewImageUrl.startsWith("/") || previewImageUrl.startsWith("file:")) Icons.Default.Image else Icons.Default.Language,
                        contentDescription = null,
                        tint = LaterboxAccent,
                        modifier = Modifier.size(15.dp)
                    )
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = title,
                            fontSize = 13.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = Color.White,
                            maxLines = 1
                        )
                        if (!siteName.isNullOrBlank()) {
                            Text(
                                text = siteName,
                                fontSize = 10.5.sp,
                                color = Color.White.copy(alpha = 0.65f),
                                maxLines = 1
                            )
                        }
                    }
                    if (detectedUrl != null) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.OpenInNew,
                            contentDescription = null,
                            tint = Color.White.copy(alpha = 0.75f),
                            modifier = Modifier.size(14.dp)
                        )
                    }
                }
            }
        } else if (detectedUrl != null) {
            // 2. Link Preview Card without image
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp))
                    .background(Color(0xFF1E1E22))
                    .border(1.dp, Color.White.copy(alpha = 0.08f), RoundedCornerShape(14.dp))
                    .padding(12.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                Box(
                    modifier = Modifier
                        .size(34.dp)
                        .clip(RoundedCornerShape(10.dp))
                        .background(Color(0xFF26262A)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.Language,
                        contentDescription = null,
                        tint = LaterboxAccent,
                        modifier = Modifier.size(16.dp)
                    )
                }
                Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                    Text(
                        text = title,
                        fontSize = 13.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = Color.White,
                        maxLines = 1
                    )
                    Text(
                        text = siteName ?: runCatching { URI(detectedUrl).host?.removePrefix("www.") }.getOrNull() ?: detectedUrl,
                        fontSize = 10.5.sp,
                        color = Color.White.copy(alpha = 0.60f),
                        maxLines = 1
                    )
                }
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.OpenInNew,
                    contentDescription = null,
                    tint = Color.White.copy(alpha = 0.60f),
                    modifier = Modifier.size(14.dp)
                )
            }
        } else if (content.isNotBlank()) {
            // 3. Shared Note / Text Card
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp))
                    .background(Color(0xFF1E1E22))
                    .border(1.dp, Color.White.copy(alpha = 0.08f), RoundedCornerShape(14.dp))
                    .padding(12.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                Box(
                    modifier = Modifier
                        .size(34.dp)
                        .clip(RoundedCornerShape(10.dp))
                        .background(Color(0xFF26262A)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.Description,
                        contentDescription = null,
                        tint = LaterboxAccent,
                        modifier = Modifier.size(16.dp)
                    )
                }
                Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                    Text(
                        text = title,
                        fontSize = 13.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = Color.White,
                        maxLines = 1
                    )
                    Text(
                        text = content.take(90),
                        fontSize = 11.sp,
                        color = Color.White.copy(alpha = 0.60f),
                        maxLines = 1
                    )
                }
            }
        }

        // 4. Attachments list
        attachments.forEach { file ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(12.dp))
                    .background(Color(0xFF1B1B1E))
                    .border(1.dp, Color.White.copy(alpha = 0.08f), RoundedCornerShape(12.dp))
                    .padding(horizontal = 12.dp, vertical = 9.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(9.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.AttachFile,
                    contentDescription = null,
                    tint = LaterboxAccent,
                    modifier = Modifier.size(15.dp)
                )
                Text(
                    text = file.name,
                    fontSize = 12.5.sp,
                    fontWeight = FontWeight.Medium,
                    color = Color.White,
                    maxLines = 1,
                    modifier = Modifier.weight(1f)
                )
            }
        }

        // 5. Return Countdown Badge
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
                    .padding(horizontal = 12.dp, vertical = 9.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(9.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.Timer,
                    contentDescription = null,
                    tint = LaterboxAccent,
                    modifier = Modifier.size(15.dp)
                )
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = "RETURN SCHEDULED",
                        fontSize = 8.5.sp,
                        fontWeight = FontWeight.Bold,
                        color = LaterboxAccent,
                        letterSpacing = 0.5.sp
                    )
                    Text(
                        text = formatted,
                        fontSize = 11.5.sp,
                        color = Color.White.copy(alpha = 0.9f)
                    )
                }
                Icon(
                    imageVector = Icons.Default.Close,
                    contentDescription = "Clear return date",
                    tint = Color.White.copy(alpha = 0.45f),
                    modifier = Modifier
                        .size(15.dp)
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
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.Start,
            verticalAlignment = Alignment.Top
        ) {
            Box(
                modifier = Modifier
                    .size(28.dp)
                    .clip(CircleShape)
                    .background(Color(0xFF26262A)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.AutoAwesome,
                    contentDescription = null,
                    tint = LaterboxAccent,
                    modifier = Modifier.size(13.dp)
                )
            }

            Spacer(modifier = Modifier.width(10.dp))

            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(3.dp)
            ) {
                Text(
                    text = message.text,
                    fontSize = 13.5.sp,
                    lineHeight = 19.sp,
                    color = Color.White
                )
                Text(
                    text = timeFormatted,
                    fontSize = 10.sp,
                    color = Color.White.copy(alpha = 0.40f)
                )
            }
        }
    } else {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.End
        ) {
            Surface(
                shape = RoundedCornerShape(18.dp),
                color = Color(0xFF2C2C2E),
                modifier = Modifier.widthIn(max = 260.dp)
            ) {
                Text(
                    text = message.text,
                    fontSize = 13.5.sp,
                    color = Color.White,
                    modifier = Modifier.padding(horizontal = 14.dp, vertical = 8.dp)
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
            shape = RoundedCornerShape(18.dp),
            color = Color(0xFF18181C),
            border = BorderStroke(1.dp, Color.White.copy(alpha = 0.12f)),
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 14.dp)
        ) {
            Column(
                modifier = Modifier
                    .padding(18.dp)
                    .verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(14.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Edit Details",
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.White
                    )
                    TextButton(onClick = onDismiss) {
                        Text("Cancel", color = Color.White.copy(alpha = 0.6f), fontSize = 13.sp)
                    }
                }

                Column(verticalArrangement = Arrangement.spacedBy(5.dp)) {
                    Text("TITLE", fontSize = 10.sp, fontWeight = FontWeight.Bold, color = Color.White.copy(alpha = 0.5f))
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(10.dp))
                            .background(Color(0xFF222226))
                            .padding(10.dp)
                    ) {
                        BasicTextField(
                            value = editTitle,
                            onValueChange = { editTitle = it },
                            textStyle = TextStyle(color = Color.White, fontSize = 13.5.sp),
                            cursorBrush = SolidColor(LaterboxAccent),
                            modifier = Modifier.fillMaxWidth()
                        )
                    }
                }

                Column(verticalArrangement = Arrangement.spacedBy(5.dp)) {
                    Text("CONTENT OR LINK", fontSize = 10.sp, fontWeight = FontWeight.Bold, color = Color.White.copy(alpha = 0.5f))
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .heightIn(min = 55.dp, max = 110.dp)
                            .clip(RoundedCornerShape(10.dp))
                            .background(Color(0xFF222226))
                            .padding(10.dp)
                    ) {
                        BasicTextField(
                            value = editContent,
                            onValueChange = { editContent = it },
                            textStyle = TextStyle(color = Color.White, fontSize = 13.sp),
                            cursorBrush = SolidColor(LaterboxAccent),
                            modifier = Modifier.fillMaxSize()
                        )
                    }
                }

                Column(verticalArrangement = Arrangement.spacedBy(5.dp)) {
                    Text("CATEGORY", fontSize = 10.sp, fontWeight = FontWeight.Bold, color = Color.White.copy(alpha = 0.5f))
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(10.dp))
                            .background(Color(0xFF222226))
                            .padding(10.dp)
                    ) {
                        BasicTextField(
                            value = editCategory,
                            onValueChange = { editCategory = it },
                            textStyle = TextStyle(color = Color.White, fontSize = 13.5.sp),
                            cursorBrush = SolidColor(LaterboxAccent),
                            modifier = Modifier.fillMaxWidth()
                        )
                    }
                }

                Column(verticalArrangement = Arrangement.spacedBy(5.dp)) {
                    Text("TAGS (COMMA SEPARATED)", fontSize = 10.sp, fontWeight = FontWeight.Bold, color = Color.White.copy(alpha = 0.5f))
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(10.dp))
                            .background(Color(0xFF222226))
                            .padding(10.dp)
                    ) {
                        BasicTextField(
                            value = editTagsStr,
                            onValueChange = { editTagsStr = it },
                            textStyle = TextStyle(color = Color.White, fontSize = 13.5.sp),
                            cursorBrush = SolidColor(LaterboxAccent),
                            modifier = Modifier.fillMaxWidth()
                        )
                    }
                }

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
                    Text("Done", fontWeight = FontWeight.Bold, fontSize = 14.sp)
                }
            }
        }
    }
}
