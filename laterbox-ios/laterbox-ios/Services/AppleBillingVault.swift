import Foundation
import Security

public nonisolated struct ApplePurchaseOutboxEntry: Codable, Equatable, Sendable {
    public let originalId: String
    public let transactionId: String
    public let environment: String
    public let accountToken: String?
    public let signedDate: Date
    public let signedTransaction: String
    public var key: String { "\(environment):\(originalId)" }
}

/// Device-only purchase identity and retry receipts. Never stores a login token.
@MainActor
public final class AppleBillingVault {
    private let service: String
    private let account = "purchase-state-v1"
    private struct State: Codable {
        var anonymousToken: UUID?
        var outbox: [String: ApplePurchaseOutboxEntry] = [:]
    }
    public enum VaultError: Error { case unavailable(OSStatus), invalidData }

    public init(service: String = "pro.micorp.laterbox.apple-billing") { self.service = service }

    private var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account]
    }
    private func read() throws -> State {
        var lookup = query
        lookup[kSecReturnData as String] = true
        lookup[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(lookup as CFDictionary, &result)
        if status == errSecItemNotFound { return State() }
        guard status == errSecSuccess else { throw VaultError.unavailable(status) }
        guard let data = result as? Data else { throw VaultError.invalidData }
        return try JSONDecoder().decode(State.self, from: data)
    }
    private func write(_ state: State) throws {
        let data = try JSONEncoder().encode(state)
        let changes = [kSecValueData as String: data]
        let status = SecItemUpdate(query as CFDictionary, changes as CFDictionary)
        if status == errSecItemNotFound {
            var insert = query
            insert[kSecValueData as String] = data
            insert[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            let added = SecItemAdd(insert as CFDictionary, nil)
            guard added == errSecSuccess else { throw VaultError.unavailable(added) }
        } else if status != errSecSuccess { throw VaultError.unavailable(status) }
    }
    public func anonymousToken() throws -> UUID {
        var state = try read()
        if let token = state.anonymousToken { return token }
        let token = UUID()
        state.anonymousToken = token
        try write(state)
        return token
    }
    public func entries() throws -> [ApplePurchaseOutboxEntry] { Array(try read().outbox.values) }
    public func enqueue(_ entry: ApplePurchaseOutboxEntry) throws {
        guard entry.environment != "Xcode" else { return }
        var state = try read()
        if let existing = state.outbox[entry.key], existing.signedDate > entry.signedDate { return }
        state.outbox[entry.key] = entry
        try write(state)
    }
    public func acknowledge(_ entry: ApplePurchaseOutboxEntry) throws {
        var state = try read()
        // Do not remove a newer renewal queued while the request was in flight.
        if state.outbox[entry.key] == entry { state.outbox.removeValue(forKey: entry.key); try write(state) }
    }
}
