package pro.micorp.laterbox

import android.content.Intent
import android.os.Bundle
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val pendingShares by lazy { PendingShareQueue(applicationContext) }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enqueueShareIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        )
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "consumeShares" -> {
                    result.success(pendingShares.readPending().map(PendingShareCapture::toMap))
                }
                "acknowledgeShares" -> {
                    val ids = call.argument<List<String>>("ids")?.toSet().orEmpty()
                    result.success(pendingShares.acknowledge(ids))
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            FILE_OPEN_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method != "openFile") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val path = call.argument<String>("path")
            val mimeType = call.argument<String>("mimeType") ?: "*/*"
            if (path.isNullOrBlank()) {
                result.error("invalid_path", "A file path is required.", null)
                return@setMethodCallHandler
            }

            try {
                val file = File(path).canonicalFile
                val filesRoot = filesDir.canonicalFile
                if (!file.exists() || !file.isFile || !file.path.startsWith("${filesRoot.path}${File.separator}")) {
                    result.error("unavailable", "The file is unavailable.", null)
                    return@setMethodCallHandler
                }
                val uri = FileProvider.getUriForFile(
                    this,
                    "$packageName.fileprovider",
                    file,
                )
                val intent = Intent(Intent.ACTION_VIEW).apply {
                    setDataAndType(uri, mimeType)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                if (intent.resolveActivity(packageManager) == null) {
                    result.error("no_handler", "No application can open this file.", null)
                    return@setMethodCallHandler
                }
                startActivity(intent)
                result.success(true)
            } catch (error: Exception) {
                result.error("open_failed", error.message, null)
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        enqueueShareIntent(intent)
    }

    private fun enqueueShareIntent(intent: Intent?) {
        if (intent?.action != Intent.ACTION_SEND) return
        if (intent.type?.startsWith("text/") != true) return

        val text = intent.getStringExtra(Intent.EXTRA_TEXT)
            ?.trim()
            ?.takeIf { it.isNotEmpty() }
            ?: return

        intent.action = null
        pendingShares.enqueue(text)
    }

    companion object {
        private const val CHANNEL = "laterbox/android_share"
        private const val FILE_OPEN_CHANNEL = "laterbox/file_open"
    }
}
