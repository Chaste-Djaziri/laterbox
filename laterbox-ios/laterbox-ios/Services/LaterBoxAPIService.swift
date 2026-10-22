//
//  LaterBoxAPIService.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 04.10.26.
//

import Foundation

#if DEBUG
public nonisolated enum LaterBoxDevConfig: Sendable {
    public static let localHost = "172.20.10.3"
    public static let defaultSupabaseUrl = "http://\(localHost):54321"
    public static let defaultAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
    public static let defaultWebUrl = "http://\(localHost):3000"
    public static let defaultBillingUrl = "http://\(localHost):3000"
    public static let defaultMailpitUrl = "http://\(localHost):54324"
}
#endif

private nonisolated enum LaterBoxRuntimeConfiguration: Sendable {
    nonisolated static func value(for environmentKey: String, devDefault: String, prodFallback: String) -> String {
        #if DEBUG
        if let env = ProcessInfo.processInfo.environment[environmentKey]?.trimmingCharacters(in: .whitespacesAndNewlines), !env.isEmpty {
            // Strictly forbid remote hosted Supabase in dev mode
            if env.contains("supabase.co") {
                return devDefault
            }
            return env
        }
        return devDefault
        #else
        return prodFallback
        #endif
    }
}

public nonisolated struct RemoteItemDTO: Codable, Sendable {
    public let id: String
    public let user_id: String?
    public let url: String?
    public let title: String?
    public let text_content: String?
    public let text_selector: String?
    public let type: String?
    public let favorite: Bool?
    public let status: String?
    public let return_at: String?
    public let inbox_entered_at: String?
    public let created_at: String?
    public let updated_at: String?
}

public nonisolated struct RemoteCollectionDTO: Codable, Sendable {
    public let id: String
    public let user_id: String?
    public let name: String
    public let created_at: String?
    public let updated_at: String?
}

public nonisolated struct AccountBillingEntitlement: Decodable, Sendable {
    public let tier: String
    public let status: String
    public let provider: String?
    public let accessEndsAt: String?
    public let willCancel: Bool
    public let billingInterval: String?
    public let appleEnvironment: String?

    public var accessEndDate: Date? {
        guard let accessEndsAt else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: accessEndsAt) ?? ISO8601DateFormatter().date(from: accessEndsAt)
    }

    public var hasAccess: Bool {
        tier == "pro" && (accessEndsAt == nil || (accessEndDate.map { $0 > Date() } ?? false))
    }
}

