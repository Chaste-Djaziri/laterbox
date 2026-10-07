package com.example.laterbox

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.zIndex
import com.example.laterbox.data.*
import com.example.laterbox.data.local.*
import com.example.laterbox.services.*
import com.example.laterbox.theme.*
import com.example.laterbox.ui.ai.LaterAIScreen
import com.example.laterbox.ui.auth.*
import com.example.laterbox.ui.capture.QuickCaptureSheet
import com.example.laterbox.ui.screens.*
import kotlinx.coroutines.launch
import java.time.Instant

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AppNavigation(notificationItemId: String? = null, context: android.content.Context = LocalContext.current, repository: DataRepository = remember { DefaultDataRepository(context, AppDatabase.getDatabase(context)) }) {
    val preferences = remember { context.getSharedPreferences("laterbox", 0) }
    val account by AccountService.state.collectAsState()
    val allItems by repository.items.collectAsState(emptyList())
    val items = allItems.filter { it.userId == null || it.userId == account.userId }
    var entered by rememberSaveable { mutableStateOf(preferences.getBoolean("entered", false)) }
    var tab by rememberSaveable { mutableIntStateOf(if ((context as? android.app.Activity)?.intent?.hasExtra("item_id") == true) 1 else 0) }
    var capture by remember { mutableStateOf(false) }; var ai by remember { mutableStateOf(false) }; var auth by remember { mutableStateOf(false) }
    var organizer by remember { mutableStateOf(false) }; var trash by remember { mutableStateOf(false) }
    var selected by remember { mutableStateOf<ItemEntity?>(null) }
    val scope = rememberCoroutineScope()
    LaunchedEffect(notificationItemId, items) {
        if (notificationItemId != null) { tab = 1; selected = items.firstOrNull { it.id == notificationItemId } }
    }
    LaunchedEffect(Unit) {
        AccountService.refresh()
        if (account.userId != null) entered = true
        val dao = AppDatabase.getDatabase(context).itemDao()
        dao.promoteDue(Instant.now().toString())
        dao.getAllItems().forEach { ReturnsService.schedule(context, it) }
        repository.syncNow()
    }
    selected?.let { item ->
        ItemDetailScreen(initialItem = item, repository = repository, onBack = { selected = null })
        return
    }
    if (!entered && account.userId == null) WelcomeScreen(onContinueAsGuest = { entered = true; preferences.edit().putBoolean("entered", true).apply() }, onOpenSignIn = { auth = true })
    else Scaffold(containerColor = LaterboxBg, bottomBar = {
        Surface(modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp), shape = RoundedCornerShape(28.dp), color = Color.White, shadowElevation = 8.dp) {
            NavigationBar(containerColor = Color.Transparent, tonalElevation = 0.dp) {
                val names = listOf("Home", "Inbox", "Returns", "Library", "Settings")
                val icons = listOf(Icons.Default.Home, Icons.Default.Inbox, Icons.Default.CalendarToday, Icons.Default.Folder, Icons.Default.Settings)
                names.forEachIndexed { index, name -> NavigationBarItem(selected = tab == index, onClick = { tab = index }, icon = { Icon(icons[index], contentDescription = name) }, label = { Text(name, style = MaterialTheme.typography.labelSmall) }, colors = NavigationBarItemDefaults.colors(indicatorColor = LaterboxAccent, selectedIconColor = Color.Black)) }
            }
        }
    }, floatingActionButton = { if (tab != 4) FloatingActionButton(onClick = { ai = true }, shape = CircleShape, containerColor = LaterboxDarkSurface, contentColor = LaterboxAccent) { Icon(Icons.Default.Add, "Later AI") } }) { padding ->
        Box(Modifier.fillMaxSize().padding(padding)) {
            if (tab < 4) VaultScreen(
                tab = tab,
                repository = repository,
                onCapture = { capture = true },
                onAI = { ai = true },
                onItem = { selected = it },
                onOrganizer = { organizer = true },
                onSignOut = {
                    preferences.edit().putBoolean("entered", false).apply()
                    entered = false
                },
                onAuth = { auth = true },
                profileEnabled = !ai
            )
            else NativeSettings(repository, { auth = true }, { trash = true })
        }
    }
    if (capture) QuickCaptureSheet(repository, { capture = false }, { repository.syncNow() })
    AnimatedVisibility(
        visible = ai,
        modifier = Modifier.fillMaxSize().zIndex(200f),
        enter = slideInVertically(initialOffsetY = { -it }) + fadeIn(),
        exit = slideOutVertically(targetOffsetY = { -it }) + fadeOut()
    ) {
        LaterAIScreen(repository = repository, onDismiss = { ai = false })
    }
    if (auth) AuthSheet(onDismiss = { auth = false }, onAuthenticated = { entered = true; preferences.edit().putBoolean("entered", true).apply(); repository.syncNow() })
    if (organizer) OrganizerSheet(items, { organizer = false }, { repository.syncNow() })
    if (trash) {
        val deleted by AppDatabase.getDatabase(context).itemDao().watchTrash().collectAsState(emptyList())
        ModalBottomSheet(onDismissRequest = { trash = false }) {
            LazyColumn(Modifier.fillMaxWidth().padding(20.dp)) {
                item { Text("Trash", style = MaterialTheme.typography.headlineLarge) }
                items(deleted.filter { it.userId == null || it.userId == account.userId }) { item -> ListItem(headlineContent = { Text(item.title.orEmpty()) }, supportingContent = { Text("Deleted capture") }, trailingContent = { TextButton(onClick = { scope.launch { AppDatabase.getDatabase(context).itemDao().restore(item.id, Instant.now().toString()); repository.syncNow() } }) { Text("Restore") } }) }
                if (deleted.isEmpty()) item { Text("Trash is empty") }
            }
        }
    }
}
