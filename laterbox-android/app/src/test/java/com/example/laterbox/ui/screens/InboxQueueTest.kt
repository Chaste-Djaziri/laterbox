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
}
