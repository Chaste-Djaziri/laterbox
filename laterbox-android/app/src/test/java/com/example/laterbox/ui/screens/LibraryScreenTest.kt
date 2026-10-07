package com.example.laterbox.ui.screens

import com.example.laterbox.data.local.CollectionEntity
import com.example.laterbox.data.local.ItemEntity
import org.junit.Assert.*
import org.junit.Test

class LibraryScreenTest {
    private fun item(id: String, status: String = "inbox", favorite: Boolean = false, folder: String? = null, category: String = "", deleted: String? = null) = ItemEntity(id = id, status = status, favorite = favorite, collectionId = folder, category = category, deletedAt = deleted, createdAt = "2026-10-07T12:00:00Z", updatedAt = "2026-10-07T12:00:00Z")
    @Test fun `category counts exclude trash and retain reviewed Android items`() {
        val items = listOf(item("favorite", favorite = true), item("saved", "saved"), item("done", "done"), item("archive", "archived"), item("trash", "deleted", favorite = true, deleted = "now"))
        assertEquals(listOf("favorite"), librarySectionItems(LibrarySection.FAVORITES, items).map { it.id })
        assertEquals(listOf("saved", "done"), librarySectionItems(LibrarySection.KEPT, items).map { it.id })
        assertEquals(listOf("archive"), librarySectionItems(LibrarySection.ARCHIVED, items).map { it.id })
        assertEquals(listOf("trash"), librarySectionItems(LibrarySection.DELETED, items).map { it.id })
    }
    @Test fun `folders include empty stored collections and legacy categories without duplicates`() {
        val collection = CollectionEntity("folder", name = "Reading", createdAt = "now", updatedAt = "now")
        val folders = libraryFolders(listOf(collection), listOf(item("one", category = "reading"), item("two", category = "Work"), item("deleted", category = "Trash category", deleted = "now")))
        assertEquals(listOf("Reading", "Work"), folders.map { it.name })
        assertEquals("folder", folders.first().collectionId)
    }
    @Test fun `collection lists include matching legacy items but never another collection or trash`() {
        val folder = LibraryFolder("folder", "Reading", "folder")
        val items = listOf(item("stored", folder = "folder"), item("legacy", category = "Reading"), item("other", folder = "other", category = "Reading"), item("trash", folder = "folder", deleted = "now"))
        assertEquals(listOf("stored", "legacy"), libraryFolderItems(folder, items).map { it.id })
    }
}
