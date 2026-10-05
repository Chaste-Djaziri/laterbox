package com.example.laterbox.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import kotlinx.coroutines.flow.Flow

@Dao
interface ItemDao {
    @Query("UPDATE items SET attachments = :files WHERE id = :id AND updated_at = :version")
    suspend fun replaceAttachmentsIfUnchanged(id: String, version: String, files: String)

    @Query("SELECT * FROM items WHERE deleted_at IS NOT NULL ORDER BY deleted_at DESC")
    fun watchTrash(): Flow<List<ItemEntity>>

    @Query("SELECT * FROM items")
    suspend fun getAllItems(): List<ItemEntity>

    @Query("UPDATE items SET sync_status = 'synced', last_synced_at = :syncedAt, user_id = :userId WHERE id = :id AND updated_at = :version")
    suspend fun markSyncedIfUnchanged(id: String, version: String, syncedAt: String, userId: String)

    @Query("UPDATE items SET status = 'inbox', updated_at = :now, sync_status = 'pending' WHERE status = 'deferred' AND return_at <= :now AND deleted_at IS NULL")
    suspend fun promoteDue(now: String)

    @Query("UPDATE items SET deleted_at = NULL, status = 'inbox', updated_at = :now, sync_status = 'pending' WHERE id = :id")
    suspend fun restore(id: String, now: String)

    @Query("SELECT * FROM items WHERE deleted_at IS NULL ORDER BY created_at DESC")
    fun watchAllItems(): Flow<List<ItemEntity>>

    @Query("SELECT * FROM items WHERE id = :id")
    suspend fun getItemById(id: String): ItemEntity?

    @Query("SELECT * FROM items WHERE sync_status IN ('pending', 'failed')")
    suspend fun getItemsNeedingSync(): List<ItemEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertItem(item: ItemEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertItems(items: List<ItemEntity>)

    @Update
    suspend fun updateItem(item: ItemEntity)

    @Query("UPDATE items SET status = :status, updated_at = :updatedAt, sync_status = 'pending' WHERE id = :id")
    suspend fun updateStatus(id: String, status: String, updatedAt: String)

    @Query("UPDATE items SET favorite = :favorite, updated_at = :updatedAt, sync_status = 'pending' WHERE id = :id")
    suspend fun updateFavorite(id: String, favorite: Boolean, updatedAt: String)

    @Query("UPDATE items SET return_at = :returnAt, status = :status, updated_at = :updatedAt, sync_status = 'pending' WHERE id = :id")
    suspend fun updateReturnAt(id: String, returnAt: String?, status: String, updatedAt: String)

    @Query("UPDATE items SET deleted_at = :deletedAt, updated_at = :deletedAt, sync_status = 'pending' WHERE id = :id")
    suspend fun softDelete(id: String, deletedAt: String)

    @Query("DELETE FROM items WHERE id = :id")
    suspend fun deletePermanently(id: String)

    @Query("UPDATE items SET sync_status = 'synced', last_synced_at = :syncedAt WHERE id = :id")
    suspend fun markSynced(id: String, syncedAt: String)

    @Query("UPDATE items SET sync_status = 'failed' WHERE id = :id")
    suspend fun markFailed(id: String)
}
