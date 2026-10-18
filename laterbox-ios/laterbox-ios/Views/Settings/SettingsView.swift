//
//  SettingsView.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 04.10.26.
//

import SwiftUI
import UserNotifications
import SwiftData

public struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var coordinator = SyncCoordinator.shared
    @ObservedObject private var lockManager = AppLockManager.shared
    @ObservedObject private var iconManager = AppIconManager.shared
    @StateObject private var storageManager = LocalStorageManager.shared
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var showingSignOutAlert = false
    @State private var showingExitGuestAlert = false
    @State private var showingAuthSheet = false

    public init() {}

    public var body: some View {
        ZStack {
            AppTheme.canvasBackground
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    // Header Bar (left back button, centered title, right sync dot)
                    ZStack {
                        HStack {
                            Button {
                                dismiss()
                                LBHaptic.light()
                            } label: {
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(AppTheme.textPrimary)
                                    .frame(width: 38, height: 38)
                                    .background(Color.black.opacity(0.04), in: Circle())
                                    .contentShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Back to Inbox")

                            Spacer()

                            // Sync status indicator
                            Button(action: {
                                if !coordinator.hasCloudPro {
                                    LBHaptic.light()
                                    coordinator.showingPlansSheet = true
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

                        Text("Settings")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 6)

                    // Profile Card (matching reference layout)
                    NavigationLink(destination: AccountSettingsView()) {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.accent)
                                    .frame(width: 52, height: 52)
                                Image(systemName: "person.fill")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(AppTheme.textPrimary)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                if let email = coordinator.currentUserEmail {
                                    Text(email)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(AppTheme.textPrimary)
                                        .lineLimit(1)

                                    Text(coordinator.isProUser ? "LaterBox Pro Active" : "Free Cloud Account")
                                        .font(.caption.weight(.medium))
                                        .foregroundColor(AppTheme.textSecondary)
                                } else {
                                    Text("Guest Mode")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(AppTheme.textPrimary)

                                    Text("Local saving active • Tap to sign in")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppTheme.textSecondary.opacity(0.6))
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .liquidGlassCard(cornerRadius: 18)
                    }
                    .buttonStyle(.plain)

                    // Group 1: Membership & Cloud
                    VStack(spacing: 0) {
                        NavigationLink(destination: SubscriptionSettingsView()) {
                            groupedRow(
                                icon: "crown",
                                title: "Plans",
                                badge: coordinator.isProUser ? "Pro" : "Free"
                            )
                        }
                        .buttonStyle(.plain)

                        rowDivider

                        NavigationLink(destination: SyncSettingsView()) {
                            groupedRow(
                                icon: "bolt.horizontal.icloud",
                                title: "Sync",
                                badge: coordinator.isAuthenticated ? coordinator.syncState.rawValue : "Local"
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .liquidGlassCard(cornerRadius: 18)

                    // Group 2: Preferences & System
                    VStack(spacing: 0) {
                        NavigationLink(destination: NotificationsSettingsView()) {
                            groupedRow(
                                icon: "bell",
                                title: "Notifications",
                                badge: notificationStatusTitle
                            )
                        }
                        .buttonStyle(.plain)

                        rowDivider

                        NavigationLink(destination: SecuritySettingsView()) {
                            groupedRow(
                                icon: "lock.shield",
                                title: "Security",
                                badge: lockManager.isAppLockEnabled ? "On" : "Off"
                            )
                        }
                        .buttonStyle(.plain)

                        rowDivider

                        NavigationLink(destination: AppIconSelectionView()) {
                            groupedRow(
                                icon: "paintpalette",
                                title: "Appearance",
                                badge: "\(AppIconManager.availableIcons.count) Icons"
                            )
                        }
                        .buttonStyle(.plain)

                        rowDivider

                        NavigationLink(destination: ShortcutsSettingsView()) {
                            groupedRow(
                                icon: "plus.square.fill.on.square.fill",
                                title: "Quick Save",
                                badge: "Active"
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .liquidGlassCard(cornerRadius: 18)

                    // Group 3: Data & Intelligence
                    VStack(spacing: 0) {
                        NavigationLink(destination: StorageManagementView()) {
                            groupedRow(
                                icon: "internaldrive",
                                title: "Storage",
                                badge: storageManager.breakdown.formattedTotal
                            )
                        }
                        .buttonStyle(.plain)

                        rowDivider

                        NavigationLink(destination: AIModelSettingsView()) {
                            groupedRow(
                                icon: "sparkles",
                                title: "AI Assistant",
                                badge: coordinator.isProUser ? "Configured" : "Pro"
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .liquidGlassCard(cornerRadius: 18)

                    // Group 4: Support & Updates
                    VStack(spacing: 0) {
                        NavigationLink(destination: ServiceStatusView()) {
                            groupedRow(icon: "waveform.path.ecg", title: "Service Status", badge: nil)
                        }
                        .buttonStyle(.plain)

                        rowDivider

                        NavigationLink(destination: CheckForUpdatesView()) {
                            groupedRow(
                                icon: "arrow.triangle.2.circlepath",
                                title: "Updates",
                                badge: AppVersion.currentVersion
                            )
                        }
                        .buttonStyle(.plain)

                        rowDivider

                        NavigationLink(destination: SupportRequestView()) {
                            groupedRow(
                                icon: "questionmark.circle",
                                title: "Help",
                                badge: nil
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .liquidGlassCard(cornerRadius: 18)

                    // Bottom Session Action Button (matching reference)
                    if coordinator.isAuthenticated {
                        Button(action: {
                            LBHaptic.medium()
                            showingSignOutAlert = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 15, weight: .semibold))
                                Text("Log Out")
                                    .font(.system(size: 15, weight: .bold))
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(AppTheme.cardBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    } else {
                        VStack(spacing: 10) {
                            Button(action: {
                                LBHaptic.light()
                                showingAuthSheet = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "person.crop.circle.badge.plus")
                                        .font(.system(size: 15, weight: .semibold))
                                    Text("Sign In to LaterBox")
                                        .font(.system(size: 15, weight: .bold))
                                }
                                .foregroundColor(AppTheme.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(AppTheme.cardBackground)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)

                            Button(action: {
                                LBHaptic.medium()
                                showingExitGuestAlert = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.system(size: 15, weight: .semibold))
                                    Text("Exit Guest Mode")
                                        .font(.system(size: 15, weight: .bold))
                                }
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(AppTheme.cardBackground)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 4)
                    }

                    // App Version Footer
                    VStack(spacing: 3) {
                        Text("LaterBox for iOS • Liquid Glass Edition")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(AppVersion.displayString)
                            .font(.caption2.monospaced())
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 6)
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        }
        .navigationBarHidden(true)
        .onAppear {
            iconManager.refreshCurrentIcon()
            storageManager.refreshBreakdown()
        }
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
        .alert("Exit Guest Mode", isPresented: $showingExitGuestAlert) {
            Button("Exit & Clear Data", role: .destructive) {
                coordinator.exitGuest(context: modelContext)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Exiting guest mode will clear all items saved on this device during this guest session.")
        }
        .task {
            await refreshNotificationStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task {
                await refreshNotificationStatus()
            }
        }
    }

    // MARK: - Subcomponents

    private var rowDivider: some View {
        Divider()
            .background(AppTheme.cardBorder.opacity(0.7))
            .padding(.leading, 48)
    }

    private func groupedRow(
        icon: String,
        title: String,
        badge: String?
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(AppTheme.textPrimary)
                .frame(width: 24, alignment: .center)

            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)

            Spacer()

            if let badge {
                Text(badge)
                    .font(.caption.weight(.medium))
                    .foregroundColor(AppTheme.textSecondary)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppTheme.textSecondary.opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    private var notificationStatusTitle: String {
        switch notificationStatus {
        case .authorized:
            return "Active"
        case .provisional:
            return "Provisional"
        case .denied:
            return "Off"
        case .notDetermined:
            return "Off"
        default:
            return "Off"
        }
    }

    private func refreshNotificationStatus() async {
        let status = await ReturnNotification.currentAuthorizationStatus()
        await MainActor.run {
            self.notificationStatus = status
        }
    }
}
