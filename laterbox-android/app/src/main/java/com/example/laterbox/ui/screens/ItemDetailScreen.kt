package com.example.laterbox.ui.screens

import android.content.Intent
import android.net.Uri
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.StarBorder
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.FileProvider
import com.example.laterbox.R
import com.example.laterbox.data.DataRepository
import com.example.laterbox.data.local.ItemEntity
import com.example.laterbox.services.VaultStore
import com.example.laterbox.theme.*
import com.example.laterbox.ui.capture.Field
import com.example.laterbox.ui.capture.ReturnChoices
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONArray
import java.io.File
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter

@Composable
fun ItemDetailScreen(initialItem: ItemEntity, repository: DataRepository, onBack: () -> Unit, onChanged: () -> Unit = {}) {
    val items by repository.items.collectAsState(emptyList())
    val collections by repository.collections.collectAsState(emptyList())
    val item = items.find { it.id == initialItem.id } ?: initialItem
    val metadata by remember(repository, item.id) { repository.watchMetadata(item.id) }.collectAsState(null)
    val context = LocalContext.current
    val store = remember { VaultStore(context) }
    val scope = rememberCoroutineScope()
    var editing by remember(item.id) { mutableStateOf(false) }
    var title by remember(item.id) { mutableStateOf(item.title.orEmpty()) }
    var content by remember(item.id) { mutableStateOf(item.textContent.orEmpty()) }
    var tags by remember(item.id) { mutableStateOf(item.tags) }
    var category by remember(item.id) { mutableStateOf(item.category) }
    var notes by remember(item.id) { mutableStateOf(item.notes) }
    var scheduling by remember(item.id) { mutableStateOf(false) }
    var deleting by remember(item.id) { mutableStateOf(false) }
    var busy by remember(item.id) { mutableStateOf(false) }
    var error by remember(item.id) { mutableStateOf<String?>(null) }
    LaunchedEffect(editing) {
        if (editing) { title = item.title.orEmpty(); content = item.textContent.orEmpty(); tags = item.tags; category = item.category; notes = item.notes }
    }
    fun update(updated: ItemEntity, close: Boolean = false) {
        if (busy) return
        scope.launch {
            busy = true; error = null
            try { store.edit(updated); repository.syncNow(); onChanged(); editing = false; scheduling = false; if (close) onBack() }
            catch (cancelled: kotlinx.coroutines.CancellationException) { throw cancelled }
            catch (_: Exception) { error = "Unable to save changes. Please try again." }
            finally { busy = false }
        }
    }
    fun open(intent: Intent) { runCatching { context.startActivity(intent) }.onFailure { error = "No app is available to open or share this content." } }
    fun share() = open(Intent.createChooser(Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_TEXT, item.url ?: item.textContent ?: item.title), "Share item"))
    BackHandler { if (editing) editing = false else onBack() }
    Column(Modifier.fillMaxSize().background(LaterboxBg).safeDrawingPadding()) {
        Row(Modifier.fillMaxWidth().padding(end = 12.dp), verticalAlignment = Alignment.CenterVertically) {
            IconButton(onClick = { if (editing) editing = false else onBack() }) { Icon(Icons.AutoMirrored.Filled.ArrowBack, "Back") }
            Image(painterResource(R.drawable.laterbox_icon_green), "LaterBox", Modifier.size(28.dp).clip(RoundedCornerShape(7.dp)))
            Text(if (editing) "Edit item" else "Item details", Modifier.weight(1f).padding(start = 10.dp), fontSize = 20.sp, fontWeight = FontWeight.Bold, color = LaterboxTextPrimary)
            IconButton(onClick = { update(item.copy(favorite = !item.favorite)) }, enabled = !busy) { Icon(if (item.favorite) Icons.Default.Star else Icons.Outlined.StarBorder, if (item.favorite) "Unstar" else "Star", tint = if (item.favorite) LaterboxAmber else LaterboxTextSecondary) }
            IconButton(onClick = { share() }) { Icon(Icons.Default.Share, "Share item") }
        }
        Column(Modifier.fillMaxWidth().weight(1f).verticalScroll(rememberScrollState()).padding(20.dp).imePadding(), verticalArrangement = Arrangement.spacedBy(20.dp)) {
            error?.let { Text(it, color = MaterialTheme.colorScheme.error) }
            if (editing) {
                DetailSection("EDIT DETAILS") {
                    Field(title, { title = it }, "Title")
                    Field(content, { content = it }, "Captured content")
                    Field(category, { category = it }, "Category / collection")
                    Field(tags, { tags = it }, "Tags (comma-separated)")
                    Field(notes, { notes = it }, "Your notes")
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        Button(onClick = { update(item.copy(title = title, textContent = content, category = category, tags = tags, notes = notes)) }, enabled = !busy) { Text(if (busy) "Saving…" else "Save changes") }
                        TextButton(onClick = { editing = false }, enabled = !busy) { Text("Cancel") }
                    }
                }
            } else {
                val source = item.url
                val kind = directMediaKind(source)
                val embed = hostedMediaPreview(source)
                val preview = metadata?.previewImageUrl?.takeIf { it.isNotBlank() }
                if (source != null && (kind != null || embed != null)) DetailSection("PREVIEW") {
                    when {
                        embed != null -> HostedItemPreview(embed)
                        kind == "image" -> ItemImagePreview(source, item.title.orEmpty())
                        kind == "video" -> ItemVideoPreview(source)
                        kind == "audio" -> ItemAudioPreview(source)
                        kind == "pdf" -> RemoteItemPdfPreview(source)
                    }
                    TextButton(onClick = { open(Intent(Intent.ACTION_VIEW, Uri.parse(source))) }) { Text("Open original") }
                } else if (preview != null) ItemImagePreview(preview, item.title.orEmpty())
                DetailSection("SOURCE & DETAILS") {
                    SelectionContainer { Text(item.title?.takeIf { it.isNotBlank() } ?: metadata?.title ?: "Untitled item", fontSize = 26.sp, lineHeight = 32.sp, fontWeight = FontWeight.Bold, color = LaterboxTextPrimary) }
                    Text("${item.type.replaceFirstChar { it.uppercase() }} · ${item.status.replaceFirstChar { it.uppercase() }}", color = LaterboxTextSecondary)
                    val domain = metadata?.siteName?.takeIf { it.isNotBlank() } ?: metadata?.domain?.takeIf { it.isNotBlank() }
                    domain?.let { Text(it, fontWeight = FontWeight.SemiBold) }
                    source?.let { url ->
                        SelectionContainer { Text(url, style = MaterialTheme.typography.bodySmall, color = LaterboxTextSecondary) }
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            TextButton(onClick = { open(Intent(Intent.ACTION_VIEW, Uri.parse(url))) }) { Text("Open original") }
                            TextButton(onClick = { (context.getSystemService(android.content.Context.CLIPBOARD_SERVICE) as android.content.ClipboardManager).setPrimaryClip(android.content.ClipData.newPlainText("Saved link", url)) }) { Text("Copy link") }
                        }
                    }
                    Text("Saved ${detailDate(item.createdAt)}", style = MaterialTheme.typography.bodySmall, color = LaterboxTextSecondary)
                    Text("Updated ${detailDate(item.updatedAt)}", style = MaterialTheme.typography.bodySmall, color = LaterboxTextSecondary)
                    metadata?.description?.takeIf { it.isNotBlank() && it != item.summary }?.let { Text(it, color = LaterboxTextSecondary) }
                }
                val attachments = remember(item.attachments) { runCatching { JSONArray(item.attachments) }.getOrNull() }
                attachments?.let { files ->
                    if (files.length() > 0) DetailSection("ATTACHMENTS & FILES") {
                        for (index in 0 until files.length()) {
                            val attachment = files.optJSONObject(index) ?: continue
                            val name = attachment.optString("name").ifBlank { "Attachment ${index + 1}" }
                            val mime = attachment.optString("mime", "application/octet-stream")
                            val file = trustedAttachment(attachment.optString("path"), File(context.filesDir, "captures"))
                            Text(name, fontWeight = FontWeight.Bold)
                            Text(mime, style = MaterialTheme.typography.bodySmall, color = LaterboxTextSecondary)
                            if (file == null) Text("This attachment is unavailable on this device.", color = LaterboxTextSecondary)
                            else {
                                key(file.path) {
                                    when {
                                        mime.startsWith("image/") -> ItemImagePreview(file, name)
                                        mime.startsWith("video/") -> ItemVideoPreview(file.path)
                                        mime.startsWith("audio/") -> ItemAudioPreview(file.path)
                                        mime == "application/pdf" || file.extension.equals("pdf", true) -> ItemPdfPreview(file)
                                        mime.startsWith("text/") || file.extension.lowercase() in listOf("txt", "md", "csv", "json", "xml", "html", "kt", "swift", "js", "py") -> {
                                            val text by produceState<String?>(null, file.path) { value = withContext(Dispatchers.IO) { runCatching { file.inputStream().use { String(it.readNBytes(128 * 1024), Charsets.UTF_8) } }.getOrDefault("Unable to read this file.") } }
                                            text?.let { DetailContent(it) }
                                            if (file.length() > 128 * 1024) Text("Showing the first 128 KB. Open the file to view all content.")
                                        }
                                        else -> Text("Use Open file to preview this format in a compatible app.", color = LaterboxTextSecondary)
                                    }
                                }
                                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                    TextButton(onClick = { runCatching { FileProvider.getUriForFile(context, context.packageName + ".files", file) }.onSuccess { uri -> open(Intent(Intent.ACTION_VIEW).setDataAndType(uri, mime).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)) }.onFailure { error = "Unable to open attachment." } }) { Text("Open file") }
                                    TextButton(onClick = { runCatching { FileProvider.getUriForFile(context, context.packageName + ".files", file) }.onSuccess { uri -> open(Intent.createChooser(Intent(Intent.ACTION_SEND).setType(mime).putExtra(Intent.EXTRA_STREAM, uri).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION), "Share file")) }.onFailure { error = "Unable to share attachment." } }) { Text("Share file") }
                                }
                            }
                            HorizontalDivider()
                        }
                    }
                }
                if (item.summary.isNotBlank()) DetailSection("SUMMARY") { DetailContent(item.summary) }
                val captured = item.formattedContent.ifBlank { item.textContent.orEmpty() }
                if (captured.isNotBlank()) DetailSection("CAPTURED CONTENT") { DetailContent(captured) }
                DetailSection("YOUR NOTES") {
                    if (item.notes.isBlank()) Text("No personal notes yet.", color = LaterboxTextSecondary) else DetailContent(item.notes)
                    TextButton(onClick = { editing = true }) { Text(if (item.notes.isBlank()) "Add notes" else "Edit notes") }
                }
                DetailSection("ORGANIZATION & RETURN") {
                    Text("Collection: ${collections.find { it.id == item.collectionId }?.name ?: item.category.ifBlank { "Unfiled" }}")
                    if (item.tags.isNotBlank()) Text("Tags: ${item.tags}")
                    Text("Return: ${item.returnAt?.let(::detailDate) ?: if (item.status == "deferred") "Someday" else "Not scheduled"}")
                    TextButton(onClick = { scheduling = !scheduling }, enabled = !busy) { Text("Schedule return") }
                    if (scheduling) ReturnChoices { date -> update(item.copy(returnAt = date, status = if (date == null) "inbox" else "deferred")) }
                    TextButton(onClick = { editing = true }) { Text("Edit details") }
                }
                DetailSection("ACTIONS") {
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        OutlinedButton(onClick = { update(item.copy(status = if (item.status == "done") "inbox" else "done")) }, enabled = !busy) { Text(if (item.status == "done") "Move to Inbox" else "Mark done") }
                        OutlinedButton(onClick = { update(item.copy(status = if (item.status == "archived") "inbox" else "archived")) }, enabled = !busy) { Text(if (item.status == "archived") "Unarchive" else "Archive") }
                    }
                    TextButton(onClick = { deleting = true }, enabled = !busy) { Text(if (item.deletedAt == null) "Delete item" else "Restore item", color = MaterialTheme.colorScheme.error) }
                }
            }
        }
    }
    if (deleting) AlertDialog(onDismissRequest = { deleting = false }, title = { Text(if (item.deletedAt == null) "Delete item?" else "Restore item?") }, text = { Text(if (item.deletedAt == null) "This item will move to Trash." else "This item will return to your Inbox.") }, confirmButton = { TextButton(onClick = { deleting = false; update(item.copy(deletedAt = if (item.deletedAt == null) Instant.now().toString() else null, status = if (item.deletedAt == null) "deleted" else "inbox"), close = true) }) { Text("Confirm") } }, dismissButton = { TextButton(onClick = { deleting = false }) { Text("Cancel") } })
}

