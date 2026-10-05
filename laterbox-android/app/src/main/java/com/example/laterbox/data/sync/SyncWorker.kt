package com.example.laterbox.data.sync

import android.content.Context
import androidx.room.withTransaction
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.example.laterbox.data.api.LaterBoxApiService
import com.example.laterbox.data.local.*
import com.example.laterbox.services.*
import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant

class SyncWorker(context: Context, parameters: WorkerParameters) : CoroutineWorker(context, parameters) {
    override suspend fun doWork(): Result {
        return try {
            AccountService.refresh()
            val account = AccountService.state.value
            if (!account.pro || account.userId == null) return Result.success()
            val uid = account.userId
            val database = AppDatabase.getDatabase(applicationContext)
            val dao = database.itemDao()
            val base = LaterBoxApiService.supabaseUrl + "/rest/v1/"
            suspend fun post(table: String, body: JSONObject) {
                check(AccountService.state.value == account) { "Account changed" }
                NativeApi.call(base + table, "POST", body)
            }
            var collectionOffset = 0
            while (true) {
                val rows = JSONArray(NativeApi.call(base + "collections?user_id=eq.$uid&order=id.asc&limit=100&offset=$collectionOffset"))
                for (index in 0 until rows.length()) {
                    val row = rows.getJSONObject(index); val id = row.getString("id"); val stamp = row.getString("updated_at")
                    val existing = database.collectionDao().getCollectionById(id)
                    if (existing == null || Instant.parse(existing.updatedAt).isBefore(Instant.parse(stamp))) {
                        database.collectionDao().insertCollection(CollectionEntity(id, uid, row.getString("name"), createdAt = row.getString("created_at"), updatedAt = stamp,
                            syncStatus = "synced", deletedAt = if (row.isNull("deleted_at")) null else row.getString("deleted_at")))
                    }
                }
                if (rows.length() < 100) break
                collectionOffset += rows.length()
            }
            for (collection in database.collectionDao().getAllCollections().filter { it.syncStatus != "synced" && (it.userId == null || it.userId == uid) }) {
                post("collections?on_conflict=id", JSONObject().put("id", collection.id).put("user_id", uid).put("name", collection.name)
                    .put("created_at", collection.createdAt).put("updated_at", collection.updatedAt).put("deleted_at", collection.deletedAt ?: JSONObject.NULL))
                database.collectionDao().markSynced(collection.id, collection.updatedAt, uid)
            }
            var offset = 0
            while (true) {
                val rows = JSONArray(NativeApi.call(base + "items?user_id=eq.$uid&select=*,item_metadata(*),item_notes(*),collection_items(collection_id,deleted_at)&order=id.asc&limit=100&offset=$offset"))
                database.withTransaction {
                    for (index in 0 until rows.length()) {
                        val row = rows.getJSONObject(index); val id = row.getString("id")
                        val local = dao.getItemById(id)
                        val updated = row.getString("updated_at")
                        if (local != null && (!Instant.parse(local.updatedAt).isBefore(Instant.parse(updated)))) continue
                        fun objectValue(key: String): JSONObject? = row.optJSONObject(key) ?: row.optJSONArray(key)?.optJSONObject(0)
                        val metadata = objectValue("item_metadata")
                        val classification = metadata?.optJSONObject("structured_data") ?: metadata?.optString("structured_data")?.let { runCatching { JSONObject(it) }.getOrNull() }
                        fun nullable(key: String) = if (row.isNull(key)) null else row.optString(key).ifBlank { null }
                        val item = ItemEntity(id, userId = uid, url = nullable("url"), title = nullable("title"), textContent = nullable("text_content"),
                            type = row.optString("type", "note"), favorite = row.optBoolean("favorite"), status = row.optString("status", "inbox"), returnAt = nullable("return_at"),
                            createdAt = row.getString("created_at"), updatedAt = updated, syncStatus = "synced", deletedAt = nullable("deleted_at"),
                            tags = classification?.optJSONArray("tags")?.let { tags -> (0 until tags.length()).joinToString(", ") { tags.getString(it) } }.orEmpty(),
                            category = classification?.optString("category").orEmpty(), summary = classification?.optString("summary").orEmpty(), formattedContent = classification?.optString("formattedContent").orEmpty(),
                            notes = objectValue("item_notes")?.takeIf { it.isNull("deleted_at") }?.optString("content").orEmpty(),
                            collectionId = row.optJSONArray("collection_items")?.let { memberships -> (0 until memberships.length()).map { memberships.getJSONObject(it) }.firstOrNull { it.isNull("deleted_at") }?.optString("collection_id") }, attachments = local?.attachments ?: "[]")
                        metadata?.let { database.itemMetadataDao().insertMetadata(ItemMetadataEntity(id, uid, domain = it.optString("domain"), siteName = it.optString("site_name"), title = it.optString("title"), description = it.optString("description"), faviconUrl = it.optString("favicon_url"), previewImageUrl = it.optString("preview_image_url"), status = it.optString("status", "enriched"), structuredData = classification?.toString(), createdAt = item.createdAt, updatedAt = updated)) }
                        dao.insertItem(item)
                        ReturnsService.schedule(applicationContext, item)
                    }
                }
                if (rows.length() < 100) break
                offset += rows.length()
            }
            for (item in dao.getItemsNeedingSync().filter { it.userId == null || it.userId == uid }) {
                val body = JSONObject().put("id", item.id).put("user_id", uid).put("title", item.title).put("url", item.url ?: JSONObject.NULL)
                    .put("text_content", item.textContent ?: JSONObject.NULL).put("type", item.type).put("favorite", item.favorite).put("status", item.status)
                    .put("return_at", item.returnAt ?: JSONObject.NULL).put("created_at", item.createdAt).put("updated_at", item.updatedAt).put("deleted_at", item.deletedAt ?: JSONObject.NULL)
                post("items?on_conflict=id", body)
                val oldMetadata = JSONArray(NativeApi.call(base + "item_metadata?item_id=eq.${item.id}&select=structured_data")).optJSONObject(0)
                val previous = oldMetadata?.optJSONObject("structured_data") ?: oldMetadata?.optString("structured_data")?.let { runCatching { JSONObject(it) }.getOrNull() } ?: JSONObject()
                previous.put("tags", JSONArray(item.tags.split(",").map { it.trim() }.filter { it.isNotBlank() })).put("category", item.category).put("summary", item.summary).put("formattedContent", item.formattedContent)
                post("item_metadata?on_conflict=item_id", JSONObject().put("item_id", item.id).put("user_id", uid).put("status", "enriched").put("structured_data", previous).put("updated_at", item.updatedAt))
                post("item_notes?on_conflict=item_id", JSONObject().put("item_id", item.id).put("user_id", uid).put("content", item.notes).put("updated_at", item.updatedAt).put("deleted_at", if (item.notes.isBlank()) item.updatedAt else JSONObject.NULL))
                val memberships = JSONArray(NativeApi.call(base + "collection_items?item_id=eq.${item.id}&user_id=eq.$uid&select=collection_id"))
                for (index in 0 until memberships.length()) {
                    val id = memberships.getJSONObject(index).getString("collection_id")
                    if (id != item.collectionId) NativeApi.call(base + "collection_items?collection_id=eq.$id&item_id=eq.${item.id}&user_id=eq.$uid", "PATCH", JSONObject().put("deleted_at", item.updatedAt).put("updated_at", item.updatedAt))
                }
                item.collectionId?.let { id -> database.collectionDao().getCollectionById(id)?.takeIf { it.deletedAt == null }?.let {
                    post("collection_items?on_conflict=collection_id,item_id", JSONObject().put("collection_id", id).put("item_id", item.id).put("user_id", uid).put("created_at", item.createdAt).put("updated_at", item.updatedAt).put("deleted_at", JSONObject.NULL))
                } }
                dao.markSyncedIfUnchanged(item.id, item.updatedAt, Instant.now().toString(), uid)
            }
            Result.success()
        } catch (error: kotlinx.coroutines.CancellationException) { throw error } catch (error: Exception) { Result.retry() }
    }
}
