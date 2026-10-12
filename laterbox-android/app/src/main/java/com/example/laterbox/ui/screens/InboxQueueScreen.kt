package com.example.laterbox.ui.screens

import android.text.format.DateUtils
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.material.icons.automirrored.filled.Login
import androidx.compose.material.icons.automirrored.filled.Logout
import androidx.compose.material.icons.automirrored.filled.Article
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.StarBorder
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.example.laterbox.R
import com.example.laterbox.data.DataRepository
import com.example.laterbox.data.local.ItemEntity
import com.example.laterbox.data.local.ItemMetadataEntity
import com.example.laterbox.services.AccountService
import com.example.laterbox.theme.*
import kotlinx.coroutines.launch
import java.net.URI
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter

@Composable
fun InboxQueueScreen(
    repository: DataRepository,
    onItem: (ItemEntity) -> Unit,
    onOrganizer: () -> Unit,
    onCapture: () -> Unit,
    onOpenSidebar: () -> Unit = {},
    onSignOut: () -> Unit = {},
    onAuth: () -> Unit = {},
    onOpenSettings: () -> Unit = {}
) {
    val allItems by repository.items.collectAsState(emptyList())
    val collections by repository.collections.collectAsState(emptyList())
    val account by AccountService.state.collectAsState()
    var showingSearch by rememberSaveable { mutableStateOf(false) }
    var actionError by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()
    val inbox = allItems.filter { it.status == "inbox" && it.deletedAt == null }
    val queue = inbox.sortedBy { inboxArrival(it) }
    val syncTitle = when {
        !account.pro -> "Local only"
        allItems.any { it.syncStatus == "failed" } -> "Sync needs attention"
        allItems.any { it.syncStatus == "pending" } -> "Pending sync"
        else -> "Synced"
    }
    fun action(block: suspend () -> Unit) {
        scope.launch { try { block(); actionError = null } catch (_: Exception) { actionError = "Unable to update this item. Please try again." } }
    }
    if (showingSearch) {
        DedicatedSearchScreen(allItems = allItems, repository = repository, onClose = { showingSearch = false }, onItemClick = onItem)
        return
    }
    LazyColumn(
        modifier = Modifier.fillMaxSize().background(LaterboxBg),
        contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 12.dp, bottom = 24.dp),
        verticalArrangement = Arrangement.spacedBy(2.5.dp)
    ) {
        // 3 Components Top Bar: 3-line Sidebar Opener (left), Centered Search (middle), Profile Pic with Menu (right)
        item {
            var profileExpanded by remember { mutableStateOf(false) }
            val userInitial = remember(account.displayName, account.email) {
                account.displayName?.trim()?.firstOrNull()?.uppercase()
                    ?: account.email?.trim()?.firstOrNull()?.uppercase()
                    ?: "U"
            }

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 6.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                // 1. Top left: 3 lines sidebar opener
                Surface(
                    modifier = Modifier
                        .size(36.dp)
                        .clip(CircleShape)
                        .clickable(onClick = onOpenSidebar),
                    shape = CircleShape,
                    color = Color.Transparent
                ) {
                    Box(contentAlignment = Alignment.Center, modifier = Modifier.fillMaxSize()) {
                        Icon(
                            imageVector = Icons.Default.Menu,
                            contentDescription = "Open sidebar",
                            tint = LaterboxTextPrimary,
                            modifier = Modifier.size(22.dp)
                        )
                    }
                }

                // 2. Centered search bar (matching iOS Ask LaterBox pill)
                Surface(
                    modifier = Modifier
                        .weight(1f)
                        .height(48.dp)
                        .clip(CircleShape)
                        .clickable { showingSearch = true },
                    shape = CircleShape,
                    color = Color.White,
                    border = BorderStroke(1.dp, Color.Black.copy(alpha = 0.08f)),
                    shadowElevation = 2.dp
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(horizontal = 16.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(
                            text = "Ask LaterBox",
                            fontSize = 15.sp,
                            color = LaterboxTextSecondary,
                            fontWeight = FontWeight.Normal
                        )
                        Icon(
                            imageVector = Icons.Default.AutoAwesome,
                            contentDescription = null,
                            tint = Color(0xFF1A73E8),
                            modifier = Modifier.size(16.dp)
                        )
                    }
                }

                // 3. Top right: Profile pic / avatar with dropdown menu
                Box {
                    Surface(
                        modifier = Modifier
                            .size(36.dp)
                            .clip(CircleShape)
                            .clickable { profileExpanded = true },
                        shape = CircleShape,
                        color = Color(0xFF171711),
                        border = BorderStroke(2.dp, Color(0xFF1A73E8))
                    ) {
                        Box(contentAlignment = Alignment.Center, modifier = Modifier.fillMaxSize()) {
                            Text(
                                text = userInitial,
                                fontSize = 14.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color.White
                            )
                        }
                    }

                    DropdownMenu(
                        expanded = profileExpanded,
                        onDismissRequest = { profileExpanded = false },
                        modifier = Modifier
                            .background(LaterboxCard)
                            .border(1.dp, LaterboxBorder, RoundedCornerShape(12.dp))
                            .widthIn(min = 200.dp)
                    ) {
                        DropdownMenuItem(
                            text = { Text("Settings", fontWeight = FontWeight.Medium) },
                            leadingIcon = { Icon(Icons.Default.Settings, contentDescription = null, modifier = Modifier.size(18.dp)) },
                            onClick = {
                                profileExpanded = false
                                onOpenSettings()
                            }
                        )

                        HorizontalDivider(color = LaterboxBorder, thickness = 0.5.dp)

                        if (account.userId != null) {
                            account.email?.let { email ->
                                DropdownMenuItem(
                                    text = {
                                        Column {
                                            Text(email, fontSize = 11.sp, color = LaterboxTextSecondary, maxLines = 1, overflow = TextOverflow.Ellipsis)
                                        }
                                    },
                                    enabled = false,
                                    onClick = {}
                                )
                            }
                            DropdownMenuItem(
                                text = { Text("Sign Out", color = Color(0xFFE53935), fontWeight = FontWeight.SemiBold) },
                                leadingIcon = { Icon(Icons.AutoMirrored.Filled.Logout, contentDescription = null, tint = Color(0xFFE53935), modifier = Modifier.size(18.dp)) },
                                onClick = {
                                    profileExpanded = false
                                    onSignOut()
                                }
                            )
                        } else {
                            DropdownMenuItem(
                                text = { Text("Guest Mode", fontSize = 11.sp, color = LaterboxTextSecondary) },
                                enabled = false,
                                onClick = {}
                            )
                            DropdownMenuItem(
                                text = { Text("Sign In / Exit Guest", color = Color(0xFF1A73E8), fontWeight = FontWeight.SemiBold) },
                                leadingIcon = { Icon(Icons.AutoMirrored.Filled.Login, contentDescription = null, tint = Color(0xFF1A73E8), modifier = Modifier.size(18.dp)) },
                                onClick = {
                                    profileExpanded = false
                                    onAuth()
                                }
                            )
                        }
                    }
                }
            }
        }
        item {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 8.dp, bottom = 4.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Inbox",
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Bold,
                    color = LaterboxTextSecondary
                )
            }
        }
        actionError?.let { message -> item { Text(message, color = MaterialTheme.colorScheme.error) } }
        if (queue.isEmpty()) item {
            Surface(shape = RoundedCornerShape(16.dp), color = Color.White, border = BorderStroke(1.dp, Color.Black.copy(alpha = 0.06f)), modifier = Modifier.fillMaxWidth()) {
                Column(Modifier.padding(48.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(14.dp)) {
                    Icon(Icons.Default.Inbox, null, Modifier.size(40.dp), tint = LaterboxTextSecondary.copy(alpha = 0.35f))
                    Text(if (inbox.isEmpty()) "Inbox Zero!" else "No matches", fontSize = 17.sp, fontWeight = FontWeight.Bold, color = LaterboxTextPrimary)
                    Text(if (inbox.isEmpty()) "All caught up. Everything saved has been processed or reviewed." else "Try another search or content format.", fontSize = 12.sp, color = LaterboxTextSecondary, textAlign = TextAlign.Center)
                    if (inbox.isEmpty()) TextButton(onClick = onCapture) { Text("Save something") }
                }
            }
        }
        itemsIndexed(queue, key = { _, item -> item.id }) { index, item ->
            val isFirst = index == 0
            val isLast = index == queue.size - 1
            val topRadius = if (isFirst) 12.dp else 4.dp
            val bottomRadius = if (isLast) 12.dp else 4.dp
            val metadata by remember(repository, item.id) { repository.watchMetadata(item.id) }.collectAsState(null)

            EmailInboxRowCard(
                item = item,
                metadata = metadata,
                collectionName = collections.find { it.id == item.collectionId }?.name,
                topRadius = topRadius,
                bottomRadius = bottomRadius,
                onClick = { onItem(item) },
                onToggleFavorite = { action { repository.toggleFavorite(item.id, item.favorite) } }
            )
        }
    }
}

