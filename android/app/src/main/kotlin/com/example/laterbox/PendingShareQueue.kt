package com.example.laterbox

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject
import java.io.File
import java.util.UUID

data class PendingShareCapture(
    val id: String,
    val text: String?,
    val filePaths: List<String>,
    val createdAt: String,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "id" to id,
        "text" to text,
        "filePaths" to filePaths,
        "createdAt" to createdAt,
    )
}

class PendingShareQueue(private val context: Context) {
    private val prefs: SharedPreferences =
        context.getSharedPreferences("laterbox_pending_shares", Context.MODE_PRIVATE)

    @Synchronized
    fun enqueue(capture: PendingShareCapture): Boolean {
        val items = readAll().toMutableList()
        items.add(capture)
        return write(items)
    }

    @Synchronized
    fun enqueue(value: String): Boolean = enqueue(
        PendingShareCapture(
            id = UUID.randomUUID().toString(),
            text = value,
            filePaths = emptyList(),
            createdAt = java.time.Instant.now().toString(),
        ),
    )

    @Synchronized
    fun readPending(): List<PendingShareCapture> {
        val items = readAll()
        write(items)
        return items
    }

    @Synchronized
    fun acknowledge(ids: Set<String>): Boolean {
        if (ids.isEmpty()) return true
        val remaining = readAll().filterNot { it.id in ids }
        val written = write(remaining)
        if (written) ids.forEach(::deleteStagingDirectory)
        return written
    }

    @Synchronized
    fun size(): Int = readAll().size

    private fun readAll(): List<PendingShareCapture> {
        val raw = prefs.getString(KEY, null) ?: return emptyList()
        return try {
            val array = JSONArray(raw)
            (0 until array.length()).mapNotNull { index ->
                when (val entry = array.get(index)) {
                    is JSONObject -> entry.toCapture()
                    is String -> PendingShareCapture(
                        id = UUID.randomUUID().toString(),
                        text = entry,
                        filePaths = emptyList(),
                        createdAt = java.time.Instant.now().toString(),
                    )
                    else -> null
                }
            }
        } catch (error: JSONException) {
            emptyList()
        }
    }

    private fun write(items: List<PendingShareCapture>): Boolean {
        if (items.isEmpty()) return prefs.edit().remove(KEY).commit()
        val array = JSONArray()
        items.forEach { capture ->
            array.put(
                JSONObject().apply {
                    put("id", capture.id)
                    put("text", capture.text)
                    put("filePaths", JSONArray(capture.filePaths))
                    put("createdAt", capture.createdAt)
                },
            )
        }
        return prefs.edit().putString(KEY, array.toString()).commit()
    }

    private fun JSONObject.toCapture(): PendingShareCapture? {
        val id = optString("id").takeIf { it.isNotBlank() } ?: return null
        val text = optString("text").takeIf { it.isNotBlank() }
        val paths = optJSONArray("filePaths") ?: JSONArray()
        return PendingShareCapture(
            id = id,
            text = text,
            filePaths = (0 until paths.length()).mapNotNull { index ->
                paths.optString(index).takeIf { it.isNotBlank() }
            },
            createdAt = optString("createdAt").takeIf { it.isNotBlank() }
                ?: java.time.Instant.now().toString(),
        )
    }

    private fun deleteStagingDirectory(id: String) {
        val root = File(context.filesDir, STAGING_DIRECTORY)
        val directory = File(root, id)
        val rootPath = runCatching { root.canonicalPath }.getOrNull() ?: return
        val directoryPath = runCatching { directory.canonicalPath }.getOrNull() ?: return
        if (directoryPath.startsWith("$rootPath${File.separator}")) {
            directory.deleteRecursively()
        }
    }

    companion object {
        private const val KEY = "pendingShares"
        const val STAGING_DIRECTORY = "PendingAttachments"
    }
}
