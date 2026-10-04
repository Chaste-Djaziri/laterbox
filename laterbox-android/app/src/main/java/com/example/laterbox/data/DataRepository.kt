package com.example.laterbox.data

import android.content.Context
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import com.example.laterbox.data.api.LaterBoxApiService
import com.example.laterbox.data.api.SystemStatusResponse
import com.example.laterbox.data.local.AppDatabase
import com.example.laterbox.data.local.CollectionEntity
import com.example.laterbox.data.local.ItemEntity
import com.example.laterbox.data.local.ItemMetadataEntity
import com.example.laterbox.data.sync.SyncWorker
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.time.Instant
import java.time.format.DateTimeFormatter
import java.util.UUID

interface DataRepository {
    val items: Flow<List<ItemEntity>>
    val collections: Flow<List<CollectionEntity>>
    val webStatus: StateFlow<SystemStatusResponse>

    fun refreshWebStatus()
    suspend fun captureItem(
        url: String?,
        text: String?,
        title: String?,
        returnAt: String? = null,
        collectionId: String? = null
    ): ItemEntity

    suspend fun updateItemStatus(id: String, status: String)
    suspend fun toggleFavorite(id: String, currentFavorite: Boolean)
    suspend fun scheduleReturn(id: String, returnAt: String?)
    suspend fun deleteItem(id: String)
    suspend fun getMetadata(itemId: String): ItemMetadataEntity?

    suspend fun addCollection(name: String, colorHex: String = "#F59E0B", iconName: String = "folder"): CollectionEntity
    suspend fun deleteCollection(id: String)

    fun syncNow()
}

class DefaultDataRepository(
    private val context: Context,
    private val database: AppDatabase
) : DataRepository {

    private val scope = CoroutineScope(Dispatchers.IO)
    private val _webStatus = MutableStateFlow(
        SystemStatusResponse(
            status = "operational",
            label = "Checking Systems...",
            indicator = "emerald",
            isOperational = true
        )
    )
    override val webStatus: StateFlow<SystemStatusResponse> = _webStatus.asStateFlow()

    init {
        refreshWebStatus()
    }

    override val items: Flow<List<ItemEntity>> = database.itemDao().watchAllItems()
    override val collections: Flow<List<CollectionEntity>> = database.collectionDao().watchAllCollections()

    override fun refreshWebStatus() {
        scope.launch {
            val status = LaterBoxApiService.fetchSystemStatus()
            _webStatus.value = status
        }
    }

    override suspend fun captureItem(
        url: String?,
        text: String?,
        title: String?,
        returnAt: String?,
        collectionId: String?
    ): ItemEntity {
        val now = DateTimeFormatter.ISO_INSTANT.format(Instant.now())
        val itemId = UUID.randomUUID().toString()

        var resolvedType = "link"
        if (url == null && text != null) {
            resolvedType = "note"
        }

        val item = ItemEntity(
            id = itemId,
            url = url,
            title = title ?: (if (!url.isNullOrEmpty()) url else "Quick Note"),
            textContent = text,
            type = resolvedType,
            status = if (returnAt != null) "returned" else "inbox",
            returnAt = returnAt,
            createdAt = now,
            updatedAt = now,
            syncStatus = "pending"
        )

        database.itemDao().insertItem(item)

        // Web enrichment integration
        if (!url.isNullOrEmpty()) {
            scope.launch {
                val enrichment = LaterBoxApiService.enrichUrl(url)
                if (enrichment != null) {
                    val metadata = ItemMetadataEntity(
                        itemId = itemId,
                        domain = enrichment.domain,
                        siteName = enrichment.siteName,
                        title = enrichment.title ?: item.title,
                        description = enrichment.description,
                        faviconUrl = enrichment.faviconUrl,
                        previewImageUrl = enrichment.previewImageUrl,
                        contentType = enrichment.contentType,
                        status = "enriched",
                        enrichedAt = DateTimeFormatter.ISO_INSTANT.format(Instant.now()),
                        createdAt = now,
                        updatedAt = now
                    )
                    database.itemMetadataDao().insertMetadata(metadata)

                    // Update item title and type if enrichment found better info
                    if (!enrichment.title.isNullOrEmpty() || enrichment.contentType != "link") {
                        val updated = item.copy(
                            title = enrichment.title ?: item.title,
                            type = enrichment.contentType,
                            updatedAt = DateTimeFormatter.ISO_INSTANT.format(Instant.now())
                        )
                        database.itemDao().updateItem(updated)
                    }
                }
            }
        }

        // Trigger background sync
        syncNow()

        return item
    }

    override suspend fun updateItemStatus(id: String, status: String) {
        val now = DateTimeFormatter.ISO_INSTANT.format(Instant.now())
        database.itemDao().updateStatus(id, status, now)
        syncNow()
    }

    override suspend fun toggleFavorite(id: String, currentFavorite: Boolean) {
        val now = DateTimeFormatter.ISO_INSTANT.format(Instant.now())
        database.itemDao().updateFavorite(id, !currentFavorite, now)
        syncNow()
    }

    override suspend fun scheduleReturn(id: String, returnAt: String?) {
        val now = DateTimeFormatter.ISO_INSTANT.format(Instant.now())
        val status = if (returnAt != null) "returned" else "inbox"
        database.itemDao().updateReturnAt(id, returnAt, status, now)
        syncNow()
    }

    override suspend fun deleteItem(id: String) {
        val now = DateTimeFormatter.ISO_INSTANT.format(Instant.now())
        database.itemDao().softDelete(id, now)
        syncNow()
    }

    override suspend fun getMetadata(itemId: String): ItemMetadataEntity? {
        return database.itemMetadataDao().getMetadataById(itemId)
    }

    override suspend fun addCollection(name: String, colorHex: String, iconName: String): CollectionEntity {
        val now = DateTimeFormatter.ISO_INSTANT.format(Instant.now())
        val collection = CollectionEntity(
            id = UUID.randomUUID().toString(),
            name = name,
            colorHex = colorHex,
            iconName = iconName,
            createdAt = now,
            updatedAt = now
        )
        database.collectionDao().insertCollection(collection)
        return collection
    }

    override suspend fun deleteCollection(id: String) {
        database.collectionDao().deleteCollection(id)
    }

    override fun syncNow() {
        try {
            val syncRequest = OneTimeWorkRequestBuilder<SyncWorker>().build()
            WorkManager.getInstance(context).enqueue(syncRequest)
        } catch (e: Exception) {
            // Log or fallback
        }
    }
}
