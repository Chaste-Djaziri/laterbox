package pro.micorp.laterbox

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
    private data class FormattedShareResult(val formattedText: String?, val targetUrl: String?)
    private data class EnrichedMetadata(
        val title: String?,
        val siteName: String?,
        val description: String?,
        val previewImageUrl: String?,
        val keywords: List<String>,
    )

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
        val validActions = setOf(
            Intent.ACTION_SEND,
            Intent.ACTION_SEND_MULTIPLE,
            Intent.ACTION_PROCESS_TEXT
        )
        if (intent == null || intent.action !in validActions) {
            showFailure("No shareable content found")
            return
        }

        val rawText = (intent.getStringExtra(Intent.EXTRA_PROCESS_TEXT)
            ?: intent.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)?.toString()
            ?: intent.getStringExtra(Intent.EXTRA_TEXT)
            ?: intent.getStringExtra(Intent.EXTRA_SUBJECT))
            ?.trim()
            ?.takeIf { it.isNotEmpty() }

        val referrerUrl = extractReferrerUrl(intent)
        val shareFormat = formatSharedText(rawText, referrerUrl)
        val text = shareFormat.formattedText
        val targetUrl = shareFormat.targetUrl
        val uris = sharedUris(intent)

        if (text == null && uris.isEmpty()) {
            showFailure("No shareable content found")
            return
        }

        val captureId = UUID.randomUUID().toString()
        Thread {
            val stagedResult = runCatching { stageSharedFiles(captureId, uris) }
            val enriched = if (targetUrl != null) fetchEnrichment(targetUrl) else null

            runOnUiThread {
                stagedResult.fold(
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
                            title = enriched?.title,
                            url = targetUrl,
                            previewImageUrl = enriched?.previewImageUrl,
                            siteName = enriched?.siteName,
                        )
                        if (pendingShares.enqueue(capture)) {
                            val subtitle = when {
                                staged.failureCount > 0 ->
                                    "${staged.paths.size} saved, ${staged.failureCount} couldn't be read"
                                staged.paths.size > 1 -> "${staged.paths.size} files"
                                staged.paths.size == 1 -> File(staged.paths.first()).name
                                !enriched?.title.isNullOrBlank() -> {
                                    val site = enriched?.siteName
                                    val pageTitle = enriched?.title
                                    if (!site.isNullOrBlank() && !pageTitle.contains(site, ignoreCase = true)) {
                                        "$site • $pageTitle"
                                    } else {
                                        pageTitle
                                    }
                                }
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
        }.start()
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

    private fun extractReferrerUrl(intent: Intent): String? {
        val extraReferrer = runCatching {
            intent.getParcelableExtra<Uri>(Intent.EXTRA_REFERRER)?.toString()
        }.getOrNull()
        if (extraReferrer?.startsWith("http") == true) return extraReferrer

        val extraReferrerName = intent.getStringExtra(Intent.EXTRA_REFERRER_NAME)
            ?: intent.getStringExtra("android.intent.extra.REFERRER_NAME")
            ?: intent.getStringExtra("android.intent.extra.ORIGINATING_URI")
        if (extraReferrerName?.startsWith("http") == true) return extraReferrerName

        val subject = intent.getStringExtra(Intent.EXTRA_SUBJECT)?.trim()
        if (subject?.startsWith("http://") == true || subject?.startsWith("https://") == true) {
            return subject
        }

        val dataString = intent.dataString?.trim()
        if (dataString?.startsWith("http://") == true || dataString?.startsWith("https://") == true) {
            return dataString
        }

        return null
    }

    private fun cleanUrl(rawUrl: String): String {
        return runCatching {
            val uri = Uri.parse(rawUrl)
            val queryNames = uri.queryParameterNames
            val trackingKeys = setOf(
                "utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content",
                "si", "igsh", "fbclid", "gclid", "ref", "ref_src", "feature", "share_id", "s"
            )
            if (queryNames.none { it.lowercase() in trackingKeys }) {
                return rawUrl
            }
            val builder = uri.buildUpon().clearQuery()
            for (name in queryNames) {
                if (name.lowercase() !in trackingKeys) {
                    for (value in uri.getQueryParameters(name)) {
                        builder.appendQueryParameter(name, value)
                    }
                }
            }
            builder.build().toString()
        }.getOrDefault(rawUrl)
    }

    private fun formatSharedText(raw: String?, referrer: String? = null): FormattedShareResult {
        if (raw.isNullOrBlank() && referrer.isNullOrBlank()) return FormattedShareResult(null, null)
        val trimmed = raw?.trim() ?: ""

        val urlRegex = Regex("(https?://[^\\s]+)")
        val match = urlRegex.find(trimmed)
        val rawTargetUrl = match?.value ?: referrer?.trim()

        if (rawTargetUrl != null && (rawTargetUrl.startsWith("http://") || rawTargetUrl.startsWith("https://"))) {
            val cleanedTargetUrl = cleanUrl(rawTargetUrl)
            val quote = trimmed.replace(rawTargetUrl, "").trim().trim('"', '“', '”', '\'', ' ', '\n', '\r')
            if (quote.isNotEmpty()) {
                if (cleanedTargetUrl.contains(":~:text=")) {
                    return FormattedShareResult(cleanedTargetUrl, cleanedTargetUrl)
                }
                val snippet = quote.take(120).trim()
                val encoded = runCatching { Uri.encode(snippet) }.getOrNull()
                if (!encoded.isNullOrEmpty()) {
                    val separator = if (cleanedTargetUrl.contains("#")) ":~:text=" else "#:~:text="
                    val fullUrlWithFragment = "$cleanedTargetUrl$separator$encoded"
                    return FormattedShareResult(fullUrlWithFragment, cleanedTargetUrl)
                }
                return FormattedShareResult("$cleanedTargetUrl\n$quote", cleanedTargetUrl)
            }
            return FormattedShareResult(cleanedTargetUrl, cleanedTargetUrl)
        }

        return FormattedShareResult(trimmed.ifEmpty { referrer }, null)
    }

    private fun isGenericTitle(title: String?): Boolean {
        val raw = title?.trim() ?: return true
        val stripped = raw.trim('-', '–', '—', '|', ':', '•', ' ', '\t', '\n', '\r')
        val lower = stripped.lowercase()
        return lower.isEmpty() ||
            lower == "youtube" ||
            lower == "- youtube" ||
            (lower.endsWith("youtube") && lower.length <= 14) ||
            lower.contains("video playlist") ||
            lower == "untitled" ||
            lower.startsWith("http://") ||
            lower.startsWith("https://") ||
            lower == "watch" ||
            lower == "before you continue to youtube"
    }

    private fun cleanTitle(title: String?): String? {
        val raw = title?.trim() ?: return null
        if (isGenericTitle(raw)) return null
        var cleaned = raw
        for (suffix in listOf(" - YouTube", " | YouTube", " – YouTube", " — YouTube", " - Vimeo", " | Vimeo")) {
            if (cleaned.endsWith(suffix, ignoreCase = true)) {
                cleaned = cleaned.dropLast(suffix.length).trim()
            }
        }
        return if (isGenericTitle(cleaned)) null else cleaned
    }

    private fun isGenericDescription(desc: String?): Boolean {
        val raw = desc?.lowercase()?.trim() ?: return true
        return raw.contains("enjoy the videos and music you love") ||
            raw.contains("upload original content") ||
            raw.contains("share it all with friends, family")
    }

    private fun fetchEnrichment(rawUrl: String): EnrichedMetadata? {
        return runCatching {
            var oembedTitle: String? = null
            var oembedThumb: String? = null
            var oembedAuthor: String? = null
            if (rawUrl.contains("youtube.com") || rawUrl.contains("youtu.be")) {
                runCatching {
                    val encoded = java.net.URLEncoder.encode(rawUrl, "UTF-8")
                    val oembedConn = (java.net.URL("https://www.youtube.com/oembed?url=$encoded&format=json").openConnection() as java.net.HttpURLConnection).apply {
                        connectTimeout = 3000
                        readTimeout = 3000
                    }
                    if (oembedConn.responseCode in 200..299) {
                        val ytJson = org.json.JSONObject(oembedConn.inputStream.bufferedReader().use { it.readText() })
                        val rawYtTitle = ytJson.optString("title").trim().takeIf { it.isNotEmpty() }
                        oembedTitle = cleanTitle(rawYtTitle) ?: rawYtTitle
                        oembedThumb = ytJson.optString("thumbnail_url").takeIf { it.isNotEmpty() }
                        oembedAuthor = ytJson.optString("author_name").takeIf { it.isNotEmpty() }
                    }
                }
            }

            val endpoint = java.net.URL("https://laterbox.dev/api/enrich")
            val conn = (endpoint.openConnection() as java.net.HttpURLConnection).apply {
                requestMethod = "POST"
                connectTimeout = 4000
                readTimeout = 4000
                doOutput = true
                setRequestProperty("Content-Type", "application/json; charset=UTF-8")
                setRequestProperty("Accept", "application/json")
            }

            val payload = org.json.JSONObject().apply {
                put("url", rawUrl)
            }.toString()

            conn.outputStream.use { os ->
                os.write(payload.toByteArray(Charsets.UTF_8))
            }

            if (conn.responseCode in 200..299) {
                val responseText = conn.inputStream.bufferedReader().use { it.readText() }
                val json = org.json.JSONObject(responseText)
                val rawTitle = json.optString("title").trim().takeIf { it.isNotEmpty() }
                val cleanedTitle = cleanTitle(rawTitle)
                val siteName = (json.optString("siteName").takeIf { it.isNotEmpty() }
                    ?: json.optString("site_name")).trim().takeIf { it.isNotEmpty() }
                val rawDesc = json.optString("description").trim().takeIf { it.isNotEmpty() }
                val description = if (rawDesc != null && !isGenericDescription(rawDesc)) rawDesc else oembedAuthor?.let { "Video by $it on YouTube" }
                val previewImageUrl = (json.optString("previewImageUrl").takeIf { it.isNotEmpty() }
                    ?: json.optString("preview_image_url")).trim().takeIf { it.isNotEmpty() } ?: oembedThumb
                val keywordsArray = json.optJSONArray("keywords") ?: org.json.JSONArray()
                val junk = setOf("sharing", "camera phone", "video phone", "free", "upload", "playlist", "video playlist", "youtube")
                val keywords = (0 until keywordsArray.length()).mapNotNull { i ->
                    keywordsArray.optString(i).trim().takeIf { it.isNotEmpty() && it.lowercase() !in junk }
                }

                val finalTitle = cleanedTitle ?: oembedTitle
                EnrichedMetadata(finalTitle, siteName ?: (if (rawUrl.contains("youtube")) "YouTube" else null), description, previewImageUrl, keywords)
            } else if (oembedTitle != null || oembedThumb != null) {
                EnrichedMetadata(oembedTitle, "YouTube", oembedAuthor?.let { "Video by $it on YouTube" }, oembedThumb, emptyList())
            } else {
                null
            }
        }.getOrNull()
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
