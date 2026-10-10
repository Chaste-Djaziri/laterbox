//
//  ItemThreadModel.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 11.10.26.
//

import Foundation

public struct ItemThreadEntry: Codable, Identifiable, Hashable, Sendable {
    public var id: String
    public var type: String // "message", "note", "poll", "document"
    public var authorName: String?
    public var content: String
    public var createdAt: String
    public var updatedAt: String?
    public var attachedToId: String?
    public var attachedSnippet: String?
    public var reactions: [String: Int]?
    public var userReactions: [String]?

    public init(
        id: String = "entry-\(Int(Date().timeIntervalSince1970 * 1000))-\(UUID().uuidString.prefix(5))",
        type: String = "message",
        authorName: String? = "Me",
        content: String,
        createdAt: String = ISO8601DateFormatter().string(from: Date()),
        updatedAt: String? = nil,
        attachedToId: String? = nil,
        attachedSnippet: String? = nil,
        reactions: [String: Int]? = [:],
        userReactions: [String]? = []
    ) {
        self.id = id
        self.type = type
        self.authorName = authorName
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.attachedToId = attachedToId
        self.attachedSnippet = attachedSnippet
        self.reactions = reactions
        self.userReactions = userReactions
    }

    public var parsedDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = formatter.date(from: createdAt) {
            return d
        }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: createdAt)
    }

    public var formattedRelativeTime: String {
        guard let date = parsedDate else { return "Recently" }
        let now = Date()
        let diff = now.timeIntervalSince(date)
        if diff < 60 {
            return "Just now"
        } else if diff < 3600 {
            let mins = Int(diff / 60)
            return "\(mins)m ago"
        } else if diff < 86400 {
            let hours = Int(diff / 3600)
            return "\(hours)h ago"
        } else if diff < 604800 {
            let days = Int(diff / 86400)
            return "\(days)d ago"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }
}

public struct ItemThreadData: Codable, Sendable {
    public var version: Int
    public var entries: [ItemThreadEntry]
    public var rootReactions: [String: Int]?
    public var rootUserReactions: [String]?

    public init(
        version: Int = 1,
        entries: [ItemThreadEntry] = [],
        rootReactions: [String: Int]? = [:],
        rootUserReactions: [String]? = []
    ) {
        self.version = version
        self.entries = entries
        self.rootReactions = rootReactions
        self.rootUserReactions = rootUserReactions
    }
}

public enum ItemThreadParser {
    public static func parse(from noteContent: String?) -> ItemThreadData {
        guard let raw = noteContent?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return ItemThreadData(entries: [])
        }

        // Try JSON deserialization matching web schema
        if (raw.hasPrefix("{") && raw.hasSuffix("}")) || (raw.hasPrefix("[") && raw.hasSuffix("]")) {
            if let data = raw.data(using: .utf8) {
                if let thread = try? JSONDecoder().decode(ItemThreadData.self, from: data) {
                    return thread
                }
            }
        }

        // Legacy or plain text note fallback
        let initialEntry = ItemThreadEntry(
            id: "initial-note",
            type: "note",
            authorName: "Note",
            content: raw,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        return ItemThreadData(entries: [initialEntry])
    }

    public static func serialize(_ thread: ItemThreadData) -> String {
        if thread.entries.isEmpty && (thread.rootReactions?.isEmpty ?? true) && (thread.rootUserReactions?.isEmpty ?? true) {
            return ""
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes]
        if let data = try? encoder.encode(thread), let str = String(data: data, encoding: .utf8) {
            return str
        }
        return ""
    }

    public static func addEntry(
        to thread: ItemThreadData,
        authorName: String? = "Me",
        content: String,
        attachedSnippet: String? = nil
    ) -> ItemThreadData {
        let entry = ItemThreadEntry(
            authorName: authorName,
            content: content,
            attachedSnippet: attachedSnippet
        )
        var updated = thread
        updated.entries.append(entry)
        return updated
    }
}
