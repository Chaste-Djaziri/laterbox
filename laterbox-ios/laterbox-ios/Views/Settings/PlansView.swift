//
//  PlansView.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 05.10.26.
//

import SwiftUI
import StoreKit

public enum PlanIntervalSelection {
    case annual
    case monthly
}

public struct PlansView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @ObservedObject private var storeKit = StoreKitManager.shared
    @ObservedObject private var coordinator = SyncCoordinator.shared

    @State private var selectedInterval: PlanIntervalSelection = .annual
    public let isLiquidGlass: Bool

    public init(isLiquidGlass: Bool = false) {
        self.isLiquidGlass = isLiquidGlass
    }

    private var liquidGlassModalBackground: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            Color.black.opacity(0.42)
                .ignoresSafeArea()

            Circle()
                .fill(Color(hex: "E6EDB0").opacity(0.18))
                .frame(width: 320, height: 320)
                .blur(radius: 80)
                .offset(x: -120, y: -200)

            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 260, height: 260)
                .blur(radius: 70)
                .offset(x: 140, y: 160)
        }
        .allowsHitTesting(false)
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                if isLiquidGlass {
                    liquidGlassModalBackground
                } else {
                    LiquidGlassBackground()
                }

                ScrollView {
                    VStack(spacing: 24) {
                        // Header Branding
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(isLiquidGlass ? Color.white.opacity(0.18) : AppTheme.accent)
                                    .frame(width: 68, height: 68)
                                    .overlay(
                                        Circle()
                                            .stroke(isLiquidGlass ? Color.white.opacity(0.35) : Color.clear, lineWidth: 1)
                                    )
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(isLiquidGlass ? .white : AppTheme.textPrimary)
                            }
                            .padding(.top, 8)

                            VStack(spacing: 6) {
                                Text("LaterBox Pro")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(isLiquidGlass ? .white : AppTheme.textPrimary)

                                Text("Pro app icons and your choice of AI providers on this device. Connect an optional account for cloud sync, backup, and web access.")
                                    .font(.subheadline)
                                    .foregroundColor(isLiquidGlass ? Color.white.opacity(0.85) : AppTheme.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 16)
                            }
                        }

                        // If user is already Pro, show active badge
                        if storeKit.isProSubscriptionActive || coordinator.isProUser {
                            activeSubscriptionCard
                        }
                        Group {
                            // Plan Options: 1 Plan with Monthly or Annual Interval
                            VStack(spacing: 12) {
                                // Annual Option Card
                                planOptionCard(
                                    interval: .annual,
                                    title: "Annual",
                                    badge: nil,
                                    price: storeKit.annualDisplayPrice,
                                    period: "/ year",
                                    detail: storeKit.annualPlanDetail,
                                    isSelected: selectedInterval == .annual
                                )

                                // Monthly Option Card
                                planOptionCard(
                                    interval: .monthly,
                                    title: "Monthly",
                                    badge: nil,
                                    price: storeKit.monthlyDisplayPrice,
                                    period: "/ month",
                                    detail: storeKit.monthlyPlanDetail,
                                    isSelected: selectedInterval == .monthly
                                )
                            }

                            // Primary CTA Button
                            if !storeKit.isProSubscriptionActive && !(coordinator.billingEntitlement?.hasAccess == true && coordinator.billingEntitlement?.provider != nil) {
                            Button(action: {
                                handlePurchase()
                            }) {
                                HStack(spacing: 8) {
                                    if storeKit.isPurchasing {
                                        ProgressView()
                                            .tint(isLiquidGlass ? .black : .white)
                                    } else {
                                        Image(systemName: "sparkles")
                                            .font(.subheadline.weight(.semibold))
                                        Text(primaryButtonTitle)
                                            .font(.headline.weight(.bold))
                                    }
                                }
                                .foregroundColor(isLiquidGlass ? .black : .white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(isLiquidGlass ? Color.white : AppTheme.darkSurface)
                                )
                                .shadow(color: Color.black.opacity(isLiquidGlass ? 0.3 : 0.0), radius: 8, x: 0, y: 3)
                            }
                            .buttonStyle(.plain)
                            .disabled(storeKit.isPurchasing || (selectedInterval == .annual ? storeKit.annualProduct : storeKit.monthlyProduct) == nil)
                            .accessibilityIdentifier("billing.purchase")
                            }
                        }

                        ConnectProView(isLiquidGlass: isLiquidGlass)
                        if storeKit.monthlyProduct == nil || storeKit.annualProduct == nil {
                            Button("Retry App Store prices") { Task { await storeKit.loadProducts() } }
                                .foregroundColor(isLiquidGlass ? Color.white.opacity(0.85) : AppTheme.textPrimary)
                        }
                        // Feature Breakdown
                        VStack(alignment: .leading, spacing: 14) {
                            Text("What's Included with Pro")
                                .font(.caption.weight(.bold))
                                .foregroundColor(isLiquidGlass ? Color.white.opacity(0.65) : AppTheme.textSecondary)
                                .textCase(.uppercase)

                            VStack(alignment: .leading, spacing: 12) {
                                featureRow(
                                    icon: "icloud.fill",
                                    title: "Multi-Device Cloud Sync",
                                    subtitle: "Optional account connection enables sync across your devices."
                                )
                                featureRow(
                                    icon: "wand.and.stars",
                                    title: "AI Inbox Organizer",
                                    subtitle: "Use compatible on-device AI or your own AI provider keys."
                                )
                                featureRow(
                                    icon: "safari.fill",
                                    title: "Browser & Desktop Extensions",
                                    subtitle: "Browser extensions and local capture remain free."
                                )
                                featureRow(
                                    icon: "lock.icloud.fill",
                                    title: "Encrypted Cloud Backup",
                                    subtitle: "Optional account connection enables cloud backup and restore."
                                )
                            }
                            .padding(18)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(isLiquidGlass ? Color.white.opacity(0.08) : AppTheme.cardBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .strokeBorder(isLiquidGlass ? Color.white.opacity(0.18) : AppTheme.cardBorder, lineWidth: 1)
                            )
                        }

                        if storeKit.registrationAccountId == coordinator.currentUserId,
                           let message = storeKit.cloudRegistrationMessage {
                            Text(message)
                                .font(.caption)
                                .foregroundColor(isLiquidGlass ? Color.white.opacity(0.8) : AppTheme.textSecondary)
                        }
                        // Error Banner if any
                        if let error = storeKit.errorMessage ?? coordinator.billingError {
                            VStack(spacing: 8) {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(isLiquidGlass ? Color(red: 255/255, green: 130/255, blue: 130/255) : .red)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)

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
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(Color.red.opacity(0.12))
                                    .foregroundColor(.red)
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                                .disabled(coordinator.isCheckingEntitlement)
                            }
                        }

                        // Compliance & Legal Footer (Apple App Store Guideline 3.1.2)
                        VStack(spacing: 12) {
                            // Restore Purchases Button
                            Button(action: {
                                Task {
                                    await storeKit.restorePurchases()
                                }
                            }) {
                                HStack(spacing: 6) {
                                    if storeKit.isRestoring {
                                        ProgressView()
                                            .tint(isLiquidGlass ? .white : .black)
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.caption.weight(.semibold))
                                    }
                                    Text("Restore Purchases")
                                        .font(.caption.weight(.semibold))
                                }
                                .foregroundColor(isLiquidGlass ? .white : AppTheme.textPrimary)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(
                                    Capsule()
                                        .fill(isLiquidGlass ? Color.white.opacity(0.15) : Color.black.opacity(0.06))
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(isLiquidGlass ? Color.white.opacity(0.25) : Color.clear, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(storeKit.isRestoring)

                            // Legal Disclosure
                            Text("Payment will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless canceled at least 24 hours before the end of the current period. You can manage or cancel your subscription anytime in your Apple ID Account Settings.")
                                .font(.system(size: 11))
                                .foregroundColor(isLiquidGlass ? Color.white.opacity(0.65) : AppTheme.textSecondary.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .lineSpacing(2)

                            Button("LaterBox Service Terms") { if let url = URL(string: StoreKitManager.termsOfServiceUrl) { openURL(url) } }
                                .font(.caption)
                                .foregroundColor(isLiquidGlass ? Color.white.opacity(0.85) : AppTheme.textPrimary)
                            // EULA & Privacy Policy Links
                            HStack(spacing: 16) {
                                Button("Terms of Use (EULA)") {
                                    if let url = URL(string: StoreKitManager.eulaUrl) {
                                        openURL(url)
                                    }
                                }
                                .font(.caption.weight(.medium))
                                .foregroundColor(isLiquidGlass ? Color.white.opacity(0.85) : AppTheme.textPrimary)

                                Text("•")
                                    .foregroundColor(isLiquidGlass ? Color.white.opacity(0.4) : AppTheme.textSecondary)

                                Button("Privacy Policy") {
                                    if let url = URL(string: StoreKitManager.privacyPolicyUrl) {
                                        openURL(url)
                                    }
                                }
                                .font(.caption.weight(.medium))
                                .foregroundColor(isLiquidGlass ? Color.white.opacity(0.85) : AppTheme.textPrimary)
                            }
                        }
                        .padding(.top, 4)
                        .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(isLiquidGlass ? Color.white.opacity(0.65) : Color.black.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                }
            }
            .task {
                await storeKit.updatePurchasedProducts()
                await coordinator.refreshEntitlement()
            }
            .alert("Welcome to Pro!", isPresented: $storeKit.purchaseSuccessAlert) {
                Button("Continue", role: .cancel) {}
            } message: {
                Text(storeKit.cloudPurchaseConfirmed
                    ? "Your purchase is synced with your LaterBox account. Pro is available on the web and your connected devices."
                    : "Pro is active on this device. No registration is required. You can optionally connect Pro to your account for cloud and web access.")
            }
        }
    }

    // MARK: - Plan Option Card View
    private func planOptionCard(
        interval: PlanIntervalSelection,
        title: String,
        badge: String?,
        price: String,
        period: String,
        detail: String,
        isSelected: Bool
    ) -> some View {
        Button(action: {
            LBHaptic.light()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedInterval = interval
            }
        }) {
            HStack(alignment: .center) {
                // Radio Indicator
                ZStack {
                    Circle()
                        .strokeBorder(
                            isSelected
                                ? (isLiquidGlass ? Color.white : AppTheme.textPrimary)
                                : (isLiquidGlass ? Color.white.opacity(0.35) : Color.black.opacity(0.2)),
                            lineWidth: 2
                        )
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(isLiquidGlass ? Color.white : AppTheme.textPrimary)
                            .frame(width: 12, height: 12)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.headline.weight(.bold))
                            .foregroundColor(isLiquidGlass ? .white : AppTheme.textPrimary)

                        if let badgeText = badge {
                            Text(badgeText)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(isLiquidGlass ? .white : AppTheme.textPrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(isLiquidGlass ? Color.white.opacity(0.2) : AppTheme.accent)
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(isLiquidGlass ? Color.white.opacity(0.35) : Color.clear, lineWidth: 1)
                                )
                        }
                    }

                    Text(detail)
                        .fixedSize(horizontal: false, vertical: true)
                        .font(.caption)
                        .foregroundColor(isLiquidGlass ? Color.white.opacity(0.75) : AppTheme.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(price)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(isLiquidGlass ? .white : AppTheme.textPrimary)
                        Text(period)
                            .font(.caption)
                            .foregroundColor(isLiquidGlass ? Color.white.opacity(0.7) : AppTheme.textSecondary)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isLiquidGlass
                        ? (isSelected ? Color.white.opacity(0.18) : Color.white.opacity(0.08))
                        : AppTheme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        isSelected
                            ? (isLiquidGlass ? Color.white.opacity(0.85) : AppTheme.textPrimary)
                            : (isLiquidGlass ? Color.white.opacity(0.20) : AppTheme.cardBorder),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .shadow(color: Color.black.opacity(isLiquidGlass ? 0.25 : (isSelected ? 0.06 : 0.02)), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Active Subscription Card
    private var activeSubscriptionCard: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title3)
                        .foregroundColor(Color.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("LaterBox Pro Active")
                            .font(.headline.weight(.bold))
                            .foregroundColor(isLiquidGlass ? .white : AppTheme.textPrimary)
                        if let date = coordinator.billingEntitlement?.accessEndDate ?? storeKit.expirationDate {
                            Text("\(coordinator.billingEntitlement?.willCancel == true ? "Access ends" : coordinator.billingEntitlement?.status == "trialing" ? "Trial ends" : coordinator.billingEntitlement?.status == "past_due" ? "Grace period ends" : "Current period ends") \(date.formatted(date: .long, time: .omitted))")
                                .font(.caption)
                                .foregroundColor(isLiquidGlass ? Color.white.opacity(0.75) : AppTheme.textSecondary)
                        } else {
                            Text(coordinator.hasCloudPro ? "Device and account Pro active" : "Device Pro active · Account connection optional")
                                .font(.caption)
                                .foregroundColor(isLiquidGlass ? Color.white.opacity(0.75) : AppTheme.textSecondary)
                        }
                    }
                }

                Spacer()

                Text("Active")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(isLiquidGlass ? .white : AppTheme.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(isLiquidGlass ? Color.white.opacity(0.2) : AppTheme.accent)
                    )
                    .overlay(
                        Capsule()
                            .stroke(isLiquidGlass ? Color.white.opacity(0.35) : Color.clear, lineWidth: 1)
                    )
            }

            Divider().background(isLiquidGlass ? Color.white.opacity(0.2) : AppTheme.cardBorder)

            if coordinator.billingEntitlement?.provider != nil || storeKit.isProSubscriptionActive {
            Button(action: {
                Task { await storeKit.manageSubscription() }
            }) {
                HStack(spacing: 6) {
                    Text(storeKit.managementProvider == "paddle" ? "Manage Subscription with Paddle" : "Manage Subscription in App Store")
                        .font(.subheadline.weight(.semibold))
                    Image(systemName: "arrow.up.right")
                        .font(.caption.weight(.bold))
                }
                .foregroundColor(isLiquidGlass ? .white : AppTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isLiquidGlass ? Color.white.opacity(0.18) : Color.black.opacity(0.05))
                )
            }
            .buttonStyle(.plain)
            Text("To switch payment providers, cancel renewal with your current provider and subscribe again after access ends.")
                .font(.caption).foregroundColor(isLiquidGlass ? Color.white.opacity(0.7) : AppTheme.textSecondary)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isLiquidGlass ? Color.white.opacity(0.08) : AppTheme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(isLiquidGlass ? Color.white.opacity(0.18) : AppTheme.cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Feature Row Helper
    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(isLiquidGlass ? Color.white.opacity(0.18) : AppTheme.accent.opacity(0.6))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(isLiquidGlass ? .white : AppTheme.textPrimary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(isLiquidGlass ? .white : AppTheme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(isLiquidGlass ? Color.white.opacity(0.75) : AppTheme.textSecondary)
            }
        }
    }

    // MARK: - Purchase Action
    private var primaryButtonTitle: String {
        storeKit.purchaseButtonTitle(annual: selectedInterval == .annual)
    }

    private func handlePurchase() {
        LBHaptic.medium()
        Task {
            let targetProduct = (selectedInterval == .annual)
                ? storeKit.annualProduct
                : storeKit.monthlyProduct

            if let product = targetProduct {
                let uuid = coordinator.currentUserId.flatMap { UUID(uuidString: $0) }
                await storeKit.purchase(product, appAccountToken: uuid)
            } else {
                // If product is not loaded from App Store yet, trigger a reload
                await storeKit.loadProducts()
                if let product = (selectedInterval == .annual) ? storeKit.annualProduct : storeKit.monthlyProduct {
                    let uuid = coordinator.currentUserId.flatMap { UUID(uuidString: $0) }
                    await storeKit.purchase(product, appAccountToken: uuid)
                }
            }
        }
    }
}
