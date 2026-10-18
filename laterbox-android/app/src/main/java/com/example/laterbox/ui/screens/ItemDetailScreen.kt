package com.example.laterbox.ui.screens

import android.app.DatePickerDialog
import android.app.TimePickerDialog
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.OpenInNew
import androidx.compose.material.icons.automirrored.filled.Reply
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.Folder
import androidx.compose.material.icons.outlined.StarBorder
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.core.content.FileProvider
import com.example.laterbox.data.ItemThreadData
import com.example.laterbox.data.ItemThreadEntry
import com.example.laterbox.data.ItemThreadParser
import com.example.laterbox.data.POPULAR_REACTIONS
import com.example.laterbox.data.DataRepository
import com.example.laterbox.data.local.CollectionEntity
import com.example.laterbox.data.local.ItemEntity
import com.example.laterbox.services.VaultStore
import com.example.laterbox.theme.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONArray
import java.io.File
import java.time.Instant
import java.util.Calendar
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit

@Composable
fun ItemDetailScreen(
    initialItem: ItemEntity,
    repository: DataRepository,
    onBack: () -> Unit,
    onChanged: () -> Unit = {}
) {
    val items by repository.items.collectAsState(emptyList())
    val collections by repository.collections.collectAsState(emptyList())
    val item = items.find { it.id == initialItem.id } ?: initialItem
    val metadata by remember(repository, item.id) { repository.watchMetadata(item.id) }.collectAsState(null)
    val account by com.example.laterbox.services.AccountService.state.collectAsState()

    if (item.userId != null && item.userId != account.userId) {
        LaunchedEffect(item.id, account.userId) { onBack() }
        return
    }

    val context = LocalContext.current
    val store = remember { VaultStore(context) }
    val scope = rememberCoroutineScope()

    // Notes & Thread State
    var threadData by remember(item.notes) { mutableStateOf(ItemThreadParser.parse(item.notes)) }
    var noteDraftText by remember { mutableStateOf("") }
    var quotedSnippet by remember { mutableStateOf<String?>(null) }
    var activeReactionPickerForId by remember { mutableStateOf<String?>(null) }

    // Dialog & UI State
    var showingDeleteConfirm by remember { mutableStateOf(false) }
    var showingCollectionSheet by remember { mutableStateOf(false) }
    var showingSchedulePicker by remember { mutableStateOf(false) }
    var editingTitle by remember { mutableStateOf(false) }
    var editedTitle by remember(item.title) { mutableStateOf(item.title.orEmpty()) }
    var busy by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }

    fun update(updated: ItemEntity, close: Boolean = false) {
        if (busy) return
        scope.launch {
            busy = true
            error = null
            try {
                store.edit(updated)
                repository.syncNow()
                onChanged()
                if (close) onBack()
            } catch (cancelled: kotlinx.coroutines.CancellationException) {
                throw cancelled
            } catch (_: Exception) {
                error = "Unable to save changes. Please try again."
            } finally {
                busy = false
            }
        }
    }

    fun persistThread(newThread: ItemThreadData) {
        threadData = newThread
        val serialized = ItemThreadParser.serialize(newThread)
        update(item.copy(notes = serialized))
    }

    fun sendNote() {
        val trimmed = noteDraftText.trim()
        if (trimmed.isBlank()) return
        val updated = ItemThreadParser.addEntry(
            thread = threadData,
            authorName = "Me",
            content = trimmed,
            attachedSnippet = quotedSnippet
        )
        noteDraftText = ""
        quotedSnippet = null
        persistThread(updated)
    }

    fun open(intent: Intent) {
        runCatching { context.startActivity(intent) }
            .onFailure { error = "No app is available to open or share this content." }
    }

    fun share() {
        val shareText = cleanText(item.url) ?: cleanText(item.textContent) ?: cleanText(item.title).orEmpty()
        open(Intent.createChooser(Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_TEXT, shareText), "Share item"))
    }

    fun copyLinkOrText() {
        val text = cleanText(item.url) ?: cleanText(item.title).orEmpty()
        val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        clipboard.setPrimaryClip(ClipData.newPlainText("LaterBox item", text))
    }

    BackHandler { onBack() }

    // Domain & sender computations
    val domainOrSender = remember(metadata, item.url, item.type, item.attachments) {
        val site = cleanText(metadata?.siteName)
        if (site != null) return@remember site
        val domain = cleanText(metadata?.domain) ?: cleanText(item.url)?.let {
            runCatching { java.net.URI(it).host?.removePrefix("www.") }.getOrNull()
        }
        val cleanDomain = cleanText(domain)
        if (cleanDomain != null) return@remember cleanDomain
        val hasFiles = item.attachments.isNotBlank() && item.attachments != "[]"
        if (hasFiles) return@remember "File"
        val cleanType = cleanText(item.type)
        if (cleanType == "note") return@remember "Note"
        if (cleanType == "file") return@remember "File"
        if (cleanType == "image") return@remember "Photo"
        cleanType?.replaceFirstChar { it.uppercase() } ?: "LaterBox"
    }
    val senderInitial = remember(domainOrSender) {
        domainOrSender.firstOrNull { it.isLetterOrDigit() }?.uppercaseChar()?.toString() ?: "L"
    }

    Box(
        Modifier
            .fillMaxSize()
            .background(LaterboxBg)
    ) {
        Column(Modifier.fillMaxSize()) {
            // 1. TOP NAVIGATION BAR (Actions top-right matching iOS & Web)
            Row(
                Modifier
                    .fillMaxWidth()
                    .statusBarsPadding()
                    .padding(horizontal = 14.dp, vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Back Button
                Row(
                    Modifier
                        .clip(RoundedCornerShape(8.dp))
                        .clickable { onBack() }
                        .padding(vertical = 6.dp, horizontal = 4.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        Icons.AutoMirrored.Filled.ArrowBack,
                        contentDescription = "Back",
                        tint = LaterboxTextPrimary,
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(Modifier.width(4.dp))
                    Text(
                        "Back",
                        fontSize = 14.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = LaterboxTextPrimary
                    )
                }

                Spacer(Modifier.weight(1f))

                // Grouped Action Controls on Top Right
                Row(
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // 1. Star / Favorite Button
                    Box(
                        Modifier
                            .size(34.dp)
                            .clip(RoundedCornerShape(10.dp))
                            .background(if (item.favorite) Color(0xFFFEF3C7) else Color.White)
                            .border(BorderStroke(1.dp, Color.Black.copy(alpha = 0.08f)), RoundedCornerShape(10.dp))
                            .clickable(enabled = !busy) { update(item.copy(favorite = !item.favorite)) },
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            if (item.favorite) Icons.Default.Star else Icons.Outlined.StarBorder,
                            contentDescription = if (item.favorite) "Unstar" else "Star",
                            tint = if (item.favorite) Color(0xFFF59E0B) else Color(0xFF6C6B63),
                            modifier = Modifier.size(17.dp)
                        )
                    }

                    // 2. Status Action Pill (Keep / Archive / Move to Inbox)
                    val statusIsActive = item.status == "inbox" || item.status == "deferred"
                    val statusIsSaved = item.status == "done" || item.status == "saved"
                    Row(
                        Modifier
                            .height(34.dp)
                            .clip(RoundedCornerShape(10.dp))
                            .background(if (statusIsActive) Color(0xFFE6EDB0) else Color.White)
                            .border(BorderStroke(1.dp, Color.Black.copy(alpha = 0.08f)), RoundedCornerShape(10.dp))
                            .clickable(enabled = !busy) {
                                val nextStatus = when {
                                    statusIsActive -> "done"
                                    statusIsSaved -> "archived"
                                    else -> "inbox"
                                }
                                update(item.copy(status = nextStatus))
                            }
                            .padding(horizontal = 10.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            when {
                                statusIsActive -> Icons.Default.CheckCircle
                                statusIsSaved -> Icons.Default.Archive
                                else -> Icons.Default.Inbox
                            },
                            contentDescription = "Status action",
                            tint = Color(0xFF171711),
                            modifier = Modifier.size(13.dp)
                        )
                        Spacer(Modifier.width(4.dp))
                        Text(
                            when {
                                statusIsActive -> "Keep"
                                statusIsSaved -> "Archive"
                                else -> "Inbox"
                            },
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color(0xFF171711)
                        )
                    }

                    // 3. Collection Button
                    val hasCollection = cleanText(item.collectionId) != null || cleanText(item.category) != null
                    Box(
                        Modifier
                            .size(34.dp)
                            .clip(RoundedCornerShape(10.dp))
                            .background(Color.White)
                            .border(BorderStroke(1.dp, Color.Black.copy(alpha = 0.08f)), RoundedCornerShape(10.dp))
                            .clickable { showingCollectionSheet = true },
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            if (hasCollection) Icons.Default.Folder else Icons.Outlined.Folder,
                            contentDescription = "Collections",
                            tint = Color(0xFF0369A1),
                            modifier = Modifier.size(16.dp)
                        )
                    }

                    // 4. Share / Copy Link Button
                    Box(
                        Modifier
                            .size(34.dp)
                            .clip(RoundedCornerShape(10.dp))
                            .background(Color.White)
                            .border(BorderStroke(1.dp, Color.Black.copy(alpha = 0.08f)), RoundedCornerShape(10.dp))
                            .clickable { share() },
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            Icons.Default.Share,
                            contentDescription = "Share",
                            tint = Color(0xFF6C6B63),
                            modifier = Modifier.size(15.dp)
                        )
                    }

                    // 5. External Link Button (if item.url exists and is a valid web link)
                    cleanText(item.url)?.takeIf { it.startsWith("http://", ignoreCase = true) || it.startsWith("https://", ignoreCase = true) }?.let { url ->
                        Box(
                            Modifier
                                .size(34.dp)
                                .clip(RoundedCornerShape(10.dp))
                                .background(Color.White)
                                .border(BorderStroke(1.dp, Color.Black.copy(alpha = 0.08f)), RoundedCornerShape(10.dp))
                                .clickable { open(Intent(Intent.ACTION_VIEW, Uri.parse(url))) },
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                Icons.AutoMirrored.Filled.OpenInNew,
                                contentDescription = "Open original",
                                tint = Color(0xFF6C6B63),
                                modifier = Modifier.size(15.dp)
                            )
                        }
                    }

                    // 6. Delete Button
                    Box(
                        Modifier
                            .size(34.dp)
                            .clip(RoundedCornerShape(10.dp))
                            .background(Color.White)
                            .border(BorderStroke(1.dp, Color.Black.copy(alpha = 0.08f)), RoundedCornerShape(10.dp))
                            .clickable(enabled = !busy) { showingDeleteConfirm = true },
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            Icons.Default.Delete,
                            contentDescription = "Delete item",
                            tint = Color(0xFFEF4444),
                            modifier = Modifier.size(16.dp)
                        )
                    }
                }
            }

            // 2. SCROLLABLE CONTENT BODY
            Column(
                Modifier
                    .fillMaxWidth()
                    .weight(1f)
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 14.dp, vertical = 10.dp),
                verticalArrangement = Arrangement.spacedBy(14.dp)
            ) {
                error?.let {
                    Surface(
                        color = Color(0xFFFEE2E2),
                        shape = RoundedCornerShape(10.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text(it, color = Color(0xFFDC2626), modifier = Modifier.padding(12.dp), fontSize = 13.sp)
                    }
                }

                // Return Schedule Banner (if scheduled)
                item.returnAt?.let { retIso ->
                    val retParsed = runCatching { Instant.parse(retIso) }.getOrNull()
                    val isTodayOrOverdue = retParsed?.let { it.isBefore(Instant.now().plus(24, ChronoUnit.HOURS)) } ?: false
                    Surface(
                        color = Color.White,
                        shape = RoundedCornerShape(14.dp),
                        border = BorderStroke(1.dp, Color.Black.copy(alpha = 0.06f)),
                        shadowElevation = 2.dp,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Row(
                            Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(10.dp)
                        ) {
                            Box(
                                Modifier
                                    .size(30.dp)
                                    .clip(CircleShape)
                                    .background(if (isTodayOrOverdue) Color(0xFF171711) else Color(0xFFE6EDB0)),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(
                                    Icons.Default.Schedule,
                                    contentDescription = null,
                                    tint = if (isTodayOrOverdue) Color(0xFFE6EDB0) else Color(0xFF171711),
                                    modifier = Modifier.size(15.dp)
                                )
                            }
                            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(1.dp)) {
                                Text(
                                    if (isTodayOrOverdue) "Due Today" else "Scheduled Return",
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = LaterboxTextPrimary
                                )
                                Text(
                                    detailDate(retIso),
                                    fontSize = 11.sp,
                                    color = LaterboxTextSecondary
                                )
                            }
                            Button(
                                onClick = { showingSchedulePicker = true },
                                colors = ButtonDefaults.buttonColors(containerColor = Color.Black.copy(alpha = 0.05f), contentColor = LaterboxTextPrimary),
                                contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp),
                                shape = RoundedCornerShape(14.dp),
                                modifier = Modifier.height(28.dp)
                            ) {
                                Text("Reschedule", fontSize = 11.sp, fontWeight = FontWeight.Bold)
                            }
                            IconButton(
                                onClick = { update(item.copy(returnAt = null, status = "inbox")) },
                                modifier = Modifier.size(24.dp)
                            ) {
                                Icon(Icons.Default.Close, contentDescription = "Cancel schedule", tint = LaterboxTextSecondary, modifier = Modifier.size(14.dp))
                            }
                        }
                    }
                }

                // Attachments & Files Card (Component 2: right after Return Schedule Banner, matching iOS)
                val rawAttachments = cleanText(item.attachments)
                val attachments = remember(rawAttachments) {
                    if (rawAttachments != null && rawAttachments != "[]") {
                        runCatching { JSONArray(rawAttachments) }.getOrNull()
                    } else null
                }
                attachments?.takeIf { it.length() > 0 }?.let { files ->
                    Surface(
                        color = Color.White,
                        shape = RoundedCornerShape(16.dp),
                        border = BorderStroke(1.dp, Color.Black.copy(alpha = 0.06f)),
                        shadowElevation = 2.dp,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                Icon(Icons.Default.AttachFile, contentDescription = null, tint = LaterboxTextSecondary, modifier = Modifier.size(14.dp))
                                Text("ATTACHMENTS & FILES (${files.length()})", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = LaterboxTextSecondary, letterSpacing = 0.6.sp)
                            }
                            for (index in 0 until files.length()) {
                                val attachment = files.optJSONObject(index) ?: continue
                                val name = cleanText(attachment.optString("name")) ?: "Attachment ${index + 1}"
                                val mime = cleanText(attachment.optString("mime")) ?: "application/octet-stream"
                                val rawPath = cleanText(attachment.optString("path")).orEmpty()
                                val file = trustedAttachment(rawPath, File(context.filesDir, "captures"))
                                Row(
                                    Modifier
                                        .fillMaxWidth()
                                        .clip(RoundedCornerShape(10.dp))
                                        .background(Color(0xFFFAFAF8))
                                        .padding(10.dp),
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                                ) {
                                    Icon(Icons.Default.Description, contentDescription = null, tint = Color(0xFF171711), modifier = Modifier.size(24.dp))
                                    Column(Modifier.weight(1f)) {
                                        Text(name, fontWeight = FontWeight.SemiBold, fontSize = 13.sp, color = LaterboxTextPrimary, maxLines = 1, overflow = TextOverflow.Ellipsis)
                                        Text(mime.uppercase(), fontSize = 10.sp, fontWeight = FontWeight.Bold, color = LaterboxTextSecondary)
                                    }
                                    if (file != null) {
                                        TextButton(onClick = {
                                             runCatching {
                                                 FileProvider.getUriForFile(context, context.packageName + ".files", file)
                                             }.onSuccess { uri ->
                                                 open(Intent(Intent.ACTION_VIEW).setDataAndType(uri, mime).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION))
                                             }.onFailure { error = "Unable to open attachment." }
                                         }) {
                                             Text("Open", fontSize = 12.sp, fontWeight = FontWeight.Bold)
                                         }
                                    }
                                }
                            }
                        }
                    }
                }

                // Media Preview / Hero Image Card (Component 3: matching iOS)
                val source = cleanText(item.url)
                val kind = directMediaKind(source)
                val embed = hostedMediaPreview(source)

                // Locate first local image attachment if present
                val localImageFile = remember(item.attachments) {
                    val arr = runCatching { JSONArray(item.attachments) }.getOrNull()
                    if (arr != null) {
                        var found: File? = null
                        for (idx in 0 until arr.length()) {
                            val att = arr.optJSONObject(idx) ?: continue
                            val mime = cleanText(att.optString("mime", "")).orEmpty().lowercase()
                            val name = cleanText(att.optString("name", "")).orEmpty().lowercase()
                            val isImg = mime.startsWith("image/") || name.endsWith(".jpg") || name.endsWith(".jpeg") || name.endsWith(".png") || name.endsWith(".webp") || name.endsWith(".gif")
                            if (isImg) {
                                val p = cleanText(att.optString("path")).orEmpty()
                                val f = File(p)
                                if (f.isFile) {
                                    found = f
                                    break
                                }
                                val alt = File(context.filesDir, "captures/${f.name}")
                                if (alt.isFile) {
                                    found = alt
                                    break
                                }
                            }
                        }
                        found
                    } else null
                }

                val remotePreviewImg = sanitizePreviewImageUrl(metadata?.previewImageUrl)
                val effectivePreview = localImageFile ?: remotePreviewImg

                if (source != null && (kind != null || embed != null)) {
                    Surface(
                        color = Color.White,
                        shape = RoundedCornerShape(16.dp),
                        border = BorderStroke(1.dp, Color.Black.copy(alpha = 0.06f)),
                        shadowElevation = 2.dp,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            when {
                                embed != null -> HostedItemPreview(embed)
                                kind == "image" -> ItemImagePreview(
                                    source = localImageFile ?: source,
                                    label = cleanText(item.title).orEmpty(),
                                    fallbackSource = if (localImageFile != null) source else remotePreviewImg,
                                    onClick = {
                                        if (localImageFile != null) {
                                            runCatching {
                                                FileProvider.getUriForFile(context, context.packageName + ".files", localImageFile)
                                            }.onSuccess { uri ->
                                                open(Intent(Intent.ACTION_VIEW).setDataAndType(uri, "image/*").addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION))
                                            }
                                        } else {
                                            open(Intent(Intent.ACTION_VIEW, Uri.parse(source)))
                                        }
                                    }
                                )
                                kind == "video" -> ItemVideoPreview(source)
                                kind == "audio" -> ItemAudioPreview(source)
                                kind == "pdf" -> RemoteItemPdfPreview(source)
                            }
                        }
                    }
                } else if (effectivePreview != null) {
                    Surface(
                        color = Color.White,
                        shape = RoundedCornerShape(16.dp),
                        border = BorderStroke(1.dp, Color.Black.copy(alpha = 0.06f)),
                        shadowElevation = 2.dp,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        ItemImagePreview(
                            source = effectivePreview,
                            label = cleanText(item.title).orEmpty(),
                            fallbackSource = if (effectivePreview == localImageFile) remotePreviewImg else localImageFile,
                            onClick = {
                                if (localImageFile != null) {
                                    runCatching {
                                        FileProvider.getUriForFile(context, context.packageName + ".files", localImageFile)
                                    }.onSuccess { uri ->
                                        open(Intent(Intent.ACTION_VIEW).setDataAndType(uri, "image/*").addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION))
                                    }
                                } else if (!source.isNullOrBlank()) {
                                    open(Intent(Intent.ACTION_VIEW, Uri.parse(source)))
                                }
                            }
                        )
                    }
                }

                // MAIN HEADER CARD (Title, Domain, Metadata, Collections, Reactions)
                Surface(
                    color = Color.White,
                    shape = RoundedCornerShape(16.dp),
                    border = BorderStroke(1.dp, Color.Black.copy(alpha = 0.06f)),
                    shadowElevation = 2.dp,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        // Top sender & metadata chips
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            Box(
                                Modifier
                                    .size(22.dp)
                                    .clip(CircleShape)
                                    .background(Color(0xFF171711)),
                                contentAlignment = Alignment.Center
                            ) {
                                Text(
                                    senderInitial,
                                    fontSize = 10.sp,
                                    fontWeight = FontWeight.Black,
                                    color = Color(0xFFE6EDB0)
                                )
                            }
                            Text(
                                domainOrSender,
                                fontSize = 13.sp,
                                fontWeight = FontWeight.Bold,
                                color = LaterboxTextPrimary
                            )
                            val cleanItemType = cleanText(item.type)
                            if (cleanItemType != null) {
                                Box(
                                    Modifier
                                        .clip(RoundedCornerShape(10.dp))
                                        .background(Color(0xFFE6EDB0))
                                        .padding(horizontal = 7.dp, vertical = 3.dp)
                                ) {
                                    Text(
                                        cleanItemType.replaceFirstChar { it.uppercase() },
                                        fontSize = 10.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = Color(0xFF171711)
                                    )
                                }
                            }
                            Spacer(Modifier.weight(1f))
                            val cleanCreated = cleanText(item.createdAt)
                            if (cleanCreated != null) {
                                Text(
                                    detailDateShort(cleanCreated),
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.Medium,
                                    color = LaterboxTextSecondary
                                )
                            }
                        }

                        // Title (Editable or Bold Header)
                        val cleanTitle = cleanText(item.title) ?: cleanText(metadata?.title) ?: "Untitled item"
                        if (editingTitle) {
                            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                BasicTextField(
                                    value = editedTitle,
                                    onValueChange = { editedTitle = it },
                                    textStyle = TextStyle(fontSize = 18.sp, fontWeight = FontWeight.Bold, color = LaterboxTextPrimary),
                                    modifier = Modifier
                                        .weight(1f)
                                        .border(BorderStroke(1.dp, LaterboxBorder), RoundedCornerShape(8.dp))
                                        .padding(8.dp)
                                )
                                Button(
                                    onClick = {
                                        editingTitle = false
                                        update(item.copy(title = editedTitle))
                                    },
                                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF171711), contentColor = Color(0xFFE6EDB0)),
                                    shape = RoundedCornerShape(8.dp)
                                ) {
                                    Text("Done", fontSize = 12.sp, fontWeight = FontWeight.Bold)
                                }
                            }
                        } else {
                            Row(verticalAlignment = Alignment.Top) {
                                SelectionContainer(Modifier.weight(1f)) {
                                    Text(
                                        cleanTitle,
                                        fontSize = 18.sp,
                                        lineHeight = 24.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = LaterboxTextPrimary
                                    )
                                }
                                IconButton(onClick = { editingTitle = true }, modifier = Modifier.size(28.dp)) {
                                    Icon(Icons.Default.Edit, contentDescription = "Edit title", tint = LaterboxTextSecondary, modifier = Modifier.size(14.dp))
                                }
                            }
                        }

                        // Description snippet
                        val cleanDesc = cleanText(metadata?.description)
                        if (cleanDesc != null && cleanDesc != cleanText(item.summary)) {
                            Text(
                                cleanDesc,
                                fontSize = 13.sp,
                                lineHeight = 18.sp,
                                color = Color(0xFF45443F),
                                maxLines = 4,
                                overflow = TextOverflow.Ellipsis
                            )
                        }

                        // Collections, Tags & Reader View
                        val collectionName = cleanText(collections.find { it.id == item.collectionId }?.name ?: item.category)
                        val validTags = cleanText(item.tags)?.split(",")
                            ?.mapNotNull { cleanText(it) }
                            ?.filter { !it.equals("null", ignoreCase = true) && !it.equals("undefined", ignoreCase = true) }
                            ?: emptyList()
                        val validUrl = cleanText(item.url)?.takeIf { it.startsWith("http://", ignoreCase = true) || it.startsWith("https://", ignoreCase = true) }

                        if (collectionName != null || validTags.isNotEmpty() || validUrl != null) {
                            Row(
                                Modifier.fillMaxWidth(),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(6.dp)
                            ) {
                                collectionName?.let { coll ->
                                    Row(
                                        Modifier
                                            .clip(RoundedCornerShape(6.dp))
                                            .background(Color(0xFFE0F2FE))
                                            .clickable { showingCollectionSheet = true }
                                            .padding(horizontal = 8.dp, vertical = 4.dp),
                                        verticalAlignment = Alignment.CenterVertically,
                                        horizontalArrangement = Arrangement.spacedBy(4.dp)
                                    ) {
                                        Icon(Icons.Default.Folder, contentDescription = null, tint = Color(0xFF0369A1), modifier = Modifier.size(11.dp))
                                        Text(coll, fontSize = 11.sp, fontWeight = FontWeight.Bold, color = Color(0xFF0369A1))
                                    }
                                }

                                if (validTags.isNotEmpty()) {
                                    validTags.take(3).forEach { tag ->
                                        Box(
                                            Modifier
                                                .clip(RoundedCornerShape(6.dp))
                                                .background(Color.Black.copy(alpha = 0.04f))
                                                .padding(horizontal = 8.dp, vertical = 4.dp)
                                        ) {
                                            Text("#$tag", fontSize = 11.sp, fontWeight = FontWeight.SemiBold, color = LaterboxTextSecondary)
                                        }
                                    }
                                }

                                Spacer(Modifier.weight(1f))

                                validUrl?.let { url ->
                                    Row(
                                        Modifier
                                            .clip(RoundedCornerShape(14.dp))
                                            .background(Color(0xFFF7F5EE))
                                            .border(BorderStroke(1.dp, Color.Black.copy(alpha = 0.08f)), RoundedCornerShape(14.dp))
                                            .clickable { open(Intent(Intent.ACTION_VIEW, Uri.parse(url))) }
                                            .padding(horizontal = 9.dp, vertical = 4.dp),
                                        verticalAlignment = Alignment.CenterVertically,
                                        horizontalArrangement = Arrangement.spacedBy(4.dp)
                                    ) {
                                        Icon(Icons.AutoMirrored.Filled.OpenInNew, contentDescription = null, tint = LaterboxTextPrimary, modifier = Modifier.size(11.dp))
                                        Text("Reader", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = LaterboxTextPrimary)
                                    }
                                }
                            }
                        }

                        // Root Reaction Bar for Main Saved Content
                        HorizontalDivider(color = Color.Black.copy(alpha = 0.06f))
                        Row(
                            Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(6.dp)
                        ) {
                            // Active root reactions
                            threadData.rootReactions.forEach { (emoji, count) ->
                                val userReacted = threadData.rootUserReactions.contains(emoji)
                                Row(
                                    Modifier
                                        .clip(RoundedCornerShape(12.dp))
                                        .background(if (userReacted) Color(0xFFE6EDB0) else Color(0xFFF7F5EE))
                                        .border(BorderStroke(1.dp, if (userReacted) Color.Black.copy(alpha = 0.2f) else LaterboxBorder), RoundedCornerShape(12.dp))
                                        .clickable {
                                            val updated = ItemThreadParser.toggleRootReaction(threadData, emoji)
                                            persistThread(updated)
                                        }
                                        .padding(horizontal = 8.dp, vertical = 4.dp),
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                                ) {
                                    Text(emoji, fontSize = 12.sp)
                                    Text("$count", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = Color(0xFF171711))
                                }
                            }

                            // Reaction Picker Toggle for Root
                            Box {
                                IconButton(
                                    onClick = {
                                        activeReactionPickerForId = if (activeReactionPickerForId == "root") null else "root"
                                    },
                                    modifier = Modifier.size(30.dp)
                                ) {
                                    Icon(Icons.Default.Add, contentDescription = "Add reaction", tint = LaterboxTextSecondary, modifier = Modifier.size(16.dp))
                                }

                                if (activeReactionPickerForId == "root") {
                                    Surface(
                                        color = Color.White,
                                        shape = RoundedCornerShape(20.dp),
                                        shadowElevation = 6.dp,
                                        border = BorderStroke(1.dp, Color.Black.copy(alpha = 0.1f)),
                                        modifier = Modifier.padding(top = 34.dp)
                                    ) {
                                        Row(Modifier.padding(6.dp), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                            POPULAR_REACTIONS.forEach { emoji ->
                                                Text(
                                                    emoji,
                                                    fontSize = 18.sp,
                                                    modifier = Modifier
                                                        .clip(CircleShape)
                                                        .clickable {
                                                            activeReactionPickerForId = null
                                                            val updated = ItemThreadParser.toggleRootReaction(threadData, emoji)
                                                            persistThread(updated)
                                                        }
                                                        .padding(4.dp)
                                                )
                                            }
                                        }
                                    }
                                }
                            }

                            Spacer(Modifier.weight(1f))

                            // Reply to main content button
                            Row(
                                Modifier
                                    .clip(RoundedCornerShape(10.dp))
                                    .clickable {
                                        quotedSnippet = item.title ?: domainOrSender
                                    }
                                    .padding(horizontal = 8.dp, vertical = 4.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(4.dp)
                            ) {
                                Icon(Icons.AutoMirrored.Filled.Reply, contentDescription = "Reply", tint = LaterboxTextSecondary, modifier = Modifier.size(14.dp))
                                Text("Reply", fontSize = 12.sp, fontWeight = FontWeight.SemiBold, color = LaterboxTextSecondary)
                            }
                        }
                    }
                }

                // Captured Highlight Quote Card (if saved via extension text highlight)
                val cleanTextSelector = cleanText(item.textSelector)
                val cleanTextContent = cleanText(item.textContent)
                if (cleanTextSelector != null) {
                    val highlightText = cleanTextContent ?: cleanTextSelector
                    Surface(
                        color = Color(0xFFFEF3C7).copy(alpha = 0.7f),
                        shape = RoundedCornerShape(14.dp),
                        border = BorderStroke(1.dp, Color(0xFFFDE68A)),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                            Text(
                                "CAPTURED HIGHLIGHT",
                                fontSize = 10.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color(0xFFB45309),
                                letterSpacing = 0.5.sp
                            )
                            Text(
                                "“$highlightText”",
                                fontSize = 14.sp,
                                fontWeight = FontWeight.Medium,
                                color = Color(0xFF92400E),
                                lineHeight = 20.sp
                            )
                        }
                    }
                }

                // AI Summary Card (if present)
                val cleanSummary = cleanText(item.summary)
                if (cleanSummary != null) {
                    Surface(
                        color = Color.White,
                        shape = RoundedCornerShape(16.dp),
                        border = BorderStroke(1.dp, Color.Black.copy(alpha = 0.06f)),
                        shadowElevation = 2.dp,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                Icon(Icons.Default.AutoAwesome, contentDescription = null, tint = Color(0xFF1A73E8), modifier = Modifier.size(15.dp))
                                Text("AI Summary", fontSize = 13.sp, fontWeight = FontWeight.Bold, color = LaterboxTextPrimary)
                            }
                            Text(cleanSummary, fontSize = 13.sp, lineHeight = 20.sp, color = Color(0xFF45443F))
                        }
                    }
                }

                // Captured Content / Full Article Text Viewer
                val cleanFormatted = cleanText(item.formattedContent)
                val cleanBody = cleanFormatted ?: (if (cleanTextSelector == null) cleanTextContent else null)
                if (cleanBody != null) {
                    Surface(
                        color = Color.White,
                        shape = RoundedCornerShape(16.dp),
                        border = BorderStroke(1.dp, Color.Black.copy(alpha = 0.06f)),
                        shadowElevation = 2.dp,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                            Text("CAPTURED CONTENT", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = LaterboxTextSecondary, letterSpacing = 0.6.sp)
                            DetailContent(cleanBody)
                        }
                    }
                }

                // PERSONAL NOTES & FOLLOW-UPS SECTION (Clean Timeline)
                Surface(
                    color = Color.White,
                    shape = RoundedCornerShape(16.dp),
                    border = BorderStroke(1.dp, Color.Black.copy(alpha = 0.06f)),
                    shadowElevation = 2.dp,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                            Icon(Icons.Default.Edit, contentDescription = null, tint = LaterboxTextSecondary, modifier = Modifier.size(13.dp))
                            Text("NOTES & FOLLOW-UPS (${threadData.entries.size})", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = LaterboxTextSecondary, letterSpacing = 0.6.sp)
                        }

                        if (threadData.entries.isNotEmpty()) {
                            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                                threadData.entries.forEach { entry ->
                                    FollowUpEntryCard(
                                        entry = entry,
                                        activePickerId = activeReactionPickerForId,
                                        onToggleReaction = { emoji ->
                                            val updated = ItemThreadParser.toggleThreadReaction(threadData, entry.id, emoji)
                                            persistThread(updated)
                                        },
                                        onOpenPicker = {
                                            activeReactionPickerForId = if (activeReactionPickerForId == entry.id) null else entry.id
                                        },
                                        onReply = { snippet ->
                                            quotedSnippet = snippet
                                        },
                                        onDelete = { id ->
                                            val updated = ItemThreadParser.deleteEntry(threadData, id)
                                            persistThread(updated)
                                        }
                                    )
                                }
                            }
                        } else {
                            Text(
                                "No notes or follow-ups yet. Use the prompt below to add thoughts anytime.",
                                fontSize = 12.sp,
                                color = LaterboxTextSecondary,
                                modifier = Modifier.padding(vertical = 4.dp)
                            )
                        }
                    }
                }

                Spacer(Modifier.height(16.dp))
            }

            // 3. DOCKED BOTTOM CHAT INPUT BAR (No background, sits right on bottom)
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .navigationBarsPadding()
                    .imePadding()
            ) {
                Column(Modifier.fillMaxWidth()) {
                    // Quoted reply banner
                    AnimatedVisibility(visible = quotedSnippet != null, enter = fadeIn(), exit = fadeOut()) {
                        quotedSnippet?.let { snippet ->
                            Row(
                                Modifier
                                    .fillMaxWidth()
                                    .padding(horizontal = 14.dp, vertical = 4.dp)
                                    .clip(RoundedCornerShape(8.dp))
                                    .background(Color.Black.copy(alpha = 0.05f))
                                    .padding(horizontal = 12.dp, vertical = 6.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                Icon(Icons.AutoMirrored.Filled.Reply, contentDescription = null, tint = LaterboxTextSecondary, modifier = Modifier.size(12.dp))
                                Text(
                                    "Replying to: \"$snippet\"",
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.SemiBold,
                                    color = LaterboxTextPrimary,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis,
                                    modifier = Modifier.weight(1f)
                                )
                                IconButton(onClick = { quotedSnippet = null }, modifier = Modifier.size(20.dp)) {
                                    Icon(Icons.Default.Close, contentDescription = "Clear quote", tint = LaterboxTextSecondary, modifier = Modifier.size(13.dp))
                                }
                            }
                        }
                    }

                    // Input pill sitting cleanly on bottom with no background
                    Row(
                        Modifier
                            .fillMaxWidth()
                            .padding(start = 14.dp, end = 14.dp, bottom = 8.dp, top = 4.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Surface(
                            color = Color.Transparent,
                            shape = RoundedCornerShape(24.dp),
                            border = BorderStroke(1.dp, Color.Black.copy(alpha = 0.15f)),
                            shadowElevation = 0.dp,
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Row(
                                Modifier.padding(horizontal = 14.dp, vertical = 8.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(10.dp)
                            ) {
                                Box(Modifier.weight(1f)) {
                                    if (noteDraftText.isEmpty()) {
                                        Text(
                                            "Add a note or thought...",
                                            fontSize = 14.sp,
                                            color = LaterboxTextSecondary
                                        )
                                    }
                                    BasicTextField(
                                        value = noteDraftText,
                                        onValueChange = { noteDraftText = it },
                                        textStyle = TextStyle(fontSize = 14.sp, color = LaterboxTextPrimary),
                                        cursorBrush = SolidColor(LaterboxTextPrimary),
                                        maxLines = 4,
                                        modifier = Modifier.fillMaxWidth()
                                    )
                                }

                                val canSend = noteDraftText.isNotBlank()
                                Box(
                                    Modifier
                                        .size(32.dp)
                                        .clip(CircleShape)
                                        .background(if (canSend) Color(0xFF171711) else Color.Black.copy(alpha = 0.12f))
                                        .clickable(enabled = canSend) { sendNote() },
                                    contentAlignment = Alignment.Center
                                ) {
                                    Icon(
                                        Icons.Default.ArrowUpward,
                                        contentDescription = "Send",
                                        tint = if (canSend) Color(0xFFE6EDB0) else Color.White,
                                        modifier = Modifier.size(15.dp)
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Collection Picker Dialog
    if (showingCollectionSheet) {
        CollectionPickerDialog(
            currentCollectionName = cleanText(collections.find { it.id == item.collectionId }?.name ?: item.category),
            collections = collections,
            onDismiss = { showingCollectionSheet = false },
            onSelect = { coll ->
                showingCollectionSheet = false
                update(item.copy(collectionId = coll.id, category = coll.name))
            },
            onRemove = {
                showingCollectionSheet = false
                update(item.copy(collectionId = null, category = ""))
            },
            onCreateNew = { name ->
                showingCollectionSheet = false
                scope.launch {
                    val created = repository.addCollection(name, "#0369A1", "folder")
                    update(item.copy(collectionId = created.id, category = created.name))
                }
            }
        )
    }

    // Schedule Picker Dialog
    if (showingSchedulePicker) {
        SchedulePickerDialog(
            currentReturnAt = item.returnAt,
            onDismiss = { showingSchedulePicker = false },
            onSetDate = { isoString ->
                showingSchedulePicker = false
                update(item.copy(returnAt = isoString, status = if (isoString != null) "deferred" else "inbox"))
            }
        )
    }

    // Delete Confirmation Dialog
    if (showingDeleteConfirm) {
        AlertDialog(
            onDismissRequest = { showingDeleteConfirm = false },
            title = { Text("Delete item?", fontWeight = FontWeight.Bold) },
            text = { Text("Are you sure you want to delete this item? It will be moved to Trash.") },
            confirmButton = {
                Button(
                    onClick = {
                        showingDeleteConfirm = false
                        scope.launch {
                            repository.deleteItem(item.id)
                            onBack()
                        }
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFEF4444), contentColor = Color.White)
                ) {
                    Text("Delete")
                }
            },
            dismissButton = {
                TextButton(onClick = { showingDeleteConfirm = false }) {
                    Text("Cancel")
                }
            }
        )
    }
}

@Composable
private fun FollowUpEntryCard(
    entry: ItemThreadEntry,
    activePickerId: String?,
    onToggleReaction: (String) -> Unit,
    onOpenPicker: () -> Unit,
    onReply: (String) -> Unit,
    onDelete: (String) -> Unit
) {
    Surface(
        color = Color(0xFFFAFAF8),
        shape = RoundedCornerShape(12.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            // Header: Avatar, Name, Relative time, Reply, Delete
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Box(
                    Modifier
                        .size(22.dp)
                        .clip(CircleShape)
                        .background(Color(0xFF171711)),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        (entry.authorName ?: "Me").firstOrNull()?.uppercaseChar()?.toString() ?: "M",
                        fontSize = 10.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color(0xFFE6EDB0)
                    )
                }
                Text(entry.authorName ?: "Me", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = LaterboxTextPrimary)
                Text(entry.formattedRelativeTime, fontSize = 10.sp, color = LaterboxTextSecondary)
                Spacer(Modifier.weight(1f))
                IconButton(onClick = { onReply(entry.content) }, modifier = Modifier.size(24.dp)) {
                    Icon(Icons.AutoMirrored.Filled.Reply, contentDescription = "Reply to note", tint = LaterboxTextSecondary, modifier = Modifier.size(13.dp))
                }
                IconButton(onClick = { onDelete(entry.id) }, modifier = Modifier.size(24.dp)) {
                    Icon(Icons.Default.Delete, contentDescription = "Delete note", tint = LaterboxTextSecondary.copy(alpha = 0.7f), modifier = Modifier.size(13.dp))
                }
            }

            // Attached snippet quote (if any)
            entry.attachedSnippet?.takeIf { it.isNotBlank() }?.let { snippet ->
                Row(
                    Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(6.dp))
                        .background(Color(0xFFF7F5EE))
                        .padding(horizontal = 8.dp, vertical = 4.dp),
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    Box(Modifier.width(2.dp).fillMaxHeight().background(Color(0xFF171711)))
                    Text(
                        "\"$snippet\"",
                        fontSize = 11.sp,
                        color = LaterboxTextSecondary,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis
                    )
                }
            }

            // Note Content
            SelectionContainer {
                Text(
                    entry.content,
                    fontSize = 13.sp,
                    lineHeight = 18.sp,
                    color = LaterboxTextPrimary
                )
            }

            // Reaction Bar for Entry
            Row(
                Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                entry.reactions.forEach { (emoji, count) ->
                    val userReacted = entry.userReactions.contains(emoji)
                    Row(
                        Modifier
                            .clip(RoundedCornerShape(10.dp))
                            .background(if (userReacted) Color(0xFFE6EDB0) else Color.White)
                            .border(BorderStroke(1.dp, if (userReacted) Color.Black.copy(alpha = 0.2f) else LaterboxBorder), RoundedCornerShape(10.dp))
                            .clickable { onToggleReaction(emoji) }
                            .padding(horizontal = 7.dp, vertical = 3.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(3.dp)
                    ) {
                        Text(emoji, fontSize = 11.sp)
                        Text("$count", fontSize = 10.sp, fontWeight = FontWeight.Bold, color = Color(0xFF171711))
                    }
                }

                Box {
                    IconButton(onClick = onOpenPicker, modifier = Modifier.size(26.dp)) {
                        Icon(Icons.Default.Add, contentDescription = "Add reaction", tint = LaterboxTextSecondary, modifier = Modifier.size(14.dp))
                    }

                    if (activePickerId == entry.id) {
                        Surface(
                            color = Color.White,
                            shape = RoundedCornerShape(18.dp),
                            shadowElevation = 6.dp,
                            border = BorderStroke(1.dp, Color.Black.copy(alpha = 0.1f)),
                            modifier = Modifier.padding(top = 30.dp)
                        ) {
                            Row(Modifier.padding(4.dp), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                                POPULAR_REACTIONS.forEach { emoji ->
                                    Text(
                                        emoji,
                                        fontSize = 16.sp,
                                        modifier = Modifier
                                            .clip(CircleShape)
                                            .clickable { onToggleReaction(emoji) }
                                            .padding(4.dp)
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
internal fun CollectionPickerDialog(
    currentCollectionName: String?,
    collections: List<CollectionEntity>,
    onDismiss: () -> Unit,
    onSelect: (CollectionEntity) -> Unit,
    onRemove: () -> Unit,
    onCreateNew: (String) -> Unit
) {
    var newName by remember { mutableStateOf("") }
    Dialog(onDismissRequest = onDismiss) {
        Surface(
            color = Color.White,
            shape = RoundedCornerShape(20.dp),
            modifier = Modifier.fillMaxWidth().padding(16.dp)
        ) {
            Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text("Collections", fontSize = 18.sp, fontWeight = FontWeight.Bold, color = LaterboxTextPrimary)
                    Spacer(Modifier.weight(1f))
                    IconButton(onClick = onDismiss, modifier = Modifier.size(28.dp)) {
                        Icon(Icons.Default.Close, contentDescription = "Close", tint = LaterboxTextSecondary)
                    }
                }

                // Current Collection
                val validCurrent = cleanText(currentCollectionName)
                if (validCurrent != null) {
                    Row(
                        Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(10.dp))
                            .background(Color(0xFFE0F2FE))
                            .padding(10.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(Icons.Default.Folder, contentDescription = null, tint = Color(0xFF0369A1), modifier = Modifier.size(16.dp))
                        Spacer(Modifier.width(8.dp))
                        Text(validCurrent, fontWeight = FontWeight.SemiBold, fontSize = 14.sp, color = Color(0xFF0369A1))
                        Spacer(Modifier.weight(1f))
                        TextButton(onClick = onRemove) {
                            Text("Remove", color = Color(0xFFEF4444), fontSize = 12.sp, fontWeight = FontWeight.Bold)
                        }
                    }
                }

                // Available Collections List
                Text("Select Collection", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = LaterboxTextSecondary)
                Column(Modifier.verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    collections.forEach { coll ->
                        Row(
                            Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(8.dp))
                                .clickable { onSelect(coll) }
                                .padding(vertical = 8.dp, horizontal = 10.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(Icons.Default.Folder, contentDescription = null, tint = Color(0xFF0369A1), modifier = Modifier.size(16.dp))
                            Spacer(Modifier.width(8.dp))
                            Text(coll.name, fontSize = 14.sp, fontWeight = FontWeight.Medium, color = LaterboxTextPrimary)
                            Spacer(Modifier.weight(1f))
                            if (validCurrent?.equals(coll.name, true) == true) {
                                Icon(Icons.Default.Check, contentDescription = "Selected", tint = Color(0xFF0369A1), modifier = Modifier.size(16.dp))
                            }
                        }
                    }
                }

                HorizontalDivider(color = Color.Black.copy(alpha = 0.06f))

                // Create New Collection
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    BasicTextField(
                        value = newName,
                        onValueChange = { newName = it },
                        textStyle = TextStyle(fontSize = 13.sp, color = LaterboxTextPrimary),
                        modifier = Modifier
                            .weight(1f)
                            .border(BorderStroke(1.dp, LaterboxBorder), RoundedCornerShape(8.dp))
                            .padding(8.dp),
                        decorationBox = { inner ->
                            if (newName.isBlank()) Text("New collection name", fontSize = 13.sp, color = LaterboxTextSecondary)
                            inner()
                        }
                    )
                    Button(
                        onClick = {
                            if (newName.isNotBlank()) {
                                onCreateNew(newName.trim())
                            }
                        },
                        enabled = newName.isNotBlank(),
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF0369A1), contentColor = Color.White),
                        shape = RoundedCornerShape(8.dp)
                    ) {
                        Text("Add", fontSize = 12.sp, fontWeight = FontWeight.Bold)
                    }
                }
            }
        }
    }
}

@Composable
internal fun SchedulePickerDialog(
    currentReturnAt: String?,
    onDismiss: () -> Unit,
    onSetDate: (String?) -> Unit
) {
    Dialog(onDismissRequest = onDismiss) {
        Surface(
            color = Color.White,
            shape = RoundedCornerShape(20.dp),
            modifier = Modifier.fillMaxWidth().padding(16.dp)
        ) {
            Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                val context = LocalContext.current
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text("Schedule Return", fontSize = 18.sp, fontWeight = FontWeight.Bold, color = LaterboxTextPrimary)
                    Spacer(Modifier.weight(1f))
                    IconButton(onClick = onDismiss, modifier = Modifier.size(28.dp)) {
                        Icon(Icons.Default.Close, contentDescription = "Close", tint = LaterboxTextSecondary)
                    }
                }

                // Preset options
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Button(
                        onClick = {
                            val tomorrow = Instant.now().plus(24, ChronoUnit.HOURS).toString()
                            onSetDate(tomorrow)
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFE6EDB0), contentColor = Color(0xFF171711)),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text("Tomorrow (in 24 hours)", fontWeight = FontWeight.Bold)
                    }

                    OutlinedButton(
                        onClick = {
                            val nextWeek = Instant.now().plus(7, ChronoUnit.DAYS).toString()
                            onSetDate(nextWeek)
                        },
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text("Next Week (in 7 days)", fontWeight = FontWeight.SemiBold, color = LaterboxTextPrimary)
                    }

                    OutlinedButton(
                        onClick = {
                            val calendar = Calendar.getInstance()
                            DatePickerDialog(
                                context,
                                { _, year, month, day ->
                                    val selected = Calendar.getInstance().apply { set(year, month, day, 9, 0, 0); set(Calendar.MILLISECOND, 0) }
                                    TimePickerDialog(
                                        context,
                                        { _, hour, minute ->
                                            selected.set(Calendar.HOUR_OF_DAY, hour)
                                            selected.set(Calendar.MINUTE, minute)
                                            onSetDate(Instant.ofEpochMilli(selected.timeInMillis).toString())
                                        },
                                        selected.get(Calendar.HOUR_OF_DAY), selected.get(Calendar.MINUTE), false
                                    ).show()
                                },
                                calendar.get(Calendar.YEAR), calendar.get(Calendar.MONTH), calendar.get(Calendar.DAY_OF_MONTH)
                            ).apply { datePicker.minDate = calendar.timeInMillis }.show()
                        },
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Icon(Icons.Default.CalendarToday, contentDescription = null, modifier = Modifier.size(18.dp))
                        Spacer(Modifier.width(8.dp))
                        Text("Choose a date", fontWeight = FontWeight.SemiBold, color = LaterboxTextPrimary)
                    }

                    if (currentReturnAt != null) {
                        TextButton(
                            onClick = { onSetDate(null) },
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text("Clear Return Schedule", color = Color(0xFFEF4444), fontWeight = FontWeight.Bold)
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun DetailContent(source: String) {
    val text = remember(source) {
        if (source.trimStart().startsWith("<")) {
            org.jsoup.Jsoup.parse(source).apply { select("script,style,iframe").remove() }.body().wholeText()
        } else {
            source
        }
    }
    SelectionContainer {
        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
            var code = false
            text.lineSequence().take(500).forEach { line ->
                if (line.startsWith("```")) {
                    code = !code
                } else {
                    val heading = if (!code) line.takeWhile { it == '#' }.length.coerceAtMost(6) else 0
                    Text(
                        if (heading > 0 && line.getOrNull(heading) == ' ') line.drop(heading + 1)
                        else if (line.startsWith("- ")) "• ${line.drop(2)}"
                        else line,
                        fontSize = if (heading > 0) (22 - heading).sp else 14.sp,
                        lineHeight = 20.sp,
                        fontWeight = if (heading > 0) FontWeight.Bold else FontWeight.Normal,
                        fontFamily = if (code) FontFamily.Monospace else FontFamily.Default,
                        color = LaterboxTextPrimary
                    )
                }
            }
            if (text.lineSequence().drop(500).any()) {
                Text(
                    "Preview limited to 500 lines. Open original to view complete content.",
                    fontSize = 12.sp,
                    color = LaterboxTextSecondary
                )
            }
        }
    }
}

private fun detailDate(value: String): String = runCatching {
    Instant.parse(value).atZone(ZoneId.systemDefault()).format(DateTimeFormatter.ofPattern("MMM d, yyyy · HH:mm"))
}.getOrDefault(value)

private fun detailDateShort(value: String): String = runCatching {
    Instant.parse(value).atZone(ZoneId.systemDefault()).format(DateTimeFormatter.ofPattern("MMM d, yyyy"))
}.getOrDefault(value)
