//
//  LBItem.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 04.10.26.
//

import Foundation
import SwiftData

public enum ItemContentType: String, Codable, CaseIterable {
    case link
    case article
    case video
    case music
    case document
    case image
    case file
    case note

    public var systemIcon: String {
        switch self {
        case .link: return "link"
        case .article: return "doc.text"
        case .video: return "play.rectangle.fill"
        case .music: return "music.note"
        case .image: return "photo"
        case .file: return "paperclip"
        case .document: return "doc.fill"
        case .note: return "note.text"
        }
    }
}

public enum ItemStatus: String, Codable, CaseIterable {
    case inbox
    case deferred
    case saved
    case archived
    case deleted

    public var title: String {
        switch self {
        case .inbox: return "Inbox"
        case .deferred: return "Scheduled"
        case .saved: return "Kept"
        case .archived: return "Archived"
        case .deleted: return "Recently Deleted"
        }
    }
}

@Model
public final class LBItem {
    @Attribute(.unique) public var id: String
    public var userId: String?
    public var url: String?
    public var title: String
    public var textContent: String?
    public var textSelector: String?
    public var type: String
    public var favorite: Bool
    public var status: String
    public var returnAt: Date?
    public var createdAt: Date
    public var updatedAt: Date
    
    // Enriched metadata fields
    public var domain: String?
    public var siteName: String?
    public var metadataDescription: String?
    public var faviconUrl: String?
    public var previewImageUrl: String?
    public var enrichmentStatus: String
    
    // Notes & Collection
    public var noteContent: String?
    public var collectionId: String?
    public var collectionName: String?
    
    public var attachmentsData: Data? = nil
    public var tags: [String] = []
    public var category: String = ""
    public var summary: String = ""
    public var formattedContent: String = ""

    // Sync state
    public var isSyncPending: Bool
    public var seen: Bool = false

    public init(
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
        isSyncPending: Bool = true,
        seen: Bool = false
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
        self.seen = seen
    }

    public var parsedContentType: ItemContentType {
        ItemContentType(rawValue: type) ?? .link
    }

    public var parsedStatus: ItemStatus {
        ItemStatus(rawValue: status) ?? .inbox
    }