@Composable
private fun DetailSection(title: String, content: @Composable ColumnScope.() -> Unit) {
    Surface(color = LaterboxCard, shape = RoundedCornerShape(20.dp), border = BorderStroke(1.dp, LaterboxBorder), modifier = Modifier.fillMaxWidth()) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text(title, fontSize = 11.sp, fontWeight = FontWeight.Bold, color = LaterboxTextSecondary, letterSpacing = 0.6.sp)
            content()
        }
    }
}

@Composable
private fun DetailContent(source: String) {
    val text = remember(source) { if (source.trimStart().startsWith("<")) org.jsoup.Jsoup.parse(source).apply { select("script,style,iframe").remove() }.body().wholeText() else source }
    SelectionContainer {
        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
            var code = false
            text.lineSequence().forEach { line ->
                if (line.startsWith("```")) code = !code
                else {
                    val heading = if (!code) line.takeWhile { it == '#' }.length.coerceAtMost(6) else 0
                    Text(if (heading > 0 && line.getOrNull(heading) == ' ') line.drop(heading + 1) else if (line.startsWith("- ")) "• ${line.drop(2)}" else line,
                        fontSize = if (heading > 0) (23 - heading).sp else 14.sp, lineHeight = 22.sp,
                        fontWeight = if (heading > 0) FontWeight.Bold else FontWeight.Normal,
                        fontFamily = if (code) FontFamily.Monospace else FontFamily.Default, color = LaterboxTextPrimary)
                }
            }
        }
    }
}

private fun detailDate(value: String): String = runCatching { Instant.parse(value).atZone(ZoneId.systemDefault()).format(DateTimeFormatter.ofPattern("MMM d, yyyy · HH:mm")) }.getOrDefault(value)
