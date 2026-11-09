// laterbox-ios/laterbox-iosTests/CaptureComposerTests.swift
import Foundation
import SwiftData
import Testing
@testable import laterbox_ios

struct CaptureComposerTests {
    @Test func quickNoteAndLinkUseSameDraftModel() {
        let note = CaptureDraft.manual("Remember to call home")
        #expect(note.type == .note)
        #expect(note.url == nil)

        let link = CaptureDraft.manual("Read https://example.com/article tomorrow")
        #expect(link.url == "https://example.com/article")
        #expect(link.type == .link)
    }

    @Test func shareImportPreservesFieldsAndIdentity() {
        var shared = SharedCapture()
        shared.id = UUID().uuidString
        shared.content = "https://example.org/article"
        shared.title = "Shared article"
        shared.category = "Reading"
        shared.tags = ["reference", "reading"]
        shared.returnAt = Date(timeIntervalSince1970: 1_900_000_000)
        shared.previewImageUrl = "https://example.org/preview.png"
        shared.metadataDescription = "An interesting article"

        let draft = CaptureDraft.fromShared(shared)
        #expect(draft.id == shared.id)
        #expect(draft.title == shared.title)
        #expect(draft.content == shared.content)
        #expect(draft.collectionName == shared.category)
        #expect(draft.category == shared.category)
        #expect(draft.tags == shared.tags)
        #expect(draft.returnAt == shared.returnAt)
        #expect(draft.previewImageUrl == shared.previewImageUrl)
        #expect(draft.metadataDescription == shared.metadataDescription)
        #expect(draft.type == .link)
    }

    @Test func inboxIsAMailboxNotAnAutoCreatedCollection() {
        #expect(SharedCaptureCollections.normalizedName("Inbox") == nil)
        #expect(SharedCaptureCollections.normalizedName(" INBOX ") == nil)
        #expect(SharedCaptureCollections.normalizedName("No collection") == nil)
        #expect(SharedCaptureCollections.available(["Inbox", "Reading", "reading", "Trash"]) == ["Reading"])
        #expect(SharedCaptureCollections.existingName("Reading", in: []) == nil)
        #expect(SharedCaptureCollections.existingName("reading", in: ["Reading"]) == "Reading")
        #expect(SharedCaptureCollections.existingName("New AI Collection", in: ["Reading"]) == nil)

        // Both notes and links without a real collection must remain unassigned.
        #expect(LaterAISharedAnalyzer.quickSuggestions(content: "A quick note", collections: []).category.isEmpty)
        #expect(LaterAISharedAnalyzer.quickSuggestions(
            content: "https://youtu.be/example", collections: []
        ).category.isEmpty)
    }

    @Test @MainActor func legacyInboxShareImportsWithoutCollection() throws {
        let schema = Schema([LBItem.self, LBCollection.self])
        let container = try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        var capture = SharedCapture()
        capture.content = "Unassigned share"
        capture.category = " Inbox "
        let item = try SyncCoordinator.shared.saveDraft(
            CaptureDraft.fromShared(capture), context: container.mainContext
        )
        #expect(item.category.isEmpty)
        #expect(item.collectionName == nil)
        #expect(item.collectionId == nil)
        #expect(try container.mainContext.fetch(FetchDescriptor<LBCollection>()).isEmpty)
    }

    @Test @MainActor func signOutErasesEveryLocalUserRecordAndSharedCapture() throws {
        let container = try ModelContainer(
            for: Schema([LBItem.self, LBCollection.self]),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        context.insert(LBItem(userId: "account-A", title: "Synced item", isSyncPending: false))
        context.insert(LBItem(userId: "account-A", title: "Offline unsynced item", isSyncPending: true))
        context.insert(LBItem(title: "Guest draft"))
        context.insert(LBItem(userId: "account-A", title: "Recently Deleted", status: .deleted))
        context.insert(LBCollection(userId: "account-A", name: "Research"))
        context.insert(LBCollection(name: "Guest collection"))
        try context.save()

        // Use a sandboxed test directory. Never erase the actual app group from tests.
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("LaterBoxSignOutTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        for folder in ["Captures", "Attachments"] {
            let path = root.appendingPathComponent(folder, isDirectory: true)
            try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
            try Data("private content".utf8).write(to: path.appendingPathComponent("private.txt"))
        }
        for name in ["cached_collections.json", "ai_settings.json"] {
            try Data("private settings".utf8).write(to: root.appendingPathComponent(name))
        }
        let unrelated = root.appendingPathComponent("unrelated-file.txt")
        try Data("keep".utf8).write(to: unrelated)

        try LocalAccountDataEraser.erase(context: context, sharedRoot: root)

        #expect(try context.fetch(FetchDescriptor<LBItem>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<LBCollection>()).isEmpty)
        for name in ["Captures", "Attachments", "cached_collections.json", "ai_settings.json"] {
            #expect(!FileManager.default.fileExists(atPath: root.appendingPathComponent(name).path))
        }
        #expect(FileManager.default.fileExists(atPath: unrelated.path),
                "Sign out must not erase unrelated content in the shared container")
    }

    @Test func openGraphRelativeImageAndEntities() {
        let html = #"""
        <html><head>
          <meta content="/images/social.png?first=1&amp;second=2" property="og:image" />
        </head></html>
        """#
        let page = URL(string: "https://example.org/blog/post")!
        #expect(LaterAISharedAnalyzer.openGraphImage(in: html, relativeTo: page) ==
                "https://example.org/images/social.png?first=1&second=2")
    }

    @Test func openGraphPrefersSecureImageRegardlessOfTagOrder() {
        let html = #"""
        <meta property="og:image" content="http://example.org/default.jpg">
        <meta content="https://example.org/secure.jpg" property="og:image:secure_url">
        """#
        let page = URL(string: "https://example.org/article")!
        #expect(LaterAISharedAnalyzer.openGraphImage(in: html, relativeTo: page) ==
                "https://example.org/secure.jpg")
    }

    @Test func openGraphRejectsUnsafeImageAndFallsBackToTwitter() {
        let html = #"""
        <meta property="og:image" content="javascript:alert(1)">
        <meta name="twitter:image" content="https://cdn.example.org/preview.jpg">
        """#
        let page = URL(string: "https://example.org/article")!
        #expect(LaterAISharedAnalyzer.openGraphImage(in: html, relativeTo: page) ==
                "https://cdn.example.org/preview.jpg")
    }

    @Test func fileOnlySharesAreValidAndKeepTheirType() {
        var shared = SharedCapture()
        shared.attachments = [
            SharedAttachment(name: "report.pdf",
                             relativePath: "Attachments/report.pdf",
                             typeIdentifier: "com.adobe.pdf")
        ]
        let draft = CaptureDraft.fromShared(shared)
        #expect(draft.content.isEmpty)
        #expect(draft.attachments == shared.attachments)
        #expect(draft.type == .document)

        shared.attachments = [
            SharedAttachment(name: "clip.mp4",
                             relativePath: "Attachments/clip.mp4",
                             typeIdentifier: "public.mpeg-4")
        ]
        #expect(CaptureDraft.fromShared(shared).type == .video)
    }
}
