package com.example.laterbox.ui.screens

import org.junit.Assert.*
import org.junit.Test

class YouTubePreviewTest {
    @Test fun `only canonical YouTube embeds enter the player`() {
        assertEquals("abc_123", youtubePreviewId("https://www.youtube.com/embed/abc_123"))
        assertNull(youtubePreviewId("https://www.youtube.com.evil.test/embed/abc_123"))
        assertNull(youtubePreviewId("https://www.youtube.com/embed/abc/other"))
        assertNull(youtubePreviewId("https://open.spotify.com/embed/track/example"))
    }

    @Test fun `player identifies the app and removes failed embeds`() {
        val document = youtubePlayerDocument("abc_123", "https://com.example.laterbox")
        assertTrue(document.contains("origin:'https://com.example.laterbox'"))
        assertTrue(document.contains("strict-origin-when-cross-origin"))
        assertTrue(document.contains("onError:function(){fallback();}"))
        assertTrue(document.contains("p.remove()"))
        assertFalse(document.contains("autoplay:1"))
    }

    @Test fun `player document rejects values that could inject script`() {
        assertThrows(IllegalArgumentException::class.java) { youtubePlayerDocument("abc';alert(1)", "https://com.example.laterbox") }
        assertThrows(IllegalArgumentException::class.java) { youtubePlayerDocument("abc", "https://example.com/'") }
    }
}
