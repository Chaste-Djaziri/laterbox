// laterbox-ios/laterbox-ios/Views/Settings/PlansView.swift
import SwiftUI

/// Plans are purchased on the web. iOS reads the same account entitlement,
/// while preserving management and restoration of legacy App Store purchases.
public enum PlanIntervalSelection {
    case annual
    case monthly
}

public struct PlansView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var coordinator = SyncCoordinator.shared
    @ObservedObject private var storeKit = StoreKitManager.shared

    public let isLiquidGlass: Bool
    public let isEmbeddedInNavigation: Bool
    private let onDone: (() -> Void)?

    public init(
        isLiquidGlass: Bool = false,
        isEmbeddedInNavigation: Bool = false,
        onDone: (() -> Void)? = nil
    ) {
        self.isLiquidGlass = isLiquidGlass
        self.isEmbeddedInNavigation = isEmbeddedInNavigation
        self.onDone = onDone
    }

    private func closePlans() {
        if let onDone {
            onDone()
        } else {
            dismiss()
        }
    }

    private var currentPlan: String {
        if let plan = coordinator.billingEntitlement?.storagePlan {
            return plan.capitalized
        }
        return storeKit.isProSubscriptionActive ? "Plus" : "Free"
    }

    private var quota: CloudStorageQuota {
        .from(coordinator.billingEntitlement)
    }

    public var body: some View {
        Group {
            if isEmbeddedInNavigation {
                plansContent
            } else {
                NavigationStack { plansContent }
            }
        }
    }

    private var plansContent: some View {
            ZStack {
                InboxGrainBackground().ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        VStack(spacing: 10) {
                            LaterBoxVectorMark(
                                size: 66, appearance: .automatic,
                                animates: false
                            )
                            .frame(width: 72, height: 72)
                            Text("LaterBox Plans")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                            Text("One account, the same cloud storage across web and iOS.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 18)

                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("YOUR CURRENT PLAN")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.secondary)
                                Text(currentPlan)
                                    .font(.title2.weight(.bold))
                                Text(quota.percent.map { _ in
                                    "\(quota.usedLabel) of \(quota.limitLabel) used"
                                } ?? "Cloud usage unavailable")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 10)
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(AppTheme.accent)
                                .font(.title)
                        }
                        .padding(18)
                        .settingsCard(for: colorScheme, cornerRadius: 20)

                        VStack(spacing: 12) {
                            tierCard(title: "Free", storage: "500 MB",
                                     details: "Cloud sync, reminders, and saved links.",
                                     icon: "cloud", selected: currentPlan == "Free")
                            tierCard(title: "Plus", storage: "10 GB",
                                     details: "More space for files, photos, PDFs, and saved content.",
                                     icon: "sparkles", selected: currentPlan == "Plus")
                            tierCard(title: "Vault", storage: "100 GB",
                                     details: "Extra space for larger libraries and attachments.",
                                     icon: "externaldrive", selected: currentPlan == "Vault")
                        }

                        VStack(alignment: .leading, spacing: 9) {
                            Label("Billing on the web", systemImage: "globe")
                                .font(.headline)
                            Text("New subscriptions and plan changes are handled through your LaterBox web account. Existing Whop plans appear here automatically when you sign in with the same account.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("This iOS app does not start a separate purchase.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .settingsCard(for: colorScheme, cornerRadius: 20)

                        if quota.level == .full {
                            Label("Storage full. New saves and uploads are paused until space is freed or your account limit increases.", systemImage: "exclamationmark.triangle.fill")
                                .font(.subheadline)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(15)
                                .settingsCard(for: colorScheme, cornerRadius: 16)
                        }

                        if coordinator.billingEntitlement?.provider != nil || storeKit.isProSubscriptionActive {
                            Button {
                                LBHaptic.light()
                                Task { await storeKit.manageSubscription() }
                            } label: {
                                Label("Manage existing subscription", systemImage: "creditcard")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            }
                            .foregroundStyle(SettingsAppearance.textPrimary(for: colorScheme))
                            .settingsCard(for: colorScheme, cornerRadius: 16)
                        }

                        Button("Restore Purchases") {
                            Task { await storeKit.restorePurchases() }
                        }
                        .font(.caption.weight(.semibold))
                        .accessibilityIdentifier("Restore Purchases")
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 32)
                }
            }
            // Keep the embedded back/Done action pinned even after scrolling
            // to restore purchases. Hidden parent toolbars cannot hide this button.
            .safeAreaInset(edge: .top, spacing: 0) {
                if isEmbeddedInNavigation {
                    HStack {
                        Spacer()
                        Button {
                            closePlans()
                        } label: {
                            Text("Done")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(SettingsAppearance.textPrimary(for: colorScheme))
                                .padding(.horizontal, 18)
                                .padding(.vertical, 11)
                                .background(SettingsAppearance.surface(for: colorScheme),
                                            in: Capsule())
                                .contentShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("plans.done")
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle("Plans")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
            .toolbar {
                if !isEmbeddedInNavigation {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { closePlans() }
                            .accessibilityIdentifier("plans.done")
                    }
                }
            }
            .task {
                await coordinator.refreshEntitlement()
            }
    }

    private func tierCard(title: String, storage: String, details: String, icon: String, selected: Bool) -> some View {
        HStack(spacing: 13) {
            Image(systemName: icon)
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(Color(hex: "171711"))
                .frame(width: 46, height: 46)
                .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 13))
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("LaterBox \(title)")
                        .font(.headline)
                    Spacer()
                    Text(storage)
                        .font(.subheadline.weight(.semibold))
                }
                Text(details)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if selected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppTheme.accent)
                    .font(.title3)
            }
        }
        .padding(15)
        .settingsCard(for: colorScheme, cornerRadius: 18)
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(selected ? AppTheme.accent : .clear, lineWidth: 2)
        }
    }
}
