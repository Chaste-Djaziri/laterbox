//
//  LocalStorageManager.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 05.10.26.
//

import Foundation
import Combine
import SwiftData
import WebKit

// MARK: - Duplicate Group

public struct DuplicateGroup: Identifiable {
    public let id: String
    public let key: String
    public let primaryItem: LBItem
    public let duplicates: [LBItem]

    public var totalCount: Int {
        1 + duplicates.count
    }
}

// MARK: - Storage Breakdown

public struct StorageBreakdown: Equatable {
    public var databaseBytes: Int64 = 0
    public var attachmentsBytes: Int64 = 0
    public var cacheBytes: Int64 = 0

    public var totalBytes: Int64 {
        databaseBytes + attachmentsBytes + cacheBytes
    }

    public var formattedTotal: String {
        ByteCountFormatter.string(fromByteCount: max(totalBytes, 1024), countStyle: .file)
    }

    public var formattedDatabase: String {
        ByteCountFormatter.string(fromByteCount: max(databaseBytes, 1024), countStyle: .file)
    }

    public var formattedAttachments: String {
        ByteCountFormatter.string(fromByteCount: attachmentsBytes, countStyle: .file)
    }

    public var formattedCache: String {
        ByteCountFormatter.string(fromByteCount: cacheBytes, countStyle: .file)
    }

    public var databasePercentage: Double {
        guard totalBytes > 0 else { return 0.5 }
        return Double(databaseBytes) / Double(totalBytes)
    }

    public var attachmentsPercentage: Double {
        guard totalBytes > 0 else { return 0.25 }
        return Double(attachmentsBytes) / Double(totalBytes)
    }

    public var cachePercentage: Double {
        guard totalBytes > 0 else { return 0.25 }
        return Double(cacheBytes) / Double(totalBytes)
    }
}

// MARK: - Local Storage Manager

@MainActor
public final class LocalStorageManager: ObservableObject {
    public static let shared = LocalStorageManager()

    @Published public var breakdown: StorageBreakdown = StorageBreakdown()
    @Published public var duplicateGroups: [DuplicateGroup] = []
    @Published public var isScanning: Bool = false

    private init() {
        refreshBreakdown()
    }

    public func refreshBreakdown() {
        let dbSize = Self.sizeOfDatabase()
        let attachmentsSize = Self.sizeOfAttachments()
        let cacheSize = Self.sizeOfCache()

        self.breakdown = StorageBreakdown(
            databaseBytes: dbSize,
            attachmentsBytes: attachmentsSize,
            cacheBytes: cacheSize
        )
    }

    public func scanDuplicates(items: [LBItem]) {
        self.duplicateGroups = Self.findDuplicates(in: items)
    }

    public var totalDuplicateItemCount: Int {
        duplicateGroups.reduce(0) { $0 + $1.duplicates.count }
    }

    // MARK: - Directory Size Calculations

