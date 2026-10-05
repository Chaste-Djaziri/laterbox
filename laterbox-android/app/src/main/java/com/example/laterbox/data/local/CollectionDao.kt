package com.example.laterbox.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import kotlinx.coroutines.flow.Flow

@Dao
interface CollectionDao {
    @Query("SELECT * FROM collections WHERE deleted_at IS NULL AND (user_id IS NULL OR user_id = :userId) AND name = :name COLLATE NOCASE LIMIT 1")
    suspend fun findByName(name: String, userId: String?): CollectionEntity?

    @Query("SELECT * FROM collections WHERE deleted_at IS NULL ORDER BY name ASC")
    fun watchAllCollections(): Flow<List<CollectionEntity>>

    @Query("SELECT * FROM collections WHERE id = :id")
    suspend fun getCollectionById(id: String): CollectionEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertCollection(collection: CollectionEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertCollections(collections: List<CollectionEntity>)

    @Update
    suspend fun updateCollection(collection: CollectionEntity)

    @Query("SELECT * FROM collections")
    suspend fun getAllCollections(): List<CollectionEntity>

    @Query("UPDATE collections SET deleted_at = :now, updated_at = :now, sync_status = 'pending' WHERE id = :id")
    suspend fun deleteCollection(id: String, now: String)

    @Query("UPDATE collections SET sync_status = 'synced', user_id = :userId WHERE id = :id AND updated_at = :version")
    suspend fun markSynced(id: String, version: String, userId: String)
}
