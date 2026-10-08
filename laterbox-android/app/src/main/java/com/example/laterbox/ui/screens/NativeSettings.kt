package com.example.laterbox.ui.screens

import android.Manifest
import android.content.Intent
import android.net.Uri
import android.os.Build
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
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
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
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import com.example.laterbox.BuildConfig
import com.example.laterbox.R
import com.example.laterbox.data.DataRepository
import com.example.laterbox.services.*
import com.example.laterbox.theme.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File

@Composable
fun NativeSettings(repository: DataRepository, onAuth: () -> Unit, onTrash: () -> Unit) {
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
    var aiSettings by remember { mutableStateOf(false) }
    var supportSheet by remember { mutableStateOf(false) }
    var busy by remember { mutableStateOf(false) }
    var bytes by remember { mutableLongStateOf(0) }
    var storageRefresh by remember { mutableIntStateOf(0) }
    LaunchedEffect(items.size, trash.size, storageRefresh) {
        bytes = withContext(Dispatchers.IO) { File(context.filesDir, "captures").walkTopDown().filter { it.isFile }.sumOf { it.length() } }
    }
    fun task(block: suspend () -> Unit) {
        if (busy) return
        scope.launch { busy = true; try { block() } catch (cancelled: kotlinx.coroutines.CancellationException) { throw cancelled } catch (failure: Exception) { message = failure.message ?: "Unable to complete this action. Please try again." } finally { busy = false } }
    }
    fun open(intent: Intent) { runCatching { context.startActivity(intent) }.onFailure { message = "No app is available to open this page." } }
    val importer = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri -> if (uri != null) task {
        val count = BackupService.import(context, uri); message = "Imported $count captures"; repository.syncNow(); storageRefresh++
    } }
    val sync = when { !account.pro -> "Local only"; items.any { it.syncStatus == "failed" } -> "Needs attention"; items.any { it.syncStatus == "pending" } -> "Pending sync"; else -> "Synced" }
    val secure = remember { SecureSettings(context) }
    val nanoStatus by NanoAIService.status.collectAsState()
    LaunchedEffect(Unit) { NanoAIService.refresh() }
    val aiProvider = remember(aiSettings, account.pro) { secure.provider }
    val aiModel = remember(aiSettings, account.pro) { if (!account.pro) "Gemini Nano (when ready), local fallback" else secure.model }
    LazyColumn(Modifier.fillMaxSize().background(LaterboxBg), contentPadding = PaddingValues(20.dp), verticalArrangement = Arrangement.spacedBy(20.dp)) {
        item {
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Image(painterResource(R.drawable.laterbox_icon_green), "LaterBox", Modifier.size(28.dp).clip(RoundedCornerShape(7.dp)))
                Text("Settings", Modifier.weight(1f).padding(start = 8.dp), fontSize = 24.sp, fontWeight = FontWeight.Bold, color = LaterboxTextPrimary)
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(5.dp)) {
                    Box(Modifier.size(7.dp).background(if (sync == "Synced") LaterboxEmerald else LaterboxAmber, CircleShape))
                    Text(sync, fontSize = 10.sp, color = LaterboxTextSecondary)
                }
            }
        }
        message?.let { text -> item {
            Surface(color = LaterboxAccent.copy(alpha = 0.4f), shape = RoundedCornerShape(14.dp)) {
                Row(Modifier.padding(start = 14.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text(text, Modifier.weight(1f), fontSize = 13.sp, color = LaterboxTextPrimary)
                    IconButton(onClick = { message = null }) { Icon(Icons.Default.Close, "Dismiss message", Modifier.size(18.dp)) }
                }
            }
        } }
        item {
            Column(Modifier.fillMaxWidth().padding(vertical = 8.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Box(Modifier.size(72.dp).background(LaterboxAccent, CircleShape), contentAlignment = Alignment.Center) { Icon(Icons.Default.Person, null, Modifier.size(34.dp), tint = LaterboxTextPrimary) }
                Text(account.displayName?.takeIf { it.isNotBlank() } ?: account.email ?: "Guest Mode", fontSize = 20.sp, fontWeight = FontWeight.Bold, color = LaterboxTextPrimary, textAlign = TextAlign.Center)
                account.email?.let { Text(it, fontSize = 13.sp, color = LaterboxTextSecondary, textAlign = TextAlign.Center) }
                Text(if (account.pro) "LaterBox Pro Active" else if (account.userId == null) "Local saving active · Sign in for cloud sync" else "Free local vault", fontSize = 13.sp, color = LaterboxTextSecondary, textAlign = TextAlign.Center)
                if (account.userId == null) Button(onClick = onAuth) { Text("Sign In") }
                else TextButton(onClick = { signOut = true }, enabled = !busy) { Text("Sign Out", color = LaterboxTextSecondary) }
            }
        }
        item {
            SettingsGroup("YOUR PLAN", Icons.Default.WorkspacePremium) {
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                    Column(Modifier.weight(1f)) {
                        Text(if (account.pro) "LaterBox Pro" else "LaterBox Local", fontSize = 19.sp, fontWeight = FontWeight.Bold, color = LaterboxTextPrimary)
                        Text(if (account.pro) "Connected features unlocked" else "Offline storage on this device", fontSize = 12.sp, color = LaterboxTextSecondary)
                    }
                    Surface(color = LaterboxAccent, shape = RoundedCornerShape(50)) { Text(if (account.pro) "Active" else "Free Forever", Modifier.padding(horizontal = 10.dp, vertical = 5.dp), fontSize = 10.sp, fontWeight = FontWeight.Bold) }
                }
                Text(if (account.pro) "Cloud sync, connected extensions, and AI organization are available with your plan." else "Save, read, organize, and export your items offline. Upgrade for cloud sync and connected features.", fontSize = 13.sp, color = LaterboxTextSecondary)
                Button(onClick = { plans = true }, modifier = Modifier.fillMaxWidth()) { Text(if (account.pro) "View Plans & Subscriptions" else "Get Pro to Sync") }
                SettingsAction(Icons.Default.Refresh, "Refresh subscription", "Check Pro access purchased on LaterBox Web") {
                    scope.launch {
                        try {
                            AccountService.refresh()
                            repository.syncNow()
                            message = if (AccountService.state.value.pro) "Pro is active. Cloud sync is enabled." else "No active Pro access. Sign in with your web subscription account."
                        } catch (_: Exception) { message = "Could not refresh subscription. Please try again." }
                    }
                }
            }
        }
        item {
            SettingsGroup("CLOUD SYNC & DIAGNOSTICS", Icons.Default.CloudSync) {
                SettingsValue("Sync status", sync)
                SettingsValue("Last updated", items.mapNotNull { it.lastSyncedAt }.maxOrNull()?.let { stamp -> runCatching { java.time.Instant.parse(stamp).atZone(java.time.ZoneId.systemDefault()).format(java.time.format.DateTimeFormatter.ofPattern("MMM d · HH:mm")) }.getOrDefault(stamp) } ?: "Not synced yet")
                SettingsAction(Icons.Default.Public, "LaterBox Web Platform", status.label) { repository.refreshWebStatus(); message = "Refreshing platform status…" }
                SettingsAction(Icons.Default.Sync, if (account.pro) "Trigger Sync Now" else "Get Pro to Enable Cloud Sync", if (account.pro) "Sync saved items across your devices" else "Your local vault stays available offline") {
                    if (account.pro) { repository.syncNow(); message = "Sync queued" } else plans = true
                }
            }
        }
        item {
            SettingsGroup("LATER AI & INTELLIGENCE", Icons.Default.AutoAwesome) {
                SettingsValue("Active engine", if (!account.pro) nanoStatus else aiProvider.replaceFirstChar { it.uppercase() })
                SettingsValue("Selected model", aiModel)
                Text(if (account.pro) "Ask questions, enrich captures, and organize saved content using your configured AI provider." else "Guided capture and keyword search are available locally. Pro adds AI answers and organization.", fontSize = 12.sp, color = LaterboxTextSecondary)
                SettingsAction(Icons.Default.Tune, "Configure AI Models & Keys", "Model selection and encrypted custom keys") { aiSettings = true }
                if (RemoteAIService.ENABLED && account.pro) SettingsToggle("Pro Gemini fallback", "Use cloud AI after local failures", fallback) { enabled ->
                    fallback = enabled; preferences.edit().putBoolean("gemini_fallback", enabled).apply()
                }
            }
        }
        item {
            SettingsGroup("NOTIFICATIONS & ALERTS", Icons.Default.Notifications) {
                NotificationAccess()
            }
        }
        item {
            SettingsGroup("SECURITY & PRIVACY", Icons.Default.Lock) {
                SettingsToggle("App Lock", "Require biometrics or device PIN", lock) { enabled ->
                    if (!enabled || AppLockService.supported(context)) { lock = enabled; preferences.edit().putBoolean("app_lock", enabled).apply() }
                    else message = "Set up a screen lock or biometrics first."
                }
                HorizontalDivider(color = LaterboxBorder)
                SettingsToggle("Screen Protection", "Hide screenshots and app previews", protect) { enabled ->
                    protect = enabled; preferences.edit().putBoolean("screen_protection", enabled).apply()
                    val activity = context as? android.app.Activity
                    if (enabled) activity?.window?.addFlags(android.view.WindowManager.LayoutParams.FLAG_SECURE) else activity?.window?.clearFlags(android.view.WindowManager.LayoutParams.FLAG_SECURE)
                }
            }
        }
        item {
            SettingsGroup("LOCAL STORAGE & VAULT", Icons.Default.Storage) {
                SettingsValue("Attachment storage", android.text.format.Formatter.formatFileSize(context, bytes))
                SettingsValue("Saved items", items.size.toString())
                SettingsValue("Recently deleted", trash.size.toString())
                Text("Your saved items remain available offline. Backups include notes, metadata, and attachments.", fontSize = 12.sp, color = LaterboxTextSecondary)
                SettingsAction(Icons.Default.UploadFile, "Export Vault Backup", "Share a backup of your vault", !busy) { task {
                    val file = BackupService.export(context); val uri = FileProvider.getUriForFile(context, context.packageName + ".files", file)
                    open(Intent.createChooser(Intent(Intent.ACTION_SEND).setType("application/zip").putExtra(Intent.EXTRA_STREAM, uri).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION), "Export LaterBox backup"))
                } }
                SettingsAction(Icons.Default.Download, "Import Vault Backup", "Keep existing items and restore missing captures", !busy) { importer.launch(arrayOf("application/zip", "application/octet-stream")) }
                SettingsAction(Icons.Default.DeleteOutline, "Recently Deleted", "Restore items from Trash") { onTrash() }
                SettingsAction(Icons.Default.DeleteForever, "Empty Trash", "Permanently remove deleted local captures", !busy) { clearing = true }
                if (busy) LinearProgressIndicator(Modifier.fillMaxWidth())
            }
        }
        item {
            SettingsGroup("HELP & FEEDBACK", Icons.Default.SupportAgent) {
                SettingsAction(Icons.Default.QuestionAnswer, "Help & Report a Problem", "Contact us for issues, questions, or feedback") { supportSheet = true }
            }
        }
        item {
            SettingsGroup("ABOUT LATERBOX", Icons.Default.Info) {
                SettingsAction(Icons.Default.PrivacyTip, "Privacy Policy") { open(Intent(Intent.ACTION_VIEW, Uri.parse("https://laterbox.dev/privacy"))) }
                SettingsAction(Icons.Default.Description, "Terms of Service") { open(Intent(Intent.ACTION_VIEW, Uri.parse("https://laterbox.dev/terms"))) }
            }
        }
        item {
            Column(Modifier.fillMaxWidth().padding(bottom = 16.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(5.dp)) {
                Text("LaterBox for Android", fontSize = 12.sp, fontWeight = FontWeight.SemiBold, color = LaterboxTextSecondary)
                Text("Version ${BuildConfig.VERSION_NAME} (${BuildConfig.VERSION_CODE})", fontSize = 11.sp, color = LaterboxTextSecondary)
            }
        }
    }
    if (signOut) AlertDialog(onDismissRequest = { if (!busy) signOut = false }, title = { Text("Sign out?") }, text = { Text("Your local captures will be kept on this device.") }, confirmButton = { TextButton(enabled = !busy, onClick = { task { AccountService.signOut(); signOut = false; message = "Signed out. Local captures are preserved." } }) { Text("Sign Out") } }, dismissButton = { TextButton(onClick = { signOut = false }) { Text("Cancel") } })
    if (clearing) AlertDialog(onDismissRequest = { if (!busy) clearing = false }, title = { Text("Empty trash permanently?") }, text = { Text("Deleted local captures and unused attachments will be removed. Export a backup first if you need them.") }, confirmButton = { TextButton(enabled = !busy, onClick = { task { BackupService.clearTrash(context); clearing = false; storageRefresh++; message = "Trash cleanup completed." } }) { Text("Empty Trash") } }, dismissButton = { TextButton(onClick = { clearing = false }) { Text("Cancel") } })
    if (plans) PlansSheet { plans = false }
    if (aiSettings) AISettingsSheet { aiSettings = false }
    if (supportSheet) SupportRequestSheet { supportSheet = false }
}

