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

    @Test fun `youtube id extraction extracts canonical ids from all forms`() {
        assertEquals("abc_123", extractYouTubeIdFromUrl("https://youtu.be/abc_123?t=30"))
        assertEquals("abc_123", extractYouTubeIdFromUrl("https://www.youtube.com/watch?v=abc_123&feature=share"))
        assertEquals("abc_123", extractYouTubeIdFromUrl("https://youtube.com/shorts/abc_123"))
        assertEquals("abc_123", extractYouTubeIdFromUrl("https://www.youtube.com/embed/abc_123"))
        assertEquals("abc_123", extractYouTubeIdFromUrl("https://m.youtube.com/watch?v=abc_123"))
        assertNull(extractYouTubeIdFromUrl("https://example.com/video"))
    }

    @Test fun `preview image url sanitization cleans protocol and replaces letterboxed youtube covers`() {
        assertEquals("https://cdn.example.com/img.jpg", sanitizePreviewImageUrl("//cdn.example.com/img.jpg"))
        assertEquals("https://img.youtube.com/vi/abc/mqdefault.jpg", sanitizePreviewImageUrl("https://img.youtube.com/vi/abc/hqdefault.jpg"))
        assertEquals("https://i.ytimg.com/vi/abc/mqdefault.jpg", sanitizePreviewImageUrl("https://i.ytimg.com/vi/abc/sddefault.jpg"))
        assertEquals("https://example.com/photo.png", sanitizePreviewImageUrl("https://example.com/photo.png"))
        assertNull(sanitizePreviewImageUrl("not-a-url"))
    }

    @Test fun `image attachments are extracted from json representations`() {
        val objectJson = """[{"path":"/storage/note.pdf","mime":"application/pdf"},{"path":"/storage/cover.jpg","mime":"image/jpeg"}]"""
        assertEquals("/storage/cover.jpg", extractFirstImageAttachment(objectJson))

        val arrayJson = """["/storage/doc.txt", "/storage/avatar.webp"]"""
        assertEquals("/storage/avatar.webp", extractFirstImageAttachment(arrayJson))

        val nonImageJson = """[{"path":"/storage/note.pdf","mime":"application/pdf"}]"""
        assertNull(extractFirstImageAttachment(nonImageJson))
    }

    @Test fun `resolveEffectivePreviewImageUrl prioritizes metadata then youtube then direct images then attachments`() {
        // 1. Metadata takes precedence
        assertEquals(
            "https://cdn.example.com/preview.jpg",
            resolveEffectivePreviewImageUrl(
                previewImageUrl = "https://cdn.example.com/preview.jpg",
                itemUrl = "https://youtu.be/12345"
            )
        )

        // 2. YouTube derivation if metadata missing
        assertEquals(
            "https://img.youtube.com/vi/12345/mqdefault.jpg",
            resolveEffectivePreviewImageUrl(
                previewImageUrl = null,
                itemUrl = "https://youtu.be/12345"
            )
        )

        // 3. Direct image url if type is image or url is image
        assertEquals(
            "https://example.com/graphic.png",
            resolveEffectivePreviewImageUrl(
                previewImageUrl = null,
                itemUrl = "https://example.com/graphic.png",
                itemType = "image"
            )
        )

        // 4. Attachments if url is not image
        assertEquals(
            "/captures/photo.jpg",
            resolveEffectivePreviewImageUrl(
                previewImageUrl = null,
                itemUrl = "https://example.com/article",
                itemType = "file",
                attachments = """[{"path":"/captures/photo.jpg","mime":"image/jpeg"}]"""
            )
        )

        // 5. Plain note without image returns null
        assertNull(
            resolveEffectivePreviewImageUrl(
                previewImageUrl = null,
                itemUrl = null,
                itemType = "note",
                textContent = "Just a quick note to remember"
            )
        )
    }
}
