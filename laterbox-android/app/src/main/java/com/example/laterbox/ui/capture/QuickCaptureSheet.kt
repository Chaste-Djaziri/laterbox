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
    val context = LocalContext.current; val scope = rememberCoroutineScope(); val store = remember { VaultStore(context) }
    var saved by remember { mutableStateOf<ItemEntity?>(null) }; var error by remember { mutableStateOf<String?>(null) }; var busy by remember { mutableStateOf(false) }; var edit by remember { mutableStateOf(false) }
    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)) {
        Column(Modifier.fillMaxWidth().padding(20.dp).imePadding(), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            if (saved == null) GuidedCapture(onSave = { draft -> if (!busy) { busy = true; scope.launch { try { saved = store.save(draft); onSaved(); repository.syncNow(); scope.launch { store.metadata(draft) } } catch (failure: Exception) { error = failure.message } finally { busy = false } } } })
            else { Text("Saved ‘${saved?.title}’", style = MaterialTheme.typography.titleLarge); Choice("Edit") { edit = true }; Choice("Undo") { scope.launch { try { store.undo(saved!!); saved = null; onSaved() } catch (failure: Exception) { error = failure.message } } }; Choice("Done") { onDismiss() } }
            if (busy) CircularProgressIndicator()
            error?.let { Text(it, color = MaterialTheme.colorScheme.error) }
        }
    }
    if (edit && saved != null) com.example.laterbox.ui.screens.ItemDetailSheet(saved!!, { edit = false }, onSaved)
}