@Composable
internal fun InboxRichItemCard(item: ItemEntity, metadata: ItemMetadataEntity?, collectionName: String?, onOpen: () -> Unit, onFavorite: () -> Unit, onDone: () -> Unit, onSchedule: (Long) -> Unit, onDelete: () -> Unit) {
    var menu by remember { mutableStateOf(false) }
    val context = LocalContext.current
    val domain = metadata?.domain?.takeIf { it.isNotBlank() } ?: runCatching { URI(item.url.orEmpty()).host?.removePrefix("www.") }.getOrNull()
    val title = item.title?.takeIf { it.isNotBlank() } ?: metadata?.title?.takeIf { it.isNotBlank() } ?: domain ?: inboxFormatLabel(item.type)
    val preview = metadata?.previewImageUrl?.takeIf { it.startsWith("https://") || it.startsWith("http://") }
        ?: if (item.type == "image") item.url else null
    val age = runCatching { DateUtils.getRelativeTimeSpanString(Instant.parse(item.createdAt).toEpochMilli(), System.currentTimeMillis(), DateUtils.MINUTE_IN_MILLIS).toString() }.getOrDefault("")
    val note = item.notes.takeIf { it.isNotBlank() } ?: item.summary.takeIf { it.isNotBlank() } ?: item.textContent?.takeIf { it.isNotBlank() }
    Surface(onClick = onOpen, shape = RoundedCornerShape(20.dp), color = LaterboxCard, border = BorderStroke(1.dp, LaterboxBorder)) {
        Column(Modifier.fillMaxWidth().padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Box(Modifier.size(24.dp).background(LaterboxAccent, RoundedCornerShape(7.dp)), contentAlignment = Alignment.Center) {
                    Icon(inboxFormatIcon(item.type), null, Modifier.size(13.dp), tint = LaterboxTextPrimary)
                    metadata?.faviconUrl?.takeIf { !domain.isNullOrBlank() }?.let { AsyncImage(it, null, Modifier.size(16.dp)) }
                }
                Spacer(Modifier.width(8.dp))
                Text(domain ?: inboxFormatLabel(item.type), fontSize = 12.sp, fontWeight = FontWeight.SemiBold, color = LaterboxTextPrimary, maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.weight(1f))
                if (age.isNotEmpty()) Text(" • $age", fontSize = 10.sp, color = LaterboxTextSecondary, maxLines = 1, modifier = Modifier.widthIn(max = 90.dp))
                IconButton(onClick = onFavorite) { Icon(if (item.favorite) Icons.Default.Star else Icons.Outlined.StarBorder, if (item.favorite) "Unstar item" else "Star item", tint = if (item.favorite) LaterboxAmber else LaterboxTextSecondary, modifier = Modifier.size(18.dp)) }
            }
            Box(Modifier.fillMaxWidth().height(if (preview != null) 130.dp else 72.dp).clip(RoundedCornerShape(14.dp)).background(Brush.linearGradient(listOf(LaterboxDarkSurface, LaterboxDarkSurface.copy(alpha = 0.8f))))) {
                Row(Modifier.align(Alignment.CenterStart).padding(14.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                    Icon(inboxFormatIcon(item.type), null, Modifier.size(28.dp), tint = LaterboxAccent)
                    Column(Modifier.weight(1f)) {
                        Text(inboxFormatLabel(item.type).uppercase(), fontSize = 10.sp, fontWeight = FontWeight.Bold, color = LaterboxAccent)
                        Text(title, fontSize = 13.sp, color = Color.White, maxLines = 1, overflow = TextOverflow.Ellipsis)
                    }
                }
                if (preview != null) {
                    AsyncImage(preview, "$title preview", Modifier.fillMaxSize(), contentScale = ContentScale.Crop)
                    Box(Modifier.fillMaxSize().background(Brush.verticalGradient(listOf(Color.Transparent, Color.Black.copy(alpha = 0.6f)))))
                    Row(Modifier.align(Alignment.BottomStart).padding(14.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        Icon(inboxFormatIcon(item.type), null, Modifier.size(18.dp), tint = LaterboxAccent)
                        Text(inboxFormatLabel(item.type), color = Color.White, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                    }
                }
            }
            Text(title, fontSize = 17.sp, lineHeight = 23.sp, fontWeight = FontWeight.Bold, color = LaterboxTextPrimary, maxLines = 2, overflow = TextOverflow.Ellipsis)
            if (note != null) Surface(shape = RoundedCornerShape(10.dp), color = LaterboxBg, border = BorderStroke(1.dp, LaterboxBorder)) {
                Text(note, Modifier.fillMaxWidth().padding(10.dp), fontSize = 13.sp, color = LaterboxTextSecondary, maxLines = 2, overflow = TextOverflow.Ellipsis)
            }
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(5.dp)) {
                    collectionName?.takeIf { it.isNotBlank() }?.let { InboxCardBadge(it, Icons.Default.Folder, false) }
                    item.returnAt?.let { date ->
                        val day = runCatching { Instant.parse(date).atZone(ZoneId.systemDefault()).toLocalDate() }.getOrElse { runCatching { LocalDate.parse(date.take(10)) }.getOrNull() }
                        if (day != null) InboxCardBadge(if (!day.isAfter(LocalDate.now())) "Due Today" else day.format(DateTimeFormatter.ofPattern("MMM d")), Icons.Default.Schedule, true)
                    }
                }
                IconButton(onClick = { onSchedule(1) }) { Icon(Icons.Default.Schedule, "Reschedule for tomorrow", tint = LaterboxTextSecondary, modifier = Modifier.size(18.dp)) }
                IconButton(onClick = onDone) {
                    Box(Modifier.size(30.dp).background(LaterboxAccent, CircleShape), contentAlignment = Alignment.Center) { Icon(Icons.Default.Check, "Mark as done", tint = LaterboxTextPrimary, modifier = Modifier.size(16.dp)) }
                }
                Box {
                    IconButton(onClick = { menu = true }) { Icon(Icons.Default.MoreVert, "More item actions", tint = LaterboxTextSecondary, modifier = Modifier.size(18.dp)) }
                    DropdownMenu(menu, { menu = false }) {
                        DropdownMenuItem(text = { Text("Mark as done") }, onClick = { menu = false; onDone() })
                        DropdownMenuItem(text = { Text(if (item.favorite) "Unstar" else "Star") }, onClick = { menu = false; onFavorite() })
                        DropdownMenuItem(text = { Text("Return tomorrow") }, onClick = { menu = false; onSchedule(1) })
                        DropdownMenuItem(text = { Text("Return next week") }, onClick = { menu = false; onSchedule(7) })
                        item.url?.let { url -> DropdownMenuItem(text = { Text("Open in browser") }, onClick = { menu = false; runCatching { context.startActivity(android.content.Intent(android.content.Intent.ACTION_VIEW, android.net.Uri.parse(url))) } }) }
                        item.url?.let { url -> DropdownMenuItem(text = { Text("Copy link") }, onClick = {
                            menu = false
                            val clipboard = context.getSystemService(android.content.Context.CLIPBOARD_SERVICE) as android.content.ClipboardManager
                            clipboard.setPrimaryClip(android.content.ClipData.newPlainText("Saved link", url))
                        }) }
                        DropdownMenuItem(text = { Text("Delete", color = MaterialTheme.colorScheme.error) }, onClick = { menu = false; onDelete() })
                    }
                }
            }
        }
    }
}

