package com.example.laterbox.ui.components

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.OpenInBrowser
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.outlined.Schedule
import androidx.compose.material.icons.outlined.StarBorder
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
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
import com.example.laterbox.data.local.ItemEntity
import com.example.laterbox.theme.LaterboxAccent
import com.example.laterbox.theme.LaterboxAmber
import com.example.laterbox.theme.LaterboxBorder
import com.example.laterbox.theme.LaterboxCard
import com.example.laterbox.theme.LaterboxDarkSurface
import com.example.laterbox.theme.LaterboxEmerald
import com.example.laterbox.theme.LaterboxRose
import com.example.laterbox.theme.LaterboxTextPrimary
import com.example.laterbox.theme.LaterboxTextSecondary
import com.example.laterbox.theme.LaterboxTextTertiary
import java.net.URI

@Composable
fun ItemCardView(
    item: ItemEntity,
    onToggleFavorite: () -> Unit,
    onMarkDone: () -> Unit,
    onScheduleReturn: (String?) -> Unit,
    onDelete: () -> Unit,
    modifier: Modifier = Modifier,
    onClick: (() -> Unit)? = null
) {
    val context = LocalContext.current
    var showMenu by remember { mutableStateOf(false) }

    val domain = remember(item.url) {
        if (!item.url.isNullOrEmpty()) {
            try {
                val uri = URI(item.url)
                val host = uri.host ?: ""
                host.removePrefix("www.")
            } catch (e: Exception) {
                ""
            }
        } else {
            ""
        }
    }

    LaterboxCard(
        modifier = modifier,
        onClick = onClick ?: {
            if (!item.url.isNullOrEmpty()) {
                openBrowser(context, item.url)
            }
        },
        backgroundColor = LaterboxCard,
        borderColor = LaterboxBorder
    ) {
        Column(
            modifier = Modifier.fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            // Top Row: Domain / Type + Favorite + Menu
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    TypeBadge(type = item.type)

                    if (domain.isNotEmpty()) {
                        Text(
                            text = domain,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = LaterboxTextPrimary,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    }
                }

                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    IconButton(
                        onClick = onToggleFavorite,
                        modifier = Modifier.size(32.dp)
                    ) {
                        Icon(
                            imageVector = if (item.favorite) Icons.Default.Star else Icons.Outlined.StarBorder,
                            contentDescription = if (item.favorite) "Starred" else "Star",
                            tint = if (item.favorite) LaterboxAmber else LaterboxTextTertiary,
                            modifier = Modifier.size(18.dp)
                        )
                    }

                    Box {
                        IconButton(
                            onClick = { showMenu = true },
                            modifier = Modifier.size(32.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.MoreVert,
                                contentDescription = "More Options",
                                tint = LaterboxTextSecondary,
                                modifier = Modifier.size(18.dp)
                            )
                        }

                        DropdownMenu(
                            expanded = showMenu,
                            onDismissRequest = { showMenu = false }
                        ) {
                            if (!item.url.isNullOrEmpty()) {
                                DropdownMenuItem(
                                    text = { Text("Open in Browser") },
                                    leadingIcon = { Icon(Icons.Default.OpenInBrowser, null) },
                                    onClick = {
                                        showMenu = false
                                        openBrowser(context, item.url)
                                    }
                                )
                            }
                            DropdownMenuItem(
                                text = { Text(if (item.status == "done") "Move to Inbox" else "Mark as Done") },
                                leadingIcon = { Icon(Icons.Default.CheckCircle, null) },
                                onClick = {
                                    showMenu = false
                                    onMarkDone()
                                }
                            )
                            DropdownMenuItem(
                                text = { Text("Schedule for Tomorrow") },
                                leadingIcon = { Icon(Icons.Default.Schedule, null) },
                                onClick = {
                                    showMenu = false
                                    onScheduleReturn("tomorrow")
                                }
                            )
                            DropdownMenuItem(
                                text = { Text("Schedule for Next Week") },
                                leadingIcon = { Icon(Icons.Outlined.Schedule, null) },
                                onClick = {
                                    showMenu = false
                                    onScheduleReturn("next_week")
                                }
                            )
                            DropdownMenuItem(
                                text = { Text("Delete", color = LaterboxRose) },
                                leadingIcon = { Icon(Icons.Default.Delete, null, tint = LaterboxRose) },
                                onClick = {
                                    showMenu = false
                                    onDelete()
                                }
                            )
                        }
                    }
                }
            }

            // Title (Bold High-Contrast)
            Text(
                text = item.title ?: "Untitled",
                fontSize = 16.sp,
                fontWeight = FontWeight.Bold,
                color = LaterboxTextPrimary,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
                lineHeight = 22.sp
            )

            // Optional text note content
            if (!item.textContent.isNullOrEmpty()) {
                Surface(
                    shape = RoundedCornerShape(10.dp),
                    color = Color.Black.copy(alpha = 0.03f),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(
                        text = item.textContent,
                        fontSize = 13.sp,
                        color = LaterboxTextSecondary,
                        maxLines = 3,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.padding(10.dp)
                    )
                }
            }

            // Bottom action row: Return tag + quick actions
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                if (!item.returnAt.isNullOrEmpty()) {
                    Surface(
                        shape = RoundedCornerShape(6.dp),
                        color = LaterboxAmber.copy(alpha = 0.15f),
                        contentColor = LaterboxAmber
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(4.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.Schedule,
                                contentDescription = null,
                                modifier = Modifier.size(11.dp)
                            )
                            Text(
                                text = "Return: ${item.returnAt.take(10)}",
                                fontSize = 11.sp,
                                fontWeight = FontWeight.SemiBold
                            )
                        }
                    }
                } else {
                    Spacer(modifier = Modifier.width(1.dp))
                }

                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Quick Action: Return / Reschedule
                    Box(
                        modifier = Modifier
                            .clip(CircleShape)
                            .background(Color.Black.copy(alpha = 0.04f))
                            .clickable { onScheduleReturn("tomorrow") }
                            .padding(6.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.Schedule,
                            contentDescription = "Schedule Return",
                            tint = LaterboxTextSecondary,
                            modifier = Modifier.size(15.dp)
                        )
                    }

                    // Quick Action: Mark Done
                    Box(
                        modifier = Modifier
                            .clip(CircleShape)
                            .background(if (item.status == "done") LaterboxEmerald.copy(alpha = 0.15f) else Color.Black.copy(alpha = 0.04f))
                            .clickable { onMarkDone() }
                            .padding(6.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.CheckCircle,
                            contentDescription = "Done",
                            tint = if (item.status == "done") LaterboxEmerald else LaterboxTextSecondary,
                            modifier = Modifier.size(15.dp)
                        )
                    }
                }
            }
        }
    }
}

private fun openBrowser(context: Context, url: String) {
    try {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
    } catch (e: Exception) {
        // Fallback
    }
}
