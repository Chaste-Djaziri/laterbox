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
                    VStack(alignment: .leading, spacing: 22) {
                        // User Profile Card
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color.lbAmber.opacity(0.2))
                                        .frame(width: 52, height: 52)
                                    Image(systemName: coordinator.currentUserEmail != nil ? "person.fill" : "person.crop.circle.badge.questionmark")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color.lbAmber)
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                    if let email = coordinator.currentUserEmail {
                                        Text(email)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                        HStack(spacing: 4) {
                                            Image(systemName: "checkmark.seal.fill")
                                                .font(.caption2)
                                                .foregroundColor(Color.lbAmber)
                                            Text("LaterBox Pro Active")
                                                .font(.caption.weight(.semibold))
                                                .foregroundColor(Color.lbAmber)
                                        }
                                    } else {
                                        Text("Guest Mode")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text("Local saving active • Sign in for cloud sync")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Spacer()

                                if coordinator.currentUserEmail == nil {
                                    Button(action: { showingAuthSheet = true }) {
                                        Text("Sign In")
                                            .font(.caption.weight(.bold))
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(Color.lbAmber)
                                            .foregroundColor(.black)
                                            .clipShape(Capsule())
                                    }
                                } else {
                                    Button(action: { showingSignOutAlert = true }) {
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .liquidGlassCard(cornerRadius: 20)

                        // LaterBox Pro Benefits Card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(Color.lbAmber)
                                Text("LaterBox Pro")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("Active")
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(Color.lbAmber.opacity(0.25)))
                                    .foregroundColor(Color.lbAmber)
                            }

                            Text("Your subscription includes multi-device cloud synchronization, real-time Safari and Chrome extensions, AI inbox suggestions, and unlimited storage.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineSpacing(2)

                            Divider().background(Color.white.opacity(0.08))

                            HStack(spacing: 16) {
                                benefitPill(icon: "icloud.fill", text: "Cloud Sync")
                                benefitPill(icon: "wand.and.stars", text: "AI Organizer")
                                benefitPill(icon: "safari.fill", text: "Extensions")
                            }
                        }
                        .padding(16)
                        .liquidGlassCard(cornerRadius: 20, borderOpacity: 0.3)

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
                                        Image(systemName: coordinator.syncState.iconName)
                                            .foregroundColor(coordinator.syncState.statusColor)
                                        Text("Sync Status")
                                            .font(.subheadline)
                                    }
                                    Spacer()
                                    Text(coordinator.syncState.rawValue)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(coordinator.syncState.statusColor)
                                }

                                Divider().background(Color.white.opacity(0.08))

                                // Last Synced Row
                                HStack {
                                    Text("Last Updated")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(coordinator.lastSyncedAt != nil ? coordinator.lastSyncedAt!.formatted(date: .omitted, time: .shortened) : "Just now")
                                        .font(.caption.weight(.medium))
                                        .foregroundColor(.primary)
                                }

                                Divider().background(Color.white.opacity(0.08))

                                // Web Platform Status Row
                                HStack {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(coordinator.isSystemOperational ? Color.green : Color.orange)
                                            .frame(width: 8, height: 8)
                                        Text("LaterBox Web Platform")
                                            .font(.subheadline)
                                    }
                                    Spacer()
                                    Text(coordinator.systemStatusText)
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(.secondary)
                                }

                                Divider().background(Color.white.opacity(0.08))

                                // Manual Sync Button
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
                                    .background(Color.white.opacity(0.06))
                                    .foregroundColor(Color.lbAmber)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                            .padding(16)
                            .liquidGlassCard(cornerRadius: 18)
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
                                    Text("\(allItems.count) entries in encrypted SwiftData store")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text("\(allItems.count)")
                                    .font(.title3.weight(.bold).monospaced())
                                    .foregroundColor(.primary)
                            }
                            .padding(16)
                            .liquidGlassCard(cornerRadius: 18)
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
                    .padding(20)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
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

    private func benefitPill(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(Color.lbAmber)
            Text(text)
                .font(.caption2.weight(.medium))
                .foregroundColor(.primary)
        }
    }
}
