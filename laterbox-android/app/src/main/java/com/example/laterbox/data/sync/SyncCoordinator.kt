package com.example.laterbox.data.sync

import android.content.Context
import androidx.room.withTransaction
import com.example.laterbox.data.api.LaterBoxApiService
import com.example.laterbox.data.local.*
import com.example.laterbox.services.*
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.net.URI
import java.time.Instant

enum class CloudSyncState(val label: String) {
    SYNCED("Synced"),
    SYNCING("Syncing"),
    OFFLINE("Offline"),
    ERROR("Error")
}

object SyncCoordinator {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val syncMutex = Mutex()

    private val _syncState = MutableStateFlow(CloudSyncState.SYNCED)
    val syncState: StateFlow<CloudSyncState> = _syncState.asStateFlow()

    private val _isPulling = MutableStateFlow(false)
    val isPulling: StateFlow<Boolean> = _isPulling.asStateFlow()

    private val _isPushing = MutableStateFlow(false)
    val isPushing: StateFlow<Boolean> = _isPushing.asStateFlow()

    private val _isSyncing = MutableStateFlow(false)
    val isSyncing: StateFlow<Boolean> = _isSyncing.asStateFlow()

    private val _isCheckingRemoteChanges = MutableStateFlow(false)
    val isCheckingRemoteChanges: StateFlow<Boolean> = _isCheckingRemoteChanges.asStateFlow()

    private val _pendingPullCount = MutableStateFlow(0)
    val pendingPullCount: StateFlow<Int> = _pendingPullCount.asStateFlow()

    private val _pendingPushCount = MutableStateFlow(0)
    val pendingPushCount: StateFlow<Int> = _pendingPushCount.asStateFlow()

    private val _lastSyncedAt = MutableStateFlow<Instant?>(null)
    val lastSyncedAt: StateFlow<Instant?> = _lastSyncedAt.asStateFlow()

    private val _lastSyncErrorMessage = MutableStateFlow<String?>(null)
    val lastSyncErrorMessage: StateFlow<String?> = _lastSyncErrorMessage.asStateFlow()

    fun normalizeUrl(url: String?): String? {
        if (url.isNullOrBlank()) return null
        var raw = url.trim()
        if (raw == "http://" || raw == "https://") return null
        if (!raw.contains("://")) {
            raw = "https://$raw"
        }
        return try {
            val uri = URI(raw)
            var host = (uri.host ?: "").lowercase()
            if (host.startsWith("www.")) {
                host = host.removePrefix("www.")
            }
            var path = uri.path ?: ""
            while (path.endsWith("/") && path.length > 1) {
                path = path.dropLast(1)
            }
            if (path == "/") path = ""
            val query = uri.query
            val filteredQuery = if (!query.isNullOrBlank()) {
                val ignored = setOf("utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content", "ref", "fbclid", "gclid")
                query.split("&")
                    .mapNotNull { param ->
                        val parts = param.split("=", limit = 2)
                        val key = parts[0].lowercase()
                        if (key in ignored) null else param
                    }
                    .sorted()
                    .joinToString("&")
            } else ""
            if (filteredQuery.isNotBlank()) "$host$path?$filteredQuery" else "$host$path"
        } catch (_: Exception) {
            val lower = raw.lowercase()
            if (lower.endsWith("/")) lower.dropLast(1) else lower
        }
    }

    suspend fun updateLocalPendingPushCount(context: Context): Int {
        return try {
            val uid = AccountService.state.value.userId
            val database = AppDatabase.getDatabase(context)
            val pendingItems = database.itemDao().getItemsNeedingSync()
                .count { it.userId == null || it.userId == uid }
            val pendingCollections = database.collectionDao().getAllCollections()
                .count { it.syncStatus != "synced" && (it.userId == null || it.userId == uid) }
            val total = pendingItems + pendingCollections
            _pendingPushCount.value = total
            total
        } catch (_: Exception) {
            _pendingPushCount.value
        }
    }

