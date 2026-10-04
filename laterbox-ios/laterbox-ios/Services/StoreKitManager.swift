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

    private var transactionListenerTask: Task<Void, Error>? = nil

    private init() {
        // Start listening to background transaction updates (renewals, cancellations, outside purchases)
        self.transactionListenerTask = listenForTransactions()

        Task {
            await loadProducts()
            await updatePurchasedProducts()
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
        var hasActivePro = false
        var matchedId: String? = nil
        var latestExpiration: Date? = nil

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }

            // Check if transaction is revoked
            guard transaction.revocationDate == nil else {
                continue
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

        self.isProSubscriptionActive = hasActivePro
        self.activeProductId = matchedId
        self.expirationDate = latestExpiration

        // Synchronize with global SyncCoordinator
        SyncCoordinator.shared.updateProFromStoreKit(hasActivePro)
    }

    // MARK: - Purchase Flow
    @discardableResult
    public func purchase(_ product: Product, appAccountToken: UUID? = nil) async -> Bool {
        isPurchasing = true
        errorMessage = nil

        var options: Set<Product.PurchaseOption> = []
        if let token = appAccountToken {
            options.insert(.appAccountToken(token))
        }

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
