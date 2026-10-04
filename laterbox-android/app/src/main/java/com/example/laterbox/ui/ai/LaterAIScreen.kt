package com.example.laterbox.ui.ai

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
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
import com.example.laterbox.data.local.ItemEntity
import com.example.laterbox.theme.LaterboxAccent
import com.example.laterbox.theme.LaterboxDarkCard
import com.example.laterbox.theme.LaterboxDarkSurface
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.util.UUID

data class ChatMessage(
    val id: String = UUID.randomUUID().toString(),
    val text: String,
    val isUser: Boolean
)

@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class)
@Composable
fun LaterAIScreen(
    repository: DataRepository,
    onDismiss: () -> Unit
) {
    val items by repository.items.collectAsState(initial = emptyList())
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val scope = rememberCoroutineScope()
    val listState = rememberLazyListState()

    val messages = remember {
        mutableStateListOf(
            ChatMessage(
                text = "Hi! I'm Later AI. Ask me anything about your saved links, articles, return schedules, or inbox organization.",
                isUser = false
            )
        )
    }

    var inputText by remember { mutableStateOf("") }
    var isThinking by remember { mutableStateOf(false) }

    val promptSuggestions = listOf(
        "Summarize my inbox",
        "What's due today?",
        "Find saved articles & videos",
        "Help me clean up"
    )

    fun generateAIResponse(query: String, allItems: List<ItemEntity>): String {
        val q = query.lowercase().trim()
        val inboxItems = allItems.filter { it.status == "inbox" }
        val returnedItems = allItems.filter { it.status == "returned" }

        return when {
            q.contains("summarize") || q.contains("inbox") -> {
                if (inboxItems.isEmpty()) {
                    "Your inbox is completely clear! You have 0 unsorted items."
                } else {
                    val count = inboxItems.size
                    val types = inboxItems.groupBy { it.type }.map { "${it.value.size} ${it.key}(s)" }.joinToString(", ")
                    val recentTitles = inboxItems.take(3).mapNotNull { it.title }.joinToString("\n• ")
                    "You have $count items waiting in your inbox ($types).\n\nTop items:\n• $recentTitles"
                }
            }
            q.contains("due") || q.contains("today") || q.contains("return") -> {
                if (returnedItems.isEmpty()) {
                    "You don't have any items scheduled for return today."
                } else {
                    val titles = returnedItems.take(4).mapNotNull { it.title }.joinToString("\n• ")
                    "You have ${returnedItems.size} items scheduled:\n• $titles"
                }
            }
            q.contains("article") || q.contains("video") || q.contains("find") -> {
                val matches = allItems.filter {
                    it.type.equals("article", true) || it.type.equals("video", true) ||
                    it.title?.lowercase()?.contains("article") == true ||
                    it.title?.lowercase()?.contains("video") == true
                }
                if (matches.isEmpty()) {
                    "I didn't find any articles or videos in your vault yet. Save one via Quick Capture!"
                } else {
                    val sample = matches.take(3).mapNotNull { it.title }.joinToString("\n• ")
                    "Found ${matches.size} articles & media captures:\n• $sample"
                }
            }
            q.contains("clean") -> {
                "To keep your vault neat, consider:\n1. Archiving or marking items done that you've finished reading.\n2. Setting return dates for items you want to read next weekend.\n3. Grouping related links into Collections."
            }
            else -> {
                val matches = allItems.filter {
                    it.title?.lowercase()?.contains(q) == true ||
                    it.textContent?.lowercase()?.contains(q) == true
                }
                if (matches.isNotEmpty()) {
                    "Found ${matches.size} matching items:\n" + matches.take(3).mapNotNull { "• ${it.title}" }.joinToString("\n")
                } else {
                    "I reviewed your ${allItems.size} saved items, but couldn't find an exact match for '$query'. Try asking me to summarize your inbox or check scheduled returns!"
                }
            }
        }
    }

    fun handleSend(text: String) {
        val userQuery = text.trim()
        if (userQuery.isEmpty()) return

        messages.add(ChatMessage(text = userQuery, isUser = true))
        inputText = ""
        isThinking = true

        scope.launch {
            delay(500) // Realistic conversational pause
            val reply = generateAIResponse(userQuery, items)
            isThinking = false
            messages.add(ChatMessage(text = reply, isUser = false))
            delay(100)
            listState.animateScrollToItem(messages.size - 1)
        }
    }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = LaterboxDarkSurface,
        shape = RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 20.dp, vertical = 8.dp)
                .padding(bottom = 24.dp),
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            // Top Header: AI Title + Close button
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
                            .size(30.dp)
                            .clip(CircleShape)
                            .background(LaterboxAccent),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.AutoAwesome,
                            contentDescription = null,
                            tint = LaterboxDarkSurface,
                            modifier = Modifier.size(16.dp)
                        )
                    }
                    Column {
                        Text(
                            text = "Later AI",
                            fontSize = 17.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color.White
                        )
                        Text(
                            text = "Personal vault intelligence",
                            fontSize = 11.sp,
                            color = Color.White.copy(alpha = 0.6f)
                        )
                    }
                }

                IconButton(onClick = onDismiss) {
                    Icon(
                        imageVector = Icons.Default.Close,
                        contentDescription = "Close",
                        tint = Color.White.copy(alpha = 0.7f)
                    )
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Conversation Messages
            LazyColumn(
                state = listState,
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(14.dp)
            ) {
                items(messages, key = { it.id }) { msg ->
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = if (msg.isUser) Arrangement.End else Arrangement.Start
                    ) {
                        Surface(
                            shape = RoundedCornerShape(
                                topStart = 16.dp,
                                topEnd = 16.dp,
                                bottomStart = if (msg.isUser) 16.dp else 4.dp,
                                bottomEnd = if (msg.isUser) 4.dp else 16.dp
                            ),
                            color = if (msg.isUser) LaterboxAccent else LaterboxDarkCard,
                            contentColor = if (msg.isUser) LaterboxDarkSurface else Color.White,
                            modifier = Modifier.widthIn(max = 290.dp)
                        ) {
                            Text(
                                text = msg.text,
                                fontSize = 14.sp,
                                lineHeight = 20.sp,
                                modifier = Modifier.padding(14.dp)
                            )
                        }
                    }
                }

                if (isThinking) {
                    item {
                        Row(
                            horizontalArrangement = Arrangement.Start,
                            modifier = Modifier.padding(start = 4.dp)
                        ) {
                            Surface(
                                shape = RoundedCornerShape(12.dp),
                                color = LaterboxDarkCard,
                                modifier = Modifier.padding(vertical = 4.dp)
                            ) {
                                Row(
                                    modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                                ) {
                                    CircularProgressIndicator(
                                        modifier = Modifier.size(14.dp),
                                        strokeWidth = 2.dp,
                                        color = LaterboxAccent
                                    )
                                    Text(
                                        text = "Later AI is thinking...",
                                        fontSize = 12.sp,
                                        color = Color.White.copy(alpha = 0.7f)
                                    )
                                }
                            }
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            // Quick Prompt Suggestions (if few messages)
            if (messages.size <= 2) {
                FlowRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(bottom = 10.dp)
                ) {
                    promptSuggestions.forEach { prompt ->
                        Surface(
                            shape = RoundedCornerShape(12.dp),
                            color = LaterboxDarkCard,
                            contentColor = Color.White.copy(alpha = 0.85f),
                            modifier = Modifier.clickable { handleSend(prompt) }
                        ) {
                            Text(
                                text = prompt,
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Medium,
                                modifier = Modifier.padding(horizontal = 12.dp, vertical = 7.dp)
                            )
                        }
                    }
                }
            }

            // Input Row
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 4.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                OutlinedTextField(
                    value = inputText,
                    onValueChange = { inputText = it },
                    placeholder = { Text("Ask Later AI...", color = Color.White.copy(alpha = 0.5f)) },
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(18.dp),
                    singleLine = true,
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedTextColor = Color.White,
                        unfocusedTextColor = Color.White,
                        focusedContainerColor = LaterboxDarkCard,
                        unfocusedContainerColor = LaterboxDarkCard,
                        focusedBorderColor = LaterboxAccent,
                        unfocusedBorderColor = Color.White.copy(alpha = 0.15f)
                    )
                )

                IconButton(
                    onClick = { handleSend(inputText) },
                    modifier = Modifier
                        .size(46.dp)
                        .clip(CircleShape)
                        .background(if (inputText.isNotBlank()) LaterboxAccent else LaterboxDarkCard)
                ) {
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.Send,
                        contentDescription = "Send",
                        tint = if (inputText.isNotBlank()) LaterboxDarkSurface else Color.White.copy(alpha = 0.4f),
                        modifier = Modifier.size(18.dp)
                    )
                }
            }
        }
    }
}