    fun refreshPendingCounts(context: Context) {
        scope.launch {
            updateLocalPendingPushCount(context)
            checkRemoteChanges(context)
        }
    }

    suspend fun checkRemoteChanges(context: Context): Int {
        val account = AccountService.state.value
        if (!account.pro || account.userId == null) {
            _pendingPullCount.value = 0
            return 0
        }
        if (_isCheckingRemoteChanges.value) return _pendingPullCount.value
        _isCheckingRemoteChanges.value = true
        try {
            val uid = account.userId
            val base = LaterBoxApiService.supabaseUrl + "/rest/v1/"
            val jsonText = NativeApi.call(base + "items?user_id=eq.$uid&select=id,url,updated_at,deleted_at,attachments(id,byte_size,sha256,deleted_at)")
            val remoteList = JSONArray(jsonText)
            val database = AppDatabase.getDatabase(context)
            val localItems = database.itemDao().getAllItems()
            val localById = localItems.associateBy { it.id.lowercase() }
            val localByUrl = localItems.filter { !it.url.isNullOrBlank() }
                .associateBy { normalizeUrl(it.url) }

            val countedKeys = mutableSetOf<String>()
            var count = 0
            for (i in 0 until remoteList.length()) {
                val remote = remoteList.getJSONObject(i)
                val remoteId = remote.optString("id").lowercase()
                val remoteUrl = normalizeUrl(if (remote.isNull("url")) null else remote.optString("url"))
                val localMatch = localById[remoteId] ?: (if (remoteUrl != null) localByUrl[remoteUrl] else null)
                val key = localMatch?.let { "local:${it.id.lowercase()}" }
                    ?: remoteUrl?.let { "url:$it" }
                    ?: "remote:$remoteId"
                if (!countedKeys.add(key)) continue

                val remoteDeleted = !remote.isNull("deleted_at")
                if (localMatch == null) {
                    if (!remoteDeleted) {
                        count++
                    }
                    continue
                }
                val remoteDateStr = remote.optString("updated_at")
                val remoteDate = runCatching { Instant.parse(remoteDateStr) }.getOrDefault(Instant.MIN)
                val localDate = runCatching { Instant.parse(localMatch.updatedAt) }.getOrDefault(Instant.MIN)
                val localDeleted = localMatch.status == "deleted" || localMatch.deletedAt != null

                val remoteAttachments = remote.optJSONArray("attachments")
                val hasMissingAttachments = if (!remoteDeleted && !localDeleted && remoteAttachments != null && remoteAttachments.length() > 0) {
                    val localFiles = runCatching { JSONArray(localMatch.attachments) }.getOrDefault(JSONArray())
                    val localList = (0 until localFiles.length()).map { localFiles.getJSONObject(it) }
                    var missing = false
                    for (aIdx in 0 until remoteAttachments.length()) {
                        val att = remoteAttachments.getJSONObject(aIdx)
                        if (!att.isNull("deleted_at") && att.optString("deleted_at").isNotBlank()) continue
                        val attId = att.optString("id")
                        val sha = att.optString("sha256")
                        val byteSize = att.optLong("byte_size", 0L)
                        val match = localList.firstOrNull {
                            it.optString("id").equals(attId, ignoreCase = true) ||
                                (sha.isNotBlank() && it.optString("path").isNotBlank() && File(it.optString("path")).isFile && CloudFileService.hash(File(it.optString("path"))).equals(sha, ignoreCase = true))
                        }
                        val path = match?.optString("path")
                        val file = if (!path.isNullOrBlank()) File(path) else null
                        if (file == null || !file.isFile || (byteSize > 0 && file.length() != byteSize)) {
                            missing = true
                            break
                        }
                    }
                    missing
                } else false

                if (remoteDate.isAfter(localDate) || hasMissingAttachments) {
                    count++
                } else if (remoteDate == localDate) {
                    if (remoteDeleted && !localDeleted) {
                        count++
                    }
                }
            }
            _pendingPullCount.value = count
            updateLocalPendingPushCount(context)
            return count
        } catch (_: Exception) {
            return _pendingPullCount.value
        } finally {
            _isCheckingRemoteChanges.value = false
        }
    }

