//
//  SettingsView.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 04.10.26.
//

import SwiftUI
import SwiftData
import UserNotifications

public struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allItems: [LBItem]
    @ObservedObject var coordinator = SyncCoordinator.shared
    @ObservedObject private var lockManager = AppLockManager.shared
    @ObservedObject private var modelManager = LaterAIModelManager.shared

    @State private var showingAuthSheet = false
    @State private var showingSignOutAlert = false
    @State private var showingSyncCompleteAlert = false
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var isSendingTestNotification = false
    @State private var testNotificationScheduled = false
    @State private var testNotificationErrorMessage: String? = nil
    @State private var showingTestNotificationAlert = false

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

                                Button(action: {
                                    LBHaptic.light()
                                    coordinator.showingPlansSheet = true
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "list.bullet.rectangle")
                                            .font(.caption.weight(.semibold))
                                        Text("View Plans & Subscriptions")
                                            .font(.caption.weight(.semibold))
                                    }
                                    .foregroundColor(AppTheme.textPrimary)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(Color.black.opacity(0.05))
                                    )
                                }
                                .buttonStyle(.plain)
                                .padding(.top, 2)
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
                                        coordinator.showingPlansSheet = true
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
                                        coordinator.showingPlansSheet = true
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

                        // Later AI & Intelligence Card
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Later AI & Intelligence")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)

                            VStack(spacing: 12) {
                                // Active Model Row
                                HStack {
                                    HStack(spacing: 8) {
                                        Image(systemName: modelManager.selectedProvider.iconName)
                                            .foregroundColor(AppTheme.textPrimary)
                                        Text("Active Engine")
                                            .font(.subheadline)
                                            .foregroundColor(AppTheme.textPrimary)
                                    }
                                    Spacer()
                                    Text(modelManager.selectedProvider.displayName)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(AppTheme.textPrimary)
                                }

                                Divider().background(AppTheme.cardBorder)

                                // Model Identifier
                                HStack {
                                    Text("Selected Model")
                                        .font(.subheadline)
                                        .foregroundColor(AppTheme.textSecondary)
                                    Spacer()
                                    Text(modelManager.activeModelName)
                                        .font(.caption.monospaced())
                                        .foregroundColor(AppTheme.textPrimary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(AppTheme.accent)
                                        .clipShape(Capsule())
                                }

                                Divider().background(AppTheme.cardBorder)

                                // Search Refinement Status
                                HStack {
                                    Text("Search Refinement")
                                        .font(.subheadline)
                                        .foregroundColor(AppTheme.textSecondary)
                                    Spacer()
                                    Text(modelManager.enableSearchRefine ? "Enabled" : "Disabled")
                                        .font(.caption.weight(.medium))
                                        .foregroundColor(modelManager.enableSearchRefine ? Color.green : AppTheme.textSecondary)
                                }

                                Divider().background(AppTheme.cardBorder)

                                // Configure Models NavigationLink
                                NavigationLink(destination: AIModelSettingsView()) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "slider.horizontal.3")
                                        Text("Configure AI Models & Keys")
                                            .font(.subheadline.weight(.semibold))
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption.weight(.bold))
                                            .foregroundColor(AppTheme.textSecondary)
                                    }
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 12)
                                    .background(Color.black.opacity(0.04))
                                    .foregroundColor(AppTheme.textPrimary)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
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

                        // Notifications & Alerts Card
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Notifications & Alerts")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)

                            VStack(spacing: 12) {
                                // Notification Status Row
                                HStack {
                                    HStack(spacing: 8) {
                                        Image(systemName: notificationStatusIcon)
                                            .foregroundColor(notificationStatusColor)
                                        Text("Notification Status")
                                            .font(.subheadline)
                                            .foregroundColor(AppTheme.textPrimary)
                                    }
                                    Spacer()
                                    Text(notificationStatusTitle)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(notificationStatusColor)
                                }

                                Divider().background(AppTheme.cardBorder)

                                if notificationStatus == .authorized || notificationStatus == .provisional {
                                    HStack {
                                        Text("Reminders & Snooze")
                                            .font(.subheadline)
                                            .foregroundColor(AppTheme.textSecondary)
                                        Spacer()
                                        HStack(spacing: 4) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.caption)
                                                .foregroundColor(AppTheme.textPrimary)
                                            Text("Enabled")
                                                .font(.caption2.weight(.bold))
                                                .foregroundColor(AppTheme.textPrimary)
                                        }
                                        .padding(.horizontal, 9)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(AppTheme.accent)
                                        )
                                    }

                                    Divider().background(AppTheme.cardBorder)

                                    // Send Test Notification Button
                                    Button(action: {
                                        triggerTestNotification()
                                    }) {
                                        HStack(spacing: 8) {
                                            if isSendingTestNotification {
                                                ProgressView()
                                                    .tint(AppTheme.textPrimary)
                                            } else {
                                                Image(systemName: testNotificationScheduled ? "checkmark" : "paperplane.fill")
                                            }
                                            Text(testNotificationScheduled ? "Test Scheduled! (Arriving in 2s)" : "Send Test Notification")
                                                .font(.subheadline.weight(.semibold))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(testNotificationScheduled ? AppTheme.accent : AppTheme.accent.opacity(0.3))
                                        .foregroundColor(AppTheme.textPrimary)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(isSendingTestNotification)

                                    // Secondary link to manage in iOS Settings
                                    Button(action: {
                                        LBHaptic.light()
                                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                            UIApplication.shared.open(settingsUrl)
                                        }
                                    }) {
                                        HStack(spacing: 4) {
                                            Text("Configure in iOS Settings")
                                            Image(systemName: "arrow.up.right")
                                        }
                                        .font(.caption2.weight(.medium))
                                        .foregroundColor(AppTheme.textSecondary)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.top, 2)

                                } else if notificationStatus == .denied {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("Notifications are currently disabled in iOS Settings. Allow notifications to receive timely return reminders for your saved items.")
                                            .font(.caption)
                                            .foregroundColor(AppTheme.textSecondary)
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
                                            .padding(.vertical, 10)
                                            .background(Color.red.opacity(0.12))
                                            .foregroundColor(.red)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                } else {
                                    // Not determined
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("Enable notifications to receive alerts when your snoozed inbox items and reminders return.")
                                            .font(.caption)
                                            .foregroundColor(AppTheme.textSecondary)
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
                                            .padding(.vertical, 10)
                                            .background(AppTheme.accent)
                                            .foregroundColor(AppTheme.textPrimary)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
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
                                            .padding(.vertical, 10)
                                            .background(Color.black.opacity(0.05))
                                            .foregroundColor(AppTheme.textSecondary)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                        }
                                        .buttonStyle(.plain)
                                    }
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

                        // Security & Privacy (App Lock)
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Security & Privacy")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)

                            VStack(spacing: 14) {
                                // Biometric Toggle Row
                                HStack(alignment: .center) {
                                    HStack(spacing: 10) {
                                        ZStack {
                                            Circle()
                                                .fill(AppTheme.accent)
                                                .frame(width: 36, height: 36)
                                            Image(systemName: lockManager.biometryIconName)
                                                .font(.system(size: 17, weight: .semibold))
                                                .foregroundColor(AppTheme.textPrimary)
                                        }

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("App Lock (\(lockManager.biometryName))")
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundColor(AppTheme.textPrimary)
                                            Text(lockManager.isAppLockEnabled ? "Requires \(lockManager.biometryName) to unlock" : "Disabled")
                                                .font(.caption2)
                                                .foregroundColor(AppTheme.textSecondary)
                                        }
                                    }

                                    Spacer()

                                    Toggle("", isOn: Binding(
                                        get: { lockManager.isAppLockEnabled },
                                        set: { _ in
                                            Task {
                                                await lockManager.toggleAppLock()
                                            }
                                        }
                                    ))
                                    .labelsHidden()
                                    .tint(Color.black)
                                }

                                if let error = lockManager.authenticationError {
                                    Text(error)
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }

                                if lockManager.isAppLockEnabled {
                                    Divider().background(AppTheme.cardBorder)

                                    // Immediate Lock Button
                                    Button(action: {
                                        LBHaptic.medium()
                                        lockManager.lockAppIfNeeded()
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "lock.fill")
                                                .font(.caption)
                                            Text("Lock LaterBox Now")
                                                .font(.subheadline.weight(.semibold))
                                        }
                                        .foregroundColor(AppTheme.textPrimary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 9)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(Color.black.opacity(0.05))
                                        )
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
                .trackPullDownForLaterAI()
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

    private var notificationStatusColor: Color {
        switch notificationStatus {
        case .authorized, .provisional:
            return Color.green
        case .denied:
            return Color.red
        case .notDetermined:
            return AppTheme.textSecondary
        default:
            return AppTheme.textSecondary
        }
    }

    private var notificationStatusIcon: String {
        switch notificationStatus {
        case .authorized, .provisional:
            return "bell.badge.fill"
        case .denied:
            return "bell.slash.fill"
        case .notDetermined:
            return "bell.fill"
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
