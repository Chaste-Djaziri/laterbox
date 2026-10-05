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
    private fun hash(file: File): String {
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
                    while (true) { val count = input.read(buffer); if (count < 0) break; total += count; require(total <= expectedSize && total <= 104857600) { "Invalid cloud file size" }; output.write(buffer, 0, count) }
                    require(total == expectedSize) { "Incomplete cloud file" }
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
    suspend fun download(context: Context, item: ItemEntity, uid: String): String = withContext(Dispatchers.IO) {
        check(AccountService.state.value.pro && AccountService.state.value.userId == uid)
        val rows = JSONArray(NativeApi.call("$rest?item_id=eq.${item.id}&user_id=eq.$uid&deleted_at=is.null&select=*"))
        val files = JSONArray(item.attachments)
        val directory = File(context.filesDir, "captures").apply { mkdirs() }
        for (index in 0 until rows.length()) {
            val row = rows.getJSONObject(index); val id = UUID.fromString(row.getString("id")).toString()
            val target = File(directory, "cloud-$id.${row.getString("file_extension").filter { it.isLetterOrDigit() }}")
            val sha = row.getString("sha256")
            if (!target.isFile || hash(target) != sha) {
                val prepared = JSONObject(NativeApi.call(edge, "POST", JSONObject().put("action", "prepare-download").put("attachmentId", id)))
                val temp = File(directory, ".$id.partial")
                try { transfer(prepared.getString("downloadUrl"), "GET", emptyMap(), temp, row.getLong("byte_size")); require(hash(temp) == sha) { "Cloud file checksum mismatch" }; check(temp.renameTo(target)) }
                finally { temp.delete() }
            }
            val existing = (0 until files.length()).map { files.getJSONObject(it) }.any { it.optString("id") == id || (File(it.optString("path")).isFile && hash(File(it.optString("path"))) == sha) }
            if (!existing) files.put(JSONObject().put("id", id).put("name", row.getString("original_file_name")).put("path", target.absolutePath).put("mime", row.getString("mime_type")).put("size", target.length()))
        }
        files.toString()
    }
}
