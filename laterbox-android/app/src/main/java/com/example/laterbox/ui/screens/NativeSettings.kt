package com.example.laterbox.ui.screens

import android.Manifest
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.FileProvider
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.example.laterbox.BuildConfig
import com.example.laterbox.data.DataRepository
import com.example.laterbox.services.*
import com.example.laterbox.ui.capture.Choice
import com.example.laterbox.ui.capture.DialogContent
import com.example.laterbox.theme.LaterboxBg
import kotlinx.coroutines.launch
import java.io.File

@Composable
fun NativeSettings(repository: DataRepository, onAuth: () -> Unit, onTrash: () -> Unit) {
    val context = LocalContext.current; val scope = rememberCoroutineScope()
    val account by AccountService.state.collectAsState(); val status by repository.webStatus.collectAsState()
    val preferences = remember { context.getSharedPreferences("laterbox", 0) }
    var lock by remember { mutableStateOf(preferences.getBoolean("app_lock", false)) }
    var protect by remember { mutableStateOf(preferences.getBoolean("screen_protection", false)) }
    var message by remember { mutableStateOf<String?>(null) }; var clearing by remember { mutableStateOf(false) }
    var plans by remember { mutableStateOf(false) }
    var aiSettings by remember { mutableStateOf(false) }
    var bytes by remember { mutableLongStateOf(File(context.filesDir, "captures").walkTopDown().filter { it.isFile }.sumOf { it.length() }) }
    val permissions = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted -> message = if (granted) "Return notifications enabled" else "Notifications are off. Returns still appear in your inbox." }
    val importer = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri -> if (uri != null) scope.launch { try { val count = BackupService.import(context, uri); message = "Imported $count captures"; repository.syncNow() } catch (failure: Exception) { message = failure.message } } }
    LazyColumn(Modifier.fillMaxSize().background(LaterboxBg), contentPadding = PaddingValues(20.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        item { Text("Settings", style = MaterialTheme.typography.headlineLarge) }
        item { Choice(account.email ?: "Guest mode", if (account.pro) "LaterBox Pro active" else "Free local vault") { if (account.userId == null) onAuth() } }
        item { if (account.userId != null) TextButton(onClick = { scope.launch { AccountService.signOut(); message = "Signed out. Your local captures are preserved." } }) { Text("Sign out") } }
        item { Text("Plans & cloud sync", style = MaterialTheme.typography.titleLarge) }
        item { Choice(if (account.pro) "Manage LaterBox Pro" else "View Pro plans", "Cloud sync and AI Inbox Organizer") { plans = true } }
        item { Choice("Restore purchases", "Verify existing access for this account") { plans = true } }
        item { Choice("Sync now", if (account.pro) "Verified Pro account" else "Pro is required") { if (account.pro) { repository.syncNow(); message = "Sync queued" } else plans = true } }
        item { Choice("Platform status", status.label) { repository.refreshWebStatus() } }
        item { Text("Later AI", style = MaterialTheme.typography.titleLarge) }
        item { Choice("On-device Gemini Nano", "Free where supported. Guided capture is always available.") { message = "Open Later AI to check availability or download the local model. Cloud AI is disabled by default." } }
        item { Choice("Configure AI models & keys", "On-device and Pro custom providers") { aiSettings = true } }
        if (RemoteAIService.ENABLED && account.pro) item {
            var fallback by remember { mutableStateOf(preferences.getBoolean("gemini_fallback", false)) }
            Row { Text("Use Pro Gemini after local failures", Modifier.weight(1f)); Switch(fallback, { fallback = it; preferences.edit().putBoolean("gemini_fallback", it).apply() }) }
        }
        item { Text("Privacy & alerts", style = MaterialTheme.typography.titleLarge) }
        item { Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) { Text("Lock with biometrics or device PIN"); Switch(lock, { enabled -> if (!enabled || AppLockService.supported(context)) { lock = enabled; preferences.edit().putBoolean("app_lock", enabled).apply() } else message = "Set up a screen lock or biometrics first." }) } }
        item { Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) { Text("Hide screenshots and previews"); Switch(protect, { protect = it; preferences.edit().putBoolean("screen_protection", it).apply(); val activity = context as? android.app.Activity; if (it) activity?.window?.addFlags(android.view.WindowManager.LayoutParams.FLAG_SECURE) else activity?.window?.clearFlags(android.view.WindowManager.LayoutParams.FLAG_SECURE) }) } }
        item { Choice("Return notifications", "Enable alerts when saved items are due") { if (Build.VERSION.SDK_INT >= 33) permissions.launch(Manifest.permission.POST_NOTIFICATIONS) else message = "Return notifications are available in Android notification settings." } }
        item { Text("Storage & backups", style = MaterialTheme.typography.titleLarge) }
        item { Text("Attachments: ${bytes / 1048576} MB · Items remain available offline") }
        item { Choice("Export vault backup", "Includes notes, metadata, and attachments") { scope.launch { try { val file = BackupService.export(context); val uri = FileProvider.getUriForFile(context, context.packageName + ".files", file); context.startActivity(Intent.createChooser(Intent(Intent.ACTION_SEND).setType("application/zip").putExtra(Intent.EXTRA_STREAM, uri).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION), "Export LaterBox backup")) } catch (failure: Exception) { message = failure.message } } } }
        item { Choice("Import vault backup", "Keep existing items; restore missing captures") { importer.launch(arrayOf("application/zip", "application/octet-stream")) } }
        item { Choice("Trash", "Restore deleted items") { onTrash() } }
        item { Choice("Empty trash", "Permanently remove deleted items and unreferenced files") { clearing = true } }
        item { Text("LaterBox ${BuildConfig.VERSION_NAME} (${BuildConfig.VERSION_CODE}) · Native Android", style = MaterialTheme.typography.bodySmall) }
        item { Choice("Privacy policy") { context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://laterbox.dev/privacy"))) } }
        item { Choice("Terms of service") { context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://laterbox.dev/terms"))) } }
        message?.let { item { Text(it) } }
    }
    if (clearing) DialogContent("Empty trash permanently?", { clearing = false }) {
        Text("This removes deleted captures and their local files. Export a backup first if you need them.")
        Button(onClick = { scope.launch { BackupService.clearTrash(context); clearing = false; bytes = File(context.filesDir, "captures").walkTopDown().filter { it.isFile }.sumOf { it.length() } } }) { Text("Empty trash") }
    }
    if (plans) PlansSheet { plans = false }
    if (aiSettings) AISettingsSheet { aiSettings = false }
}
