package com.example.laterbox.ui.screens

import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.example.laterbox.data.DefaultDataRepository
import com.example.laterbox.data.local.AppDatabase
import com.example.laterbox.data.local.ItemEntity

/** Capture flows use the same full-screen detail page without dismissing their parent. */
@Composable
fun ItemDetailSheet(item: ItemEntity, onDismiss: () -> Unit, onChanged: () -> Unit) {
    val context = LocalContext.current
    val repository = remember(context) { DefaultDataRepository(context, AppDatabase.getDatabase(context)) }
    Dialog(onDismissRequest = onDismiss, properties = DialogProperties(usePlatformDefaultWidth = false, decorFitsSystemWindows = false)) {
        ItemDetailScreen(initialItem = item, repository = repository, onBack = onDismiss, onChanged = onChanged)
    }
}
