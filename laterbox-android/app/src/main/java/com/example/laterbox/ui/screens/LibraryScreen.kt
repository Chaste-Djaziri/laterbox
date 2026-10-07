package com.example.laterbox.ui.screens

import androidx.activity.compose.BackHandler
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
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.laterbox.R
import com.example.laterbox.data.DataRepository
import com.example.laterbox.data.local.CollectionEntity
import com.example.laterbox.data.local.ItemEntity
import com.example.laterbox.services.AccountService
import com.example.laterbox.services.BackupService
import com.example.laterbox.services.LocalSearch
import com.example.laterbox.services.VaultStore
import com.example.laterbox.theme.*
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.time.ZoneId

internal enum class LibrarySection(val label: String, val icon: ImageVector) {
    FAVORITES("Favorites", Icons.Default.Star), KEPT("Kept", Icons.Default.Bookmark),
    ARCHIVED("Archived", Icons.Default.Archive), DELETED("Recently Deleted", Icons.Default.Delete)
}
internal data class LibraryFolder(val key: String, val name: String, val collectionId: String?)
internal fun libraryFolders(collections: List<CollectionEntity>, items: List<ItemEntity>): List<LibraryFolder> {
    val stored = collections.filter { it.deletedAt == null }.map { LibraryFolder(it.id, it.name, it.id) }
    val legacy = items.filter { it.deletedAt == null && it.collectionId == null && it.category.isNotBlank() }
        .map { it.category.trim() }.distinct().filter { name -> stored.none { it.name.equals(name, true) } }
        .map { LibraryFolder("legacy:$it", it, null) }
    return (stored + legacy).sortedBy { it.name.lowercase() }
}
internal fun librarySectionItems(section: LibrarySection, items: List<ItemEntity>): List<ItemEntity> = items.filter {
    val deleted = it.deletedAt != null || it.status == "deleted"
    when (section) {
        LibrarySection.FAVORITES -> !deleted && it.favorite
        LibrarySection.KEPT -> !deleted && it.status in listOf("saved", "done")
        LibrarySection.ARCHIVED -> !deleted && it.status == "archived"
        LibrarySection.DELETED -> deleted
    }
}
internal fun libraryFolderItems(folder: LibraryFolder, items: List<ItemEntity>): List<ItemEntity> = items.filter {
    it.deletedAt == null && it.status != "deleted" && (it.collectionId == folder.collectionId && folder.collectionId != null || it.collectionId == null && it.category.trim().equals(folder.name, true))
}

