package com.example.laterbox.ui.capture

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.example.laterbox.data.DataRepository
import com.example.laterbox.data.local.ItemEntity
import com.example.laterbox.services.VaultStore
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun QuickCaptureSheet(repository: DataRepository, onDismiss: () -> Unit, onSaved: () -> Unit) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val store = remember { VaultStore(context) }
    var saved by remember { mutableStateOf<ItemEntity?>(null) }
    var error by remember { mutableStateOf<String?>(null) }
    var busy by remember { mutableStateOf(false) }
    var edit by remember { mutableStateOf(false) }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
        containerColor = androidx.compose.ui.graphics.Color(0xFF161618),
        contentColor = androidx.compose.ui.graphics.Color.White
    ) {
        Column(
            Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp, vertical = 12.dp)
                .imePadding(),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            if (saved == null) {
                GuidedCapture(
                    onCancel = onDismiss,
                    onSave = { draft ->
                        if (!busy) {
                            busy = true
                            scope.launch {
                                try {
                                    saved = store.save(draft)
                                    onSaved()
                                    repository.syncNow()
                                    scope.launch { store.metadata(draft) }
                                } catch (failure: Exception) {
                                    error = failure.message
                                } finally {
                                    busy = false
                                }
                            }
                        }
                    }
                )
            } else {
                Text(
                    text = "Saved ‘${saved?.title}’",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = androidx.compose.ui.text.font.FontWeight.Bold,
                    color = androidx.compose.ui.graphics.Color.White
                )
                Choice("Edit", subtitle = "View and modify details in vault", dark = true) { edit = true }
                Choice("Undo", subtitle = "Remove this item from your library", dark = true) {
                    scope.launch {
                        try {
                            store.undo(saved!!)
                            saved = null
                            onSaved()
                        } catch (failure: Exception) {
                            error = failure.message
                        }
                    }
                }
                Choice("Done", subtitle = "Return to inbox", dark = true) { onDismiss() }
            }
            if (busy) {
                CircularProgressIndicator(
                    modifier = Modifier.align(androidx.compose.ui.Alignment.CenterHorizontally),
                    color = com.example.laterbox.theme.LaterboxAccent
                )
            }
            error?.let { Text(it, color = MaterialTheme.colorScheme.error) }
        }
    }
    if (edit && saved != null) com.example.laterbox.ui.screens.ItemDetailSheet(saved!!, { edit = false }, onSaved)
}
