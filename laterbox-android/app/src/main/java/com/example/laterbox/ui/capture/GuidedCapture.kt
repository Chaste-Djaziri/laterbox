package com.example.laterbox.ui.capture

import android.provider.OpenableColumns
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.AttachFile
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.laterbox.data.local.ItemEntity
import com.example.laterbox.services.VaultStore
import com.example.laterbox.theme.LaterboxAccent
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.time.*
import java.time.temporal.TemporalAdjusters
import java.util.UUID

@Composable
fun Choice(title: String, subtitle: String = "", dark: Boolean = false, onClick: () -> Unit) {
    Column(
        Modifier
            .fillMaxWidth()
            .background(if (dark) Color(0xFF202020) else Color.White, RoundedCornerShape(16.dp))
            .clickable(onClick = onClick)
            .padding(16.dp)
    ) {
        Text(title, color = if (dark) Color.White else Color.Black, fontWeight = FontWeight.SemiBold)
        if (subtitle.isNotBlank()) Text(subtitle, color = if (dark) Color.LightGray else Color.Gray, style = MaterialTheme.typography.bodySmall)
    }
}

@Composable
fun ReturnChoices(dark: Boolean = false, onSelect: (String?) -> Unit) {
    var custom by remember { mutableStateOf(false) }
    val tomorrow = LocalDate.now().plusDays(1).atTime(9, 0).atZone(ZoneId.systemDefault()).toInstant().toString()
    val weekend = LocalDate.now().with(TemporalAdjusters.next(DayOfWeek.SATURDAY)).atTime(9, 0).atZone(ZoneId.systemDefault()).toInstant().toString()
    Choice("Tomorrow", "9:00 AM", dark) { onSelect(tomorrow) }
    Choice("This weekend", "Saturday at 9:00 AM", dark) { onSelect(weekend) }
    Choice("Choose date", "Set a custom return", dark) { custom = true }
    Choice("No reminder", "Keep in inbox", dark) { onSelect(null) }
    if (custom) CustomReturnDialog(onDismiss = { custom = false }, onSelect = { custom = false; onSelect(it) })
}

@Composable
fun CustomReturnDialog(onDismiss: () -> Unit, onSelect: (String) -> Unit) {
    var day by rememberSaveable { mutableStateOf(LocalDate.now().plusDays(1).toString()) }
    var time by rememberSaveable { mutableStateOf("09:00") }
    var error by remember { mutableStateOf<String?>(null) }
    DialogContent("Choose return", onDismiss) {
        OutlinedTextField(day, { day = it }, label = { Text("Date (YYYY-MM-DD)") }, singleLine = true)
        OutlinedTextField(time, { time = it }, label = { Text("Time (HH:mm)") }, singleLine = true)
        error?.let { Text(it, color = Color.Red) }
        Button(
            onClick = {
                runCatching {
                    LocalDate.parse(day).atTime(LocalTime.parse(time)).atZone(ZoneId.systemDefault()).toInstant().also {
                        require(it.isAfter(Instant.now()))
                    }.toString()
                }.onSuccess(onSelect).onFailure { error = "Choose a valid future date and time." }
            },
            colors = ButtonDefaults.buttonColors(containerColor = LaterboxAccent, contentColor = Color.Black)
        ) {
            Text("Confirm return")
        }
    }
}

@Composable
fun DialogContent(title: String, onDismiss: () -> Unit, content: @Composable ColumnScope.() -> Unit) {
    androidx.compose.ui.window.Dialog(onDismissRequest = onDismiss) {
        Column(
            Modifier
                .fillMaxWidth()
                .background(Color(0xFFF7F5EE), RoundedCornerShape(24.dp))
                .padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(title, style = MaterialTheme.typography.titleLarge)
            content()
            TextButton(onClick = onDismiss) { Text("Close") }
        }
    }
}