@Composable
fun LibraryScreen(repository: DataRepository, onItem: (ItemEntity) -> Unit) {
    val items by repository.items.collectAsState(emptyList())
    val trash by repository.trash.collectAsState(emptyList())
    val collections by repository.collections.collectAsState(emptyList())
    val account by AccountService.state.collectAsState()
    val folders = libraryFolders(collections, items)
    var page by rememberSaveable { mutableStateOf<String?>(null) }
    var query by rememberSaveable(page) { mutableStateOf("") }
    var format by rememberSaveable(page) { mutableStateOf<String?>(null) }
    var grid by rememberSaveable { mutableStateOf(false) }
    var menu by remember { mutableStateOf(false) }
    var nameDialog by remember { mutableStateOf(false) }
    var editingFolder by remember { mutableStateOf<LibraryFolder?>(null) }
    var newName by remember { mutableStateOf("") }
    var deleteFolder by remember { mutableStateOf<LibraryFolder?>(null) }
    var emptyTrash by remember { mutableStateOf(false) }
    var busy by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    val context = LocalContext.current
    val store = remember { VaultStore(context) }
    val scope = rememberCoroutineScope()
    val section = LibrarySection.entries.firstOrNull { page == "section:${it.name}" }
    val folder = folders.find { page == "folder:${it.key}" }
    val base = when { section != null -> librarySectionItems(section, items + trash); folder != null -> libraryFolderItems(folder, items); else -> emptyList() }
    val formats = base.map { it.type }.distinct().sorted()
    LaunchedEffect(formats) { if (format !in formats) format = null }
    val filtered = LocalSearch.search(query, base.filter { format == null || it.type == format }).sortedByDescending { it.createdAt }
    BackHandler(enabled = page != null) { page = null }
    fun action(block: suspend () -> Unit) {
        if (busy) return
        scope.launch { busy = true; error = null; try { block() } catch (cancelled: kotlinx.coroutines.CancellationException) { throw cancelled } catch (failure: Exception) { error = failure.message ?: "Unable to update your library. Please try again." } finally { busy = false } }
    }
    fun rename(folder: LibraryFolder) { editingFolder = folder; newName = folder.name; error = null; nameDialog = true }
    val sync = when { !account.pro -> "Local only"; items.any { it.syncStatus == "failed" } -> "Sync needs attention"; items.any { it.syncStatus == "pending" } -> "Pending sync"; else -> "Synced" }
    LazyColumn(Modifier.fillMaxSize().background(LaterboxBg), contentPadding = PaddingValues(20.dp), verticalArrangement = Arrangement.spacedBy(18.dp)) {
        item {
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                if (page != null) IconButton(onClick = { page = null }) { Icon(Icons.AutoMirrored.Filled.ArrowBack, "Back to Library") }
                Image(painterResource(R.drawable.laterbox_icon_green), "LaterBox", Modifier.size(28.dp).clip(RoundedCornerShape(7.dp)))
                Text("Library", Modifier.weight(1f).padding(start = 8.dp), fontSize = 24.sp, fontWeight = FontWeight.Bold, color = LaterboxTextPrimary)
                if (page == null) Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(5.dp)) {
                    Box(Modifier.size(7.dp).background(if (sync == "Synced") LaterboxEmerald else LaterboxAmber, CircleShape))
                    Text(sync, fontSize = 10.sp, color = LaterboxTextSecondary)
                } else {
                    IconButton(onClick = { grid = !grid }) { Icon(if (grid) Icons.Default.ViewList else Icons.Default.GridView, if (grid) "List view" else "Grid view") }
                    if (folder != null) Box {
                        IconButton(onClick = { menu = true }) { Icon(Icons.Default.MoreVert, "Collection options") }
                        DropdownMenu(menu, { menu = false }) {
                            DropdownMenuItem(text = { Text("Rename folder") }, onClick = { menu = false; rename(folder) })
                            DropdownMenuItem(text = { Text("Delete folder") }, onClick = { menu = false; deleteFolder = folder })
                        }
                    }
                }
            }
        }
        error?.let { message -> item { Text(message, color = MaterialTheme.colorScheme.error) } }
        if (page == null) {
            items(LibrarySection.entries.chunked(2)) { row ->
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    row.forEach { category ->
                        LibraryOverviewCard(category.label, category.icon, librarySectionItems(category, items + trash).size, Modifier.weight(1f)) { page = "section:${category.name}" }
                    }
                }
            }
            item {
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                    Text("COLLECTIONS", Modifier.weight(1f), fontSize = 11.sp, fontWeight = FontWeight.Bold, color = LaterboxTextSecondary)
                    TextButton(onClick = { editingFolder = null; newName = ""; error = null; nameDialog = true }) { Icon(Icons.Default.Add, null, Modifier.size(16.dp)); Text("Create Collection", fontSize = 12.sp) }
                }
            }
            if (folders.isEmpty()) item { LibraryEmpty("No collections yet", "Create a collection to organize your saved items into folders.") }
            items(folders.chunked(2)) { row ->
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    row.forEach { entry ->
                        Column(Modifier.weight(1f)) {
                            LibraryOverviewCard(entry.name, Icons.Default.Folder, libraryFolderItems(entry, items).size, Modifier.fillMaxWidth(), onRename = { rename(entry) }, onDelete = { deleteFolder = entry }) { page = "folder:${entry.key}" }
                        }
                    }
                    if (row.size == 1) Spacer(Modifier.weight(1f))
                }
            }
        } else {
            item {
                Text(section?.label ?: folder?.name.orEmpty(), fontSize = 28.sp, fontWeight = FontWeight.Bold, color = LaterboxTextPrimary)
                Text("${base.size} saved items", color = LaterboxTextSecondary, fontSize = 12.sp)
            }
            item { OutlinedTextField(query, { query = it }, placeholder = { Text("Search ${section?.label ?: folder?.name.orEmpty()}…") }, singleLine = true, leadingIcon = { Icon(Icons.Default.Search, null) }, trailingIcon = { if (query.isNotEmpty()) IconButton(onClick = { query = "" }) { Icon(Icons.Default.Close, "Clear search") } }, modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(12.dp)) }
            if (formats.isNotEmpty()) item {
                Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    FilterChip(format == null, { format = null }, label = { Text("All") })
                    formats.forEach { type -> FilterChip(format == type, { format = if (format == type) null else type }, label = { Text(type.replaceFirstChar { it.uppercase() }) }) }
                }
            }
            if (section == LibrarySection.DELETED && base.isNotEmpty()) item { TextButton(onClick = { emptyTrash = true }, enabled = !busy) { Text("Empty trash", color = MaterialTheme.colorScheme.error) } }
            if (filtered.isEmpty()) item { LibraryEmpty(if (query.isBlank() && format == null) "No items yet" else "No matches", if (section == LibrarySection.DELETED) "Deleted items will appear here so you can restore them." else "Save and organize items to find them here.") }
            if (grid && section != LibrarySection.DELETED) items(filtered.chunked(2)) { row ->
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    row.forEach { item -> LibraryOverviewCard(item.title ?: "Untitled", Icons.Default.Description, null, Modifier.weight(1f)) { onItem(item) } }
                    if (row.size == 1) Spacer(Modifier.weight(1f))
                }
            } else items(filtered, key = { it.id }) { item ->
                if (section == LibrarySection.DELETED) Surface(onClick = { onItem(item) }, shape = RoundedCornerShape(20.dp), color = LaterboxCard, border = BorderStroke(1.dp, LaterboxBorder)) {
                    Column(Modifier.fillMaxWidth().padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Text(item.title ?: "Untitled", fontWeight = FontWeight.Bold, color = LaterboxTextPrimary)
                        Text(item.type.replaceFirstChar { it.uppercase() }, color = LaterboxTextSecondary)
                        TextButton(onClick = { action { store.edit(item.copy(deletedAt = null, status = "inbox")); repository.syncNow() } }, enabled = !busy) { Text("Restore to Inbox") }
                    }
                } else {
                    val metadata by remember(repository, item.id) { repository.watchMetadata(item.id) }.collectAsState(null)
                    InboxRichItemCard(item, metadata, collections.find { it.id == item.collectionId }?.name,
                        onOpen = { onItem(item) }, onFavorite = { action { repository.toggleFavorite(item.id, item.favorite) } },
                        onDone = { action { repository.updateItemStatus(item.id, if (item.status == "done") "inbox" else "done") } },
                        onSchedule = { days -> action { repository.scheduleReturn(item.id, LocalDate.now().plusDays(days).atTime(9, 0).atZone(ZoneId.systemDefault()).toInstant().toString()) } },
                        onDelete = { action { repository.deleteItem(item.id) } })
                }
            }
        }
    }
    if (nameDialog) AlertDialog(onDismissRequest = { if (!busy) nameDialog = false }, title = { Text(if (editingFolder == null) "New Collection" else "Rename Collection") }, text = {
        Column { OutlinedTextField(newName, { newName = it }, label = { Text("Collection name") }, singleLine = true); error?.let { Text(it, color = MaterialTheme.colorScheme.error) } }
    }, confirmButton = { TextButton(enabled = !busy && newName.isNotBlank(), onClick = { action {
        val name = newName.trim()
        val current = editingFolder
        require(folders.none { it.key != current?.key && it.name.equals(name, true) }) { "A collection with this name already exists." }
        if (current?.collectionId != null) repository.renameCollection(current.collectionId, name)
        else {
            val created = repository.addCollection(name)
            if (current != null) { libraryFolderItems(current, items).forEach { store.edit(it.copy(category = name, collectionId = created.id)) }; repository.syncNow(); if (page == "folder:${current.key}") page = "folder:${created.id}" }
        }
        nameDialog = false
    } }) { Text(if (busy) "Saving…" else "Save") } }, dismissButton = { TextButton(enabled = !busy, onClick = { nameDialog = false }) { Text("Cancel") } })
    deleteFolder?.let { entry -> AlertDialog(onDismissRequest = { if (!busy) deleteFolder = null }, title = { Text("Delete ${entry.name}?") }, text = { Text("Items inside this collection will not be deleted. They will be unassigned from the folder.") }, confirmButton = { TextButton(enabled = !busy, onClick = { action {
        if (entry.collectionId != null) repository.deleteCollection(entry.collectionId) else { libraryFolderItems(entry, items).forEach { store.edit(it.copy(category = "", collectionId = null)) }; repository.syncNow() }
        deleteFolder = null; if (page == "folder:${entry.key}") page = null
    } }) { Text("Delete folder") } }, dismissButton = { TextButton(enabled = !busy, onClick = { deleteFolder = null }) { Text("Cancel") } }) }
    if (emptyTrash) AlertDialog(onDismissRequest = { if (!busy) emptyTrash = false }, title = { Text("Empty trash permanently?") }, text = { Text("Deleted captures and their local files will be permanently removed.") }, confirmButton = { TextButton(enabled = !busy, onClick = { action { BackupService.clearTrash(context); emptyTrash = false } }) { Text("Empty trash") } }, dismissButton = { TextButton(enabled = !busy, onClick = { emptyTrash = false }) { Text("Cancel") } })
}

