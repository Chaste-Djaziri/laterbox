//
//  SettingsView.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 04.10.26.
//

import SwiftUI
import SwiftData

public struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allItems: [LBItem]
    @ObservedObject var coordinator = SyncCoordinator.shared

    @State private var showingAuthSheet = false
    @State private var showingSignOutAlert = false
    @State private var showingSyncCompleteAlert = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Top Level Header (Scrolls normally, uncontainerized on canvas)
                        HStack(alignment: .center) {
                            HStack(spacing: 8) {
                                Image("LaterboxIconGreen")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 28, height: 28)
                                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

                                Text("Settings")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(AppTheme.textPrimary)
                            }

                            Spacer()

                            // Sync Status Indicator (No Container)
                            Button(action: {
                                if !coordinator.isAuthenticated {
                                    LBHaptic.light()
                                    coordinator.showingAuthSheet = true
                                }
                            }) {
                                HStack(spacing: 5) {
                                    Circle()
                                        .fill(coordinator.syncHeaderColor)
                                        .frame(width: 7, height: 7)
                                    Text(coordinator.syncHeaderTitle)
                                        .font(.caption2.weight(.medium))
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 4)

                        // User Profile (Centered, uncontainerized, app theme colors)
                        VStack(alignment: .center, spacing: 12) {
                            // Centered Profile Icon (green background, black icon)
                            ZStack {
                                Circle()
                                    .fill(AppTheme.accent)
                                    .frame(width: 72, height: 72)
                                Image(systemName: "person.fill")
                                    .font(.system(size: 32, weight: .semibold))
                                    .foregroundColor(AppTheme.textPrimary)
                            }

                            // Centered Name & Description
                            VStack(spacing: 4) {
                                if let email = coordinator.currentUserEmail {
                                    Text(email)
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(AppTheme.textPrimary)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(1)

                                    HStack(spacing: 5) {
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.caption)
                                            .foregroundColor(AppTheme.textPrimary)
                                        Text("LaterBox Pro Active")
                                            .font(.subheadline.weight(.medium))
                                            .foregroundColor(AppTheme.textSecondary)
                                    }
                                } else {
                                    Text("Guest Mode")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(AppTheme.textPrimary)
                                        .multilineTextAlignment(.center)

                                    Text("Local saving active • Sign in for cloud sync")
                                        .font(.subheadline)
                                        .foregroundColor(AppTheme.textSecondary)
                                        .multilineTextAlignment(.center)
                                }
                            }

                            // Full width Sign In button (button black, text white)
                            if coordinator.currentUserEmail == nil {
                                Button(action: {
                                    LBHaptic.light()
                                    showingAuthSheet = true
                                }) {
                                    Text("Sign In")
                                        .font(.headline.weight(.bold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .fill(AppTheme.darkSurface)
                                        )
                                }
                                .buttonStyle(.plain)
                                .padding(.top, 6)
                            } else {
                                Button(action: {
                                    LBHaptic.light()
                                    showingSignOutAlert = true
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                            .font(.subheadline.weight(.semibold))
                                        Text("Sign Out")
                                            .font(.subheadline.weight(.semibold))
                                    }
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(Color.red.opacity(0.1))
                                    )
                                }
                                .buttonStyle(.plain)
                                .padding(.top, 6)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)

                        // LaterBox Plan Card
                        VStack(alignment: .leading, spacing: 14) {
                            if coordinator.isAuthenticated {
                                // Pro Plan Active Card
                                HStack(alignment: .center) {
                                    HStack(spacing: 8) {
                                        ZStack {
                                            Circle()
                                                .fill(AppTheme.accent)
                                                .frame(width: 32, height: 32)
                                            Image(systemName: "crown.fill")
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundColor(AppTheme.textPrimary)
                                        }
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text("LaterBox Pro")
                                                .font(.headline.weight(.bold))
                                                .foregroundColor(AppTheme.textPrimary)
                                            Text("All features unlocked")
                                                .font(.caption)
                                                .foregroundColor(AppTheme.textSecondary)
                                        }
                                    }

                                    Spacer()

                                    Text("Active")
                                        .font(.caption2.weight(.bold))
                                        .foregroundColor(AppTheme.textPrimary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(AppTheme.accent)
                                        )
                                }

                                Text("Your subscription includes multi-device cloud synchronization, real-time Safari and Chrome extensions, AI inbox suggestions, and unlimited storage.")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textSecondary)
                                    .lineSpacing(2)

                                Divider().background(AppTheme.cardBorder)

                                HStack(spacing: 10) {
                                    benefitPill(icon: "icloud.fill", text: "Cloud Sync")
                                    benefitPill(icon: "wand.and.stars", text: "AI Organizer")
                                    benefitPill(icon: "safari.fill", text: "Extensions")
                                }
                            } else {
                                // Guest Mode: Local Plan + Pro Upgrade Pitch
                                HStack(alignment: .center) {
                                    HStack(spacing: 8) {
                                        ZStack {
                                            Circle()
                                                .fill(AppTheme.accent)
                                                .frame(width: 32, height: 32)
                                            Image(systemName: "internaldrive.fill")
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundColor(AppTheme.textPrimary)
                                        }
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text("LaterBox Local")
                                                .font(.headline.weight(.bold))
                                                .foregroundColor(AppTheme.textPrimary)
                                            Text("Offline storage only")
                                                .font(.caption)
                                                .foregroundColor(AppTheme.textSecondary)
                                        }
                                    }

                                    Spacer()

                                    Text("Free Forever")
                                        .font(.caption2.weight(.bold))
                                        .foregroundColor(AppTheme.textPrimary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(AppTheme.accent)
                                        )
                                }

                                Text("Local mode is 100% free forever. Your items are saved offline on this device with full privacy and zero tracking.")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textSecondary)
                                    .lineSpacing(2)

                                Divider().background(AppTheme.cardBorder)

                                // Pro Pitch Details
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "crown.fill")
                                            .font(.caption.weight(.bold))
                                            .foregroundColor(AppTheme.textPrimary)
                                        Text("Need cloud sync across devices?")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(AppTheme.textPrimary)
                                    }

                                    VStack(alignment: .leading, spacing: 6) {
                                        proFeatureRow(icon: "icloud.fill", text: "Multi-device real-time cloud sync")
                                        proFeatureRow(icon: "wand.and.stars", text: "AI inbox organizer & auto-tagging")
                                        proFeatureRow(icon: "safari.fill", text: "Desktop web app & browser extensions")
                                        proFeatureRow(icon: "lock.icloud.fill", text: "Encrypted cloud backup & restore")
                                    }

                                    HStack(alignment: .firstTextBaseline) {
                                        Text("$3.99")
                                            .font(.title3.weight(.bold))
                                            .foregroundColor(AppTheme.textPrimary)
                                        Text("/ month or $39.99 / year • 14-day free trial")
                                            .font(.caption)
                                            .foregroundColor(AppTheme.textSecondary)
                                    }
                                    .padding(.top, 2)

                                    Button(action: {
                                        LBHaptic.medium()
                                        showingAuthSheet = true
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "sparkles")
                                                .font(.subheadline.weight(.semibold))
                                            Text("Get Pro to Sync")
                                                .font(.headline.weight(.bold))
                                            Image(systemName: "arrow.right")
                                                .font(.subheadline.weight(.semibold))
                                        }
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 13)
                                        .background(
                                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                                .fill(AppTheme.darkSurface)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.top, 4)
                                }
                            }
                        }
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(AppTheme.cardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)

                        // Cloud Sync & Diagnostics
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Cloud Sync & Diagnostics")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)

                            VStack(spacing: 12) {
                                // Sync Status Row
                                HStack {
                                    HStack(spacing: 8) {
                                        Image(systemName: coordinator.isAuthenticated ? coordinator.syncState.iconName : "bolt.horizontal.icloud.fill")
                                            .foregroundColor(coordinator.isAuthenticated ? coordinator.syncState.statusColor : AppTheme.textSecondary)
                                        Text("Sync Status")
                                            .font(.subheadline)
                                            .foregroundColor(AppTheme.textPrimary)
                                    }
                                    Spacer()
                                    Text(coordinator.isAuthenticated ? coordinator.syncState.rawValue : "Off (Local Mode)")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(coordinator.isAuthenticated ? coordinator.syncState.statusColor : AppTheme.textSecondary)
                                }

                                Divider().background(AppTheme.cardBorder)

                                // Last Synced Row
                                HStack {
                                    Text("Last Updated")
                                        .font(.subheadline)
                                        .foregroundColor(AppTheme.textSecondary)
                                    Spacer()
                                    Text(coordinator.isAuthenticated ? (coordinator.lastSyncedAt != nil ? coordinator.lastSyncedAt!.formatted(date: .omitted, time: .shortened) : "Just now") : "Local Only")
                                        .font(.caption.weight(.medium))
                                        .foregroundColor(AppTheme.textPrimary)
                                }

                                Divider().background(AppTheme.cardBorder)

                                // Web Platform Status Row
                                HStack {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(coordinator.isSystemOperational ? Color.green : Color.orange)
                                            .frame(width: 8, height: 8)
                                        Text("LaterBox Web Platform")
                                            .font(.subheadline)
                                            .foregroundColor(AppTheme.textPrimary)
                                    }
                                    Spacer()
                                    Text(coordinator.systemStatusText)
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(AppTheme.textSecondary)
                                }

                                Divider().background(AppTheme.cardBorder)

                                // Manual Sync Button
                                if coordinator.isAuthenticated {
                                    Button(action: {
                                        LBHaptic.medium()
                                        Task {
                                            await coordinator.syncPendingItems(context: modelContext)
                                            showingSyncCompleteAlert = true
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "arrow.triangle.2.circlepath")
                                            Text("Trigger Sync Now")
                                                .font(.subheadline.weight(.semibold))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(AppTheme.accent.opacity(0.3))
                                        .foregroundColor(AppTheme.textPrimary)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    Button(action: {
                                        LBHaptic.light()
                                        showingAuthSheet = true
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "lock.fill")
                                                .font(.caption)
                                            Text("Get Pro to Enable Cloud Sync")
                                                .font(.subheadline.weight(.semibold))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(Color.black.opacity(0.05))
                                        .foregroundColor(AppTheme.textSecondary)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                    .buttonStyle(.plain)
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
                            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
                        }

                        // Local Storage Section
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Vault Storage")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)

                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Total Local Items")
                                        .font(.subheadline)
                                        .foregroundColor(AppTheme.textPrimary)
                                    Text("\(allItems.count) entries in encrypted SwiftData store")
                                        .font(.caption2)
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                                Spacer()
                                Text("\(allItems.count)")
                                    .font(.title3.weight(.bold).monospaced())
                                    .foregroundColor(AppTheme.textPrimary)
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
                            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
                        }

                        // App Version Footer
                        VStack(spacing: 4) {
                            Text("LaterBox for iOS • Liquid Glass Edition")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("Version 1.0.170 (Build 172)")
                                .font(.caption2.monospaced())
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 10)
                        .padding(.bottom, 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAuthSheet) {
                NavigationStack {
                    AuthView()
                }
            }
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Sign Out", role: .destructive) { coordinator.signOut() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your local items will be safely kept on this device.")
            }
            .alert("Cloud Sync", isPresented: $showingSyncCompleteAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Cloud sync completed successfully.")
            }
        }
    }

    private func proFeatureRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(AppTheme.textPrimary)
                .frame(width: 16)
            Text(text)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
        }
    }

    private func benefitPill(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(AppTheme.textPrimary)
            Text(text)
                .font(.caption2.weight(.medium))
                .foregroundColor(AppTheme.textPrimary)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(AppTheme.accent.opacity(0.5))
        )
    }
}
