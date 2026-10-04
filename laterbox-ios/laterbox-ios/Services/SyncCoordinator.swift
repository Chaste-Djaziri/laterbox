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
    @Published public private(set) var isPro: Bool = false
    private var storeKitPro = false
    private var accountPro = false
    @Published public var systemStatusText: String = "Operational"
    @Published public var isSystemOperational: Bool = true
    @Published public var activeFilter: ItemContentType? = nil
    @Published public var searchQuery: String = ""
    @Published public var isGuestMode: Bool = false
    @Published public var showingQuickCapture: Bool = false
    @Published public var showingAuthSheet: Bool = false
    @Published public var showingPlansSheet: Bool = false

    public var isAuthenticated: Bool {
        currentUserEmail != nil && !(currentUserEmail?.isEmpty ?? true)
    }

    public var isProUser: Bool {
        isPro
    }

    public func updateProFromStoreKit(_ active: Bool) {
        storeKitPro = active
        isPro = accountPro || active
    }

    public func refreshEntitlement() async {
        guard let uid = currentUserId, let token = authToken else {
            accountPro = false
            isPro = storeKitPro
            return
        }
        let active = await api.checkProEntitlement(userId: uid, token: token)
        guard uid == currentUserId, token == authToken else { return }
        accountPro = active
        isPro = accountPro || storeKitPro
    }

    public var syncHeaderTitle: String {
        guard isAuthenticated && isProUser else {
            return "Get Pro to sync"
        }
        return syncState.rawValue
    }

    public var syncHeaderColor: Color {
        guard isAuthenticated && isProUser else {
            return Color.black.opacity(0.4)
        }
        return syncState == .synced ? Color.lbGreenTheme : syncState.statusColor
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
        self.syncState = (currentUserEmail != nil && !(currentUserEmail?.isEmpty ?? true)) ? .synced : .offline
        
        Task {
            await refreshSystemStatus()
            await refreshEntitlement()
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
        self.syncState = .synced
        defaults.set(email, forKey: "lb_user_email")
        defaults.set(userId, forKey: "lb_user_id")
        defaults.set(token, forKey: "lb_auth_token")
        defaults.set(false, forKey: "lb_guest_mode")
        Task { await StoreKitManager.shared.registerAccountPurchases(); await refreshEntitlement() }
        LBHaptic.success()
    }

    public func continueAsGuest() {
        self.isGuestMode = true
        self.syncState = .offline
        defaults.set(true, forKey: "lb_guest_mode")
        LBHaptic.light()
    }

    public func signOut() {
        accountPro = false
        isPro = storeKitPro
        self.currentUserEmail = nil
        self.currentUserId = nil
        self.authToken = nil
        self.isGuestMode = false
        self.syncState = .offline
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

    @discardableResult
    func saveDraft(_ draft: CaptureDraft, context: ModelContext) throws -> LBItem {
        guard !draft.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw AIProviderError.invalidCapture }
        let id = draft.id
        if let existing = try context.fetch(FetchDescriptor<LBItem>(predicate: #Predicate { $0.id == id })).first { return existing }
        let item = LBItem(id: id, userId: currentUserId, url: draft.url,
                          title: draft.title.isEmpty ? String(draft.content.prefix(100)) : draft.title,
                          textContent: draft.content, type: draft.type, returnAt: draft.returnAt,
                          domain: draft.url.flatMap { URL(string: $0)?.host })
        item.tags = draft.tags.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "") }.filter { !$0.isEmpty }
        item.category = draft.category
        item.summary = draft.summary
        item.formattedContent = draft.formattedContent
        context.insert(item)
        do { try context.save() } catch { context.delete(item); throw error }
        Task { await enrich(item: item, context: context); await syncPendingItems(context: context) }
        return item
    }

    private func enrich(item: LBItem, context: ModelContext) async {
        guard let text = item.url, let url = URL(string: text) else { return }
        do {
            let metadata = try await LinkMetadataLoader.load(url)
            guard item.status != "deleted", item.modelContext != nil else { return }
            item.siteName = metadata.site
            item.metadataDescription = metadata.description
            item.previewImageUrl = metadata.image
            item.enrichmentStatus = "enriched"
            item.updatedAt = Date()
            item.isSyncPending = true
            try context.save()
        } catch {
            item.enrichmentStatus = "failed"
            try? context.save()
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
        item.status = ItemStatus.deleted.rawValue
        item.updatedAt = Date()
        item.isSyncPending = true
        try? context.save()
        LBHaptic.medium()
    }

    public func restoreItem(item: LBItem, context: ModelContext) {
        item.status = ItemStatus.saved.rawValue
        item.updatedAt = Date()
        item.isSyncPending = true
        try? context.save()
        LBHaptic.success()
    }

    public func permanentlyDeleteItem(item: LBItem, context: ModelContext) {
        context.delete(item)
        try? context.save()
        LBHaptic.medium()
    }

    // MARK: - Full Bidirectional Sync
    public func syncPendingItems(context: ModelContext) async {
        guard isAuthenticated && isProUser else {
            self.syncState = .offline
            return
        }
        guard syncState != .syncing else { return }
        syncState = .syncing

        do {
            await StoreKitManager.shared.registerAccountPurchases()
            try await performCloudSync(context: context)

            self.syncState = .synced
            self.lastSyncedAt = Date()
        } catch {
            self.syncState = .error
        }
    }
}
