//
//  SyncCoordinator.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 04.10.26.
//

import SwiftUI
import SwiftData
import Combine
import UserNotifications

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

enum StorageFullError: LocalizedError {
    case full

    var errorDescription: String? {
        "Your cloud storage is full. Delete stored files or change your plan on the LaterBox website before saving anything new."
    }
}

/// Deletes only the local library and app-group artifacts. Never schedules
/// a Supabase deletion or calls the cloud API during sign-out.
@MainActor
enum LocalAccountDataEraser {
    static func erase(context: ModelContext, sharedRoot: URL) throws {
        // Batch-delete every account's local rows without holding model
        // instances as SwiftData invalidates them. This also scales better
        // for large offline libraries and avoids use-after-reset crashes.
        // These are purely local operations, not cloud deletion requests.
        try context.delete(model: LBItem.self)
        try context.delete(model: LBCollection.self)
        try context.save()

        // The share extension, widgets and the app share this storage.
        // Delete only LaterBox-owned paths, never the app-group container itself.
        let ownedPaths = ["Captures", "Attachments", "ai_settings.json", "cached_collections.json"]
        for name in ownedPaths {
            let path = sharedRoot.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: path.path) {
                try FileManager.default.removeItem(at: path)
            }
        }
    }
}

@MainActor
public final class SyncCoordinator: ObservableObject {
    public static let shared = SyncCoordinator()

    @Published public var syncState: CloudSyncState = .synced
    @Published public var lastSyncedAt: Date? = nil
    @Published public var lastSyncErrorMessage: String? = nil
    @Published public var showingSyncFailureAlert = false

    public var friendlySyncFailureReason: String {
        let detail = (lastSyncErrorMessage ?? "").lowercased()
        let reason: String
        if sessionExpired || detail.contains("session expired") || detail.contains("authentication") {
            reason = "Please sign in again to reconnect your account."
        } else if detail.contains("internet") || detail.contains("offline") || detail.contains("network") {
            reason = "Check your internet connection and try again."
        } else if detail.contains("timed out") || detail.contains("timeout") {
            reason = "The cloud took too long to respond. Please try again."
        } else if detail.contains("couldn’t be saved") || detail.contains("couldn't be saved") || detail.contains("space") || detail.contains("folder") {
            reason = "An attachment could not be saved on this device. Check your available storage and try again."
        } else if detail.contains("missing") || detail.contains("does not exist") || detail.contains("no such file") {
            reason = "An attachment is missing from this device. Share the original file again to restore it."
        } else if detail.contains("attachment") || detail.contains("upload") {
            reason = "An attachment could not finish transferring. Please try again, or report the issue if it continues."
        } else {
            reason = "We couldn’t connect your changes to the cloud. Please try again, or report the issue if it continues."
        }
        return reason + " Your local items are kept on this device."
    }
    @Published public var currentUserEmail: String? = nil
    @Published public var currentUserId: String? = nil
    @Published public var authToken: String? = nil
    @Published public var refreshToken: String? = nil
    @Published public var sessionExpired: Bool = false
    @Published public private(set) var isPro: Bool = false
    private var storeKitPro = false
    private var accountPro = false
    @Published public private(set) var billingEntitlement: AccountBillingEntitlement?
    @Published public private(set) var billingError: String?
    @Published public private(set) var isCheckingEntitlement: Bool = false
    @Published public var systemStatusText: String = "Operational"
    @Published public var isSystemOperational: Bool = true
    @Published public var activeFilter: ItemContentType? = nil
    @Published public var searchQuery: String = ""
    @Published public var isGuestMode: Bool = false
    @Published public var showingQuickCapture: Bool = false
    @Published public var isShowingCapture: Bool = false
    @Published public var showingAuthSheet: Bool = false
    @Published public var showingPlansSheet: Bool = false
    @Published public var showingStorageFullAlert: Bool = false

    public var isCloudStorageFull: Bool {
        guard !isGuestMode, isAuthenticated,
              let used = billingEntitlement?.storageUsedBytes,
              let limit = billingEntitlement?.storageLimitBytes,
              limit > 0 else { return false }
        return used >= limit
    }

    public func ensureStorageWritable() throws {
        guard !isCloudStorageFull else {
            showingStorageFullAlert = true
            throw StorageFullError.full
        }
    }
    @Published public var catalogUpdateTrigger: UUID = UUID()
    @Published public var pendingPullCount: Int = 0
    @Published public var pendingPushCount: Int = 0
    @Published public var isPulling: Bool = false
    @Published public var isPushing: Bool = false
    @Published public var isCheckingRemoteChanges: Bool = false

    public var isAuthenticated: Bool {
        currentUserEmail != nil && !(currentUserEmail?.isEmpty ?? true)
    }

    public var hasCloudPro: Bool { !isGuestMode && isAuthenticated } // Legacy name: authenticated sync is free.

    public var isProUser: Bool {
        isPro
    }

    public func countUnassignedLocalItems(context: ModelContext, targetUserId: String? = nil) -> Int {
        do {
            let items = try context.fetch(FetchDescriptor<LBItem>())
            return items.filter { item in
                if let target = targetUserId {
                    return item.userId == nil || item.userId != target
                }
                return item.userId == nil
            }.count
        } catch {
            return 0
        }
    }

