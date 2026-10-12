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
    public static let eulaUrl = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
    public static let termsOfServiceUrl = "https://laterbox.dev/terms"
    public static let privacyPolicyUrl = "https://laterbox.dev/privacy"

    // MARK: - Published State
    @Published public private(set) var products: [Product] = []
    @Published public private(set) var monthlyProduct: Product? = nil
    @Published public private(set) var annualProduct: Product? = nil
    @Published public private(set) var isProSubscriptionActive: Bool = false
    @Published public private(set) var activeProductId: String? = nil
    @Published public private(set) var expirationDate: Date? = nil
    @Published public private(set) var eligibleIntroProducts: Set<String> = []
    @Published public var isLoadingProducts: Bool = false
    @Published public var isPurchasing: Bool = false
    @Published public var isRestoring: Bool = false
    @Published public var errorMessage: String? = nil
    @Published public var purchaseSuccessAlert: Bool = false

    @Published public private(set) var cloudRegistrationMessage: String? = nil
    @Published public private(set) var cloudPurchaseConfirmed = false
    @Published public private(set) var registrationAccountId: String? = nil
    private var registrationInProgress = false
    private let vault = AppleBillingVault()
    private var activePurchase: ApplePurchaseOutboxEntry?
    @Published public private(set) var isConnectingAccount = false
    @Published public private(set) var needsAccountConnection = false

    public static func registrationFailureMessage(status: Int, code: String?) -> String {
        switch code {
        case "link_required": return "Pro is active on this device. Connect Pro to your account if you want cloud and web access."
        case "linking_unavailable": return "Device Pro is active. Account connection is temporarily unavailable; please retry later."
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

            eligibleIntroProducts = []
            for product in fetchedProducts {
                if let subscription = product.subscription, await subscription.isEligibleForIntroOffer {
                    eligibleIntroProducts.insert(product.id)
                }
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

    private func entry(_ transaction: StoreKit.Transaction, signed: String) -> ApplePurchaseOutboxEntry {
        ApplePurchaseOutboxEntry(originalId: String(transaction.originalID), transactionId: String(transaction.id),
            environment: transaction.environment == .xcode ? "Xcode" : transaction.environment == .sandbox ? "Sandbox" : "Production",
            accountToken: transaction.appAccountToken?.uuidString.lowercased(), signedDate: transaction.signedDate, signedTransaction: signed)
    }

    private func stage(_ transaction: StoreKit.Transaction, signed: String) {
        do { try vault.enqueue(entry(transaction, signed: signed)) }
        catch { cloudRegistrationMessage = "Device Pro is retained. Unable to save a cloud retry; restore purchases when you reconnect." }
    }

    // MARK: - Device delivery never waits for LaterBox registration
    public func updatePurchasedProducts() async {
        var purchase: ApplePurchaseOutboxEntry?
        var matchedId: String?
        var latestExpiration: Date?
        var active = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  Self.allProductIds.contains(transaction.productID), transaction.revocationDate == nil,
                  !transaction.isUpgraded else { continue }
            // StoreKit includes subscribed and valid billing-grace entitlements here.
            // A grace entitlement can retain the last paid transaction's past expiry.
            if !active || (transaction.expirationDate ?? .distantFuture) > (latestExpiration ?? .distantPast) {
                active = true
                matchedId = transaction.productID
                latestExpiration = transaction.expirationDate
                purchase = entry(transaction, signed: result.jwsRepresentation)
            }
            stage(transaction, signed: result.jwsRepresentation)
        }
        activePurchase = purchase
        isProSubscriptionActive = active
        activeProductId = matchedId
        expirationDate = latestExpiration
        needsAccountConnection = active && !cloudPurchaseConfirmed
        SyncCoordinator.shared.updateProFromStoreKit(active)
        for await result in Transaction.unfinished {
            guard case .verified(let transaction) = result, Self.allProductIds.contains(transaction.productID) else { continue }
            stage(transaction, signed: result.jwsRepresentation)
            await transaction.finish()
        }
        Task { await registerAccountPurchases() }
    }

    @discardableResult
    public func registerAccountPurchases() async -> Bool {
        let coordinator = SyncCoordinator.shared
        if registrationAccountId != coordinator.currentUserId {
            cloudPurchaseConfirmed = false
            cloudRegistrationMessage = nil
            needsAccountConnection = isProSubscriptionActive
        }
        guard !coordinator.isGuestMode, coordinator.isAuthenticated, !registrationInProgress, let token = coordinator.authToken,
              let uid = coordinator.currentUserId else {
            if coordinator.currentUserId == nil { cloudPurchaseConfirmed = false; needsAccountConnection = isProSubscriptionActive }
            return false
        }
        let receipts: [ApplePurchaseOutboxEntry]
        do { receipts = try vault.entries() }
        catch { cloudRegistrationMessage = "Device Pro is retained. Restore purchases to retry account synchronization."; return false }
        registrationAccountId = uid
        guard !receipts.isEmpty else { return false }
        registrationInProgress = true
        defer { registrationInProgress = false }
        var failure: String?
        var guestUnlinked = false
        for receipt in receipts {
            guard uid == coordinator.currentUserId, token == coordinator.authToken else { return false }
            do {
                let result = try await send(receipt, path: "verify", token: token)
                guard uid == coordinator.currentUserId, token == coordinator.authToken else { return false }
                if result.status == 200 { try vault.acknowledge(receipt) }
                else if result.code == "link_required" { guestUnlinked = true }
                else { failure = Self.registrationFailureMessage(status: result.status, code: result.code) }
            } catch { failure = "Device Pro is retained. Cloud synchronization will retry when you reconnect or return to the app." }
        }
        guard uid == coordinator.currentUserId, token == coordinator.authToken else { return false }
        await coordinator.refreshEntitlement()
        cloudPurchaseConfirmed = !guestUnlinked && failure == nil && coordinator.billingEntitlement?.provider == "apple"
            && coordinator.billingEntitlement?.hasAccess == true
        needsAccountConnection = isProSubscriptionActive && !cloudPurchaseConfirmed
        cloudRegistrationMessage = failure ?? (guestUnlinked ? Self.registrationFailureMessage(status: 409, code: "link_required")
            : cloudPurchaseConfirmed ? "Pro is connected to your LaterBox account and available on the web."
            : coordinator.billingError ?? "Your Apple subscription is no longer active.")
        return failure == nil && !guestUnlinked
    }

    private func send(_ receipt: ApplePurchaseOutboxEntry, path: String, token: String) async throws -> (status: Int, code: String?) {
        var request = URLRequest(url: URL(string: "\(LaterBoxAPIService.shared.billingUrl)/api/billing/apple/\(path)")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["signedTransaction": receipt.signedTransaction])
        let (data, response) = try await URLSession.shared.data(for: request)
        let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        return ((response as? HTTPURLResponse)?.statusCode ?? 503, payload?["code"] as? String)
    }

    // Invoked only by the explicit, confirmed Connect Pro action.
    public func connectPurchaseToAccount() async {
        let coordinator = SyncCoordinator.shared
        guard !isConnectingAccount, let token = coordinator.authToken, let uid = coordinator.currentUserId else {
            coordinator.showingAuthSheet = true
            return
        }
        guard let receipt = activePurchase else { errorMessage = "Restore an active purchase before connecting Pro."; return }
        guard receipt.environment != "Xcode" else { errorMessage = "Use TestFlight or the App Store to connect a purchase; local StoreKit simulations stay on this device."; return }
        isConnectingAccount = true
        defer { isConnectingAccount = false }
        errorMessage = nil
        do {
            let result = try await send(receipt, path: "link", token: token)
            guard uid == coordinator.currentUserId, token == coordinator.authToken else { return }
            if result.status != 200 {
                errorMessage = Self.registrationFailureMessage(status: result.status, code: result.code)
                return
            }
            try vault.acknowledge(receipt)
            await coordinator.refreshEntitlement()
            cloudPurchaseConfirmed = coordinator.billingEntitlement?.provider == "apple" && coordinator.billingEntitlement?.hasAccess == true
            needsAccountConnection = !cloudPurchaseConfirmed
            registrationAccountId = uid
            cloudRegistrationMessage = cloudPurchaseConfirmed ? "Pro is connected to your LaterBox account and available on the web."
                : "Your purchase is connected, but Apple does not currently report active Pro access."
        } catch { errorMessage = "Device Pro is active. Unable to connect your account right now; please retry when online." }
    }

    // MARK: - Purchase Flow
    @discardableResult
    public func purchase(_ product: Product, appAccountToken: UUID? = nil) async -> Bool {
        guard !isPurchasing else { return false }
        let coordinator = SyncCoordinator.shared
        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }
        guard !isProSubscriptionActive,
              !(coordinator.billingEntitlement?.hasAccess == true && coordinator.billingEntitlement?.provider != nil) else {
            errorMessage = "Pro is already active. Manage your current subscription; switch payment providers after access ends."
            return false
        }
        let accountToken: UUID
        do {
            // No login or LaterBox network request is necessary to buy.
            if !coordinator.isGuestMode, coordinator.isAuthenticated,
               let token = coordinator.currentUserId.flatMap(UUID.init(uuidString:)) { accountToken = token }
            else { accountToken = try vault.anonymousToken() }
        } catch { errorMessage = "Unable to save the purchase identity securely on this device. Please retry."; return false }
        let options: Set<Product.PurchaseOption> = [.appAccountToken(accountToken)]

        do {
            let result = try await product.purchase(options: options)

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                stage(transaction, signed: verification.jwsRepresentation)
                await updatePurchasedProducts()
                await transaction.finish()
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

    public var managementProvider: String? {
        isProSubscriptionActive ? "apple" : SyncCoordinator.shared.billingEntitlement?.provider
    }

    public func manageSubscription(provider: String? = nil) async {
        let coordinator = SyncCoordinator.shared
        errorMessage = nil
        do {
            if (provider ?? managementProvider) == "paddle" {
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

    // MARK: - StoreKit prices and offer terms
    public var monthlyDisplayPrice: String { monthlyProduct?.displayPrice ?? "Price unavailable" }
    public var annualDisplayPrice: String { annualProduct?.displayPrice ?? "Price unavailable" }

    private func trialLabel(_ product: Product?) -> String? {
        guard let product, eligibleIntroProducts.contains(product.id),
              let offer = product.subscription?.introductoryOffer, offer.paymentMode == .freeTrial else { return nil }
        let count = offer.period.value * offer.periodCount
        let unit: String
        switch offer.period.unit {
        case .day: unit = count == 1 ? "day" : "days"
        case .week: unit = count == 1 ? "week" : "weeks"
        case .month: unit = count == 1 ? "month" : "months"
        case .year: unit = count == 1 ? "year" : "years"
        @unknown default: return nil
        }
        return "\(count) \(unit) free"
    }
    public func purchaseButtonTitle(annual: Bool) -> String {
        let product = annual ? annualProduct : monthlyProduct
        if let trial = trialLabel(product) { return "Start \(trial) trial" }
        return annual ? "Subscribe annually" : "Subscribe monthly"
    }
    public var monthlyPlanDetail: String {
        guard let product = monthlyProduct else { return "App Store prices are loading" }
        let price = "\(product.displayPrice) per month"
        return trialLabel(product).map { "\($0), then \(price)" } ?? "\(price), automatically renews"
    }
    public var annualPlanDetail: String {
        guard let product = annualProduct else { return "App Store prices are loading" }
        let equivalent = (product.price / 12).formatted(product.priceFormatStyle)
        let price = "\(product.displayPrice) per year"
        let offer = trialLabel(product).map { "\($0), then \(price). " } ?? "\(price). "
        return "\(offer)Equivalent to \(equivalent) per month, billed annually"
    }

    // MARK: - Background Transaction Listener
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    guard Self.allProductIds.contains(transaction.productID) else { continue }
                    await self.stage(transaction, signed: result.jwsRepresentation)
                    await self.updatePurchasedProducts()
                    await transaction.finish()
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
