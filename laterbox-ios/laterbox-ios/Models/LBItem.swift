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
    case note

    public var systemIcon: String {
        switch self {
        case .link: return "link"
        case .article: return "doc.text"
        case .video: return "play.rectangle.fill"
        case .music: return "music.note"
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
    
    // Sync state
    public var isSyncPending: Bool

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

    public var parsedContentType: ItemContentType {
        ItemContentType(rawValue: type) ?? .link
    }

    public var parsedStatus: ItemStatus {
        ItemStatus(rawValue: status) ?? .inbox
    }
}
