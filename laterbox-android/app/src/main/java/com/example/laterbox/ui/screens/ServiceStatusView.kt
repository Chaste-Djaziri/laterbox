package com.example.laterbox.ui.screens

import android.content.Intent
import android.net.Uri
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.OpenInNew
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.ShowChart
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material.icons.filled.WifiOff
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.laterbox.data.api.LaterBoxApiService
import com.example.laterbox.data.api.MonitorUptimeHistory
import com.example.laterbox.data.api.ServiceMonitorStatus
import com.example.laterbox.data.api.ServiceStatusSnapshot
import com.example.laterbox.data.api.ServiceUptimeHistory
import com.example.laterbox.data.api.UptimeBucket
import com.example.laterbox.theme.LaterboxAccent
import com.example.laterbox.theme.LaterboxBorder
import com.example.laterbox.theme.LaterboxCard
import com.example.laterbox.theme.LaterboxDarkSurface
import com.example.laterbox.theme.LaterboxEmerald
import com.example.laterbox.theme.LaterboxTextPrimary
import com.example.laterbox.theme.LaterboxTextSecondary
import kotlinx.coroutines.launch
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit
import java.util.Locale
import kotlin.math.roundToInt

enum class HistoryRangeSelection(val label: String, val days: Long) {
    DAY("Day", 1),
    WEEK("Week", 7),
    MONTH("Month", 30),
    CUSTOM("Custom", 7)
}

