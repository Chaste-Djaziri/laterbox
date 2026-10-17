import Foundation

struct ServiceStatusSnapshot: Decodable, Sendable {
    let status: String
    let label: String
    let monitors: [ServiceMonitorStatus]
    let timestamp: String

    var refreshedAt: Date? { Self.date(timestamp) }
    static func date(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: value) ?? ISO8601DateFormatter().date(from: value)
    }
}

struct ServiceMonitorStatus: Decodable, Identifiable, Sendable {
    let id: String
    let name: String
    let status: String
    let label: String
    let lastCheckedAt: String?
    let checkFrequency: Int?

    var lastCheck: Date? { lastCheckedAt.flatMap(ServiceStatusSnapshot.date) }
}

struct ServiceUptimeHistory: Decodable, Sendable {
    let from: String
    let to: String
    let timeZone: String
    let unit: String
    let monitors: [MonitorUptimeHistory]
}

struct MonitorUptimeHistory: Decodable, Identifiable, Sendable {
    let id: String
    let availability: Double?
    let downtimeSeconds: Double?
    let buckets: [UptimeBucket]
}

struct UptimeBucket: Decodable, Identifiable, Sendable {
    var id: String { start }
    let start: String
    let end: String
    let availability: Double?
    let downtimeSeconds: Double
    var date: Date? { ServiceStatusSnapshot.date(start) }
}

extension LaterBoxAPIService {
    func fetchUptimeHistory(from: Date, to: Date, timeZone: String) async throws -> ServiceUptimeHistory {
        var components = URLComponents(string: "\(supabaseUrl)/functions/v1/system-status")!
        components.queryItems = [URLQueryItem(name: "history", value: "1"),
            URLQueryItem(name: "from", value: from.ISO8601Format()), URLQueryItem(name: "to", value: to.ISO8601Format()),
            URLQueryItem(name: "timeZone", value: timeZone)]
        guard let url = components.url else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.timeoutInterval = 60
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        return try JSONDecoder().decode(ServiceUptimeHistory.self, from: data)
    }

    func fetchServiceStatus() async throws -> ServiceStatusSnapshot {
        guard let url = URL(string: "\(supabaseUrl)/functions/v1/system-status") else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.timeoutInterval = 25
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        return try JSONDecoder().decode(ServiceStatusSnapshot.self, from: data)
    }
}
