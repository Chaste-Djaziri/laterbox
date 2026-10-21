import SwiftUI

/// Account creation and connection are separate, voluntary actions.
public struct ConnectProView: View {
    @ObservedObject private var coordinator = SyncCoordinator.shared
    @ObservedObject private var storeKit = StoreKitManager.shared
    @State private var confirming = false
    @State private var destinationId: String?
    @State private var destinationEmail: String?
    public let isLiquidGlass: Bool

    public init(isLiquidGlass: Bool = false) {
        self.isLiquidGlass = isLiquidGlass
    }

    public var body: some View {
        if storeKit.isProSubscriptionActive && storeKit.needsAccountConnection {
            VStack(alignment: .leading, spacing: 10) {
                Text("Pro on this device")
                    .font(.headline)
                    .foregroundColor(isLiquidGlass ? .white : AppTheme.textPrimary)

                Text("Your Apple purchase works without a LaterBox account. Connecting an account is optional and enables cloud sync, backup, and Pro on the web.")
                    .font(.caption)
                    .foregroundColor(isLiquidGlass ? Color.white.opacity(0.8) : AppTheme.textSecondary)

                if let email = coordinator.currentUserEmail, !email.isEmpty {
                    Text("Connect to: \(email)")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(isLiquidGlass ? Color.white.opacity(0.95) : AppTheme.textPrimary)
                }

                Button {
                    if coordinator.isAuthenticated {
                        destinationId = coordinator.currentUserId
                        destinationEmail = coordinator.currentUserEmail
                        confirming = true
                    } else {
                        coordinator.showingAuthSheet = true
                    }
                } label: {
                    HStack {
                        if storeKit.isConnectingAccount { ProgressView().tint(isLiquidGlass ? .white : .black) }
                        Text(coordinator.isAuthenticated ? "Connect Pro to your account" : "Sign in to connect Pro (optional)")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundColor(isLiquidGlass ? .white : AppTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(isLiquidGlass ? Color.white.opacity(0.18) : Color.black.opacity(0.06))
                    )
                }
                .disabled(storeKit.isConnectingAccount)
                .accessibilityIdentifier("billing.connect")

                Text("Signing in does not connect this purchase automatically.")
                    .font(.caption2)
                    .foregroundColor(isLiquidGlass ? Color.white.opacity(0.6) : AppTheme.textSecondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isLiquidGlass ? Color.white.opacity(0.08) : AppTheme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isLiquidGlass ? Color.white.opacity(0.18) : AppTheme.cardBorder, lineWidth: 1)
            )
            .confirmationDialog("Connect Pro to \(destinationEmail ?? "your LaterBox account")?", isPresented: $confirming, titleVisibility: .visible) {
                Button("Connect Pro") {
                    guard destinationId == coordinator.currentUserId else { storeKit.errorMessage = "Your account changed. Review the destination account and try again."; return }
                    Task { await storeKit.connectPurchaseToAccount() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This purchase will be linked to this account for web and cloud access. A purchase already connected to another account cannot be transferred here.")
            }
        }
    }
}
