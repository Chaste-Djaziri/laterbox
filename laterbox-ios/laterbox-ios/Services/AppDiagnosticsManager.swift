//
//  AppDiagnosticsManager.swift
//  laterbox-ios
//
//  Collects system metadata, sync health, and error details for
//  error diagnosis, support tickets, and direct export.
//

import Foundation
import UIKit
import SwiftData

public struct AppDiagnosticReport: Identifiable, Sendable {
    public let id = UUID()
    public let timestamp: Date
    public let appVersion: String
    public let buildNumber: String
    public let bundleIdentifier: String
    public let iosVersion: String
    public let deviceMarketingName: String
    public let deviceHardwareSummary: String
    public let screenResolution: String
    public let locale: String
    public let timeZone: String
    public let activeScreen: String
    public let userEmail: String
    public let accountTier: String
    public let isPro: Bool
    public let sessionExpired: Bool
    public let cloudSyncState: String
    public let lastSyncTime: String
    public let pendingPushes: Int
    public let pendingPulls: Int
    public let activeSyncOperation: String
    public let storageUsedLabel: String
    public let storageLimitLabel: String
    public let storagePercent: String
    public let storageLevel: String
    public let totalVaultItems: Int
    public let inboxItems: Int
    public let savedItems: Int
    public let archivedItems: Int
    public let deletedItems: Int
    public let apiEndpoint: String
    public let webEndpoint: String
    public let activeErrorMessage: String?

    public var hasError: Bool {
        activeErrorMessage != nil && !(activeErrorMessage?.isEmpty ?? true)
    }

    public var formattedSummary: String {
        var lines: [String] = []
        if let err = activeErrorMessage, !err.isEmpty {
            lines.append("ERROR DETAILS:")
            lines.append(err)
            lines.append("")
        }

        lines.append("DIAGNOSTICS SUMMARY:")
        lines.append("• App: LaterBox \(appVersion) (\(buildNumber))")
        lines.append("• Device: \(deviceMarketingName) · \(deviceHardwareSummary) · iOS \(iosVersion)")
        lines.append("• Screen: \(activeScreen)")
        lines.append("• Account: \(userEmail) (\(accountTier.capitalized))")
        lines.append("• Cloud Sync: \(cloudSyncState) (Pushes: \(pendingPushes), Pulls: \(pendingPulls))")
        lines.append("• Storage: \(storageUsedLabel) / \(storageLimitLabel) (\(storagePercent))")
        lines.append("• Vault Items: \(totalVaultItems) total (\(inboxItems) inbox, \(savedItems) saved, \(archivedItems) archived)")
        lines.append("• Timestamp: \(timestamp.formatted(date: .abbreviated, time: .standard))")

        return lines.joined(separator: "\n")
    }

    public var markdownExport: String {
        let isoFormatter = ISO8601DateFormatter()
        let isoDate = isoFormatter.string(from: timestamp)

        var sections: [String] = []

        sections.append("""
# LaterBox iOS Diagnostic Report
Generated: \(isoDate)

""")

        if let err = activeErrorMessage, !err.isEmpty {
            sections.append("""
## Active Error
```text
\(err)
```

""")
        }

        sections.append("""
## Application
- Version: \(appVersion)
- Build: \(buildNumber)
- Bundle ID: \(bundleIdentifier)
- Active Screen: \(activeScreen)

## Device & Environment
- Device: \(deviceMarketingName)
- Hardware: \(deviceHardwareSummary)
- OS: iOS \(iosVersion)
- Resolution: \(screenResolution)
- Locale: \(locale)
- TimeZone: \(timeZone)

## Account & Subscription
- User: \(userEmail)
- Tier: \(accountTier)
- Pro Access: \(isPro ? "Active" : "Inactive")
- Session Expired: \(sessionExpired ? "Yes" : "No")

## Cloud Sync
- State: \(cloudSyncState)
- Last Synced: \(lastSyncTime)
- Pending Outgoing: \(pendingPushes)
- Pending Incoming: \(pendingPulls)
- Current Operations: \(activeSyncOperation)

## Cloud Storage Quota
- Used: \(storageUsedLabel)
- Limit: \(storageLimitLabel)
- Utilization: \(storagePercent)
- Health Level: \(storageLevel)

## Local Vault
- Total Items: \(totalVaultItems)
- Inbox: \(inboxItems)
- Saved / Kept: \(savedItems)
- Archived: \(archivedItems)
- Deleted: \(deletedItems)

## Network Endpoints
- API / Supabase: \(apiEndpoint)
- Web App: \(webEndpoint)
""")

        return sections.joined(separator: "\n")
    }
}

