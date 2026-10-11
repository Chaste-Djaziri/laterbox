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
                                .fill(coordinator.isAuthenticated ? AppTheme.accent : Color.orange.opacity(0.15))
                                .frame(width: 72, height: 72)
                            Image(systemName: coordinator.isAuthenticated ? coordinator.syncState.iconName : "bolt.horizontal.icloud.fill")
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(coordinator.isAuthenticated ? coordinator.syncState.statusColor : Color.orange)
                        }

                        VStack(spacing: 4) {
                            Text(coordinator.isAuthenticated ? coordinator.syncState.rawValue : "Local Mode")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)

                            Text(coordinator.isAuthenticated ? "Multi-device cloud synchronization active" : "Items are stored privately on this device")
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
                                        .foregroundColor(coordinator.syncState.statusColor)
                                    Text("Sync Engine Status")
                                        .font(.subheadline)
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                                Spacer()
                                Text(coordinator.isAuthenticated ? coordinator.syncState.rawValue : "Off (Local Only)")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(coordinator.isAuthenticated ? coordinator.syncState.statusColor : AppTheme.textSecondary)
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
                                Text(coordinator.isAuthenticated ? (coordinator.lastSyncedAt != nil ? coordinator.lastSyncedAt!.formatted(date: .omitted, time: .shortened) : "Just now") : "Never (Local)")
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

                        if coordinator.isAuthenticated {
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
                                    Text(isSyncing ? "Syncing with Cloud…" : "Trigger Sync Now")
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
                                coordinator.showingPlansSheet = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "crown.fill")
                                    Text("Upgrade to Pro to Enable Cloud Sync")
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
        .alert("Cloud Sync", isPresented: $showingSyncCompleteAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Cloud sync completed successfully.")
        }
    }
}
