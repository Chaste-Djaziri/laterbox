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
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.Folder
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
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
import com.example.laterbox.theme.LaterboxEmerald
import com.example.laterbox.theme.LaterboxIndigo
import com.example.laterbox.theme.LaterboxTextPrimary
import com.example.laterbox.theme.LaterboxTextSecondary
import com.example.laterbox.ui.components.ItemCardView
import kotlinx.coroutines.launch
import java.time.LocalDate

@Composable
fun LibraryScreen(
    repository: DataRepository,
    modifier: Modifier = Modifier
) {
    val items by repository.items.collectAsState(initial = emptyList())
    val collections by repository.collections.collectAsState(initial = emptyList())
    val scope = rememberCoroutineScope()

    var searchQuery by remember { mutableStateOf("") }
    var selectedType by remember { mutableStateOf("all") }
    var showAddCollectionDialog by remember { mutableStateOf(false) }
    var newCollectionName by remember { mutableStateOf("") }

    val formatTypes = listOf(
        "all" to "All",
        "link" to "Links",
        "article" to "Articles",
        "video" to "Videos",
        "music" to "Music",
        "repository" to "Code",
        "note" to "Notes"
    )

    val filteredItems = items.filter { item ->
        val matchesSearch = if (searchQuery.isBlank()) {
            true
        } else {
            val q = searchQuery.trim().lowercase()
            (item.title?.lowercase()?.contains(q) == true) ||
            (item.url?.lowercase()?.contains(q) == true) ||
            (item.textContent?.lowercase()?.contains(q) == true)
        }

        val matchesType = if (selectedType == "all") {
            true
        } else {
            item.type.equals(selectedType, ignoreCase = true)
        }

        matchesSearch && matchesType
    }

    if (showAddCollectionDialog) {
        AlertDialog(
            onDismissRequest = { showAddCollectionDialog = false },
            title = { Text("New Collection", fontWeight = FontWeight.Bold) },
            text = {
                OutlinedTextField(
                    value = newCollectionName,
                    onValueChange = { newCollectionName = it },
                    placeholder = { Text("Collection name (e.g. Research, Tech)") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
            },
            confirmButton = {
                Button(
                    onClick = {
                        if (newCollectionName.isNotBlank()) {
                            scope.launch {
                                repository.addCollection(newCollectionName.trim())
                                newCollectionName = ""
                                showAddCollectionDialog = false
                            }
                        }
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = LaterboxDarkSurface)
                ) {
                    Text("Create")
                }
            },
            dismissButton = {
                TextButton(onClick = { showAddCollectionDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }

    LazyColumn(
        modifier = modifier
            .fillMaxSize()
            .background(LaterboxBg),
        contentPadding = PaddingValues(horizontal = 20.dp, vertical = 20.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Title Header with Brand Icon
        item {
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
                    text = "Library",
                    fontSize = 24.sp,
                    fontWeight = FontWeight.Bold,
                    color = LaterboxTextPrimary
                )
            }
        }

        // Search Bar
        item {
            OutlinedTextField(
                value = searchQuery,
                onValueChange = { searchQuery = it },
                placeholder = { Text("Search title, links, or notes...") },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(14.dp),
                leadingIcon = {
                    Icon(
                        imageVector = Icons.Default.Search,
                        contentDescription = "Search",
                        tint = LaterboxTextSecondary
                    )
                },
                trailingIcon = {
                    if (searchQuery.isNotEmpty()) {
                        IconButton(onClick = { searchQuery = "" }) {
                            Icon(Icons.Default.Clear, contentDescription = "Clear", tint = LaterboxTextSecondary)
                        }
                    }
                },
                singleLine = true,
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = LaterboxDarkSurface,
                    unfocusedBorderColor = LaterboxBorder,
                    focusedContainerColor = LaterboxCard,
                    unfocusedContainerColor = LaterboxCard
                )
            )
        }

        // Collections Row
        item {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = "Collections",
                        fontSize = 15.sp,
                        fontWeight = FontWeight.Bold,
                        color = LaterboxTextPrimary
                    )
                    Text(
                        text = "+ Add",
                        fontSize = 13.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = LaterboxIndigo,
                        modifier = Modifier.clickable { showAddCollectionDialog = true }
                    )
                }

                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    // Create collection button
                    Surface(
                        shape = RoundedCornerShape(12.dp),
                        color = LaterboxCard,
                        border = androidx.compose.foundation.BorderStroke(1.dp, LaterboxBorder),
                        modifier = Modifier.clickable { showAddCollectionDialog = true }
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(6.dp)
                        ) {
                            Icon(Icons.Default.Add, null, modifier = Modifier.size(16.dp), tint = LaterboxIndigo)
                            Text("New", fontSize = 12.sp, fontWeight = FontWeight.SemiBold, color = LaterboxIndigo)
                        }
                    }

                    collections.forEach { coll ->
                        Surface(
                            shape = RoundedCornerShape(12.dp),
                            color = LaterboxCard,
                            border = androidx.compose.foundation.BorderStroke(1.dp, LaterboxBorder)
                        ) {
                            Row(
                                modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(6.dp)
                            ) {
                                Icon(Icons.Default.Folder, null, modifier = Modifier.size(16.dp), tint = LaterboxAmber)
                                Text(coll.name, fontSize = 12.sp, fontWeight = FontWeight.Medium, color = LaterboxTextPrimary)
                            }
                        }
                    }
                }
            }
        }

        // Format Filter Chips
        item {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState()),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                formatTypes.forEach { (key, label) ->
                    val isSelected = selectedType == key
                    Surface(
                        shape = RoundedCornerShape(12.dp),
                        color = if (isSelected) LaterboxDarkSurface else LaterboxCard,
                        contentColor = if (isSelected) Color.White else LaterboxTextPrimary,
                        border = if (!isSelected) androidx.compose.foundation.BorderStroke(1.dp, LaterboxBorder) else null,
                        modifier = Modifier.clickable { selectedType = key }
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

        // Results Count
        item {
            Text(
                text = "${filteredItems.size} items",
                fontSize = 12.sp,
                color = LaterboxTextSecondary
            )
        }

        // Items list
        if (filteredItems.isEmpty()) {
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
                        verticalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        Text(
                            text = "No matching items",
                            fontSize = 15.sp,
                            fontWeight = FontWeight.Bold,
                            color = LaterboxTextPrimary
                        )
                        Text(
                            text = "Try adjusting your search query or format filter.",
                            fontSize = 13.sp,
                            color = LaterboxTextSecondary
                        )
                    }
                }
            }
        } else {
            items(filteredItems, key = { it.id }) { item ->
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
