package com.example.laterbox.data.local

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
@Entity(tableName = "item_metadata")
data class ItemMetadataEntity(
    @PrimaryKey
    @SerialName("item_id") @ColumnInfo(name = "item_id") val itemId: String,
    @SerialName("user_id") @ColumnInfo(name = "user_id") val userId: String? = null,
    val domain: String? = null,
    @SerialName("site_name") @ColumnInfo(name = "site_name") val siteName: String? = null,
    val title: String? = null,
    val description: String? = null,
    @SerialName("favicon_url") @ColumnInfo(name = "favicon_url") val faviconUrl: String? = null,
    @SerialName("preview_image_url") @ColumnInfo(name = "preview_image_url") val previewImageUrl: String? = null,
    val status: String = "pending",
    @SerialName("attempt_count") @ColumnInfo(name = "attempt_count") val attemptCount: Int = 0,
    @SerialName("last_error") @ColumnInfo(name = "last_error") val lastError: String? = null,
    @SerialName("metadata_version") @ColumnInfo(name = "metadata_version") val metadataVersion: Int = 1,
    @SerialName("enriched_at") @ColumnInfo(name = "enriched_at") val enrichedAt: String? = null,
    @SerialName("content_type") @ColumnInfo(name = "content_type") val contentType: String = "link",
    @SerialName("classification_source") @ColumnInfo(name = "classification_source") val classificationSource: String? = null,
    @SerialName("classification_confidence") @ColumnInfo(name = "classification_confidence") val classificationConfidence: Double = 0.0,
    @SerialName("structured_data") @ColumnInfo(name = "structured_data") val structuredData: String? = null,
    @SerialName("created_at") @ColumnInfo(name = "created_at") val createdAt: String,
    @SerialName("updated_at") @ColumnInfo(name = "updated_at") val updatedAt: String
)
