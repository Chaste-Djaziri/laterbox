package com.example.laterbox.services

import android.content.Context
import com.example.laterbox.data.api.LaterBoxApiService
import com.example.laterbox.data.local.ItemEntity
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest
import java.util.UUID

/** Uses the existing attachment-storage contract; local paths never leave the device. */
object CloudFileService {
    private val edge get() = LaterBoxApiService.supabaseUrl + "/functions/v1/attachment-storage"
    private val rest get() = LaterBoxApiService.supabaseUrl + "/rest/v1/attachments"
    internal fun hash(file: File): String {
        val digest = MessageDigest.getInstance("SHA-256")
        file.inputStream().use { input -> val buffer = ByteArray(65536); while (true) { val count = input.read(buffer); if (count < 0) break; digest.update(buffer, 0, count) } }
        return digest.digest().joinToString("") { "%02x".format(it) }
    }
    private fun transfer(url: String, method: String, headers: Map<String, String>, file: File, expectedSize: Long = 0) {
        require(URL(url).protocol == "https") { "Cloud storage requires HTTPS" }
        val connection = URL(url).openConnection() as HttpURLConnection
        try {
            connection.requestMethod = method; connection.connectTimeout = 15000; connection.readTimeout = 60000; connection.instanceFollowRedirects = false
            headers.forEach { (name, value) -> connection.setRequestProperty(name, value) }
            if (method == "PUT") {
                connection.doOutput = true; connection.setFixedLengthStreamingMode(file.length())
                connection.outputStream.use { output -> file.inputStream().use { it.copyTo(output) } }
                check(connection.responseCode in 200..299) { "Cloud attachment upload failed" }
            } else {
                check(connection.responseCode in 200..299) { "Cloud attachment download failed" }
                connection.inputStream.use { input -> file.outputStream().use { output ->
                    val buffer = ByteArray(65536); var total = 0L
                    while (true) {
                        val count = input.read(buffer); if (count < 0) break; total += count
                        if (expectedSize > 0) require(total <= expectedSize) { "Invalid cloud file size" }
                        require(total <= 104857600) { "Invalid cloud file size" }
                        output.write(buffer, 0, count)
                    }
                    if (expectedSize > 0) require(total == expectedSize) { "Incomplete cloud file" }
                } }
            }
        } finally { connection.disconnect() }
    }
    suspend fun upload(context: Context, item: ItemEntity, uid: String) = withContext(Dispatchers.IO) {
        check(AccountService.state.value.pro && AccountService.state.value.userId == uid)
        if (item.deletedAt != null) return@withContext
        val files = JSONArray(item.attachments)
        for (index in 0 until files.length()) {
            val attachment = files.getJSONObject(index); val file = File(attachment.getString("path"))
            require(file.isFile && file.canonicalPath.startsWith(File(context.filesDir, "captures").canonicalPath + File.separator)) { "Local file is missing; restore it before syncing" }
            val id = attachment.optString("id").takeIf { runCatching { UUID.fromString(it) }.isSuccess }
                ?: UUID.nameUUIDFromBytes("${item.id}:${file.name}".toByteArray()).toString()
            if (JSONArray(NativeApi.call("$rest?id=eq.$id&user_id=eq.$uid&select=id")).length() > 0) continue
            val name = attachment.optString("name", file.name)
            val extension = name.substringAfterLast('.', "bin").lowercase().filter { it.isLetterOrDigit() }.take(20).ifBlank { "bin" }
            val mime = attachment.optString("mime", "application/octet-stream"); val sha = hash(file)
            val body = JSONObject().put("attachmentId", id).put("itemId", item.id).put("originalFileName", name).put("extension", extension).put("mimeType", mime).put("byteSize", file.length()).put("sha256", sha)
            val prepared = JSONObject(NativeApi.call(edge, "POST", JSONObject(body.toString()).put("action", "prepare-upload")))
            transfer(prepared.getString("uploadUrl"), "PUT", mapOf("Content-Type" to mime, "x-amz-meta-sha256" to sha, "x-amz-meta-attachment-id" to id, "x-amz-meta-user-id" to uid), file)
            val completed = JSONObject(NativeApi.call(edge, "POST", JSONObject(body.toString()).put("action", "complete-upload")))
            check(completed.optBoolean("verified")) { "Cloud file verification failed" }
            check(AccountService.state.value.pro && AccountService.state.value.userId == uid)
            NativeApi.call("$rest?on_conflict=id", "POST", JSONObject().put("id", id).put("item_id", item.id).put("user_id", uid).put("original_file_name", name).put("file_extension", extension).put("mime_type", mime).put("byte_size", file.length()).put("sha256", sha).put("r2_object_key", completed.getString("objectKey")).put("created_at", item.createdAt).put("updated_at", item.updatedAt))
        }
    }
    suspend fun downloadAttachmentsForRows(
        context: Context,
        currentAttachmentsJson: String,
        rows: JSONArray,
        uid: String
    ): String = withContext(Dispatchers.IO) {
        val files = runCatching { JSONArray(currentAttachmentsJson) }.getOrDefault(JSONArray())
        val directory = File(context.filesDir, "captures").apply { mkdirs() }
        for (index in 0 until rows.length()) {
            val row = rows.getJSONObject(index)
            if (!row.isNull("deleted_at") && row.optString("deleted_at").isNotBlank()) continue
            val rawId = row.optString("id")
            val id = runCatching { UUID.fromString(rawId).toString() }.getOrNull() ?: continue
            val extension = row.optString("file_extension").filter { it.isLetterOrDigit() }.ifBlank { "bin" }
            val target = File(directory, "cloud-$id.$extension")
            val sha = row.optString("sha256")
            val byteSize = row.optLong("byte_size", 0L)
            val fileName = row.optString("original_file_name", "attachment.$extension")
            val mimeType = row.optString("mime_type", "application/octet-stream")

            val fileValid = target.isFile && (byteSize <= 0 || target.length() == byteSize) && (sha.isBlank() || hash(target).equals(sha, ignoreCase = true))
            if (!fileValid) {
                runCatching {
                    val prepared = JSONObject(
                        NativeApi.call(
                            edge,
                            "POST",
                            JSONObject().put("action", "prepare-download").put("attachmentId", id)
                        )
                    )
                    val downloadUrl = prepared.getString("downloadUrl")
                    val temp = File(directory, ".$id.partial")
                    try {
                        transfer(downloadUrl, "GET", emptyMap(), temp, byteSize)
                        if (sha.isNotBlank()) {
                            check(hash(temp).equals(sha, ignoreCase = true)) { "Cloud file checksum mismatch" }
                        }
                        if (target.exists()) target.delete()
                        check(temp.renameTo(target)) { "Failed to move temp attachment to target" }
                    } finally {
                        if (temp.exists()) temp.delete()
                    }
                }
            }

            if (target.isFile) {
                var matched = false
                for (fIndex in 0 until files.length()) {
                    val fObj = files.getJSONObject(fIndex)
                    val fId = fObj.optString("id")
                    val fPath = fObj.optString("path")
                    val isMatch = (fId.isNotBlank() && fId.equals(id, ignoreCase = true)) ||
                            (fPath.isNotBlank() && fPath == target.absolutePath) ||
                            (sha.isNotBlank() && File(fPath).isFile && hash(File(fPath)).equals(sha, ignoreCase = true))

                    if (isMatch) {
                        fObj.put("id", id)
                        if (fObj.optString("name").isBlank()) fObj.put("name", fileName)
                        fObj.put("path", target.absolutePath)
                        if (fObj.optString("mime").isBlank()) fObj.put("mime", mimeType)
                        fObj.put("size", target.length())
                        matched = true
                        break
                    }
                }
                if (!matched) {
                    files.put(
                        JSONObject()
                            .put("id", id)
                            .put("name", fileName)
                            .put("path", target.absolutePath)
                            .put("mime", mimeType)
                            .put("size", target.length())
                    )
                }
            }
        }
        files.toString()
    }
    suspend fun download(context: Context, item: ItemEntity, uid: String): String = withContext(Dispatchers.IO) {
        check(AccountService.state.value.pro && AccountService.state.value.userId == uid)
        val rows = JSONArray(NativeApi.call("$rest?item_id=eq.${item.id}&user_id=eq.$uid&deleted_at=is.null&select=*"))
        downloadAttachmentsForRows(context, item.attachments, rows, uid)
    }
    suspend fun restoreAllMissingAttachments(context: Context, uid: String) = withContext(Dispatchers.IO) {
        val account = AccountService.state.value
        if (!account.pro || account.userId != uid) return@withContext
        val rows = runCatching {
            JSONArray(NativeApi.call("$rest?user_id=eq.$uid&deleted_at=is.null&select=*"))
        }.getOrNull() ?: return@withContext

        val rowsByItemId = mutableMapOf<String, JSONArray>()
        for (i in 0 until rows.length()) {
            val row = rows.getJSONObject(i)
            val itemId = row.optString("item_id")
            if (itemId.isNotBlank()) {
                val list = rowsByItemId.getOrPut(itemId) { JSONArray() }
                list.put(row)
            }
        }

        val database = com.example.laterbox.data.local.AppDatabase.getDatabase(context)
        val dao = database.itemDao()
        for ((itemId, itemRows) in rowsByItemId) {
            val item = dao.getItemById(itemId) ?: continue
            val updated = downloadAttachmentsForRows(context, item.attachments, itemRows, uid)
            if (updated != item.attachments) {
                dao.replaceAttachmentsIfUnchanged(item.id, item.updatedAt, updated)
            }
        }
    }
}
