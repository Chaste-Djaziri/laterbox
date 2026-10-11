//
//  StoreKitManager.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 05.10.26.
//

import Foundation
import StoreKit
import SwiftUI
import Combine

@MainActor
public final class StoreKitManager: ObservableObject {
    public static let shared = StoreKitManager()

    // MARK: - Product Identifiers
    public static let monthlyId = "com.laterbox.pro.monthly"
    public static let annualId = "com.laterbox.pro.annual"
    public static let allProductIds: Set<String> = [monthlyId, annualId]

    // Official Policy URLs
    public static let termsOfServiceUrl = "https://laterbox.dev/terms"
    public static let privacyPolicyUrl = "https://laterbox.dev/privacy"

    // MARK: - Published State
    @Published public private(set) var products: [Product] = []
    @Published public private(set) var monthlyProduct: Product? = nil
    @Published public private(set) var annualProduct: Product? = nil
    @Published public private(set) var isProSubscriptionActive: Bool = false
    @Published public private(set) var activeProductId: String? = nil
    @Published public private(set) var expirationDate: Date? = nil
    @Published public var isLoadingProducts: Bool = false
    @Published public var isPurchasing: Bool = false
    @Published public var isRestoring: Bool = false
    @Published public var errorMessage: String? = nil
    @Published public var purchaseSuccessAlert: Bool = false

    @Published public private(set) var cloudRegistrationMessage: String? = nil
    @Published public private(set) var cloudPurchaseConfirmed = false
    @Published public private(set) var registrationAccountId: String? = nil
    private var registrationInProgress = false

    public static func registrationFailureMessage(status: Int, code: String?) -> String {
        switch code {
        case "account_mismatch": return "Sign in to the LaterBox account used for this purchase to enable web Pro."
        case "account_token_missing": return "This purchase has no LaterBox account link. Contact support for purchase recovery."
        case "unsupported_environment": return "Local StoreKit test purchases unlock this device only. Use TestFlight to test web Pro."
        case "configuration_unavailable": return "Apple verification is not configured on the server. Contact support; your device purchase is retained."
        case "registration_unavailable": return "Cloud purchase registration is temporarily unavailable. It will retry when you return to the app."
        default:
            if status == 401 { return "Sign in again to sync your purchase with the web." }
            if status >= 500 { return "Cloud purchase verification is unavailable. It will retry when you return to the app." }
            return "The App Store purchase could not be verified for web access. Restore purchases or contact support."
        }
    }

    private var verifiedTransactions: [String] = []
    private var transactionListenerTask: Task<Void, Error>? = nil

    private init() {
        // Start listening to background transaction updates (renewals, cancellations, outside purchases)
        self.transactionListenerTask = listenForTransactions()

        Task {
            await updatePurchasedProducts()
            await loadProducts()
        }
    }

    deinit {
        transactionListenerTask?.cancel()
    }

    // MARK: - Fetch App Store Products
    public func loadProducts() async {
        isLoadingProducts = true
        errorMessage = nil

        do {
            let fetchedProducts = try await Product.products(for: Self.allProductIds)
            self.products = fetchedProducts

            for product in fetchedProducts {
                if product.id == Self.monthlyId {
                    self.monthlyProduct = product
                } else if product.id == Self.annualId {
                    self.annualProduct = product
                }
            }
            isLoadingProducts = false
        } catch {
            self.errorMessage = "Unable to reach the App Store: \(error.localizedDescription)"
            self.isLoadingProducts = false
        }
    }

    // MARK: - Check Current Active Entitlements
    public func updatePurchasedProducts() async {
        var signedTransactions: [String] = []
        var hasActivePro = false
        var matchedId: String? = nil
        var latestExpiration: Date? = nil

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }

            // Check if transaction is revoked
            guard Self.allProductIds.contains(transaction.productID), transaction.revocationDate == nil, !transaction.isUpgraded else {
                continue
            }

            if transaction.environment != .xcode && (transaction.expirationDate == nil || transaction.expirationDate! > Date()) {
                signedTransactions.append(result.jwsRepresentation)
            }