public final class AppDiagnosticsManager {
    public static let shared = AppDiagnosticsManager()

    private init() {}

    @MainActor
    public func generateReport(
        context: ModelContext? = nil,
        specificError: String? = nil,
        activeScreen: String? = nil
    ) -> AppDiagnosticReport {
        let coordinator = SyncCoordinator.shared
        let entitlement = coordinator.billingEntitlement
        let quota = CloudStorageQuota.from(entitlement)

        // Device & hardware specs
        let deviceName = OnDeviceModelSupport.deviceMarketingName
        let hardware = LaterAIModelManager.shared.deviceHardwareSummary
        let systemVersion = UIDevice.current.systemVersion
        let bounds = UIScreen.main.bounds
        let scale = UIScreen.main.scale
        let screenRes = "\(Int(bounds.width))x\(Int(bounds.height)) @ \(Int(scale))x"

        // Local Vault Item counts
        var total = 0
        var inbox = 0
        var saved = 0
        var archived = 0
        var deleted = 0

        if let context {
            let descriptor = FetchDescriptor<LBItem>()
            if let items = try? context.fetch(descriptor) {
                total = items.count
                for item in items {
                    switch item.status {
                    case ItemStatus.inbox.rawValue, "inbox":
                        inbox += 1
                    case ItemStatus.saved.rawValue, ItemStatus.deferred.rawValue, "saved", "deferred":
                        saved += 1
                    case ItemStatus.archived.rawValue, "archived":
                        archived += 1
                    case ItemStatus.deleted.rawValue, "deleted":
                        deleted += 1
                    default:
                        break
                    }
                }
            }
        }

        // Active error message
        let effectiveError: String?
        if let specificError, !specificError.isEmpty {
            effectiveError = specificError
        } else if let syncErr = coordinator.lastSyncErrorMessage, !syncErr.isEmpty {
            effectiveError = syncErr
        } else {
            effectiveError = nil
        }

        let syncOps: String
        if coordinator.isPulling && coordinator.isPushing {
            syncOps = "Pulling & Pushing"
        } else if coordinator.isPulling {
            syncOps = "Pulling"
        } else if coordinator.isPushing {
            syncOps = "Pushing"
        } else {
            syncOps = "Idle"
        }

        let lastSyncStr: String
        if let lastSync = coordinator.lastSyncedAt {
            lastSyncStr = lastSync.formatted(date: .abbreviated, time: .standard)
        } else {
            lastSyncStr = "Never"
        }

        let userEmailStr = coordinator.currentUserEmail ?? (coordinator.isGuestMode ? "Guest User" : "Unauthenticated")
        let tierStr = entitlement?.tier ?? (coordinator.isGuestMode ? "guest" : "free")
        let isPro = entitlement?.hasAccess ?? false

        let percentStr: String
        if let pct = quota.percent {
            percentStr = String(format: "%.1f%%", pct)
        } else {
            percentStr = "N/A"
        }

        return AppDiagnosticReport(
            timestamp: Date(),
            appVersion: AppVersion.currentVersion,
            buildNumber: AppVersion.currentBuild,
            bundleIdentifier: Bundle.main.bundleIdentifier ?? "dev.laterbox.app",
            iosVersion: systemVersion,
            deviceMarketingName: deviceName,
            deviceHardwareSummary: hardware,
            screenResolution: screenRes,
            locale: Locale.current.identifier,
            timeZone: TimeZone.current.identifier,
            activeScreen: activeScreen ?? "General",
            userEmail: userEmailStr,
            accountTier: tierStr,
            isPro: isPro,
            sessionExpired: coordinator.sessionExpired,
            cloudSyncState: coordinator.syncState.rawValue,
            lastSyncTime: lastSyncStr,
            pendingPushes: coordinator.pendingPushCount,
            pendingPulls: coordinator.pendingPullCount,
            activeSyncOperation: syncOps,
            storageUsedLabel: quota.usedLabel,
            storageLimitLabel: quota.limitLabel,
            storagePercent: percentStr,
            storageLevel: quota.level.title,
            totalVaultItems: total,
            inboxItems: inbox,
            savedItems: saved,
            archivedItems: archived,
            deletedItems: deleted,
            apiEndpoint: LaterBoxAPIService.shared.supabaseUrl,
            webEndpoint: LaterBoxAPIService.shared.webUrl,
            activeErrorMessage: effectiveError
        )
    }

    public func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
    }
}