@Composable
private fun InboxCardBadge(label: String, icon: ImageVector, highlighted: Boolean) {
    Surface(shape = RoundedCornerShape(50), color = if (highlighted) LaterboxAccent else LaterboxBg, border = BorderStroke(1.dp, LaterboxBorder)) {
        Row(Modifier.padding(horizontal = 8.dp, vertical = 4.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
            Icon(icon, null, Modifier.size(11.dp), tint = LaterboxTextPrimary)
            Text(label, fontSize = 11.sp, color = LaterboxTextPrimary, maxLines = 1, overflow = TextOverflow.Ellipsis)
        }
    }
}

internal fun inboxArrival(item: ItemEntity): Instant = runCatching { Instant.parse(item.returnAt ?: item.createdAt) }.getOrElse {
    runCatching { LocalDate.parse((item.returnAt ?: item.createdAt).take(10)).atStartOfDay(ZoneId.systemDefault()).toInstant() }.getOrDefault(Instant.EPOCH)
}

private fun inboxFormatLabel(type: String) = type.replaceFirstChar { it.uppercase() }
private fun inboxFormatIcon(type: String): ImageVector = when (type.lowercase()) {
    "article" -> Icons.AutoMirrored.Filled.Article
    "video" -> Icons.Default.PlayCircle
    "music", "audio" -> Icons.Default.MusicNote
    "image" -> Icons.Default.Image
    "document", "pdf" -> Icons.Default.Description
    "repository", "code" -> Icons.Default.Code
    "note" -> Icons.Default.EditNote
    else -> Icons.Default.Link
}

private val emailAvatarColors = listOf(
    Color(0xFFA855F7), // Purple
    Color(0xFF3B82F6), // Blue
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFF6366F1), // Indigo
    Color(0xFF14B8A6), // Teal
    Color(0xFF8B5CF6)  // Violet
)

