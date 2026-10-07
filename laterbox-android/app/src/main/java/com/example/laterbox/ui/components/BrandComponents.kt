package com.example.laterbox.ui.components

import androidx.compose.foundation.BorderStroke
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Article
import androidx.compose.material.icons.filled.Code
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Image
import androidx.compose.material.icons.filled.Link
import androidx.compose.material.icons.filled.MusicNote
import androidx.compose.material.icons.filled.PictureAsPdf
import androidx.compose.material.icons.filled.Slideshow
import androidx.compose.material.icons.filled.TableChart
import androidx.compose.material.icons.filled.Videocam
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.laterbox.theme.LaterboxAmber
import com.example.laterbox.theme.LaterboxBorder
import com.example.laterbox.theme.LaterboxCard
import com.example.laterbox.theme.LaterboxEmerald
import com.example.laterbox.theme.LaterboxIndigo
import com.example.laterbox.theme.LaterboxRose
import com.example.laterbox.theme.LaterboxSky
import com.example.laterbox.theme.LaterboxTextPrimary
import com.example.laterbox.theme.LaterboxTextSecondary

@Composable
fun LaterboxCard(
    modifier: Modifier = Modifier,
    onClick: (() -> Unit)? = null,
    backgroundColor: Color = LaterboxCard,
    borderColor: Color = LaterboxBorder,
    content: @Composable () -> Unit
) {
    Card(
        modifier = modifier
            .fillMaxWidth()
            .then(if (onClick != null) Modifier.clickable { onClick() } else Modifier),
        shape = RoundedCornerShape(18.dp),
        colors = CardDefaults.cardColors(containerColor = backgroundColor),
        border = BorderStroke(1.dp, borderColor),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Box(modifier = Modifier.padding(16.dp)) {
            content()
        }
    }
}

@Composable
fun TypeBadge(type: String, modifier: Modifier = Modifier) {
    val badgeInfo: Triple<ImageVector, Color, String> = when (type.lowercase()) {
        "pdf" -> Triple(Icons.Default.PictureAsPdf, LaterboxRose, "PDF")
        "ppt", "presentation", "slides" -> Triple(Icons.Default.Slideshow, LaterboxAmber, "Presentation")
        "spreadsheet", "sheet", "csv" -> Triple(Icons.Default.TableChart, LaterboxEmerald, "Spreadsheet")
        "doc", "document" -> Triple(Icons.AutoMirrored.Filled.Article, LaterboxSky, "Document")
        "video" -> Triple(Icons.Default.Videocam, Color(0xFF9333EA), "Video")
        "music", "audio" -> Triple(Icons.Default.MusicNote, LaterboxIndigo, "Music")
        "article" -> Triple(Icons.AutoMirrored.Filled.Article, LaterboxSky, "Article")
        "image" -> Triple(Icons.Default.Image, Color(0xFF0D9488), "Image")
        "repository", "repo", "github" -> Triple(Icons.Default.Code, LaterboxEmerald, "Code")
        "note" -> Triple(Icons.Default.Description, LaterboxAmber, "Note")
        else -> Triple(Icons.Default.Link, LaterboxTextSecondary, "Link")
    }
    val (icon, color, label) = badgeInfo

    Surface(
        modifier = modifier,
        shape = RoundedCornerShape(8.dp),
        color = color.copy(alpha = 0.12f),
        contentColor = color
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 7.dp, vertical = 3.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                modifier = Modifier.size(12.dp)
            )
            Text(
                text = label,
                fontSize = 11.sp,
                fontWeight = FontWeight.SemiBold
            )
        }
    }
}

@Composable
fun SummaryMetricCard(
    title: String,
    value: String,
    icon: ImageVector,
    iconColor: Color = LaterboxIndigo,
    modifier: Modifier = Modifier,
    onClick: (() -> Unit)? = null
) {
    Card(
        modifier = modifier.then(if (onClick != null) Modifier.clickable { onClick() } else Modifier),
        shape = RoundedCornerShape(18.dp),
        colors = CardDefaults.cardColors(containerColor = LaterboxCard),
        border = BorderStroke(1.dp, LaterboxBorder),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(
                    text = title,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Medium,
                    color = LaterboxTextSecondary
                )
                Box(
                    modifier = Modifier
                        .size(24.dp)
                        .clip(CircleShape)
                        .background(iconColor.copy(alpha = 0.12f)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = icon,
                        contentDescription = null,
                        tint = iconColor,
                        modifier = Modifier.size(13.dp)
                    )
                }
            }
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = value,
                fontSize = 24.sp,
                fontWeight = FontWeight.Bold,
                color = LaterboxTextPrimary
            )
        }
    }
}

@Composable
fun SystemStatusIndicator(
    isOperational: Boolean,
    label: String,
    modifier: Modifier = Modifier,
    onClick: (() -> Unit)? = null
) {
    val indicatorColor = if (isOperational) LaterboxEmerald else LaterboxAmber

    Surface(
        modifier = modifier.then(if (onClick != null) Modifier.clickable { onClick() } else Modifier),
        shape = RoundedCornerShape(12.dp),
        color = LaterboxCard,
        border = BorderStroke(1.dp, LaterboxBorder)
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 9.dp, vertical = 5.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            Box(
                modifier = Modifier
                    .size(7.dp)
                    .clip(CircleShape)
                    .background(indicatorColor)
            )
            Text(
                text = label,
                fontSize = 11.sp,
                fontWeight = FontWeight.SemiBold,
                color = LaterboxTextSecondary
            )
        }
    }
}