    public func updateProFromStoreKit(_ active: Bool) {
        storeKitPro = active
        isPro = accountPro || active
    }

    public func setProForTesting(_ active: Bool) {
        accountPro = active
        storeKitPro = active
        isPro = active
    }

    @discardableResult
    public func refreshEntitlement() async -> Bool {
        guard !isGuestMode, isAuthenticated, let uid = currentUserId, var token = authToken else {
            accountPro = false
            billingEntitlement = nil
            billingError = nil
            isPro = storeKitPro
            return false
        }
        isCheckingEntitlement = true
        defer { isCheckingEntitlement = false }

        do {
            let entitlement = try await api.fetchBillingEntitlement(token: token)
            guard uid == currentUserId, token == authToken else { return false }
            billingEntitlement = entitlement
            billingError = nil
            accountPro = entitlement.hasAccess
            isPro = accountPro || storeKitPro
            return true
        } catch {
            var refreshedSuccessfully = false
            if let syncErr = error as? CloudSyncError, case .unauthorized = syncErr {
                refreshedSuccessfully = await refreshAuthSession()
            } else if let urlErr = error as? URLError, urlErr.code == .userAuthenticationRequired {
                refreshedSuccessfully = await refreshAuthSession()
            }
            if refreshedSuccessfully, let refreshedToken = authToken {
                token = refreshedToken
                if let entitlement = try? await api.fetchBillingEntitlement(token: token) {
                    billingEntitlement = entitlement
                    billingError = nil
                    accountPro = entitlement.hasAccess
                    isPro = accountPro || storeKitPro
                    return true
                }
            }

            // Fallback: If network allows direct Supabase RPC check, try has_pro_entitlement
            if await api.checkProEntitlement(userId: uid, token: authToken) {
                accountPro = true
                isPro = true
                billingError = nil
                return true
            }

            guard uid == currentUserId, token == authToken else { return false }
            if let syncErr = error as? CloudSyncError, case .unauthorized = syncErr {
                self.sessionExpired = true
                billingError = "Session expired (JWT expired). Reconnect or sign in again, then retry."
            } else {
                billingError = "Unable to check your account subscription. Reconnect or sign in again, then retry."
            }
            accountPro = billingEntitlement?.hasAccess ?? false
            isPro = accountPro || storeKitPro
            return false
        }
    }

    public var syncHeaderTitle: String {
        guard hasCloudPro else {
            return "Sign in to sync"
        }
        return syncState.rawValue
    }

    public var syncHeaderColor: Color {
        guard hasCloudPro else {
            return Color.black.opacity(0.4)
        }
        return syncState == .synced ? Color.lbGreenTheme : syncState.statusColor
    }

    public var hasAccess: Bool {
        isAuthenticated || isGuestMode
    }

    public static let endpointDefaultsKey = "lb_auth_endpoint"

    private let defaults: UserDefaults
    private let api: LaterBoxAPIService

    public init(defaults: UserDefaults = .standard, api: LaterBoxAPIService = .shared) {
        self.defaults = defaults
        self.api = api

        let currentEndpoint = api.supabaseUrl
        let storedEndpoint = defaults.string(forKey: Self.endpointDefaultsKey)
        let hasStoredSession = defaults.string(forKey: "lb_user_email") != nil || defaults.string(forKey: "lb_auth_token") != nil

        if hasStoredSession {
            let sessionEndpoint = storedEndpoint ?? LaterBoxAPIService.defaultSupabaseUrl
            if sessionEndpoint != currentEndpoint {
                // Invalidate session that was created against a different Supabase endpoint
                defaults.removeObject(forKey: "lb_user_email")
                defaults.removeObject(forKey: "lb_user_id")
                defaults.removeObject(forKey: "lb_auth_token")
                defaults.removeObject(forKey: "lb_refresh_token")
                defaults.removeObject(forKey: Self.endpointDefaultsKey)
            } else if storedEndpoint == nil {
                defaults.set(currentEndpoint, forKey: Self.endpointDefaultsKey)
            }
        }

        self.currentUserEmail = defaults.string(forKey: "lb_user_email")
        self.currentUserId = defaults.string(forKey: "lb_user_id")
        self.authToken = defaults.string(forKey: "lb_auth_token")
        self.refreshToken = defaults.string(forKey: "lb_refresh_token")
        self.isGuestMode = defaults.bool(forKey: "lb_guest_mode")
        self.syncState = (currentUserEmail != nil && !(currentUserEmail?.isEmpty ?? true)) ? .synced : .offline

        Task {
            await refreshSystemStatus()
            await refreshEntitlement()
        }
    }

    @discardableResult
    public func validateSessionEndpoint() -> Bool {
        let currentEndpoint = api.supabaseUrl
        let storedEndpoint = defaults.string(forKey: Self.endpointDefaultsKey)
        let hasStoredSession = currentUserEmail != nil || authToken != nil || defaults.string(forKey: "lb_user_email") != nil || defaults.string(forKey: "lb_auth_token") != nil

        guard hasStoredSession else { return true }

        let sessionEndpoint = storedEndpoint ?? LaterBoxAPIService.defaultSupabaseUrl
        if sessionEndpoint != currentEndpoint {
            signOut()
            return false
        } else if storedEndpoint == nil {
            defaults.set(currentEndpoint, forKey: Self.endpointDefaultsKey)
        }
        return true
    }

