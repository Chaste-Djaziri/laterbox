//
//  SubscriptionSettingsView.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 11.10.26.
//

import SwiftUI
import StoreKit

public struct SubscriptionSettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL
    @ObservedObject private var coordinator = SyncCoordinator.shared
    @ObservedObject private var storeKit = StoreKitManager.shared

    public init() {}

    public var body: some View {
        ZStack {
            InboxGrainBackground().ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header Plan Status Card
                    VStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 23, style: .continuous)
                                .fill(AppTheme.accent)
                                .frame(width: 76, height: 76)
                            Image(systemName: "crown.fill")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(SettingsAppearance.textPrimary(for: colorScheme))
                        }

                        VStack(spacing: 4) {
                            Text(coordinator.isProUser ? "LaterBox Pro" : "LaterBox Local")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(SettingsAppearance.textPrimary(for: colorScheme))

                            Text(coordinator.isProUser ? coordinator.hasCloudPro ? "Device Pro and account cloud access active" : "Device Pro active • Account connection optional" : "Free offline vault • Cloud synchronization available")
                                .font(.subheadline)
                                .foregroundColor(SettingsAppearance.textSecondary(for: colorScheme))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 26)
                    .padding(.horizontal, 18)
                    .settingsCard(for: colorScheme, cornerRadius: 22)

                    // Plan Overview Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Current membership")
                                .font(.headline)
                                .foregroundStyle(SettingsAppearance.textPrimary(for: colorScheme))

                            Spacer()

                            Text(coordinator.isProUser ? "Active" : "Free Forever")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(SettingsAppearance.onAccent)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(AppTheme.accent))
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            if coordinator.isProUser {
                                Text(coordinator.hasCloudPro ? "Your connected account has Pro access on iOS and the web." : "Pro works on this device without registration. Connect an account only if you want cloud sync, backup, and web access.")
                                    .font(.subheadline)
                                    .foregroundColor(SettingsAppearance.textSecondary(for: colorScheme))
                                    .lineSpacing(2)
                            } else {
                                Text("Local mode is 100% free forever. Your items are saved offline on this device with full privacy and zero tracking.")
                                    .font(.subheadline)
                                    .foregroundColor(SettingsAppearance.textSecondary(for: colorScheme))
                                    .lineSpacing(2)
                            }

                            Divider().background(SettingsAppearance.border(for: colorScheme))

                            VStack(alignment: .leading, spacing: 8) {
                                featureRow(icon: "icloud.fill", title: "Multi-Device Cloud Sync", unlocked: coordinator.hasCloudPro)
                                featureRow(icon: "wand.and.stars", title: "Pro AI Provider Options", unlocked: coordinator.isProUser)
                                featureRow(icon: "safari.fill", title: "Web Pro Access", unlocked: coordinator.hasCloudPro)
                                featureRow(icon: "lock.icloud.fill", title: "Cloud Backup & Restore", unlocked: coordinator.hasCloudPro)
                            }
                        }
                    }
                    .padding(18)
                    .settingsCard(for: colorScheme, cornerRadius: 20)

                    ConnectProView()
                    // Subscription Management Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Manage subscription")
                            .font(.headline)
                            .foregroundStyle(SettingsAppearance.textPrimary(for: colorScheme))

                        if coordinator.billingEntitlement?.provider != nil || storeKit.isProSubscriptionActive {
                            Button(action: {
                                LBHaptic.light()
                                Task { await storeKit.manageSubscription() }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: ["paddle", "whop"].contains(storeKit.managementProvider ?? "") ? "creditcard" : "applelogo")
                                    Text(storeKit.managementProvider == "paddle" ? "Manage Paddle Subscription" : storeKit.managementProvider == "whop" ? "Manage Whop Subscription" : "Manage Apple Subscription")
                                        .font(.subheadline.weight(.semibold))
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption.weight(.bold))
                                }
                                .foregroundColor(SettingsAppearance.textPrimary(for: colorScheme))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(SettingsAppearance.surface(for: colorScheme))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .strokeBorder(SettingsAppearance.border(for: colorScheme), lineWidth: 1)
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

                                Text("\(storeKit.monthlyDisplayPrice) / month or \(storeKit.annualDisplayPrice) / year")
                                    .font(.caption)
                                    .foregroundColor(SettingsAppearance.textSecondary(for: colorScheme))
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }

                        if storeKit.isProSubscriptionActive && coordinator.billingEntitlement?.provider == "paddle" {
                            Button("Manage account’s Paddle subscription") { Task { await storeKit.manageSubscription(provider: "paddle") } }
                                .font(.caption)
                        }
                        if let entitlement = coordinator.billingEntitlement, entitlement.provider != nil {
                            Text("Managed by \(entitlement.provider == "apple" ? "Apple" : entitlement.provider == "whop" ? "Whop" : "Paddle"). To switch payment providers, cancel renewal there and subscribe with the other provider after access ends.")
                                .font(.caption)
                                .foregroundColor(SettingsAppearance.textSecondary(for: colorScheme))
                            if let end = entitlement.accessEndDate {
                                Text("\(entitlement.willCancel ? "Access ends" : entitlement.status == "trialing" ? "Trial ends" : entitlement.status == "past_due" ? "Grace period ends" : "Renews") \(end.formatted(date: .long, time: .omitted))")
                                    .font(.caption)
                            }
                        }
                        if storeKit.registrationAccountId == coordinator.currentUserId,
                           let message = storeKit.cloudRegistrationMessage {
                            Text(message).font(.caption).foregroundColor(SettingsAppearance.textSecondary(for: colorScheme))
                        }
                        if let error = storeKit.errorMessage ?? coordinator.billingError {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .top, spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                HStack(spacing: 10) {
                                    Button(action: {
                                        LBHaptic.medium()
                                        Task {
                                            await coordinator.refreshEntitlement()
                                        }
                                    }) {
                                        HStack(spacing: 6) {
                                            if coordinator.isCheckingEntitlement {
                                                ProgressView()
                                                    .tint(.red)
                                                    .scaleEffect(0.8)
                                            } else {
                                                Image(systemName: "arrow.clockwise")
                                                    .font(.caption.weight(.bold))
                                            }
                                            Text(coordinator.isCheckingEntitlement ? "Checking…" : "Retry")
                                                .font(.caption.weight(.bold))
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.red.opacity(0.12))
                                        .foregroundColor(.red)
                                        .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(coordinator.isCheckingEntitlement)

                                    if coordinator.sessionExpired || error.localizedCaseInsensitiveContains("sign in") || error.localizedCaseInsensitiveContains("session expired") {
                                        Button(action: {
                                            LBHaptic.light()
                                            coordinator.showingAuthSheet = true
                                        }) {
                                            HStack(spacing: 6) {
                                                Image(systemName: "person.crop.circle.badge.exclamationmark")
                                                    .font(.caption.weight(.bold))
                                                Text("Sign In")
                                                    .font(.caption.weight(.bold))
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(AppTheme.accent.opacity(0.25))
                                            .foregroundColor(SettingsAppearance.textPrimary(for: colorScheme))
                                            .clipShape(Capsule())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(Color.red.opacity(0.15), lineWidth: 1)
                            )
                        }
                        Button("Compare plans") { coordinator.showingPlansSheet = true }
                            .font(.caption.weight(.semibold))
                            .frame(maxWidth: .infinity, alignment: .center)

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
                            .foregroundColor(SettingsAppearance.textSecondary(for: colorScheme))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(18)
                    .settingsCard(for: colorScheme, cornerRadius: 20)

                    Button("LaterBox Service Terms") { if let url = URL(string: StoreKitManager.termsOfServiceUrl) { openURL(url) } }
                        .font(.caption)
                    // Legal Links
                    HStack(spacing: 16) {
                        Button("Terms of Use (EULA)") {
                            if let url = URL(string: StoreKitManager.eulaUrl) {
                                openURL(url)
                            }
                        }
                        .font(.caption.weight(.medium))
                        .foregroundColor(SettingsAppearance.textSecondary(for: colorScheme))

                        Text("•")
                            .foregroundColor(SettingsAppearance.textSecondary(for: colorScheme).opacity(0.5))

                        Button("Privacy Policy") {
                            if let url = URL(string: StoreKitManager.privacyPolicyUrl) {
                                openURL(url)
                            }
                        }
                        .font(.caption.weight(.medium))
                        .foregroundColor(SettingsAppearance.textSecondary(for: colorScheme))
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
        .task {
            await storeKit.updatePurchasedProducts()
            await coordinator.refreshEntitlement()
        }
        .navigationTitle("Subscription & Plans")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func featureRow(icon: String, title: String, unlocked: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(unlocked ? SettingsAppearance.textPrimary(for: colorScheme) : SettingsAppearance.textSecondary(for: colorScheme))
                .frame(width: 20)
            Text(title)
                .font(.subheadline)
                .foregroundColor(SettingsAppearance.textPrimary(for: colorScheme))
            Spacer()
            Image(systemName: unlocked ? "checkmark.circle.fill" : "lock.fill")
                .font(.caption)
                .foregroundColor(unlocked ? Color.green : SettingsAppearance.textSecondary(for: colorScheme).opacity(0.6))
        }
    }
}
