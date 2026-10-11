//
//  SettingsView.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 04.10.26.
//

import SwiftUI
import UserNotifications

public struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var coordinator = SyncCoordinator.shared
    @ObservedObject private var lockManager = AppLockManager.shared
    @ObservedObject private var iconManager = AppIconManager.shared
    @StateObject private var storageManager = LocalStorageManager.shared
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

    public init() {}

    public var body: some View {
        ZStack {
            AppTheme.canvasBackground
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    // Top Navigation Header
                    HStack(alignment: .center, spacing: 12) {
                        Button {
                            dismiss()
                            LBHaptic.light()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                                .frame(width: 36, height: 36)
                                .background(Color.black.opacity(0.04), in: Circle())
                                .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Back to Inbox")

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

                        // Sync Status Indicator Pill
                        Button(action: {
                            if !coordinator.isProUser {
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
                    .padding(.top, 4)

                    // Profile & Account Summary Card (Navigation Link)
                    NavigationLink(destination: AccountSettingsView()) {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.accent)
                                    .frame(width: 52, height: 52)
                                Image(systemName: "person.fill")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(AppTheme.textPrimary)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                if let email = coordinator.currentUserEmail {
                                    Text(email)
                                        .font(.headline.weight(.bold))
                                        .foregroundColor(AppTheme.textPrimary)
                                        .lineLimit(1)

                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.caption2)
                                            .foregroundColor(AppTheme.textPrimary)
                                        Text(coordinator.isProUser ? "LaterBox Pro Active" : "Free Cloud Account")
                                            .font(.caption.weight(.medium))
                                            .foregroundColor(AppTheme.textSecondary)
                                    }
                                } else {
                                    Text("Guest Mode")
                                        .font(.headline.weight(.bold))
                                        .foregroundColor(AppTheme.textPrimary)

                                    Text("Tap to sign in & enable sync")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                                .foregroundColor(AppTheme.textSecondary.opacity(0.7))
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .liquidGlassCard(cornerRadius: 18)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())

                    // Section 1: Membership & Cloud
                    VStack(alignment: .leading, spacing: 10) {
                        sectionHeader("Membership & Cloud")

                        VStack(spacing: 10) {
                            NavigationLink(destination: SubscriptionSettingsView()) {
                                settingsRow(
                                    icon: "crown.fill",
                                    iconColor: Color(hex: "EAB308"),
                                    iconBg: Color(hex: "FEF9C3"),
                                    title: "Subscription & Plans",
                                    subtitle: "Pro features, trial & membership",
                                    badge: coordinator.isProUser ? "PRO" : "Free"
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink(destination: SyncSettingsView()) {
                                settingsRow(
                                    icon: "bolt.horizontal.icloud.fill",
                                    iconColor: Color(hex: "0284C7"),
                                    iconBg: Color(hex: "E0F2FE"),
                                    title: "Cloud Sync & Diagnostics",
                                    subtitle: "Multi-device sync & server status",
                                    badge: coordinator.isAuthenticated ? coordinator.syncState.rawValue : "Local"
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Section 2: Preferences & System
                    VStack(alignment: .leading, spacing: 10) {
                        sectionHeader("Preferences & System")

                        VStack(spacing: 10) {
                            NavigationLink(destination: NotificationsSettingsView()) {
                                settingsRow(
                                    icon: "bell.badge.fill",
                                    iconColor: Color(hex: "EA580C"),
                                    iconBg: Color(hex: "FFEDD5"),
                                    title: "Notifications & Alerts",
                                    subtitle: "Return reminders & permissions",
                                    badge: notificationStatusTitle
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink(destination: SecuritySettingsView()) {
                                settingsRow(
                                    icon: lockManager.biometryIconName,
                                    iconColor: Color(hex: "16A34A"),
                                    iconBg: Color(hex: "DCFCE7"),
                                    title: "Security & Privacy",
                                    subtitle: "\(lockManager.biometryName) & app protection",
                                    badge: lockManager.isAppLockEnabled ? "On" : "Off"
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink(destination: AppIconSelectionView()) {
                                settingsRow(
                                    icon: "paintpalette.fill",
                                    iconColor: Color(hex: "9333EA"),
                                    iconBg: Color(hex: "F3E8FF"),
                                    title: "App Icon & Appearance",
                                    subtitle: "Customize home screen icon",
                                    badge: "\(AppIconManager.availableIcons.count) Icons"
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Section 3: Data & Intelligence
                    VStack(alignment: .leading, spacing: 10) {
                        sectionHeader("Data & Intelligence")

                        VStack(spacing: 10) {
                            NavigationLink(destination: StorageManagementView()) {
                                settingsRow(
                                    icon: "internaldrive.fill",
                                    iconColor: Color(hex: "0D9488"),
                                    iconBg: Color(hex: "CCFBF1"),
                                    title: "Local Storage & Vault",
                                    subtitle: "Disk usage, cleanup & duplicates",
                                    badge: storageManager.breakdown.formattedTotal
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink(destination: AIModelSettingsView()) {
                                settingsRow(
                                    icon: "sparkles",
                                    iconColor: Color(hex: "6366F1"),
                                    iconBg: Color(hex: "EEF2FF"),
                                    title: "Later AI Models",
                                    subtitle: "Intelligence & provider keys",
                                    badge: coordinator.isProUser ? "Configured" : "Pro"
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Section 4: Support & Feedback
                    VStack(alignment: .leading, spacing: 10) {
                        sectionHeader("Support & Feedback")

                        NavigationLink(destination: SupportRequestView()) {
                            settingsRow(
                                icon: "questionmark.bubble.fill",
                                iconColor: Color(hex: "2563EB"),
                                iconBg: Color(hex: "DBEAFE"),
                                title: "Help & Report a Problem",
                                subtitle: "Contact support, questions & feedback",
                                badge: nil
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // App Version Footer
                    VStack(spacing: 4) {
                        Text("LaterBox for iOS • Liquid Glass Edition")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(AppVersion.displayString)
                            .font(.caption2.monospaced())
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.bold))
            .foregroundColor(.secondary)
            .textCase(.uppercase)
            .padding(.leading, 4)
    }

    private func settingsRow(
        icon: String,
        iconColor: Color,
        iconBg: Color,
        title: String,
        subtitle: String,
        badge: String?
    ) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(iconBg)
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppTheme.textPrimary)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            if let badge {
                Text(badge)
                    .font(.caption2.weight(.bold))
                    .foregroundColor(AppTheme.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(Color.black.opacity(0.05))
                    )
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundColor(AppTheme.textSecondary.opacity(0.6))
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .liquidGlassCard(cornerRadius: 16)
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
