//
//  LaterBoxAPIService.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 04.10.26.
//

import Foundation

public struct RemoteItemDTO: Codable {
    public let id: String
    public let user_id: String?
    public let url: String?
    public let title: String?
    public let text_content: String?
    public let type: String?
    public let favorite: Bool?
    public let status: String?
    public let return_at: String?
    public let created_at: String?
    public let updated_at: String?
}

public struct RemoteCollectionDTO: Codable {
    public let id: String
    public let user_id: String?
    public let name: String
    public let created_at: String?
    public let updated_at: String?
}

public actor LaterBoxAPIService {
    public static let shared = LaterBoxAPIService()

    public let supabaseUrl = "https://ltjisrgldssqskcylcbj.supabase.co"
    public let anonKey = "sb_publishable_Rc4e_ik2LE4SR0UrfX-OEQ_5Mu_lw9p"
    public let webUrl = "https://laterbox.dev"

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
        guard let url = URL(string: "\(webUrl)/api/system-status") else {
            return ("Unknown", true)
        }
        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return ("Degraded", false)
            }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let status = json["status"] as? String {
                return (status.capitalized, status == "operational")
            }
            return ("Operational", true)
        } catch {
            return ("Offline", false)
        }
    }

    // MARK: - Auth: Email OTP / Magic Link
    public func sendEmailOTP(email: String) async throws -> Bool {
        guard let url = URL(string: "\(supabaseUrl)/auth/v1/otp") else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        for (k, v) in headers() { req.setValue(v, forHTTPHeaderField: k) }
        let body = ["email": email, "create_user": true] as [String : Any]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.userAuthenticationRequired)
        }
        return true
    }

    public func verifyOTP(email: String, token: String) async throws -> (accessToken: String, userId: String) {
        guard let url = URL(string: "\(supabaseUrl)/auth/v1/verify") else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        for (k, v) in headers() { req.setValue(v, forHTTPHeaderField: k) }
        let body: [String: Any] = [
            "type": "email",
            "email": email,
            "token": token
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.userAuthenticationRequired)
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let token = json["access_token"] as? String,
              let user = json["user"] as? [String: Any],
              let userId = user["id"] as? String else {
            throw URLError(.cannotParseResponse)
        }
        return (token, userId)
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
            if let boolVal = try? JSONSerialization.jsonObject(with: data) as? Bool {
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
}
