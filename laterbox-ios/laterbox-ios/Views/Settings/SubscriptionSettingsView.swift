// laterbox-ios/laterbox-ios/Views/Settings/SubscriptionSettingsView.swift
import SwiftUI

/// All new plans are purchased through the LaterBox web account.
/// Existing App Store purchases stay restorable during the transition.
public struct SubscriptionSettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL
    @ObservedObject private var coordinator = SyncCoordinator.shared
    @ObservedObject private var storeKit = StoreKitManager.shared

    public init() {}

    private var planName: String {
        if let plan = coordinator.billingEntitlement?.storagePlan {
            return plan.capitalized
        }
        return storeKit.isProSubscriptionActive ? "Plus (App Store)" : "Free"
    }

    private var quota: CloudStorageQuota {
        .from(coordinator.billingEntitlement)
    }

    public var body: some View {
        ZStack {
            InboxGrainBackground().ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    VStack(spacing: 12) {
                        Image(systemName: "externaldrive.fill")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(Color(hex: "171711"))
                            .frame(width: 72, height: 72)
                            .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 23))
                        Text("LaterBox \(planName)")
                            .font(.system(size: 25, weight: .bold, design: .rounded))
                            .foregroundStyle(SettingsAppearance.textPrimary(for: colorScheme))
                        Text("Your plan follows your LaterBox account across the web and iOS.")
                            .font(.subheadline)
                            .foregroundStyle(SettingsAppearance.textSecondary(for: colorScheme))
                            .multilineTextAlignment(.center)
                        if let provider = coordinator.billingEntitlement?.provider {
                            Text("Managed by \(provider == "whop" ? "Whop" : provider == "apple" ? "App Store" : "Paddle")")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(SettingsAppearance.textSecondary(for: colorScheme))
                        }
                    }
                    .padding(25)
                    .frame(maxWidth: .infinity)
                    .settingsCard(for: colorScheme, cornerRadius: 22)

                    VStack(alignment: .leading, spacing: 13) {
                        HStack {
                            Text("Cloud storage")
                                .font(.headline)
                            Spacer()
                            Text(quota.percent.map { "\(Int($0.rounded()))%" } ?? "—")
                                .font(.headline.monospacedDigit())
                        }
                        .foregroundStyle(SettingsAppearance.textPrimary(for: colorScheme))

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(SettingsAppearance.border(for: colorScheme))
                                if let fraction = quota.ringFraction {
                                    Capsule().fill(quota.level.ringColor)
                                        .frame(width: max(0, geo.size.width * fraction))
                                }
                            }
                        }
                        .frame(height: 9)

                        HStack {
                            Text(quota.usedLabel)
                            Spacer()
                            Text(quota.limitLabel)
                        }
                        .font(.caption)
                        .foregroundStyle(SettingsAppearance.textSecondary(for: colorScheme))

                        if quota.level == .full {
                            Label("Storage full. New changes are paused until space is freed or your plan changes.", systemImage: "exclamationmark.triangle.fill")
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(18)
                    .settingsCard(for: colorScheme, cornerRadius: 20)

                    VStack(alignment: .leading, spacing: 13) {
                        Text("Subscription & billing")
                            .font(.headline)
                            .foregroundStyle(SettingsAppearance.textPrimary(for: colorScheme))
                        Text("Free, Plus (10 GB) and Vault (100 GB) plans are managed on the LaterBox website. This iOS app displays the benefits of your existing account; it does not start new purchases.")
                            .font(.subheadline)
                            .foregroundStyle(SettingsAppearance.textSecondary(for: colorScheme))

                        Button {
                            LBHaptic.light()
                            coordinator.showingPlansSheet = true
                        } label: {
                            Label("View plan details", systemImage: "square.stack")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(SettingsAppearance.textPrimary(for: colorScheme))
                        .background(SettingsAppearance.surface(for: colorScheme), in: RoundedRectangle(cornerRadius: 13))
                        .accessibilityIdentifier("Upgrade to LaterBox Pro")

                        if coordinator.billingEntitlement?.provider != nil || storeKit.isProSubscriptionActive {
                            Button {
                                LBHaptic.light()
                                Task { await storeKit.manageSubscription() }
                            } label: {
                                Label("Manage existing subscription", systemImage: "creditcard")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 13)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(SettingsAppearance.textPrimary(for: colorScheme))
                            .background(SettingsAppearance.surface(for: colorScheme), in: RoundedRectangle(cornerRadius: 13))
                        }

                        if let end = coordinator.billingEntitlement?.accessEndDate {
                            Text("\(coordinator.billingEntitlement?.willCancel == true ? "Access ends" : "Current period ends") \(end.formatted(date: .long, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(SettingsAppearance.textSecondary(for: colorScheme))
                        }

                        Button {
                            Task { await coordinator.refreshEntitlement() }
                        } label: {
                            Label(coordinator.isCheckingEntitlement ? "Checking…" : "Refresh account plan", systemImage: "arrow.clockwise")
                                .font(.caption.weight(.semibold))
                        }
                        .disabled(coordinator.isCheckingEntitlement)
                        .buttonStyle(.plain)

                        if let error = coordinator.billingError ?? storeKit.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(18)
                    .settingsCard(for: colorScheme, cornerRadius: 20)

                    ConnectProView()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Existing App Store subscribers")
                            .font(.headline)
                            .foregroundStyle(SettingsAppearance.textPrimary(for: colorScheme))
                        Text("Purchases made through Apple remain available. Restore them if you previously subscribed on this Apple ID.")
                            .font(.caption)
                            .foregroundStyle(SettingsAppearance.textSecondary(for: colorScheme))
                        Button {
                            LBHaptic.light()
                            Task { await storeKit.restorePurchases() }
                        } label: {
                            Label("Restore previous purchases", systemImage: "arrow.clockwise")
                                .font(.subheadline.weight(.semibold))
                        }
                        .buttonStyle(.plain)
                        .disabled(storeKit.isRestoring)
                        .accessibilityIdentifier("Restore Purchases")
                    }
                    .padding(18)
                    .settingsCard(for: colorScheme, cornerRadius: 20)

                    HStack(spacing: 14) {
                        Button("Terms of Use") {
                            if let url = URL(string: StoreKitManager.termsOfServiceUrl) { openURL(url) }
                        }
                        Button("Privacy Policy") {
                            if let url = URL(string: StoreKitManager.privacyPolicyUrl) { openURL(url) }
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(SettingsAppearance.textSecondary(for: colorScheme))
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 35)
            }
        }
        .task {
            await storeKit.updatePurchasedProducts()
            await coordinator.refreshEntitlement()
        }
        .navigationTitle("Subscription & Plans")
        .navigationBarTitleDisplayMode(.inline)
    }
}