@Composable
fun ServiceStatusView(
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()

    var snapshot by remember { mutableStateOf<ServiceStatusSnapshot?>(null) }
    var history by remember { mutableStateOf<ServiceUptimeHistory?>(null) }
    var selectedRange by remember { mutableStateOf(HistoryRangeSelection.WEEK) }
    var isRefreshing by remember { mutableStateOf(false) }
    var isLoadingHistory by remember { mutableStateOf(false) }
    var hasError by remember { mutableStateOf(false) }
    var historyError by remember { mutableStateOf(false) }

    fun refreshHistory(currentSnapshot: ServiceStatusSnapshot?) {
        if (currentSnapshot == null) return
        scope.launch {
            isLoadingHistory = true
            historyError = false
            try {
                val now = Instant.now()
                val from = now.minus(selectedRange.days, ChronoUnit.DAYS)
                val timeZone = ZoneId.systemDefault().id
                val result = LaterBoxApiService.fetchUptimeHistory(
                    from = from.toString(),
                    to = now.toString(),
                    timeZone = timeZone
                )
                history = result
            } catch (_: Exception) {
                historyError = true
            } finally {
                isLoadingHistory = false
            }
        }
    }

    fun refresh() {
        if (isRefreshing) return
        scope.launch {
            isRefreshing = true
            hasError = false
            try {
                val fresh = LaterBoxApiService.fetchServiceStatusDetails()
                snapshot = fresh
                refreshHistory(fresh)
            } catch (_: Exception) {
                hasError = true
            } finally {
                isRefreshing = false
            }
        }
    }

    LaunchedEffect(Unit) {
        refresh()
    }

    LaunchedEffect(selectedRange) {
        if (snapshot != null) {
            refreshHistory(snapshot)
        }
    }

    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 20.dp, vertical = 16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Refresh Header / Action
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column {
                    Text(
                        text = "BetterStack System Health",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        color = LaterboxTextSecondary,
                        letterSpacing = 0.5.sp
                    )
                }

                IconButton(
                    onClick = { refresh() },
                    enabled = !isRefreshing
                ) {
                    if (isRefreshing) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(18.dp),
                            strokeWidth = 2.dp,
                            color = LaterboxTextPrimary
                        )
                    } else {
                        Icon(
                            imageVector = Icons.Default.Refresh,
                            contentDescription = "Refresh service status",
                            tint = LaterboxTextPrimary,
                            modifier = Modifier.size(20.dp)
                        )
                    }
                }
            }
        }

        // Connection / Error Banner
        if (hasError) {
            item {
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    color = Color(0xFFFEF2F2),
                    border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFFCA5A5))
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Icon(Icons.Default.WifiOff, contentDescription = null, tint = Color(0xFFDC2626), modifier = Modifier.size(20.dp))
                            Text(
                                "Couldn't refresh service status",
                                fontSize = 14.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color(0xFF991B1B)
                            )
                        }
                        Text(
                            text = if (snapshot == null) "Check your connection and try again." else "The last available results are shown below. Check your connection and try again.",
                            fontSize = 12.sp,
                            color = Color(0xFFB91C1C)
                        )
                        Button(
                            onClick = { refresh() },
                            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFDC2626), contentColor = Color.White),
                            shape = RoundedCornerShape(10.dp),
                            contentPadding = PaddingValues(horizontal = 14.dp, vertical = 6.dp)
                        ) {
                            Text("Try again", fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                        }
                    }
                }
            }
        }

        // Overview Status Card (matching iOS large icon + headline)
        snapshot?.let { snap ->
            item {
                val isOp = snap.status == "operational" || snap.status == "up"
                val statusColor = statusColor(snap.status)

                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(18.dp),
                    color = LaterboxCard,
                    border = androidx.compose.foundation.BorderStroke(1.dp, LaterboxBorder)
                ) {
                    Column(
                        modifier = Modifier.padding(18.dp),
                        verticalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(14.dp)
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(46.dp)
                                    .background(statusColor.copy(alpha = 0.12f), CircleShape),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(
                                    imageVector = if (isOp) Icons.Default.CheckCircle else Icons.Default.ShowChart,
                                    contentDescription = null,
                                    tint = statusColor,
                                    modifier = Modifier.size(26.dp)
                                )
                            }

                            Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                                Text(
                                    text = snap.label,
                                    fontSize = 16.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = LaterboxTextPrimary
                                )
                                Text(
                                    text = "${snap.monitors.size} services monitored",
                                    fontSize = 13.sp,
                                    color = LaterboxTextSecondary
                                )
                            }
                        }

                        if (snap.timestamp.isNotBlank()) {
                            val formattedDate = formatTimestamp(snap.timestamp)
                            Text(
                                text = "Updated $formattedDate",
                                fontSize = 11.sp,
                                color = LaterboxTextSecondary
                            )
                        }
                    }
                }
            }

            // Uptime History Filter & Bars Section
            item {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text(
                        text = "UPTIME HISTORY",
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Black,
                        color = Color(0xFF9E9B92),
                        letterSpacing = 1.sp,
                        modifier = Modifier.padding(horizontal = 4.dp)
                    )

                    Surface(
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(18.dp),
                        color = LaterboxCard,
                        border = androidx.compose.foundation.BorderStroke(1.dp, LaterboxBorder)
                    ) {
                        Column(
                            modifier = Modifier.padding(16.dp),
                            verticalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            // Filter Tabs: Day, Week, Month
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                listOf(HistoryRangeSelection.DAY, HistoryRangeSelection.WEEK, HistoryRangeSelection.MONTH).forEach { option ->
                                    val isSelected = selectedRange == option
                                    FilterChip(
                                        selected = isSelected,
                                        onClick = { selectedRange = option },
                                        label = {
                                            Text(
                                                text = option.label,
                                                fontSize = 12.sp,
                                                fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium
                                            )
                                        },
                                        colors = FilterChipDefaults.filterChipColors(
                                            selectedContainerColor = LaterboxDarkSurface,
                                            selectedLabelColor = Color.White,
                                            containerColor = LaterboxBorder.copy(alpha = 0.2f),
                                            labelColor = LaterboxTextSecondary
                                        ),
                                        shape = RoundedCornerShape(10.dp),
                                        border = null
                                    )
                                }
                            }

                            if (isLoadingHistory) {
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .padding(vertical = 12.dp),
                                    horizontalArrangement = Arrangement.Center,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    CircularProgressIndicator(modifier = Modifier.size(16.dp), strokeWidth = 2.dp, color = LaterboxTextSecondary)
                                    Spacer(Modifier.width(8.dp))
                                    Text("Loading uptime history…", fontSize = 12.sp, color = LaterboxTextSecondary)
                                }
                            } else if (historyError) {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                                ) {
                                    Icon(Icons.Default.Warning, contentDescription = null, tint = Color(0xFFF59E0B), modifier = Modifier.size(16.dp))
                                    Text("Uptime history is temporarily unavailable.", fontSize = 12.sp, color = LaterboxTextSecondary)
                                }
                            } else if (history != null) {
                                val h = history!!
                                val fromStr = formatShortDate(h.from)
                                val toStr = formatShortDate(h.to)
                                val unitStr = if (h.unit == "hour") "Hourly" else "Daily"
                                Text(
                                    text = "$fromStr – $toStr • $unitStr bars",
                                    fontSize = 12.sp,
                                    color = LaterboxTextSecondary
                                )
                            }
                        }
                    }
                }
            }

            // All Monitors List Section
            item {
                Text(
                    text = "ALL MONITORS",
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Black,
                    color = Color(0xFF9E9B92),
                    letterSpacing = 1.sp,
                    modifier = Modifier.padding(horizontal = 4.dp, vertical = 2.dp)
                )
            }

            if (snap.monitors.isEmpty()) {
                item {
                    Text(
                        text = "No monitors are available yet.",
                        fontSize = 13.sp,
                        color = LaterboxTextSecondary,
                        modifier = Modifier.padding(horizontal = 4.dp)
                    )
                }
            }

            items(snap.monitors) { monitor ->
                val monitorHistory = history?.monitors?.find { it.id == monitor.id }
                MonitorCard(monitor = monitor, history = monitorHistory)
            }
        } ?: run {
            if (isRefreshing) {
                item {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 40.dp),
                        horizontalArrangement = Arrangement.Center,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        CircularProgressIndicator(modifier = Modifier.size(24.dp), strokeWidth = 2.5.dp, color = LaterboxDarkSurface)
                        Spacer(Modifier.width(10.dp))
                        Text("Loading monitors…", fontSize = 14.sp, color = LaterboxTextSecondary)
                    }
                }
            }
        }

        // Public Status Page Link Card
        item {
            Surface(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(16.dp))
                    .clickable {
                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("https://status.laterbox.dev"))
                        context.startActivity(intent)
                    },
                shape = RoundedCornerShape(16.dp),
                color = LaterboxCard,
                border = androidx.compose.foundation.BorderStroke(1.dp, LaterboxBorder)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.OpenInNew,
                            contentDescription = null,
                            tint = LaterboxTextPrimary,
                            modifier = Modifier.size(18.dp)
                        )
                        Text(
                            text = "Open public status page",
                            fontSize = 14.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = LaterboxTextPrimary
                        )
                    }

                    Text(
                        text = "status.laterbox.dev",
                        fontSize = 12.sp,
                        color = LaterboxTextSecondary
                    )
                }
            }

            Spacer(Modifier.height(4.dp))
            Text(
                text = "Service health provided by Better Stack. Pull down to refresh.",
                fontSize = 11.sp,
                color = LaterboxTextSecondary,
                modifier = Modifier.padding(horizontal = 4.dp)
            )
        }
    }
}

