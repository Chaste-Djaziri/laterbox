package com.example.laterbox.data.local

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
@Entity(tableName = "items")
data class ItemEntity(
    @PrimaryKey
    val id: String,
    @SerialName("user_id") @ColumnInfo(name = "user_id") val userId: String? = null,
    val url: String? = null,
    val title: String? = null,
    @SerialName("text_content") @ColumnInfo(name = "text_content") val textContent: String? = null,
    @SerialName("text_selector") @ColumnInfo(name = "text_selector") val textSelector: String? = null,
    val type: String = "unknown",
    val favorite: Boolean = false,
    val status: String = "inbox",
    @SerialName("return_at") @ColumnInfo(name = "return_at") val returnAt: String? = null,
    @SerialName("created_at") @ColumnInfo(name = "created_at") val createdAt: String,
    @SerialName("updated_at") @ColumnInfo(name = "updated_at") val updatedAt: String,
    @SerialName("sync_status") @ColumnInfo(name = "sync_status") val syncStatus: String = "pending",
    @SerialName("last_synced_at") @ColumnInfo(name = "last_synced_at") val lastSyncedAt: String? = null,
    @SerialName("deleted_at") @ColumnInfo(name = "deleted_at") val deletedAt: String? = null
)