    suspend fun pullChanges(context: Context) {
        val account = AccountService.state.value
        if (!account.pro || account.userId == null) {
            _syncState.value = CloudSyncState.OFFLINE
            return
        }
        if (_isPulling.value || _isSyncing.value) return
        syncMutex.withLock {
            _isPulling.value = true
            _syncState.value = CloudSyncState.SYNCING
            try {
                performPull(context, account.userId)
                _syncState.value = CloudSyncState.SYNCED
                _lastSyncedAt.value = Instant.now()
                _lastSyncErrorMessage.value = null
                _pendingPullCount.value = 0
                updateLocalPendingPushCount(context)
            } catch (cancelled: kotlinx.coroutines.CancellationException) {
                throw cancelled
            } catch (e: Exception) {
                _syncState.value = CloudSyncState.ERROR
                _lastSyncErrorMessage.value = e.message ?: "Failed to pull changes from cloud"
            } finally {
                _isPulling.value = false
            }
        }
    }

    suspend fun pushChanges(context: Context) {
        val account = AccountService.state.value
        if (!account.pro || account.userId == null) {
            _syncState.value = CloudSyncState.OFFLINE
            return
        }
        if (_isPushing.value || _isSyncing.value) return
        syncMutex.withLock {
            _isPushing.value = true
            _syncState.value = CloudSyncState.SYNCING
            try {
                performPush(context, account.userId)
                _syncState.value = CloudSyncState.SYNCED
                _lastSyncedAt.value = Instant.now()
                _lastSyncErrorMessage.value = null
                updateLocalPendingPushCount(context)
            } catch (cancelled: kotlinx.coroutines.CancellationException) {
                throw cancelled
            } catch (e: Exception) {
                _syncState.value = CloudSyncState.ERROR
                _lastSyncErrorMessage.value = e.message ?: "Failed to push changes to cloud"
            } finally {
                _isPushing.value = false
            }
        }
    }

    suspend fun pullAndPushChanges(context: Context) {
        AccountService.refresh()
        val account = AccountService.state.value
        if (!account.pro || account.userId == null) {
            _syncState.value = CloudSyncState.OFFLINE
            _lastSyncErrorMessage.value = null
            return
        }
        if (_isSyncing.value || _isPulling.value || _isPushing.value) return
        syncMutex.withLock {
            _isSyncing.value = true
            _syncState.value = CloudSyncState.SYNCING
            try {
                performPull(context, account.userId)
                performPush(context, account.userId)
                _syncState.value = CloudSyncState.SYNCED
                _lastSyncedAt.value = Instant.now()
                _lastSyncErrorMessage.value = null
                _pendingPullCount.value = 0
                updateLocalPendingPushCount(context)
            } catch (cancelled: kotlinx.coroutines.CancellationException) {
                throw cancelled
            } catch (e: Exception) {
                _syncState.value = CloudSyncState.ERROR
                _lastSyncErrorMessage.value = e.message ?: "Sync failed. Please retry."
            } finally {
                _isSyncing.value = false
            }
        }
    }