@Composable
private fun MonitorCard(
    monitor: ServiceMonitorStatus,
    history: MonitorUptimeHistory?
) {
    val statusColor = statusColor(monitor.status)

    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        color = LaterboxCard,
        border = androidx.compose.foundation.BorderStroke(1.dp, LaterboxBorder)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.Top,
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                // Colored dot
                Box(
                    modifier = Modifier
                        .padding(top = 4.dp)
                        .size(10.dp)
                        .clip(CircleShape)
                        .background(statusColor)
                )

                Column(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Text(
                        text = monitor.name,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Bold,
                        color = LaterboxTextPrimary,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )

                    // Status Pill
                    Surface(
                        shape = CircleShape,
                        color = statusColor.copy(alpha = 0.12f)
                    ) {
                        Text(
                            text = monitor.label,
                            fontSize = 11.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = statusColor,
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp)
                        )
                    }

                    if (monitor.lastCheckedAt != null) {
                        val checkedFormatted = formatTimestamp(monitor.lastCheckedAt)
                        Text(
                            text = "Last check: $checkedFormatted",
                            fontSize = 11.sp,
                            color = LaterboxTextSecondary
                        )
                    }

                    if (monitor.checkFrequency != null && monitor.checkFrequency > 0) {
                        val freqText = if (monitor.checkFrequency % 60 == 0) {
                            "Checks every ${monitor.checkFrequency / 60} min"
                        } else {
                            "Checks every ${monitor.checkFrequency} sec"
                        }
                        Text(
                            text = freqText,
                            fontSize = 11.sp,
                            color = LaterboxTextSecondary
                        )
                    }
                }
            }

            // History Availability & Downtime Row + Visual Bars
            if (history != null) {
                HorizontalDivider(color = LaterboxBorder.copy(alpha = 0.6f), thickness = 0.5.dp)

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    val availText = history.availability?.let { "${it.roundToInt()}% uptime" } ?: "Uptime unavailable"
                    Text(
                        text = availText,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        color = LaterboxTextPrimary
                    )

                    if (history.downtimeSeconds != null && history.downtimeSeconds > 0) {
                        Text(
                            text = "${formatDowntime(history.downtimeSeconds)} downtime",
                            fontSize = 11.sp,
                            color = LaterboxTextSecondary
                        )
                    }
                }

                // Bar charts
                if (history.buckets.isNotEmpty()) {
                    UptimeBars(buckets = history.buckets)
                }
            }
        }
    }
}

