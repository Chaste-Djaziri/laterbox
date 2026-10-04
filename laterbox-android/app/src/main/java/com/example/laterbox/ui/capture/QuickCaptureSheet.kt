package com.example.laterbox.ui.capture

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Link
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.laterbox.data.DataRepository
import com.example.laterbox.data.api.LaterBoxApiService
import com.example.laterbox.theme.LaterboxAccent
import com.example.laterbox.theme.LaterboxAmber
import com.example.laterbox.theme.LaterboxDarkSurface
import com.example.laterbox.theme.LaterboxEmerald
import com.example.laterbox.theme.LaterboxIndigo
import com.example.laterbox.theme.LaterboxTextPrimary
import com.example.laterbox.theme.LaterboxTextSecondary
import com.example.laterbox.ui.components.TypeBadge
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.time.format.DateTimeFormatter

@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class)
@Composable
fun QuickCaptureSheet(
    repository: DataRepository,
    onDismiss: () -> Unit,
    onSaved: () -> Unit
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val scope = rememberCoroutineScope()

    var inputContent by remember { mutableStateOf("") }
    var inputTitle by remember { mutableStateOf("") }
    var selectedType by remember { mutableStateOf("link") }
    var selectedSchedule by remember { mutableStateOf("inbox") } // inbox, tomorrow, weekend, next_week, someday
    var isEnriching by remember { mutableStateOf(false) }
    var enrichmentInfo by remember { mutableStateOf<String?>(null) }
    var isSaving by remember { mutableStateOf(false) }

    val formatOptions = listOf("link", "article", "video", "music", "repository", "note")
    val scheduleOptions = listOf(
        "inbox" to "Inbox",
        "tomorrow" to "Tomorrow",
        "weekend" to "Weekend",
        "next_week" to "Next Week",
        "someday" to "Someday"
    )

    fun tryAutoEnrich(url: String) {
        if (url.startsWith("http://") || url.startsWith("https://")) {
            isEnriching = true
            scope.launch {
                val result = LaterBoxApiService.enrichUrl(url)
                isEnriching = false
                if (result != null) {
                    if (inputTitle.isEmpty() && !result.title.isNullOrEmpty()) {
                        inputTitle = result.title
                    }
                    selectedType = result.contentType
                    enrichmentInfo = "Enriched from ${result.domain ?: result.siteName ?: "web"}"
                }
            }
        }
    }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = MaterialTheme.colorScheme.surface,
        shape = RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp, vertical = 8.dp)
                .padding(bottom = 32.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .size(28.dp)
                            .clip(CircleShape)
                            .background(LaterboxAccent),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.Link,
                            contentDescription = null,
                            tint = LaterboxDarkSurface,
                            modifier = Modifier.size(16.dp)
                        )
                    }
                    Text(
                        text = "Quick Capture",
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                }

                IconButton(
                    onClick = onDismiss,
                    modifier = Modifier.size(28.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Close,
                        contentDescription = "Close",
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            // Input: URL or Note
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text(
                    text = "URL or Note Content",
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Medium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                OutlinedTextField(
                    value = inputContent,
                    onValueChange = {
                        inputContent = it
                        if (it.startsWith("http://") || it.startsWith("https://")) {
                            tryAutoEnrich(it.trim())
                        }
                    },
                    placeholder = { Text("https://example.com or any thought...") },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = LaterboxDarkSurface,
                        unfocusedBorderColor = MaterialTheme.colorScheme.outline
                    ),
                    maxLines = 4,
                    trailingIcon = {
                        if (isEnriching) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(18.dp),
                                strokeWidth = 2.dp,
                                color = LaterboxIndigo
                            )
                        } else if (inputContent.startsWith("http")) {
                            IconButton(onClick = { tryAutoEnrich(inputContent.trim()) }) {
                                Icon(
                                    imageVector = Icons.Default.AutoAwesome,
                                    contentDescription = "Enrich",
                                    tint = LaterboxIndigo,
                                    modifier = Modifier.size(20.dp)
                                )
                            }
                        }
                    }
                )
                if (enrichmentInfo != null) {
                    Text(
                        text = "✓ $enrichmentInfo",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Medium,
                        color = LaterboxEmerald
                    )
                }
            }

            // Input: Title
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text(
                    text = "Title (Optional)",
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Medium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                OutlinedTextField(
                    value = inputTitle,
                    onValueChange = { inputTitle = it },
                    placeholder = { Text("Title or summary") },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                    singleLine = true,
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = LaterboxDarkSurface,
                        unfocusedBorderColor = MaterialTheme.colorScheme.outline
                    )
                )
            }

            // Format Selection Chips
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(
                    text = "Format Classification",
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Medium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                FlowRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    formatOptions.forEach { format ->
                        val isSelected = selectedType == format
                        Surface(
                            shape = RoundedCornerShape(10.dp),
                            color = if (isSelected) LaterboxDarkSurface else MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f),
                            contentColor = if (isSelected) Color.White else MaterialTheme.colorScheme.onSurface,
                            modifier = Modifier.clickable { selectedType = format }
                        ) {
                            Text(
                                text = format.replaceFirstChar { it.uppercase() },
                                fontSize = 12.sp,
                                fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
                                modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp)
                            )
                        }
                    }
                }
            }

            // Schedule Return Picker
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Schedule,
                        contentDescription = null,
                        tint = LaterboxAmber,
                        modifier = Modifier.size(16.dp)
                    )
                    Text(
                        text = "Schedule Return",
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Medium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }

                FlowRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    scheduleOptions.forEach { (key, label) ->
                        val isSelected = selectedSchedule == key
                        Surface(
                            shape = RoundedCornerShape(10.dp),
                            color = if (isSelected) LaterboxAmber.copy(alpha = 0.2f) else MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f),
                            contentColor = if (isSelected) LaterboxAmber else MaterialTheme.colorScheme.onSurface,
                            border = if (isSelected) androidx.compose.foundation.BorderStroke(1.dp, LaterboxAmber) else null,
                            modifier = Modifier.clickable { selectedSchedule = key }
                        ) {
                            Text(
                                text = label,
                                fontSize = 12.sp,
                                fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
                                modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp)
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(4.dp))

            // Save Button
            Button(
                onClick = {
                    if (inputContent.isNotEmpty() || inputTitle.isNotEmpty()) {
                        isSaving = true
                        scope.launch {
                            val isUrl = inputContent.startsWith("http://") || inputContent.startsWith("https://")
                            val url = if (isUrl) inputContent.trim() else null
                            val note = if (!isUrl && inputContent.isNotEmpty()) inputContent.trim() else null

                            var returnAt: String? = null
                            val today = LocalDate.now()
                            when (selectedSchedule) {
                                "tomorrow" -> returnAt = today.plusDays(1).format(DateTimeFormatter.ISO_LOCAL_DATE)
                                "weekend" -> returnAt = today.plusDays(3).format(DateTimeFormatter.ISO_LOCAL_DATE)
                                "next_week" -> returnAt = today.plusDays(7).format(DateTimeFormatter.ISO_LOCAL_DATE)
                                "someday" -> returnAt = today.plusDays(30).format(DateTimeFormatter.ISO_LOCAL_DATE)
                            }

                            repository.captureItem(
                                url = url,
                                text = note,
                                title = inputTitle.ifEmpty { url ?: note?.take(40) ?: "Untitled" },
                                returnAt = returnAt
                            )

                            isSaving = false
                            onSaved()
                            onDismiss()
                        }
                    }
                },
                enabled = !isSaving && (inputContent.isNotEmpty() || inputTitle.isNotEmpty()),
                modifier = Modifier
                    .fillMaxWidth()
                    .height(50.dp),
                shape = RoundedCornerShape(14.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = LaterboxDarkSurface,
                    contentColor = Color.White
                )
            ) {
                if (isSaving) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(20.dp),
                        strokeWidth = 2.dp,
                        color = Color.White
                    )
                } else {
                    Text(
                        text = "Save to Laterbox",
                        fontSize = 15.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }
    }
}
