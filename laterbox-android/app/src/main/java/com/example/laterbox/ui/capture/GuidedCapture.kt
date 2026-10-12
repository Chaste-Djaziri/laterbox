package com.example.laterbox.ui.capture

import android.provider.OpenableColumns
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
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
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.Article
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.laterbox.data.local.ItemEntity
import com.example.laterbox.services.VaultStore
import com.example.laterbox.theme.LaterboxAccent
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import org.jsoup.Jsoup
import java.io.File
import java.net.URI
import java.time.*
import java.time.format.DateTimeFormatter
import java.time.temporal.TemporalAdjusters
import java.util.UUID

@Composable
fun Choice(title: String, subtitle: String = "", dark: Boolean = true, onClick: () -> Unit) {
    Column(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(if (dark) Color(0xFF222225) else Color.White)
            .border(1.dp, if (dark) Color.White.copy(alpha = 0.08f) else Color.Black.copy(alpha = 0.08f), RoundedCornerShape(16.dp))
            .clickable(onClick = onClick)
            .padding(16.dp)
    ) {
        Text(title, color = if (dark) Color.White else Color.Black, fontWeight = FontWeight.SemiBold, fontSize = 15.sp)
        if (subtitle.isNotBlank()) {
            Spacer(Modifier.height(2.dp))
            Text(subtitle, color = if (dark) Color.White.copy(alpha = 0.55f) else Color.Gray, fontSize = 12.sp)
        }
    }
}

