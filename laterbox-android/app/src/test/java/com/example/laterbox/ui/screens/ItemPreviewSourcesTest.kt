package com.example.laterbox.ui.screens

import org.junit.Assert.*
import org.junit.Test
import java.io.File
import java.nio.file.Files

class ItemPreviewSourcesTest {
    @Test fun `supported hosted links resolve to canonical embeds`() {
        assertEquals("https://www.youtube.com/embed/abc_123", hostedMediaPreview("https://youtu.be/abc_123?t=30"))
        assertEquals("https://www.youtube.com/embed/abc_123", hostedMediaPreview("https://www.youtube.com/watch?v=abc_123&feature=share"))
        assertEquals("https://www.youtube.com/embed/abc_123", hostedMediaPreview("https://youtube.com/shorts/abc_123"))
        assertEquals("https://player.vimeo.com/video/1234", hostedMediaPreview("https://vimeo.com/1234"))
        assertEquals("https://open.spotify.com/embed/track/abc123", hostedMediaPreview("https://open.spotify.com/intl-de/track/abc123?si=test"))
        assertEquals("https://embed.music.apple.com/us/album/example/123", hostedMediaPreview("https://music.apple.com/us/album/example/123"))
    }

    @Test fun `arbitrary hosts schemes and malformed identifiers do not become embeds`() {
        listOf(null, "invalid", "javascript:alert(1)", "https://youtube.com.evil.test/watch?v=123", "https://example.com/watch?v=123", "https://youtu.be/abc%22", "https://vimeo.com/not-a-video", "https://open.spotify.com/user/example").forEach { assertNull(hostedMediaPreview(it)) }
    }

    @Test fun `direct media detection ignores query strings and case`() {
        assertEquals("video", directMediaKind("https://example.com/VIDEO.MP4?signature=test"))
        assertEquals("pdf", directMediaKind("https://example.com/book.pdf?download=1"))
        assertEquals("audio", directMediaKind("https://example.com/song.mp3"))
        assertEquals("image", directMediaKind("https://example.com/photo.webp"))
        assertNull(directMediaKind("file:///private/image.png"))
        assertNull(directMediaKind("https://example.com/article"))
    }

    @Test fun `attachment previews reject paths outside capture storage`() {
        val root = Files.createTempDirectory("item-preview-test").toFile()
        try {
            val captures = File(root, "captures").apply { mkdirs() }
            val valid = File(captures, "note.txt").apply { writeText("note") }
            val privateFile = File(root, "private.txt").apply { writeText("private") }
            assertEquals(valid.canonicalFile, trustedAttachment(valid.path, captures))
            assertNull(trustedAttachment(privateFile.path, captures))
            assertNull(trustedAttachment(File(captures, "../private.txt").path, captures))
            assertNull(trustedAttachment(File(captures, "missing.txt").path, captures))
            assertNull(trustedAttachment(captures.path, captures))
        } finally { root.deleteRecursively() }
    }
}
