package com.example.laterbox.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import kotlinx.coroutines.flow.Flow

@Dao
interface ItemMetadataDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertMetadata(metadata: ItemMetadataEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertMetadataList(metadata: List<ItemMetadataEntity>)

    @Update
    suspend fun updateMetadata(metadata: ItemMetadataEntity)

    @Query("SELECT * FROM item_metadata WHERE item_id = :itemId")
    suspend fun getMetadataById(itemId: String): ItemMetadataEntity?

    @Query("SELECT * FROM item_metadata")
    suspend fun getAllMetadata(): List<ItemMetadataEntity>
}