@Composable
private fun UptimeBars(buckets: List<UptimeBucket>) {
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(2.dp),
            verticalAlignment = Alignment.Bottom
        ) {
            buckets.forEach { bucket ->
                val barColor = bucketColor(bucket.availability)
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .height(28.dp)
                        .clip(RoundedCornerShape(2.dp))
                        .background(barColor)
                )
            }
        }

        val firstDate = buckets.firstOrNull()?.start?.let { formatShortDate(it) }
        val lastDate = buckets.lastOrNull()?.end?.let { formatShortDate(it) }
        if (firstDate != null && lastDate != null) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(firstDate, fontSize = 10.sp, color = LaterboxTextSecondary)
                Text(lastDate, fontSize = 10.sp, color = LaterboxTextSecondary)
            }
        }
    }
}

private fun bucketColor(availability: Double?): Color {
    if (availability == null) return Color(0xFFD1D5DB)
    return when {
        availability >= 99.9 -> Color(0xFF10B981) // Green
        availability >= 99.0 -> Color(0xFFF59E0B) // Amber
        else -> Color(0xFFEF4444) // Red
    }
}

private fun statusColor(status: String): Color {
    return when (status.lowercase(Locale.ROOT)) {
        "up", "operational" -> Color(0xFF10B981)
        "down", "outage" -> Color(0xFFEF4444)
        "validating", "degraded", "maintenance" -> Color(0xFFF59E0B)
        else -> Color(0xFF9E9B92)
    }
}

private fun formatDowntime(seconds: Double): String {
    val sec = seconds.toInt()
    if (sec < 60) return "${sec}s"
    val minutes = sec / 60
    if (minutes < 60) return "${minutes}m"
    val hours = minutes / 60
    val remMin = minutes % 60
    return if (remMin == 0) "${hours}h" else "${hours}h ${remMin}m"
}

private fun formatTimestamp(isoString: String): String {
    return try {
        val instant = Instant.parse(isoString)
        val zone = ZoneId.systemDefault()
        val formatter = DateTimeFormatter.ofPattern("MMM d, h:mm a", Locale.getDefault())
        instant.atZone(zone).format(formatter)
    } catch (_: Exception) {
        isoString
    }
}

private fun formatShortDate(isoString: String): String {
    return try {
        val instant = Instant.parse(isoString)
        val zone = ZoneId.systemDefault()
        val formatter = DateTimeFormatter.ofPattern("MMM d", Locale.getDefault())
        instant.atZone(zone).format(formatter)
    } catch (_: Exception) {
        isoString
    }
}
