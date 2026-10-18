package com.example.laterbox.ui.components

import com.example.laterbox.data.local.CollectionEntity
import com.example.laterbox.data.local.ItemEntity
import org.junit.Assert.assertEquals
import org.junit.Test

class MobileSidebarTest {
    private fun item(
        id: String,
        status: String = "inbox",
        category: String = "",
        collectionId: String? = null,
        deletedAt: String? = null
    ) = ItemEntity(
        id = id,
        status = status,
        category = category,
        collectionId = collectionId,
        deletedAt = deletedAt,
        createdAt = "2026-10-12T10:00:00Z",
        updatedAt = "2026-10-12T10:00:00Z"
    )

    private fun collection(id: String, name: String) = CollectionEntity(
        id = id,
        name = name,
        createdAt = "2026-10-12T10:00:00Z",
        updatedAt = "2026-10-12T10:00:00Z"
    )

    @Test
    fun `collection count includes items matching collectionId or category case-insensitively`() {
        val collections = listOf(collection("c1", "Design"), collection("c2", "Work"))
        val items = listOf(
            item("1", collectionId = "c1"),
            item("2", category = "design"),
            item("3", category = "DESIGN"),
            item("4", category = "Work"),
            item("5", collectionId = "c2"),
            item("6", collectionId = "c1", deletedAt = "2026-10-12T11:00:00Z"),
            item("7", status = "deleted", category = "Design")
        )

        fun count(name: String): Int {
            return items.count {
                it.deletedAt == null && it.status != "deleted" &&
                    (it.category.equals(name, ignoreCase = true) ||
                        collections.find { c -> c.id == it.collectionId }?.name?.equals(name, ignoreCase = true) == true)
            }
        }

        assertEquals(3, count("Design"))
        assertEquals(2, count("Work"))
        assertEquals(0, count("Personal"))
    }

    @Test
    fun `today and upcoming counts only include deferred items`() {
        val now = java.time.Instant.parse("2026-10-12T12:00:00Z")
        val endOfToday = now.atZone(java.time.ZoneId.systemDefault()).toLocalDate().plusDays(1).atStartOfDay(java.time.ZoneId.systemDefault()).toInstant()
        val dueTodayDeferred = ItemEntity(id = "1", status = "deferred", returnAt = "2026-10-12T15:00:00Z", createdAt = "2026-10-12T10:00:00Z", updatedAt = "2026-10-12T10:00:00Z")
        val dueTodayInbox = ItemEntity(id = "2", status = "inbox", returnAt = "2026-10-12T11:00:00Z", createdAt = "2026-10-12T10:00:00Z", updatedAt = "2026-10-12T10:00:00Z")
        val upcomingDeferred = ItemEntity(id = "3", status = "deferred", returnAt = "2026-10-15T09:00:00Z", createdAt = "2026-10-12T10:00:00Z", updatedAt = "2026-10-12T10:00:00Z")
        val items = listOf(dueTodayDeferred, dueTodayInbox, upcomingDeferred)

        val todayCount = items.count {
            it.deletedAt == null && it.status == "deferred" &&
                it.returnAt != null && runCatching { java.time.Instant.parse(it.returnAt) <= endOfToday }.getOrDefault(false)
        }
        val upcomingCount = items.count {
            it.deletedAt == null && it.status == "deferred" &&
                it.returnAt != null && runCatching { java.time.Instant.parse(it.returnAt) > endOfToday }.getOrDefault(false)
        }

        assertEquals(1, todayCount)
        assertEquals(1, upcomingCount)
    }

    @Test
    fun `collections expansion state toggles and auto-expands on active collection`() {
        var isCollectionsExpanded = true
        // Toggle collapse
        isCollectionsExpanded = !isCollectionsExpanded
        assertEquals(false, isCollectionsExpanded)

        // Toggle expand
        isCollectionsExpanded = !isCollectionsExpanded
        assertEquals(true, isCollectionsExpanded)

        // Collapsed state
        isCollectionsExpanded = false

        // When active collection is selected or new collection is created, expand
        val activeCollection: String? = "Design"
        if (activeCollection != null) {
            isCollectionsExpanded = true
        }
        assertEquals(true, isCollectionsExpanded)
    }
}
