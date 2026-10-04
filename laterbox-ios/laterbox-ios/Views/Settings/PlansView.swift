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

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header Branding
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.accent)
                                    .frame(width: 68, height: 68)
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(AppTheme.textPrimary)
                            }
                            .padding(.top, 8)

                            VStack(spacing: 6) {
                                Text("LaterBox Pro")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(AppTheme.textPrimary)

                                Text("Cloud sync, AI intelligence, and seamless ecosystem access across all your devices.")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 16)
                            }
                        }

                        // If user is already Pro, show active badge
                        if storeKit.isProSubscriptionActive || coordinator.isProUser {
                            activeSubscriptionCard
                        } else {
                            // Plan Options: 1 Plan with Monthly or Annual Interval
                            VStack(spacing: 12) {
                                // Annual Option Card
                                planOptionCard(
                                    interval: .annual,
                                    title: "Annual",
                                    badge: "SAVE 17%",
                                    price: storeKit.annualDisplayPrice,
                                    period: "/ year",
                                    detail: "14-day free trial, then $3.33/mo",
                                    isSelected: selectedInterval == .annual
                                )

                                // Monthly Option Card
                                planOptionCard(
                                    interval: .monthly,
                                    title: "Monthly",
                                    badge: nil,
                                    price: storeKit.monthlyDisplayPrice,
                                    period: "/ month",
                                    detail: "14-day free trial, cancel anytime",
                                    isSelected: selectedInterval == .monthly
                                )
                            }

                            // Primary CTA Button
                            Button(action: {
                                handlePurchase()
                            }) {
                                HStack(spacing: 8) {
                                    if storeKit.isPurchasing {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "sparkles")
                                            .font(.subheadline.weight(.semibold))
                                        Text(primaryButtonTitle)
                                            .font(.headline.weight(.bold))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(AppTheme.darkSurface)
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(storeKit.isPurchasing)
                        }

                        // Feature Breakdown
                        VStack(alignment: .leading, spacing: 14) {
                            Text("What's Included with Pro")
                                .font(.caption.weight(.bold))
                                .foregroundColor(AppTheme.textSecondary)
                                .textCase(.uppercase)

                            VStack(alignment: .leading, spacing: 12) {
                                featureRow(
                                    icon: "icloud.fill",
                                    title: "Multi-Device Cloud Sync",
                                    subtitle: "Sync items instantly between iPhone, iPad, Mac, and Web."
                                )
                                featureRow(
                                    icon: "wand.and.stars",
                                    title: "AI Inbox Organizer",
                                    subtitle: "Smart suggestions, automatic tagging, and digest summaries."
                                )
                                featureRow(
                                    icon: "safari.fill",
                                    title: "Browser & Desktop Extensions",
                                    subtitle: "One-click capture for Safari, Chrome, and system share sheets."
                                )
                                featureRow(
                                    icon: "lock.icloud.fill",
                                    title: "Encrypted Cloud Backup",
                                    subtitle: "Secure cloud vault snapshot with effortless zero-loss restore."
                                )
                            }
                            .padding(18)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(AppTheme.cardBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                            )
                        }

                        // Error Banner if any
                        if let error = storeKit.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
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
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.caption.weight(.semibold))
                                    }
                                    Text("Restore Purchases")
                                        .font(.caption.weight(.semibold))
                                }
                                .foregroundColor(AppTheme.textPrimary)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(
                                    Capsule()
                                        .fill(Color.black.opacity(0.06))
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(storeKit.isRestoring)

                            // Legal Disclosure
                            Text("Payment will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless canceled at least 24 hours before the end of the current period. You can manage or cancel your subscription anytime in your Apple ID Account Settings.")
                                .font(.system(size: 11))
                                .foregroundColor(AppTheme.textSecondary.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .lineSpacing(2)

                            // EULA & Privacy Policy Links
                            HStack(spacing: 16) {
                                Button("Terms of Use (EULA)") {
                                    if let url = URL(string: StoreKitManager.termsOfServiceUrl) {
                                        openURL(url)
                                    }
                                }
                                .font(.caption.weight(.medium))
                                .foregroundColor(AppTheme.textPrimary)

                                Text("•")
                                    .foregroundColor(AppTheme.textSecondary)

                                Button("Privacy Policy") {
                                    if let url = URL(string: StoreKitManager.privacyPolicyUrl) {
                                        openURL(url)
                                    }
                                }
                                .font(.caption.weight(.medium))
                                .foregroundColor(AppTheme.textPrimary)
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
                            .foregroundColor(Color.black.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                }
            }
            .alert("Welcome to Pro!", isPresented: $storeKit.purchaseSuccessAlert) {
                Button("Done", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("Your LaterBox Pro subscription is now active across all your devices.")
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
                        .strokeBorder(isSelected ? AppTheme.textPrimary : Color.black.opacity(0.2), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(AppTheme.textPrimary)
                            .frame(width: 12, height: 12)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.headline.weight(.bold))
                            .foregroundColor(AppTheme.textPrimary)

                        if let badgeText = badge {
                            Text(badgeText)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(AppTheme.accent)
                                )
                        }
                    }

                    Text(detail)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(price)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        Text(period)
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppTheme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isSelected ? AppTheme.textPrimary : AppTheme.cardBorder, lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: Color.black.opacity(isSelected ? 0.06 : 0.02), radius: 6, x: 0, y: 2)
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
                            .foregroundColor(AppTheme.textPrimary)
                        if let date = storeKit.expirationDate {
                            Text("Renews on \(date.formatted(date: .long, time: .omitted))")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        } else {
                            Text("All Pro capabilities unlocked")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
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

            Divider().background(AppTheme.cardBorder)

            Button(action: {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    Task {
                        try? await AppStore.showManageSubscriptions(in: windowScene)
                    }
                }
            }) {
                HStack(spacing: 6) {
                    Text("Manage Subscription in App Store")
                        .font(.subheadline.weight(.semibold))
                    Image(systemName: "arrow.up.right")
                        .font(.caption.weight(.bold))
                }
                .foregroundColor(AppTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.black.opacity(0.05))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Feature Row Helper
    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.6))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppTheme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
    }

    // MARK: - Purchase Action
    private var primaryButtonTitle: String {
        switch selectedInterval {
        case .annual:
            return "Start 14-Day Free Trial (Annual)"
        case .monthly:
            return "Start 14-Day Free Trial (Monthly)"
        }
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
