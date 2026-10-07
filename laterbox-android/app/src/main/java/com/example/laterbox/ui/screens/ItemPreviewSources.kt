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
