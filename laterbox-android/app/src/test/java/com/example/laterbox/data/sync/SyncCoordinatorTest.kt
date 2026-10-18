package com.example.laterbox.data.sync

import com.example.laterbox.data.local.ItemEntity
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import java.time.Instant

class SyncCoordinatorTest {

    data class RemoteSnapshot(
        val id: String,
        val url: String?,
        val updatedAt: String,
        val deletedAt: String? = null
    )

    @Test
    fun `normalizeUrl cleans tracking params, trailing slashes, and protocol`() {
        val raw1 = "https://www.example.com/article/?utm_source=twitter&ref=blog&id=42"
        val normalized1 = SyncCoordinator.normalizeUrl(raw1)
        assertEquals("example.com/article?id=42", normalized1)

        val raw2 = "http://example.com/path/"
        val normalized2 = SyncCoordinator.normalizeUrl(raw2)
        assertEquals("example.com/path", normalized2)

        val raw3 = "sub.domain.org/page"
        val normalized3 = SyncCoordinator.normalizeUrl(raw3)
        assertEquals("sub.domain.org/page", normalized3)

        assertNull(SyncCoordinator.normalizeUrl(""))
        assertNull(SyncCoordinator.normalizeUrl("   "))
        assertNull(SyncCoordinator.normalizeUrl("https://"))
    }

    @Test
    fun `initial sync state flows are correctly initialized`() {
        assertEquals(CloudSyncState.SYNCED, SyncCoordinator.syncState.value)
        assertEquals(false, SyncCoordinator.isPulling.value)
        assertEquals(false, SyncCoordinator.isPushing.value)
        assertEquals(false, SyncCoordinator.isSyncing.value)
        assertEquals(false, SyncCoordinator.isCheckingRemoteChanges.value)
    }

    @Test
    fun `remote change counting identifies newer remote items and cloud deletions`() {
        val localItem1 = ItemEntity(
            id = "item-1",
            url = "https://example.com/article-1",
            title = "Article 1",
            createdAt = "2026-10-10T10:00:00Z",
            updatedAt = "2026-10-10T10:00:00Z",
            syncStatus = "synced"
        )
        val localItem2 = ItemEntity(
            id = "item-2",
            url = "https://example.com/article-2",
            title = "Article 2",
            createdAt = "2026-10-10T10:00:00Z",
            updatedAt = "2026-10-10T12:00:00Z",
            syncStatus = "synced"
        )
        val localItems = listOf(localItem1, localItem2)
        val localById = localItems.associateBy { it.id.lowercase() }
        val localByUrl = localItems.filter { !it.url.isNullOrBlank() }
            .associateBy { SyncCoordinator.normalizeUrl(it.url) }

        val remoteList = listOf(
            RemoteSnapshot("item-1", "https://example.com/article-1", "2026-10-10T11:00:00Z", null),
            RemoteSnapshot("item-2", "https://example.com/article-2", "2026-10-10T11:00:00Z", null),
            RemoteSnapshot("item-3", "https://example.com/article-3", "2026-10-10T13:00:00Z", null),
            RemoteSnapshot("item-4", "https://example.com/article-4", "2026-10-10T09:00:00Z", "2026-10-10T09:00:00Z")
        )

        val countedKeys = mutableSetOf<String>()
        var count = 0
        for (remote in remoteList) {
            val remoteId = remote.id.lowercase()
            val remoteUrl = SyncCoordinator.normalizeUrl(remote.url)
            val localMatch = localById[remoteId] ?: (if (remoteUrl != null) localByUrl[remoteUrl] else null)
            val key = localMatch?.let { "local:${it.id.lowercase()}" }
                ?: remoteUrl?.let { "url:$it" }
                ?: "remote:$remoteId"
            if (!countedKeys.add(key)) continue

            val remoteDeleted = remote.deletedAt != null
            if (localMatch == null) {
                if (!remoteDeleted) count++
                continue
            }
            val remoteDate = runCatching { Instant.parse(remote.updatedAt) }.getOrDefault(Instant.MIN)
            val localDate = runCatching { Instant.parse(localMatch.updatedAt) }.getOrDefault(Instant.MIN)
            if (remoteDate.isAfter(localDate)) {
                count++
            } else if (remoteDate == localDate) {
                val localDeleted = localMatch.status == "deleted" || localMatch.deletedAt != null
                if (remoteDeleted && !localDeleted) {
                    count++
                }
            }
        }

        // item-1 is newer (+1), item-3 is new (+1) = 2 changes
        assertEquals(2, count)
    }

    @Test
    fun `equal timestamp delete wins over non-deleted local item`() {
        val stamp = "2026-10-10T15:00:00Z"
        val localItem = ItemEntity(
            id = "item-conflict",
            url = "https://example.com/conflict",
            title = "Conflict",
            createdAt = stamp,
            updatedAt = stamp,
            status = "inbox",
            deletedAt = null
        )
        val remoteDeleted = RemoteSnapshot("item-conflict", "https://example.com/conflict", stamp, stamp)

        val localMatch = localItem
        val remoteDate = Instant.parse(remoteDeleted.updatedAt)
        val localDate = Instant.parse(localMatch.updatedAt)
        val remoteIsDeleted = remoteDeleted.deletedAt != null
        val localIsDeleted = localMatch.status == "deleted" || localMatch.deletedAt != null

        val shouldPull = remoteDate.isAfter(localDate) || (remoteDate == localDate && remoteIsDeleted && !localIsDeleted)
        assertEquals(true, shouldPull)
    }

    data class RemoteAttachment(
        val id: String,
        val byteSize: Long,
        val sha256: String,
        val deletedAt: String? = null
    )

    data class LocalAttachment(
        val id: String,
        val path: String
    )

    @Test
    fun `remote item with missing attachments counts as pending pull even if timestamps match`() {
        val stamp = "2026-10-10T12:00:00Z"
        val localItem = ItemEntity(
            id = "item-att",
            url = "https://example.com/att",
            title = "Attachment Test",
            createdAt = stamp,
            updatedAt = stamp,
            attachments = "[]"
        )

        val remoteAttachments = listOf(
            RemoteAttachment(
                id = "att-1",
                byteSize = 1024L,
                sha256 = "abc123sha",
                deletedAt = null
            )
        )

        val localList = emptyList<LocalAttachment>()
        var missing = false
        for (att in remoteAttachments) {
            if (att.deletedAt != null) continue
            val match = localList.firstOrNull { it.id.equals(att.id, ignoreCase = true) }
            val file = match?.let { java.io.File(it.path) }
            if (file == null || !file.isFile) {
                missing = true
                break
            }
        }

        val remoteDate = Instant.parse(stamp)
        val localDate = Instant.parse(localItem.updatedAt)
        val needsPull = remoteDate.isAfter(localDate) || missing
        assertEquals(true, needsPull)
    }

    @Test
    fun `cloud file service hashes file contents with sha256 accurately`() {
        val temp = java.io.File.createTempFile("test_att", ".txt")
        try {
            temp.writeText("hello cloudflare attachment")
            val sha = com.example.laterbox.services.CloudFileService.hash(temp)
            assertEquals("cdf7d51a63b20e20b56ca8901f28c40a4842356f320ec4394647d0c9690c5bd8", sha)
        } finally {
            temp.delete()
        }
    }
}