@Composable
fun GuidedCapture(
    initial: String = "",
    attachments: String = "[]",
    dark: Boolean = false,
    scrollable: Boolean = true,
    modifier: Modifier = Modifier,
    onSave: (ItemEntity) -> Unit
) {
    val context = LocalContext.current
    var content by rememberSaveable { mutableStateOf(initial) }
    var title by rememberSaveable { mutableStateOf(VaultStore.draft(initial).title.orEmpty()) }
    var tags by rememberSaveable { mutableStateOf(VaultStore.draft(initial).tags) }
    var category by rememberSaveable { mutableStateOf("") }
    var returnAt by rememberSaveable { mutableStateOf<String?>(null) }
    var step by rememberSaveable { mutableIntStateOf(0) }
    val id = rememberSaveable { UUID.randomUUID().toString() }
    val text = if (dark) Color.White else Color.Black

    val attachmentList = remember {
        mutableStateListOf<JSONObject>().apply {
            runCatching {
                val arr = JSONArray(attachments)
                for (i in 0 until arr.length()) add(arr.getJSONObject(i))
            }
        }
    }

    val filePickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetMultipleContents()
    ) { uris ->
        if (uris.isEmpty()) return@rememberLauncherForActivityResult
        val directory = File(context.filesDir, "captures").apply { mkdirs() }
        for (uri in uris) {
            val name = runCatching {
                context.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { cursor ->
                    if (cursor.moveToFirst()) cursor.getString(0) else "Attachment"
                }
            }.getOrNull() ?: "Attachment"
            val extension = name.substringAfterLast('.', "").take(12).filter { it.isLetterOrDigit() }
            val file = File(directory, UUID.randomUUID().toString() + if (extension.isBlank()) "" else ".$extension")
            try {
                context.contentResolver.openInputStream(uri)?.use { input ->
                    file.outputStream().use { output ->
                        input.copyTo(output)
                    }
                }
                val mime = context.contentResolver.getType(uri) ?: "application/octet-stream"
                attachmentList.add(
                    JSONObject()
                        .put("name", name)
                        .put("path", file.absolutePath)
                        .put("mime", mime)
                        .put("size", file.length())
                )
            } catch (_: Exception) {
                file.delete()
            }
        }
    }

    val currentAttachmentsJson = remember(attachmentList.size) {
        JSONArray().apply { attachmentList.forEach { put(it) } }.toString()
    }

    Column(
        modifier = modifier.fillMaxSize(),
        verticalArrangement = Arrangement.SpaceBetween
    ) {
        // Step title & content container (takes weight(1f) to give full room)
        Column(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            Text(
                text = listOf(
                    "What would you like to save?",
                    "Give it a title",
                    "Organize your capture",
                    "When should it return?",
                    "Ready to save"
                )[step],
                color = text,
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )

            when (step) {
                0 -> {
                    // Full-height freeform editor for anything: markdown, html, links, code, notes
                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .fillMaxWidth()
                            .background(
                                if (dark) Color(0xFF161618) else Color(0xFFF7F5EE),
                                RoundedCornerShape(18.dp)
                            )
                            .border(
                                1.dp,
                                if (dark) Color.White.copy(alpha = 0.12f) else Color.Black.copy(alpha = 0.1f),
                                RoundedCornerShape(18.dp)
                            )
                            .padding(16.dp)
                    ) {
                        BasicTextField(
                            value = content,
                            onValueChange = { content = it },
                            textStyle = TextStyle(
                                fontSize = 15.sp,
                                lineHeight = 22.sp,
                                color = if (dark) Color.White else Color.Black
                            ),
                            cursorBrush = SolidColor(LaterboxAccent),
                            modifier = Modifier
                                .fillMaxSize()
                                .verticalScroll(rememberScrollState()),
                            decorationBox = { innerTextField ->
                                Box(contentAlignment = Alignment.TopStart) {
                                    if (content.isEmpty()) {
                                        Text(
                                            text = "Enter or paste anything here…\n\n• Notes & ideas\n• Markdown formatted text\n• HTML & code snippets\n• Web links & URLs",
                                            fontSize = 14.sp,
                                            lineHeight = 22.sp,
                                            color = if (dark) Color.White.copy(alpha = 0.35f) else Color.Black.copy(alpha = 0.35f)
                                        )
                                    }
                                    innerTextField()
                                }
                            }
                        )
                    }
                }
                1 -> {
                    Column(
                        modifier = Modifier
                            .weight(1f)
                            .fillMaxWidth(),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Field(title, { title = it }, "Title (optional)", dark)
                        Text(
                            text = "Leave empty to automatically generate a title based on your content.",
                            color = if (dark) Color.White.copy(alpha = 0.5f) else Color.Gray,
                            fontSize = 13.sp
                        )
                    }
                }
                2 -> {
                    Column(
                        modifier = Modifier
                            .weight(1f)
                            .fillMaxWidth()
                            .verticalScroll(rememberScrollState()),
                        verticalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        Field(category, { category = it }, "Collection / category (optional)", dark)
                        Field(tags, { tags = it }, "Tags, separated by commas", dark)
                        listOf("Reading", "Ideas", "Work", "Recipes").forEach { suggestion ->
                            Choice(suggestion, "Use as collection", dark) { category = suggestion }
                        }
                    }
                }
                3 -> {
                    Column(
                        modifier = Modifier
                            .weight(1f)
                            .fillMaxWidth()
                            .verticalScroll(rememberScrollState()),
                        verticalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        ReturnChoices(dark) { returnAt = it; step = 4 }
                    }
                }
                4 -> {
                    Column(
                        modifier = Modifier
                            .weight(1f)
                            .fillMaxWidth()
                            .verticalScroll(rememberScrollState()),
                        verticalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        Choice(title.ifBlank { content.take(100) }, "Content summary", dark) {}
                        Choice("${category.ifBlank { "Inbox" }} · ${tags.ifBlank { "No tags" }}", "Collection & tags", dark) {}
                        Choice(returnAt ?: "No reminder", "Return date", dark) {}
                    }
                }
            }

            // Attached files row if any
            if (attachmentList.isNotEmpty()) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    attachmentList.forEachIndexed { index, fileObj ->
                        Surface(
                            shape = RoundedCornerShape(14.dp),
                            color = if (dark) Color(0xFF222225) else Color.White,
                            border = BorderStroke(1.dp, if (dark) Color.White.copy(alpha = 0.12f) else Color.LightGray)
                        ) {
                            Row(
                                modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(6.dp)
                            ) {
                                Icon(
                                    imageVector = Icons.Default.AttachFile,
                                    contentDescription = null,
                                    tint = LaterboxAccent,
                                    modifier = Modifier.size(13.dp)
                                )
                                Text(
                                    text = fileObj.optString("name", "Attachment"),
                                    fontSize = 12.sp,
                                    color = if (dark) Color.White else Color.Black,
                                    maxLines = 1
                                )
                                Icon(
                                    imageVector = Icons.Default.Close,
                                    contentDescription = "Remove",
                                    tint = if (dark) Color.White.copy(alpha = 0.5f) else Color.Gray,
                                    modifier = Modifier
                                        .size(14.dp)
                                        .clickable { attachmentList.removeAt(index) }
                                )
                            }
                        }
                    }
                }
            }
        }

        // Bottom Action Bar: docked at bottom, moves up with keyboard
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            if (step > 0) {
                IconButton(
                    onClick = { step-- },
                    modifier = Modifier
                        .size(46.dp)
                        .background(if (dark) Color(0xFF222225) else Color(0xFFE5E5EA), CircleShape)
                ) {
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                        contentDescription = "Back",
                        tint = if (dark) Color.White else Color.Black,
                        modifier = Modifier.size(18.dp)
                    )
                }
            }

            // Small circular attachment button on the left of continue
            IconButton(
                onClick = { filePickerLauncher.launch("*/*") },
                modifier = Modifier
                    .size(46.dp)
                    .background(if (dark) Color(0xFF222225) else Color(0xFFE5E5EA), CircleShape)
                    .border(1.dp, if (dark) Color.White.copy(alpha = 0.12f) else Color.Transparent, CircleShape)
            ) {
                Icon(
                    imageVector = Icons.Default.AttachFile,
                    contentDescription = "Add attachment",
                    tint = LaterboxAccent,
                    modifier = Modifier.size(20.dp)
                )
            }

            // Continue button filling the remaining width
            if (step != 3) {
                Button(
                    onClick = {
                        if (step == 4) {
                            onSave(VaultStore.draft(content, title, tags, category, returnAt, currentAttachmentsJson, id))
                        } else {
                            step++
                        }
                    },
                    enabled = step != 0 || content.isNotBlank() || attachmentList.isNotEmpty(),
                    shape = RoundedCornerShape(24.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = LaterboxAccent,
                        contentColor = Color.Black,
                        disabledContainerColor = if (dark) Color.White.copy(alpha = 0.12f) else Color.LightGray,
                        disabledContentColor = if (dark) Color.White.copy(alpha = 0.35f) else Color.Gray
                    ),
                    modifier = Modifier
                        .weight(1f)
                        .height(46.dp)
                ) {
                    Text(
                        text = if (step == 4) "Save to vault" else "Continue",
                        fontWeight = FontWeight.Bold,
                        fontSize = 15.sp
                    )
                }
            }
        }
    }
}

@Composable
fun Field(value: String, change: (String) -> Unit, label: String, dark: Boolean = false) {
    OutlinedTextField(
        value = value,
        onValueChange = change,
        label = { Text(label) },
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(14.dp),
        colors = OutlinedTextFieldDefaults.colors(
            focusedTextColor = if (dark) Color.White else Color.Black,
            unfocusedTextColor = if (dark) Color.White else Color.Black,
            focusedBorderColor = LaterboxAccent,
            unfocusedBorderColor = Color.Gray,
            focusedLabelColor = if (dark) LaterboxAccent else Color.Black,
            unfocusedLabelColor = Color.Gray
        )
    )
}
