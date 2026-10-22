import Foundation
import SwiftData

// A versioned, portable JSON archive. Attachment bytes are stored as base64 by Codable.
enum LibraryBackup {
    struct Archive: Codable {
        var version: Int
        var exportedAt: Date
        var items: [Item]
        var collections: [Collection]
    }

    struct Attachment: Codable {
        var metadata: SharedAttachment
        var bytes: Data?
    }

    struct Item: Codable {
        var id: String
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
        var domain: String?
        var siteName: String?
        var metadataDescription: String?
        var faviconUrl: String?
        var previewImageUrl: String?
        var enrichmentStatus: String
        var noteContent: String?
        var collectionId: String?
        var collectionName: String?
        var tags: [String]
        var category: String
        var summary: String
        var formattedContent: String
        var seen: Bool
        var attachments: [Attachment]

        init(_ source: LBItem) {
            id = source.id
            url = source.url
            title = source.title
            textContent = source.textContent
            textSelector = source.textSelector
            type = source.type
            favorite = source.favorite
            status = source.status
            returnAt = source.returnAt
            createdAt = source.createdAt
            updatedAt = source.updatedAt
            domain = source.domain
            siteName = source.siteName
            metadataDescription = source.metadataDescription
            faviconUrl = source.faviconUrl
            previewImageUrl = source.previewImageUrl
            enrichmentStatus = source.enrichmentStatus
            noteContent = source.noteContent
            collectionId = source.collectionId
            collectionName = source.collectionName
            tags = source.tags
            category = source.category
            summary = source.summary
            formattedContent = source.formattedContent
            seen = source.seen
            let references = source.attachmentsData.flatMap {
                try? JSONDecoder().decode([SharedAttachment].self, from: $0)
            } ?? []
            attachments = references.map { attachment in
                let bytes = (try? SharedCaptureStore.fileURL(attachment)).flatMap {
                    try? Data(contentsOf: $0)
                }
                return Attachment(metadata: attachment, bytes: bytes)
            }
        }
    }

    struct Collection: Codable {
        var id: String
        var name: String
        var colorHex: String
        var iconName: String
        var createdAt: Date
        var updatedAt: Date

        init(_ source: LBCollection) {
            id = source.id
            name = source.name
            colorHex = source.colorHex
            iconName = source.iconName
            createdAt = source.createdAt
            updatedAt = source.updatedAt
        }
    }

    struct Result {
        var items: Int
        var collections: Int
        var attachments: Int
        var skipped: Int
    }

    enum BackupError: LocalizedError {
        case unsupportedVersion
        case invalidArchive
        var errorDescription: String? {
            switch self {
            case .unsupportedVersion: "This backup uses an unsupported LaterBox format."
            case .invalidArchive: "The selected file is not a valid LaterBox backup."
            }
        }
    }

    @MainActor
    static func export(context: ModelContext) throws -> URL {
        let items = try context.fetch(FetchDescriptor<LBItem>())
        let collections = try context.fetch(FetchDescriptor<LBCollection>())
        let archive = Archive(version: 1, exportedAt: Date(),
                              items: items.map(Item.init), collections: collections.map(Collection.init))
        let data = try JSONEncoder().encode(archive)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("LaterBox-Backup-\(Int(Date().timeIntervalSince1970)).laterbox")
        try data.write(to: url, options: .atomic)
        return url
    }

    @MainActor
    static func importArchive(from file: URL, context: ModelContext) throws -> Result {
        let access = file.startAccessingSecurityScopedResource()
        defer { if access { file.stopAccessingSecurityScopedResource() } }
        let data = try Data(contentsOf: file)
        guard let archive = try? JSONDecoder().decode(Archive.self, from: data) else {
            throw BackupError.invalidArchive
        }
        guard archive.version == 1 else { throw BackupError.unsupportedVersion }
        let existingItems = try context.fetch(FetchDescriptor<LBItem>())
        let existingCollections = try context.fetch(FetchDescriptor<LBCollection>())
        var itemIDs = Set(existingItems.map(\.id))
        var collectionIDs = Set(existingCollections.map(\.id))
        var collectionNames = Set(existingCollections.map { $0.name.lowercased() })
        var result = Result(items: 0, collections: 0, attachments: 0, skipped: 0)
        var collectionRemap: [String: String] = [:]

        for collection in archive.collections {
            if collectionIDs.contains(collection.id) {
                collectionRemap[collection.id] = collection.id
                continue
            }
            if let match = existingCollections.first(where: { $0.name.caseInsensitiveCompare(collection.name) == .orderedSame }) {
                collectionRemap[collection.id] = match.id
                continue
            }
            guard !collectionNames.contains(collection.name.lowercased()) else { continue }
            let created = LBCollection(id: collection.id, name: collection.name,
                                       colorHex: collection.colorHex, iconName: collection.iconName,
                                       createdAt: collection.createdAt, updatedAt: collection.updatedAt)
            context.insert(created)
            collectionRemap[collection.id] = collection.id
            collectionIDs.insert(collection.id)
            collectionNames.insert(collection.name.lowercased())
            result.collections += 1
        }

        for entry in archive.items {
            guard !itemIDs.contains(entry.id) else {
                result.skipped += 1
                continue
            }
            guard ItemStatus(rawValue: entry.status) != nil, ItemContentType(rawValue: entry.type) != nil else {
                result.skipped += 1
                continue
            }
            let item = LBItem(id: entry.id, url: entry.url, title: entry.title,
                              textContent: entry.textContent, textSelector: entry.textSelector,
                              type: ItemContentType(rawValue: entry.type) ?? .link,
                              favorite: entry.favorite, status: ItemStatus(rawValue: entry.status) ?? .inbox,
                              returnAt: entry.returnAt, createdAt: entry.createdAt, updatedAt: entry.updatedAt,
                              domain: entry.domain, siteName: entry.siteName,
                              metadataDescription: entry.metadataDescription, faviconUrl: entry.faviconUrl,
                              previewImageUrl: entry.previewImageUrl, enrichmentStatus: entry.enrichmentStatus,
                              noteContent: entry.noteContent,
                              collectionId: entry.collectionId.flatMap { collectionRemap[$0] ?? $0 },
                              collectionName: entry.collectionName, isSyncPending: true, seen: entry.seen)
            item.tags = entry.tags
            item.category = entry.category
            item.summary = entry.summary
            item.formattedContent = entry.formattedContent
            var restored: [SharedAttachment] = []
            for attachment in entry.attachments {
                guard let bytes = attachment.bytes else { continue }
                // Never reuse paths embedded in an external archive.
                let safeName = (attachment.metadata.name as NSString).lastPathComponent
                let filename = safeName.isEmpty ? "attachment" : safeName
                let temporary = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString + "-" + filename)
                try bytes.write(to: temporary, options: .atomic)
                defer { try? FileManager.default.removeItem(at: temporary) }
                let copied = try SharedCaptureStore.copyFile(temporary, type: attachment.metadata.typeIdentifier)
                var metadata = copied
                metadata.name = attachment.metadata.name
                metadata.mimeType = attachment.metadata.mimeType
                metadata.byteSize = attachment.metadata.byteSize
                metadata.sha256 = attachment.metadata.sha256
                restored.append(metadata)
                result.attachments += 1
            }
            if !restored.isEmpty { item.attachmentsData = try JSONEncoder().encode(restored) }
            context.insert(item)
            itemIDs.insert(entry.id)
            result.items += 1
        }
        try context.save()
        return result
    }
}