    private suspend fun performPull(context: Context, uid: String) {
        val database = AppDatabase.getDatabase(context)
        val dao = database.itemDao()
        val base = LaterBoxApiService.supabaseUrl + "/rest/v1/"

        // 1. Pull Collections
        var collectionOffset = 0
        while (true) {
            val rows = JSONArray(NativeApi.call(base + "collections?user_id=eq.$uid&order=id.asc&limit=100&offset=$collectionOffset"))
            for (index in 0 until rows.length()) {
                val row = rows.getJSONObject(index)
                val id = row.getString("id")
                val stamp = row.getString("updated_at")
                val existing = database.collectionDao().getCollectionById(id)
                val remoteDate = runCatching { Instant.parse(stamp) }.getOrDefault(Instant.MIN)
                val existingDate = existing?.let { runCatching { Instant.parse(it.updatedAt) }.getOrDefault(Instant.MIN) }
                if (existing == null || existingDate == null || existingDate.isBefore(remoteDate)) {
                    database.collectionDao().insertCollection(
                        CollectionEntity(
                            id = id,
                            userId = uid,
                            name = row.getString("name"),
                            createdAt = row.getString("created_at"),
                            updatedAt = stamp,
                            syncStatus = "synced",
                            deletedAt = if (row.isNull("deleted_at")) null else row.getString("deleted_at")
                        )
                    )
                }
            }
            if (rows.length() < 100) break
            collectionOffset += rows.length()
        }

        // 2. Pull Items with Cloudflare attachments
        var offset = 0
        while (true) {
            val rows = JSONArray(
                NativeApi.call(
                    base + "items?user_id=eq.$uid&select=*,item_metadata(*),item_notes(*),collection_items(collection_id,deleted_at),attachments(id,item_id,original_file_name,file_extension,mime_type,byte_size,sha256,r2_object_key,deleted_at)&order=id.asc&limit=100&offset=$offset"
                )
            )
            val itemsToUpsert = mutableListOf<Pair<ItemEntity, ItemMetadataEntity?>>()
            val itemsToSchedule = mutableListOf<ItemEntity>()

            for (index in 0 until rows.length()) {
                val row = rows.getJSONObject(index)
                val id = row.getString("id")
                val local = dao.getItemById(id)
                val updated = row.getString("updated_at")

                val remoteDate = runCatching { Instant.parse(updated) }.getOrDefault(Instant.MIN)
                val localDate = local?.let { runCatching { Instant.parse(it.updatedAt) }.getOrDefault(Instant.MIN) }
                val remoteAttachments = row.optJSONArray("attachments") ?: JSONArray()
                val remoteDeleted = !row.isNull("deleted_at")

                fun objectValue(key: String): JSONObject? = row.optJSONObject(key) ?: row.optJSONArray(key)?.optJSONObject(0)
                fun JSONObject.cleanString(key: String): String? {
                    if (isNull(key)) return null
                    val v = optString(key).trim()
                    return if (v.isEmpty() || v.equals("null", ignoreCase = true) || v.equals("undefined", ignoreCase = true)) null else v
                }

                if (local != null && localDate != null) {
                    val localDeleted = local.status == "deleted" || local.deletedAt != null
                    if (remoteDate.isBefore(localDate) || (remoteDate == localDate && !(remoteDeleted && !localDeleted))) {
                        // Restore attachments independently of local item edits/timestamps
                        if (remoteAttachments.length() > 0 && !localDeleted) {
                            val restored = CloudFileService.downloadAttachmentsForRows(
                                context = context,
                                currentAttachmentsJson = local.attachments,
                                rows = remoteAttachments,
                                uid = uid
                            )
                            if (restored != local.attachments) {
                                dao.replaceAttachmentsIfUnchanged(local.id, local.updatedAt, restored)
                            }
                        }
                        // Ensure missing metadata is saved even if item timestamps matched
                        val remoteMeta = objectValue("item_metadata")
                        if (remoteMeta != null && database.itemMetadataDao().getMetadataById(id) == null) {
                            val classification = remoteMeta.optJSONObject("structured_data")
                                ?: remoteMeta.optString("structured_data")?.let { runCatching { JSONObject(it) }.getOrNull() }
                            database.itemMetadataDao().insertMetadata(
                                ItemMetadataEntity(
                                    itemId = id,
                                    userId = uid,
                                    domain = remoteMeta.cleanString("domain"),
                                    siteName = remoteMeta.cleanString("site_name"),
                                    title = remoteMeta.cleanString("title"),
                                    description = remoteMeta.cleanString("description"),
                                    faviconUrl = remoteMeta.cleanString("favicon_url"),
                                    previewImageUrl = remoteMeta.cleanString("preview_image_url"),
                                    status = remoteMeta.cleanString("status") ?: "enriched",
                                    structuredData = classification?.toString()?.takeIf { it != "{}" && it != "null" },
                                    createdAt = local.createdAt,
                                    updatedAt = updated
                                )
                            )
                        }
                        continue
                    }
                }

                val downloadedAttachments = if (remoteAttachments.length() > 0 && !remoteDeleted) {
                    CloudFileService.downloadAttachmentsForRows(
                        context = context,
                        currentAttachmentsJson = local?.attachments ?: "[]",
                        rows = remoteAttachments,
                        uid = uid
                    )
                } else {
                    local?.attachments ?: "[]"
                }

                val metadata = objectValue("item_metadata")
                val classification = metadata?.optJSONObject("structured_data")
                    ?: metadata?.optString("structured_data")?.let { runCatching { JSONObject(it) }.getOrNull() }

                val item = ItemEntity(
                    id = id,
                    userId = uid,
                    url = row.cleanString("url"),
                    title = row.cleanString("title"),
                    textContent = row.cleanString("text_content"),
                    textSelector = row.cleanString("text_selector"),
                    type = row.cleanString("type") ?: "note",
                    favorite = row.optBoolean("favorite"),
                    status = row.cleanString("status") ?: "inbox",
                    returnAt = row.cleanString("return_at"),
                    createdAt = row.getString("created_at"),
                    updatedAt = updated,
                    syncStatus = "synced",
                    deletedAt = row.cleanString("deleted_at"),
                    tags = classification?.optJSONArray("tags")?.let { tags ->
                        (0 until tags.length()).mapNotNull { idx ->
                            tags.optString(idx).trim().takeIf { it.isNotEmpty() && !it.equals("null", ignoreCase = true) }
                        }.joinToString(", ")
                    }.orEmpty(),
                    category = classification?.cleanString("category").orEmpty(),
                    summary = classification?.cleanString("summary").orEmpty(),
                    formattedContent = classification?.cleanString("formattedContent").orEmpty(),
                    notes = objectValue("item_notes")?.takeIf { it.isNull("deleted_at") }?.cleanString("content").orEmpty(),
                    collectionId = row.optJSONArray("collection_items")?.let { memberships ->
                        (0 until memberships.length())
                            .map { memberships.getJSONObject(it) }
                            .firstOrNull { it.isNull("deleted_at") }
                            ?.cleanString("collection_id")
                    },
                    attachments = downloadedAttachments
                )

                val metaEntity = metadata?.let {
                    ItemMetadataEntity(
                        itemId = id,
                        userId = uid,
                        domain = it.cleanString("domain"),
                        siteName = it.cleanString("site_name"),
                        title = it.cleanString("title"),
                        description = it.cleanString("description"),
                        faviconUrl = it.cleanString("favicon_url"),
                        previewImageUrl = it.cleanString("preview_image_url"),
                        status = it.cleanString("status") ?: "enriched",
                        structuredData = classification?.toString()?.takeIf { s -> s != "{}" && s != "null" },
                        createdAt = item.createdAt,
                        updatedAt = updated
                    )
                }

                itemsToUpsert.add(Pair(item, metaEntity))
                itemsToSchedule.add(item)
            }

            if (itemsToUpsert.isNotEmpty()) {
                database.withTransaction {
                    for ((item, meta) in itemsToUpsert) {
                        meta?.let { database.itemMetadataDao().insertMetadata(it) }
                        dao.insertItem(item)
                    }
                }
            }
            for (item in itemsToSchedule) {
                ReturnsService.schedule(context, item)
            }
            if (rows.length() < 100) break
            offset += rows.length()
        }

        // 3. Ensure any missing attachments across existing items are restored
        CloudFileService.restoreAllMissingAttachments(context, uid)
    }

