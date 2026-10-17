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

extension LaterBoxAPIService {
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
