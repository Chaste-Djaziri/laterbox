//
//  NotificationsSettingsView.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 11.10.26.
//

import SwiftUI
import UserNotifications

public struct NotificationsSettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var isSendingTestNotification = false
    @State private var testNotificationScheduled = false
    @State private var testNotificationErrorMessage: String? = nil
    @State private var showingTestNotificationAlert = false

    public init() {}

    public var body: some View {
        ZStack {
            InboxGrainBackground().ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header Status Card
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(statusCircleFill)
                                .frame(width: 72, height: 72)
                            Image(systemName: notificationStatusIcon)
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(notificationStatusColor)
                        }

                        VStack(spacing: 4) {
                            Text(notificationStatusTitle)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(SettingsAppearance.textPrimary(for: colorScheme))

                            Text(notificationStatusSubtitle)
                                .font(.subheadline)
                                .foregroundColor(SettingsAppearance.textSecondary(for: colorScheme))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 26)
                    .padding(.horizontal, 18)
                    .settingsCard(for: colorScheme, cornerRadius: 22)

                    // Permission & Control Card
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Notification Permissions")
                            .font(.headline)
                            .foregroundStyle(SettingsAppearance.textPrimary(for: colorScheme))

                        VStack(spacing: 12) {
                            HStack {
                                HStack(spacing: 8) {
                                    Image(systemName: notificationStatusIcon)
                                        .foregroundColor(notificationStatusColor)
                                    Text("System Authorization")
                                        .font(.subheadline)
                                        .foregroundColor(SettingsAppearance.textPrimary(for: colorScheme))
                                }
                                Spacer()
                                Text(notificationStatusTitle)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(notificationStatusColor)
                            }

                            Divider().background(SettingsAppearance.border(for: colorScheme))

                            if notificationStatus == .authorized || notificationStatus == .provisional {
                                HStack {
                                    Text("Reminders & Resurfacing")
                                        .font(.subheadline)
                                        .foregroundColor(SettingsAppearance.textSecondary(for: colorScheme))
                                    Spacer()
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(SettingsAppearance.textPrimary(for: colorScheme))
                                        Text("Enabled")
                                            .font(.caption2.weight(.bold))
                                            .foregroundColor(SettingsAppearance.onAccent)
                                    }
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(AppTheme.accent))
                                }

                                Divider().background(SettingsAppearance.border(for: colorScheme))

                                // Send Test Notification
                                Button(action: {
                                    triggerTestNotification()
                                }) {
                                    HStack(spacing: 8) {
                                        if isSendingTestNotification {
                                            ProgressView()
                                                .tint(SettingsAppearance.textPrimary(for: colorScheme))
                                        } else {
                                            Image(systemName: testNotificationScheduled ? "checkmark" : "paperplane.fill")
                                        }
                                        Text(testNotificationScheduled ? "Scheduled! (Arriving in 2s)" : "Send Test Notification")
                                            .font(.subheadline.weight(.semibold))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(testNotificationScheduled ? AppTheme.accent : AppTheme.accent.opacity(0.35))
                                    .foregroundColor(SettingsAppearance.onAccent)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                                .disabled(isSendingTestNotification)

                                // Open in iOS Settings
                                Button(action: {
                                    LBHaptic.light()
                                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(settingsUrl)
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Text("Configure Sounds & Badges in iOS Settings")
                                        Image(systemName: "arrow.up.right")
                                    }
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(SettingsAppearance.textSecondary(for: colorScheme))
                                }
                                .buttonStyle(.plain)
                                .padding(.top, 2)

                            } else if notificationStatus == .denied {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Notifications are currently disabled in iOS Settings. Allow notifications to receive timely return reminders for your saved items.")
                                        .font(.caption)
                                        .foregroundColor(SettingsAppearance.textSecondary(for: colorScheme))
                                        .lineSpacing(2)

                                    Button(action: {
                                        LBHaptic.medium()
                                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                            UIApplication.shared.open(settingsUrl)
                                        }
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "gearshape.fill")
                                            Text("Open iOS Settings to Allow")
                                                .font(.subheadline.weight(.semibold))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.red.opacity(0.12))
                                        .foregroundColor(.red)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                    .buttonStyle(.plain)
                                }
                            } else {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Enable notifications to receive alerts when your snoozed inbox items and reminders return.")
                                        .font(.caption)
                                        .foregroundColor(SettingsAppearance.textSecondary(for: colorScheme))
                                        .lineSpacing(2)

                                    Button(action: {
                                        requestNotificationPermission()
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "bell.badge.fill")
                                            Text("Allow Notifications")
                                                .font(.subheadline.weight(.semibold))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(AppTheme.accent)
                                        .foregroundColor(SettingsAppearance.textPrimary(for: colorScheme))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                    .buttonStyle(.plain)

                                    Button(action: {
                                        triggerTestNotification()
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "paperplane")
                                            Text("Send Test Notification")
                                                .font(.subheadline.weight(.semibold))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.black.opacity(0.05))
                                        .foregroundColor(SettingsAppearance.textSecondary(for: colorScheme))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(SettingsAppearance.surface(for: colorScheme))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(SettingsAppearance.border(for: colorScheme), lineWidth: 1)
                        )
                    }

                    // Quiet Resurfacing Information
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Quiet Utility Design")
                            .font(.headline)
                            .foregroundStyle(SettingsAppearance.textPrimary(for: colorScheme))

                        VStack(alignment: .leading, spacing: 8) {
                            Text("LaterBox is built as a quiet utility. You will only receive a notification when an item you explicitly scheduled is ready to return to your inbox.")
                                .font(.subheadline)
                                .foregroundColor(SettingsAppearance.textSecondary(for: colorScheme))
                                .lineSpacing(2)

                            Text("• No promotional notifications or engagement nudges.")
                                .font(.caption)
                                .foregroundColor(SettingsAppearance.textSecondary(for: colorScheme))
                            Text("• Tapping a notification opens the item directly.")
                                .font(.caption)
                                .foregroundColor(SettingsAppearance.textSecondary(for: colorScheme))
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(SettingsAppearance.surface(for: colorScheme))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(SettingsAppearance.border(for: colorScheme), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Notifications & Alerts")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Notifications", isPresented: $showingTestNotificationAlert) {
            if notificationStatus == .denied {
                Button("Open Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } else {
                Button("OK", role: .cancel) {}
            }
        } message: {
            Text(testNotificationErrorMessage ?? "Unable to schedule notification.")
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

    private var statusCircleFill: Color {
        switch notificationStatus {
        case .authorized, .provisional:
            return AppTheme.accent
        case .denied:
            return Color.red.opacity(0.12)
        default:
            return Color.black.opacity(0.04)
        }
    }

    private var notificationStatusTitle: String {
        switch notificationStatus {
        case .authorized:
            return "Active"
        case .provisional:
            return "Provisional"
        case .denied:
            return "Disabled"
        case .notDetermined:
            return "Not Allowed"
        case .ephemeral:
            return "App Clip"
        @unknown default:
            return "Unknown"
        }
    }

    private var notificationStatusSubtitle: String {
        switch notificationStatus {
        case .authorized, .provisional:
            return "Alerts deliver when scheduled items return"
        case .denied:
            return "Notifications disabled in iOS Settings"
        case .notDetermined:
            return "Permission not requested yet"
        default:
            return "Status: \(notificationStatusTitle)"
        }
    }

    private var notificationStatusColor: Color {
        switch notificationStatus {
        case .authorized, .provisional:
            return Color.green
        case .denied:
            return Color.red
        default:
            return SettingsAppearance.textSecondary(for: colorScheme)
        }
    }

    private var notificationStatusIcon: String {
        switch notificationStatus {
        case .authorized, .provisional:
            return "bell.badge.fill"
        case .denied:
            return "bell.slash.fill"
        default:
            return "bell.fill"
        }
    }

    private func refreshNotificationStatus() async {
        let status = await ReturnNotification.currentAuthorizationStatus()
        await MainActor.run {
            self.notificationStatus = status
        }
    }

    private func requestNotificationPermission() {
        LBHaptic.medium()
        Task {
            do {
                _ = try await ReturnNotification.requestPermissions()
                await refreshNotificationStatus()
            } catch {
                await MainActor.run {
                    testNotificationErrorMessage = error.localizedDescription
                    showingTestNotificationAlert = true
                }
            }
        }
    }

    private func triggerTestNotification() {
        LBHaptic.medium()
        isSendingTestNotification = true
        testNotificationScheduled = false

        Task {
            do {
                let success = try await ReturnNotification.sendTestNotification(delaySeconds: 2.0)
                await refreshNotificationStatus()
                await MainActor.run {
                    isSendingTestNotification = false
                    if success {
                        testNotificationScheduled = true
                        LBHaptic.success()
                        Task {
                            try? await Task.sleep(nanoseconds: 3_000_000_000)
                            await MainActor.run {
                                testNotificationScheduled = false
                            }
                        }
                    } else {
                        testNotificationErrorMessage = "Notifications are disabled. Please allow them in iOS Settings."
                        showingTestNotificationAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    isSendingTestNotification = false
                    testNotificationErrorMessage = error.localizedDescription
                    showingTestNotificationAlert = true
                }
            }
        }
    }
}