public actor LaterBoxAPIService {
    public static let shared = LaterBoxAPIService()

    public nonisolated static let defaultSupabaseUrl = "https://ltjisrgldssqskcylcbj.supabase.co"
    #if DEBUG
    public nonisolated static let isDevMode = true
    public nonisolated let mailpitUrl: String = LaterBoxRuntimeConfiguration.value(
        for: "LATERBOX_MAILPIT_URL",
        devDefault: LaterBoxDevConfig.defaultMailpitUrl,
        prodFallback: ""
    )
    #else
    public nonisolated static let isDevMode = false
    public nonisolated let mailpitUrl: String = ""
    #endif

    public nonisolated let supabaseUrl = LaterBoxRuntimeConfiguration.value(
        for: "LATERBOX_SUPABASE_URL",
        devDefault: {
            #if DEBUG
            return LaterBoxDevConfig.defaultSupabaseUrl
            #else
            return defaultSupabaseUrl
            #endif
        }(),
        prodFallback: defaultSupabaseUrl
    )
    public nonisolated let anonKey = LaterBoxRuntimeConfiguration.value(
        for: "LATERBOX_SUPABASE_ANON_KEY",
        devDefault: {
            #if DEBUG
            return LaterBoxDevConfig.defaultAnonKey
            #else
            return "sb_publishable_Rc4e_ik2LE4SR0UrfX-OEQ_5Mu_lw9p"
            #endif
        }(),
        prodFallback: "sb_publishable_Rc4e_ik2LE4SR0UrfX-OEQ_5Mu_lw9p"
    )
    public nonisolated let webUrl = LaterBoxRuntimeConfiguration.value(
        for: "LATERBOX_WEB_URL",
        devDefault: {
            #if DEBUG
            return LaterBoxDevConfig.defaultWebUrl
            #else
            return "https://laterbox.dev"
            #endif
        }(),
        prodFallback: "https://laterbox.dev"
    )
    public nonisolated let billingUrl = LaterBoxRuntimeConfiguration.value(
        for: "LATERBOX_BILLING_URL",
        devDefault: {
            #if DEBUG
            return LaterBoxDevConfig.defaultBillingUrl
            #else
            return "https://app.laterbox.dev"
            #endif
        }(),
        prodFallback: "https://app.laterbox.dev"
    )

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }

    // MARK: - Headers Helper
    private func headers(token: String? = nil) -> [String: String] {
        var dict: [String: String] = [
            "apikey": anonKey,
            "Content-Type": "application/json"
        ]
        if let token = token, !token.isEmpty {
            dict["Authorization"] = "Bearer \(token)"
        }
        return dict
    }

    // MARK: - System Status Check (Web Integration)
    public func fetchSystemStatus() async -> (status: String, isOperational: Bool) {
        do {
            let snapshot = try await fetchServiceStatus()
            return (snapshot.status.capitalized, snapshot.status == "operational")
        } catch {
            return ("Status unavailable", false)
        }
    }

    // MARK: - Auth: Email OTP & Password Flow
    public enum SendOTPResult: Equatable {
        case sent
        case userNotFound
    }

    public func requestEmailOTP(email: String) async throws -> SendOTPResult {
        guard let url = URL(string: "\(supabaseUrl)/auth/v1/otp") else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        for (k, v) in headers() { req.setValue(v, forHTTPHeaderField: k) }
        let body = ["email": email, "create_user": false] as [String : Any]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if (200...299).contains(http.statusCode) {
            return .sent
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let msg = ((json["msg"] as? String) ?? (json["message"] as? String) ?? "").lowercased()
            let errorCode = ((json["error_code"] as? String) ?? "").lowercased()
            if errorCode == "otp_disabled" ||
               errorCode == "user_not_found" ||
               msg.contains("signups not allowed") ||
               msg.contains("user not found") {
                return .userNotFound
            }
            if let customMsg = json["msg"] as? String ?? json["message"] as? String {
                throw NSError(domain: "LaterBoxAuth", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: customMsg])
            }
        }

        throw URLError(.userAuthenticationRequired)
    }

    @discardableResult
    public func sendEmailOTP(email: String) async throws -> Bool {
        let result = try await requestEmailOTP(email: email)
        switch result {
        case .sent:
            return true
        case .userNotFound:
            throw NSError(domain: "LaterBoxAuth", code: 422, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
    }

    public func signUp(email: String, password: String) async throws -> (requiresConfirmation: Bool, userId: String?) {
        guard let url = URL(string: "\(supabaseUrl)/auth/v1/signup") else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        for (k, v) in headers() { req.setValue(v, forHTTPHeaderField: k) }
        let body = ["email": email, "password": password]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if (200...299).contains(http.statusCode) {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let hasAccessToken = (json["access_token"] as? String) != nil
                let user = (json["user"] as? [String: Any]) ?? json
                let userId = user["id"] as? String
                return (!hasAccessToken, userId)
            }
            return (true, nil)
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let msg = json["msg"] as? String ?? json["message"] as? String ?? json["error_description"] as? String {
            throw NSError(domain: "LaterBoxAuth", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        throw URLError(.userAuthenticationRequired)
    }

    public func signInWithPassword(email: String, password: String) async throws -> (accessToken: String, refreshToken: String?, userId: String) {
        guard let url = URL(string: "\(supabaseUrl)/auth/v1/token?grant_type=password") else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        for (k, v) in headers() { req.setValue(v, forHTTPHeaderField: k) }
        let body = ["email": email, "password": password]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            if let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
               let msg = json["msg"] as? String ?? json["message"] as? String ?? json["error_description"] as? String {
                throw NSError(domain: "LaterBoxAuth", code: (response as? HTTPURLResponse)?.statusCode ?? 400, userInfo: [NSLocalizedDescriptionKey: msg])
            }
            throw URLError(.userAuthenticationRequired)
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let token = json["access_token"] as? String,
              let user = json["user"] as? [String: Any],
              let userId = user["id"] as? String else {
            throw URLError(.cannotParseResponse)
        }
        let refreshToken = json["refresh_token"] as? String
        return (token, refreshToken, userId)
    }

    public func verifyOTP(email: String, token: String, type: String = "email") async throws -> (accessToken: String, refreshToken: String?, userId: String) {
        guard let url = URL(string: "\(supabaseUrl)/auth/v1/verify") else {
            throw URLError(.badURL)
        }
        do {
            return try await executeVerifyOTP(url: url, email: email, token: token, type: type)
        } catch {
            let fallbackType = (type == "signup") ? "email" : "signup"
            return try await executeVerifyOTP(url: url, email: email, token: token, type: fallbackType)
        }
    }

    public func verifyOTP(email: String, token: String) async throws -> (accessToken: String, userId: String) {
        let (token, _, userId): (String, String?, String) = try await verifyOTP(email: email, token: token, type: "email")
        return (token, userId)
    }

    private func executeVerifyOTP(url: URL, email: String, token: String, type: String) async throws -> (accessToken: String, refreshToken: String?, userId: String) {
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        for (k, v) in headers() { req.setValue(v, forHTTPHeaderField: k) }
        let body: [String: Any] = [
            "type": type,
            "email": email,
            "token": token
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            if let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
               let msg = json["msg"] as? String ?? json["message"] as? String ?? json["error_description"] as? String {
                throw NSError(domain: "LaterBoxAuth", code: (response as? HTTPURLResponse)?.statusCode ?? 400, userInfo: [NSLocalizedDescriptionKey: msg])
            }
            throw URLError(.userAuthenticationRequired)
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String,
              let user = json["user"] as? [String: Any],
              let userId = user["id"] as? String else {
            throw URLError(.cannotParseResponse)
        }
        let refreshToken = json["refresh_token"] as? String
        return (accessToken, refreshToken, userId)
    }

    // MARK: - Auth: Native Sign in with Apple
    public func signInWithApple(identityToken: String, nonce: String? = nil, sessionToken: String? = nil) async throws -> (accessToken: String, refreshToken: String?, userId: String, email: String?) {
        guard let url = URL(string: "\(supabaseUrl)/auth/v1/token?grant_type=id_token") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        for (key, value) in headers(token: sessionToken) { request.setValue(value, forHTTPHeaderField: key) }
        var body: [String: Any] = ["provider": "apple", "id_token": identityToken]
        if let nonce, !nonce.isEmpty { body["nonce"] = nonce }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.userAuthenticationRequired)
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String,
              let user = json["user"] as? [String: Any],
              let userId = user["id"] as? String else {
            throw URLError(.cannotParseResponse)
        }
        return (accessToken, json["refresh_token"] as? String, userId, user["email"] as? String)
    }

    // MARK: - Auth: Refresh Session Token
    public func refreshSession(refreshToken: String) async throws -> (accessToken: String, refreshToken: String, userId: String) {
        guard let url = URL(string: "\(supabaseUrl)/auth/v1/token?grant_type=refresh_token") else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        for (k, v) in headers() { req.setValue(v, forHTTPHeaderField: k) }
        let body: [String: Any] = [
            "refresh_token": refreshToken
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw CloudSyncError.unauthenticated
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let newAccessToken = json["access_token"] as? String,
              let user = json["user"] as? [String: Any],
              let userId = user["id"] as? String else {
            throw CloudSyncError.unauthenticated
        }
        let newRefreshToken = (json["refresh_token"] as? String) ?? refreshToken
        return (newAccessToken, newRefreshToken, userId)
    }

    public func deleteAccount(token: String) async throws {
        guard let url = URL(string: "\(billingUrl)/api/account/delete") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("******", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200..<300).contains(http.statusCode) else {
            throw CloudSyncError.other("Account deletion could not finish. Please try again.")
        }
    }

    public func fetchBillingEntitlement(token: String) async throws -> AccountBillingEntitlement {
        guard let url = URL(string: "\(billingUrl)/api/billing/entitlement") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        if http.statusCode == 401 || http.statusCode == 403 {
            let serverMsg = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String
                ?? (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["message"] as? String
                ?? "JWT expired"
            throw CloudSyncError.unauthorized(message: serverMsg)
        }
        guard (200...299).contains(http.statusCode) else {
            throw CloudSyncError.serverError(statusCode: http.statusCode, message: "Subscription service unavailable")
        }
        return try JSONDecoder().decode(AccountBillingEntitlement.self, from: data)
    }

    public func paddleManagementURL(token: String) async throws -> URL {
        var request = URLRequest(url: URL(string: "\(billingUrl)/api/billing/portal")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data(#"{"action":"manage"}"#.utf8)
        let (data, response) = try await session.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200,
              let payload = try JSONSerialization.jsonObject(with: data) as? [String: String],
              let value = payload["url"], let url = URL(string: value), url.scheme == "https" else {
            throw URLError(.badServerResponse)
        }
        return url
    }

    // MARK: - Pro Entitlement Check
    public func checkProEntitlement(userId: String, token: String?) async -> Bool {
        guard let url = URL(string: "\(supabaseUrl)/rest/v1/rpc/has_pro_entitlement") else {
            return false
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        for (k, v) in headers(token: token) { req.setValue(v, forHTTPHeaderField: k) }
        let body = ["target_user_id": userId]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await session.data(for: req)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return false
            }
            if let boolVal = try? JSONDecoder().decode(Bool.self, from: data) {
                return boolVal
            }
            return false
        } catch {
            return false
        }
    }

    // MARK: - Quick Capture via Supabase Edge Function
    public func captureConnectedItem(url: String?, text: String?, title: String?, token: String?) async throws -> String {
        guard let endpoint = URL(string: "\(supabaseUrl)/functions/v1/capture") else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        for (k, v) in headers(token: token) { req.setValue(v, forHTTPHeaderField: k) }
        
        var body: [String: Any] = ["source": "ios_native"]
        if let url = url { body["url"] = url }
        if let text = text { body["text"] = text }
        if let title = title { body["title"] = title }
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let id = json["id"] as? String {
            return id
        }
        return UUID().uuidString
    }

    // MARK: - Sync: Remote Items & Collections Fetch
    public func fetchRemoteItems(userId: String, token: String?) async throws -> [RemoteItemDTO] {
        guard let url = URL(string: "\(supabaseUrl)/rest/v1/items?select=*&order=created_at.desc&limit=100") else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        for (k, v) in headers(token: token) { req.setValue(v, forHTTPHeaderField: k) }

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode([RemoteItemDTO].self, from: data)
    }

    public func fetchRemoteCollections(userId: String, token: String?) async throws -> [RemoteCollectionDTO] {
        guard let url = URL(string: "\(supabaseUrl)/rest/v1/collections?select=*&order=name.asc") else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        for (k, v) in headers(token: token) { req.setValue(v, forHTTPHeaderField: k) }

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode([RemoteCollectionDTO].self, from: data)
    }

    // MARK: - Dev Mode Mailpit Helper
    #if DEBUG
    public func fetchLatestMailpitOTP(for email: String) async -> String? {
        guard let url = URL(string: "\(mailpitUrl)/api/v1/messages") else { return nil }
        var req = URLRequest(url: url)
        req.timeoutInterval = 5
        guard let (data, response) = try? await session.data(for: req),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let messages = json["messages"] as? [[String: Any]] else {
            return nil
        }
        let cleanEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        for msg in messages {
            if let toList = msg["To"] as? [[String: Any]] {
                let matchesTo = toList.contains { ($0["Address"] as? String)?.lowercased() == cleanEmail }
                if matchesTo, let msgId = msg["ID"] as? String {
                    if let detailUrl = URL(string: "\(mailpitUrl)/api/v1/message/\(msgId)") {
                        var detailReq = URLRequest(url: detailUrl)
                        detailReq.timeoutInterval = 5
                        if let (detailData, detailResp) = try? await session.data(for: detailReq),
                           (detailResp as? HTTPURLResponse)?.statusCode == 200,
                           let detailJson = try? JSONSerialization.jsonObject(with: detailData) as? [String: Any] {
                            let text = (detailJson["Text"] as? String) ?? ""
                            let html = (detailJson["HTML"] as? String) ?? ""
                            let snippet = (msg["Snippet"] as? String) ?? ""
                            let combined = text + "\n" + html + "\n" + snippet
                            if let regex = try? NSRegularExpression(pattern: "\\b(\\d{8})\\b"),
                               let match = regex.firstMatch(in: combined, range: NSRange(combined.startIndex..., in: combined)),
                               let range = Range(match.range(at: 1), in: combined) {
                                return String(combined[range])
                            }
                        }
                    }
                }
            }
        }
        return nil
    }
    #endif
}
