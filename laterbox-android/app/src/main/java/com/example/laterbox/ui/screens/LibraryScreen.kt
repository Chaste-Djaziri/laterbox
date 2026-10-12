package com.example.laterbox.ui.screens

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.laterbox.R
import com.example.laterbox.data.DataRepository
import com.example.laterbox.data.local.CollectionEntity
import com.example.laterbox.data.local.ItemEntity
import com.example.laterbox.services.AccountService
import com.example.laterbox.services.BackupService
import com.example.laterbox.services.LocalSearch
import com.example.laterbox.services.VaultStore
import com.example.laterbox.theme.*
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.time.ZoneId

internal enum class LibrarySection(val label: String, val icon: ImageVector) {
    FAVORITES("Favorites", Icons.Default.Star), KEPT("Kept", Icons.Default.Bookmark),
    ARCHIVED("Archived", Icons.Default.Archive), DELETED("Deleted", Icons.Default.Delete)
}
internal data class LibraryFolder(val key: String, val name: String, val collectionId: String?)
internal fun libraryFolders(collections: List<CollectionEntity>, items: List<ItemEntity>): List<LibraryFolder> {
    val stored = collections.filter { it.deletedAt == null }.map { LibraryFolder(it.id, it.name, it.id) }
    val legacy = items.filter { it.deletedAt == null && it.collectionId == null && it.category.isNotBlank() }
        .map { it.category.trim() }.distinct().filter { name -> stored.none { it.name.equals(name, true) } }
        .map { LibraryFolder("legacy:$it", it, null) }
    return (stored + legacy).sortedBy { it.name.lowercase() }
}
internal fun librarySectionItems(section: LibrarySection, items: List<ItemEntity>): List<ItemEntity> = items.filter {
    val deleted = it.deletedAt != null || it.status == "deleted"
    when (section) {
        LibrarySection.FAVORITES -> !deleted && it.favorite
        LibrarySection.KEPT -> !deleted && it.status in listOf("saved", "done")
        LibrarySection.ARCHIVED -> !deleted && it.status == "archived"
        LibrarySection.DELETED -> deleted
    }
}
internal fun libraryFolderItems(folder: LibraryFolder, items: List<ItemEntity>): List<ItemEntity> = items.filter {
    it.deletedAt == null && it.status != "deleted" && (it.collectionId == folder.collectionId && folder.collectionId != null || it.collectionId == null && it.category.trim().equals(folder.name, true))
}

@Composable
fun LibraryScreen(
    repository: DataRepository,
    onItem: (ItemEntity) -> Unit,
    initialMailbox: com.example.laterbox.ui.components.MailboxViewType = com.example.laterbox.ui.components.MailboxViewType.STARRED,
    initialCollection: String? = null
) {
    InboxQueueScreen(
        repository = repository,
        onItem = onItem,
        initialMailbox = initialMailbox,
        initialCollection = initialCollection
    )
}

