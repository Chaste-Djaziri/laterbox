package com.example.laterbox.ui.screens

import android.Manifest
import android.app.Activity
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import com.example.laterbox.MainActivity
import com.example.laterbox.R
import com.example.laterbox.services.ReturnsService

@Composable
internal fun NotificationAccess() {
    val context = LocalContext.current
    val activity = context as? Activity
    val preferences = remember { context.getSharedPreferences("laterbox", 0) }
    val manager = remember { context.getSystemService(NotificationManager::class.java) }
    var allowed by remember { mutableStateOf(NotificationManagerCompat.from(context).areNotificationsEnabled()) }
    var channelAllowed by remember { mutableStateOf(true) }
    var requested by remember { mutableStateOf(preferences.getBoolean("notification_permission_requested", false)) }
    var rationale by remember { mutableStateOf(false) }
    var requesting by remember { mutableStateOf(false) }
    var message by remember { mutableStateOf<String?>(null) }
    fun refresh() {
        allowed = NotificationManagerCompat.from(context).areNotificationsEnabled()
        channelAllowed = manager.getNotificationChannel(ReturnsService.CHANNEL_ID)?.importance != NotificationManager.IMPORTANCE_NONE
    }
    val lifecycle = LocalLifecycleOwner.current.lifecycle
    DisposableEffect(lifecycle) {
        ReturnsService.ensureChannel(context)
        refresh()
        val observer = LifecycleEventObserver { _, event -> if (event == Lifecycle.Event.ON_RESUME) refresh() }
        lifecycle.addObserver(observer)
        onDispose { lifecycle.removeObserver(observer) }
    }
    fun openSettings(channel: Boolean = false) {
        val intent = Intent(if (channel) Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS else Settings.ACTION_APP_NOTIFICATION_SETTINGS)
            .putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
        if (channel) intent.putExtra(Settings.EXTRA_CHANNEL_ID, ReturnsService.CHANNEL_ID)
        runCatching { context.startActivity(intent) }.onFailure { message = "Open Android Settings → Apps → LaterBox → Notifications to allow alerts." }
    }
    val permission = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        requesting = false
        requested = true
        preferences.edit().putBoolean("notification_permission_requested", true).apply()
        refresh()
        message = if (granted) "Notifications allowed. You can test a reminder below." else "Notifications remain off. Your scheduled items still return to the Inbox."
    }
    fun request() {
        requesting = true
        permission.launch(Manifest.permission.POST_NOTIFICATIONS)
    }
    val permissionGranted = Build.VERSION.SDK_INT < 33 || ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
    val needsRationale = Build.VERSION.SDK_INT >= 33 && activity != null && ActivityCompat.shouldShowRequestPermissionRationale(activity, Manifest.permission.POST_NOTIFICATIONS)
    val settingsRequired = Build.VERSION.SDK_INT < 33 || permissionGranted || requested && !needsRationale || activity == null
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text(if (!allowed) "Notifications are off" else if (!channelAllowed) "Reminder alerts are off" else "Notifications are enabled", style = MaterialTheme.typography.titleMedium)
        Text("Allow LaterBox to notify you when scheduled items return to your Inbox. This is available for guest, free, and Pro accounts.", style = MaterialTheme.typography.bodyMedium)
        Button(onClick = {
            when {
                allowed && !channelAllowed -> openSettings(true)
                allowed || settingsRequired -> openSettings()
                needsRationale -> rationale = true
                else -> request()
            }
        }, enabled = !requesting, modifier = Modifier.fillMaxWidth()) {
            Icon(Icons.Default.NotificationsActive, null)
            Spacer(Modifier.width(8.dp))
            Text(if (allowed && channelAllowed) "Manage notifications" else if (allowed) "Enable reminder alerts" else if (settingsRequired) "Allow in Android Settings" else "Allow notifications")
        }
        if (allowed && channelAllowed) OutlinedButton(onClick = {
            runCatching {
                val pending = PendingIntent.getActivity(context, 0, Intent(context, MainActivity::class.java), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                NotificationManagerCompat.from(context).notify(987654, NotificationCompat.Builder(context, ReturnsService.CHANNEL_ID)
                    .setSmallIcon(R.drawable.ic_launcher_foreground).setContentTitle("LaterBox reminders are ready")
                    .setContentText("You'll receive alerts when scheduled items return to your Inbox.")
                    .setContentIntent(pending).setAutoCancel(true).build())
            }.onSuccess { message = "Test notification sent. Check your notification shade." }
                .onFailure { refresh(); message = "Could not send the alert. Check Android notification settings." }
        }, modifier = Modifier.fillMaxWidth()) { Text("Send test notification") }
        if (!allowed && !settingsRequired) TextButton(onClick = { openSettings() }) { Text("Open Android notification settings") }
        message?.let { Text(it, style = MaterialTheme.typography.bodySmall) }
    }
    if (rationale) AlertDialog(onDismissRequest = { rationale = false }, title = { Text("Allow reminder notifications?") },
        text = { Text("LaterBox uses notifications to remind you about items you've scheduled. You can keep using the app without alerts and change this anytime in Android Settings.") },
        confirmButton = { TextButton(onClick = { rationale = false; request() }) { Text("Continue") } },
        dismissButton = { TextButton(onClick = { rationale = false }) { Text("Not now") } })
}
