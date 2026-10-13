import Testing
import Foundation
import StoreKit
import StoreKitTest
import Security
@testable import laterbox_ios

extension LaterAITests {
    @Test func deviceSubscriptionPreservesGraceAndRemovesRefundedAccess() async throws {
        let file = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("laterbox-ios/Products.storekit")
        print("Billing integration: configuring StoreKit session")
        let session = try SKTestSession(contentsOf: file)
        session.disableDialogs = true
        session.timeRate = .realTime
        session.clearTransactions()
        defer { session.clearTransactions() }
        let coordinator = SyncCoordinator.shared
        let previous = (coordinator.currentUserId, coordinator.currentUserEmail, coordinator.authToken, coordinator.isGuestMode, coordinator.isProUser)
        defer {
            coordinator.currentUserId = previous.0; coordinator.currentUserEmail = previous.1; coordinator.authToken = previous.2
            coordinator.isGuestMode = previous.3; coordinator.setProForTesting(previous.4)
        }
        coordinator.signOut()
        coordinator.continueAsGuest()
        let manager = StoreKitManager.shared
        print("Billing integration: refreshing device entitlements")
        await manager.updatePurchasedProducts()
        print("Billing integration: loading StoreKit products")
        await manager.loadProducts()
        let product = try #require(manager.monthlyProduct)
        print("Billing integration: creating a verified StoreKit test transaction")
        let guestToken = try AppleBillingVault().anonymousToken()
        _ = try await session.buyProduct(identifier: product.id, options: [.appAccountToken(guestToken)])
        await manager.updatePurchasedProducts()
        session.shouldEnterBillingRetryOnRenewal = true
        session.billingGracePeriodIsEnabled = true
        print("Billing integration: entering billing grace")
        try session.forceRenewalOfSubscription(productIdentifier: product.id)
        let subscription = try #require(product.subscription)
        var inGrace = false
        for _ in 0..<20 {
            inGrace = try await subscription.status.contains { $0.state == .inGracePeriod }
            if inGrace { break }
            try await Task.sleep(for: .milliseconds(100))
        }
        #expect(inGrace)
        await manager.updatePurchasedProducts()
        #expect(manager.isProSubscriptionActive)
        session.shouldEnterBillingRetryOnRenewal = false
        session.clearTransactions()
        await manager.updatePurchasedProducts()
        _ = try await session.buyProduct(identifier: product.id, options: [.appAccountToken(guestToken)])
        await manager.updatePurchasedProducts()
        let transaction = try #require(session.allTransactions().first)
        try session.disableAutoRenewForTransaction(identifier: transaction.identifier)
        await manager.updatePurchasedProducts()
        #expect(manager.isProSubscriptionActive)
        try session.refundTransaction(identifier: transaction.identifier)
        for _ in 0..<20 {
            await manager.updatePurchasedProducts()
            if !manager.isProSubscriptionActive { break }
            try await Task.sleep(for: .milliseconds(100))
        }
        #expect(!manager.isProSubscriptionActive && !coordinator.hasCloudPro)
    }

    @Test func guestEntitlementDeliversWithoutAnAccountAndFinishesTheTransaction() async throws {
        let file = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("laterbox-ios/Products.storekit")
        print("Billing integration: configuring StoreKit session")
        let session = try SKTestSession(contentsOf: file)
        session.disableDialogs = true
        session.timeRate = .realTime
        session.clearTransactions()
        defer { session.clearTransactions() }
        let coordinator = SyncCoordinator.shared
        let previous = (coordinator.currentUserId, coordinator.currentUserEmail, coordinator.authToken, coordinator.isGuestMode, coordinator.isProUser)
        defer {
            coordinator.currentUserId = previous.0; coordinator.currentUserEmail = previous.1; coordinator.authToken = previous.2
            coordinator.isGuestMode = previous.3; coordinator.setProForTesting(previous.4)
        }
        coordinator.signOut()
        coordinator.continueAsGuest()
        let manager = StoreKitManager.shared
        print("Billing integration: refreshing device entitlements")
        await manager.updatePurchasedProducts()
        print("Billing integration: loading StoreKit products")
        await manager.loadProducts()
        let product = try #require(manager.monthlyProduct)
        let annual = try #require(manager.annualProduct)
        #expect(annual.displayPrice == "$39.99")
        if annual.price.formatted(annual.priceFormatStyle) != annual.displayPrice {
            #expect(!manager.annualPlanDetail.contains("Equivalent"))
            #expect(manager.annualPlanDetail.contains("$39.99 per year"))
        }
        #expect(coordinator.currentUserId == nil && coordinator.authToken == nil)
        print("Billing integration: creating a verified StoreKit test transaction")
        let guestToken = try AppleBillingVault().anonymousToken()
        let purchase = try await session.buyProduct(identifier: product.id, options: [.appAccountToken(guestToken)])
        #expect(purchase.appAccountToken == guestToken)
        for _ in 0..<20 {
            await manager.updatePurchasedProducts()
            if manager.isProSubscriptionActive && coordinator.isProUser { break }
            try await Task.sleep(for: .milliseconds(100))
        }
        #expect(manager.isProSubscriptionActive)
        #expect(coordinator.isProUser && !coordinator.hasCloudPro)
        #expect(!coordinator.showingAuthSheet)
        var unfinished = 0
        for await _ in Transaction.unfinished { unfinished += 1 }
        #expect(unfinished == 0)
        let transaction = try #require(session.allTransactions().first)
        #expect(transaction.productIdentifier == StoreKitManager.monthlyId)
        // Launch entitlement recovery does not require a confirmation window.
        // AppStore.sync's user-facing restore action is exercised by the UI test.
        await manager.updatePurchasedProducts()
        #expect(manager.isProSubscriptionActive)
        #expect(coordinator.currentUserId == nil)
        // A second purchase on this device is blocked without requesting signup.
        #expect(await !manager.purchase(product))
        #expect(!coordinator.showingAuthSheet)
        session.clearTransactions()
        await manager.updatePurchasedProducts()
    }
}

@MainActor
struct BillingVaultTests {
    @Test func anonymousIdentityAndOutboxSurviveRelaunchWithoutLosingNewerReceipts() throws {
        let service = "pro.micorp.laterbox.test.billing.\(UUID())"
        defer { SecItemDelete([kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service] as CFDictionary) }
        let vault = AppleBillingVault(service: service)
        let token = try vault.anonymousToken()
        let reopened = AppleBillingVault(service: service)
        #expect(try reopened.anonymousToken() == token)
        let old = ApplePurchaseOutboxEntry(originalId: "original", transactionId: "one", environment: "Sandbox", accountToken: token.uuidString, signedDate: Date(timeIntervalSince1970: 1), signedTransaction: "old-jws")
        let newer = ApplePurchaseOutboxEntry(originalId: "original", transactionId: "two", environment: "Sandbox", accountToken: token.uuidString, signedDate: Date(timeIntervalSince1970: 2), signedTransaction: "refund-jws")
        try vault.enqueue(old)
        try reopened.enqueue(newer)
        try vault.acknowledge(old)
        #expect(try reopened.entries() == [newer])
        try reopened.acknowledge(newer)
        #expect(try vault.entries().isEmpty)
        #expect(try vault.anonymousToken() == token)
    }
}