private fun resolveAvatarColor(sender: String): Color {
    val hash = kotlin.math.abs(sender.hashCode())
    return emailAvatarColors[hash % emailAvatarColors.size]
}

private fun resolveSenderText(item: ItemEntity, metadata: ItemMetadataEntity?): String {
    val site = metadata?.siteName?.trim()
    if (!site.isNullOrEmpty()) return site

    val domain = metadata?.domain?.trim() ?: runCatching { URI(item.url.orEmpty()).host }.getOrNull()?.trim()
    if (!domain.isNullOrEmpty()) {
        val host = domain.removePrefix("www.")
        val parts = host.split(".")
        if (parts.size >= 2) {
            val main = parts[0]
            return main.replaceFirstChar { it.uppercase() }
        }
        return host
    }

    if (item.type == "note") return "Note"
    if (item.type == "file") return "File"
    return "LaterBox"
}

private fun formatEmailDate(dateStr: String): String {
    return try {
        val instant = Instant.parse(dateStr)
        val zdt = instant.atZone(ZoneId.systemDefault())
        val today = LocalDate.now()
        val itemDate = zdt.toLocalDate()
        if (itemDate == today) {
            zdt.format(DateTimeFormatter.ofPattern("h:mm a")).lowercase()
        } else if (itemDate.year == today.year) {
            zdt.format(DateTimeFormatter.ofPattern("d MMM"))
        } else {
            zdt.format(DateTimeFormatter.ofPattern("M/d/yy"))
        }
    } catch (_: Exception) {
        ""
    }
}

