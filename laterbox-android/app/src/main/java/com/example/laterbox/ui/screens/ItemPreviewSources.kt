package com.example.laterbox.ui.screens

import java.io.File
import java.net.URI

internal fun hostedMediaPreview(url: String?): String? {
    val uri = runCatching { URI(url ?: return null) }.getOrNull() ?: return null
    if (uri.scheme !in listOf("https", "http")) return null
    val host = uri.host?.lowercase()?.removePrefix("www.") ?: return null
    val parts = uri.path.orEmpty().split('/').filter { it.isNotEmpty() }
    fun valid(value: String?) = value?.takeIf { it.matches(Regex("[A-Za-z0-9_-]+")) }
    return when (host) {
        "youtube.com", "m.youtube.com", "youtu.be" -> {
            val id = if (host == "youtu.be") parts.firstOrNull() else if (parts.firstOrNull() in listOf("shorts", "embed", "live")) parts.getOrNull(1)
                else uri.rawQuery.orEmpty().split('&').firstOrNull { it.startsWith("v=") }?.substringAfter('=')
            valid(id)?.let { "https://www.youtube.com/embed/$it" }
        }
        "vimeo.com", "player.vimeo.com" -> parts.lastOrNull()?.takeIf { it.all(Char::isDigit) && it.isNotEmpty() }?.let { "https://player.vimeo.com/video/$it" }
        "open.spotify.com" -> {
            val normalized = if (parts.firstOrNull()?.startsWith("intl-") == true) parts.drop(1) else parts
            val kind = normalized.firstOrNull()
            if (kind in listOf("track", "album", "playlist", "episode", "show")) valid(normalized.getOrNull(1))?.let { "https://open.spotify.com/embed/$kind/$it" } else null
        }
        "music.apple.com" -> "https://embed.music.apple.com${uri.rawPath}"
        else -> null
    }
}

internal fun trustedAttachment(path: String, captures: File): File? = runCatching {
    File(path).canonicalFile.takeIf { it.isFile && it.path.startsWith(captures.canonicalPath + File.separator) }
}.getOrNull()

internal fun directMediaKind(url: String?): String? {
    val uri = runCatching { URI(url ?: return null) }.getOrNull() ?: return null
    if (uri.scheme !in listOf("http", "https")) return null
    return when (uri.path.orEmpty().substringAfterLast('.').lowercase()) {
        "png", "jpg", "jpeg", "gif", "webp" -> "image"
        "mp4", "webm", "m4v", "mov" -> "video"
        "mp3", "m4a", "wav", "ogg", "aac" -> "audio"
        "pdf" -> "pdf"
        else -> null
    }
}

internal fun extractFirstImageAttachment(attachmentsJson: String?): String? {
    if (attachmentsJson.isNullOrBlank() || attachmentsJson == "[]") return null
    val imageExtensions = listOf(".png", ".jpg", ".jpeg", ".webp", ".gif", ".bmp")
    val pathRegex = Regex(""""path"\s*:\s*"([^"]+)"""")
    val mimeRegex = Regex(""""mime"\s*:\s*"([^"]+)"""")
    val directStringRegex = Regex(""""([^"]+\.(?:png|jpg|jpeg|webp|gif|bmp))"""", RegexOption.IGNORE_CASE)

    val pathMatches = pathRegex.findAll(attachmentsJson).toList()
    val mimeMatches = mimeRegex.findAll(attachmentsJson).toList()
    for (i in pathMatches.indices) {
        val path = pathMatches[i].groupValues[1]
        val mime = mimeMatches.getOrNull(i)?.groupValues?.get(1)?.lowercase()
        if (mime?.startsWith("image/") == true || imageExtensions.any { path.endsWith(it, ignoreCase = true) }) {
            return path
        }
    }

    directStringRegex.find(attachmentsJson)?.groupValues?.get(1)?.let { return it }

    return null
}

internal fun extractYouTubeIdFromUrl(url: String?): String? {
    if (url.isNullOrBlank()) return null
    hostedMediaPreview(url)?.let { youtubePreviewId(it) }?.let { return it }

    val patterns = listOf(
        Regex("""youtu\.be/([A-Za-z0-9_-]+)"""),
        Regex("""youtube\.com/(?:watch\?.*v=|shorts/|embed/|live/)([A-Za-z0-9_-]+)""")
    )
    for (pattern in patterns) {
        val match = pattern.find(url)
        if (match != null) {
            val id = match.groupValues[1]
            if (id.isNotEmpty() && id.matches(Regex("[A-Za-z0-9_-]+"))) {
                return id
            }
        }
    }
    return null
}

internal fun sanitizePreviewImageUrl(rawUrl: String?): String? {
    if (rawUrl.isNullOrBlank()) return null
    var trimmed = rawUrl.trim()
    if (trimmed.startsWith("//")) {
        trimmed = "https:$trimmed"
    }
    if (trimmed.contains("youtube.com") || trimmed.contains("ytimg.com")) {
        trimmed = trimmed.replace("/hqdefault.jpg", "/mqdefault.jpg")
            .replace("/sddefault.jpg", "/mqdefault.jpg")
    }
    return if (trimmed.startsWith("http://") || trimmed.startsWith("https://") || trimmed.startsWith("file://") || trimmed.startsWith("content://") || trimmed.startsWith("/")) {
        trimmed
    } else {
        null
    }
}

internal fun resolveEffectivePreviewImageUrl(
    previewImageUrl: String? = null,
    itemUrl: String? = null,
    itemType: String? = null,
    textContent: String? = null,
    attachments: String? = null
): String? {
    val sanitized = sanitizePreviewImageUrl(previewImageUrl)
    if (sanitized != null) return sanitized

    val youtubeId = extractYouTubeIdFromUrl(itemUrl) ?: extractYouTubeIdFromUrl(textContent)
    if (youtubeId != null) {
        return "https://img.youtube.com/vi/$youtubeId/mqdefault.jpg"
    }

    if (itemType.equals("image", ignoreCase = true) || directMediaKind(itemUrl) == "image") {
        val directImage = sanitizePreviewImageUrl(itemUrl)
        if (directImage != null) return directImage
    }

    val attachmentImage = extractFirstImageAttachment(attachments)
    if (attachmentImage != null) {
        return sanitizePreviewImageUrl(attachmentImage) ?: attachmentImage
    }

    return null
}

internal fun resolveEffectivePreviewImageUrl(
    item: com.example.laterbox.data.local.ItemEntity,
    metadata: com.example.laterbox.data.local.ItemMetadataEntity?
): String? {
    return resolveEffectivePreviewImageUrl(
        previewImageUrl = metadata?.previewImageUrl,
        itemUrl = item.url,
        itemType = item.type,
        textContent = item.textContent,
        attachments = item.attachments
    )
}

