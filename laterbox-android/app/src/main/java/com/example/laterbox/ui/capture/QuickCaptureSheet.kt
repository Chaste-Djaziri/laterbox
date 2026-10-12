package com.example.laterbox.ui.capture

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import com.example.laterbox.data.DataRepository

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun QuickCaptureSheet(repository: DataRepository, onDismiss: () -> Unit, onSaved: () -> Unit) {
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
        containerColor = Color.Black,
        contentColor = Color.White,
        dragHandle = null,
        modifier = Modifier
            .fillMaxWidth()
            .imePadding()
    ) {
        ShareCaptureScreen(
            initialText = "",
            attachmentsJson = "[]",
            isLockedInitially = false,
            onClose = onDismiss,
            onSaved = onSaved
        )
    }
}
