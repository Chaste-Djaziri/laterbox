package com.example.laterbox.ui.screens

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Article
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Code
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Image
import androidx.compose.material.icons.filled.Link
import androidx.compose.material.icons.filled.MusicNote
import androidx.compose.material.icons.filled.PictureAsPdf
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Slideshow
import androidx.compose.material.icons.filled.TableChart
import androidx.compose.material.icons.filled.Videocam
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import androidx.compose.foundation.border
import androidx.compose.material.icons.automirrored.filled.Login
import androidx.compose.material.icons.automirrored.filled.Logout
import androidx.compose.material.icons.filled.Person
import com.example.laterbox.data.DataRepository
import com.example.laterbox.data.local.ItemEntity
import com.example.laterbox.services.AccountService
import com.example.laterbox.services.AccountState
import com.example.laterbox.services.LaterAIService
import com.example.laterbox.services.LocalSearch
import com.example.laterbox.theme.*
import com.example.laterbox.ui.capture.Field
import com.example.laterbox.ui.components.ItemCardView
import java.net.URI
import java.time.Instant
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@Composable
fun VaultScreen(
    tab: Int,
    repository: DataRepository,
    onCapture: () -> Unit,
    onAI: () -> Unit,
    onItem: (ItemEntity) -> Unit,
    onOrganizer: () -> Unit,
    onSignOut: () -> Unit = {},
    onAuth: () -> Unit = {},
    profileEnabled: Boolean = true
) {
    if (tab == 1) {
        InboxQueueScreen(repository, onItem, onOrganizer, onCapture)
        return
    }
    val allItems by repository.items.collectAsState(emptyList())
    val collections by repository.collections.collectAsState(emptyList())
    var query by rememberSaveable(tab) { mutableStateOf("") }
    var searchActive by rememberSaveable(tab) { mutableStateOf(false) }
    var type by rememberSaveable(tab) { mutableStateOf("All") }
    var collection by rememberSaveable(tab) { mutableStateOf<String?>(null) }
    var category by rememberSaveable(tab) { mutableStateOf("All") }
    var sort by rememberSaveable { mutableStateOf("Newest") }
    var addCollection by remember { mutableStateOf(false) }
    var newName by remember { mutableStateOf("") }; var error by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()
    val model = remember { LaterAIService() }
    var interpreted by remember { mutableStateOf("" to "") }
    DisposableEffect(model) { onDispose { model.close() } }
    LaunchedEffect(query) {
        interpreted = query to ""
        if (query.trim().length >= 4) {
            delay(400)
            interpreted = query to model.interpretQuery(query)
        }
    }
    val filtered = remember(allItems, tab, type, category, collection, query, sort, interpreted) {
        val eligible = allItems.filter { item -> when(tab) {
            1 -> item.status == "inbox"
            2 -> item.returnAt != null && item.status != "deleted" && item.status != "done" && item.status != "archived"
            3 -> when(category) { "Starred" -> item.favorite; "Archive" -> item.status == "archived"; "Done" -> item.status == "done"; else -> true }
            else -> true
        } }.filter { type == "All" || it.type == type.lowercase() }.filter { collection == null || it.collectionId == collection }
        val expanded = if (interpreted.first == query) interpreted.second else ""
        val results = LocalSearch.search(listOf(query, expanded).filter { it.isNotBlank() }.joinToString(" "), eligible)
        if (query.isNotBlank()) results else if (sort == "Oldest") results.sortedBy { it.createdAt } else if (tab == 2) results.sortedBy { it.returnAt } else results.sortedByDescending { it.createdAt }
    }
    val account by com.example.laterbox.services.AccountService.state.collectAsState()
    val userName = remember(account.displayName, account.email) {
        account.displayName?.takeIf { it.isNotBlank() }
            ?: account.email?.takeIf { it.isNotBlank() }?.substringBefore("@")?.replaceFirstChar { it.uppercase() }
            ?: "Guest"
    }
    val greetingText = remember {
        val hour = java.util.Calendar.getInstance().get(java.util.Calendar.HOUR_OF_DAY)
        when {
            hour < 12 -> "Good Morning"
            hour < 18 -> "Good Afternoon"
            else -> "Good Evening"
        }
    }
    val inboxWaitingItems = remember(allItems) {
        allItems.filter { it.status == "inbox" && it.deletedAt == null }
    }

    if (searchActive) {
        DedicatedSearchScreen(
            allItems = allItems,
            repository = repository,
            onClose = { searchActive = false },
            onItemClick = onItem
        )
        return
    }

    LazyColumn(
        Modifier.fillMaxSize().background(LaterboxBg),
        contentPadding = PaddingValues(20.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        if (tab == 0) {
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(
                        modifier = Modifier
                            .weight(1f)
                            .padding(end = 12.dp),
                        horizontalAlignment = Alignment.Start,
                        verticalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        Text(
                            text = "$greetingText, $userName",
                            fontSize = 22.sp,
                            fontWeight = FontWeight.Bold,
                            color = LaterboxTextPrimary,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                        Text(
                            text = "Your personal knowledge vault",
                            fontSize = 13.sp,
                            color = LaterboxTextSecondary,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    }

                    ProfileMenuButton(
                        userName = userName,
                        account = account,
                        onSignOut = onSignOut,
                        onAuth = onAuth,
                        enabled = profileEnabled
                    )
                }
            }
        }
        if (tab != 0) {
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(
                        modifier = Modifier
                            .weight(1f)
                            .padding(end = 12.dp)
                    ) {
                        Text(listOf("Home", "Inbox", "Returns", "Library")[tab], style = MaterialTheme.typography.headlineLarge)
                        Text("${filtered.size} saved items", color = LaterboxTextSecondary)
                    }

                    ProfileMenuButton(
                        userName = userName,
                        account = account,
                        onSignOut = onSignOut,
                        onAuth = onAuth,
                        enabled = profileEnabled
                    )
                }
            }
        }
        item {
            VaultSearchBar(
                query = query,
                onQueryChange = { query = it },
                placeholder = "Search your vault...",
                onClick = { searchActive = true }
            )
        }
        if (tab == 0) {
            item {
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    listOf("Inbox" to allItems.count { it.status == "inbox" }, "Returns" to allItems.count { it.status == "deferred" }, "Starred" to allItems.count { it.favorite }).forEach { (title, count) ->
                        Column(
                            Modifier.weight(1f).background(LaterboxCard, RoundedCornerShape(18.dp)).padding(16.dp)
                        ) {
                            Text(count.toString(), style = MaterialTheme.typography.headlineMedium)
                            Text(title, style = MaterialTheme.typography.labelMedium, color = LaterboxTextSecondary)
                        }
                    }
                }
            }

            item {
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(top = 6.dp, bottom = 2.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(
                            text = "WAITING FOR YOU",
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold,
                            color = LaterboxTextSecondary,
                            letterSpacing = 0.8.sp
                        )
                        if (inboxWaitingItems.isNotEmpty()) {
                            Text(
                                text = "${inboxWaitingItems.size} in inbox",
                                fontSize = 12.sp,
                                fontWeight = FontWeight.SemiBold,
                                color = LaterboxTextSecondary
                            )
                        }
                    }

                    if (inboxWaitingItems.isNotEmpty()) {
                        inboxWaitingItems.take(3).forEach { item ->
                            WaitingItemBar(
                                item = item,
                                onClick = { onItem(item) }
                            )
                        }
                    } else {
                        Surface(
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(18.dp),
                            color = LaterboxCard,
                            border = BorderStroke(1.dp, LaterboxBorder)
                        ) {
                            Column(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(24.dp),
                                horizontalAlignment = Alignment.CenterHorizontally,
                                verticalArrangement = Arrangement.spacedBy(6.dp)
                            ) {
                                Box(
                                    modifier = Modifier
                                        .size(40.dp)
                                        .background(LaterboxAccent, CircleShape),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Icon(
                                        imageVector = Icons.Default.CheckCircle,
                                        contentDescription = null,
                                        tint = LaterboxDarkSurface,
                                        modifier = Modifier.size(20.dp)
                                    )
                                }
                                Text(
                                    text = "All caught up",
                                    fontSize = 15.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = LaterboxTextPrimary
                                )
                                Text(
                                    text = "Nothing waiting in your inbox right now.",
                                    fontSize = 12.sp,
                                    color = LaterboxTextSecondary
                                )
                            }
                        }
                    }
                }
            }
        }
        if (tab != 0 || query.isNotEmpty()) {
            item {
                Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    listOf("All", "Link", "Article", "Video", "Music", "Note", "Document", "Image").forEach { option ->
                        FilterChip(selected = type == option, onClick = { type = option }, label = { Text(option) })
                    }
                }
            }
        }
        if (tab == 1) item { OutlinedButton(onClick = onOrganizer) { Text("✦ Organize inbox") } }
        if (tab == 3) {
            item {
                Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    listOf("All", "Starred", "Archive", "Done").forEach { option ->
                        FilterChip(category == option, { category = option }, label = { Text(option) })
                    }
                }
            }
            item {
                Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    FilterChip(collection == null, { collection = null }, label = { Text("All collections") })
                    collections.forEach { group -> FilterChip(collection == group.id, { collection = group.id }, label = { Text(group.name) }) }
                    OutlinedButton(onClick = { addCollection = true }) { Text("+ Collection") }
                }
            }
            if (collection != null) item { TextButton(onClick = { scope.launch { repository.deleteCollection(collection!!); collection = null } }) { Text("Delete collection") } }
        }
        if (tab != 0 || query.isNotEmpty()) {
            item { TextButton(onClick = { sort = if (sort == "Newest") "Oldest" else "Newest" }) { Text("Sort: $sort") } }
        }
        if (filtered.isEmpty() && (tab != 0 || query.isNotEmpty())) {
            item {
                Column(Modifier.fillMaxWidth().background(LaterboxCard, RoundedCornerShape(20.dp)).padding(24.dp)) {
                    Text(if (query.isEmpty()) "Nothing here yet" else "No matches", style = MaterialTheme.typography.titleLarge)
                    Text("Add a capture or try a topic, tag, or phrase you remember.")
                    TextButton(onClick = onCapture) { Text("Save something") }
                }
            }
        }
        if (tab != 0 || query.isNotEmpty()) {
            items(filtered, key = { it.id }) { item ->
                ItemCardView(
                    item = item,
                    onToggleFavorite = { scope.launch { repository.toggleFavorite(item.id, item.favorite) } },
                    onMarkDone = { scope.launch { repository.updateItemStatus(item.id, "done") } },
                    onScheduleReturn = { date -> scope.launch { repository.scheduleReturn(item.id, date) } },
                    onDelete = { scope.launch { repository.deleteItem(item.id) } },
                    onClick = { onItem(item) }
                )
            }
        }
    }
    if (addCollection) com.example.laterbox.ui.capture.DialogContent("New collection", { addCollection = false }) {
        Field(newName, { newName = it }, "Collection name")
        error?.let { Text(it) }
        Button(onClick = { scope.launch { try { require(newName.isNotBlank()); repository.addCollection(newName.trim()); addCollection = false; newName = "" } catch (failure: Exception) { error = "Enter a collection name and retry." } } }) { Text("Create") }
    }
}