@Composable
private fun SettingsGroup(title: String, icon: ImageVector, content: @Composable ColumnScope.() -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Text(title, fontSize = 11.sp, fontWeight = FontWeight.Bold, letterSpacing = 0.6.sp, color = LaterboxTextSecondary)
        Surface(shape = RoundedCornerShape(20.dp), color = LaterboxCard, border = BorderStroke(1.dp, LaterboxBorder), modifier = Modifier.fillMaxWidth()) {
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Box(Modifier.size(32.dp).background(LaterboxAccent, RoundedCornerShape(9.dp)), contentAlignment = Alignment.Center) { Icon(icon, null, Modifier.size(18.dp), tint = LaterboxTextPrimary) }
                content()
            }
        }
    }
}

@Composable
private fun SettingsAction(icon: ImageVector, title: String, subtitle: String? = null, enabled: Boolean = true, onClick: () -> Unit) {
    Row(Modifier.fillMaxWidth().clip(RoundedCornerShape(10.dp)).clickable(enabled = enabled, onClick = onClick).padding(vertical = 10.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        Icon(icon, null, Modifier.size(20.dp), tint = LaterboxTextSecondary)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Text(title, fontSize = 14.sp, fontWeight = FontWeight.SemiBold, color = LaterboxTextPrimary.copy(alpha = if (enabled) 1f else 0.5f))
            subtitle?.let { Text(it, fontSize = 11.sp, color = LaterboxTextSecondary) }
        }
        Icon(Icons.Default.ChevronRight, null, Modifier.size(16.dp), tint = LaterboxTextSecondary)
    }
}

@Composable
private fun SettingsValue(label: String, value: String) {
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.CenterVertically) {
        Text(label, Modifier.weight(1f), fontSize = 13.sp, color = LaterboxTextSecondary)
        Text(value, Modifier.weight(1f), fontSize = 13.sp, fontWeight = FontWeight.SemiBold, color = LaterboxTextPrimary, textAlign = TextAlign.End, maxLines = 2, overflow = TextOverflow.Ellipsis)
    }
}

@Composable
private fun SettingsToggle(title: String, subtitle: String, checked: Boolean, onChange: (Boolean) -> Unit) {
    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(title, fontWeight = FontWeight.SemiBold, fontSize = 14.sp, color = LaterboxTextPrimary)
            Text(subtitle, fontSize = 11.sp, color = LaterboxTextSecondary)
        }
        Switch(checked = checked, onCheckedChange = onChange)
    }
}