    private suspend fun performPush(context: Context, uid: String) {
        val database = AppDatabase.getDatabase(context)
        val dao = database.itemDao()
        val base = LaterBoxApiService.supabaseUrl + "/rest/v1/"

        suspend fun post(table: String, body: JSONObject) {
            NativeApi.call(base + table, "POST", body)
        }

        // 1. Push Collections
        for (collection in database.collectionDao().getAllCollections().filter { it.syncStatus != "synced" && (it.userId == null || it.userId == uid) }) {
            post(
                "collections?on_conflict=id",
                JSONObject()
                    .put("id", collection.id)
                    .put("user_id", uid)
                    .put("name", collection.name)
                    .put("created_at", collection.createdAt)
                    .put("updated_at", collection.updatedAt)
                    .put("deleted_at", collection.deletedAt ?: JSONObject.NULL)
            )
            database.collectionDao().markSynced(collection.id, collection.updatedAt, uid)
        }

        // 2. Push Items
        for (item in dao.getItemsNeedingSync().filter { it.userId == null || it.userId == uid }) {
            val body = JSONObject()
                .put("id", item.id)
                .put("user_id", uid)
                .put("title", item.title)
                .put("url", item.url ?: JSONObject.NULL)
                .put("text_content", item.textContent ?: JSONObject.NULL)
                .put("type", item.type)
                .put("favorite", item.favorite)
                .put("status", item.status)
                .put("return_at", item.returnAt ?: JSONObject.NULL)
                .put("created_at", item.createdAt)
                .put("updated_at", item.updatedAt)
                .put("deleted_at", item.deletedAt ?: JSONObject.NULL)
            post("items?on_conflict=id", body)

            val oldMetadata = JSONArray(NativeApi.call(base + "item_metadata?item_id=eq.${item.id}&select=structured_data")).optJSONObject(0)
            val previous = oldMetadata?.optJSONObject("structured_data")
                ?: oldMetadata?.optString("structured_data")?.let { runCatching { JSONObject(it) }.getOrNull() }
                ?: JSONObject()
            previous.put("tags", JSONArray(item.tags.split(",").map { it.trim() }.filter { it.isNotBlank() }))
                .put("category", item.category)
                .put("summary", item.summary)
                .put("formattedContent", item.formattedContent)
            post(
                "item_metadata?on_conflict=item_id",
                JSONObject()
                    .put("item_id", item.id)
                    .put("user_id", uid)
                    .put("status", "enriched")
                    .put("structured_data", previous)
                    .put("updated_at", item.updatedAt)
            )
            post(
                "item_notes?on_conflict=item_id",
                JSONObject()
                    .put("item_id", item.id)
                    .put("user_id", uid)
                    .put("content", item.notes)
                    .put("updated_at", item.updatedAt)
                    .put("deleted_at", if (item.notes.isBlank()) item.updatedAt else JSONObject.NULL)
            )

            val memberships = JSONArray(NativeApi.call(base + "collection_items?item_id=eq.${item.id}&user_id=eq.$uid&select=collection_id"))
            for (index in 0 until memberships.length()) {
                val id = memberships.getJSONObject(index).getString("collection_id")
                if (id != item.collectionId) {
                    NativeApi.call(
                        base + "collection_items?collection_id=eq.$id&item_id=eq.${item.id}&user_id=eq.$uid",
                        "PATCH",
                        JSONObject().put("deleted_at", item.updatedAt).put("updated_at", item.updatedAt)
                    )
                }
            }

            item.collectionId?.let { id ->
                database.collectionDao().getCollectionById(id)?.takeIf { it.deletedAt == null }?.let {
                    post(
                        "collection_items?on_conflict=collection_id,item_id",
                        JSONObject()
                            .put("collection_id", id)
                            .put("item_id", item.id)
                            .put("user_id", uid)
                            .put("created_at", item.createdAt)
                            .put("updated_at", item.updatedAt)
                            .put("deleted_at", JSONObject.NULL)
                    )
                }
            }

            CloudFileService.upload(context, item, uid)
            dao.markSyncedIfUnchanged(item.id, item.updatedAt, Instant.now().toString(), uid)
        }
    }
}