    public func refreshSystemStatus() async {
        let (status, ok) = await api.fetchSystemStatus()
        self.systemStatusText = status
        self.isSystemOperational = ok
    }

    public func setSession(email: String, userId: String, token: String, refreshToken: String? = nil) {
        if currentUserId != userId { billingEntitlement = nil; accountPro = false }
        self.currentUserEmail = email
        self.currentUserId = userId
        self.authToken = token
        if let refreshToken, !refreshToken.isEmpty {
            self.refreshToken = refreshToken
            defaults.set(refreshToken, forKey: "lb_refresh_token")
        }
        self.sessionExpired = false
        self.isGuestMode = false
        self.syncState = .synced
        defaults.set(email, forKey: "lb_user_email")
        defaults.set(userId, forKey: "lb_user_id")
        defaults.set(token, forKey: "lb_auth_token")
        defaults.set(false, forKey: "lb_guest_mode")
        defaults.set(api.supabaseUrl, forKey: Self.endpointDefaultsKey)
        Task { await StoreKitManager.shared.updatePurchasedProducts(); await refreshEntitlement() }
        LBHaptic.success()
    }

    public func continueAsGuest() {
        self.isGuestMode = true
        self.syncState = .offline
        defaults.set(true, forKey: "lb_guest_mode")
        LBHaptic.light()
    }

