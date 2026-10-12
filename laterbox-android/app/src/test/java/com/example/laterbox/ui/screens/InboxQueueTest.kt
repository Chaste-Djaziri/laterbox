package com.example.laterbox.ui.screens

import com.example.laterbox.data.local.ItemEntity
import org.junit.Assert.assertEquals
import org.junit.Test
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId

class InboxQueueTest {
    private fun item(id: String, created: String, returned: String? = null) = ItemEntity(
        id = id, createdAt = created, updatedAt = created, returnAt = returned
    )

    @Test fun `FIFO prioritizes return date and falls back to arrival date`() {
        val queue = listOf(
            item("new", "2026-10-07T10:00:00Z"),
            item("returned", "2026-10-01T10:00:00Z", "2026-10-07T09:00:00Z"),
            item("waiting", "2026-10-06T10:00:00Z")
        ).sortedBy(::inboxArrival)
        assertEquals(listOf("waiting", "returned", "new"), queue.map { it.id })
    }

    @Test fun `date only reminders use the local start of day`() {
        assertEquals(LocalDate.of(2026, 10, 7).atStartOfDay(ZoneId.systemDefault()).toInstant(),
            inboxArrival(item("legacy", "2026-10-01T10:00:00Z", "2026-10-07")))
    }

    @Test fun `malformed arrival data does not crash the queue`() {
        assertEquals(Instant.EPOCH, inboxArrival(item("invalid", "invalid")))
    }

    @Test fun `scheduled item transitions into inbox and out of scheduled when status promotes`() {
        val now = Instant.parse("2026-10-12T12:00:00Z")
        val futureReturn = "2026-10-15T09:00:00Z"
        val scheduledItem = ItemEntity(
            id = "sch1",
            createdAt = "2026-10-12T10:00:00Z",
            updatedAt = "2026-10-12T10:00:00Z",
            returnAt = futureReturn,
            status = "deferred"
        )

        // Before return time arrives: item is in scheduled, not inbox
        val endOfToday = now.atZone(ZoneId.systemDefault()).toLocalDate().plusDays(1).atStartOfDay(ZoneId.systemDefault()).toInstant()
        val allItemsBefore = listOf(scheduledItem)
        val inboxBefore = allItemsBefore.filter { it.status == "inbox" && it.deletedAt == null }
        val scheduledBefore = allItemsBefore.filter {
            it.deletedAt == null && it.status == "deferred" &&
                it.returnAt != null && runCatching { Instant.parse(it.returnAt) > endOfToday }.getOrDefault(false)
        }
        assertEquals(0, inboxBefore.size)
        assertEquals(1, scheduledBefore.size)

        // When return time arrives: promoted to inbox
        val promotedItem = scheduledItem.copy(status = "inbox", updatedAt = "2026-10-15T09:00:00Z")
        val allItemsAfter = listOf(promotedItem)
        val inboxAfter = allItemsAfter.filter { it.status == "inbox" && it.deletedAt == null }
        val scheduledAfter = allItemsAfter.filter {
            it.deletedAt == null && it.status == "deferred" &&
                it.returnAt != null && runCatching { Instant.parse(it.returnAt) > endOfToday }.getOrDefault(false)
        }
        assertEquals(1, inboxAfter.size)
        assertEquals(0, scheduledAfter.size)
        assertEquals("sch1", inboxAfter.first().id)
    }

    @Test fun `due scheduled items filter accurately selects items with returnAt on or before now`() {
        val now = Instant.parse("2026-10-12T12:00:00Z")
        val duePast = ItemEntity(id = "1", createdAt = "2026-10-12T10:00:00Z", updatedAt = "2026-10-12T10:00:00Z", status = "deferred", returnAt = "2026-10-12T11:00:00Z")
        val dueExact = ItemEntity(id = "2", createdAt = "2026-10-12T10:00:00Z", updatedAt = "2026-10-12T10:00:00Z", status = "deferred", returnAt = "2026-10-12T12:00:00Z")
        val future = ItemEntity(id = "3", createdAt = "2026-10-12T10:00:00Z", updatedAt = "2026-10-12T10:00:00Z", status = "deferred", returnAt = "2026-10-12T13:00:00Z")
        val alreadyInbox = ItemEntity(id = "4", createdAt = "2026-10-12T10:00:00Z", updatedAt = "2026-10-12T10:00:00Z", status = "inbox", returnAt = "2026-10-12T11:00:00Z")

        val items = listOf(duePast, dueExact, future, alreadyInbox)
        val dueItems = items.filter { it.status == "deferred" && it.returnAt != null && runCatching { Instant.parse(it.returnAt) <= now }.getOrDefault(false) }

        assertEquals(listOf("1", "2"), dueItems.map { it.id })
    }
}
