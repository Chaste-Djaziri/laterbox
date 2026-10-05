package com.example.laterbox.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.example.laterbox.data.DataRepository
import com.example.laterbox.data.local.ItemEntity
import com.example.laterbox.services.LocalSearch
import com.example.laterbox.theme.*
import com.example.laterbox.ui.capture.Field
import com.example.laterbox.ui.components.ItemCardView
import kotlinx.coroutines.launch
import java.time.Instant

@Composable
fun VaultScreen(tab: Int, repository: DataRepository, onCapture: () -> Unit, onAI: () -> Unit, onItem: (ItemEntity) -> Unit, onOrganizer: () -> Unit) {
    val allItems by repository.items.collectAsState(emptyList())
    val collections by repository.collections.collectAsState(emptyList())
    var query by rememberSaveable(tab) { mutableStateOf("") }
    var type by rememberSaveable(tab) { mutableStateOf("All") }
    var collection by rememberSaveable(tab) { mutableStateOf<String?>(null) }
    var category by rememberSaveable(tab) { mutableStateOf("All") }
    var sort by rememberSaveable { mutableStateOf("Newest") }
    var addCollection by remember { mutableStateOf(false) }
    var newName by remember { mutableStateOf("") }; var error by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()
    val filtered = remember(allItems, tab, type, category, collection, query, sort) {
        val eligible = allItems.filter { item -> when(tab) {
            1 -> item.status == "inbox"
            2 -> item.returnAt != null && item.status != "deleted" && item.status != "done" && item.status != "archived"
            3 -> when(category) { "Starred" -> item.favorite; "Archive" -> item.status == "archived"; "Done" -> item.status == "done"; else -> true }
            else -> true
        } }.filter { type == "All" || it.type == type.lowercase() }.filter { collection == null || it.collectionId == collection }
        val results = LocalSearch.search(query, eligible)
        if (sort == "Oldest") results.sortedBy { it.createdAt } else if (tab == 2) results.sortedBy { it.returnAt } else results.sortedByDescending { it.createdAt }
    }
    LazyColumn(Modifier.fillMaxSize().background(LaterboxBg), contentPadding = PaddingValues(20.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
        item {
            Text(listOf("Home", "Inbox", "Returns", "Library")[tab], style = MaterialTheme.typography.headlineLarge)
            Text(if (tab == 0) "Your personal vault, ready when you are." else "${filtered.size} saved items", color = LaterboxTextSecondary)
        }
        if (tab == 0) {
            item {
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    listOf("Inbox" to allItems.count { it.status == "inbox" }, "Returns" to allItems.count { it.status == "deferred" }, "Starred" to allItems.count { it.favorite }).forEach { (title, count) ->
                        Column(Modifier.weight(1f).background(Color.White, RoundedCornerShape(18.dp)).padding(16.dp)) { Text(count.toString(), style = MaterialTheme.typography.headlineMedium); Text(title, style = MaterialTheme.typography.labelMedium) }
                    }
                }
            }
            item {
                Card(colors = CardDefaults.cardColors(containerColor = LaterboxDarkSurface), modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(24.dp)) {
                    Column(Modifier.padding(22.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        Text("Make room for later.", color = Color.White, style = MaterialTheme.typography.headlineMedium)
                        Text("Save a thought, a link, or something worth coming back to.", color = Color.LightGray)
                        Row { Button(onClick = onCapture, colors = ButtonDefaults.buttonColors(containerColor = LaterboxAccent, contentColor = Color.Black)) { Text("Add item") }; TextButton(onClick = onAI) { Text("✦ Later AI", color = LaterboxAccent) } }
                    }
                }
            }
        }
        item { Field(query, { query = it }, "Search titles, content, tags, topics…") }
        item { Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp)) { listOf("All", "Link", "Article", "Video", "Music", "Note", "Document").forEach { option -> FilterChip(selected = type == option, onClick = { type = option }, label = { Text(option) }) } } }
        if (tab == 1) item { OutlinedButton(onClick = onOrganizer) { Text("✦ Organize inbox") } }
        if (tab == 3) {
            item { Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp)) { listOf("All", "Starred", "Archive", "Done").forEach { option -> FilterChip(category == option, { category = option }, label = { Text(option) }) } } }
            item {
                Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    FilterChip(collection == null, { collection = null }, label = { Text("All collections") })
                    collections.forEach { group -> FilterChip(collection == group.id, { collection = group.id }, label = { Text(group.name) }) }
                    OutlinedButton(onClick = { addCollection = true }) { Text("+ Collection") }
                }
            }
            if (collection != null) item { TextButton(onClick = { scope.launch { repository.deleteCollection(collection!!); collection = null } }) { Text("Delete collection") } }
        }
        item { TextButton(onClick = { sort = if (sort == "Newest") "Oldest" else "Newest" }) { Text("Sort: $sort") } }
        if (filtered.isEmpty()) item {
            Column(Modifier.fillMaxWidth().background(Color.White, RoundedCornerShape(20.dp)).padding(24.dp)) { Text(if (query.isEmpty()) "Nothing here yet" else "No matches", style = MaterialTheme.typography.titleLarge); Text("Add a capture or try a topic, tag, or phrase you remember."); TextButton(onClick = onCapture) { Text("Save something") } }
        }
        items(if (tab == 0 && query.isEmpty()) filtered.take(10) else filtered, key = { it.id }) { item ->
            ItemCardView(item = item, onToggleFavorite = { scope.launch { repository.toggleFavorite(item.id, item.favorite) } },
                onMarkDone = { scope.launch { repository.updateItemStatus(item.id, "done") } },
                onReturn = { scope.launch { repository.scheduleReturn(item.id, java.time.LocalDate.now().plusDays(1).atTime(9,0).atZone(java.time.ZoneId.systemDefault()).toInstant().toString()) } },
                onDelete = { scope.launch { repository.deleteItem(item.id) } }, onClick = { onItem(item) })
        }
    }
    if (addCollection) com.example.laterbox.ui.capture.DialogContent("New collection", { addCollection = false }) {
        Field(newName, { newName = it }, "Collection name")
        error?.let { Text(it) }
        Button(onClick = { scope.launch { try { require(newName.isNotBlank()); repository.addCollection(newName.trim()); addCollection = false; newName = "" } catch (failure: Exception) { error = "Enter a collection name and retry." } } }) { Text("Create") }
    }
}
