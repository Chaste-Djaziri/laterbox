package com.example.laterbox.ui.screens

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
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
import androidx.compose.material.icons.automirrored.filled.TrendingUp
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.Inbox
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
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
import com.example.laterbox.theme.LaterboxEmerald
import com.example.laterbox.theme.LaterboxIndigo
import com.example.laterbox.theme.LaterboxTextPrimary
import com.example.laterbox.theme.LaterboxTextSecondary
import com.example.laterbox.ui.components.ItemCardView
import com.example.laterbox.ui.components.SummaryMetricCard
import com.example.laterbox.ui.components.SystemStatusIndicator
import kotlinx.coroutines.launch
import java.time.LocalDate

@Composable
fun HomeScreen(
    repository: DataRepository,
    onOpenQuickCapture: () -> Unit,
    onOpenLaterAI: () -> Unit,
    onNavigateToTab: (Int) -> Unit,
    modifier: Modifier = Modifier
) {
    val items by repository.items.collectAsState(initial = emptyList())
    val webStatus by repository.webStatus.collectAsState()
    val scope = rememberCoroutineScope()

    val inboxItems = items.filter { it.status == "inbox" }
    val todayStr = LocalDate.now().toString()
    val dueTodayItems = items.filter { it.returnAt?.startsWith(todayStr) == true }
    val starredItems = items.filter { it.favorite }
    val recentItems = items.take(6)

    LazyColumn(
        modifier = modifier
            .fillMaxSize()
            .background(LaterboxBg),
        contentPadding = PaddingValues(horizontal = 20.dp, vertical = 20.dp),
        verticalArrangement = Arrangement.spacedBy(20.dp)
    ) {
        // App Header: Official Logo / Icon + Brand Name + Live Web System Status + AI Trigger
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
                        contentDescription = "Laterbox",
                        modifier = Modifier
                            .size(32.dp)
                            .clip(RoundedCornerShape(8.dp)),
                        contentScale = ContentScale.Fit
                    )

                    Column {
                        Text(
                            text = "laterbox",
                            fontSize = 22.sp,
                            fontWeight = FontWeight.Black,
                            letterSpacing = (-0.5).sp,
                            color = LaterboxTextPrimary
                        )
                        Text(
                            text = "Save now, return when ready",
                            fontSize = 12.sp,
                            color = LaterboxTextSecondary
                        )
                    }
                }

                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    SystemStatusIndicator(
                        isOperational = webStatus.isOperational,
                        label = webStatus.status.replaceFirstChar { it.uppercase() }
                    )

                    // Later AI button
                    Box(
                        modifier = Modifier
                            .size(36.dp)
                            .clip(CircleShape)
                            .background(LaterboxDarkSurface)
                            .clickable { onOpenLaterAI() },
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.AutoAwesome,
                            contentDescription = "Later AI",
                            tint = LaterboxAccent,
                            modifier = Modifier.size(18.dp)
                        )
                    }
                }
            }
        }

        // Quick Capture Trigger Banner
        item {
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { onOpenQuickCapture() },
                shape = RoundedCornerShape(20.dp),
                colors = CardDefaults.cardColors(containerColor = LaterboxDarkSurface),
                elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(18.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(14.dp)
                    ) {
                        Box(
                            modifier = Modifier
                                .size(40.dp)
                                .clip(CircleShape)
                                .background(LaterboxAccent),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = Icons.Default.Add,
                                contentDescription = null,
                                tint = LaterboxDarkSurface,
                                modifier = Modifier.size(22.dp)
                            )
                        }

                        Column {
                            Text(
                                text = "Save an item",
                                fontSize = 16.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color.White
                            )
                            Text(
                                text = "Paste a link or write a note...",
                                fontSize = 13.sp,
                                color = Color.White.copy(alpha = 0.7f)
                            )
                        }
                    }

                    Surface(
                        shape = RoundedCornerShape(10.dp),
                        color = Color.White.copy(alpha = 0.15f)
                    ) {
                        Text(
                            text = "+ New",
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Bold,
                            color = LaterboxAccent,
                            modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp)
                        )
                    }
                }
            }
        }

        // Summary Metric Cards (Inbox, Today, Starred)
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                SummaryMetricCard(
                    title = "Inbox",
                    value = inboxItems.size.toString(),
                    icon = Icons.Default.Inbox,
                    iconColor = LaterboxIndigo,
                    modifier = Modifier.weight(1f),
                    onClick = { onNavigateToTab(1) }
                )
                SummaryMetricCard(
                    title = "Today",
                    value = dueTodayItems.size.toString(),
                    icon = Icons.Default.CalendarToday,
                    iconColor = LaterboxAmber,
                    modifier = Modifier.weight(1f),
                    onClick = { onNavigateToTab(2) }
                )
                SummaryMetricCard(
                    title = "Starred",
                    value = starredItems.size.toString(),
                    icon = Icons.Default.Star,
                    iconColor = LaterboxEmerald,
                    modifier = Modifier.weight(1f),
                    onClick = { onNavigateToTab(3) }
                )
            }
        }

        // Returns Hub Quick Shortcuts
        item {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = "Returns Hub",
                        fontSize = 17.sp,
                        fontWeight = FontWeight.Bold,
                        color = LaterboxTextPrimary
                    )
                    Text(
                        text = "View All",
                        fontSize = 13.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = LaterboxIndigo,
                        modifier = Modifier.clickable { onNavigateToTab(2) }
                    )
                }

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    Surface(
                        modifier = Modifier
                            .weight(1f)
                            .clickable { onNavigateToTab(2) },
                        shape = RoundedCornerShape(14.dp),
                        color = LaterboxCard,
                        border = androidx.compose.foundation.BorderStroke(1.dp, LaterboxBorder)
                    ) {
                        Row(
                            modifier = Modifier.padding(14.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.Schedule,
                                contentDescription = null,
                                tint = LaterboxAmber,
                                modifier = Modifier.size(16.dp)
                            )
                            Column {
                                Text(text = "Today", fontSize = 13.sp, fontWeight = FontWeight.Bold, color = LaterboxTextPrimary)
                                Text(text = "${dueTodayItems.size} items", fontSize = 11.sp, color = LaterboxTextSecondary)
                            }
                        }
                    }

                    Surface(
                        modifier = Modifier
                            .weight(1f)
                            .clickable { onNavigateToTab(2) },
                        shape = RoundedCornerShape(14.dp),
                        color = LaterboxCard,
                        border = androidx.compose.foundation.BorderStroke(1.dp, LaterboxBorder)
                    ) {
                        Row(
                            modifier = Modifier.padding(14.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Icon(
                                imageVector = Icons.AutoMirrored.Filled.TrendingUp,
                                contentDescription = null,
                                tint = LaterboxIndigo,
                                modifier = Modifier.size(16.dp)
                            )
                            Column {
                                Text(text = "Upcoming", fontSize = 13.sp, fontWeight = FontWeight.Bold, color = LaterboxTextPrimary)
                                Text(text = "Scheduled", fontSize = 11.sp, color = LaterboxTextSecondary)
                            }
                        }
                    }
                }
            }
        }

        // Recent Items Section
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = "Recent Captures",
                    fontSize = 17.sp,
                    fontWeight = FontWeight.Bold,
                    color = LaterboxTextPrimary
                )
                if (items.isNotEmpty()) {
                    Text(
                        text = "${items.size} total",
                        fontSize = 12.sp,
                        color = LaterboxTextSecondary
                    )
                }
            }
        }

        if (recentItems.isEmpty()) {
            item {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = LaterboxCard),
                    border = androidx.compose.foundation.BorderStroke(1.dp, LaterboxBorder)
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(32.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.Inbox,
                            contentDescription = null,
                            tint = LaterboxTextSecondary,
                            modifier = Modifier.size(36.dp)
                        )
                        Text(
                            text = "No saved items yet",
                            fontSize = 15.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = LaterboxTextPrimary
                        )
                        Text(
                            text = "Tap '+ New' above to save your first link or note.",
                            fontSize = 13.sp,
                            color = LaterboxTextSecondary
                        )
                    }
                }
            }
        } else {
            items(recentItems, key = { it.id }) { item ->
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
