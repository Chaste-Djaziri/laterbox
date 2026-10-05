package com.example.laterbox.ui.screens

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarToday
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
import com.example.laterbox.theme.LaterboxAmber
import com.example.laterbox.theme.LaterboxBg
import com.example.laterbox.theme.LaterboxBorder
import com.example.laterbox.theme.LaterboxCard
import com.example.laterbox.theme.LaterboxDarkSurface
import com.example.laterbox.theme.LaterboxTextPrimary
import com.example.laterbox.theme.LaterboxTextSecondary
import com.example.laterbox.ui.components.ItemCardView
import kotlinx.coroutines.launch
import java.time.LocalDate

@Composable
fun ReturnsScreen(
    repository: DataRepository,
    modifier: Modifier = Modifier
) {
    val items by repository.items.collectAsState(initial = emptyList())
    val scope = rememberCoroutineScope()

    var activeTab by remember { mutableStateOf("today") } // today, upcoming, someday, inbox

    val today = LocalDate.now()
    val todayStr = today.toString()

    val tabCounts = remember(items) {
        val todayCount = items.count { it.returnAt?.startsWith(todayStr) == true }
        val upcomingCount = items.count {
            val r = it.returnAt
            r != null && r > todayStr
        }
        val somedayCount = items.count { it.status == "returned" && it.returnAt == null }
        val inboxCount = items.count { it.status == "inbox" }
        mapOf(
            "today" to todayCount,
            "upcoming" to upcomingCount,
            "someday" to somedayCount,
            "inbox" to inboxCount
        )
    }

    val displayItems = remember(items, activeTab) {
        when (activeTab) {
            "today" -> items.filter { it.returnAt?.startsWith(todayStr) == true }
            "upcoming" -> items.filter {
                val r = it.returnAt
                r != null && r > todayStr
            }
            "someday" -> items.filter { it.status == "returned" && it.returnAt == null }
            "inbox" -> items.filter { it.status == "inbox" }
            else -> items
        }
    }

    val tabs = listOf(
        "today" to "Today",
        "upcoming" to "Upcoming",
        "someday" to "Someday",
        "inbox" to "Inbox"
    )

    LazyColumn(
        modifier = modifier
            .fillMaxSize()
            .background(LaterboxBg),
        contentPadding = PaddingValues(horizontal = 20.dp, vertical = 20.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Header Row: Brand Icon + Title & Subtitle
        item {
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
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
                        text = "Returns",
                        fontSize = 24.sp,
                        fontWeight = FontWeight.Bold,
                        color = LaterboxTextPrimary
                    )
                }

                Text(
                    text = "Deliberately scheduled content returning to your attention.",
                    fontSize = 13.sp,
                    color = LaterboxTextSecondary
                )
            }
        }

        // Sub-tabs Row
        item {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp))
                    .background(LaterboxCard)
                    .border(1.dp, LaterboxBorder, RoundedCornerShape(14.dp))
                    .padding(4.dp),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                tabs.forEach { (key, label) ->
                    val isSelected = activeTab == key
                    val count = tabCounts[key] ?: 0

                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .clip(RoundedCornerShape(10.dp))
                            .background(if (isSelected) LaterboxDarkSurface else Color.Transparent)
                            .clickable { activeTab = key }
                            .padding(vertical = 8.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(4.dp)
                        ) {
                            Text(
                                text = label,
                                fontSize = 12.sp,
                                fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                                color = if (isSelected) Color.White else LaterboxTextPrimary
                            )
                            if (count > 0) {
                                Text(
                                    text = "($count)",
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.Normal,
                                    color = if (isSelected) LaterboxAccent else LaterboxTextSecondary
                                )
                            }
                        }
                    }
                }
            }
        }

        // List of returned items or empty state
        if (displayItems.isEmpty()) {
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
                            .padding(36.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.CalendarToday,
                            contentDescription = null,
                            tint = LaterboxAmber,
                            modifier = Modifier.size(32.dp)
                        )
                        Text(
                            text = "No items for ${tabs.firstOrNull { it.first == activeTab }?.second}",
                            fontSize = 15.sp,
                            fontWeight = FontWeight.Bold,
                            color = LaterboxTextPrimary
                        )
                        Text(
                            text = "Schedule any item to return here when you're ready to review it.",
                            fontSize = 13.sp,
                            color = LaterboxTextSecondary
                        )
                    }
                }
            }
        } else {
            items(displayItems, key = { it.id }) { item ->
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