    public static func sizeOfDirectory(at url: URL) -> Int64 {
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
               let size = resourceValues.fileSize {
                total += Int64(size)
            }
        }
        return total
    }

    public static func sizeOfDatabase() -> Int64 {
        var total: Int64 = 0
        let fileManager = FileManager.default
        if let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            total += sizeOfDirectory(at: appSupport)
        }
        if let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            total += sizeOfDirectory(at: documents)
        }
        return max(total, 50_000) // Minimum baseline for active store
    }

    public static func sizeOfAttachments() -> Int64 {
        if let root = try? SharedCaptureStore.root() {
            let attachmentsFolder = root.appendingPathComponent("Attachments")
            let capturesFolder = root.appendingPathComponent("Captures")
            return sizeOfDirectory(at: attachmentsFolder) + sizeOfDirectory(at: capturesFolder)
        }
        return 0
    }

    public static func sizeOfCache() -> Int64 {
        let disk = Int64(URLCache.shared.currentDiskUsage)
        let memory = Int64(URLCache.shared.currentMemoryUsage)
        return max(disk + memory, 12_000)
    }

    // MARK: - Duplicates Finder

    public static func findDuplicates(in items: [LBItem]) -> [DuplicateGroup] {
        let activeItems = items.filter { $0.status != ItemStatus.deleted.rawValue }

        var urlGroups: [String: [LBItem]] = [:]
        var nonUrlItems: [LBItem] = []

        for item in activeItems {
            if let rawUrl = item.url?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
               !rawUrl.isEmpty, rawUrl != "http://", rawUrl != "https://" {
                let normalized = rawUrl.hasSuffix("/") ? String(rawUrl.dropLast()) : rawUrl
                urlGroups[normalized, default: []].append(item)
            } else {
                nonUrlItems.append(item)
            }
        }

        var groups: [DuplicateGroup] = []

        for (url, groupedItems) in urlGroups where groupedItems.count > 1 {
            let sorted = groupedItems.sorted { $0.createdAt > $1.createdAt }
            let primary = sorted[0]
            let duplicates = Array(sorted.dropFirst())
            groups.append(DuplicateGroup(id: "url-\(url)", key: url, primaryItem: primary, duplicates: duplicates))
        }

        var titleGroups: [String: [LBItem]] = [:]
        for item in nonUrlItems {
            let clean = item.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if clean.count > 3 && !clean.hasPrefix("untitled") {
                titleGroups[clean, default: []].append(item)
            }
        }

        for (title, groupedItems) in titleGroups where groupedItems.count > 1 {
            let sorted = groupedItems.sorted { $0.createdAt > $1.createdAt }
            let primary = sorted[0]
            let duplicates = Array(sorted.dropFirst())
            groups.append(DuplicateGroup(id: "title-\(title)", key: title, primaryItem: primary, duplicates: duplicates))
        }

        return groups.sorted { $0.duplicates.count > $1.duplicates.count }
    }

    // MARK: - Cleanup Operations

    public func emptyTrash(items: [LBItem], context: ModelContext, coordinator: SyncCoordinator) -> Int {
        let trashItems = items.filter { $0.status == ItemStatus.deleted.rawValue }
        guard !trashItems.isEmpty else { return 0 }

        for item in trashItems {
            coordinator.permanentlyDeleteItem(item: item, context: context)
        }

        LBHaptic.success()
        refreshBreakdown()
        return trashItems.count
    }

    public func clearKeptItems(items: [LBItem], context: ModelContext, coordinator: SyncCoordinator, moveToTrash: Bool = true) -> Int {
        let keptItems = items.filter { $0.status == ItemStatus.saved.rawValue || $0.status == ItemStatus.archived.rawValue }
        guard !keptItems.isEmpty else { return 0 }

        for item in keptItems {
            if moveToTrash {
                coordinator.deleteItem(item: item, context: context)
            } else {
                coordinator.permanentlyDeleteItem(item: item, context: context)
            }
        }

        LBHaptic.success()
        refreshBreakdown()
        return keptItems.count
    }

    public func resolveDuplicates(context: ModelContext, coordinator: SyncCoordinator) -> Int {
        var count = 0
        for group in duplicateGroups {
            for item in group.duplicates {
                coordinator.permanentlyDeleteItem(item: item, context: context)
                count += 1
            }
        }

        duplicateGroups.removeAll()
        LBHaptic.success()
        refreshBreakdown()
        return count
    }

    public func clearMediaAndWebCache() {
        URLCache.shared.removeAllCachedResponses()
        if let root = try? SharedCaptureStore.root() {
            let captures = root.appendingPathComponent("Captures")
            let items = (try? FileManager.default.contentsOfDirectory(at: captures, includingPropertiesForKeys: nil)) ?? []
            for file in items {
                try? FileManager.default.removeItem(at: file)
            }
        }
        LBHaptic.success()
        refreshBreakdown()
    }
}