@Composable
private fun LibraryOverviewCard(title: String, icon: ImageVector, count: Int?, modifier: Modifier, onRename: (() -> Unit)? = null, onDelete: (() -> Unit)? = null, onClick: () -> Unit) {
    var options by remember { mutableStateOf(false) }
    Surface(onClick = onClick, modifier = modifier, shape = RoundedCornerShape(18.dp), color = LaterboxCard, border = BorderStroke(1.dp, LaterboxBorder)) {
        Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween) {
                Box(Modifier.size(38.dp).background(LaterboxAccent, RoundedCornerShape(10.dp)), contentAlignment = Alignment.Center) { Icon(icon, null, Modifier.size(18.dp), tint = LaterboxTextPrimary) }
                Row(verticalAlignment = Alignment.CenterVertically) {
                    count?.let { Text(it.toString(), fontSize = 18.sp, fontWeight = FontWeight.Bold, color = LaterboxTextPrimary) }
                    if (onRename != null || onDelete != null) Box {
                        IconButton(onClick = { options = true }, modifier = Modifier.size(36.dp)) { Icon(Icons.Default.MoreVert, "$title folder options", modifier = Modifier.size(18.dp)) }
                        DropdownMenu(options, { options = false }) {
                            onRename?.let { DropdownMenuItem(text = { Text("Rename folder") }, onClick = { options = false; it() }) }
                            onDelete?.let { DropdownMenuItem(text = { Text("Delete folder") }, onClick = { options = false; it() }) }
                        }
                    }
                }
            }
            Text(title, fontWeight = FontWeight.Bold, color = LaterboxTextPrimary, maxLines = 2, overflow = TextOverflow.Ellipsis, fontSize = 14.sp)
            Text(if (count == null) "Open item ›" else "View items ›", fontSize = 11.sp, color = LaterboxTextSecondary)
        }
    }
}

@Composable
private fun LibraryEmpty(title: String, description: String) {
    Surface(modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(20.dp), color = LaterboxCard, border = BorderStroke(1.dp, LaterboxBorder)) {
        Column(Modifier.padding(28.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Icon(Icons.Default.FolderOpen, null, Modifier.size(36.dp), tint = LaterboxTextSecondary)
            Text(title, fontWeight = FontWeight.Bold, color = LaterboxTextPrimary)
            Text(description, color = LaterboxTextSecondary, fontSize = 12.sp)
        }
    }
}