@Composable
fun GuidedCapture(
    initial: String = "",
    attachments: String = "[]",
    dark: Boolean = true,
    scrollable: Boolean = true,
    modifier: Modifier = Modifier,
    onCancel: (() -> Unit)? = null,
    onSave: (ItemEntity) -> Unit
) {
    val context = LocalContext.current
    var content by rememberSaveable { mutableStateOf(initial) }
    var title by rememberSaveable { mutableStateOf("") }
    var summary by rememberSaveable { mutableStateOf("") }
    var category by rememberSaveable { mutableStateOf("") }
    var selectedFormat by rememberSaveable { mutableStateOf<String?>(null) }
    var tagText by rememberSaveable { mutableStateOf("") }
    var returnAt by rememberSaveable { mutableStateOf<String?>(null) }
    var step by rememberSaveable { mutableIntStateOf(0) }
    var isFetchingMetadata by remember { mutableStateOf(false) }
    var customReturnDate by remember { mutableStateOf(false) }
    val id = rememberSaveable { UUID.randomUUID().toString() }

    val attachmentList = remember {
        mutableStateListOf<JSONObject>().apply {
            runCatching {
                val arr = JSONArray(attachments)
                for (i in 0 until arr.length()) add(arr.getJSONObject(i))
            }
        }
    }

    val filePickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetMultipleContents()
    ) { uris ->
        if (uris.isEmpty()) return@rememberLauncherForActivityResult
        val directory = File(context.filesDir, "captures").apply { mkdirs() }
        for (uri in uris) {
            val name = runCatching {
                context.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { cursor ->
                    if (cursor.moveToFirst()) cursor.getString(0) else "Attachment"
                }
            }.getOrNull() ?: "Attachment"
            val extension = name.substringAfterLast('.', "").take(12).filter { it.isLetterOrDigit() }
            val file = File(directory, UUID.randomUUID().toString() + if (extension.isBlank()) "" else ".$extension")
            try {
                context.contentResolver.openInputStream(uri)?.use { input ->
                    file.outputStream().use { output ->
                        input.copyTo(output)
                    }
                }
                val mime = context.contentResolver.getType(uri) ?: "application/octet-stream"
                attachmentList.add(
                    JSONObject()
                        .put("name", name)
                        .put("path", file.absolutePath)
                        .put("mime", mime)
                        .put("size", file.length())
                )
                if (title.isBlank()) {
                    title = name.substringBeforeLast('.')
                }
            } catch (_: Exception) {
                file.delete()
            }
        }
    }

    val currentAttachmentsJson = remember(attachmentList.size) {
        JSONArray().apply { attachmentList.forEach { put(it) } }.toString()
    }

    // Real-time URL detection
    val detectedUrl = remember(content) {
        Regex("https?://[^\\s]+").find(content)?.value
    }

    // Automatic metadata scraping without any AI prompts
    LaunchedEffect(detectedUrl) {
        if (detectedUrl != null) {
            isFetchingMetadata = true
            withContext(Dispatchers.IO) {
                runCatching {
                    val doc = Jsoup.connect(detectedUrl).timeout(7000).maxBodySize(1024 * 1024).get()
                    val webTitle = doc.selectFirst("meta[property=og:title]")?.attr("content")?.takeIf { it.isNotBlank() }
                        ?: doc.title().takeIf { it.isNotBlank() }
                    val webDesc = doc.selectFirst("meta[property=og:description], meta[name=description]")?.attr("content")?.takeIf { it.isNotBlank() }
                    val keywords = doc.selectFirst("meta[name=keywords]")?.attr("content")
                    val host = runCatching { URI(detectedUrl).host?.removePrefix("www.") }.getOrNull()

                    withContext(Dispatchers.Main) {
                        if (title.isBlank() || title == detectedUrl || title == host) {
                            webTitle?.let { title = it }
                        }
                        if (summary.isBlank()) {
                            webDesc?.let { summary = it }
                        }
                        if (tagText.isBlank() && !keywords.isNullOrBlank()) {
                            val kwList = keywords.split(",").map { it.trim().lowercase() }.filter { it.isNotBlank() }.distinct().take(4)
                            if (kwList.isNotEmpty()) {
                                tagText = kwList.joinToString(", ")
                            }
                        }
                    }
                }
            }
            isFetchingMetadata = false
        }
    }

    // Automatic format detection based on attachments or URL host
    val detectedType = remember(detectedUrl, attachmentList.size, selectedFormat) {
        if (selectedFormat != null) return@remember selectedFormat!!
        if (attachmentList.isNotEmpty()) {
            val first = attachmentList.firstOrNull()
            val name = first?.optString("name", "")?.lowercase().orEmpty()
            val mime = first?.optString("mime", "").orEmpty()
            when {
                name.endsWith(".jpg") || name.endsWith(".jpeg") || name.endsWith(".png") || name.endsWith(".webp") || mime.startsWith("image/") -> "image"
                name.endsWith(".mp4") || name.endsWith(".mov") || name.endsWith(".mkv") || mime.startsWith("video/") -> "video"
                name.endsWith(".mp3") || name.endsWith(".wav") || name.endsWith(".m4a") || mime.startsWith("audio/") -> "music"
                name.endsWith(".pdf") || name.endsWith(".doc") || name.endsWith(".docx") || name.endsWith(".txt") -> "document"
                else -> "document"
            }
        } else if (detectedUrl != null) {
            val host = runCatching { URI(detectedUrl).host?.lowercase() }.getOrNull().orEmpty()
            when {
                host.contains("youtube") || host.contains("youtu.be") || host.contains("vimeo") -> "video"
                host.contains("spotify") || host.contains("soundcloud") || host.contains("music.apple") -> "music"
                host.contains("medium") || host.contains("substack") || host.contains("dev.to") -> "article"
                detectedUrl.endsWith(".pdf") -> "document"
                else -> "link"
            }
        } else {
            "note"
        }
    }

    // Dynamic suggested tags
    val suggestedTags = remember(detectedType, detectedUrl, content) {
        val list = mutableListOf<String>()
        when (detectedType) {
            "article" -> list.add("reading")
            "video" -> list.add("watch")
            "music" -> list.add("audio")
            "note" -> list.add("idea")
            "document" -> list.add("reference")
            else -> list.add("saved")
        }
        detectedUrl?.let {
            val domainName = runCatching { URI(it).host?.removePrefix("www.")?.substringBefore(".") }.getOrNull()
            if (!domainName.isNullOrBlank() && domainName.length in 3..14 && domainName !in list) {
                list.add(domainName)
            }
        }
        for (extra in listOf("work", "personal", "inspiration")) {
            if (extra !in list && list.size < 4) list.add(extra)
        }
        list
    }

    val canProceed = content.trim().isNotEmpty() || attachmentList.isNotEmpty()

    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(22.dp))
            .background(Color(0xFF161618))
            .border(1.dp, Color.White.copy(alpha = 0.12f), RoundedCornerShape(22.dp))
            .padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Header Row: Close X on right
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.End,
            verticalAlignment = Alignment.CenterVertically
        ) {
            if (onCancel != null) {
                Surface(
                    modifier = Modifier
                        .size(32.dp)
                        .clip(CircleShape)
                        .clickable(onClick = onCancel),
                    shape = CircleShape,
                    color = Color(0xFF26262A)
                ) {
                    Box(contentAlignment = Alignment.Center, modifier = Modifier.fillMaxSize()) {
                        Icon(
                            imageVector = Icons.Default.Close,
                            contentDescription = "Close",
                            tint = Color.White.copy(alpha = 0.7f),
                            modifier = Modifier.size(16.dp)
                        )
                    }
                }
            }
        }

        // Active Step Content
        when (step) {
            0 -> {
                // Step 0: "Start typing here"
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Text(
                        text = "Start typing here",
                        fontStyle = androidx.compose.ui.text.font.FontStyle.Normal,
                        fontWeight = FontWeight.Bold,
                        fontSize = 17.sp,
                        color = Color.White
                    )

                    // Text Editor Card
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .heightIn(min = 130.dp, max = 200.dp)
                            .clip(RoundedCornerShape(14.dp))
                            .background(Color(0xFF1F1F22))
                            .border(1.dp, Color.White.copy(alpha = 0.12f), RoundedCornerShape(14.dp))
                            .padding(14.dp)
                    ) {
                        BasicTextField(
                            value = content,
                            onValueChange = { content = it },
                            textStyle = TextStyle(
                                fontSize = 15.sp,
                                lineHeight = 22.sp,
                                color = Color.White,
                                fontWeight = FontWeight.Normal
                            ),
                            cursorBrush = SolidColor(LaterboxAccent),
                            modifier = Modifier
                                .fillMaxSize()
                                .verticalScroll(rememberScrollState()),
                            decorationBox = { innerTextField ->
                                Box(contentAlignment = Alignment.TopStart) {
                                    if (content.isEmpty()) {
                                        Text(
                                            text = "Start typing here...",
                                            fontSize = 15.sp,
                                            color = Color.White.copy(alpha = 0.35f)
                                        )
                                    }
                                    innerTextField()
                                }
                            }
                        )
                    }

                    // Attached Documents or Photos Pills
                    if (attachmentList.isNotEmpty()) {
                        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                            attachmentList.forEachIndexed { index, fileObj ->
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .clip(RoundedCornerShape(10.dp))
                                        .background(Color(0xFF26262A))
                                        .padding(horizontal = 12.dp, vertical = 8.dp),
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                                ) {
                                    val name = fileObj.optString("name", "Attachment")
                                    val isImg = name.endsWith(".png") || name.endsWith(".jpg") || name.endsWith(".jpeg")
                                    Icon(
                                        imageVector = if (isImg) Icons.Default.Image else Icons.Default.AttachFile,
                                        contentDescription = null,
                                        tint = LaterboxAccent,
                                        modifier = Modifier.size(15.dp)
                                    )
                                    Text(
                                        text = name,
                                        fontSize = 13.sp,
                                        fontWeight = FontWeight.Medium,
                                        color = Color.White,
                                        maxLines = 1,
                                        modifier = Modifier.weight(1f)
                                    )
                                    Icon(
                                        imageVector = Icons.Default.Close,
                                        contentDescription = "Remove attachment",
                                        tint = Color.White.copy(alpha = 0.5f),
                                        modifier = Modifier
                                            .size(16.dp)
                                            .clickable { attachmentList.removeAt(index) }
                                    )
                                }
                            }
                        }
                    }

                    // Web Link Detected Pill
                    if (detectedUrl != null) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(10.dp))
                                .background(Color(0xFF222226))
                                .border(1.dp, Color.White.copy(alpha = 0.08f), RoundedCornerShape(10.dp))
                            .padding(horizontal = 12.dp, vertical = 8.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.Link,
                                contentDescription = null,
                                tint = LaterboxAccent,
                                modifier = Modifier.size(16.dp)
                            )
                            Text(
                                text = "Web link detected",
                                fontSize = 12.sp,
                                fontWeight = FontWeight.SemiBold,
                                color = LaterboxAccent
                            )
                            Spacer(Modifier.weight(1f))
                            val cleanHost = runCatching { URI(detectedUrl).host?.removePrefix("www.") }.getOrNull() ?: ""
                            Text(
                                text = cleanHost,
                                fontSize = 11.sp,
                                color = Color.White.copy(alpha = 0.5f)
                            )
                            if (isFetchingMetadata) {
                                CircularProgressIndicator(
                                    modifier = Modifier.size(12.dp),
                                    strokeWidth = 2.dp,
                                    color = LaterboxAccent
                                )
                            }
                        }
                    }
                }
            }

            1 -> {
                // Step 1: "Give it a title"
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    verticalArrangement = Arrangement.spacedBy(14.dp)
                ) {
                    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Text(
                            text = "Give it a title",
                            fontWeight = FontWeight.Bold,
                            fontSize = 17.sp,
                            color = Color.White
                        )
                        Text(
                            text = "A clear title helps you find and remember this item.",
                            fontSize = 13.sp,
                            color = Color.White.copy(alpha = 0.6f)
                        )
                    }

                    // TITLE FIELD
                    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text(
                            text = "TITLE",
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color.White.copy(alpha = 0.5f)
                        )
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(12.dp))
                                .background(Color(0xFF1F1F22))
                                .border(1.dp, Color.White.copy(alpha = 0.12f), RoundedCornerShape(12.dp))
                                .padding(horizontal = 14.dp, vertical = 12.dp)
                        ) {
                            BasicTextField(
                                value = title,
                                onValueChange = { title = it },
                                singleLine = true,
                                textStyle = TextStyle(fontSize = 15.sp, fontWeight = FontWeight.Medium, color = Color.White),
                                cursorBrush = SolidColor(LaterboxAccent),
                                modifier = Modifier.fillMaxWidth(),
                                decorationBox = { inner ->
                                    if (title.isEmpty()) Text("Title", fontSize = 15.sp, color = Color.White.copy(alpha = 0.35f))
                                    inner()
                                }
                            )
                        }
                    }

                    // NOTES / SUMMARY FIELD
                    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text(
                            text = "NOTES OR SUMMARY (OPTIONAL)",
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color.White.copy(alpha = 0.5f)
                        )
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .heightIn(min = 70.dp, max = 120.dp)
                                .clip(RoundedCornerShape(12.dp))
                                .background(Color(0xFF1F1F22))
                                .border(1.dp, Color.White.copy(alpha = 0.12f), RoundedCornerShape(12.dp))
                                .padding(12.dp)
                        ) {
                            BasicTextField(
                                value = summary,
                                onValueChange = { summary = it },
                                textStyle = TextStyle(fontSize = 14.sp, color = Color.White),
                                cursorBrush = SolidColor(LaterboxAccent),
                                modifier = Modifier
                                    .fillMaxSize()
                                    .verticalScroll(rememberScrollState()),
                                decorationBox = { inner ->
                                    if (summary.isEmpty()) Text("Add context or key takeaways", fontSize = 14.sp, color = Color.White.copy(alpha = 0.35f))
                                    inner()
                                }
                            )
                        }
                    }
                }
            }

            2 -> {
                // Step 2: "Format, Category & Tags"
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    verticalArrangement = Arrangement.spacedBy(14.dp)
                ) {
                    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Text(
                            text = "Format, Category & Tags",
                            fontWeight = FontWeight.Bold,
                            fontSize = 17.sp,
                            color = Color.White
                        )
                        Text(
                            text = "Organize this capture so you can filter it later.",
                            fontSize = 13.sp,
                            color = Color.White.copy(alpha = 0.6f)
                        )
                    }

                    // FORMAT SECTION
                    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text(
                            text = "FORMAT",
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color.White.copy(alpha = 0.5f)
                        )
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .horizontalScroll(rememberScrollState()),
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            FormatPill(
                                title = "Automatic (${detectedType.replaceFirstChar { it.uppercase() }})",
                                isSelected = selectedFormat == null,
                                onClick = { selectedFormat = null }
                            )
                            FormatPill("Article", Icons.AutoMirrored.Filled.Article, selectedFormat == "article") { selectedFormat = "article" }
                            FormatPill("Video", Icons.Default.PlayCircle, selectedFormat == "video") { selectedFormat = "video" }
                            FormatPill("Note", Icons.Default.EditNote, selectedFormat == "note") { selectedFormat = "note" }
                            FormatPill("Document", Icons.Default.Description, selectedFormat == "document") { selectedFormat = "document" }
                            FormatPill("Image", Icons.Default.Image, selectedFormat == "image") { selectedFormat = "image" }
                            FormatPill("Music", Icons.Default.MusicNote, selectedFormat == "music") { selectedFormat = "music" }
                            FormatPill("Link", Icons.Default.Link, selectedFormat == "link") { selectedFormat = "link" }
                        }
                    }

                    // CATEGORY SECTION
                    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text(
                            text = "CATEGORY",
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color.White.copy(alpha = 0.5f)
                        )
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .horizontalScroll(rememberScrollState()),
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            listOf("General", "Reading", "Work", "Ideas", "Learning", "Personal").forEach { cat ->
                                FormatPill(
                                    title = cat,
                                    isSelected = category == cat,
                                    onClick = { category = if (category == cat) "" else cat }
                                )
                            }
                        }
                    }

                    // TAGS SECTION
                    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text(
                            text = "TAGS",
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color.White.copy(alpha = 0.5f)
                        )
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(12.dp))
                                .background(Color(0xFF1F1F22))
                                .border(1.dp, Color.White.copy(alpha = 0.12f), RoundedCornerShape(12.dp))
                                .padding(horizontal = 14.dp, vertical = 12.dp)
                        ) {
                            BasicTextField(
                                value = tagText,
                                onValueChange = { tagText = it },
                                singleLine = true,
                                textStyle = TextStyle(fontSize = 14.sp, color = Color.White),
                                cursorBrush = SolidColor(LaterboxAccent),
                                modifier = Modifier.fillMaxWidth(),
                                decorationBox = { inner ->
                                    if (tagText.isEmpty()) Text("Tags, separated by commas", fontSize = 14.sp, color = Color.White.copy(alpha = 0.35f))
                                    inner()
                                }
                            )
                        }

                        // Suggested Tags Chips
                        if (suggestedTags.isNotEmpty()) {
                            Row(
                                modifier = Modifier.padding(top = 2.dp),
                                horizontalArrangement = Arrangement.spacedBy(6.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text("Suggested:", fontSize = 11.sp, color = Color.White.copy(alpha = 0.5f))
                                suggestedTags.forEach { tag ->
                                    Surface(
                                        shape = CircleShape,
                                        color = Color(0xFF26262A),
                                        border = BorderStroke(1.dp, Color.White.copy(alpha = 0.1f)),
                                        modifier = Modifier.clickable {
                                            val current = tagText.split(",").map { it.trim() }.filter { it.isNotBlank() }
                                            if (tag !in current) {
                                                tagText = if (tagText.isBlank()) tag else "$tagText, $tag"
                                            }
                                        }
                                    ) {
                                        Text(
                                            text = "#$tag",
                                            fontSize = 11.sp,
                                            fontWeight = FontWeight.Medium,
                                            color = LaterboxAccent,
                                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }

            3 -> {
                // Step 3: "When do you want to see it again?"
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    verticalArrangement = Arrangement.spacedBy(14.dp)
                ) {
                    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Text(
                            text = "When do you want to see it again?",
                            fontWeight = FontWeight.Bold,
                            fontSize = 17.sp,
                            color = Color.White
                        )
                        Text(
                            text = "Set a reminder date or save to your inbox for later.",
                            fontSize = 13.sp,
                            color = Color.White.copy(alpha = 0.6f)
                        )
                    }

                    val tomorrow = remember {
                        LocalDate.now().plusDays(1).atTime(9, 0).atZone(ZoneId.systemDefault()).toInstant().toString()
                    }
                    val weekend = remember {
                        LocalDate.now().with(TemporalAdjusters.next(DayOfWeek.SATURDAY)).atTime(9, 0).atZone(ZoneId.systemDefault()).toInstant().toString()
                    }
                    val nextWeek = remember {
                        LocalDate.now().plusDays(7).atTime(9, 0).atZone(ZoneId.systemDefault()).toInstant().toString()
                    }

                    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        ScheduleChoiceRow(
                            title = "Tomorrow",
                            subtitle = "9:00 AM",
                            icon = Icons.Default.Schedule,
                            isSelected = returnAt == tomorrow && !customReturnDate,
                            onClick = { customReturnDate = false; returnAt = tomorrow }
                        )

                        ScheduleChoiceRow(
                            title = "This Weekend",
                            subtitle = "Saturday morning",
                            icon = Icons.Default.WbSunny,
                            isSelected = returnAt == weekend && !customReturnDate,
                            onClick = { customReturnDate = false; returnAt = weekend }
                        )

                        ScheduleChoiceRow(
                            title = "Next Week",
                            subtitle = "7 days from now",
                            icon = Icons.Default.CalendarToday,
                            isSelected = returnAt == nextWeek && !customReturnDate,
                            onClick = { customReturnDate = false; returnAt = nextWeek }
                        )

                        ScheduleChoiceRow(
                            title = "No Reminder",
                            subtitle = "Keep in inbox",
                            icon = Icons.Default.Inbox,
                            isSelected = returnAt == null && !customReturnDate,
                            onClick = { customReturnDate = false; returnAt = null }
                        )

                        ScheduleChoiceRow(
                            title = "Choose Date",
                            subtitle = if (customReturnDate && returnAt != null) "Custom date & time selected" else "Custom date & time",
                            icon = Icons.Default.Tune,
                            isSelected = customReturnDate,
                            onClick = { customReturnDate = true }
                        )
                    }

                    if (customReturnDate) {
                        CustomReturnDialog(
                            onDismiss = { customReturnDate = false },
                            onSelect = {
                                returnAt = it
                                customReturnDate = false
                            }
                        )
                    }

                    if (returnAt != null) {
                        Row(
                            modifier = Modifier
                                .clip(RoundedCornerShape(8.dp))
                                .background(Color(0xFF222226))
                                .padding(horizontal = 10.dp, vertical = 6.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(6.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.Notifications,
                                contentDescription = null,
                                tint = LaterboxAccent,
                                modifier = Modifier.size(13.dp)
                            )
                            val formatted = runCatching {
                                Instant.parse(returnAt).atZone(ZoneId.systemDefault()).format(DateTimeFormatter.ofPattern("EEE, MMM d 'at' h:mm a"))
                            }.getOrDefault(returnAt ?: "")
                            Text(
                                text = "Returns: $formatted",
                                fontSize = 12.sp,
                                fontWeight = FontWeight.SemiBold,
                                color = Color.White
                            )
                        }
                    }
                }
            }
        }

        // Footer Navigation: Back (if step > 0), Attach (+), and Continue / Save
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 4.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            if (step > 0) {
                Surface(
                    modifier = Modifier
                        .size(46.dp)
                        .clip(CircleShape)
                        .clickable { step-- },
                    shape = CircleShape,
                    color = Color(0xFF26262A),
                    border = BorderStroke(1.dp, Color.White.copy(alpha = 0.12f))
                ) {
                    Box(contentAlignment = Alignment.Center, modifier = Modifier.fillMaxSize()) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back",
                            tint = Color.White,
                            modifier = Modifier.size(18.dp)
                        )
                    }
                }
            }

            // '+' Attachment Options Button
            Surface(
                modifier = Modifier
                    .size(46.dp)
                    .clip(CircleShape)
                    .clickable { filePickerLauncher.launch("*/*") },
                shape = CircleShape,
                color = Color(0xFF26262A),
                border = BorderStroke(1.dp, Color.White.copy(alpha = 0.12f))
            ) {
                Box(contentAlignment = Alignment.Center, modifier = Modifier.fillMaxSize()) {
                    Icon(
                        imageVector = Icons.Default.AttachFile,
                        contentDescription = "Add attachment",
                        tint = LaterboxAccent,
                        modifier = Modifier.size(20.dp)
                    )
                }
            }

            // Continue / Save Button
            Button(
                onClick = {
                    if (step == 0) {
                        // Extract title from web or text line if still blank
                        if (title.isBlank()) {
                            if (attachmentList.isNotEmpty()) {
                                title = attachmentList.firstOrNull()?.optString("name", "Attachment")?.substringBeforeLast('.').orEmpty()
                            } else if (detectedUrl != null) {
                                title = runCatching { URI(detectedUrl).host?.removePrefix("www.") }.getOrNull() ?: detectedUrl
                            } else {
                                title = content.lineSequence().firstOrNull { it.isNotBlank() }?.take(80) ?: "Note"
                            }
                        }
                        // Extract any #hashtags if tags field is blank
                        if (tagText.isBlank()) {
                            val hashtags = Regex("#([\\p{L}\\d_-]+)").findAll(content).map { it.groupValues[1] }.toList()
                            if (hashtags.isNotEmpty()) {
                                tagText = hashtags.joinToString(", ")
                            }
                        }
                        step = 1
                    } else if (step == 1) {
                        step = 2
                    } else if (step == 2) {
                        step = 3
                    } else {
                        // Save to vault directly (Step 3 completed)
                        val finalType = selectedFormat ?: detectedType
                        val item = VaultStore.draft(
                            content = content,
                            title = title,
                            tags = tagText,
                            category = category,
                            returnAt = returnAt,
                            attachments = currentAttachmentsJson,
                            id = id,
                            type = finalType,
                            summary = summary
                        )
                        onSave(item)
                    }
                },
                enabled = canProceed,
                shape = RoundedCornerShape(14.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = LaterboxAccent,
                    contentColor = Color(0xFF171711),
                    disabledContainerColor = Color.White.copy(alpha = 0.12f),
                    disabledContentColor = Color.White.copy(alpha = 0.35f)
                ),
                modifier = Modifier
                    .weight(1f)
                    .height(46.dp)
            ) {
                Text(
                    text = if (step == 3) "Save to vault" else "Continue",
                    fontWeight = FontWeight.Bold,
                    fontSize = 15.sp
                )
            }
        }
    }
}