            // Verify if still within valid period
            if let expDate = transaction.expirationDate {
                if expDate > Date() {
                    hasActivePro = true
                    matchedId = transaction.productID
                    latestExpiration = expDate
                }
            } else {
                // Non-expiring lifetime / active entitlement
                hasActivePro = true
                matchedId = transaction.productID
            }
        }

        verifiedTransactions = signedTransactions
        self.isProSubscriptionActive = hasActivePro
        self.activeProductId = matchedId
        self.expirationDate = latestExpiration

        // Synchronize with global SyncCoordinator
        SyncCoordinator.shared.updateProFromStoreKit(hasActivePro)
        await registerAccountPurchases()
    }

    public func registerAccountPurchases(extraTransactions: [String] = []) async {
        let coordinator = SyncCoordinator.shared
        guard !registrationInProgress, let token = coordinator.authToken,
              let uid = coordinator.currentUserId else { return }
        let transactions = Array(Set(verifiedTransactions + extraTransactions))
        registrationAccountId = uid
        cloudPurchaseConfirmed = false
        guard !transactions.isEmpty else {
            cloudRegistrationMessage = isProSubscriptionActive
                ? "Local StoreKit tests unlock this device only. Use TestFlight to test web Pro." : nil
            return
        }
        registrationInProgress = true
        defer { registrationInProgress = false }
        cloudRegistrationMessage = "Syncing your App Store purchase with your LaterBox account…"
        var failure: String?
        for signed in transactions {
            guard uid == coordinator.currentUserId, token == coordinator.authToken else { return }
            do {
                var request = URLRequest(url: URL(string: "\(LaterBoxAPIService.shared.billingUrl)/api/billing/apple/verify")!)
                request.httpMethod = "POST"
                request.timeoutInterval = 20
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONEncoder().encode(["signedTransaction": signed])
                let (data, response) = try await URLSession.shared.data(for: request)
                guard uid == coordinator.currentUserId, token == coordinator.authToken else { return }
                let status = (response as? HTTPURLResponse)?.statusCode ?? 503
                if status != 200 {
                    let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                    failure = Self.registrationFailureMessage(status: status, code: payload?["code"] as? String)
                }
            } catch {
                failure = "Your device purchase is retained. Cloud verification will retry when you reconnect or return to the app."
            }
        }
        guard uid == coordinator.currentUserId, token == coordinator.authToken else { return }
        await coordinator.refreshEntitlement()
        cloudPurchaseConfirmed = failure == nil && coordinator.billingEntitlement?.provider == "apple"
            && coordinator.billingEntitlement?.hasAccess == true
        cloudRegistrationMessage = failure ?? (cloudPurchaseConfirmed
            ? "Pro is synced with your LaterBox account and available on the web."
            : coordinator.billingError ?? "Your Apple subscription is no longer active.")
    }

    // MARK: - Purchase Flow
    @discardableResult
    public func purchase(_ product: Product, appAccountToken: UUID? = nil) async -> Bool {
        guard !isPurchasing else { return false }
        let coordinator = SyncCoordinator.shared
        guard let uid = coordinator.currentUserId, let accountToken = UUID(uuidString: uid),
              let authToken = coordinator.authToken, !authToken.isEmpty,
              appAccountToken == nil || appAccountToken == accountToken else {
            errorMessage = "Sign in to your LaterBox account before starting a subscription."
            coordinator.showingAuthSheet = true
            return false
        }
        isPurchasing = true
        errorMessage = nil
        guard await coordinator.refreshEntitlement(), uid == coordinator.currentUserId,
              authToken == coordinator.authToken else {
            isPurchasing = false
            errorMessage = coordinator.billingError ?? "Your account changed. Sign in and retry."
            return false
        }
        guard !isProSubscriptionActive,
              !(coordinator.billingEntitlement?.hasAccess == true && coordinator.billingEntitlement?.provider != nil) else {
            isPurchasing = false
            errorMessage = "Pro is already active. Manage your current subscription; switch payment providers after access ends."
            return false
        }
        let options: Set<Product.PurchaseOption> = [.appAccountToken(accountToken)]

        do {
            let result = try await product.purchase(options: options)

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await updatePurchasedProducts()
                isPurchasing = false
                purchaseSuccessAlert = true
                LBHaptic.success()
                return true

            case .userCancelled:
                isPurchasing = false
                return false

            case .pending:
                isPurchasing = false
                self.errorMessage = "Your purchase is pending approval (e.g. Ask to Buy)."
                return false

            @unknown default:
                isPurchasing = false
                return false
            }
        } catch {
            isPurchasing = false
            self.errorMessage = error.localizedDescription
            LBHaptic.error()
            return false
        }
    }

    // MARK: - Restore Purchases
    public func restorePurchases() async {
        isRestoring = true
        errorMessage = nil

        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
            isRestoring = false
            LBHaptic.success()
        } catch {
            isRestoring = false
            self.errorMessage = "Could not restore purchases: \(error.localizedDescription)"
            LBHaptic.error()
        }
    }

    public func manageSubscription() async {
        let coordinator = SyncCoordinator.shared
        errorMessage = nil
        do {
            if coordinator.billingEntitlement?.provider == "paddle" {
                guard let token = coordinator.authToken else { throw URLError(.userAuthenticationRequired) }
                let url = try await LaterBoxAPIService.shared.paddleManagementURL(token: token)
                await UIApplication.shared.open(url)
            } else if coordinator.billingEntitlement?.provider == "apple" || isProSubscriptionActive {
                guard let scene = UIApplication.shared.connectedScenes.first(where: {
                    $0.activationState == .foregroundActive
                }) as? UIWindowScene else { throw URLError(.unknown) }
                try await AppStore.showManageSubscriptions(in: scene)
            } else {
                coordinator.showingPlansSheet = true
            }
        } catch {
            errorMessage = "Unable to open subscription management. Sign in again or retry when online."
        }
    }

    // MARK: - Display Price Helpers
    public var monthlyDisplayPrice: String {
        monthlyProduct?.displayPrice ?? "$3.99"
    }

    public var annualDisplayPrice: String {
        annualProduct?.displayPrice ?? "$39.99"
    }

    // MARK: - Background Transaction Listener
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    if transaction.environment != .xcode {
                        await self.registerAccountPurchases(extraTransactions: [result.jwsRepresentation])
                    }
                    await transaction.finish()
                    await self.updatePurchasedProducts()
                } catch {
                    // Ignore unverified or invalid transactions
                }
            }
        }
    }

    // MARK: - Verification
    private nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
}
