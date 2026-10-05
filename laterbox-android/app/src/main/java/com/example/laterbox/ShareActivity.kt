package com.example.laterbox

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.OpenableColumns
import androidx.fragment.app.FragmentActivity
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import android.view.WindowManager
import com.example.laterbox.services.*
import androidx.activity.compose.setContent
import androidx.compose.runtime.*
import androidx.lifecycle.lifecycleScope
import com.example.laterbox.data.local.AppDatabase
import com.example.laterbox.theme.LaterboxTheme
import com.example.laterbox.ui.ai.LaterAIContent
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.util.UUID

class ShareActivity : FragmentActivity() {
    private var locked by mutableStateOf(false)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        locked = getSharedPreferences("laterbox", 0).getBoolean("app_lock", false)
        if (getSharedPreferences("laterbox", 0).getBoolean("screen_protection", false)) window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        lifecycleScope.launch {
            AccountService.refresh() 
            val text = intent.getCharSequenceExtra(Intent.EXTRA_TEXT)?.toString().orEmpty()
            val files = savedInstanceState?.getString("files") ?: withContext(Dispatchers.IO) { copyAttachments() }
            intent.putExtra("copied_files", files)
            setContent { LaterboxTheme {
                val items by com.example.laterbox.data.DefaultDataRepository(this@ShareActivity, AppDatabase.getDatabase(this@ShareActivity)).items.collectAsState(initial = emptyList())
                if (locked) Column(Modifier.padding(24.dp)) {
                    Text("Unlock to save to your private vault")
                    Button(onClick = { AppLockService.authenticate(this@ShareActivity, { locked = false }, {}) }) { Text("Unlock LaterBox") }
                    TextButton(onClick = { finish() }) { Text("Cancel") }
                } else LaterAIContent(items, text, files, onDismiss = { finish() }, onSaved = {
                    com.example.laterbox.data.DefaultDataRepository(this@ShareActivity, AppDatabase.getDatabase(this@ShareActivity)).syncNow()
                })
            } }
        }
    }
    @Suppress("DEPRECATION")
    private fun copyAttachments(): String {
        val uris = mutableListOf<Uri>()
        if (intent.action == Intent.ACTION_SEND_MULTIPLE) intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)?.let { uris.addAll(it) }
        else intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)?.let { uris.add(it) }
        intent.clipData?.let { clip -> for (index in 0 until clip.itemCount) clip.getItemAt(index).uri?.let { uris.add(it) } }
        val result = JSONArray()
        val directory = File(filesDir, "captures").apply { mkdirs() }
        for (uri in uris.distinct().take(20)) {
            // External providers' transient grants must be copied while the share Activity owns them.
            if (uri.scheme != "content") continue
            val name = runCatching { contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { cursor -> if (cursor.moveToFirst()) cursor.getString(0) else "Shared file" } }.getOrNull() ?: "Shared file"
            val extension = name.substringAfterLast('.', "").take(12).filter { it.isLetterOrDigit() }
            val file = File(directory, UUID.randomUUID().toString() + if (extension.isBlank()) "" else ".$extension")
            try {
                contentResolver.openInputStream(uri)?.use { input -> file.outputStream().use { output ->
                    val buffer = ByteArray(65536); var total = 0L
                    while (true) { val read = input.read(buffer); if (read == -1) break; total += read; require(total <= 100L * 1024 * 1024) { "Shared file exceeds 100 MB" }; output.write(buffer, 0, read) }
                } } ?: error("The shared file cannot be opened")
                result.put(JSONObject().put("name", name).put("path", file.absolutePath).put("mime", contentResolver.getType(uri) ?: "application/octet-stream").put("size", file.length()))
            } catch (failure: Exception) {
                file.delete()
                result.put(JSONObject().put("name", name).put("error", failure.message ?: "Unable to copy shared file"))
            }
        }
        return result.toString()
    }
    override fun onSaveInstanceState(outState: Bundle) { outState.putString("files", intent.getStringExtra("copied_files")); super.onSaveInstanceState(outState) }
}