@Composable
private fun FormatPill(
    title: String,
    icon: ImageVector? = null,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    Surface(
        modifier = Modifier
            .clip(RoundedCornerShape(14.dp))
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(14.dp),
        color = if (isSelected) LaterboxAccent else Color(0xFF26262A),
        border = if (isSelected) null else BorderStroke(1.dp, Color.White.copy(alpha = 0.12f))
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 14.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(5.dp)
        ) {
            if (icon != null) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = if (isSelected) Color(0xFF171711) else Color.White,
                    modifier = Modifier.size(13.dp)
                )
            }
            Text(
                text = title,
                fontSize = 13.sp,
                fontWeight = FontWeight.SemiBold,
                color = if (isSelected) Color(0xFF171711) else Color.White
            )
        }
    }
}

@Composable
private fun ScheduleChoiceRow(
    title: String,
    subtitle: String,
    icon: ImageVector,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(14.dp),
        color = if (isSelected) LaterboxAccent else Color(0xFF1F1F22),
        border = if (isSelected) null else BorderStroke(1.dp, Color.White.copy(alpha = 0.08f))
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 14.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Surface(
                modifier = Modifier.size(32.dp),
                shape = CircleShape,
                color = if (isSelected) Color.Black.copy(alpha = 0.15f) else Color(0xFF28282C)
            ) {
                Box(contentAlignment = Alignment.Center, modifier = Modifier.fillMaxSize()) {
                    Icon(
                        imageVector = icon,
                        contentDescription = null,
                        tint = if (isSelected) Color(0xFF171711) else LaterboxAccent,
                        modifier = Modifier.size(16.dp)
                    )
                }
            }

            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text(
                    text = title,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = if (isSelected) Color(0xFF171711) else Color.White
                )
                Text(
                    text = subtitle,
                    fontSize = 11.sp,
                    color = if (isSelected) Color.Black.copy(alpha = 0.7f) else Color.White.copy(alpha = 0.55f)
                )
            }

            if (isSelected) {
                Icon(
                    imageVector = Icons.Default.CheckCircle,
                    contentDescription = null,
                    tint = Color(0xFF171711),
                    modifier = Modifier.size(18.dp)
                )
            }
        }
    }
}

