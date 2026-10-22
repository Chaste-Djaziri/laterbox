import Foundation
import SwiftData
import UserNotifications
import CryptoKit
import CommonCrypto

// A versioned, portable JSON archive. Attachment bytes are stored as base64 by Codable.
enum LibraryBackup {
    nonisolated struct Archive: Codable, Sendable {
        var version: Int
        var exportedAt: Date
        var items: [Item]
        var collections: [Collection]
    }

    nonisolated struct Attachment: Codable, Sendable {
        var metadata: SharedAttachment
        var bytes: Data?
    }

    nonisolated struct Item: Codable, Sendable {
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
        var inboxEnteredAt: Date?
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
            inboxEnteredAt = source.inboxEnteredAt
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

    nonisolated struct Collection: Codable, Sendable {
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

    // Encrypted backups use PBKDF2-SHA256 and AES-256-GCM.
    nonisolated struct EncryptedArchive: Codable, Sendable {
        var format: String
        var salt: Data
        var rounds: Int
        var sealed: Data
    }

    nonisolated static func derivedKey(password: String, salt: Data, rounds: Int) throws -> SymmetricKey {
        guard !password.isEmpty, rounds >= 100_000 && rounds <= 2_000_000 else {
            throw BackupError.invalidArchive
        }
        var keyBytes = [UInt8](repeating: 0, count: 32)
        let status = password.withCString { passwordBytes in
            salt.withUnsafeBytes { saltBytes in
                CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2), passwordBytes,
                                    password.utf8.count,
                                    saltBytes.bindMemory(to: UInt8.self).baseAddress, salt.count,
                                    CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                                    UInt32(rounds), &keyBytes, keyBytes.count)
            }
        }
        guard status == kCCSuccess else { throw BackupError.invalidArchive }
        defer { keyBytes.withUnsafeMutableBytes { $0.initializeMemory(as: UInt8.self, repeating: 0) } }
        return SymmetricKey(data: keyBytes)
    }

    nonisolated static func encrypt(_ data: Data, password: String) throws -> Data {
        guard password.count >= 8 else { throw BackupError.invalidArchive }
        let salt = Data((0..<16).map { _ in UInt8.random(in: 0...255) })
        let rounds = 250_000
        let key = try derivedKey(password: password, salt: salt, rounds: rounds)
        let sealed = try AES.GCM.seal(data, using: key)
        let envelope = EncryptedArchive(format: "laterbox-encrypted-v1", salt: salt,
                                        rounds: rounds, sealed: sealed.combined!)
        return try JSONEncoder().encode(envelope)
    }

    nonisolated static func decrypt(_ data: Data, password: String) throws -> Data {
        guard let envelope = try? JSONDecoder().decode(EncryptedArchive.self, from: data),
              envelope.format == "laterbox-encrypted-v1" else { throw BackupError.invalidArchive }
        let key = try derivedKey(password: password, salt: envelope.salt, rounds: envelope.rounds)
        return try AES.GCM.open(AES.GCM.SealedBox(combined: envelope.sealed), using: key)
    }

    struct ImportPreview {
        let total: Int
        let newItems: Int
        let conflicts: [(id: String, title: String)]
    }

    @MainActor
    static func inspectImport(from file: URL, password: String, context: ModelContext) async throws -> ImportPreview {
        let archive = try await Task.detached(priority: .userInitiated) {
            let access = file.startAccessingSecurityScopedResource()
            defer { if access { file.stopAccessingSecurityScopedResource() } }
            let data = try decrypt(Data(contentsOf: file), password: password)
            return try JSONDecoder().decode(Archive.self, from: data)
        }.value
        guard archive.version == 1 else { throw BackupError.unsupportedVersion }
        let ids = Set(try context.fetch(FetchDescriptor<LBItem>()).map(\.id))
        let conflicts = archive.items.filter { ids.contains($0.id) }
            .map { (id: $0.id, title: $0.title) }
        return ImportPreview(total: archive.items.count,
                             newItems: archive.items.count - conflicts.count,
                             conflicts: conflicts)
    }

