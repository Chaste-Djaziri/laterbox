import SwiftUI

/// Account creation and connection are separate, voluntary actions.
public struct ConnectProView: View {
    @ObservedObject private var coordinator = SyncCoordinator.shared
    @ObservedObject private var storeKit = StoreKitManager.shared
    @State private var confirming = false
    public init() {}

    public var body: some View {
        if storeKit.isProSubscriptionActive && storeKit.needsAccountConnection {
            VStack(alignment: .leading, spacing: 10) {
                Text("Pro on this device").font(.headline)
                Text("Your Apple purchase works without a LaterBox account. Connecting an account is optional and enables cloud sync, backup, and Pro on the web.")
                    .font(.caption).foregroundColor(AppTheme.textSecondary)
                if let email = coordinator.currentUserEmail {
                    Text("Connect to: \(email)").font(.caption.weight(.semibold))
                }
                Button {
                    if coordinator.isAuthenticated { confirming = true }
                    else { coordinator.showingAuthSheet = true }
                } label: {
                    HStack {
                        if storeKit.isConnectingAccount { ProgressView() }
                        Text(coordinator.isAuthenticated ? "Connect Pro to your account" : "Sign in to connect Pro (optional)")
                    }
                }
                .disabled(storeKit.isConnectingAccount)
                .accessibilityIdentifier("billing.connect")
                Text("Signing in does not connect this purchase automatically.")
                    .font(.caption2).foregroundColor(AppTheme.textSecondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
            .confirmationDialog("Connect Pro to \(coordinator.currentUserEmail ?? "your LaterBox account")?", isPresented: $confirming, titleVisibility: .visible) {
                Button("Connect Pro") { Task { await storeKit.connectPurchaseToAccount() } }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This purchase will be linked to this account for web and cloud access. A purchase already connected to another account cannot be transferred here.")
            }
        }
    }
}
