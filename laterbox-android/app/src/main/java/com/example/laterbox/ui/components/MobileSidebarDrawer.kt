package com.example.laterbox.ui.components

import androidx.activity.compose.BackHandler
import androidx.compose.animation.*
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.*
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.automirrored.filled.Label
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.zIndex
import com.example.laterbox.R
import com.example.laterbox.data.local.CollectionEntity
import com.example.laterbox.data.local.ItemEntity
import com.example.laterbox.theme.LaterboxBg
import com.example.laterbox.theme.LaterboxBorder
import com.example.laterbox.theme.LaterboxTextPrimary
import com.example.laterbox.theme.LaterboxTextSecondary
import java.time.Instant
import java.time.ZoneId

enum class MailboxViewType(val title: String) {
    INBOX("Inbox"),
    TODAY("Today"),
    SCHEDULED("Scheduled"),
    SOMEDAY("Someday"),
    STARRED("Starred"),
    KEPT("Kept"),
    ARCHIVED("Archived"),
    TRASH("Recently Deleted")
}

@Composable
fun MobileSidebarDrawer(
    isOpen: Boolean,
    onDismiss: () -> Unit,
    activeMailbox: MailboxViewType = MailboxViewType.INBOX,
    activeCollection: String? = null,
    allItems: List<ItemEntity>,
    collections: List<CollectionEntity>,
    isPro: Boolean = false,
    userEmail: String? = null,
    onSelectMailbox: (MailboxViewType) -> Unit = {},
    onSelectCollection: (String) -> Unit = {},
    onCreateCollection: (String) -> Unit = {},
    onEditCollection: (String, String) -> Unit = { _, _ -> },
    onDeleteCollection: (String) -> Unit = {},
    onOpenSaveItem: () -> Unit = {},
    onOpenPlans: () -> Unit = {},
    onOpenSettings: () -> Unit = {}
) {
    BackHandler(enabled = isOpen) {
        onDismiss()
    }

    val configuration = LocalConfiguration.current
    val screenWidth = configuration.screenWidthDp.dp
    val drawerWidth = (screenWidth * 0.82f).coerceAtMost(310.dp)

    // Calculate live counts matching iOS and web logic
    val inboxCount = remember(allItems) {
        allItems.count { it.status == "inbox" && it.deletedAt == null }
    }
    val starredCount = remember(allItems) {
        allItems.count { it.favorite && it.deletedAt == null && it.status != "deleted" }
    }
    val keptCount = remember(allItems) {
        allItems.count { it.deletedAt == null && (it.status == "saved" || it.status == "done") }
    }
    val archivedCount = remember(allItems) {
        allItems.count { it.deletedAt == null && it.status == "archived" }
    }
    val trashCount = remember(allItems) {
        allItems.count { it.deletedAt != null || it.status == "deleted" }
    }
    val todayCount = remember(allItems) {
        val now = Instant.now()
        val endOfToday = now.atZone(ZoneId.systemDefault()).toLocalDate().plusDays(1).atStartOfDay(ZoneId.systemDefault()).toInstant()
        allItems.count {
            it.deletedAt == null && it.status == "deferred" &&
                it.returnAt != null && runCatching { Instant.parse(it.returnAt) <= endOfToday }.getOrDefault(false)
        }
    }
    val upcomingCount = remember(allItems) {
        val now = Instant.now()
        val endOfToday = now.atZone(ZoneId.systemDefault()).toLocalDate().plusDays(1).atStartOfDay(ZoneId.systemDefault()).toInstant()
        allItems.count {
            it.deletedAt == null && it.status == "deferred" &&
                it.returnAt != null && runCatching { Instant.parse(it.returnAt) > endOfToday }.getOrDefault(false)
        }
    }
    val somedayCount = remember(allItems) {
        allItems.count { it.deletedAt == null && it.status == "deferred" && it.returnAt == null }
    }

    fun collectionCount(name: String): Int {
        return allItems.count {
            it.deletedAt == null && it.status != "deleted" &&
                (it.category.equals(name, ignoreCase = true) ||
                    collections.find { c -> c.id == it.collectionId }?.name?.equals(name, ignoreCase = true) == true)
        }
    }

    var isCollectionsExpanded by remember { mutableStateOf(true) }
    var isCreatingCollection by remember { mutableStateOf(false) }
    var newCollectionName by remember { mutableStateOf("") }
    var collectionForActions by remember { mutableStateOf<CollectionEntity?>(null) }
    var collectionToRename by remember { mutableStateOf<CollectionEntity?>(null) }
    var renameText by remember { mutableStateOf("") }
    var collectionToDelete by remember { mutableStateOf<CollectionEntity?>(null) }

    LaunchedEffect(activeCollection) {
        if (activeCollection != null) {
            isCollectionsExpanded = true
        }
    }

    AnimatedVisibility(
        visible = isOpen,
        enter = fadeIn(animationSpec = tween(durationMillis = 280, easing = LinearEasing)),
        exit = fadeOut(animationSpec = tween(durationMillis = 240, easing = LinearEasing))
    ) {
        Box(
            Modifier
                .fillMaxSize()
                .zIndex(150f)
        ) {
            // Semi-transparent scrim backdrop
            Box(
                Modifier
                    .fillMaxSize()
                    .background(Color.Black.copy(alpha = 0.35f))
                    .clickable(
                        interactionSource = remember { MutableInteractionSource() },
                        indication = null
                    ) { onDismiss() }
            )

            // Slide-in drawer body
            Surface(
                modifier = Modifier
                    .width(drawerWidth)
                    .fillMaxHeight()
                    .animateEnterExit(
                        enter = slideInHorizontally(
                            initialOffsetX = { -it },
                            animationSpec = tween(durationMillis = 280, easing = FastOutSlowInEasing)
                        ),
                        exit = slideOutHorizontally(
                            targetOffsetX = { -it },
                            animationSpec = tween(durationMillis = 240, easing = FastOutSlowInEasing)
                        )
                    ),
                color = LaterboxBg,
                shadowElevation = 16.dp
            ) {
            Column(
                Modifier
                    .fillMaxSize()
                    .statusBarsPadding()
                    .navigationBarsPadding()
            ) {
                // 1. Header (LaterBox icon + logo text)
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 18.dp, vertical = 14.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    Image(
                        painter = painterResource(R.drawable.laterbox_icon_green),
                        contentDescription = "LaterBox",
                        modifier = Modifier
                            .size(38.dp)
                            .clip(RoundedCornerShape(10.dp))
                    )
                    Text(
                        text = "laterbox",
                        fontSize = 22.sp,
                        fontWeight = FontWeight.Black,
                        color = Color(0xFF171711),
                        letterSpacing = (-0.5).sp
                    )
                }

                // Scrollable Drawer Items
                Column(
                    modifier = Modifier
                        .weight(1f)
                        .verticalScroll(rememberScrollState())
                        .padding(bottom = 16.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    // 2. Save Item Action Button (Black full-width pill)
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 14.dp)
                    ) {
                        Surface(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(52.dp)
                                .clip(RoundedCornerShape(16.dp))
                                .clickable {
                                    onDismiss()
                                    onOpenSaveItem()
                                },
                            shape = RoundedCornerShape(16.dp),
                            color = Color(0xFF171711),
                            shadowElevation = 4.dp
                        ) {
                            Row(
                                modifier = Modifier.fillMaxSize(),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.Center
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Add,
                                    contentDescription = null,
                                    tint = Color.White,
                                    modifier = Modifier.size(18.dp)
                                )
                                Spacer(Modifier.width(8.dp))
                                Text(
                                    text = "Save Item",
                                    fontSize = 16.sp,
                                    fontWeight = FontWeight.ExtraBold,
                                    color = Color.White
                                )
                            }
                        }
                    }

                    // 3. Core Mailboxes Section
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 10.dp),
                        verticalArrangement = Arrangement.spacedBy(2.dp)
                    ) {
                        SidebarNavLinkRow(
                            title = "Inbox",
                            icon = Icons.Default.Inbox,
                            badgeCount = inboxCount,
                            isActive = activeMailbox == MailboxViewType.INBOX && activeCollection == null,
                            onClick = {
                                onDismiss()
                                onSelectMailbox(MailboxViewType.INBOX)
                            }
                        )

                        SidebarNavLinkRow(
                            title = "Today",
                            icon = Icons.Default.Schedule,
                            badgeCount = todayCount,
                            isActive = activeMailbox == MailboxViewType.TODAY && activeCollection == null,
                            onClick = {
                                onDismiss()
                                onSelectMailbox(MailboxViewType.TODAY)
                            }
                        )

                        SidebarNavLinkRow(
                            title = "Scheduled",
                            icon = Icons.Default.CalendarToday,
                            badgeCount = upcomingCount,
                            isActive = activeMailbox == MailboxViewType.SCHEDULED && activeCollection == null,
                            onClick = {
                                onDismiss()
                                onSelectMailbox(MailboxViewType.SCHEDULED)
                            }
                        )

                        SidebarNavLinkRow(
                            title = "Someday",
                            icon = Icons.Default.DateRange,
                            badgeCount = somedayCount,
                            isActive = activeMailbox == MailboxViewType.SOMEDAY && activeCollection == null,
                            onClick = {
                                onDismiss()
                                onSelectMailbox(MailboxViewType.SOMEDAY)
                            }
                        )

                        SidebarNavLinkRow(
                            title = "Starred",
                            icon = Icons.Default.Star,
                            badgeCount = starredCount,
                            isActive = activeMailbox == MailboxViewType.STARRED && activeCollection == null,
                            iconColor = Color(0xFFF59E0B),
                            onClick = {
                                onDismiss()
                                onSelectMailbox(MailboxViewType.STARRED)
                            }
                        )

                        SidebarNavLinkRow(
                            title = "Kept",
                            icon = Icons.Default.CheckCircle,
                            badgeCount = keptCount,
                            isActive = activeMailbox == MailboxViewType.KEPT && activeCollection == null,
                            onClick = {
                                onDismiss()
                                onSelectMailbox(MailboxViewType.KEPT)
                            }
                        )

                        SidebarNavLinkRow(
                            title = "Archived",
                            icon = Icons.Default.Archive,
                            badgeCount = archivedCount,
                            isActive = activeMailbox == MailboxViewType.ARCHIVED && activeCollection == null,
                            onClick = {
                                onDismiss()
                                onSelectMailbox(MailboxViewType.ARCHIVED)
                            }
                        )

                        SidebarNavLinkRow(
                            title = "Recently Deleted",
                            icon = Icons.Default.Delete,
                            badgeCount = trashCount,
                            isActive = activeMailbox == MailboxViewType.TRASH && activeCollection == null,
                            onClick = {
                                onDismiss()
                                onSelectMailbox(MailboxViewType.TRASH)
                            }
                        )
                    }

                    // 4. Collections Section
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 10.dp),
                        verticalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 14.dp, vertical = 2.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Row(
                                modifier = Modifier
                                    .clip(RoundedCornerShape(6.dp))
                                    .clickable { isCollectionsExpanded = !isCollectionsExpanded }
                                    .padding(vertical = 4.dp, horizontal = 2.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(4.dp)
                            ) {
                                Icon(
                                    imageVector = if (isCollectionsExpanded) Icons.Default.KeyboardArrowDown else Icons.AutoMirrored.Filled.KeyboardArrowRight,
                                    contentDescription = if (isCollectionsExpanded) "Collapse collections" else "Expand collections",
                                    tint = Color(0xFF9E9B92),
                                    modifier = Modifier.size(14.dp)
                                )
                                Text(
                                    text = "COLLECTIONS",
                                    fontSize = 10.sp,
                                    fontWeight = FontWeight.Black,
                                    color = Color(0xFF9E9B92),
                                    letterSpacing = 1.sp
                                )
                            }
                            Spacer(Modifier.weight(1f))
                            IconButton(
                                onClick = {
                                    if (!isCollectionsExpanded) isCollectionsExpanded = true
                                    isCreatingCollection = !isCreatingCollection
                                },
                                modifier = Modifier.size(24.dp)
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Add,
                                    contentDescription = "Add collection",
                                    tint = LaterboxTextSecondary,
                                    modifier = Modifier.size(15.dp)
                                )
                            }
                        }

                        AnimatedVisibility(
                            visible = isCollectionsExpanded,
                            enter = expandVertically(animationSpec = tween(durationMillis = 200)) + fadeIn(animationSpec = tween(durationMillis = 200)),
                            exit = shrinkVertically(animationSpec = tween(durationMillis = 200)) + fadeOut(animationSpec = tween(durationMillis = 150))
                        ) {
                            Column(
                                modifier = Modifier.fillMaxWidth(),
                                verticalArrangement = Arrangement.spacedBy(6.dp)
                            ) {
                                if (isCreatingCollection) {
                                    val focusRequester = remember { FocusRequester() }
                                    LaunchedEffect(Unit) {
                                        focusRequester.requestFocus()
                                    }

                                    val submit = {
                                        val trimmed = newCollectionName.trim()
                                        if (trimmed.isNotBlank()) {
                                            onCreateCollection(trimmed)
                                            newCollectionName = ""
                                            isCreatingCollection = false
                                        }
                                    }

                                    Row(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .padding(horizontal = 10.dp, vertical = 4.dp),
                                        verticalAlignment = Alignment.CenterVertically,
                                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                                    ) {
                                        BasicTextField(
                                            value = newCollectionName,
                                            onValueChange = { newCollectionName = it },
                                            singleLine = true,
                                            keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done),
                                            keyboardActions = KeyboardActions(onDone = { submit() }),
                                            textStyle = TextStyle(fontSize = 13.sp, color = LaterboxTextPrimary),
                                            cursorBrush = SolidColor(LaterboxTextPrimary),
                                            modifier = Modifier
                                                .weight(1f)
                                                .height(36.dp)
                                                .focusRequester(focusRequester)
                                                .clip(RoundedCornerShape(10.dp))
                                                .background(Color.White)
                                                .border(BorderStroke(1.dp, Color.Black.copy(alpha = 0.1f)), RoundedCornerShape(10.dp))
                                                .padding(horizontal = 10.dp),
                                            decorationBox = { inner ->
                                                Box(
                                                    contentAlignment = Alignment.CenterStart,
                                                    modifier = Modifier.fillMaxSize()
                                                ) {
                                                    if (newCollectionName.isBlank()) {
                                                        Text("New collection name...", fontSize = 13.sp, color = LaterboxTextSecondary)
                                                    }
                                                    inner()
                                                }
                                            }
                                        )

                                        Button(
                                            onClick = { submit() },
                                            enabled = newCollectionName.isNotBlank(),
                                            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFE6EDB0), contentColor = Color(0xFF171711)),
                                            shape = RoundedCornerShape(8.dp),
                                            contentPadding = PaddingValues(horizontal = 10.dp, vertical = 6.dp),
                                            modifier = Modifier.height(36.dp)
                                        ) {
                                            Text("Add", fontSize = 12.sp, fontWeight = FontWeight.Bold)
                                        }
                                    }
                                }

                                Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                                    collections.forEach { col ->
                                        val count = collectionCount(col.name)
                                        val isColActive = activeCollection.equals(col.name, ignoreCase = true)
                                        SidebarNavLinkRow(
                                            title = col.name,
                                            icon = Icons.AutoMirrored.Filled.Label,
                                            badgeCount = count,
                                            isActive = isColActive,
                                            onLongClick = {
                                                collectionForActions = col
                                            },
                                            onClick = {
                                                onDismiss()
                                                onSelectCollection(col.name)
                                            }
                                        )
                                    }

                                    if (collections.isEmpty() && !isCreatingCollection) {
                                        Row(
                                            modifier = Modifier
                                                .fillMaxWidth()
                                                .clip(RoundedCornerShape(10.dp))
                                                .clickable { isCreatingCollection = true }
                                                .padding(horizontal = 12.dp, vertical = 8.dp),
                                            verticalAlignment = Alignment.CenterVertically,
                                            horizontalArrangement = Arrangement.spacedBy(6.dp)
                                        ) {
                                            Icon(
                                                imageVector = Icons.Default.Add,
                                                contentDescription = null,
                                                tint = Color(0xFF9E9B92),
                                                modifier = Modifier.size(13.dp)
                                            )
                                            Text(
                                                text = "New collection...",
                                                fontSize = 12.sp,
                                                color = Color(0xFF9E9B92)
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 5. Activity Section
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 10.dp),
                        verticalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        Text(
                            text = "ACTIVITY",
                            fontSize = 10.sp,
                            fontWeight = FontWeight.Black,
                            color = Color(0xFF9E9B92),
                            letterSpacing = 1.sp,
                            modifier = Modifier.padding(horizontal = 14.dp, vertical = 2.dp)
                        )

                        SidebarNavLinkRow(
                            title = "Plans",
                            icon = Icons.Default.WorkspacePremium,
                            badgeCount = 0,
                            isActive = false,
                            iconColor = Color(0xFFF59E0B),
                            onClick = {
                                onDismiss()
                                onOpenPlans()
                            }
                        )

                        SidebarNavLinkRow(
                            title = "Settings",
                            icon = Icons.Default.Settings,
                            badgeCount = 0,
                            isActive = false,
                            onClick = {
                                onDismiss()
                                onOpenSettings()
                            }
                        )
                    }
                }

                // 6. Bottom Footer View (Plans & Cloud Sync Status)
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 14.dp, vertical = 10.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    HorizontalDivider(color = Color.Black.copy(alpha = 0.06f))

                    // Plan Card
                    Surface(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(14.dp))
                            .clickable {
                                onDismiss()
                                onOpenPlans()
                            },
                        shape = RoundedCornerShape(14.dp),
                        color = Color.White,
                        border = BorderStroke(1.dp, Color.Black.copy(alpha = 0.06f)),
                        shadowElevation = 2.dp
                    ) {
                        Row(
                            modifier = Modifier.padding(12.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(10.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.WorkspacePremium,
                                contentDescription = null,
                                tint = Color(0xFFF59E0B),
                                modifier = Modifier.size(18.dp)
                            )
                            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                                Text(
                                    text = if (isPro) "Pro Plan" else "Free Plan",
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = Color(0xFF171711)
                                )
                                Text(
                                    text = if (isPro) "Active subscription" else "Upgrade for more space",
                                    fontSize = 10.sp,
                                    fontWeight = FontWeight.Medium,
                                    color = Color(0xFF8E8D87)
                                )
                            }
                            Icon(
                                imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                                contentDescription = null,
                                tint = Color(0xFF9E9B92),
                                modifier = Modifier.size(16.dp)
                            )
                        }
                    }

                    // Cloud Sync Status Row
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 6.dp, vertical = 2.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        Box(
                            modifier = Modifier
                                .size(6.dp)
                                .clip(CircleShape)
                                .background(Color(0xFF10B981))
                        )
                        Text(
                            text = if (userEmail != null) "Synced with LaterBox Cloud" else "Local Vault Mode",
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Medium,
                            color = Color(0xFF6C6B63),
                            modifier = Modifier.weight(1f),
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                        Icon(
                            imageVector = Icons.Default.Cloud,
                            contentDescription = null,
                            tint = Color(0xFF8E8D87),
                            modifier = Modifier.size(14.dp)
                        )
                    }
                }
            }
        }
    }

    // Collection Options Dialog (Edit or Delete)
    if (collectionForActions != null) {
        val col = collectionForActions!!
        AlertDialog(
            onDismissRequest = { collectionForActions = null },
            title = {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Icon(Icons.AutoMirrored.Filled.Label, contentDescription = null, tint = Color(0xFF0369A1), modifier = Modifier.size(20.dp))
                    Text(col.name, fontWeight = FontWeight.Bold, maxLines = 1, overflow = TextOverflow.Ellipsis)
                }
            },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Surface(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(8.dp))
                            .clickable {
                                val target = col
                                collectionForActions = null
                                collectionToRename = target
                                renameText = target.name
                            }
                            .padding(vertical = 12.dp, horizontal = 8.dp),
                        color = Color.Transparent
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                            Icon(Icons.Default.Edit, contentDescription = null, tint = LaterboxTextPrimary, modifier = Modifier.size(18.dp))
                            Text("Edit Collection", fontSize = 14.sp, fontWeight = FontWeight.SemiBold, color = LaterboxTextPrimary)
                        }
                    }
                    HorizontalDivider(color = Color.Black.copy(alpha = 0.06f))
                    Surface(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(8.dp))
                            .clickable {
                                val target = col
                                collectionForActions = null
                                collectionToDelete = target
                            }
                            .padding(vertical = 12.dp, horizontal = 8.dp),
                        color = Color.Transparent
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                            Icon(Icons.Default.Delete, contentDescription = null, tint = Color(0xFFEF4444), modifier = Modifier.size(18.dp))
                            Text("Delete Collection", fontSize = 14.sp, fontWeight = FontWeight.SemiBold, color = Color(0xFFEF4444))
                        }
                    }
                }
            },
            confirmButton = {},
            dismissButton = {
                TextButton(onClick = { collectionForActions = null }) {
                    Text("Cancel", color = LaterboxTextSecondary)
                }
            }
        )
    }

    // Rename Collection Dialog
    if (collectionToRename != null) {
        val col = collectionToRename!!
        AlertDialog(
            onDismissRequest = { collectionToRename = null },
            title = { Text("Edit Collection", fontWeight = FontWeight.Bold) },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text("Enter a new name for this collection.", fontSize = 13.sp, color = LaterboxTextSecondary)
                    BasicTextField(
                        value = renameText,
                        onValueChange = { renameText = it },
                        singleLine = true,
                        textStyle = TextStyle(fontSize = 14.sp, color = LaterboxTextPrimary, fontWeight = FontWeight.Medium),
                        cursorBrush = SolidColor(LaterboxTextPrimary),
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(8.dp))
                            .background(Color(0xFFFAFAF8))
                            .border(BorderStroke(1.dp, Color.Black.copy(alpha = 0.15f)), RoundedCornerShape(8.dp))
                            .padding(10.dp)
                    )
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        val trimmed = renameText.trim()
                        if (trimmed.isNotBlank()) {
                            onEditCollection(col.id, trimmed)
                            collectionToRename = null
                        }
                    },
                    enabled = renameText.trim().isNotBlank(),
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF171711), contentColor = Color(0xFFE6EDB0))
                ) {
                    Text("Save")
                }
            },
            dismissButton = {
                TextButton(onClick = { collectionToRename = null }) {
                    Text("Cancel", color = LaterboxTextSecondary)
                }
            }
        )
    }

    // Delete Collection Confirmation Dialog
    if (collectionToDelete != null) {
        val col = collectionToDelete!!
        AlertDialog(
            onDismissRequest = { collectionToDelete = null },
            title = { Text("Delete Collection?", fontWeight = FontWeight.Bold) },
            text = {
                Text(
                    "Items inside this collection will not be deleted; they will simply be unassigned from this collection.",
                    fontSize = 13.sp,
                    color = Color(0xFF45443F)
                )
            },
            confirmButton = {
                Button(
                    onClick = {
                        onDeleteCollection(col.id)
                        collectionToDelete = null
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFEF4444), contentColor = Color.White)
                ) {
                    Text("Delete")
                }
            },
            dismissButton = {
                TextButton(onClick = { collectionToDelete = null }) {
                    Text("Cancel", color = LaterboxTextSecondary)
                }
            }
        )
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun SidebarNavLinkRow(
    title: String,
    icon: ImageVector,
    badgeCount: Int,
    isActive: Boolean,
    iconColor: Color? = null,
    onLongClick: (() -> Unit)? = null,
    onClick: () -> Unit
) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .then(
                if (onLongClick != null) {
                    Modifier.combinedClickable(
                        onClick = onClick,
                        onLongClick = onLongClick
                    )
                } else {
                    Modifier.clickable(onClick = onClick)
                }
            ),
        shape = RoundedCornerShape(12.dp),
        color = if (isActive) Color(0xFFE6EDB0) else Color.Transparent
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 9.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = iconColor ?: if (isActive) Color(0xFF171711) else Color(0xFF8E8D87),
                modifier = Modifier.size(18.dp)
            )

            Text(
                text = title,
                fontSize = 13.sp,
                fontWeight = if (isActive) FontWeight.Bold else FontWeight.Medium,
                color = if (isActive) Color(0xFF171711) else Color(0xFF6C6B63),
                modifier = Modifier.weight(1f)
            )

            if (badgeCount > 0) {
                Box(
                    modifier = Modifier
                        .clip(CircleShape)
                        .background(if (isActive) Color(0xFFD8E09E) else Color(0xFFE6EDB0))
                        .padding(horizontal = 7.dp, vertical = 2.dp)
                ) {
                    Text(
                        text = "$badgeCount",
                        fontSize = 10.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color(0xFF171711)
                    )
                }
            }
        }
    }
}
