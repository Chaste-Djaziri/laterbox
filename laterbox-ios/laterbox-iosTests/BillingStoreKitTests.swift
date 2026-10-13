import Testing
import Foundation
import Security
@testable import laterbox_ios

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
