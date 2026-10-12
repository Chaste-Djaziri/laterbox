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

                            Text(coordinator.isProUser ? coordinator.hasCloudPro ? "Device Pro and account cloud access active" : "Device Pro active • Account connection optional" : "Free offline vault • Cloud synchronization available")
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
                                Text(coordinator.hasCloudPro ? "Your connected account has Pro access on iOS and the web." : "Pro works on this device without registration. Connect an account only if you want cloud sync, backup, and web access.")
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
                                featureRow(icon: "icloud.fill", title: "Multi-Device Cloud Sync", unlocked: coordinator.hasCloudPro)
                                featureRow(icon: "wand.and.stars", title: "Pro AI Provider Options", unlocked: coordinator.isProUser)
                                featureRow(icon: "safari.fill", title: "Web Pro Access", unlocked: coordinator.hasCloudPro)
                                featureRow(icon: "lock.icloud.fill", title: "Cloud Backup & Restore", unlocked: coordinator.hasCloudPro)
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

                    ConnectProView()
                    // Subscription Management Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Plan Actions")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        if coordinator.billingEntitlement?.provider != nil || storeKit.isProSubscriptionActive {
                            Button(action: {
                                LBHaptic.light()
                                Task { await storeKit.manageSubscription() }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: storeKit.managementProvider == "paddle" ? "creditcard" : "applelogo")
                                    Text(storeKit.managementProvider == "paddle" ? "Manage Paddle Subscription" : "Manage Apple Subscription")
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

                                Text("\(storeKit.monthlyDisplayPrice) / month or \(storeKit.annualDisplayPrice) / year")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }

                        if storeKit.isProSubscriptionActive && coordinator.billingEntitlement?.provider == "paddle" {
                            Button("Manage account’s Paddle subscription") { Task { await storeKit.manageSubscription(provider: "paddle") } }
                                .font(.caption)
                        }
                        if let entitlement = coordinator.billingEntitlement, entitlement.provider != nil {
                            Text("Managed by \(entitlement.provider == "apple" ? "Apple" : "Paddle"). To switch payment providers, cancel renewal there and subscribe with the other provider after access ends.")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                            if let end = entitlement.accessEndDate {
                                Text("\(entitlement.willCancel ? "Access ends" : entitlement.status == "trialing" ? "Trial ends" : entitlement.status == "past_due" ? "Grace period ends" : "Renews") \(end.formatted(date: .long, time: .omitted))")
                                    .font(.caption)
                            }
                        }
                        if storeKit.registrationAccountId == coordinator.currentUserId,
                           let message = storeKit.cloudRegistrationMessage {
                            Text(message).font(.caption).foregroundColor(AppTheme.textSecondary)
                        }
                        if let error = storeKit.errorMessage ?? coordinator.billingError {
                            Text(error).font(.caption).foregroundColor(.red)
                        }
                        Button("Compare plans") { coordinator.showingPlansSheet = true }
                            .font(.caption.weight(.semibold))

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
