package com.example.laterbox.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import kotlinx.coroutines.flow.Flow

@Dao
interface ItemDao {
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

    @Query("UPDATE items SET sync_status = 'synced', last_synced_at = :syncedAt WHERE id = :id")
    suspend fun markSynced(id: String, syncedAt: String)

    @Query("UPDATE items SET sync_status = 'failed' WHERE id = :id")
    suspend fun markFailed(id: String)
}
