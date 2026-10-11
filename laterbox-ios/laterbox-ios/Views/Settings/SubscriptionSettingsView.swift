//
//  SubscriptionSettingsView.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 11.10.26.
//

import SwiftUI
import StoreKit

public struct SubscriptionSettingsView: View {
    @Environment(\.openURL) private var openURL
    @ObservedObject private var coordinator = SyncCoordinator.shared
    @ObservedObject private var storeKit = StoreKitManager.shared

    public init() {}

    public var body: some View {
        ZStack {
            LiquidGlassBackground()

            ScrollView {
                VStack(spacing: 20) {
                    // Header Plan Status Card
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.accent)
                                .frame(width: 76, height: 76)
                            Image(systemName: "crown.fill")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                        }

                        VStack(spacing: 4) {
                            Text(coordinator.isProUser ? "LaterBox Pro" : "LaterBox Local")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)

                            Text(coordinator.isProUser ? "All features and multi-device cloud sync unlocked" : "Free offline vault • Cloud synchronization available")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)

                    // Plan Overview Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Current Membership")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)

                            Spacer()

                            Text(coordinator.isProUser ? "Active" : "Free Forever")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(AppTheme.textPrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(AppTheme.accent))
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            if coordinator.isProUser {
                                Text("Your active Pro subscription gives you seamless access to LaterBox on iOS, macOS, Chrome, Safari, and the web.")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textSecondary)
                                    .lineSpacing(2)
                            } else {
                                Text("Local mode is 100% free forever. Your items are saved offline on this device with full privacy and zero tracking.")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textSecondary)
                                    .lineSpacing(2)
                            }

                            Divider().background(AppTheme.cardBorder)

                            VStack(alignment: .leading, spacing: 8) {
                                featureRow(icon: "icloud.fill", title: "Multi-Device Cloud Sync", unlocked: coordinator.isProUser)
                                featureRow(icon: "wand.and.stars", title: "AI Inbox Suggestions & Tagging", unlocked: coordinator.isProUser)
                                featureRow(icon: "safari.fill", title: "Desktop Web & Browser Extensions", unlocked: coordinator.isProUser)
                                featureRow(icon: "lock.icloud.fill", title: "Encrypted Cloud Backup & Restore", unlocked: coordinator.isProUser)
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

                    // Subscription Management Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Plan Actions")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        if coordinator.isProUser {
                            Button(action: {
                                LBHaptic.light()
                                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                    openURL(url)
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "applelogo")
                                    Text("Manage Apple Subscriptions")
                                        .font(.subheadline.weight(.semibold))
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption.weight(.bold))
                                }
                                .foregroundColor(AppTheme.textPrimary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(AppTheme.cardBackground)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        } else {
                            VStack(spacing: 12) {
                                Button(action: {
                                    LBHaptic.medium()
                                    coordinator.showingPlansSheet = true
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "sparkles")
                                            .font(.subheadline.weight(.semibold))
                                        Text("Upgrade to LaterBox Pro")
                                            .font(.headline.weight(.bold))
                                        Image(systemName: "arrow.right")
                                            .font(.subheadline.weight(.semibold))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(AppTheme.darkSurface)
                                    )
                                }
                                .buttonStyle(.plain)

                                Text("$3.99 / month or $39.99 / year • 14-day free trial included")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }

                        // Restore Purchases Button
                        Button(action: {
                            LBHaptic.light()
                            Task {
                                await storeKit.restorePurchases()
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.caption)
                                Text("Restore Previous Purchases")
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundColor(AppTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }

                    // Legal Links
                    HStack(spacing: 16) {
                        Button("Terms of Use (EULA)") {
                            if let url = URL(string: StoreKitManager.termsOfServiceUrl) {
                                openURL(url)
                            }
                        }
                        .font(.caption.weight(.medium))
                        .foregroundColor(AppTheme.textSecondary)

                        Text("•")
                            .foregroundColor(AppTheme.textSecondary.opacity(0.5))

                        Button("Privacy Policy") {
                            if let url = URL(string: StoreKitManager.privacyPolicyUrl) {
                                openURL(url)
                            }
                        }
                        .font(.caption.weight(.medium))
                        .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Subscription & Plans")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func featureRow(icon: String, title: String, unlocked: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(unlocked ? AppTheme.textPrimary : AppTheme.textSecondary)
                .frame(width: 20)
            Text(title)
                .font(.subheadline)
                .foregroundColor(AppTheme.textPrimary)
            Spacer()
            Image(systemName: unlocked ? "checkmark.circle.fill" : "lock.fill")
                .font(.caption)
                .foregroundColor(unlocked ? Color.green : AppTheme.textSecondary.opacity(0.6))
        }
    }
}