@Composable
fun DedicatedSearchScreen(
    allItems: List<ItemEntity>,
    repository: DataRepository,
    onClose: () -> Unit,
    onItemClick: (ItemEntity) -> Unit
) {
    var query by rememberSaveable { mutableStateOf("") }
    var type by rememberSaveable { mutableStateOf("All") }
    val focusRequester = remember { FocusRequester() }
    val scope = rememberCoroutineScope()
    val model = remember { LaterAIService() }
    var interpreted by remember { mutableStateOf("" to "") }
    DisposableEffect(model) { onDispose { model.close() } }

    LaunchedEffect(query) {
        interpreted = query to ""
        if (query.trim().length >= 4) {
            delay(400)
            interpreted = query to model.interpretQuery(query)
        }
    }

    LaunchedEffect(Unit) {
        focusRequester.requestFocus()
    }

    BackHandler(onBack = onClose)

    val activeItems = remember(allItems) {
        allItems.filter { it.deletedAt == null && it.status != "deleted" }
    }

    val availableFilters = remember(activeItems) {
        val types = activeItems
            .map { it.type.trim() }
            .filter { it.isNotBlank() && !it.equals("unknown", ignoreCase = true) }
            .map { it.replaceFirstChar { c -> c.uppercase() } }
            .distinct()

        val tags = activeItems
            .flatMap { item ->
                item.tags.split(",")
                    .map { it.trim() }
                    .filter { it.isNotBlank() }
            }
            .distinctBy { it.lowercase() }

        (types + tags).distinctBy { it.lowercase() }
    }

    LaunchedEffect(availableFilters) {
        if (type != "All" && availableFilters.none { it.equals(type, ignoreCase = true) }) {
            type = "All"
        }
    }

    val filtered = remember(activeItems, type, query, interpreted) {
        val eligible = activeItems.filter { item ->
            if (type == "All") {
                true
            } else {
                item.type.equals(type, ignoreCase = true) ||
                item.tags.split(",").map { it.trim() }.any { it.equals(type, ignoreCase = true) } ||
                item.category.equals(type, ignoreCase = true)
            }
        }
        val expanded = if (interpreted.first == query) interpreted.second else ""
        LocalSearch.search(listOf(query, expanded).filter { it.isNotBlank() }.joinToString(" "), eligible)
            .sortedByDescending { it.createdAt }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(LaterboxBg)
            .statusBarsPadding()
    ) {
        // Search Header Row: Search Input + Close Button on right
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(start = 16.dp, end = 8.dp, top = 4.dp, bottom = 6.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Surface(
                modifier = Modifier
                    .weight(1f)
                    .height(48.dp),
                shape = RoundedCornerShape(16.dp),
                color = LaterboxCard,
                border = BorderStroke(1.dp, LaterboxBorder)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(horizontal = 14.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Search,
                        contentDescription = "Search",
                        tint = LaterboxTextSecondary,
                        modifier = Modifier.size(20.dp)
                    )

                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .fillMaxHeight(),
                        contentAlignment = Alignment.CenterStart
                    ) {
                        if (query.isEmpty()) {
                            Text(
                                text = "Search your vault...",
                                fontSize = 15.sp,
                                color = LaterboxTextSecondary
                            )
                        }
                        BasicTextField(
                            value = query,
                            onValueChange = { query = it },
                            singleLine = true,
                            textStyle = TextStyle(
                                fontSize = 15.sp,
                                color = LaterboxTextPrimary,
                                fontWeight = FontWeight.Normal
                            ),
                            modifier = Modifier
                                .fillMaxWidth()
                                .focusRequester(focusRequester)
                        )
                    }

                    if (query.isNotEmpty()) {
                        IconButton(
                            onClick = { query = "" },
                            modifier = Modifier.size(28.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.Close,
                                contentDescription = "Clear search",
                                tint = LaterboxTextSecondary,
                                modifier = Modifier.size(16.dp)
                            )
                        }
                    }
                }
            }

            IconButton(
                onClick = onClose,
                modifier = Modifier.size(40.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.Close,
                    contentDescription = "Close search",
                    tint = LaterboxTextPrimary,
                    modifier = Modifier.size(22.dp)
                )
            }
        }

        // Filter Chips Row (only from available content)
        if (availableFilters.isNotEmpty()) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState())
                    .padding(horizontal = 16.dp, vertical = 4.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                (listOf("All") + availableFilters).forEach { option ->
                    FilterChip(
                        selected = type.equals(option, ignoreCase = true),
                        onClick = { type = option },
                        label = { Text(option) }
                    )
                }
            }
        }

        // Search Results List
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            if (query.isBlank()) {
                item {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 48.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.Search,
                            contentDescription = null,
                            tint = LaterboxTextSecondary,
                            modifier = Modifier.size(36.dp)
                        )
                        Text(
                            text = "Search across your entire vault",
                            fontSize = 16.sp,
                            fontWeight = FontWeight.Bold,
                            color = LaterboxTextPrimary,
                            textAlign = TextAlign.Center,
                            modifier = Modifier.fillMaxWidth()
                        )
                        Text(
                            text = "Search titles, links, text content, tags, or topics",
                            fontSize = 13.sp,
                            color = LaterboxTextSecondary,
                            textAlign = TextAlign.Center,
                            modifier = Modifier.fillMaxWidth()
                        )
                    }
                }
            } else if (filtered.isEmpty()) {
                item {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(LaterboxCard, RoundedCornerShape(20.dp))
                            .padding(24.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        Text(
                            text = "No matches for \"$query\"",
                            fontSize = 16.sp,
                            fontWeight = FontWeight.Bold,
                            color = LaterboxTextPrimary,
                            textAlign = TextAlign.Center,
                            modifier = Modifier.fillMaxWidth()
                        )
                        Text(
                            text = "Try searching with a different keyword, tag, or domain.",
                            fontSize = 13.sp,
                            color = LaterboxTextSecondary,
                            textAlign = TextAlign.Center,
                            modifier = Modifier.fillMaxWidth()
                        )
                    }
                }
            } else {
                item {
                    Text(
                        text = "SEARCH RESULTS (${filtered.size})",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        color = LaterboxTextSecondary,
                        modifier = Modifier.padding(bottom = 2.dp)
                    )
                }
                items(filtered, key = { it.id }) { item ->
                    ItemCardView(
                        item = item,
                        onToggleFavorite = { scope.launch { repository.toggleFavorite(item.id, item.favorite) } },
                        onMarkDone = { scope.launch { repository.updateItemStatus(item.id, "done") } },
                        onScheduleReturn = { date -> scope.launch { repository.scheduleReturn(item.id, date) } },
                        onDelete = { scope.launch { repository.deleteItem(item.id) } },
                        onClick = { onItemClick(item) }
                    )
                }
            }
        }
    }
}

