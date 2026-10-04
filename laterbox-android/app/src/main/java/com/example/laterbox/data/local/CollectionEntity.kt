package com.example.laterbox.data.local

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
@Entity(tableName = "collections")
data class CollectionEntity(
    @PrimaryKey
    val id: String,
    @SerialName("user_id") @ColumnInfo(name = "user_id") val userId: String? = null,
    val name: String,
    @SerialName("color_hex") @ColumnInfo(name = "color_hex") val colorHex: String = "#F59E0B",
    @SerialName("icon_name") @ColumnInfo(name = "icon_name") val iconName: String = "folder",
    @SerialName("created_at") @ColumnInfo(name = "created_at") val createdAt: String,
    @SerialName("updated_at") @ColumnInfo(name = "updated_at") val updatedAt: String,
    @SerialName("sync_status") @ColumnInfo(name = "sync_status") val syncStatus: String = "synced"
)
