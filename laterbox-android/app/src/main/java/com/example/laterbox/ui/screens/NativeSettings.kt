package com.example.laterbox.ui.screens

import android.content.Intent
import android.net.Uri
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.Logout
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.FileProvider
import com.example.laterbox.BuildConfig
import com.example.laterbox.R
import com.example.laterbox.data.DataRepository
import com.example.laterbox.data.api.LaterBoxApiService
import com.example.laterbox.data.sync.CloudSyncState
import com.example.laterbox.services.*
import com.example.laterbox.theme.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter

enum class SettingsSubpage(val title: String) {
    ACCOUNT("Account Details"),
    SUBSCRIPTION("Plans"),
    SYNC("Sync"),
    NOTIFICATIONS("Notifications"),
    SECURITY("Security"),
    STORAGE("Storage"),
    AI_MODELS("AI Assistant"),
    SERVICE_STATUS("Service Status"),
    UPDATES("Updates")
}

@Composable
fun NativeSettings(
    repository: DataRepository,
    onAuth: () -> Unit,
    onTrash: () -> Unit,
    onBack: (() -> Unit)? = null
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val account by AccountService.state.collectAsState()
    val status by repository.webStatus.collectAsState()
    val items by repository.items.collectAsState(emptyList())
    val trash by repository.trash.collectAsState(emptyList())

    val preferences = remember { context.getSharedPreferences("laterbox", 0) }
    var lock by remember { mutableStateOf(preferences.getBoolean("app_lock", false)) }
    var fallback by remember { mutableStateOf(preferences.getBoolean("gemini_fallback", false)) }
    var protect by remember { mutableStateOf(preferences.getBoolean("screen_protection", false)) }
    var message by remember { mutableStateOf<String?>(null) }
    var clearing by remember { mutableStateOf(false) }
    var signOut by remember { mutableStateOf(false) }
    var plans by remember { mutableStateOf(false) }
    var searchRefine by remember { mutableStateOf(preferences.getBoolean("search_refine", true)) }
    var supportSheet by remember { mutableStateOf(false) }
    var showingDeleteAccountDialog by remember { mutableStateOf(false) }
    var isDeletingAccount by remember { mutableStateOf(false) }
    var busy by remember { mutableStateOf(false) }
    var bytes by remember { mutableLongStateOf(0) }
    var storageRefresh by remember { mutableIntStateOf(0) }
    val syncState by repository.syncState.collectAsState()
    val isPulling by repository.isPulling.collectAsState()
    val isPushing by repository.isPushing.collectAsState()
    val isSyncingState by repository.isSyncing.collectAsState()
    val pendingPullCount by repository.pendingPullCount.collectAsState()
    val pendingPushCount by repository.pendingPushCount.collectAsState()
    val lastSyncedAtState by repository.lastSyncedAt.collectAsState()

    var activeSubpage by rememberSaveable { mutableStateOf<SettingsSubpage?>(null) }

    LaunchedEffect(activeSubpage) {
        if (activeSubpage == SettingsSubpage.SYNC) {
            repository.refreshPendingCounts()
        }
    }

    LaunchedEffect(items.size, trash.size, storageRefresh) {
        bytes = withContext(Dispatchers.IO) {
            File(context.filesDir, "captures").walkTopDown().filter { it.isFile }.sumOf { it.length() }
        }
    }

    fun task(block: suspend () -> Unit) {
        if (busy) return
        scope.launch {
            busy = true
            try {
                block()
            } catch (cancelled: kotlinx.coroutines.CancellationException) {
                throw cancelled
            } catch (failure: Exception) {
                message = failure.message ?: "Unable to complete this action. Please try again."
            } finally {
                busy = false
            }
        }
    }

    fun open(intent: Intent) {
        runCatching { context.startActivity(intent) }.onFailure {
            message = "No app is available to open this page."
        }
    }

    val importer = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        if (uri != null) task {
            val count = BackupService.import(context, uri)
            message = "Imported $count captures"
            repository.syncNow()
            storageRefresh++
        }
    }

    val sync = when {
        !account.pro -> "Local only"
        syncState == CloudSyncState.SYNCING || isPulling || isPushing || isSyncingState -> "Syncing"
        syncState == CloudSyncState.ERROR -> "Needs attention"
        pendingPullCount > 0 || pendingPushCount > 0 -> "Sync needed"
        items.any { it.syncStatus == "failed" } -> "Needs attention"
        items.any { it.syncStatus == "pending" } -> "Pending sync"
        else -> "Synced"
    }

    val notificationsEnabled = remember {
        NotificationManagerCompat.from(context).areNotificationsEnabled()
    }

    if (activeSubpage != null) {
        BackHandler { activeSubpage = null }
    } else if (onBack != null) {
        BackHandler { onBack() }
    }

    Box(Modifier.fillMaxSize().background(LaterboxBg)) {
        if (activeSubpage == null) {
            // MAIN SETTINGS VIEW: Only links leading to subpages (matching iOS SettingsView)
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(horizontal = 20.dp, vertical = 20.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Header Bar (matching iOS Header Bar)
                item {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(top = 4.dp, bottom = 6.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        if (onBack != null) {
                            Surface(
                                modifier = Modifier
                                    .size(38.dp)
                                    .clip(CircleShape)
                                    .clickable { onBack() },
                                shape = CircleShape,
                                color = Color.Black.copy(alpha = 0.04f)
                            ) {
                                Box(contentAlignment = Alignment.Center, modifier = Modifier.fillMaxSize()) {
                                    Icon(
                                        imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                                        contentDescription = "Back to Inbox",
                                        tint = LaterboxTextPrimary,
                                        modifier = Modifier.size(18.dp)
                                    )
                                }
                            }
                        } else {
                            Image(
                                painter = painterResource(R.drawable.laterbox_icon_green),
                                contentDescription = "LaterBox",
                                modifier = Modifier
                                    .size(34.dp)
                                    .clip(RoundedCornerShape(8.dp))
                            )
                        }

                        Text(
                            text = "Settings",
                            fontSize = 18.sp,
                            fontWeight = FontWeight.Bold,
                            color = LaterboxTextPrimary,
                            textAlign = TextAlign.Center,
                            modifier = Modifier.weight(1f)
                        )

                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(5.dp),
                            modifier = Modifier.clickable {
                                if (!account.pro) plans = true
                            }
                        ) {
                            Box(
                                Modifier
                                    .size(7.dp)
                                    .background(if (sync == "Synced") LaterboxEmerald else LaterboxAmber, CircleShape)
                            )
                            Text(sync, fontSize = 11.sp, fontWeight = FontWeight.Medium, color = LaterboxTextSecondary)
                        }
                    }
                }

                message?.let { text ->
                    item {
                        Surface(color = LaterboxAccent.copy(alpha = 0.4f), shape = RoundedCornerShape(14.dp)) {
                            Row(Modifier.padding(start = 14.dp), verticalAlignment = Alignment.CenterVertically) {
                                Text(text, Modifier.weight(1f), fontSize = 13.sp, color = LaterboxTextPrimary)
                                IconButton(onClick = { message = null }) {
                                    Icon(Icons.Default.Close, "Dismiss message", Modifier.size(18.dp))
                                }
                            }
                        }
                    }
                }

                // Profile Card Link (matching iOS Profile Card)
                item {
                    Surface(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(18.dp))
                            .clickable { activeSubpage = SettingsSubpage.ACCOUNT },
                        shape = RoundedCornerShape(18.dp),
                        color = LaterboxCard,
                        border = BorderStroke(1.dp, LaterboxBorder)
                    ) {
                        Row(
                            modifier = Modifier.padding(16.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(14.dp)
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(52.dp)
                                    .background(LaterboxAccent, CircleShape),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Person,
                                    contentDescription = null,
                                    tint = LaterboxTextPrimary,
                                    modifier = Modifier.size(24.dp)
                                )
                            }

                            Column(
                                modifier = Modifier.weight(1f),
                                verticalArrangement = Arrangement.spacedBy(3.dp)
                            ) {
                                val email = account.email
                                if (!email.isNullOrBlank()) {
                                    Text(
                                        text = email,
                                        fontSize = 16.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = LaterboxTextPrimary,
                                        maxLines = 1,
                                        overflow = TextOverflow.Ellipsis
                                    )
                                    Text(
                                        text = if (account.pro) "LaterBox Pro Active" else "Free Cloud Account",
                                        fontSize = 12.sp,
                                        color = LaterboxTextSecondary,
                                        fontWeight = FontWeight.Medium
                                    )
                                } else {
                                    Text(
                                        text = "Guest Mode",
                                        fontSize = 16.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = LaterboxTextPrimary
                                    )
                                    Text(
                                        text = "Local saving active • Tap to sign in",
                                        fontSize = 12.sp,
                                        color = LaterboxTextSecondary
                                    )
                                }
                            }

                            Icon(
                                imageVector = Icons.Default.ChevronRight,
                                contentDescription = null,
                                tint = LaterboxTextSecondary.copy(alpha = 0.5f),
                                modifier = Modifier.size(16.dp)
                            )
                        }
                    }
                }

                // Group 1: Membership & Cloud
                item {
                    SettingsGroupCard(title = "MEMBERSHIP & CLOUD") {
                        SettingsLinkRow(
                            icon = Icons.Default.WorkspacePremium,
                            title = "Plans",
                            subtitle = "Cloud sync, AI models & storage tiers",
                            badge = if (account.pro) "Pro" else "Free",
                            onClick = { activeSubpage = SettingsSubpage.SUBSCRIPTION }
                        )
                        HorizontalDivider(color = LaterboxBorder, thickness = 0.5.dp)
                        SettingsLinkRow(
                            icon = Icons.Default.CloudSync,
                            title = "Sync",
                            subtitle = "Real-time sync status & platform health",
                            badge = sync,
                            onClick = { activeSubpage = SettingsSubpage.SYNC }
                        )
                    }
                }

                // Group 2: Preferences & System
                item {
                    SettingsGroupCard(title = "PREFERENCES & SYSTEM") {
                        SettingsLinkRow(
                            icon = Icons.Default.Notifications,
                            title = "Notifications",
                            subtitle = "Daily delivery schedule & system channel",
                            badge = if (notificationsEnabled) "On" else "Off",
                            onClick = { activeSubpage = SettingsSubpage.NOTIFICATIONS }
                        )
                        HorizontalDivider(color = LaterboxBorder, thickness = 0.5.dp)
                        SettingsLinkRow(
                            icon = Icons.Default.Lock,
                            title = "Security",
                            subtitle = "App Lock biometrics & screen protection",
                            badge = if (lock) "On" else "Off",
                            onClick = { activeSubpage = SettingsSubpage.SECURITY }
                        )
                    }
                }

                // Group 3: Data & Intelligence
                item {
                    SettingsGroupCard(title = "DATA & INTELLIGENCE") {
                        SettingsLinkRow(
                            icon = Icons.Default.Storage,
                            title = "Storage",
                            subtitle = "Backups, export & trash management",
                            badge = android.text.format.Formatter.formatFileSize(context, bytes),
                            onClick = { activeSubpage = SettingsSubpage.STORAGE }
                        )
                        HorizontalDivider(color = LaterboxBorder, thickness = 0.5.dp)
                        SettingsLinkRow(
                            icon = Icons.Default.AutoAwesome,
                            title = "AI Assistant",
                            subtitle = "Local responses · Offline assistant",
                            badge = if (account.pro) "Configured" else "Pro",
                            onClick = { activeSubpage = SettingsSubpage.AI_MODELS }
                        )
                    }
                }

                // Group 4: Support & Updates
                item {
                    SettingsGroupCard(title = "SUPPORT & UPDATES") {
                        SettingsLinkRow(
                            icon = Icons.Default.ShowChart,
                            title = "Service Status",
                            subtitle = "Live BetterStack monitor health & uptime",
                            badge = if (status.isOperational) "Operational" else "Issues",
                            onClick = { activeSubpage = SettingsSubpage.SERVICE_STATUS }
                        )
                        HorizontalDivider(color = LaterboxBorder, thickness = 0.5.dp)
                        SettingsLinkRow(
                            icon = Icons.Default.Update,
                            title = "Updates",
                            subtitle = "Release notes & update channel",
                            badge = "v${BuildConfig.VERSION_NAME}",
                            onClick = { activeSubpage = SettingsSubpage.UPDATES }
                        )
                        HorizontalDivider(color = LaterboxBorder, thickness = 0.5.dp)
                        SettingsLinkRow(
                            icon = Icons.Default.QuestionAnswer,
                            title = "Help",
                            subtitle = "Send diagnostics, suggestions or bug reports",
                            badge = null,
                            onClick = { supportSheet = true }
                        )
                    }
                }

                // Bottom Session Action Button (matching iOS)
                item {
                    if (account.userId != null) {
                        Surface(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(16.dp))
                                .clickable { signOut = true },
                            shape = RoundedCornerShape(16.dp),
                            color = LaterboxCard,
                            border = BorderStroke(1.dp, LaterboxBorder)
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(vertical = 14.dp),
                                horizontalArrangement = Arrangement.Center,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(
                                    imageVector = Icons.AutoMirrored.Filled.Logout,
                                    contentDescription = null,
                                    tint = Color(0xFFEF4444),
                                    modifier = Modifier.size(16.dp)
                                )
                                Spacer(Modifier.width(8.dp))
                                Text(
                                    text = "Log Out",
                                    fontSize = 15.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = Color(0xFFEF4444)
                                )
                            }
                        }
                    } else {
                        Surface(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(16.dp))
                                .clickable(onClick = onAuth),
                            shape = RoundedCornerShape(16.dp),
                            color = Color(0xFF171711)
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(vertical = 14.dp),
                                horizontalArrangement = Arrangement.Center,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Person,
                                    contentDescription = null,
                                    tint = Color.White,
                                    modifier = Modifier.size(16.dp)
                                )
                                Spacer(Modifier.width(8.dp))
                                Text(
                                    text = "Sign In",
                                    fontSize = 15.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = Color.White
                                )
                            }
                        }
                    }
                }

                // App Version Footer
                item {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(bottom = 16.dp, top = 4.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        Text(
                            text = "LaterBox for Android",
                            fontSize = 12.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = LaterboxTextSecondary
                        )
                        Text(
                            text = "Version ${BuildConfig.VERSION_NAME} (${BuildConfig.VERSION_CODE})",
                            fontSize = 11.sp,
                            color = LaterboxTextSecondary.copy(alpha = 0.7f)
                        )
                    }
                }
            }
        } else {
            // SUBPAGE VIEW: Rendered when user taps any settings link
            Column(Modifier.fillMaxSize()) {
                // Subpage Header
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Surface(
                        modifier = Modifier
                            .size(38.dp)
                            .clip(CircleShape)
                            .clickable { activeSubpage = null },
                        shape = CircleShape,
                        color = Color.Black.copy(alpha = 0.04f)
                    ) {
                        Box(contentAlignment = Alignment.Center, modifier = Modifier.fillMaxSize()) {
                            Icon(
                                imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                                contentDescription = "Back to Settings",
                                tint = LaterboxTextPrimary,
                                modifier = Modifier.size(18.dp)
                            )
                        }
                    }

                    Text(
                        text = activeSubpage!!.title,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold,
                        color = LaterboxTextPrimary,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.weight(1f)
                    )

                    Spacer(Modifier.size(38.dp))
                }

                if (activeSubpage == SettingsSubpage.SERVICE_STATUS) {
                    ServiceStatusView(modifier = Modifier.weight(1f))
                } else {
                    LazyColumn(
                        modifier = Modifier.weight(1f),
                        contentPadding = PaddingValues(horizontal = 20.dp, vertical = 16.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        when (activeSubpage) {
                        SettingsSubpage.ACCOUNT -> {
                            item {
                                Surface(
                                    modifier = Modifier.fillMaxWidth(),
                                    shape = RoundedCornerShape(18.dp),
                                    color = LaterboxCard,
                                    border = BorderStroke(1.dp, LaterboxBorder)
                                ) {
                                    Column(
                                        modifier = Modifier.padding(20.dp),
                                        horizontalAlignment = Alignment.CenterHorizontally,
                                        verticalArrangement = Arrangement.spacedBy(12.dp)
                                    ) {
                                        Box(
                                            modifier = Modifier
                                                .size(72.dp)
                                                .background(LaterboxAccent, CircleShape),
                                            contentAlignment = Alignment.Center
                                        ) {
                                            Icon(
                                                imageVector = Icons.Default.Person,
                                                contentDescription = null,
                                                tint = LaterboxTextPrimary,
                                                modifier = Modifier.size(34.dp)
                                            )
                                        }
                                        Text(
                                            text = account.displayName?.takeIf { it.isNotBlank() } ?: account.email ?: "Guest Mode",
                                            fontSize = 20.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = LaterboxTextPrimary,
                                            textAlign = TextAlign.Center
                                        )
                                        account.email?.let {
                                            Text(it, fontSize = 13.sp, color = LaterboxTextSecondary, textAlign = TextAlign.Center)
                                        }
                                        Text(
                                            text = if (account.pro) "LaterBox Pro Active" else if (account.userId == null) "Local saving active · Sign in for cloud sync" else "Free cloud account",
                                            fontSize = 13.sp,
                                            color = LaterboxTextSecondary,
                                            textAlign = TextAlign.Center
                                        )
                                        if (account.userId == null) {
                                            Button(onClick = onAuth, modifier = Modifier.padding(top = 8.dp)) {
                                                Text("Sign In")
                                            }
                                        } else {
                                            OutlinedButton(
                                                onClick = { signOut = true },
                                                modifier = Modifier.padding(top = 8.dp)
                                            ) {
                                                Text("Sign Out", color = Color(0xFFEF4444))
                                            }
                                        }
                                    }
                                }
                            }
                            item {
                                SettingsGroupCard(title = "ACCOUNT DETAILS") {
                                    SubpageValueRow("Status", if (account.userId != null) "Signed In" else "Local Guest")
                                    HorizontalDivider(color = LaterboxBorder, thickness = 0.5.dp)
                                    SubpageValueRow("Account Type", if (account.pro) "Pro" else if (account.userId != null) "Free" else "Guest")
                                    HorizontalDivider(color = LaterboxBorder, thickness = 0.5.dp)
                                    SubpageValueRow("User ID", account.userId?.take(12)?.plus("…") ?: "Not registered")
                                    if (account.userId != null && !account.googleLinked) {
                                        HorizontalDivider(color = LaterboxBorder, thickness = 0.5.dp)
                                        Column(
                                            modifier = Modifier.padding(14.dp),
                                            verticalArrangement = Arrangement.spacedBy(10.dp)
                                        ) {
                                            Text("Connect Google", fontSize = 15.sp, fontWeight = FontWeight.Bold, color = LaterboxTextPrimary)
                                            Text("Keep using this account when email login is retired.", fontSize = 12.sp, color = LaterboxTextSecondary)
                                            Button(
                                                onClick = {
                                                    val activity = context as? android.app.Activity ?: return@Button
                                                    scope.launch {
                                                        busy = true
                                                        try {
                                                            GoogleAuthService.link(activity)
                                                            AccountService.refresh()
                                                            message = "Google account connected."
                                                        } catch (error: Exception) {
                                                            message = error.message ?: "Unable to connect Google right now."
                                                        } finally { busy = false }
                                                    }
                                                },
                                                enabled = !busy,
                                                modifier = Modifier.fillMaxWidth().height(48.dp),
                                                shape = RoundedCornerShape(12.dp),
                                                colors = ButtonDefaults.buttonColors(containerColor = Color.White, contentColor = LaterboxTextPrimary)
                                            ) {
                                                if (busy) CircularProgressIndicator(modifier = Modifier.size(18.dp), strokeWidth = 2.dp)
                                                else {
                                                    Image(painter = painterResource(R.drawable.ic_google_g), contentDescription = null, modifier = Modifier.size(20.dp))
                                                    Spacer(Modifier.width(8.dp))
                                                    Text("Connect with Google", fontWeight = FontWeight.Bold)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        SettingsSubpage.SUBSCRIPTION -> {
                            item {
                                Surface(
                                    modifier = Modifier.fillMaxWidth(),
                                    shape = RoundedCornerShape(18.dp),
                                    color = LaterboxCard,
                                    border = BorderStroke(1.dp, LaterboxBorder)
                                ) {
                                    Column(
                                        modifier = Modifier.padding(20.dp),
                                        verticalArrangement = Arrangement.spacedBy(14.dp)
                                    ) {
                                        Row(
                                            modifier = Modifier.fillMaxWidth(),
                                            verticalAlignment = Alignment.CenterVertically
                                        ) {
                                            Column(modifier = Modifier.weight(1f)) {
                                                Text(
                                                    text = if (account.pro) "LaterBox Pro" else "LaterBox Local",
                                                    fontSize = 20.sp,
                                                    fontWeight = FontWeight.Bold,
                                                    color = LaterboxTextPrimary
                                                )
                                                Text(
                                                    text = if (account.pro) "Connected cloud features active" else "Free offline vault active",
                                                    fontSize = 12.sp,
                                                    color = LaterboxTextSecondary
                                                )
                                            }
                                            Surface(
                                                color = LaterboxAccent,
                                                shape = RoundedCornerShape(50)
                                            ) {
                                                Text(
                                                    text = if (account.pro) "Active" else "Free Forever",
                                                    modifier = Modifier.padding(horizontal = 10.dp, vertical = 5.dp),
                                                    fontSize = 11.sp,
                                                    fontWeight = FontWeight.Bold
                                                )
                                            }
                                        }

                                        Text(
                                            text = if (account.pro)
                                                "Cloud sync, connected extensions, and Later AI models are active across your devices."
                                            else
                                                "Save, organize, and export your captures offline. Upgrade to Pro for cloud sync across devices and full AI intelligence.",
                                            fontSize = 13.sp,
                                            color = LaterboxTextSecondary,
                                            lineHeight = 18.sp
                                        )

                                        if (account.pro) {
                                            var openingPaddle by remember { mutableStateOf(false) }
                                            Button(
                                                onClick = {
                                                    scope.launch {
                                                        openingPaddle = true
                                                        try {
                                                            val paddleUrl = LaterBoxApiService.getPaddleManagementUrl()
                                                            if (!paddleUrl.isNullOrBlank()) {
                                                                open(Intent(Intent.ACTION_VIEW, Uri.parse(paddleUrl)))
                                                            } else {
                                                                open(Intent(Intent.ACTION_VIEW, Uri.parse("https://app.laterbox.dev/login?next=%2Fplans")))
                                                            }
                                                        } catch (_: Exception) {
                                                            message = "Could not open Paddle subscription management."
                                                        } finally {
                                                            openingPaddle = false
                                                        }
                                                    }
                                                },
                                                enabled = !openingPaddle,
                                                modifier = Modifier.fillMaxWidth()
                                            ) {
                                                if (openingPaddle) {
                                                    CircularProgressIndicator(
                                                        modifier = Modifier.size(16.dp),
                                                        strokeWidth = 2.dp,
                                                        color = Color.White
                                                    )
                                                    Spacer(Modifier.width(8.dp))
                                                } else {
                                                    Icon(
                                                        imageVector = Icons.Default.CreditCard,
                                                        contentDescription = null,
                                                        modifier = Modifier.size(16.dp)
                                                    )
                                                    Spacer(Modifier.width(8.dp))
                                                }
                                                Text("Manage Subscription with Paddle")
                                            }

                                            OutlinedButton(
                                                onClick = { plans = true },
                                                modifier = Modifier.fillMaxWidth()
                                            ) {
                                                Text("View Plans & Inclusions")
                                            }
                                        } else {
                                            Button(
                                                onClick = { plans = true },
                                                modifier = Modifier.fillMaxWidth()
                                            ) {
                                                Text("Explore Plans ($3.99/mo)")
                                            }
                                        }

                                        OutlinedButton(
                                            onClick = {
                                                scope.launch {
                                                    try {
                                                        AccountService.refresh()
                                                        repository.syncNow()
                                                        message = if (AccountService.state.value.pro) "Pro access confirmed." else "Subscription refreshed. Pro not active on this account."
                                                    } catch (_: Exception) {
                                                        message = "Could not refresh subscription."
                                                    }
                                                }
                                            },
                                            modifier = Modifier.fillMaxWidth()
                                        ) {
                                            Text("Refresh Subscription Status")
                                        }
                                    }
                                }
                            }
                        }

                        SettingsSubpage.SYNC -> {
                            item {
                                SettingsGroupCard(title = "CLOUD SYNC STATUS") {
                                    SubpageValueRow("Sync State", sync)
                                    HorizontalDivider(color = LaterboxBorder, thickness = 0.5.dp)
                                    SubpageValueRow(
                                        "Pending Cloud Pull",
                                        if (pendingPullCount > 0) "$pendingPullCount available to pull" else "Up to date"
                                    )
                                    HorizontalDivider(color = LaterboxBorder, thickness = 0.5.dp)
                                    SubpageValueRow(
                                        "Pending Local Push",
                                        if (pendingPushCount > 0) "$pendingPushCount unpushed edits" else "Up to date"
                                    )
                                    HorizontalDivider(color = LaterboxBorder, thickness = 0.5.dp)
                                    val lastSyncStamp = lastSyncedAtState?.let { instant ->
                                        runCatching {
                                            instant.atZone(ZoneId.systemDefault()).format(DateTimeFormatter.ofPattern("MMM d · HH:mm"))
                                        }.getOrNull()
                                    } ?: items.mapNotNull { it.lastSyncedAt }.maxOrNull()?.let { stamp ->
                                        runCatching {
                                            Instant.parse(stamp).atZone(ZoneId.systemDefault()).format(DateTimeFormatter.ofPattern("MMM d · HH:mm"))
                                        }.getOrDefault(stamp)
                                    } ?: "Not synced yet"
                                    SubpageValueRow("Last Synced", lastSyncStamp)
                                    HorizontalDivider(color = LaterboxBorder, thickness = 0.5.dp)
                                    SubpageValueRow("Platform Health", status.label)
                                }
                            }
                            item {
                                Surface(
                                    modifier = Modifier.fillMaxWidth(),
                                    shape = RoundedCornerShape(18.dp),
                                    color = LaterboxCard,
                                    border = BorderStroke(1.dp, LaterboxBorder)
                                ) {
                                    Column(
                                        modifier = Modifier.padding(18.dp),
                                        verticalArrangement = Arrangement.spacedBy(12.dp)
                                    ) {
                                        Text(
                                            text = "Sync Actions",
                                            fontSize = 14.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = LaterboxTextPrimary
                                        )

                                        if (account.pro) {
                                            val isBusySyncing = isPulling || isPushing || isSyncingState || syncState == CloudSyncState.SYNCING

                                            // 1. Separate Pull Changes
                                            Surface(
                                                modifier = Modifier
                                                    .fillMaxWidth()
                                                    .clip(RoundedCornerShape(14.dp))
                                                    .clickable(enabled = !isBusySyncing) {
                                                        scope.launch {
                                                            repository.pullChanges()
                                                            message = "Pull completed"
                                                        }
                                                    },
                                                shape = RoundedCornerShape(14.dp),
                                                color = LaterboxCard,
                                                border = BorderStroke(
                                                    1.dp,
                                                    if (pendingPullCount > 0) Color(0xFF2563EB).copy(alpha = 0.4f) else LaterboxBorder
                                                )
                                            ) {
                                                Row(
                                                    modifier = Modifier
                                                        .fillMaxWidth()
                                                        .padding(vertical = 14.dp, horizontal = 16.dp),
                                                    horizontalArrangement = Arrangement.Center,
                                                    verticalAlignment = Alignment.CenterVertically
                                                ) {
                                                    if (isPulling) {
                                                        CircularProgressIndicator(
                                                            modifier = Modifier.size(16.dp),
                                                            strokeWidth = 2.dp,
                                                            color = LaterboxTextPrimary
                                                        )
                                                        Spacer(Modifier.width(8.dp))
                                                    } else {
                                                        Icon(
                                                            imageVector = Icons.Default.ArrowDownward,
                                                            contentDescription = null,
                                                            tint = if (pendingPullCount > 0) Color(0xFF2563EB) else LaterboxTextPrimary,
                                                            modifier = Modifier.size(16.dp)
                                                        )
                                                        Spacer(Modifier.width(8.dp))
                                                    }
                                                    Text(
                                                        text = if (isPulling) "Pulling from Cloud…" else if (pendingPullCount > 0) "Pull Changes ($pendingPullCount Available)" else "Pull Changes from Cloud",
                                                        fontSize = 14.sp,
                                                        fontWeight = FontWeight.SemiBold,
                                                        color = LaterboxTextPrimary
                                                    )
                                                }
                                            }

                                            // 2. Separate Push Changes
                                            Surface(
                                                modifier = Modifier
                                                    .fillMaxWidth()
                                                    .clip(RoundedCornerShape(14.dp))
                                                    .clickable(enabled = !isBusySyncing) {
                                                        scope.launch {
                                                            repository.pushChanges()
                                                            message = "Push completed"
                                                        }
                                                    },
                                                shape = RoundedCornerShape(14.dp),
                                                color = LaterboxCard,
                                                border = BorderStroke(
                                                    1.dp,
                                                    if (pendingPushCount > 0) Color(0xFFD97706).copy(alpha = 0.4f) else LaterboxBorder
                                                )
                                            ) {
                                                Row(
                                                    modifier = Modifier
                                                        .fillMaxWidth()
                                                        .padding(vertical = 14.dp, horizontal = 16.dp),
                                                    horizontalArrangement = Arrangement.Center,
                                                    verticalAlignment = Alignment.CenterVertically
                                                ) {
                                                    if (isPushing) {
                                                        CircularProgressIndicator(
                                                            modifier = Modifier.size(16.dp),
                                                            strokeWidth = 2.dp,
                                                            color = LaterboxTextPrimary
                                                        )
                                                        Spacer(Modifier.width(8.dp))
                                                    } else {
                                                        Icon(
                                                            imageVector = Icons.Default.ArrowUpward,
                                                            contentDescription = null,
                                                            tint = if (pendingPushCount > 0) Color(0xFFD97706) else LaterboxTextPrimary,
                                                            modifier = Modifier.size(16.dp)
                                                        )
                                                        Spacer(Modifier.width(8.dp))
                                                    }
                                                    Text(
                                                        text = if (isPushing) "Pushing to Cloud…" else if (pendingPushCount > 0) "Push Changes ($pendingPushCount Unpushed)" else "Push Changes to Cloud",
                                                        fontSize = 14.sp,
                                                        fontWeight = FontWeight.SemiBold,
                                                        color = LaterboxTextPrimary
                                                    )
                                                }
                                            }

                                            // 3. Full Sync (Pull then Push)
                                            Button(
                                                onClick = {
                                                    scope.launch {
                                                        repository.syncNow()
                                                        message = "Full sync initiated"
                                                    }
                                                },
                                                enabled = !isBusySyncing,
                                                modifier = Modifier.fillMaxWidth(),
                                                shape = RoundedCornerShape(14.dp),
                                                colors = ButtonDefaults.buttonColors(
                                                    containerColor = Color(0xFF8B5CF6),
                                                    contentColor = Color.White
                                                )
                                            ) {
                                                if (isSyncingState) {
                                                    CircularProgressIndicator(
                                                        modifier = Modifier.size(16.dp),
                                                        strokeWidth = 2.dp,
                                                        color = Color.White
                                                    )
                                                    Spacer(Modifier.width(8.dp))
                                                } else {
                                                    Icon(
                                                        imageVector = Icons.Default.Sync,
                                                        contentDescription = null,
                                                        tint = Color.White,
                                                        modifier = Modifier.size(16.dp)
                                                    )
                                                    Spacer(Modifier.width(8.dp))
                                                }
                                                Text(if (isSyncingState) "Syncing with Cloud…" else "Full Sync (Pull then Push)", fontWeight = FontWeight.SemiBold)
                                            }

                                            // 4. Check for Remote Changes
                                            OutlinedButton(
                                                onClick = {
                                                    scope.launch {
                                                        val available = repository.checkRemoteChanges()
                                                        message = if (available > 0) "$available change(s) available to pull" else "All changes up to date"
                                                    }
                                                },
                                                enabled = !isBusySyncing,
                                                modifier = Modifier.fillMaxWidth(),
                                                shape = RoundedCornerShape(14.dp)
                                            ) {
                                                Icon(
                                                    imageVector = Icons.Default.Sync,
                                                    contentDescription = null,
                                                    modifier = Modifier.size(15.dp)
                                                )
                                                Spacer(Modifier.width(6.dp))
                                                Text("Check Remote Changes")
                                            }
                                        } else {
                                            Button(
                                                onClick = { plans = true },
                                                modifier = Modifier.fillMaxWidth()
                                            ) {
                                                Text("Upgrade to Enable Cloud Sync")
                                            }
                                        }

                                        OutlinedButton(
                                            onClick = {
                                                repository.refreshWebStatus()
                                                message = "Platform health check refreshed."
                                            },
                                            modifier = Modifier.fillMaxWidth()
                                        ) {
                                            Text("Refresh Platform Health")
                                        }
                                    }
                                }
                            }
                        }

                        SettingsSubpage.NOTIFICATIONS -> {
                            item {
                                Surface(
                                    modifier = Modifier.fillMaxWidth(),
                                    shape = RoundedCornerShape(18.dp),
                                    color = LaterboxCard,
                                    border = BorderStroke(1.dp, LaterboxBorder)
                                ) {
                                    Column(
                                        modifier = Modifier.padding(18.dp),
                                        verticalArrangement = Arrangement.spacedBy(14.dp)
                                    ) {
                                        Text(
                                            text = "Notification Preferences",
                                            fontSize = 16.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = LaterboxTextPrimary
                                        )
                                        Text(
                                            text = "LaterBox sends reminders at your scheduled return times (e.g. tomorrow at 9:00 AM) so you can review saved links when ready.",
                                            fontSize = 13.sp,
                                            color = LaterboxTextSecondary
                                        )
                                        NotificationAccess()
                                    }
                                }
                            }
                        }

                        SettingsSubpage.SECURITY -> {
                            item {
                                Surface(
                                    modifier = Modifier.fillMaxWidth(),
                                    shape = RoundedCornerShape(18.dp),
                                    color = LaterboxCard,
                                    border = BorderStroke(1.dp, LaterboxBorder)
                                ) {
                                    Column(
                                        modifier = Modifier.padding(18.dp),
                                        verticalArrangement = Arrangement.spacedBy(14.dp)
                                    ) {
                                        Row(
                                            modifier = Modifier.fillMaxWidth(),
                                            verticalAlignment = Alignment.CenterVertically,
                                            horizontalArrangement = Arrangement.SpaceBetween
                                        ) {
                                            Column(modifier = Modifier.weight(1f)) {
                                                Text(
                                                    text = "App Lock",
                                                    fontWeight = FontWeight.SemiBold,
                                                    fontSize = 15.sp,
                                                    color = LaterboxTextPrimary
                                                )
                                                Text(
                                                    text = "Require biometrics or device PIN to open",
                                                    fontSize = 12.sp,
                                                    color = LaterboxTextSecondary
                                                )
                                            }
                                            Switch(
                                                checked = lock,
                                                onCheckedChange = { enabled ->
                                                    if (!enabled || AppLockService.supported(context)) {
                                                        lock = enabled
                                                        preferences.edit().putBoolean("app_lock", enabled).apply()
                                                    } else {
                                                        message = "Set up a screen lock or biometrics on your device first."
                                                    }
                                                }
                                            )
                                        }

                                        HorizontalDivider(color = LaterboxBorder, thickness = 0.5.dp)

                                        Row(
                                            modifier = Modifier.fillMaxWidth(),
                                            verticalAlignment = Alignment.CenterVertically,
                                            horizontalArrangement = Arrangement.SpaceBetween
                                        ) {
                                            Column(modifier = Modifier.weight(1f)) {
                                                Text(
                                                    text = "Screen Protection",
                                                    fontWeight = FontWeight.SemiBold,
                                                    fontSize = 15.sp,
                                                    color = LaterboxTextPrimary
                                                )
                                                Text(
                                                    text = "Hide screenshots and app previews in task switcher",
                                                    fontSize = 12.sp,
                                                    color = LaterboxTextSecondary
                                                )
                                            }
                                            Switch(
                                                checked = protect,
                                                onCheckedChange = { enabled ->
                                                    protect = enabled
                                                    preferences.edit().putBoolean("screen_protection", enabled).apply()
                                                    val activity = context as? android.app.Activity
                                                    if (enabled) {
                                                        activity?.window?.addFlags(android.view.WindowManager.LayoutParams.FLAG_SECURE)
                                                    } else {
                                                        activity?.window?.clearFlags(android.view.WindowManager.LayoutParams.FLAG_SECURE)
                                                    }
                                                }
                                            )
                                        }
                                    }
                                }
                            }

                            if (account.userId != null) {
                                item {
                                    Surface(
                                        modifier = Modifier.fillMaxWidth(),
                                        shape = RoundedCornerShape(18.dp),
                                        color = LaterboxCard,
                                        border = BorderStroke(1.dp, Color(0xFFEF4444).copy(alpha = 0.25f))
                                    ) {
                                        Column(
                                            modifier = Modifier.padding(18.dp),
                                            verticalArrangement = Arrangement.spacedBy(14.dp)
                                        ) {
                                            Row(
                                                verticalAlignment = Alignment.CenterVertically,
                                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                                            ) {
                                                Icon(
                                                    imageVector = Icons.Default.Warning,
                                                    contentDescription = null,
                                                    tint = Color(0xFFEF4444),
                                                    modifier = Modifier.size(18.dp)
                                                )
                                                Text(
                                                    text = "Danger Zone",
                                                    fontSize = 12.sp,
                                                    fontWeight = FontWeight.Bold,
                                                    color = Color(0xFFEF4444)
                                                )
                                            }

                                            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                                                Text(
                                                    text = "Delete Account & Cloud Data",
                                                    fontWeight = FontWeight.SemiBold,
                                                    fontSize = 15.sp,
                                                    color = LaterboxTextPrimary
                                                )
                                                Text(
                                                    text = "Permanently delete your LaterBox account, cloud sync data, attachments in Cloudflare, and remote vault records. This action cannot be undone.",
                                                    fontSize = 12.sp,
                                                    color = LaterboxTextSecondary,
                                                    lineHeight = 17.sp
                                                )
                                            }

                                            Button(
                                                onClick = { showingDeleteAccountDialog = true },
                                                enabled = !isDeletingAccount,
                                                modifier = Modifier.fillMaxWidth(),
                                                shape = RoundedCornerShape(12.dp),
                                                colors = ButtonDefaults.buttonColors(
                                                    containerColor = Color(0xFFEF4444),
                                                    contentColor = Color.White
                                                )
                                            ) {
                                                if (isDeletingAccount) {
                                                    CircularProgressIndicator(
                                                        modifier = Modifier.size(16.dp),
                                                        strokeWidth = 2.dp,
                                                        color = Color.White
                                                    )
                                                    Spacer(Modifier.width(8.dp))
                                                    Text("Deleting Account…")
                                                } else {
                                                    Icon(
                                                        imageVector = Icons.Default.DeleteForever,
                                                        contentDescription = null,
                                                        modifier = Modifier.size(16.dp)
                                                    )
                                                    Spacer(Modifier.width(8.dp))
                                                    Text("Delete Account")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        SettingsSubpage.STORAGE -> {
                            item {
                                SettingsGroupCard(title = "VAULT STORAGE USAGE") {
                                    SubpageValueRow("Attachment Storage", android.text.format.Formatter.formatFileSize(context, bytes))
                                    HorizontalDivider(color = LaterboxBorder, thickness = 0.5.dp)
                                    SubpageValueRow("Saved Items", items.size.toString())
                                    HorizontalDivider(color = LaterboxBorder, thickness = 0.5.dp)
                                    SubpageValueRow("Recently Deleted", trash.size.toString())
                                }
                            }
                            item {
                                Surface(
                                    modifier = Modifier.fillMaxWidth(),
                                    shape = RoundedCornerShape(18.dp),
                                    color = LaterboxCard,
                                    border = BorderStroke(1.dp, LaterboxBorder)
                                ) {
                                    Column(
                                        modifier = Modifier.padding(18.dp),
                                        verticalArrangement = Arrangement.spacedBy(12.dp)
                                    ) {
                                        Text(
                                            text = "Backup & Vault Tools",
                                            fontSize = 14.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = LaterboxTextPrimary
                                        )
                                        Button(
                                            onClick = {
                                                task {
                                                    val file = BackupService.export(context)
                                                    val uri = FileProvider.getUriForFile(context, context.packageName + ".files", file)
                                                    open(
                                                        Intent.createChooser(
                                                            Intent(Intent.ACTION_SEND).setType("application/zip").putExtra(Intent.EXTRA_STREAM, uri).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION),
                                                            "Export LaterBox backup"
                                                        )
                                                    )
                                                }
                                            },
                                            enabled = !busy,
                                            modifier = Modifier.fillMaxWidth()
                                        ) {
                                            Text("Export Vault Backup (ZIP)")
                                        }

                                        OutlinedButton(
                                            onClick = {
                                                importer.launch(arrayOf("application/zip", "application/octet-stream"))
                                            },
                                            enabled = !busy,
                                            modifier = Modifier.fillMaxWidth()
                                        ) {
                                            Text("Import Vault Backup")
                                        }

                                        OutlinedButton(
                                            onClick = { clearing = true },
                                            enabled = !busy,
                                            modifier = Modifier.fillMaxWidth()
                                        ) {
                                            Text("Empty Trash Permanently", color = Color(0xFFEF4444))
                                        }
                                    }
                                }
                            }
                        }

                        SettingsSubpage.AI_MODELS -> {
                            item {
                                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                                    Row(
                                        verticalAlignment = Alignment.CenterVertically,
                                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                                    ) {
                                        Icon(
                                            imageVector = Icons.Default.AutoAwesome,
                                            contentDescription = null,
                                            tint = LaterboxTextPrimary,
                                            modifier = Modifier.size(20.dp)
                                        )
                                        Text(
                                            text = "Intelligence Engine",
                                            fontSize = 18.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = LaterboxTextPrimary
                                        )
                                    }
                                    Text(
                                        text = "LaterBox currently uses an offline response assistant for capture and search.",
                                        fontSize = 13.sp,
                                        color = LaterboxTextSecondary
                                    )
                                }
                            }

                            item {
                                Surface(
                                    modifier = Modifier.fillMaxWidth(),
                                    shape = RoundedCornerShape(18.dp),
                                    color = LaterboxCard,
                                    border = BorderStroke(1.dp, LaterboxBorder)
                                ) {
                                    Row(
                                        modifier = Modifier.padding(16.dp),
                                        verticalAlignment = Alignment.CenterVertically,
                                        horizontalArrangement = Arrangement.spacedBy(14.dp)
                                    ) {
                                        Box(
                                            modifier = Modifier
                                                .size(42.dp)
                                                .background(LaterboxAccent, CircleShape),
                                            contentAlignment = Alignment.Center
                                        ) {
                                            Icon(
                                                imageVector = Icons.Default.AutoAwesome,
                                                contentDescription = null,
                                                tint = LaterboxDarkSurface,
                                                modifier = Modifier.size(20.dp)
                                            )
                                        }

                                        Column(
                                            modifier = Modifier.weight(1f),
                                            verticalArrangement = Arrangement.spacedBy(2.dp)
                                        ) {
                                            Text(
                                                text = "Local responses",
                                                fontSize = 15.sp,
                                                fontWeight = FontWeight.Bold,
                                                color = LaterboxTextPrimary
                                            )
                                            Text(
                                                text = "Available now · works offline",
                                                fontSize = 12.sp,
                                                color = LaterboxTextSecondary
                                            )
                                        }

                                        Surface(
                                            shape = CircleShape,
                                            color = LaterboxAccent
                                        ) {
                                            Text(
                                                text = "Active",
                                                fontSize = 11.sp,
                                                fontWeight = FontWeight.Bold,
                                                color = LaterboxDarkSurface,
                                                modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp)
                                            )
                                        }
                                    }
                                }
                            }

                            item {
                                Surface(
                                    modifier = Modifier.fillMaxWidth(),
                                    shape = RoundedCornerShape(18.dp),
                                    color = LaterboxCard,
                                    border = BorderStroke(1.dp, LaterboxBorder)
                                ) {
                                    Column(
                                        modifier = Modifier.padding(16.dp),
                                        verticalArrangement = Arrangement.spacedBy(8.dp)
                                    ) {
                                        Row(
                                            verticalAlignment = Alignment.CenterVertically,
                                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                                        ) {
                                            Icon(
                                                imageVector = Icons.Default.Schedule,
                                                contentDescription = null,
                                                tint = LaterboxTextSecondary,
                                                modifier = Modifier.size(18.dp)
                                            )
                                            Text(
                                                text = "AI providers",
                                                fontSize = 15.sp,
                                                fontWeight = FontWeight.Bold,
                                                color = LaterboxTextPrimary
                                            )
                                        }
                                        Text(
                                            text = "Cloud and custom AI providers are coming soon. Provider switching and API-key connections are disabled until they are implemented.",
                                            fontSize = 13.sp,
                                            color = LaterboxTextSecondary,
                                            lineHeight = 18.sp
                                        )
                                    }
                                }
                            }

                            item {
                                Surface(
                                    modifier = Modifier.fillMaxWidth(),
                                    shape = RoundedCornerShape(18.dp),
                                    color = LaterboxCard,
                                    border = BorderStroke(1.dp, LaterboxBorder)
                                ) {
                                    Row(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .padding(16.dp),
                                        verticalAlignment = Alignment.CenterVertically,
                                        horizontalArrangement = Arrangement.SpaceBetween
                                    ) {
                                        Column(modifier = Modifier.weight(1f)) {
                                            Text(
                                                text = "Search refinement",
                                                fontSize = 15.sp,
                                                fontWeight = FontWeight.Bold,
                                                color = LaterboxTextPrimary
                                            )
                                            Text(
                                                text = "Use local assistant to refine search queries",
                                                fontSize = 12.sp,
                                                color = LaterboxTextSecondary
                                            )
                                        }

                                        Switch(
                                            checked = searchRefine,
                                            onCheckedChange = { enabled ->
                                                searchRefine = enabled
                                                preferences.edit().putBoolean("search_refine", enabled).apply()
                                            }
                                        )
                                    }
                                }
                            }
                        }

                        SettingsSubpage.UPDATES -> {
                            item {
                                SettingsGroupCard(title = "APP INFORMATION") {
                                    SubpageValueRow("Application", "LaterBox for Android")
                                    HorizontalDivider(color = LaterboxBorder, thickness = 0.5.dp)
                                    SubpageValueRow("Version", BuildConfig.VERSION_NAME)
                                    HorizontalDivider(color = LaterboxBorder, thickness = 0.5.dp)
                                    SubpageValueRow("Build Code", BuildConfig.VERSION_CODE.toString())
                                    HorizontalDivider(color = LaterboxBorder, thickness = 0.5.dp)
                                    SubpageValueRow("Channel", "Stable")
                                }
                            }
                            item {
                                Surface(
                                    modifier = Modifier.fillMaxWidth(),
                                    shape = RoundedCornerShape(18.dp),
                                    color = LaterboxCard,
                                    border = BorderStroke(1.dp, LaterboxBorder)
                                ) {
                                    Column(
                                        modifier = Modifier.padding(18.dp),
                                        verticalArrangement = Arrangement.spacedBy(12.dp)
                                    ) {
                                        Button(
                                            onClick = { message = "You are using the latest version of LaterBox." },
                                            modifier = Modifier.fillMaxWidth()
                                        ) {
                                            Text("Check for Updates")
                                        }
                                        OutlinedButton(
                                            onClick = { open(Intent(Intent.ACTION_VIEW, Uri.parse("https://laterbox.dev/privacy"))) },
                                            modifier = Modifier.fillMaxWidth()
                                        ) {
                                            Text("Privacy Policy")
                                        }
                                        OutlinedButton(
                                            onClick = { open(Intent(Intent.ACTION_VIEW, Uri.parse("https://laterbox.dev/terms"))) },
                                            modifier = Modifier.fillMaxWidth()
                                        ) {
                                            Text("Terms of Service")
                                        }
                                    }
                                }
                            }
                        }
                        SettingsSubpage.SERVICE_STATUS -> {}
                        null -> {}
                    }
                }
                }
            }
        }
    }

    if (signOut) {
        AlertDialog(
            onDismissRequest = { if (!busy) signOut = false },
            title = { Text("Sign out?") },
            text = { Text("Your local captures will be preserved on this device.") },
            confirmButton = {
                TextButton(
                    enabled = !busy,
                    onClick = {
                        task {
                            AccountService.signOut()
                            signOut = false
                            message = "Signed out. Local captures are preserved."
                        }
                    }
                ) {
                    Text("Sign Out", color = Color(0xFFEF4444))
                }
            },
            dismissButton = {
                TextButton(onClick = { signOut = false }) { Text("Cancel") }
            }
        )
    }

    if (showingDeleteAccountDialog) {
        AlertDialog(
            onDismissRequest = { if (!isDeletingAccount) showingDeleteAccountDialog = false },
            title = {
                Text(
                    text = "Delete Account & Cloud Data?",
                    fontWeight = FontWeight.Bold,
                    color = Color(0xFFEF4444)
                )
            },
            text = {
                Text(
                    text = "This permanently deletes your account, cloud records, Cloudflare attachments, and local account data. This cannot be undone.",
                    fontSize = 13.sp,
                    color = LaterboxTextSecondary,
                    lineHeight = 18.sp
                )
            },
            confirmButton = {
                Button(
                    onClick = {
                        isDeletingAccount = true
                        scope.launch {
                            try {
                                AccountService.deleteAccount(context)
                                showingDeleteAccountDialog = false
                                message = "Account and all cloud attachments have been permanently deleted."
                                activeSubpage = null
                            } catch (e: Exception) {
                                message = e.message ?: "Failed to delete account. Please try again."
                            } finally {
                                isDeletingAccount = false
                            }
                        }
                    },
                    enabled = !isDeletingAccount,
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color(0xFFEF4444),
                        contentColor = Color.White
                    )
                ) {
                    if (isDeletingAccount) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(14.dp),
                            strokeWidth = 2.dp,
                            color = Color.White
                        )
                        Spacer(Modifier.width(6.dp))
                    }
                    Text("Delete Everything")
                }
            },
            dismissButton = {
                TextButton(
                    onClick = { showingDeleteAccountDialog = false },
                    enabled = !isDeletingAccount
                ) {
                    Text("Cancel")
                }
            }
        )
    }

    if (clearing) {
        AlertDialog(
            onDismissRequest = { if (!busy) clearing = false },
            title = { Text("Empty trash permanently?") },
            text = { Text("Deleted captures and local files will be removed.") },
            confirmButton = {
                TextButton(
                    enabled = !busy,
                    onClick = {
                        task {
                            BackupService.clearTrash(context)
                            clearing = false
                            storageRefresh++
                            message = "Trash cleanup completed."
                        }
                    }
                ) {
                    Text("Empty Trash", color = Color(0xFFEF4444))
                }
            },
            dismissButton = {
                TextButton(onClick = { clearing = false }) { Text("Cancel") }
            }
        )
    }

    if (plans) PlansSheet { plans = false }
    if (supportSheet) SupportRequestSheet { supportSheet = false }
}

@Composable
private fun SettingsGroupCard(
    title: String,
    content: @Composable ColumnScope.() -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(
            text = title,
            fontSize = 10.sp,
            fontWeight = FontWeight.Black,
            letterSpacing = 1.sp,
            color = Color(0xFF9E9B92),
            modifier = Modifier.padding(horizontal = 14.dp)
        )
        Surface(
            shape = RoundedCornerShape(18.dp),
            color = LaterboxCard,
            border = BorderStroke(1.dp, LaterboxBorder),
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(content = content)
        }
    }
}

@Composable
private fun SettingsLinkRow(
    icon: ImageVector,
    title: String,
    subtitle: String? = null,
    badge: String? = null,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        Box(
            modifier = Modifier
                .size(30.dp)
                .background(LaterboxAccent, CircleShape),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = LaterboxTextPrimary,
                modifier = Modifier.size(16.dp)
            )
        }

        Column(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.Center
        ) {
            Text(
                text = title,
                fontSize = 13.sp,
                fontWeight = FontWeight.SemiBold,
                color = LaterboxTextPrimary
            )
        }

        badge?.let {
            Text(
                text = it,
                fontSize = 13.sp,
                fontWeight = FontWeight.Medium,
                color = LaterboxTextSecondary
            )
        }

        Icon(
            imageVector = Icons.Default.ChevronRight,
            contentDescription = null,
            tint = LaterboxTextSecondary.copy(alpha = 0.5f),
            modifier = Modifier.size(16.dp)
        )
    }
}

@Composable
private fun SubpageValueRow(label: String, value: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 14.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(label, fontSize = 14.sp, color = LaterboxTextSecondary)
        Text(
            value,
            fontSize = 14.sp,
            fontWeight = FontWeight.SemiBold,
            color = LaterboxTextPrimary,
            textAlign = TextAlign.End,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )
    }
}