    @MainActor
    static func exportAsync(context: ModelContext, password: String,
                            progress: @escaping @MainActor (Double) -> Void) async throws -> URL {
        let items = try context.fetch(FetchDescriptor<LBItem>())
        let collections = try context.fetch(FetchDescriptor<LBCollection>())
        var records: [Item] = []
        for (index, item) in items.enumerated() {
            records.append(Item(item))
            if index % 10 == 0 {
                progress(Double(index + 1) / Double(max(items.count, 1)) * 0.7)
                await Task.yield()
            }
        }
        let archive = Archive(version: 1, exportedAt: Date(), items: records,
                              collections: collections.map(Collection.init))
        progress(0.75)
        let url = try await Task.detached(priority: .userInitiated) {
            let encoded = try JSONEncoder().encode(archive)
            let encrypted = try encrypt(encoded, password: password)
            let destination = FileManager.default.temporaryDirectory
                .appendingPathComponent("LaterBox-Backup-\\(Int(Date().timeIntervalSince1970)).laterbox")
            try encrypted.write(to: destination, options: .atomic)
            return destination
        }.value
        progress(1)
        return url
    }

    @MainActor
    static func export(context: ModelContext, password: String) throws -> URL {
        let items = try context.fetch(FetchDescriptor<LBItem>())
        let collections = try context.fetch(FetchDescriptor<LBCollection>())
        let archive = Archive(version: 1, exportedAt: Date(),
                              items: items.map(Item.init), collections: collections.map(Collection.init))
        let data = try JSONEncoder().encode(archive)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("LaterBox-Backup-\(Int(Date().timeIntervalSince1970)).laterbox")
        try encrypt(data, password: password).write(to: url, options: .atomic)
        return url
    }

    @MainActor
    static func importArchive(from file: URL, context: ModelContext, password: String, replaceIDs: Set<String> = [], progress: @escaping @MainActor (Double) -> Void = { _ in }) async throws -> Result {
        let archive = try await Task.detached(priority: .userInitiated) {
            let access = file.startAccessingSecurityScopedResource()
            defer { if access { file.stopAccessingSecurityScopedResource() } }
            let data = try decrypt(Data(contentsOf: file), password: password)
            guard let decoded = try? JSONDecoder().decode(Archive.self, from: data) else {
                throw BackupError.invalidArchive
            }
            return decoded
        }.value
        progress(0.25)
        guard archive.version == 1 else { throw BackupError.unsupportedVersion }
        let existingItems = try context.fetch(FetchDescriptor<LBItem>())
        let existingCollections = try context.fetch(FetchDescriptor<LBCollection>())
        var itemIDs = Set(existingItems.map(\.id))
        var collectionIDs = Set(existingCollections.map(\.id))
        var collectionNames = Set(existingCollections.map { $0.name.lowercased() })
        var result = Result(items: 0, collections: 0, attachments: 0, skipped: 0)
        var collectionRemap: [String: String] = [:]
        var importedReminders: [(id: String, title: String, description: String?, date: Date)] = []

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

        for (index, entry) in archive.items.enumerated() {
            if index % 10 == 0 {
                progress(0.25 + Double(index) / Double(max(archive.items.count, 1)) * 0.7)
                await Task.yield()
            }
            if itemIDs.contains(entry.id) {
                guard replaceIDs.contains(entry.id),
                      let existing = existingItems.first(where: { $0.id == entry.id }) else {
                    result.skipped += 1
                    continue
                }
                context.delete(existing)
            }
            guard ItemStatus(rawValue: entry.status) != nil, ItemContentType(rawValue: entry.type) != nil else {
                result.skipped += 1
                continue
            }
            let item = LBItem(id: entry.id, url: entry.url, title: entry.title,
                              textContent: entry.textContent, textSelector: entry.textSelector,
                              type: ItemContentType(rawValue: entry.type) ?? .link,
                              favorite: entry.favorite, status: ItemStatus(rawValue: entry.status) ?? .inbox,
                              returnAt: entry.returnAt, createdAt: entry.createdAt,
                              inboxEnteredAt: entry.inboxEnteredAt, updatedAt: entry.updatedAt,
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
            if item.status == ItemStatus.deferred.rawValue,
               let returnAt = item.returnAt, returnAt > Date() {
                importedReminders.append((item.id, item.title, item.notificationDescription, returnAt))
            }
            itemIDs.insert(entry.id)
            result.items += 1
        }
        try context.save()
        progress(1)
        // Notification recovery is best-effort and never rolls back a successful import.
        // Do not prompt for permission implicitly during data restoration.
        if !importedReminders.isEmpty {
            Task { @MainActor in
                let authorization = await ReturnNotification.currentAuthorizationStatus()
                guard authorization == .authorized || authorization == .provisional else { return }
                for reminder in importedReminders where reminder.date > Date() {
                    _ = try? await ReturnNotification.update(
                        id: reminder.id, title: reminder.title,
                        description: reminder.description, date: reminder.date)
                }
            }
        }
        return result
    }
}
