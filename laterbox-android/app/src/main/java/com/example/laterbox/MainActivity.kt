package com.example.laterbox

import android.content.Intent
import android.os.Bundle
import android.view.WindowManager
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.fragment.app.FragmentActivity
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.example.laterbox.services.AppLockService
import com.example.laterbox.theme.LaterboxTheme
import io.github.jan.supabase.auth.handleDeeplinks

class MainActivity : FragmentActivity() {
    private var notificationItem by mutableStateOf<String?>(null)
    private var locked by mutableStateOf(false)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        notificationItem = intent.getStringExtra("item_id")
        locked = getSharedPreferences("laterbox", 0).getBoolean("app_lock", false)
        SupabaseClient.client.handleDeeplinks(intent)
        enableEdgeToEdge()
        setContent {
            LaterboxTheme {
                if (!locked) AppNavigation(notificationItemId = notificationItem)
                else {
                    var error by remember { mutableStateOf<String?>(null) }
                    Column(Modifier.fillMaxSize().padding(24.dp), verticalArrangement = Arrangement.Center, horizontalAlignment = Alignment.CenterHorizontally) {
                        Text("Your vault is locked", style = MaterialTheme.typography.headlineMedium)
                        Button(onClick = { AppLockService.authenticate(this@MainActivity, { locked = false }, { error = it }) }) { Text("Unlock LaterBox") }
                        error?.let { Text(it) }
                    }
                }
            }
        }
    }
    override fun onStart() { super.onStart(); if (getSharedPreferences("laterbox", 0).getBoolean("screen_protection", false)) window.addFlags(WindowManager.LayoutParams.FLAG_SECURE) }
    override fun onStop() { super.onStop(); if (getSharedPreferences("laterbox", 0).getBoolean("app_lock", false)) locked = true }
    override fun onNewIntent(newIntent: Intent) { super.onNewIntent(newIntent); intent = newIntent; notificationItem = newIntent.getStringExtra("item_id"); SupabaseClient.client.handleDeeplinks(newIntent) }
}