    /// Run the destructive local reset after the presenting alert/dialog has
    /// completed its update transaction. Changing a TabView/NavigationStack and
    /// its presenting dialog synchronously causes recursive navigation updates.
    public func signOutAfterDialog(
        context: ModelContext,
        continueAsGuest: Bool = false,
        onError: @escaping @MainActor (Error) -> Void
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            do {
                try self.signOutAndEraseLocalData(context: context)
                if continueAsGuest { self.continueAsGuest() }
            } catch {
                onError(error)
            }
        }
    }

    /// Explicit Sign Out removes *all* LaterBox user content from this device.
    /// This includes unuploaded items; the cloud account and its records remain intact.
    /// The caller keeps the session active and shows an error if local deletion fails.
    public func signOutAndEraseLocalData(context: ModelContext) throws {
        let root = try SharedCaptureStore.root()
        try LocalAccountDataEraser.erase(context: context, sharedRoot: root)

        // Clear any user-provided AI credentials retained in a live manager.
        // The manager writes shared settings when properties change; erase the
        // generated file and defaults immediately afterward.
        LaterAIModelManager.shared.resetForSignOut()
        ClipboardDetectionManager.shared.resetSessionData()
        let aiSettings = root.appendingPathComponent("ai_settings.json")
        if FileManager.default.fileExists(atPath: aiSettings.path) {
            try FileManager.default.removeItem(at: aiSettings)
        }

        // Exported backups in the app's temporary directory are private data.
        let temporary = FileManager.default.temporaryDirectory
        let exports = try FileManager.default.contentsOfDirectory(at: temporary, includingPropertiesForKeys: nil)
        for file in exports where file.lastPathComponent.hasPrefix("LaterBox-Backup-")
            && file.pathExtension == "laterbox" {
            try FileManager.default.removeItem(at: file)
        }

        URLCache.shared.removeAllCachedResponses()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        ReturnNotificationRouter.shared.itemID = nil
        LaterAIManager.shared.isShowingLaterAI = false
        LaterAIManager.shared.flowProgress = 0
        LaterAIManager.shared.attachedSubject = nil
        LaterAIManager.shared.initialPrompt = nil
        AppLockManager.shared.isAppLockEnabled = false
        AppLockManager.shared.isLocked = false

        // Purge app-owned purchase-linkage Keychain data before credentials.
        // Apple's StoreKit entitlement remains available independently.
        try StoreKitManager.shared.resetAccountConnection()

        // Only clear our own persistent preference domains. Enumerating an
        // App Group's dictionaryRepresentation also reads global/AnyUser
        // preferences, which produces CFPrefsPlistSource container warnings.
        if let bundleID = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: bundleID)
        }
        if let groupDefaults = UserDefaults(suiteName: SharedCaptureStore.group) {
            groupDefaults.removePersistentDomain(forName: SharedCaptureStore.group)
        }

        // Preserve device-owned StoreKit entitlement (it belongs to Apple),
        // while discarding the previous LaterBox account's connection state.
        signOut()
        pendingPullCount = 0
        pendingPushCount = 0
        isPulling = false
        isPushing = false
        isCheckingRemoteChanges = false
        lastSyncedAt = nil
        lastSyncErrorMessage = nil
        showingSyncFailureAlert = false
        showingStorageFullAlert = false
        showingQuickCapture = false
        isShowingCapture = false
        showingAuthSheet = false
        activeFilter = nil
        searchQuery = ""
        catalogUpdateTrigger = UUID()
    }

    public func signOut() {
        billingEntitlement = nil
        billingError = nil
        accountPro = false
        isPro = storeKitPro
        self.currentUserEmail = nil
        self.currentUserId = nil
        self.authToken = nil
        self.refreshToken = nil
        self.sessionExpired = false
        self.isGuestMode = false
        self.syncState = .offline
        defaults.removeObject(forKey: "lb_user_email")
        defaults.removeObject(forKey: "lb_user_id")
        defaults.removeObject(forKey: "lb_auth_token")
        defaults.removeObject(forKey: "lb_refresh_token")
        defaults.removeObject(forKey: "lb_guest_mode")
        defaults.removeObject(forKey: Self.endpointDefaultsKey)
        LBHaptic.light()
    }

    public func deleteAccount(context: ModelContext) async throws {
        guard let token = authToken, !token.isEmpty else {
            throw CloudSyncError.unauthenticated
        }

        try await api.deleteAccount(token: token)
        // After the server confirms deletion, wipe the same local data and
        // app-group artifacts as ordinary sign out.
        try signOutAndEraseLocalData(context: context)
    }

    @discardableResult
    public func refreshAuthSession() async -> Bool {
        guard let rToken = refreshToken ?? defaults.string(forKey: "lb_refresh_token"), !rToken.isEmpty else {
            return false
        }
        do {
            let (newAccess, newRefresh, uid) = try await api.refreshSession(refreshToken: rToken)
            self.authToken = newAccess
            self.refreshToken = newRefresh
            self.currentUserId = uid
            self.sessionExpired = false
            defaults.set(newAccess, forKey: "lb_auth_token")
            defaults.set(newRefresh, forKey: "lb_refresh_token")
            defaults.set(uid, forKey: "lb_user_id")
            defaults.set(api.supabaseUrl, forKey: Self.endpointDefaultsKey)
            return true
        } catch {
            return false
        }
    }

    /// Exit guest mode removes all private local data and extension captures.
    public func exitGuest(context: ModelContext) throws {
        try signOutAndEraseLocalData(context: context)
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
        guard !isCloudStorageFull else {
            showingStorageFullAlert = true
            LBHaptic.warning()
            return
        }
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? (url ?? "Untitled Link")
            : title

        // Determine domain
        var extractedDomain: String? = nil
        if let urlStr = url, let parsedUrl = URL(string: urlStr), let host = parsedUrl.host {
            extractedDomain = host.replacingOccurrences(of: "www.", with: "")
        }

        var resolvedCollName = SharedCaptureCollections.normalizedName(collectionName)
        var resolvedCollId: String? = nil
        if let name = resolvedCollName, !name.isEmpty {
            if let coll = ensureCollectionExists(named: name, context: context) {
                resolvedCollName = coll.name
                resolvedCollId = coll.id
            }
        }

        let newItem = LBItem(
            userId: currentUserId,
            url: url,
            title: cleanTitle,
            type: type,
            status: returnAt == nil ? .inbox : .deferred,
            returnAt: returnAt,
            domain: extractedDomain,
            noteContent: note,
            collectionId: resolvedCollId,
            collectionName: resolvedCollName,
            isSyncPending: true
        )
        if let name = resolvedCollName {
            newItem.category = name
        }
        context.insert(newItem)
        try? context.save()
        LBHaptic.success()

        // Capture values before scheduling work; SwiftData model instances may
        // be invalidated by sign-out or by the end of an in-memory test.
        let savedID = newItem.id
        let savedTitle = newItem.title
        let savedDescription = newItem.notificationDescription
        let savedReturnAt = newItem.returnAt
        let savedURL = newItem.url
        let savedUserID = currentUserId
        let savedAuthToken = authToken
        Task {
            if savedReturnAt != nil {
                _ = try? await ReturnNotification.update(
                    id: savedID, title: savedTitle,
                    description: savedDescription, date: savedReturnAt
                )
            }
            if savedURL != nil {
                await enrichItem(id: savedID, originalURL: savedURL, context: context)
            }
            guard savedUserID == currentUserId, savedAuthToken == authToken, hasCloudPro else { return }
            await syncPendingItems(context: context)
        }
    }

    @discardableResult
    func saveDraft(_ draft: CaptureDraft, context: ModelContext, status: ItemStatus? = nil) throws -> LBItem {
        try ensureStorageWritable()
        guard !draft.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !draft.attachments.isEmpty else { throw AIProviderError.invalidCapture }
        let id = draft.id
        if let existing = try context.fetch(FetchDescriptor<LBItem>(predicate: #Predicate { $0.id == id })).first { return existing }

        let rawCollName = SharedCaptureCollections.normalizedName(draft.collectionName)
            ?? SharedCaptureCollections.normalizedName(draft.category)
        
        var resolvedCollName: String? = nil
        var resolvedCollId: String? = nil
        if let name = rawCollName?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            if let coll = ensureCollectionExists(named: name, context: context) {
                resolvedCollName = coll.name
                resolvedCollId = coll.id
            } else {
                resolvedCollName = name
            }
        }

        let fallbackTitle = draft.attachments.first?.name ?? String(draft.content.prefix(100))
        let item = LBItem(id: id, userId: currentUserId, url: draft.url,
                          title: draft.title.isEmpty ? fallbackTitle : draft.title,
                          textContent: draft.content.isEmpty ? (draft.attachments.first?.name ?? "") : draft.content,
                          type: draft.type, status: status ?? (draft.returnAt == nil ? .inbox : .deferred), returnAt: draft.returnAt,
                          domain: draft.url.flatMap { URL(string: $0)?.host })
        if !draft.attachments.isEmpty {
            item.attachmentsData = try? JSONEncoder().encode(draft.attachments)
        }
        item.tags = draft.tags.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "") }.filter { !$0.isEmpty }
        item.enrichmentStatus = draft.url == nil ? "enriched" : "pending"
        // No collection is an empty category, never the Inbox mailbox name.
        item.category = resolvedCollName ?? ""
        item.collectionName = resolvedCollName
        item.collectionId = resolvedCollId
        item.summary = draft.summary
        item.formattedContent = draft.formattedContent
        item.siteName = draft.siteName
        item.metadataDescription = draft.metadataDescription
        item.previewImageUrl = draft.previewImageUrl
        item.faviconUrl = draft.faviconUrl
        context.insert(item)
        do { try context.save() } catch { context.delete(item); throw error }
        let savedID = item.id
        let savedTitle = item.title
        let savedDescription = item.notificationDescription
        let savedReturnAt = item.returnAt
        let savedURL = item.url
        let savedUserID = currentUserId
        let savedAuthToken = authToken
        Task {
            if savedReturnAt != nil {
                _ = try? await ReturnNotification.update(
                    id: savedID, title: savedTitle,
                    description: savedDescription, date: savedReturnAt
                )
            }
            if savedURL != nil {
                await enrichItem(id: savedID, originalURL: savedURL, context: context)
            }
            guard savedUserID == currentUserId, savedAuthToken == authToken, hasCloudPro else { return }
            await syncPendingItems(context: context)
        }
        return item
    }

    // MARK: - Collection Auto-Creation
    @discardableResult
    public func ensureCollectionExists(named rawName: String?, context: ModelContext) -> LBCollection? {
        guard let raw = rawName?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return nil }
        let excluded: Set<String> = ["inbox", "archive", "archived", "trash", "deleted", "none", "uncategorized", "general"]
        if excluded.contains(raw.lowercased()) { return nil }

        do {
            let existing = try context.fetch(FetchDescriptor<LBCollection>())
            if let found = existing.first(where: { $0.name.localizedCaseInsensitiveCompare(raw) == .orderedSame }) {
                return found
            }
            guard !isCloudStorageFull else {
                showingStorageFullAlert = true
                return nil
            }
            let (icon, color) = defaultCollectionStyle(for: raw)
            let newCollection = LBCollection(
                userId: currentUserId,
                name: raw,
                colorHex: color,
                iconName: icon,
                createdAt: Date(),
                updatedAt: Date()
            )
            context.insert(newCollection)
            try? context.save()
            return newCollection
        } catch {
            return nil
        }
    }

    private func defaultCollectionStyle(for name: String) -> (icon: String, color: String) {
        let lower = name.lowercased()
        if lower.contains("video") || lower.contains("amv") || lower.contains("movie") || lower.contains("youtube") {
            return ("play.rectangle.fill", "#EF4444")
        } else if lower.contains("music") || lower.contains("audio") || lower.contains("song") {
            return ("music.note", "#10B981")
        } else if lower.contains("book") || lower.contains("read") || lower.contains("article") {
            return ("book.fill", "#3B82F6")
        } else if lower.contains("code") || lower.contains("dev") || lower.contains("tech") {
            return ("curlybraces", "#8B5CF6")
        } else if lower.contains("work") || lower.contains("project") || lower.contains("task") {
            return ("briefcase.fill", "#F59E0B")
        } else if lower.contains("recipe") || lower.contains("food") || lower.contains("cook") {
            return ("fork.knife", "#EC4899")
        } else if lower.contains("idea") || lower.contains("note") {
            return ("lightbulb.fill", "#FBBF24")
        }
        return ("folder.fill", "#F59E0B")
    }

    public func enrich(item: LBItem, context: ModelContext) async {
        await enrichItem(id: item.id, originalURL: item.url, context: context)
    }

    private func enrichItem(id: String, originalURL: String?, context: ModelContext) async {
        guard let originalURL, let url = URL(string: originalURL) else { return }
        let expectedUserID = currentUserId
        let expectedAuthToken = authToken
        do {
            let metadata = try await LinkMetadataLoader.load(url)
            guard currentUserId == expectedUserID, authToken == expectedAuthToken else { return }
            let descriptor = FetchDescriptor<LBItem>(predicate: #Predicate { $0.id == id })
            guard let item = try context.fetch(descriptor).first,
                  item.status != ItemStatus.deleted.rawValue else { return }
            let candidateTitle = LinkMetadataLoader.cleanTitle(metadata.title)
            let currentIsGeneric = item.title.isEmpty || item.title == url.host || item.title == originalURL || item.title.hasPrefix("http") || LinkMetadataLoader.isGenericTitle(item.title)
            if let candidateTitle, !LinkMetadataLoader.isGenericTitle(candidateTitle) {
                if currentIsGeneric || LinkMetadataLoader.isGenericTitle(item.title) {
                    item.title = candidateTitle
                }
            }
            item.siteName = metadata.site ?? item.siteName
            if let desc = metadata.description, !desc.isEmpty, !LinkMetadataLoader.isGenericDescription(desc) {
                item.metadataDescription = desc
                if item.summary.isEmpty {
                    item.summary = desc
                }
            }
            item.previewImageUrl = metadata.image ?? item.previewImageUrl
            item.faviconUrl = metadata.faviconUrl ?? item.faviconUrl
            if !metadata.keywords.isEmpty {
                let junkTags: Set<String> = ["sharing", "camera phone", "video phone", "free", "upload", "playlist", "video playlist", "youtube"]
                let filteredCurrent = item.tags.filter { !junkTags.contains($0.lowercased()) }
                let filteredNew = metadata.keywords.filter { !junkTags.contains($0.lowercased()) }
                let merged = Set(filteredCurrent + filteredNew.map { $0.lowercased() })
                if !merged.isEmpty {
                    item.tags = Array(merged).sorted()
                }
            }
            if let ct = metadata.contentType, !ct.isEmpty, item.type == ItemContentType.link.rawValue {
                item.type = ct
            }
            item.enrichmentStatus = "enriched"
            item.updatedAt = Date()
            item.isSyncPending = true
            try context.save()
        } catch {
            guard currentUserId == expectedUserID, authToken == expectedAuthToken else { return }
            let descriptor = FetchDescriptor<LBItem>(predicate: #Predicate { $0.id == id })
            if let item = try? context.fetch(descriptor).first,
               item.status != ItemStatus.deleted.rawValue {
                item.enrichmentStatus = "failed"
                try? context.save()
            }
        }
    }

    // MARK: - Item Actions
    public func markDone(item: LBItem, context: ModelContext) {
        guard !isCloudStorageFull else {
            showingStorageFullAlert = true
            LBHaptic.warning()
            return
        }
        item.status = ItemStatus.saved.rawValue
        item.updatedAt = Date()
        item.isSyncPending = true
        do {
            try context.save()
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [item.id])
            Task { await syncPendingItems(context: context) }
        } catch { context.rollback() }
        LBHaptic.light()
    }

    /// Dismiss a return reminder without deleting the saved content.
    /// The item remains recoverable from Archive.
    public func dismissReturn(item: LBItem, context: ModelContext) {
        guard !isCloudStorageFull else {
            showingStorageFullAlert = true
            LBHaptic.warning()
            return
        }
        guard item.status == ItemStatus.deferred.rawValue else { return }
        item.status = ItemStatus.archived.rawValue
        item.returnAt = nil
        item.updatedAt = Date()
        item.isSyncPending = true
        do {
            try context.save()
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [item.id])
            Task { await syncPendingItems(context: context) }
        } catch { context.rollback() }
        LBHaptic.light()
    }

    public func scheduleItem(item: LBItem, date: Date, context: ModelContext) {
        guard !isCloudStorageFull else {
            showingStorageFullAlert = true
            LBHaptic.warning()
            return
        }
        item.status = ItemStatus.deferred.rawValue
        item.inboxEnteredAt = nil
        item.returnAt = date
        item.updatedAt = Date()
        item.isSyncPending = true
        do {
            try context.save()
            Task {
                _ = try? await ReturnNotification.update(id: item.id, title: item.title, description: item.notificationDescription, date: date)
                await syncPendingItems(context: context)
            }
        } catch { context.rollback() }
        LBHaptic.light()
    }

    public func toggleFavorite(item: LBItem, context: ModelContext) {
        guard !isCloudStorageFull else {
            showingStorageFullAlert = true
            LBHaptic.warning()
            return
        }
        item.favorite.toggle()
        item.updatedAt = Date()
        item.isSyncPending = true
        do {
            try context.save()
            Task { await syncPendingItems(context: context) }
        } catch { context.rollback() }
        LBHaptic.light()
    }

    public func markItemSeen(item: LBItem, context: ModelContext) {
        guard item.parsedStatus == .inbox, !item.seen else { return }
        item.seen = true
        item.updatedAt = Date()
        item.isSyncPending = true
        do {
            try context.save()
            Task { await syncPendingItems(context: context) }
        } catch {
            context.rollback()
        }
    }

    public func deleteItem(item: LBItem, context: ModelContext) {
        item.status = ItemStatus.deleted.rawValue
        item.updatedAt = Date()
        item.isSyncPending = true
        do {
            try context.save()
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [item.id])
            Task { await syncPendingItems(context: context) }
        } catch { context.rollback() }
        LBHaptic.medium()
    }

    public func restoreItem(item: LBItem, context: ModelContext) {
        guard !isCloudStorageFull else {
            showingStorageFullAlert = true
            LBHaptic.warning()
            return
        }
        item.status = ItemStatus.saved.rawValue
        item.updatedAt = Date()
        item.isSyncPending = true
        do {
            try context.save()
            Task { await syncPendingItems(context: context) }
        } catch { context.rollback() }
        LBHaptic.success()
    }

    var cloudDeletionQueue: [String] {
        get { defaults.stringArray(forKey: "lb_cloud_deletions_\(currentUserId ?? "guest")") ?? [] }
        set { defaults.set(newValue, forKey: "lb_cloud_deletions_\(currentUserId ?? "guest")") }
    }

    public func permanentlyDeleteItem(item: LBItem, context: ModelContext) {
        let id = item.id
        let needsCloudDeletion = currentUserId != nil && (item.userId == nil || item.userId?.caseInsensitiveCompare(currentUserId!) == .orderedSame)
        // Keep a durable deletion request so an offline delete cannot reappear on download.
        if needsCloudDeletion, !cloudDeletionQueue.contains(id) { cloudDeletionQueue.append(id) }
        context.delete(item)
        do {
            try context.save()
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [item.id])
            Task { await syncPendingItems(context: context) }
        } catch {
            context.rollback()
            if needsCloudDeletion { cloudDeletionQueue.removeAll { $0 == id } }
        }
        LBHaptic.medium()
    }

    // MARK: - Local Push Count
    @discardableResult
    public func updateLocalPendingPushCount(context: ModelContext) -> Int {
        do {
            let uid = currentUserId
            let pending = try context.fetch(FetchDescriptor<LBItem>())
                .filter { $0.isSyncPending && ($0.userId == nil || $0.userId == uid) }
                .count
            let total = pending + cloudDeletionQueue.count
            self.pendingPushCount = total
            return total
        } catch {
            return self.pendingPushCount
        }
    }

    // MARK: - Check Remote Changes
    private func countRemoteChanges(_ remoteList: [CloudItemSnapshot], local: [LBItem]) -> Int {
        var byID: [String: LBItem] = [:]
        var byURL: [String: LBItem] = [:]
        for item in local {
            byID[item.id.lowercased()] = item
            if let normalized = LBItem.normalizeURL(item.url) {
                if let existing = byURL[normalized] {
                    if !item.isSyncPending && existing.isSyncPending {
                        byURL[normalized] = item
                    }
                } else {
                    byURL[normalized] = item
                }
            }
        }

        var countedKeys = Set<String>()
        var count = 0
        for remote in remoteList {
            let remoteID = remote.id.lowercased()
            let normalizedURL = LBItem.normalizeURL(remote.url)
            let localMatch = byID[remoteID] ?? normalizedURL.flatMap { byURL[$0] }
            let key = localMatch.map { "local:\($0.id.lowercased())" }
                ?? normalizedURL.map { "url:\($0)" }
                ?? "remote:\(remoteID)"
            guard countedKeys.insert(key).inserted else { continue }

            guard let localMatch else {
                if remote.deleted_at == nil && !cloudDeletionQueue.contains(where: { $0.caseInsensitiveCompare(remote.id) == .orderedSame }) {
                    count += 1
                }
                continue
            }

            let remoteDate = remote.updated_at.flatMap(Self.cloudDate) ?? .distantPast
            if remoteDate > localMatch.updatedAt {
                count += 1
            } else if remoteDate == localMatch.updatedAt {
                let remoteIsDeleted = remote.deleted_at != nil
                let localIsDeleted = localMatch.status == ItemStatus.deleted.rawValue
                if remoteIsDeleted && !localIsDeleted {
                    count += 1
                }
            }
        }
        return count
    }

    @discardableResult
    public func checkRemoteChanges(context: ModelContext) async -> Int {
        await checkRemoteChanges(context: context, transport: nil)
    }

    @discardableResult
    func checkRemoteChanges(context: ModelContext, transport: (any IOSCloudTransport)?) async -> Int {
        guard hasCloudPro, isAuthenticated, let uid = currentUserId, let token = authToken else {
            self.pendingPullCount = 0
            return 0
        }
        guard !isCheckingRemoteChanges else { return self.pendingPullCount }
        self.isCheckingRemoteChanges = true
        defer { self.isCheckingRemoteChanges = false }

        let api: any IOSCloudTransport = transport ?? LaterBoxAPIService.shared
        do {
            let data = try await api.cloudRequest("items?user_id=eq.\(uid)&select=id,url,updated_at,deleted_at", token: token, method: "GET", body: nil)
            let remoteList = (try? JSONDecoder().decode([CloudItemSnapshot].self, from: data)) ?? []
            let local = (try? context.fetch(FetchDescriptor<LBItem>())) ?? []
            self.pendingPullCount = countRemoteChanges(remoteList, local: local)
            _ = self.updateLocalPendingPushCount(context: context)
            return self.pendingPullCount
        } catch {
            if let syncErr = error as? CloudSyncError, case .unauthorized = syncErr {
                if await refreshAuthSession(), let refreshedToken = authToken {
                    if let retryData = try? await api.cloudRequest("items?user_id=eq.\(uid)&select=id,url,updated_at,deleted_at", token: refreshedToken, method: "GET", body: nil) {
                        let remoteList = (try? JSONDecoder().decode([CloudItemSnapshot].self, from: retryData)) ?? []
                        let local = (try? context.fetch(FetchDescriptor<LBItem>())) ?? []
                        self.pendingPullCount = countRemoteChanges(remoteList, local: local)
                        _ = self.updateLocalPendingPushCount(context: context)
                        return self.pendingPullCount
                    }
                }
                self.sessionExpired = true
            }
            return self.pendingPullCount
        }
    }

    public func refreshPendingCounts(context: ModelContext) {
        _ = updateLocalPendingPushCount(context: context)
        Task {
            await checkRemoteChanges(context: context)
        }
    }

    // MARK: - Separate Pull Changes
    public func pullChanges(context: ModelContext) async {
        await pullChanges(context: context, transport: nil)
    }

    func pullChanges(context: ModelContext, transport: (any IOSCloudTransport)?) async {
        guard hasCloudPro else { return }
        guard !isPulling && syncState != .syncing else { return }
        isPulling = true
        syncState = .syncing
        defer { isPulling = false }

        do {
            _ = try await performCloudPull(context: context, transport: transport)
            self.syncState = .synced
            self.lastSyncedAt = Date()
            self.lastSyncErrorMessage = nil
            self.pendingPullCount = 0
            _ = self.updateLocalPendingPushCount(context: context)
        } catch {
            self.handleSyncError(error)
        }
    }

    // MARK: - Separate Push Changes
    public func pushChanges(context: ModelContext) async {
        await pushChanges(context: context, transport: nil)
    }

    func pushChanges(context: ModelContext, transport: (any IOSCloudTransport)?) async {
        guard hasCloudPro else { return }
        guard !isPushing && syncState != .syncing else { return }
        isPushing = true
        syncState = .syncing
        defer { isPushing = false }

        do {
            _ = try await performCloudPush(context: context, transport: transport)
            self.syncState = .synced
            self.lastSyncedAt = Date()
            self.lastSyncErrorMessage = nil
            _ = self.updateLocalPendingPushCount(context: context)
        } catch {
            self.handleSyncError(error)
        }
    }

    // MARK: - Full Bidirectional Sync (Pull then Push)
    public func pullAndPushChanges(context: ModelContext) async {
        await pullAndPushChanges(context: context, transport: nil)
    }

    func pullAndPushChanges(context: ModelContext, transport: (any IOSCloudTransport)?) async {
        await syncPendingItems(context: context, transport: transport)
    }

    public func syncPendingItems(context: ModelContext) async {
        await syncPendingItems(context: context, announceFailure: true)
    }

    public func syncPendingItems(context: ModelContext, announceFailure: Bool) async {
        await syncPendingItems(context: context, transport: nil, announceFailure: announceFailure)
    }

    func syncPendingItems(context: ModelContext, transport: (any IOSCloudTransport)?, announceFailure: Bool = true) async {
        if !hasCloudPro && !cloudDeletionQueue.isEmpty {
            do { _ = try await performCloudPush(context: context, transport: transport, deletionsOnly: true) }
            catch { handleSyncError(error, announce: announceFailure); return }
        }
        guard hasCloudPro else {
            self.syncState = .offline
            self.lastSyncErrorMessage = nil
            return
        }
        guard syncState != .syncing && !isPulling && !isPushing else { return }
        syncState = .syncing

        do {
            await StoreKitManager.shared.registerAccountPurchases()
            try await performCloudSync(context: context, transport: transport)

            self.syncState = .synced
            self.lastSyncedAt = Date()
            self.lastSyncErrorMessage = nil
            self.pendingPullCount = 0
            _ = self.updateLocalPendingPushCount(context: context)
            if isCloudStorageFull {
                // A successful cloud deletion can release space immediately.
                _ = await refreshEntitlement()
            }
        } catch {
            self.handleSyncError(error, announce: announceFailure)
        }
    }

    private func handleSyncError(_ error: Error, announce: Bool = true) {
        // SwiftUI cancels refresh tasks when the refresh control finishes or the
        // view disappears. URLSession surfaces that cancellation as a network
        // error, but it is not a failed sync and should never show an alert.
        if error is CancellationError || (error as? URLError)?.code == .cancelled {
            if syncState == .syncing {
                syncState = .synced
            }
            lastSyncErrorMessage = nil
            return
        }
        self.syncState = .error
        if let syncErr = error as? CloudSyncError {
            if case .unauthorized = syncErr {
                self.sessionExpired = true
            }
            self.lastSyncErrorMessage = syncErr.localizedDescription
        } else if let urlErr = error as? URLError {
            switch urlErr.code {
            case .notConnectedToInternet, .networkConnectionLost, .dnsLookupFailed:
                self.lastSyncErrorMessage = "No internet connection. Changes will sync once back online."
            case .timedOut:
                self.lastSyncErrorMessage = "Request timed out connecting to cloud server."
            default:
                self.lastSyncErrorMessage = urlErr.localizedDescription
            }
        } else {
            self.lastSyncErrorMessage = error.localizedDescription
        }
        if announce {
            self.showingSyncFailureAlert = true
        }
    }
}
