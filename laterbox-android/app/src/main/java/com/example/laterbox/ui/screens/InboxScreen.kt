package com.example.laterbox.ui.screens

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Sort
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.laterbox.R
import com.example.laterbox.data.DataRepository
import com.example.laterbox.theme.LaterboxAccent
import com.example.laterbox.theme.LaterboxBg
import com.example.laterbox.theme.LaterboxBorder
import com.example.laterbox.theme.LaterboxCard
import com.example.laterbox.theme.LaterboxDarkSurface
import com.example.laterbox.theme.LaterboxEmerald
import com.example.laterbox.theme.LaterboxTextPrimary
import com.example.laterbox.theme.LaterboxTextSecondary
import com.example.laterbox.ui.components.ItemCardView
import kotlinx.coroutines.launch
import java.time.LocalDate

@Composable
fun InboxScreen(
    repository: DataRepository,
    modifier: Modifier = Modifier
) {
    val items by repository.items.collectAsState(initial = emptyList())
    val scope = rememberCoroutineScope()

    var activeFilter by remember { mutableStateOf("all") }
    var isFifoAscending by remember { mutableStateOf(false) }

    val filterOptions = listOf(
        "all" to "All",
        "link" to "Links",
        "article" to "Articles",
        "video" to "Videos",
        "music" to "Music",
        "note" to "Notes",
        "starred" to "Starred"
    )

    // Filter by inbox status and active filter
    val inboxItems = items
        .filter { it.status == "inbox" }
        .filter { item ->
            when (activeFilter) {
                "all" -> true
                "starred" -> item.favorite
                else -> item.type.equals(activeFilter, ignoreCase = true)
            }
        }
        .let { list ->
            if (isFifoAscending) {
                list.sortedBy { it.createdAt }
            } else {
                list.sortedByDescending { it.createdAt }
            }
        }

    LazyColumn(
        modifier = modifier
            .fillMaxSize()
            .background(LaterboxBg),
        contentPadding = PaddingValues(horizontal = 20.dp, vertical = 20.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Header Row: Title + Count Badge + Sort Toggle
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    Image(
                        painter = painterResource(id = R.drawable.laterbox_icon_green),
                        contentDescription = null,
                        modifier = Modifier
                            .size(26.dp)
                            .clip(RoundedCornerShape(6.dp)),
                        contentScale = ContentScale.Fit
                    )

                    Text(
                        text = "Inbox",
                        fontSize = 24.sp,
                        fontWeight = FontWeight.Bold,
                        color = LaterboxTextPrimary
                    )

                    Surface(
                        shape = CircleShape,
                        color = LaterboxDarkSurface,
                        contentColor = Color.White
                    ) {
                        Text(
                            text = inboxItems.size.toString(),
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp)
                        )
                    }
                }

                // Sort toggle (FIFO / LIFO)
                Surface(
                    shape = RoundedCornerShape(10.dp),
                    color = LaterboxCard,
                    border = androidx.compose.foundation.BorderStroke(1.dp, LaterboxBorder),
                    modifier = Modifier.clickable { isFifoAscending = !isFifoAscending }
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.Sort,
                            contentDescription = null,
                            tint = LaterboxTextSecondary,
                            modifier = Modifier.size(14.dp)
                        )
                        Text(
                            text = if (isFifoAscending) "Oldest first" else "Newest first",
                            fontSize = 12.sp,
                            color = LaterboxTextSecondary,
                            fontWeight = FontWeight.Medium
                        )
                    }
                }
            }
        }

        // Filter Chips Row
        item {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState()),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                filterOptions.forEach { (key, label) ->
                    val isSelected = activeFilter == key
                    Surface(
                        shape = RoundedCornerShape(12.dp),
                        color = if (isSelected) LaterboxDarkSurface else LaterboxCard,
                        contentColor = if (isSelected) Color.White else LaterboxTextPrimary,
                        border = if (!isSelected) androidx.compose.foundation.BorderStroke(1.dp, LaterboxBorder) else null,
                        modifier = Modifier.clickable { activeFilter = key }
                    ) {
                        Text(
                            text = label,
                            fontSize = 13.sp,
                            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                            modifier = Modifier.padding(horizontal = 14.dp, vertical = 7.dp)
                        )
                    }
                }
            }
        }

        // Items List or Empty State
        if (inboxItems.isEmpty()) {
            item {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(18.dp),
                    colors = CardDefaults.cardColors(containerColor = LaterboxCard),
                    border = androidx.compose.foundation.BorderStroke(1.dp, LaterboxBorder)
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(40.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        Box(
                            modifier = Modifier
                                .size(50.dp)
                                .clip(CircleShape)
                                .background(LaterboxEmerald.copy(alpha = 0.15f)),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = Icons.Default.CheckCircle,
                                contentDescription = null,
                                tint = LaterboxEmerald,
                                modifier = Modifier.size(28.dp)
                            )
                        }
                        Text(
                            text = "Inbox Zero",
                            fontSize = 17.sp,
                            fontWeight = FontWeight.Bold,
                            color = LaterboxTextPrimary
                        )
                        Text(
                            text = "You have caught up with all your saved captures.",
                            fontSize = 13.sp,
                            color = LaterboxTextSecondary
                        )
                    }
                }
            }
        } else {
            items(inboxItems, key = { it.id }) { item ->
                ItemCardView(
                    item = item,
                    onToggleFavorite = {
                        scope.launch { repository.toggleFavorite(item.id, item.favorite) }
                    },
                    onMarkDone = {
                        scope.launch {
                            val newStatus = if (item.status == "done") "inbox" else "done"
                            repository.updateItemStatus(item.id, newStatus)
                        }
                    },
                    onScheduleReturn = { scheduleKey ->
                        scope.launch {
                            val targetDate = when (scheduleKey) {
                                "tomorrow" -> LocalDate.now().plusDays(1).toString()
                                "next_week" -> LocalDate.now().plusDays(7).toString()
                                else -> null
                            }
                            repository.scheduleReturn(item.id, targetDate)
                        }
                    },
                    onDelete = {
                        scope.launch { repository.deleteItem(item.id) }
                    }
                )
            }
        }
    }
}