@Composable
internal fun EmailInboxRowCard(
    item: ItemEntity,
    metadata: ItemMetadataEntity?,
    collectionName: String?,
    topRadius: androidx.compose.ui.unit.Dp,
    bottomRadius: androidx.compose.ui.unit.Dp,
    onClick: () -> Unit,
    onToggleFavorite: () -> Unit
) {
    val senderText = resolveSenderText(item, metadata)
    val avatarColor = resolveAvatarColor(senderText)
    val avatarInitial = senderText.trim().firstOrNull()?.uppercase() ?: "L"
    val dateText = formatEmailDate(item.createdAt)
    val title = item.title?.takeIf { it.isNotBlank() } ?: metadata?.title?.takeIf { it.isNotBlank() } ?: senderText
    val snippet = item.summary.takeIf { it.isNotBlank() }
        ?: metadata?.description?.takeIf { it.isNotBlank() }
        ?: item.notes.takeIf { it.isNotBlank() }
        ?: item.textContent?.takeIf { it.isNotBlank() }
        ?: item.url
        ?: "Saved item"
    val preview = metadata?.previewImageUrl?.takeIf { it.startsWith("http") }
        ?: if (item.type == "image") item.url else null

    val cardShape = RoundedCornerShape(
        topStart = topRadius,
        topEnd = topRadius,
        bottomStart = bottomRadius,
        bottomEnd = bottomRadius
    )

    Surface(
        onClick = onClick,
        shape = cardShape,
        color = Color.White,
        border = BorderStroke(1.dp, Color.Black.copy(alpha = 0.06f)),
        modifier = Modifier.fillMaxWidth()
    ) {
        Box(modifier = Modifier.fillMaxWidth()) {
            // Right-aligned fading preview watermark matching iOS
            if (!preview.isNullOrBlank()) {
                Box(
                    modifier = Modifier.matchParentSize(),
                    contentAlignment = Alignment.CenterEnd
                ) {
                    AsyncImage(
                        model = preview,
                        contentDescription = null,
                        contentScale = ContentScale.Crop,
                        modifier = Modifier
                            .fillMaxHeight()
                            .width(185.dp)
                            .alpha(0.65f)
                    )
                    Box(
                        modifier = Modifier
                            .matchParentSize()
                            .background(
                                Brush.horizontalGradient(
                                    0.0f to Color.White,
                                    0.35f to Color.White.copy(alpha = 0.85f),
                                    0.70f to Color.White.copy(alpha = 0.25f),
                                    1.0f to Color.Transparent
                                )
                            )
                    )
                }
            }

            // Foreground Email 3-line content
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                verticalAlignment = Alignment.Top,
                horizontalArrangement = Arrangement.spacedBy(14.dp)
            ) {
                // Left: Avatar circle
                Box(
                    modifier = Modifier
                        .size(40.dp)
                        .background(avatarColor, CircleShape),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = avatarInitial,
                        fontSize = 17.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = Color.White
                    )
                }

                // Middle & Right: 3 lines
                Column(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(2.5.dp)
                ) {
                    // Line 1: Sender Name + Timestamp
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(
                            text = senderText,
                            fontSize = 15.sp,
                            fontWeight = FontWeight.Bold,
                            color = LaterboxTextPrimary,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                            modifier = Modifier.weight(1f)
                        )
                        Spacer(Modifier.width(8.dp))
                        Text(
                            text = dateText,
                            fontSize = 12.sp,
                            color = LaterboxTextSecondary
                        )
                    }

                    // Line 2: Subject / Title
                    Text(
                        text = title,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Medium,
                        color = LaterboxTextPrimary,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )

                    // Line 3: Snippet + Star
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = snippet,
                            fontSize = 13.sp,
                            color = LaterboxTextSecondary,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                            modifier = Modifier.weight(1f)
                        )
                        IconButton(
                            onClick = onToggleFavorite,
                            modifier = Modifier.size(24.dp)
                        ) {
                            Icon(
                                imageVector = if (item.favorite) Icons.Default.Star else Icons.Outlined.StarBorder,
                                contentDescription = if (item.favorite) "Unstar" else "Star",
                                tint = if (item.favorite) LaterboxAmber else Color.Black.copy(alpha = 0.28f),
                                modifier = Modifier.size(16.dp)
                            )
                        }
                    }

                    // Optional Collection tag or file badge
                    if (!collectionName.isNullOrBlank()) {
                        Surface(
                            shape = CircleShape,
                            color = Color(0xFFE8F0FE),
                            contentColor = Color(0xFF1967D2),
                            modifier = Modifier.padding(top = 2.dp)
                        ) {
                            Row(
                                modifier = Modifier.padding(horizontal = 10.dp, vertical = 3.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(4.dp)
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Folder,
                                    contentDescription = null,
                                    modifier = Modifier.size(9.dp)
                                )
                                Text(
                                    text = collectionName,
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.SemiBold
                                )
                            }
                        }
                    } else if (item.type == "file") {
                        Surface(
                            shape = CircleShape,
                            color = Color(0xFFE8F0FE),
                            contentColor = Color(0xFF1967D2),
                            modifier = Modifier.padding(top = 2.dp)
                        ) {
                            Row(
                                modifier = Modifier.padding(horizontal = 10.dp, vertical = 3.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(4.dp)
                            ) {
                                Icon(
                                    imageVector = Icons.Default.AttachFile,
                                    contentDescription = null,
                                    modifier = Modifier.size(9.dp)
                                )
                                Text(
                                    text = "Attachment",
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.SemiBold
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}
