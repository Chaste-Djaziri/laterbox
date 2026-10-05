package com.example.laterbox.ui.capture

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.example.laterbox.data.local.ItemEntity
import com.example.laterbox.services.VaultStore
import com.example.laterbox.theme.LaterboxAccent
import java.time.*
import java.time.temporal.TemporalAdjusters
import java.util.UUID

@Composable
fun Choice(title: String, subtitle: String = "", dark: Boolean = false, onClick: () -> Unit) {
    Column(Modifier.fillMaxWidth().background(if (dark) Color(0xFF202020) else Color.White, RoundedCornerShape(16.dp)).clickable(onClick = onClick).padding(16.dp)) {
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
    // Brand choice cards keep platform picker chrome out of capture.
    DialogContent("Choose return", onDismiss) {
        OutlinedTextField(day, { day = it }, label = { Text("Date (YYYY-MM-DD)") }, singleLine = true)
        OutlinedTextField(time, { time = it }, label = { Text("Time (HH:mm)") }, singleLine = true)
        error?.let { Text(it, color = Color.Red) }
        Button(onClick = { runCatching { LocalDate.parse(day).atTime(LocalTime.parse(time)).atZone(ZoneId.systemDefault()).toInstant().also { require(it.isAfter(Instant.now())) }.toString() }.onSuccess(onSelect).onFailure { error = "Choose a valid future date and time." } }, colors = ButtonDefaults.buttonColors(containerColor = LaterboxAccent, contentColor = Color.Black)) { Text("Confirm return") }
    }
}
@Composable
fun DialogContent(title: String, onDismiss: () -> Unit, content: @Composable ColumnScope.() -> Unit) {
    androidx.compose.ui.window.Dialog(onDismissRequest = onDismiss) {
        Column(Modifier.fillMaxWidth().background(Color(0xFFF7F5EE), RoundedCornerShape(24.dp)).padding(20.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text(title, style = MaterialTheme.typography.titleLarge)
            content()
            TextButton(onClick = onDismiss) { Text("Close") }
        }
    }
}
@Composable
fun GuidedCapture(initial: String = "", attachments: String = "[]", dark: Boolean = false, onSave: (ItemEntity) -> Unit) {
    var content by rememberSaveable { mutableStateOf(initial) }
    var title by rememberSaveable { mutableStateOf(VaultStore.draft(initial).title.orEmpty()) }
    var tags by rememberSaveable { mutableStateOf(VaultStore.draft(initial).tags) }
    var category by rememberSaveable { mutableStateOf("") }
    var returnAt by rememberSaveable { mutableStateOf<String?>(null) }
    var step by rememberSaveable { mutableIntStateOf(0) }
    val id = rememberSaveable { UUID.randomUUID().toString() }
    val text = if (dark) Color.White else Color.Black
    Column(Modifier.fillMaxWidth().verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text(listOf("What would you like to save?", "Give it a title", "Organize your capture", "When should it return?", "Ready to save")[step], color = text, style = MaterialTheme.typography.titleLarge)
        when (step) {
            0 -> { Field(content, { content = it }, "Content or URL", dark); if (attachments != "[]") Text("Shared attachments are ready to save", color = text) }
            1 -> Field(title, { title = it }, "Title (optional)", dark)
            2 -> {
                Field(category, { category = it }, "Collection / category (optional)", dark)
                Field(tags, { tags = it }, "Tags, separated by commas", dark)
                listOf("Reading", "Ideas", "Work", "Recipes").forEach { suggestion -> Choice(suggestion, "Use as collection", dark) { category = suggestion } }
            }
            3 -> ReturnChoices(dark) { returnAt = it; step = 4 }
            4 -> { Text(title.ifBlank { content.take(100) }, color = text); Text("${category.ifBlank { "Inbox" }} · ${tags.ifBlank { "No tags" }}", color = text); Text(returnAt ?: "No reminder", color = text) }
        }
        if (step != 3) Button(onClick = { if (step == 4) onSave(VaultStore.draft(content, title, tags, category, returnAt, attachments, id)) else step++ }, enabled = step != 0 || content.isNotBlank() || attachments != "[]", colors = ButtonDefaults.buttonColors(containerColor = LaterboxAccent, contentColor = Color.Black), modifier = Modifier.fillMaxWidth()) { Text(if (step == 4) "Save to vault" else "Continue") }
        if (step > 0) TextButton(onClick = { step-- }) { Text("Back", color = text) }
    }
}
@Composable
fun Field(value: String, change: (String) -> Unit, label: String, dark: Boolean = false) {
    OutlinedTextField(value, change, label = { Text(label) }, modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(14.dp),
        colors = OutlinedTextFieldDefaults.colors(focusedTextColor = if (dark) Color.White else Color.Black, unfocusedTextColor = if (dark) Color.White else Color.Black,
            focusedBorderColor = LaterboxAccent, unfocusedBorderColor = Color.Gray, focusedLabelColor = if (dark) LaterboxAccent else Color.Black, unfocusedLabelColor = Color.Gray))
}