    /// Contextual description snippet for notification bodies when items resurface or return to inbox
    public var notificationDescription: String? {
        if let desc = metadataDescription?.trimmingCharacters(in: .whitespacesAndNewlines), !desc.isEmpty {
            return desc
        }
        let cleanSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanSummary.isEmpty {
            return cleanSummary
        }
        if let text = textContent?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
            return text
        }
        if let note = noteContent?.trimmingCharacters(in: .whitespacesAndNewlines), !note.isEmpty {
            return note
        }
        if let u = url?.trimmingCharacters(in: .whitespacesAndNewlines), !u.isEmpty {
            return u
        }
        return nil
    }

    public static func normalizeURL(_ url: String?) -> String? {
        guard var raw = url?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty, raw != "http://", raw != "https://" else {
            return nil
        }
        if !raw.contains("://") {
            raw = "https://" + raw
        }
        guard let components = URLComponents(string: raw) else {
            let lower = raw.lowercased()
            return lower.hasSuffix("/") ? String(lower.dropLast()) : lower
        }
        var host = (components.host ?? "").lowercased()
        if host.hasPrefix("www.") {
            host = String(host.dropFirst(4))
        }
        var path = components.path
        while path.hasSuffix("/") && path.count > 1 {
            path = String(path.dropLast())
        }
        if path == "/" { path = "" }

        let ignoredParams: Set<String> = ["utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content", "ref", "fbclid", "gclid"]
        let filteredQueries = components.queryItems?.filter { item in
            !ignoredParams.contains(item.name.lowercased())
        } ?? []

        var result = host + path
        if !filteredQueries.isEmpty {
            let queryStr = filteredQueries.sorted(by: { $0.name < $1.name }).compactMap { item -> String? in
                if let val = item.value { return "\(item.name)=\(val)" }
                return item.name
            }.joined(separator: "&")
            result += "?" + queryStr
        }
        return result.isEmpty ? nil : result
    }

    /// Reconciles and deletes redundant duplicate item records from the SwiftData store,
    /// keeping the authoritative synced version and preserving any unique local notes or tags.
    public static func cleanupDuplicatesInStore(context: ModelContext) {
        guard let all = try? context.fetch(FetchDescriptor<LBItem>()) else { return }
        var seenKeys: [String: LBItem] = [:]
        var toDelete: [LBItem] = []

        let sorted = all.sorted { a, b in
            if a.isSyncPending != b.isSyncPending {
                return !a.isSyncPending
            }
            if a.updatedAt != b.updatedAt {
                return a.updatedAt > b.updatedAt
            }
            return a.createdAt > b.createdAt
        }

        for item in sorted {
            let key: String?
            if let norm = normalizeURL(item.url) {
                key = "url:\(norm)"
            } else if let text = item.textContent?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty, text.count > 10 {
                key = "text:\(text.lowercased())"
            } else {
                key = nil
            }

            if let k = key {
                if let primary = seenKeys[k] {
                    if let data = item.attachmentsData,
                       let incoming = try? JSONDecoder().decode([SharedAttachment].self, from: data),
                       !incoming.isEmpty {
                        let current = primary.attachmentsData.flatMap { try? JSONDecoder().decode([SharedAttachment].self, from: $0) } ?? []
                        let missing = incoming.filter { asset in !current.contains(where: { $0.id.caseInsensitiveCompare(asset.id) == .orderedSame }) }
                        if !missing.isEmpty {
                            primary.attachmentsData = try? JSONEncoder().encode(current + missing)
                            primary.isSyncPending = true
                        }
                    }
                    if (primary.noteContent == nil || primary.noteContent?.isEmpty == true) && item.noteContent?.isEmpty == false {
                        primary.noteContent = item.noteContent
                    }
                    for tag in item.tags where !primary.tags.contains(tag) {
                        primary.tags.append(tag)
                    }
                    if (primary.collectionName == nil || primary.collectionName?.isEmpty == true) && item.collectionName?.isEmpty == false {
                        primary.collectionName = item.collectionName
                        primary.collectionId = item.collectionId
                    }
                    toDelete.append(item)
                } else {
                    seenKeys[k] = item
                }
            }
        }

        if !toDelete.isEmpty {
            for dup in toDelete {
                context.delete(dup)
            }
            try? context.save()
        }
    }
}

extension Array where Element == LBItem {
    /// Returns a deduplicated list of items. If both a local item and its cloud version exist,
    /// only one local version is shown (preferring the up-to-date synced version).
    public func deduplicatedForDisplay() -> [LBItem] {
        var seenIds = Set<String>()
        var seenKeys = Set<String>()
        var result: [LBItem] = []

        // Prioritize up-to-date synced items (!isSyncPending), then newer updatedAt, then newer createdAt
        let sorted = self.sorted { a, b in
            if a.isSyncPending != b.isSyncPending {
                return !a.isSyncPending
            }
            if a.updatedAt != b.updatedAt {
                return a.updatedAt > b.updatedAt
            }
            return a.createdAt > b.createdAt
        }

        for item in sorted {
            if seenIds.contains(item.id) { continue }

            let key: String?
            if let normUrl = LBItem.normalizeURL(item.url) {
                key = "url:\(normUrl)"
            } else if let text = item.textContent?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty, text.count > 10 {
                key = "text:\(text.lowercased())"
            } else {
                key = "id:\(item.id)"
            }

            if let k = key {
                if seenKeys.contains(k) { continue }
                seenKeys.insert(k)
            }
            seenIds.insert(item.id)
            result.append(item)
        }

        return result
    }
}
