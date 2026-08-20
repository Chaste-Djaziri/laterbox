package com.example.laterbox

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.net.Uri
import android.os.Bundle
import android.provider.OpenableColumns
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView
import java.io.File
import java.time.Instant
import java.util.UUID

class ShareReceiverActivity : Activity() {

    private data class StagedShare(val paths: List<String>, val failureCount: Int)

    private lateinit var pendingShares: PendingShareQueue
    private lateinit var spinner: ProgressBar
    private lateinit var icon: TextView
    private lateinit var title: TextView
    private lateinit var subtitle: TextView
    private lateinit var actions: LinearLayout

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        pendingShares = PendingShareQueue(applicationContext)
        buildView()
        showSaving()
        handleShare(intent)
    }

    private fun buildView() {
        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(40), dp(40), dp(40), dp(40))
        }

        spinner = ProgressBar(this)
        spinner.visibility = View.GONE

        icon = TextView(this).apply {
            textSize = 44f
            gravity = Gravity.CENTER
            visibility = View.GONE
        }

        title = TextView(this).apply {
            textSize = 18f
            setTextColor(resolveAttr(android.R.attr.textColorPrimary))
            gravity = Gravity.CENTER
            typeface = Typeface.DEFAULT_BOLD
        }

        subtitle = TextView(this).apply {
            textSize = 14f
            setTextColor(resolveAttr(android.R.attr.textColorSecondary))
            gravity = Gravity.CENTER
            maxLines = 2
        }

        actions = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            visibility = View.GONE
        }

        val cancel = Button(this).apply {
            text = "Cancel"
            setOnClickListener { finish() }
        }
        val retry = Button(this).apply {
            text = "Try again"
            setOnClickListener {
                actions.visibility = View.GONE
                showSaving()
                handleShare(intent)
            }
        }
        actions.addView(cancel)
        actions.addView(retry)

        content.addView(spinner, centerParams())
        content.addView(icon, centerParams())
        content.addView(title, labelParams(topMargin = dp(8)))
        content.addView(subtitle, labelParams(topMargin = dp(4)))
        content.addView(actions, labelParams(topMargin = dp(20)))

        setContentView(content)
    }

    private fun handleShare(intent: Intent?) {
        if (intent == null || (intent.action != Intent.ACTION_SEND && intent.action != Intent.ACTION_SEND_MULTIPLE)) {
            showFailure("No shareable content found")
            return
        }

        val text = intent.getStringExtra(Intent.EXTRA_TEXT)
            ?.trim()
            ?.takeIf { it.isNotEmpty() }
            ?: intent.getStringExtra(Intent.EXTRA_SUBJECT)
                ?.trim()
                ?.takeIf { it.isNotEmpty() }
        val uris = sharedUris(intent)

        if (text == null && uris.isEmpty()) {
            showFailure("No shareable content found")
            return
        }

        val captureId = UUID.randomUUID().toString()
        Thread {
            val result = runCatching { stageSharedFiles(captureId, uris) }
            runOnUiThread {
                result.fold(
                    onSuccess = { staged ->
                        if (staged.paths.isEmpty() && text == null) {
                            deleteStagedCapture(captureId)
                            showFailure("Couldn't read the shared files")
                            return@fold
                        }
                        val capture = PendingShareCapture(
                            id = captureId,
                            text = text,
                            filePaths = staged.paths,
                            createdAt = Instant.now().toString(),
                        )
                        if (pendingShares.enqueue(capture)) {
                            val subtitle = when {
                                staged.failureCount > 0 ->
                                    "${staged.paths.size} saved, ${staged.failureCount} couldn't be read"
                                staged.paths.size > 1 -> "${staged.paths.size} files"
                                staged.paths.size == 1 -> File(staged.paths.first()).name
                                text != null -> displaySubtitle(text)
                                else -> null
                            }
                            showSuccess(subtitle)
                        } else {
                            deleteStagedCapture(captureId)
                            showFailure("Couldn't write to LaterBox storage")
                        }
                    },
                    onFailure = { error ->
                        deleteStagedCapture(captureId)
                        showFailure(error.message ?: "Couldn't read the shared files")
                    },
                )
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun sharedUris(intent: Intent): List<Uri> = when (intent.action) {
        Intent.ACTION_SEND -> listOfNotNull(intent.getParcelableExtra(Intent.EXTRA_STREAM) as? Uri)
        Intent.ACTION_SEND_MULTIPLE ->
            intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)?.toList().orEmpty()
        else -> emptyList()
    }.distinct()

    private fun stageSharedFiles(captureId: String, uris: List<Uri>): StagedShare {
        if (uris.isEmpty()) return StagedShare(emptyList(), 0)
        val directory = File(filesDir, "${PendingShareQueue.STAGING_DIRECTORY}/$captureId")
        check(directory.mkdirs() || directory.isDirectory) {
            "Couldn't create LaterBox staging storage"
        }
        val usedNames = mutableSetOf<String>()
        var failureCount = 0
        val paths = uris.mapIndexedNotNull { index, uri ->
            runCatching {
                val displayName = queryDisplayName(uri)
                    ?: fallbackFileName(uri, contentResolver.getType(uri) ?: intent?.type, index)
                val safeName = uniqueSafeName(displayName, usedNames)
                val destination = File(directory, safeName)
                contentResolver.openInputStream(uri)?.use { input ->
                    destination.outputStream().use { output -> input.copyTo(output) }
                } ?: error("Couldn't read ${displayName.take(80)}")
                destination.absolutePath
            }.getOrElse {
                failureCount += 1
                null
            }
        }
        return StagedShare(paths, failureCount)
    }

    private fun queryDisplayName(uri: Uri): String? = runCatching {
        contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { cursor ->
            if (!cursor.moveToFirst()) return@use null
            cursor.getString(cursor.getColumnIndexOrThrow(OpenableColumns.DISPLAY_NAME))
        }
    }.getOrNull()

    private fun fallbackFileName(uri: Uri, mimeType: String?, index: Int): String {
        val candidate = uri.lastPathSegment?.substringAfterLast('/')?.takeIf { it.contains('.') }
        if (candidate != null) return candidate
        val extension = android.webkit.MimeTypeMap.getSingleton()
            .getExtensionFromMimeType(mimeType)
            ?.takeIf { it.isNotBlank() }
            ?: "bin"
        return "shared-${index + 1}.$extension"
    }

    private fun uniqueSafeName(original: String, used: MutableSet<String>): String {
        val sanitized = original
            .replace(Regex("[\\/\\u0000-\\u001f]"), "_")
            .trim()
            .take(180)
            .ifEmpty { "shared-file" }
        val dot = sanitized.lastIndexOf('.')
        val stem = if (dot > 0) sanitized.substring(0, dot) else sanitized
        val extension = if (dot > 0) sanitized.substring(dot) else ""
        var candidate = sanitized
        var suffix = 2
        while (!used.add(candidate.lowercase())) {
            candidate = "$stem-$suffix$extension"
            suffix += 1
        }
        return candidate
    }

    private fun deleteStagedCapture(captureId: String) {
        File(filesDir, "${PendingShareQueue.STAGING_DIRECTORY}/$captureId").deleteRecursively()
    }

    private fun showSaving() {
        actions.visibility = View.GONE
        icon.visibility = View.GONE
        subtitle.visibility = View.GONE
        spinner.visibility = View.VISIBLE
        title.text = "Saving…"
    }

    private fun showSuccess(subtitle: String?) {
        actions.visibility = View.GONE
        spinner.visibility = View.GONE
        icon.visibility = View.VISIBLE
        icon.text = "✓"
        icon.setTextColor(Color.parseColor("#34C759"))
        title.text = "Saved to LaterBox"
        this.subtitle.text = subtitle ?: ""
        this.subtitle.visibility = if (subtitle == null) View.GONE else View.VISIBLE
        window.decorView.postDelayed({ finish() }, 800)
    }

    private fun showFailure(message: String) {
        spinner.visibility = View.GONE
        icon.visibility = View.VISIBLE
        icon.text = "!"
        icon.setTextColor(Color.parseColor("#FF3B30"))
        title.text = "Couldn't save"
        subtitle.text = message
        subtitle.visibility = View.VISIBLE
        actions.visibility = View.VISIBLE
    }

    private fun displaySubtitle(value: String): String? {
        val trimmed = value.trim()
        val host = if (trimmed.startsWith("http://") || trimmed.startsWith("https://")) {
            runCatching { Uri.parse(trimmed).host }.getOrNull()
        } else {
            null
        }
        if (!host.isNullOrEmpty()) return host.removePrefix("www.")
        return trimmed.take(60).ifEmpty { null }
    }

    private fun centerParams(): LinearLayout.LayoutParams =
        LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT)

    private fun labelParams(topMargin: Int): LinearLayout.LayoutParams =
        LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT).apply {
            this.topMargin = topMargin
        }

    private fun resolveAttr(attr: Int): Int {
        val typedValue = TypedValue()
        theme.resolveAttribute(attr, typedValue, true)
        return typedValue.data
    }

    private fun dp(value: Int): Int = (value * resources.displayMetrics.density).toInt()
}
