//
//  SyncCoordinator.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 04.10.26.
//

import SwiftUI
import SwiftData
import Combine

public enum CloudSyncState: String {
    case synced = "Synced"
    case syncing = "Syncing"
    case offline = "Offline"
    case error = "Error"
    
    public var iconName: String {
        switch self {
        case .synced: return "checkmark.icloud.fill"
        case .syncing: return "arrow.triangle.2.circlepath.icloud.fill"
        case .offline: return "bolt.horizontal.icloud.fill"
        case .error: return "exclamationmark.icloud.fill"
        }
    }
    
    public var statusColor: Color {
        switch self {
        case .synced: return .green
        case .syncing: return Color.lbAmber
        case .offline: return .secondary
        case .error: return .red
        }
    }
}

@MainActor
public final class SyncCoordinator: ObservableObject {
    public static let shared = SyncCoordinator()

    @Published public var syncState: CloudSyncState = .synced
    @Published public var lastSyncedAt: Date? = nil
    @Published public var currentUserEmail: String? = nil
    @Published public var currentUserId: String? = nil
    @Published public var authToken: String? = nil
    @Published public var isPro: Bool = true // Pro features active on mobile
    @Published public var systemStatusText: String = "Operational"
    @Published public var isSystemOperational: Bool = true
    @Published public var activeFilter: ItemContentType? = nil
    @Published public var searchQuery: String = ""
    @Published public var isGuestMode: Bool = false

    public var isAuthenticated: Bool {
        currentUserEmail != nil && !(currentUserEmail?.isEmpty ?? true)
    }

    public var hasAccess: Bool {
        isAuthenticated || isGuestMode
    }

    private let defaults = UserDefaults.standard
    private let api = LaterBoxAPIService.shared

    private init() {
        self.currentUserEmail = defaults.string(forKey: "lb_user_email")
        self.currentUserId = defaults.string(forKey: "lb_user_id")
        self.authToken = defaults.string(forKey: "lb_auth_token")
        self.isGuestMode = defaults.bool(forKey: "lb_guest_mode")
        
        Task {
            await refreshSystemStatus()
        }
    }

    public func refreshSystemStatus() async {
        let (status, ok) = await api.fetchSystemStatus()
        self.systemStatusText = status
        self.isSystemOperational = ok
    }

    public func setSession(email: String, userId: String, token: String) {
        self.currentUserEmail = email
        self.currentUserId = userId
        self.authToken = token
        self.isGuestMode = false
        defaults.set(email, forKey: "lb_user_email")
        defaults.set(userId, forKey: "lb_user_id")
        defaults.set(token, forKey: "lb_auth_token")
        defaults.set(false, forKey: "lb_guest_mode")
        LBHaptic.success()
    }

    public func continueAsGuest() {
        self.isGuestMode = true
        defaults.set(true, forKey: "lb_guest_mode")
        LBHaptic.light()
    }

    public func signOut() {
        self.currentUserEmail = nil
        self.currentUserId = nil
        self.authToken = nil
        self.isGuestMode = false
        defaults.removeObject(forKey: "lb_user_email")
        defaults.removeObject(forKey: "lb_user_id")
        defaults.removeObject(forKey: "lb_auth_token")
        defaults.removeObject(forKey: "lb_guest_mode")
        LBHaptic.light()
    }

    // MARK: - Save Local Item
    public func saveItem(
        title: String,
        url: String? = nil,
        note: String? = nil,
        type: ItemContentType = .link,
        returnAt: Date? = nil,
        collectionName: String? = nil,
        context: ModelContext
    ) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? (url ?? "Untitled Link")
            : title

        // Determine domain
        var extractedDomain: String? = nil
        if let urlStr = url, let parsedUrl = URL(string: urlStr), let host = parsedUrl.host {
            extractedDomain = host.replacingOccurrences(of: "www.", with: "")
        }

        let newItem = LBItem(
            userId: currentUserId,
            url: url,
            title: cleanTitle,
            type: type,
            returnAt: returnAt,
            domain: extractedDomain,
            noteContent: note,
            collectionName: collectionName,
            isSyncPending: true
        )
        context.insert(newItem)
        try? context.save()
        LBHaptic.success()

        // Kick off cloud sync if online
        Task {
            await syncPendingItems(context: context)
        }
    }

    // MARK: - Item Actions
    public func markDone(item: LBItem, context: ModelContext) {
        item.status = ItemStatus.saved.rawValue
        item.updatedAt = Date()
        item.isSyncPending = true
        try? context.save()
        LBHaptic.light()
    }

    public func scheduleItem(item: LBItem, date: Date, context: ModelContext) {
        item.status = ItemStatus.deferred.rawValue
        item.returnAt = date
        item.updatedAt = Date()
        item.isSyncPending = true
        try? context.save()
        LBHaptic.light()
    }

    public func toggleFavorite(item: LBItem, context: ModelContext) {
        item.favorite.toggle()
        item.updatedAt = Date()
        item.isSyncPending = true
        try? context.save()
        LBHaptic.light()
    }

    public func deleteItem(item: LBItem, context: ModelContext) {
        context.delete(item)
        try? context.save()
        LBHaptic.medium()
    }

    // MARK: - Full Bidirectional Sync
    public func syncPendingItems(context: ModelContext) async {
        guard syncState != .syncing else { return }
        syncState = .syncing

        do {
            // Check status
            await refreshSystemStatus()
            
            // If logged in, fetch remote items
            if let uid = currentUserId, let token = authToken {
                let remoteItems = try await api.fetchRemoteItems(userId: uid, token: token)
                for r in remoteItems {
                    let descriptor = FetchDescriptor<LBItem>(predicate: #Predicate { $0.id == r.id })
                    let existing = try? context.fetch(descriptor).first
                    if existing == nil {
                        let parsedType = ItemContentType(rawValue: r.type ?? "link") ?? .link
                        let parsedStatus = ItemStatus(rawValue: r.status ?? "inbox") ?? .inbox
                        let parsedDate = ISO8601DateFormatter().date(from: r.created_at ?? "") ?? Date()
                        let returnDate = r.return_at != nil ? ISO8601DateFormatter().date(from: r.return_at!) : nil
                        
                        let imported = LBItem(
                            id: r.id,
                            userId: r.user_id,
                            url: r.url,
                            title: r.title ?? "Imported Link",
                            type: parsedType,
                            favorite: r.favorite ?? false,
                            status: parsedStatus,
                            returnAt: returnDate,
                            createdAt: parsedDate,
                            isSyncPending: false
                        )
                        context.insert(imported)
                    }
                }
                try? context.save()
            }

            self.syncState = .synced
            self.lastSyncedAt = Date()
        } catch {
            self.syncState = .error
        }
    }
}
