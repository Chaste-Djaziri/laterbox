import Testing
import Foundation
import StoreKit
import StoreKitTest
import Security
@testable import laterbox_ios

extension LaterAITests {
    @Test func guestPurchaseDeliversWithoutAnAccountAndFinishesTheTransaction() async throws {
        let file = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("laterbox-ios/Products.storekit")
        let session = try SKTestSession(contentsOf: file)
        session.disableDialogs = true
        session.clearTransactions()
        defer { session.clearTransactions() }
        let coordinator = SyncCoordinator.shared
        coordinator.signOut()
        coordinator.continueAsGuest()
        let manager = StoreKitManager.shared
        await manager.updatePurchasedProducts()
        await manager.loadProducts()
        let product = try #require(manager.monthlyProduct)
        #expect(coordinator.currentUserId == nil && coordinator.authToken == nil)
        #expect(await manager.purchase(product))
        #expect(manager.isProSubscriptionActive)
        #expect(coordinator.isProUser && !coordinator.hasCloudPro)
        #expect(!coordinator.showingAuthSheet)
        var unfinished = 0
        for await _ in Transaction.unfinished { unfinished += 1 }
        #expect(unfinished == 0)
        let transaction = try #require(session.allTransactions().first)
        #expect(transaction.productIdentifier == StoreKitManager.monthlyId)
        await manager.restorePurchases()
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
