package com.example.laterbox.data

import android.content.Context
import androidx.room.withTransaction
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
    val trash: Flow<List<ItemEntity>> get() = kotlinx.coroutines.flow.flowOf(emptyList())
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
    fun watchMetadata(itemId: String): Flow<ItemMetadataEntity?> = kotlinx.coroutines.flow.flow { emit(getMetadata(itemId)) }
    suspend fun getMetadata(itemId: String): ItemMetadataEntity?

    suspend fun addCollection(name: String, colorHex: String = "#F59E0B", iconName: String = "folder"): CollectionEntity
    suspend fun renameCollection(id: String, name: String) { error("Collection renaming is unavailable.") }
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

    override val items: Flow<List<ItemEntity>> = kotlinx.coroutines.flow.combine(database.itemDao().watchAllItems(), com.example.laterbox.services.AccountService.state) { items, account -> items.filter { it.userId == null || it.userId == account.userId } }
    override val trash: Flow<List<ItemEntity>> = kotlinx.coroutines.flow.combine(database.itemDao().watchTrash(), com.example.laterbox.services.AccountService.state) { items, account -> items.filter { it.userId == null || it.userId == account.userId } }
    override val collections: Flow<List<CollectionEntity>> = kotlinx.coroutines.flow.combine(database.collectionDao().watchAllCollections(), com.example.laterbox.services.AccountService.state) { collections, account -> collections.filter { it.userId == null || it.userId == account.userId } }

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
        val store = com.example.laterbox.services.VaultStore(context)
        val draft = com.example.laterbox.services.VaultStore.draft(text ?: url.orEmpty(), title.orEmpty(), returnAt = returnAt).copy(collectionId = collectionId)
        val item = store.save(draft)
        scope.launch { store.metadata(item); syncNow() }
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
        val status = if (returnAt != null) "deferred" else "inbox"
        database.itemDao().updateReturnAt(id, returnAt, status, now)
        database.itemDao().getItemById(id)?.let { com.example.laterbox.services.ReturnsService.schedule(context, it) }
        syncNow()
    }

    override suspend fun deleteItem(id: String) {
        val now = DateTimeFormatter.ISO_INSTANT.format(Instant.now())
        database.itemDao().softDelete(id, now)
        androidx.work.WorkManager.getInstance(context).cancelUniqueWork("return-$id")
        syncNow()
    }

    override fun watchMetadata(itemId: String): Flow<ItemMetadataEntity?> = database.itemMetadataDao().watchMetadataById(itemId)

    override suspend fun getMetadata(itemId: String): ItemMetadataEntity? {
        return database.itemMetadataDao().getMetadataById(itemId)
    }

    override suspend fun addCollection(name: String, colorHex: String, iconName: String): CollectionEntity {
        val now = DateTimeFormatter.ISO_INSTANT.format(Instant.now())
        val collection = CollectionEntity(
            id = UUID.randomUUID().toString(),
            userId = com.example.laterbox.services.AccountService.state.value.userId,
            name = name.trim(),
            colorHex = colorHex,
            iconName = iconName,
            createdAt = now,
            updatedAt = now
        )
        require(collection.name.isNotBlank())
        database.collectionDao().insertCollection(collection)
        syncNow()
        return collection
    }

    override suspend fun renameCollection(id: String, name: String) {
        val trimmed = name.trim()
        require(trimmed.isNotBlank()) { "Enter a collection name." }
        database.withTransaction {
            val current = database.collectionDao().getCollectionById(id) ?: error("Collection no longer exists.")
            require(current.userId == null || current.userId == com.example.laterbox.services.AccountService.state.value.userId)
            require(database.collectionDao().getAllCollections().none { it.id != id && it.deletedAt == null && it.userId == current.userId && it.name.equals(trimmed, true) }) { "A collection with this name already exists." }
            val now = Instant.now().toString()
            database.collectionDao().updateCollection(current.copy(name = trimmed, updatedAt = now, syncStatus = "pending"))
            database.itemDao().getAllItems().filter {
                (it.userId == null || it.userId == com.example.laterbox.services.AccountService.state.value.userId) &&
                    (it.collectionId == id || it.collectionId == null && it.category.trim().equals(current.name, true))
            }.forEach {
                database.itemDao().updateItem(it.copy(collectionId = id, category = trimmed, updatedAt = now, syncStatus = "pending"))
            }
        }
        syncNow()
    }

    override suspend fun deleteCollection(id: String) {
        database.withTransaction {
            val current = database.collectionDao().getCollectionById(id) ?: error("Collection no longer exists.")
            require(current.userId == null || current.userId == com.example.laterbox.services.AccountService.state.value.userId)
            val now = Instant.now().toString()
            database.collectionDao().deleteCollection(id, now)
            database.itemDao().getAllItems().filter {
                (it.userId == null || it.userId == com.example.laterbox.services.AccountService.state.value.userId) &&
                    (it.collectionId == id || it.collectionId == null && it.category.trim().equals(current.name, true))
            }.forEach { database.itemDao().updateItem(it.copy(collectionId = null, category = "", updatedAt = now, syncStatus = "pending")) }
        }
        syncNow()
    }

    override fun syncNow() {
        val account = com.example.laterbox.services.AccountService.state.value
        if (account.userId == null || !account.pro) return
        try {
            val syncRequest = OneTimeWorkRequestBuilder<SyncWorker>().build()
            WorkManager.getInstance(context).enqueueUniqueWork("cloud-sync", androidx.work.ExistingWorkPolicy.KEEP, syncRequest)
        } catch (e: Exception) {
            // Log or fallback
        }
    }
}