@Composable
fun CustomReturnDialog(onDismiss: () -> Unit, onSelect: (String) -> Unit) {
    var day by rememberSaveable { mutableStateOf(LocalDate.now().plusDays(1).toString()) }
    var time by rememberSaveable { mutableStateOf("09:00") }
    var error by remember { mutableStateOf<String?>(null) }

    androidx.compose.ui.window.Dialog(onDismissRequest = onDismiss) {
        Surface(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(20.dp),
            color = Color(0xFF1E1E22),
            border = BorderStroke(1.dp, Color.White.copy(alpha = 0.12f))
        ) {
            Column(
                modifier = Modifier.padding(20.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Text(
                    text = "Choose Return Date & Time",
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )

                OutlinedTextField(
                    value = day,
                    onValueChange = { day = it },
                    label = { Text("Date (YYYY-MM-DD)") },
                    singleLine = true,
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedTextColor = Color.White,
                        unfocusedTextColor = Color.White,
                        focusedBorderColor = LaterboxAccent,
                        unfocusedBorderColor = Color.White.copy(alpha = 0.2f),
                        focusedLabelColor = LaterboxAccent,
                        unfocusedLabelColor = Color.White.copy(alpha = 0.6f)
                    ),
                    modifier = Modifier.fillMaxWidth()
                )

                OutlinedTextField(
                    value = time,
                    onValueChange = { time = it },
                    label = { Text("Time (HH:mm)") },
                    singleLine = true,
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedTextColor = Color.White,
                        unfocusedTextColor = Color.White,
                        focusedBorderColor = LaterboxAccent,
                        unfocusedBorderColor = Color.White.copy(alpha = 0.2f),
                        focusedLabelColor = LaterboxAccent,
                        unfocusedLabelColor = Color.White.copy(alpha = 0.6f)
                    ),
                    modifier = Modifier.fillMaxWidth()
                )

                error?.let { Text(it, color = Color(0xFFEF4444), fontSize = 12.sp) }

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.End,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    TextButton(onClick = onDismiss) {
                        Text("Cancel", color = Color.White.copy(alpha = 0.6f))
                    }
                    Spacer(Modifier.width(8.dp))
                    Button(
                        onClick = {
                            runCatching {
                                LocalDate.parse(day).atTime(LocalTime.parse(time)).atZone(ZoneId.systemDefault()).toInstant().also {
                                    require(it.isAfter(Instant.now()))
                                }.toString()
                            }.onSuccess(onSelect).onFailure { error = "Choose a valid future date and time." }
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = LaterboxAccent, contentColor = Color(0xFF171711))
                    ) {
                        Text("Confirm", fontWeight = FontWeight.Bold)
                    }
                }
            }
        }
    }
}

