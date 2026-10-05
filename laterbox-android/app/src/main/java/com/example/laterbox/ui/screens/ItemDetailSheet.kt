package com.example.laterbox.ui.screens

import android.content.Intent
import android.net.Uri
import android.media.MediaPlayer
import android.widget.VideoView
import android.widget.MediaController
import androidx.core.content.FileProvider
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import coil.compose.AsyncImage
import com.example.laterbox.data.local.ItemEntity
import com.example.laterbox.services.VaultStore
import com.example.laterbox.ui.capture.Field
import com.example.laterbox.ui.capture.ReturnChoices
import kotlinx.coroutines.launch
import org.json.JSONArray
import java.io.File
import java.time.Instant

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ItemDetailSheet(item: ItemEntity, onDismiss: () -> Unit, onChanged: () -> Unit) {
    val context = LocalContext.current; val scope = rememberCoroutineScope(); val store = remember { VaultStore(context) }
    var title by remember(item.id) { mutableStateOf(item.title.orEmpty()) }
    var content by remember(item.id) { mutableStateOf(item.textContent.orEmpty()) }
    var tags by remember(item.id) { mutableStateOf(item.tags) }
    var category by remember(item.id) { mutableStateOf(item.category) }
    var notes by remember(item.id) { mutableStateOf(item.notes) }
    var showReturn by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    var editing by remember { mutableStateOf(false) }
    fun update(updated: ItemEntity, close: Boolean = true) { scope.launch { try { store.edit(updated); onChanged(); if (close) onDismiss() } catch (failure: Exception) { error = failure.message } } }
    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)) {
        Column(Modifier.fillMaxWidth().padding(20.dp).verticalScroll(rememberScrollState()).imePadding(), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text(item.title.orEmpty(), style = MaterialTheme.typography.headlineSmall)
            Text("${item.type.replaceFirstChar { it.uppercase() }} · ${item.category.ifBlank { "Inbox" }}", style = MaterialTheme.typography.bodySmall)
            if (editing) {
                Field(title, { title = it }, "Title")
                Field(content, { content = it }, "Original content")
                Field(category, { category = it }, "Category / collection")
                Field(tags, { tags = it }, "Tags")
                Field(notes, { notes = it }, "Your notes")
                Button(onClick = { update(item.copy(title = title, textContent = content, tags = tags, category = category, notes = notes)) }) { Text("Save changes") }
            } else {
                if (item.summary.isNotBlank()) Text(item.summary)
                SelectionContainer { Text(item.formattedContent.ifBlank { item.textContent.orEmpty() }) }
                if (item.tags.isNotBlank()) Text(item.tags, style = MaterialTheme.typography.labelLarge)
                if (item.notes.isNotBlank()) { Text("Your notes", style = MaterialTheme.typography.titleMedium); SelectionContainer { Text(item.notes) } }
                val files = runCatching { JSONArray(item.attachments) }.getOrNull()
                files?.let { list -> for (index in 0 until list.length()) {
                    val attachment = list.getJSONObject(index)
                    val name = attachment.optString("name", "File"); val mime = attachment.optString("mime", "application/octet-stream")
                    val file = File(attachment.optString("path"))
                    if (file.exists() && file.canonicalPath.startsWith(File(context.filesDir, "captures").canonicalPath + File.separator)) {
                        Text(name)
                        when {
                            mime.startsWith("image/") -> AsyncImage(model = file, contentDescription = name, modifier = Modifier.fillMaxWidth().height(240.dp))
                            mime.startsWith("video/") -> AndroidView(factory = { androidContext -> VideoView(androidContext).apply { setVideoPath(file.path); setMediaController(MediaController(androidContext).also { it.setAnchorView(this) }) } }, modifier = Modifier.fillMaxWidth().height(240.dp))
                            mime.startsWith("audio/") -> AudioPreview(file)
                        }
                        Button(onClick = { runCatching { val uri = FileProvider.getUriForFile(context, context.packageName + ".files", file); context.startActivity(Intent(Intent.ACTION_VIEW).setDataAndType(uri, mime).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)) }.onFailure { error = "No app can open this file. Use Share to export it." } }) { Text("Open file") }
                        TextButton(onClick = { val uri = FileProvider.getUriForFile(context, context.packageName + ".files", file); context.startActivity(Intent.createChooser(Intent(Intent.ACTION_SEND).setType(mime).putExtra(Intent.EXTRA_STREAM, uri).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION), "Share file")) }) { Text("Share file") }
                    } else Text(attachment.optString("error", "This file is unavailable on this device."))
                } }
                item.url?.let { url -> Button(onClick = { runCatching { context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url))) }.onFailure { error = "Unable to open this link" } }) { Text("Open original") } }
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    TextButton(onClick = { editing = true }) { Text("Edit") }
                    TextButton(onClick = { context.startActivity(Intent.createChooser(Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_TEXT, item.url ?: item.textContent ?: item.title), "Share item")) }) { Text("Share") }
                    TextButton(onClick = { update(item.copy(favorite = !item.favorite)) }) { Text(if (item.favorite) "Unstar" else "Star") }
                }
                TextButton(onClick = { showReturn = !showReturn }) { Text("Schedule return") }
                if (showReturn) ReturnChoices { date -> update(item.copy(returnAt = date, status = if (date == null) "inbox" else "deferred")) }
                Row {
                    TextButton(onClick = { update(item.copy(status = if (item.status == "archived") "inbox" else "archived")) }) { Text(if (item.status == "archived") "Move to inbox" else "Archive") }
                    TextButton(onClick = { update(item.copy(status = "done")) }) { Text("Mark done") }
                    TextButton(onClick = { update(item.copy(deletedAt = if (item.deletedAt == null) Instant.now().toString() else null, status = if (item.deletedAt == null) "deleted" else "inbox")) }) { Text(if (item.deletedAt == null) "Delete" else "Restore") }
                }
            }
            error?.let { Text(it, color = MaterialTheme.colorScheme.error) }
            TextButton(onClick = onDismiss) { Text("Close") }
            Spacer(Modifier.height(20.dp))
        }
    }
}
@Composable
private fun AudioPreview(file: File) {
    val player = remember(file) { MediaPlayer().apply { setDataSource(file.path); prepare() } }
    var playing by remember { mutableStateOf(false) }
    DisposableEffect(player) { onDispose { player.release() } }
    Button(onClick = { if (playing) player.pause() else player.start(); playing = !playing }) { Text(if (playing) "Pause audio" else "Play audio") }
}
