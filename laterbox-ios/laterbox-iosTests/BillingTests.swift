import Testing
import Foundation
@testable import laterbox_ios

@MainActor
struct BillingTests {
    @Test func registrationFailuresExplainRecoveryAndRetry() {
        #expect(StoreKitManager.registrationFailureMessage(status: 403, code: "account_mismatch").contains("account used"))
        #expect(StoreKitManager.registrationFailureMessage(status: 422, code: "account_token_missing").contains("support"))
        #expect(StoreKitManager.registrationFailureMessage(status: 503, code: "configuration_unavailable").contains("server"))
        #expect(StoreKitManager.registrationFailureMessage(status: 503, code: "registration_unavailable").contains("retry"))
        #expect(StoreKitManager.registrationFailureMessage(status: 401, code: nil).contains("Sign in again"))
        #expect(StoreKitManager.registrationFailureMessage(status: 422, code: "unsupported_environment").contains("TestFlight"))
    }

    @Test func accountEntitlementUnderstandsProvidersAndFiniteExpiry() throws {
        for provider in ["apple", "paddle"] {
            let future = ISO8601DateFormatter().string(from: Date().addingTimeInterval(3600))
            let data = Data("{\"tier\":\"pro\",\"status\":\"active\",\"provider\":\"\(provider)\",\"accessEndsAt\":\"\(future)\",\"willCancel\":false}".utf8)
            let value = try JSONDecoder().decode(AccountBillingEntitlement.self, from: data)
            #expect(value.provider == provider)
            #expect(value.hasAccess)
        }
        for end in ["2020-01-01T00:00:00.000Z", "invalid"] {
            let data = Data("{\"tier\":\"pro\",\"status\":\"active\",\"provider\":\"apple\",\"accessEndsAt\":\"\(end)\",\"willCancel\":false}".utf8)
            #expect(try !JSONDecoder().decode(AccountBillingEntitlement.self, from: data).hasAccess)
        }
        let sandbox = Data(#"{"tier":"pro","status":"trialing","provider":"apple","accessEndsAt":"2099-01-01T00:00:00.000Z","willCancel":true,"billingInterval":"year","appleEnvironment":"Sandbox"}"#.utf8)
        let value = try JSONDecoder().decode(AccountBillingEntitlement.self, from: sandbox)
        #expect(value.hasAccess && value.willCancel)
        #expect(value.billingInterval == "year" && value.appleEnvironment == "Sandbox")
    }
}