@Composable
fun ReturnChoices(dark: Boolean = false, onSelect: (String?) -> Unit) {
    var custom by remember { mutableStateOf(false) }
    val tomorrow = LocalDate.now().plusDays(1).atTime(9, 0).atZone(ZoneId.systemDefault()).toInstant().toString()
    val weekend = LocalDate.now().with(TemporalAdjusters.next(DayOfWeek.SATURDAY)).atTime(9, 0).atZone(ZoneId.systemDefault()).toInstant().toString()
    Choice("Tomorrow", "9:00 AM", dark) { onSelect(tomorrow) }
    Choice("This weekend", "Saturday at 9:00 AM", dark) { onSelect(weekend) }
    Choice("Choose date", "Set a custom return", dark) { custom = true }
    Choice("No reminder", "Keep in inbox", dark) { onSelect(null) }
    if (custom) CustomReturnDialog(onDismiss = { custom = false }, onSelect = { custom = false; onSelect(it) })
}

@Composable
fun Field(value: String, change: (String) -> Unit, label: String, dark: Boolean = false) {
    OutlinedTextField(
        value = value,
        onValueChange = change,
        label = { Text(label) },
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(14.dp),
        colors = OutlinedTextFieldDefaults.colors(
            focusedTextColor = if (dark) Color.White else Color.Black,
            unfocusedTextColor = if (dark) Color.White else Color.Black,
            focusedBorderColor = LaterboxAccent,
            unfocusedBorderColor = Color.Gray,
            focusedLabelColor = if (dark) LaterboxAccent else Color.Black,
            unfocusedLabelColor = Color.Gray
        )
    )
}
