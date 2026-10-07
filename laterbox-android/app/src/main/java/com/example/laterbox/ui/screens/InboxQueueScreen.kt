package com.example.laterbox.ui.screens

import android.text.format.DateUtils
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Article
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.StarBorder
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
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
import com.example.laterbox.services.LocalSearch
import com.example.laterbox.theme.*
import kotlinx.coroutines.launch
import java.net.URI
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter

@Composable
fun InboxQueueScreen(repository: DataRepository, onItem: (ItemEntity) -> Unit, onOrganizer: () -> Unit, onCapture: () -> Unit) {
    val allItems by repository.items.collectAsState(emptyList())
    val collections by repository.collections.collectAsState(emptyList())
    val account by AccountService.state.collectAsState()
    var showingSearch by rememberSaveable { mutableStateOf(false) }
    var query by rememberSaveable { mutableStateOf("") }
    var selectedType by rememberSaveable { mutableStateOf<String?>(null) }
    var actionError by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()
    val inbox = allItems.filter { it.status == "inbox" && it.deletedAt == null }
    val formats = inbox.map { it.type }.distinct().sorted()
    LaunchedEffect(formats) { if (selectedType !in formats) selectedType = null }
    val candidates = inbox.filter { selectedType == null || it.type == selectedType }
    val queue = if (query.isBlank()) candidates.sortedBy { inboxArrival(it) } else LocalSearch.search(query, candidates)
    val syncTitle = when {
        !account.pro -> "Local only"
        inbox.any { it.syncStatus == "pending" } -> "Pending sync"
        inbox.any { it.syncStatus == "error" } -> "Sync needs attention"
        else -> "Synced"
    }
    fun action(block: suspend () -> Unit) {
        scope.launch { try { block(); actionError = null } catch (_: Exception) { actionError = "Unable to update this item. Please try again." } }
    }
    LazyColumn(
        modifier = Modifier.fillMaxSize().background(LaterboxBg),
        contentPadding = PaddingValues(start = 20.dp, end = 20.dp, top = 16.dp, bottom = 24.dp),
        verticalArrangement = Arrangement.spacedBy(18.dp)
    ) {
        item {
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Image(painterResource(R.drawable.laterbox_icon_green), "LaterBox logo", Modifier.size(28.dp).clip(RoundedCornerShape(7.dp)))
                Spacer(Modifier.width(8.dp))
                Text("Inbox", fontSize = 24.sp, fontWeight = FontWeight.Bold, color = LaterboxTextPrimary, modifier = Modifier.weight(1f))
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(5.dp)) {
                    Box(Modifier.size(7.dp).background(if (syncTitle == "Synced") LaterboxEmerald else LaterboxAmber, CircleShape))
                    Text(syncTitle, fontSize = 10.sp, color = LaterboxTextSecondary)
                }
                IconButton(onClick = onOrganizer) { Icon(Icons.Default.AutoAwesome, "AI Inbox Organizer", tint = LaterboxTextSecondary, modifier = Modifier.size(20.dp)) }
                IconButton(onClick = { showingSearch = !showingSearch; if (!showingSearch) query = "" }) {
                    Box(Modifier.size(32.dp).background(if (showingSearch) LaterboxAccent else Color.Transparent, CircleShape), contentAlignment = Alignment.Center) {
                        Icon(Icons.Default.Search, if (showingSearch) "Close inbox search" else "Search inbox", tint = LaterboxTextPrimary, modifier = Modifier.size(18.dp))
                    }
                }
            }
        }
        if (showingSearch) item {
            OutlinedTextField(value = query, onValueChange = { query = it }, placeholder = { Text("Search inbox…") }, singleLine = true,
                leadingIcon = { Icon(Icons.Default.Search, null) }, trailingIcon = { if (query.isNotEmpty()) IconButton(onClick = { query = "" }) { Icon(Icons.Default.Close, "Clear search") } },
                shape = RoundedCornerShape(12.dp), modifier = Modifier.fillMaxWidth())
        }
        if (formats.isNotEmpty()) item {
            Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                FilterChip(selected = selectedType == null, onClick = { selectedType = null }, label = { Text("All (${inbox.size})") })
                formats.forEach { format ->
                    FilterChip(selected = selectedType == format, onClick = { selectedType = if (selectedType == format) null else format },
                        leadingIcon = { Icon(inboxFormatIcon(format), null, Modifier.size(14.dp)) }, label = { Text("${inboxFormatLabel(format)} (${inbox.count { it.type == format }})") })
                }
            }
        }
        item {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                Text("QUEUE • ${queue.size} TO REVIEW", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = LaterboxTextSecondary, modifier = Modifier.weight(1f))
                Text(if (query.isBlank()) "FIFO Sorted" else "Search Results", fontSize = 10.sp, color = LaterboxAmber)
            }
        }
        actionError?.let { message -> item { Text(message, color = MaterialTheme.colorScheme.error) } }
        if (queue.isEmpty()) item {
            Surface(shape = RoundedCornerShape(20.dp), color = LaterboxCard, border = BorderStroke(1.dp, LaterboxBorder), modifier = Modifier.fillMaxWidth()) {
                Column(Modifier.padding(40.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(16.dp)) {
                    Icon(Icons.Default.Inbox, null, Modifier.size(44.dp), tint = LaterboxTextSecondary.copy(alpha = 0.4f))
                    Text(if (inbox.isEmpty()) "Inbox Zero!" else "No matches", fontWeight = FontWeight.Bold, color = LaterboxTextPrimary)
                    Text(if (inbox.isEmpty()) "All caught up. Everything saved has been processed or reviewed." else "Try another search or content format.", fontSize = 12.sp, color = LaterboxTextSecondary, textAlign = TextAlign.Center)
                    if (inbox.isEmpty()) TextButton(onClick = onCapture) { Text("Save something") }
                }
            }
        }
        items(queue, key = { it.id }) { item ->
            val metadata by produceState<ItemMetadataEntity?>(null, item.id, item.updatedAt) { value = runCatching { repository.getMetadata(item.id) }.getOrNull() }
            InboxRichItemCard(item, metadata, collections.find { it.id == item.collectionId }?.name,
                onOpen = { onItem(item) },
                onFavorite = { action { repository.toggleFavorite(item.id, item.favorite) } },
                onDone = { action { repository.updateItemStatus(item.id, "done") } },
                onSchedule = { days -> action { repository.scheduleReturn(item.id, LocalDate.now().plusDays(days).atTime(9, 0).atZone(ZoneId.systemDefault()).toInstant().toString()) } },
                onDelete = { action { repository.deleteItem(item.id) } })
        }
    }
}

@Composable
private fun InboxRichItemCard(item: ItemEntity, metadata: ItemMetadataEntity?, collectionName: String?, onOpen: () -> Unit, onFavorite: () -> Unit, onDone: () -> Unit, onSchedule: (Long) -> Unit, onDelete: () -> Unit) {
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
