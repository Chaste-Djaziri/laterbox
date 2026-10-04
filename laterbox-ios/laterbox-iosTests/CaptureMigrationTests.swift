import Testing
import SwiftData
import Foundation
@testable import laterbox_ios

@MainActor
struct CaptureMigrationTests {
    @Test func legacyItemSurvivesClassificationUpgrade() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("capture.store")
        do {
            let schema = Schema([LegacyCaptureSchema.LBItem.self])
            let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, url: url))
            let item = LegacyCaptureSchema.LBItem(title: "Before upgrade", textContent: "Original content", noteContent: "Personal note")
            container.mainContext.insert(item)
            try container.mainContext.save()
        }
        let schema = Schema([LBItem.self])
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, url: url))
        let item = try #require(container.mainContext.fetch(FetchDescriptor<LBItem>()).first)
        #expect(item.title == "Before upgrade")
        #expect(item.textContent == "Original content" && item.noteContent == "Personal note")
        #expect(item.tags.isEmpty && item.category.isEmpty && item.summary.isEmpty && item.formattedContent.isEmpty)
    }
}

// The pre-upgrade entity shape. Matching the leaf entity name exercises real lightweight migration.
private enum LegacyCaptureSchema {
@Model
final class LBItem {
    @Attribute(.unique) var id: String
    var userId: String?
    var url: String?
    var title: String
    var textContent: String?
    var textSelector: String?
    var type: String
    var favorite: Bool
    var status: String
    var returnAt: Date?
    var createdAt: Date
    var updatedAt: Date

    // Enriched metadata fields
    var domain: String?
    var siteName: String?
    var metadataDescription: String?
    var faviconUrl: String?
    var previewImageUrl: String?
    var enrichmentStatus: String

    // Notes & Collection
    var noteContent: String?
    var collectionId: String?
    var collectionName: String?

    // Sync state
    var isSyncPending: Bool

    init(
        id: String = UUID().uuidString,
        userId: String? = nil,
        url: String? = nil,
        title: String,
        textContent: String? = nil,
        textSelector: String? = nil,
        type: ItemContentType = .link,
        favorite: Bool = false,
        status: ItemStatus = .inbox,
        returnAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        domain: String? = nil,
        siteName: String? = nil,
        metadataDescription: String? = nil,
        faviconUrl: String? = nil,
        previewImageUrl: String? = nil,
        enrichmentStatus: String = "pending",
        noteContent: String? = nil,
        collectionId: String? = nil,
        collectionName: String? = nil,
        isSyncPending: Bool = true
    ) {
        self.id = id
        self.userId = userId
        self.url = url
        self.title = title
        self.textContent = textContent
        self.textSelector = textSelector
        self.type = type.rawValue
        self.favorite = favorite
        self.status = status.rawValue
        self.returnAt = returnAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.domain = domain
        self.siteName = siteName
        self.metadataDescription = metadataDescription
        self.faviconUrl = faviconUrl
        self.previewImageUrl = previewImageUrl
        self.enrichmentStatus = enrichmentStatus
        self.noteContent = noteContent
        self.collectionId = collectionId
        self.collectionName = collectionName
        self.isSyncPending = isSyncPending
    }

    var parsedContentType: ItemContentType {
        ItemContentType(rawValue: type) ?? .link
    }

    var parsedStatus: ItemStatus {
        ItemStatus(rawValue: status) ?? .inbox
    }
}

}