@Composable
fun VaultSearchBar(
    query: String,
    onQueryChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    placeholder: String = "Search your vault...",
    onClick: (() -> Unit)? = null
) {
    Surface(
        modifier = modifier
            .fillMaxWidth()
            .height(48.dp)
            .then(if (onClick != null) Modifier.clickable { onClick() } else Modifier),
        shape = RoundedCornerShape(16.dp),
        color = LaterboxCard,
        border = BorderStroke(1.dp, LaterboxBorder)
    ) {
        Row(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 14.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            Icon(
                imageVector = Icons.Default.Search,
                contentDescription = "Search",
                tint = LaterboxTextSecondary,
                modifier = Modifier.size(20.dp)
            )

            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxHeight(),
                contentAlignment = Alignment.CenterStart
            ) {
                if (query.isEmpty()) {
                    Text(
                        text = placeholder,
                        fontSize = 15.sp,
                        color = LaterboxTextSecondary
                    )
                }
                if (onClick != null) {
                    Text(
                        text = query.ifEmpty { placeholder },
                        fontSize = 15.sp,
                        color = if (query.isEmpty()) LaterboxTextSecondary else LaterboxTextPrimary
                    )
                } else {
                    BasicTextField(
                        value = query,
                        onValueChange = onQueryChange,
                        singleLine = true,
                        textStyle = TextStyle(
                            fontSize = 15.sp,
                            color = LaterboxTextPrimary,
                            fontWeight = FontWeight.Normal
                        ),
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            }

            if (query.isNotEmpty() && onClick == null) {
                IconButton(
                    onClick = { onQueryChange("") },
                    modifier = Modifier.size(28.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Close,
                        contentDescription = "Clear search",
                        tint = LaterboxTextSecondary,
                        modifier = Modifier.size(16.dp)
                    )
                }
            }
        }
    }
}

enum class ItemDocType(val label: String) {
    PDF("PDF"),
    PPT("Presentation"),
    DOCS("Document"),
    SHEETS("Spreadsheet"),
    AUDIO("Audio"),
    VIDEO("Video"),
    IMAGE("Image"),
    CODE("Code"),
    NOTE("Note"),
    LINK("Link")
}

fun resolveItemDocType(item: ItemEntity): ItemDocType {
    val type = item.type.lowercase().trim()
    val url = item.url?.lowercase()?.trim().orEmpty()
    val title = item.title?.lowercase()?.trim().orEmpty()
    val attachments = item.attachments.lowercase()

    // 1. PDF
    if (type == "pdf" ||
        url.endsWith(".pdf") || url.contains(".pdf?") || url.contains(".pdf#") ||
        title.endsWith(".pdf") || title.contains("[pdf]") ||
        attachments.contains(".pdf")
    ) {
        return ItemDocType.PDF
    }

    // 2. PPT / Presentation
    if (type in listOf("presentation", "ppt", "pptx", "slides", "keynote") ||
        url.endsWith(".ppt") || url.endsWith(".pptx") || url.endsWith(".key") || url.endsWith(".odp") ||
        title.endsWith(".ppt") || title.endsWith(".pptx") || title.endsWith(".key") ||
        attachments.contains(".ppt") || attachments.contains(".pptx") || attachments.contains(".key") ||
        url.contains("slides.google.com") || url.contains("pitch.com")
    ) {
        return ItemDocType.PPT
    }

    // 3. Spreadsheets / Sheets / Excel
    if (type in listOf("spreadsheet", "sheet", "csv", "excel", "numbers") ||
        url.endsWith(".xls") || url.endsWith(".xlsx") || url.endsWith(".csv") || url.endsWith(".numbers") ||
        attachments.contains(".xls") || attachments.contains(".xlsx") || attachments.contains(".csv") ||
        url.contains("sheets.google.com") || url.contains("airtable.com")
    ) {
        return ItemDocType.SHEETS
    }

    // 4. Audio
    if (type in listOf("audio", "music", "podcast") ||
        url.endsWith(".mp3") || url.endsWith(".wav") || url.endsWith(".m4a") || url.endsWith(".aac") || url.endsWith(".flac") || url.endsWith(".ogg") ||
        attachments.contains(".mp3") || attachments.contains(".wav") || attachments.contains(".m4a") ||
        url.contains("spotify.com") || url.contains("soundcloud.com") || url.contains("podcasts.apple.com")
    ) {
        return ItemDocType.AUDIO
    }

    // 5. Video
    if (type in listOf("video", "movie") ||
        url.endsWith(".mp4") || url.endsWith(".mov") || url.endsWith(".webm") || url.endsWith(".mkv") || url.endsWith(".avi") ||
        attachments.contains(".mp4") || attachments.contains(".mov") ||
        url.contains("youtube.com") || url.contains("youtu.be") || url.contains("vimeo.com") || url.contains("tiktok.com")
    ) {
        return ItemDocType.VIDEO
    }

    // 6. Docs / Text documents
    if (type in listOf("document", "doc", "docx", "word") ||
        url.endsWith(".doc") || url.endsWith(".docx") || url.endsWith(".odt") || url.endsWith(".rtf") || url.endsWith(".pages") || url.endsWith(".txt") ||
        attachments.contains(".doc") || attachments.contains(".docx") || attachments.contains(".txt") ||
        url.contains("docs.google.com")
    ) {
        return ItemDocType.DOCS
    }

    // 7. Image
    if (type == "image" ||
        url.endsWith(".jpg") || url.endsWith(".jpeg") || url.endsWith(".png") || url.endsWith(".gif") || url.endsWith(".webp") || url.endsWith(".svg") ||
        attachments.contains(".jpg") || attachments.contains(".jpeg") || attachments.contains(".png")
    ) {
        return ItemDocType.IMAGE
    }

    // 8. Code
    if (type in listOf("code", "repository", "repo", "github", "gitlab") ||
        url.contains("github.com") || url.contains("gitlab.com") ||
        url.endsWith(".json") || url.endsWith(".py") || url.endsWith(".js") || url.endsWith(".ts") || url.endsWith(".kt")
    ) {
        return ItemDocType.CODE
    }

    // 9. Note
    if (type == "note" || (item.url.isNullOrBlank() && item.textContent?.isNotBlank() == true)) {
        return ItemDocType.NOTE
    }

    // 10. Link (web URL or default)
    return ItemDocType.LINK
}

private data class ItemIconStyle(
    val icon: androidx.compose.ui.graphics.vector.ImageVector,
    val iconColor: Color = LaterboxDarkSurface,
    val containerBg: Color = LaterboxAccent,
    val allowsFavicon: Boolean = false
)

@Composable
fun WaitingItemBar(
    item: ItemEntity,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val docType = remember(item) { resolveItemDocType(item) }
    val iconStyle = when (docType) {
        ItemDocType.LINK -> ItemIconStyle(Icons.Default.Link, allowsFavicon = true)
        ItemDocType.PDF -> ItemIconStyle(Icons.Default.PictureAsPdf)
        ItemDocType.PPT -> ItemIconStyle(Icons.Default.Slideshow)
        ItemDocType.SHEETS -> ItemIconStyle(Icons.Default.TableChart)
        ItemDocType.DOCS -> ItemIconStyle(Icons.AutoMirrored.Filled.Article)
        ItemDocType.AUDIO -> ItemIconStyle(Icons.Default.MusicNote)
        ItemDocType.VIDEO -> ItemIconStyle(Icons.Default.Videocam)
        ItemDocType.IMAGE -> ItemIconStyle(Icons.Default.Image)
        ItemDocType.CODE -> ItemIconStyle(Icons.Default.Code)
        ItemDocType.NOTE -> ItemIconStyle(Icons.Default.Description)
    }

    val domain = remember(item.url) {
        if (!item.url.isNullOrEmpty()) {
            try {
                val uri = URI(item.url)
                val host = uri.host ?: ""
                host.removePrefix("www.")
            } catch (e: Exception) {
                ""
            }
        } else {
            ""
        }
    }

    val faviconUrl = remember(item.url, domain, iconStyle.allowsFavicon) {
        if (iconStyle.allowsFavicon && domain.isNotBlank()) {
            "https://www.google.com/s2/favicons?domain=$domain&sz=128"
        } else {
            null
        }
    }

    val subtitle = when {
        domain.isNotBlank() -> domain
        item.tags.isNotBlank() -> item.tags
        item.textContent?.isNotBlank() == true -> item.textContent.trim().take(40)
        else -> docType.label
    }

    Surface(
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(16.dp),
        color = LaterboxCard,
        border = BorderStroke(1.dp, LaterboxBorder)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 14.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Box(
                modifier = Modifier
                    .size(38.dp)
                    .background(iconStyle.containerBg, RoundedCornerShape(12.dp)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = iconStyle.icon,
                    contentDescription = null,
                    tint = iconStyle.iconColor,
                    modifier = Modifier.size(18.dp)
                )

                if (faviconUrl != null) {
                    Surface(
                        shape = RoundedCornerShape(7.dp),
                        color = LaterboxCard,
                        border = BorderStroke(0.5.dp, LaterboxBorder),
                        modifier = Modifier.size(24.dp)
                    ) {
                        Box(contentAlignment = Alignment.Center, modifier = Modifier.fillMaxSize()) {
                            AsyncImage(
                                model = faviconUrl,
                                contentDescription = null,
                                modifier = Modifier
                                    .size(16.dp)
                                    .clip(RoundedCornerShape(3.dp)),
                                contentScale = ContentScale.Fit
                            )
                        }
                    }
                }
            }

            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(2.dp)
            ) {
                Text(
                    text = item.title?.takeIf { it.isNotBlank() } ?: "Untitled",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = LaterboxTextPrimary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Text(
                    text = subtitle,
                    fontSize = 12.sp,
                    color = LaterboxTextSecondary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }

            Icon(
                imageVector = Icons.Default.Schedule,
                contentDescription = null,
                tint = LaterboxTextTertiary,
                modifier = Modifier.size(15.dp)
            )
        }
    }
}

@Composable
private fun ProfileMenuButton(
    userName: String,
    account: AccountState,
    onSignOut: () -> Unit,
    onAuth: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true
) {
    var expanded by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()
    val isGuest = account.userId == null

    Box(modifier = modifier) {
        Surface(
            modifier = Modifier
                .size(40.dp)
                .clip(CircleShape)
                .clickable(enabled = enabled) { expanded = true },
            shape = CircleShape,
            color = LaterboxCard,
            border = BorderStroke(1.dp, LaterboxBorder),
            shadowElevation = 1.dp
        ) {
            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier.fillMaxSize()
            ) {
                if (!isGuest && userName.isNotBlank() && userName != "Guest") {
                    Text(
                        text = userName.take(1).uppercase(),
                        fontSize = 15.sp,
                        fontWeight = FontWeight.Bold,
                        color = LaterboxTextPrimary
                    )
                } else {
                    Icon(
                        imageVector = Icons.Default.Person,
                        contentDescription = "Profile options",
                        tint = LaterboxTextSecondary,
                        modifier = Modifier.size(20.dp)
                    )
                }
            }
        }

        DropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false },
            modifier = Modifier
                .background(LaterboxCard)
                .border(1.dp, LaterboxBorder, RoundedCornerShape(12.dp))
                .widthIn(min = 210.dp)
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 12.dp)
            ) {
                Text(
                    text = if (isGuest) "Guest Mode" else userName,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Bold,
                    color = LaterboxTextPrimary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                if (!isGuest && !account.email.isNullOrBlank()) {
                    Text(
                        text = account.email,
                        fontSize = 12.sp,
                        color = LaterboxTextSecondary,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
                Spacer(modifier = Modifier.height(4.dp))
                Surface(
                    shape = RoundedCornerShape(6.dp),
                    color = if (account.pro) LaterboxAccent.copy(alpha = 0.25f) else LaterboxTextPrimary.copy(alpha = 0.06f)
                ) {
                    Text(
                        text = if (account.pro) "LaterBox Pro" else if (isGuest) "Local Vault" else "Free Account",
                        fontSize = 10.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = if (account.pro) LaterboxDarkSurface else LaterboxTextSecondary,
                        modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                    )
                }
            }

            HorizontalDivider(
                modifier = Modifier.padding(vertical = 4.dp),
                thickness = 0.5.dp,
                color = LaterboxBorder
            )

            if (!isGuest) {
                DropdownMenuItem(
                    text = {
                        Text(
                            text = "Log out",
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Medium,
                            color = LaterboxRose
                        )
                    },
                    leadingIcon = {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.Logout,
                            contentDescription = "Log out",
                            tint = LaterboxRose,
                            modifier = Modifier.size(18.dp)
                        )
                    },
                    onClick = {
                        expanded = false
                        scope.launch {
                            AccountService.signOut()
                            onSignOut()
                        }
                    }
                )
            } else {
                DropdownMenuItem(
                    text = {
                        Text(
                            text = "Sign in",
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Medium,
                            color = LaterboxTextPrimary
                        )
                    },
                    leadingIcon = {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.Login,
                            contentDescription = "Sign in",
                            tint = LaterboxTextPrimary,
                            modifier = Modifier.size(18.dp)
                        )
                    },
                    onClick = {
                        expanded = false
                        onAuth()
                    }
                )
            }
        }
    }
}


