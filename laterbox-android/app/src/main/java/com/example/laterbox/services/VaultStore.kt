package com.example.laterbox.services

import android.content.Context
import androidx.room.withTransaction
import com.example.laterbox.data.local.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.jsoup.Jsoup
import org.json.JSONArray
import java.time.Instant
import java.util.UUID

class VaultStore(private val context: Context) {
    val database = AppDatabase.getDatabase(context)
    suspend fun save(draft: ItemEntity): ItemEntity {
        require((0 until JSONArray(draft.attachments).length()).none { JSONArray(draft.attachments).getJSONObject(it).has("error") }) { "Some shared files could not be copied. Retry sharing those files before saving." }
        require(!draft.textContent.isNullOrBlank() || !draft.url.isNullOrBlank() || JSONArray(draft.attachments).length() > 0) { "Add content or an attachment first." }
        val item = database.withTransaction {
            val existing = database.itemDao().getItemById(draft.id)
            if (existing != null) return@withTransaction existing
            var capture = draft.copy(userId = AccountService.state.value.userId)
            if (draft.category.isNotBlank() && draft.collectionId == null) {
                val existingCollection = database.collectionDao().findByName(draft.category)
                val collection = existingCollection ?: CollectionEntity(UUID.randomUUID().toString(), capture.userId, draft.category, createdAt = draft.createdAt, updatedAt = draft.updatedAt, syncStatus = "pending")
                database.collectionDao().insertCollection(collection)
                capture = capture.copy(collectionId = collection.id)
            }
            database.itemDao().insertItem(capture)
            capture
        }
        ReturnsService.schedule(context, item)
        return item
    }
    suspend fun edit(item: ItemEntity) {
        val updated = item.copy(updatedAt = Instant.now().toString(), syncStatus = "pending")
        database.itemDao().updateItem(updated); ReturnsService.schedule(context, updated)
    }
    suspend fun undo(item: ItemEntity) { edit(item.copy(deletedAt = Instant.now().toString(), status = "deleted")) }
    suspend fun metadata(item: ItemEntity) = withContext(Dispatchers.IO) {
        val url = item.url ?: return@withContext
        runCatching {
            val doc = Jsoup.connect(url).timeout(10000).maxBodySize(1024 * 1024).get()
            val title = doc.selectFirst("meta[property=og:title]")?.attr("content") ?: doc.title()
            val summary = doc.selectFirst("meta[property=og:description],meta[name=description]")?.attr("content").orEmpty()
            val current = database.itemDao().getItemById(item.id) ?: return@runCatching
            if (current.deletedAt != null) return@runCatching
            val now = Instant.now().toString()
            database.itemMetadataDao().insertMetadata(ItemMetadataEntity(item.id, domain = java.net.URI(url).host, title = title, description = summary,
                previewImageUrl = doc.selectFirst("meta[property=og:image]")?.absUrl("content"), status = "enriched", createdAt = now, updatedAt = now))
            edit(current.copy(title = if (current.title == item.url || current.title == java.net.URI(url).host) title.ifBlank { current.title } else current.title,
                summary = current.summary.ifBlank { summary }))
        }
    }
    companion object {
        fun draft(content: String, title: String = "", tags: String = "", category: String = "", returnAt: String? = null, attachments: String = "[]", id: String = UUID.randomUUID().toString()): ItemEntity {
            val url = Regex("https?://[^\\s]+").find(content)?.value
            val host = url?.let { runCatching { java.net.URI(it).host }.getOrNull() }.orEmpty()
            val mime = runCatching { JSONArray(attachments).optJSONObject(0)?.optString("mime") }.getOrNull().orEmpty()
            val type = when { mime.startsWith("image/") -> "image"; mime.startsWith("video/") -> "video"; mime.startsWith("audio/") -> "music"; attachments != "[]" -> "document"; url == null -> "note"; host.contains("youtube") || host.contains("youtu.be") -> "video"; host.contains("spotify") || host.contains("soundcloud") -> "music"; url.endsWith(".pdf") -> "document"; else -> "link" }
            val hashtags = Regex("#([\\p{L}\\d_-]+)").findAll(content).map { it.groupValues[1] }.toList()
            val stamp = Instant.now().toString()
            return ItemEntity(id, title = title.ifBlank { host.ifBlank { content.lineSequence().firstOrNull().orEmpty().take(100).ifBlank { "Shared file" } } }, url = url,
                textContent = content, type = type, tags = (tags.split(Regex("[,\\s]+")) + hashtags).map { it.removePrefix("#") }.filter { it.isNotBlank() }.distinct().joinToString(", "), category = category,
                returnAt = returnAt, status = if (returnAt == null) "inbox" else "deferred", attachments = attachments, createdAt = stamp, updatedAt = stamp)
        }
    }
}
