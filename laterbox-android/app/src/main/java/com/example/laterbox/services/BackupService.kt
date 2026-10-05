package com.example.laterbox.services

import android.content.Context
import com.example.laterbox.data.local.AppDatabase
import com.example.laterbox.data.local.ItemEntity
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.util.UUID
import java.util.zip.ZipEntry
import java.util.zip.ZipInputStream
import java.util.zip.ZipOutputStream

object BackupService {
    private val json = Json { ignoreUnknownKeys = true }
    suspend fun export(context: Context): File = withContext(Dispatchers.IO) {
        val items = AppDatabase.getDatabase(context).itemDao().getAllItems()
        val folder = File(context.cacheDir, "exports").apply { mkdirs() }
        val target = File(folder, "LaterBox-${System.currentTimeMillis()}.zip")
        ZipOutputStream(target.outputStream()).use { zip ->
            val captures = File(context.filesDir, "captures").canonicalPath + File.separator
            val exported = mutableSetOf<String>()
            items.forEach { item ->
                val files = JSONArray(item.attachments)
                for (index in 0 until files.length()) {
                    val file = File(files.getJSONObject(index).optString("path"))
                    if (file.exists() && file.canonicalPath.startsWith(captures) && exported.add(file.name)) {
                        zip.putNextEntry(ZipEntry("files/${file.name}")); file.inputStream().use { it.copyTo(zip) }; zip.closeEntry()
                    }
                }
            }
            zip.putNextEntry(ZipEntry("items.json")); zip.write(json.encodeToString(items).toByteArray()); zip.closeEntry()
        }
        target
    }
    suspend fun import(context: Context, uri: android.net.Uri): Int = withContext(Dispatchers.IO) {
        val directory = File(context.filesDir, "captures").apply { mkdirs() }
        val copies = mutableMapOf<String, File>(); var manifest: String? = null; var total = 0L
        try {
            context.contentResolver.openInputStream(uri)?.use { input -> ZipInputStream(input).use { zip ->
                var entry = zip.nextEntry
                while (entry != null) {
                    val name = entry.name
                    if (name == "items.json") { val bytes = zip.readNBytes(10 * 1024 * 1024 + 1); require(bytes.size <= 10 * 1024 * 1024); manifest = bytes.toString(Charsets.UTF_8) }
                    else if (!entry.isDirectory && name.startsWith("files/") && !name.removePrefix("files/").contains('/') && !name.contains("..")) {
                        val target = File(directory, UUID.randomUUID().toString() + "-" + name.removePrefix("files/").filter { it.isLetterOrDigit() || it == '.' || it == '-' }.take(100))
                        copies[name.removePrefix("files/")] = target
                        target.outputStream().use { output -> val buffer = ByteArray(65536); while (true) { val count = zip.read(buffer); if (count < 0) break; total += count; require(total <= 500L * 1024 * 1024) { "Backup exceeds 500 MB" }; output.write(buffer, 0, count) } }
                    }
                    zip.closeEntry(); entry = zip.nextEntry
                }
            } } ?: error("Cannot read this backup")
            val items = json.decodeFromString<List<ItemEntity>>(requireNotNull(manifest) { "Not a LaterBox backup" })
            val store = VaultStore(context); var imported = 0
            for (item in items) {
                if (store.database.itemDao().getItemById(item.id) != null) continue
                val files = JSONArray(item.attachments)
                for (index in 0 until files.length()) { val attachment = files.getJSONObject(index); val copied = copies[File(attachment.optString("path")).name]; attachment.put("path", copied?.absolutePath ?: "") }
                store.save(item.copy(userId = AccountService.state.value.userId, syncStatus = "pending", collectionId = null, attachments = files.toString())); imported++
            }
            imported
        } catch (failure: Exception) { copies.values.forEach { it.delete() }; throw failure }
    }
    suspend fun clearTrash(context: Context) {
        val dao = AppDatabase.getDatabase(context).itemDao()
        val all = dao.getAllItems()
        val active = all.filter { it.deletedAt == null }.flatMap { item -> val files = JSONArray(item.attachments); (0 until files.length()).map { files.getJSONObject(it).optString("path") } }.toSet()
        all.filter { it.deletedAt != null }.forEach { item ->
            val files = JSONArray(item.attachments)
            for (index in 0 until files.length()) {
                val file = File(files.getJSONObject(index).optString("path"))
                if (file.path !in active && file.canonicalPath.startsWith(File(context.filesDir, "captures").canonicalPath + File.separator)) file.delete()
            }
            dao.deletePermanently(item.id)
        }
    }
}
