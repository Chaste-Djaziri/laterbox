package com.example.laterbox

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.Folder
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Inbox
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Badge
import androidx.compose.material3.BadgedBox
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.FloatingActionButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.laterbox.data.DataRepository
import com.example.laterbox.data.DefaultDataRepository
import com.example.laterbox.data.local.AppDatabase
import com.example.laterbox.theme.LaterboxAccent
import com.example.laterbox.theme.LaterboxDarkSurface
import com.example.laterbox.ui.ai.LaterAIScreen
import com.example.laterbox.ui.auth.AuthSheet
import com.example.laterbox.ui.auth.WelcomeScreen
import com.example.laterbox.ui.capture.QuickCaptureSheet
import com.example.laterbox.ui.screens.HomeScreen
import com.example.laterbox.ui.screens.InboxScreen
import com.example.laterbox.ui.screens.LibraryScreen
import com.example.laterbox.ui.screens.ReturnsScreen
import com.example.laterbox.ui.screens.SettingsScreen

@Composable
fun AppNavigation(
    context: android.content.Context = LocalContext.current,
    repository: DataRepository = remember {
        val db = AppDatabase.getDatabase(context)
        DefaultDataRepository(context, db)
    }
) {
    val items by repository.items.collectAsState(initial = emptyList())
    val inboxCount = remember(items) { items.count { it.status == "inbox" } }

    var hasEnteredApp by remember { mutableStateOf(true) }
    var selectedTab by remember { mutableIntStateOf(0) } // 0: Home, 1: Inbox, 2: Returns, 3: Library, 4: Settings
    var showQuickCapture by remember { mutableStateOf(false) }
    var showLaterAI by remember { mutableStateOf(false) }
    var showAuthSheet by remember { mutableStateOf(false) }

    if (!hasEnteredApp) {
        WelcomeScreen(
            onContinueAsGuest = { hasEnteredApp = true },
            onOpenSignIn = { showAuthSheet = true }
        )
    } else {
        Scaffold(
            bottomBar = {
                NavigationBar(
                    containerColor = MaterialTheme.colorScheme.surface,
                    tonalElevation = 6.dp
                ) {
                    // Home
                    NavigationBarItem(
                        selected = selectedTab == 0,
                        onClick = { selectedTab = 0 },
                        icon = { Icon(Icons.Default.Home, contentDescription = "Home") },
                        label = { Text("Home", fontSize = 11.sp, fontWeight = if (selectedTab == 0) FontWeight.Bold else FontWeight.Normal) },
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = LaterboxDarkSurface,
                            selectedTextColor = LaterboxDarkSurface,
                            indicatorColor = LaterboxAccent
                        )
                    )

                    // Inbox
                    NavigationBarItem(
                        selected = selectedTab == 1,
                        onClick = { selectedTab = 1 },
                        icon = {
                            BadgedBox(
                                badge = {
                                    if (inboxCount > 0) {
                                        Badge(
                                            containerColor = LaterboxDarkSurface,
                                            contentColor = Color.White
                                        ) {
                                            Text(inboxCount.toString())
                                        }
                                    }
                                }
                            ) {
                                Icon(Icons.Default.Inbox, contentDescription = "Inbox")
                            }
                        },
                        label = { Text("Inbox", fontSize = 11.sp, fontWeight = if (selectedTab == 1) FontWeight.Bold else FontWeight.Normal) },
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = LaterboxDarkSurface,
                            selectedTextColor = LaterboxDarkSurface,
                            indicatorColor = LaterboxAccent
                        )
                    )

                    // Returns
                    NavigationBarItem(
                        selected = selectedTab == 2,
                        onClick = { selectedTab = 2 },
                        icon = { Icon(Icons.Default.CalendarToday, contentDescription = "Returns") },
                        label = { Text("Returns", fontSize = 11.sp, fontWeight = if (selectedTab == 2) FontWeight.Bold else FontWeight.Normal) },
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = LaterboxDarkSurface,
                            selectedTextColor = LaterboxDarkSurface,
                            indicatorColor = LaterboxAccent
                        )
                    )

                    // Library
                    NavigationBarItem(
                        selected = selectedTab == 3,
                        onClick = { selectedTab = 3 },
                        icon = { Icon(Icons.Default.Folder, contentDescription = "Library") },
                        label = { Text("Library", fontSize = 11.sp, fontWeight = if (selectedTab == 3) FontWeight.Bold else FontWeight.Normal) },
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = LaterboxDarkSurface,
                            selectedTextColor = LaterboxDarkSurface,
                            indicatorColor = LaterboxAccent
                        )
                    )

                    // Settings
                    NavigationBarItem(
                        selected = selectedTab == 4,
                        onClick = { selectedTab = 4 },
                        icon = { Icon(Icons.Default.Settings, contentDescription = "Settings") },
                        label = { Text("Settings", fontSize = 11.sp, fontWeight = if (selectedTab == 4) FontWeight.Bold else FontWeight.Normal) },
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = LaterboxDarkSurface,
                            selectedTextColor = LaterboxDarkSurface,
                            indicatorColor = LaterboxAccent
                        )
                    )
                }
            },
            floatingActionButton = {
                FloatingActionButton(
                    onClick = { showQuickCapture = true },
                    containerColor = LaterboxDarkSurface,
                    contentColor = LaterboxAccent,
                    shape = CircleShape,
                    elevation = FloatingActionButtonDefaults.elevation(defaultElevation = 4.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Add,
                        contentDescription = "Save Item",
                        modifier = Modifier.size(26.dp)
                    )
                }
            }
        ) { paddingValues ->
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues)
            ) {
                when (selectedTab) {
                    0 -> HomeScreen(
                        repository = repository,
                        onOpenQuickCapture = { showQuickCapture = true },
                        onOpenLaterAI = { showLaterAI = true },
                        onNavigateToTab = { tab -> selectedTab = tab }
                    )
                    1 -> InboxScreen(repository = repository)
                    2 -> ReturnsScreen(repository = repository)
                    3 -> LibraryScreen(repository = repository)
                    4 -> SettingsScreen(
                        repository = repository,
                        onOpenAuth = { showAuthSheet = true }
                    )
                }
            }
        }
    }

    // Modal Sheets
    if (showQuickCapture) {
        QuickCaptureSheet(
            repository = repository,
            onDismiss = { showQuickCapture = false },
            onSaved = { repository.syncNow() }
        )
    }

    if (showLaterAI) {
        LaterAIScreen(
            repository = repository,
            onDismiss = { showLaterAI = false }
        )
    }

    if (showAuthSheet) {
        AuthSheet(
            onDismiss = { showAuthSheet = false },
            onAuthenticated = {
                hasEnteredApp = true
                repository.syncNow()
            }
        )
    }
}
