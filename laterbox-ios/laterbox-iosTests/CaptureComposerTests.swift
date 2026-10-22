// laterbox-ios/laterbox-iosTests/CaptureComposerTests.swift
import Foundation
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
