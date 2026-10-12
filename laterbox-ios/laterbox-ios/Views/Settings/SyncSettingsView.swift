//
//  SyncSettingsView.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 11.10.26.
//

import SwiftUI
import SwiftData

public struct SyncSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var coordinator = SyncCoordinator.shared
    @State private var showingSyncCompleteAlert = false
    @State private var isSyncing = false

    public init() {}

    public var body: some View {
        ZStack {
            LiquidGlassBackground()

            ScrollView {
                VStack(spacing: 20) {
                    // Header Status Card
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(coordinator.hasCloudPro ? AppTheme.accent : Color.orange.opacity(0.15))
                                .frame(width: 72, height: 72)
                            Image(systemName: coordinator.hasCloudPro ? coordinator.syncState.iconName : ((coordinator.isAuthenticated) ? "crown.fill" : "bolt.horizontal.icloud.fill"))
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(coordinator.hasCloudPro ? coordinator.syncState.statusColor : Color.orange)
                        }

                        VStack(spacing: 4) {
                            Text(coordinator.hasCloudPro ? coordinator.syncState.rawValue : (coordinator.isAuthenticated ? coordinator.isProUser ? "Device Pro (Local Only)" : "Free Plan (Local Only)" : "Local Mode"))
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)

                            Text(coordinator.hasCloudPro ? "Multi-device cloud synchronization active" : (coordinator.isAuthenticated ? coordinator.isProUser ? "Connect Pro to your account to enable cloud sync. Account connection is optional." : "Cloud sync is exclusive to Pro. Upgrade to sync across all devices." : "Items are stored privately on this device"))
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)

                    // Live Diagnostics Card
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Sync Metrics & Health")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        VStack(spacing: 12) {
                            HStack {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .foregroundColor(coordinator.hasCloudPro ? coordinator.syncState.statusColor : AppTheme.textSecondary)
                                    Text("Sync Engine Status")
                                        .font(.subheadline)
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                                Spacer()
                                Text(coordinator.hasCloudPro ? coordinator.syncState.rawValue : (coordinator.isAuthenticated ? "Off (Pro Required)" : "Off (Local Only)"))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(coordinator.hasCloudPro ? coordinator.syncState.statusColor : AppTheme.textSecondary)
                            }

                            Divider().background(AppTheme.cardBorder)

                            HStack {
                                HStack(spacing: 8) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .foregroundColor(AppTheme.textSecondary)
                                    Text("Last Updated")
                                        .font(.subheadline)
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                                Spacer()
                                Text(coordinator.hasCloudPro ? (coordinator.lastSyncedAt != nil ? coordinator.lastSyncedAt!.formatted(date: .omitted, time: .shortened) : "Just now") : (coordinator.isAuthenticated ? "Disabled on Free Plan" : "Never (Local)"))
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(AppTheme.textPrimary)
                            }

                            Divider().background(AppTheme.cardBorder)

                            HStack {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(coordinator.isSystemOperational ? Color.green : Color.orange)
                                        .frame(width: 8, height: 8)
                                    Text("Web Platform Server")
                                        .font(.subheadline)
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                                Spacer()
                                Text(coordinator.systemStatusText)
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(AppTheme.textSecondary)
                            }

                            if coordinator.hasCloudPro, coordinator.syncState == .error, let errorMsg = coordinator.lastSyncErrorMessage, !errorMsg.isEmpty {
                                Divider().background(AppTheme.cardBorder)

                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                        .font(.subheadline)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Sync Failure Reason")
                                            .font(.caption.weight(.bold))
                                            .foregroundColor(.red)
                                        Text(errorMsg)
                                            .font(.caption)
                                            .foregroundColor(AppTheme.textSecondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(AppTheme.cardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                        )
                    }

                    // Actions Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Actions")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        if coordinator.hasCloudPro {
                            Button(action: {
                                LBHaptic.medium()
                                isSyncing = true
                                Task {
                                    await coordinator.syncPendingItems(context: modelContext)
                                    await MainActor.run {
                                        isSyncing = false
                                        showingSyncCompleteAlert = true
                                    }
                                }
                            }) {
                                HStack(spacing: 8) {
                                    if isSyncing {
                                        ProgressView()
                                            .tint(AppTheme.textPrimary)
                                    } else {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                    }
                                    Text(isSyncing ? "Syncing with Cloud…" : "Force Sync Now")
                                        .font(.subheadline.weight(.semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(AppTheme.accent)
                                .foregroundColor(AppTheme.textPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)
                            .disabled(isSyncing)
                        } else {
                            Button(action: {
                                LBHaptic.light()
                                if !coordinator.isAuthenticated {
                                    coordinator.showingAuthSheet = true
                                } else {
                                    coordinator.showingPlansSheet = true
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "crown.fill")
                                        .foregroundColor(.orange)
                                    Text(coordinator.isAuthenticated ? "Upgrade to Pro to Force Sync" : "Sign in & Upgrade to Pro to Sync")
                                        .font(.subheadline.weight(.semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(AppTheme.darkSurface)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Explanatory Info Card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("About Multi-Device Sync")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("When Pro is active, changes made in your iOS app, Chrome extension, Safari extension, and web browser are synchronized instantaneously.")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                                .lineSpacing(2)

                            Text("• Timestamp-based conflict resolution preserves your newest changes.")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                            Text("• Local offline caching ensures instant loading with or without internet.")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(AppTheme.cardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Cloud Sync & Diagnostics")
        .navigationBarTitleDisplayMode(.inline)
        .alert(coordinator.syncState == .error ? "Sync Failed" : "Cloud Sync", isPresented: $showingSyncCompleteAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            if coordinator.syncState == .error {
                Text(coordinator.lastSyncErrorMessage ?? "An unexpected error occurred during cloud sync.")
            } else {
                Text("Cloud sync completed successfully.")
            }
        }
    }
}
