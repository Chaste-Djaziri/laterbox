// laterbox-ios/laterbox-ios/Services/PlatformMaintenanceManager.swift
import Foundation
import SwiftUI
import Combine

/// Real-time client manager that tracks platform-wide maintenance mode set by admins.
/// Notifies users when web access is temporarily down and sync may experience delays,
/// running a live countdown action timer.
@MainActor
public final class PlatformMaintenanceManager: ObservableObject {
    public static let shared = PlatformMaintenanceManager()

    @Published public private(set) var isMaintenanceActive: Bool = false
    @Published public private(set) var isMaintenanceUpcoming: Bool = false
    @Published public private(set) var message: String = "We are improving LaterBox. Please check back shortly."
    @Published public private(set) var startsAt: Date? = nil
    @Published public private(set) var endsAt: Date? = nil
    @Published public private(set) var timeRemainingString: String = ""
    @Published public var isCollapsed: Bool = false

    private var pollTimer: AnyCancellable?
    private var clockTimer: AnyCancellable?
    private let session: URLSession

    private struct StatusResponse: Decodable {
        struct MaintenancePayload: Decodable {
            let state: String?
            let mode: String?
            let startsAt: String?
            let endsAt: String?
            let message: String?
        }
        let maintenance: MaintenancePayload?
        let serverTime: String?
    }

    private init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 8
        config.timeoutIntervalForResource = 12
        self.session = URLSession(configuration: config)

        startTimers()
        Task { await checkStatus() }
    }

    public func startTimers() {
        // Poll every 30 seconds for admin maintenance updates
        pollTimer = Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.checkStatus()
                }
            }

        // Live 1-second clock tick for countdown calculations
        clockTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateCountdown()
            }
    }

    public func checkStatus() async {
        guard let url = URL(string: "\(LaterBoxAPIService.shared.webUrl)/api/platform/status") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { return }

            if http.statusCode == 503 {
                // If platform status explicitly returns 503 Service Unavailable, treat as active maintenance
                self.isMaintenanceActive = true
                self.isMaintenanceUpcoming = false
                self.updateCountdown()
                return
            }

            guard (200...299).contains(http.statusCode) else { return }

            let decoder = JSONDecoder()
            let decoded = try decoder.decode(StatusResponse.self, from: data)

            guard let m = decoded.maintenance else {
                self.isMaintenanceActive = false
                self.isMaintenanceUpcoming = false
                return
            }

            let mode = m.mode?.lowercased() ?? "off"
            let now = Date()

            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let fallbackIso = ISO8601DateFormatter()
            fallbackIso.formatOptions = [.withInternetDateTime]

            let parseDate: (String?) -> Date? = { str in
                guard let str else { return nil }
                return iso.date(from: str) ?? fallbackIso.date(from: str)
            }

            let parsedStart = parseDate(m.startsAt)
            let parsedEnd = parseDate(m.endsAt)

            self.startsAt = parsedStart
            self.endsAt = parsedEnd
            if let customMsg = m.message, !customMsg.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                self.message = customMsg
            }

            if mode == "off" || (parsedEnd != nil && now >= parsedEnd!) {
                self.isMaintenanceActive = false
                self.isMaintenanceUpcoming = false
            } else if mode == "active" {
                self.isMaintenanceActive = true
                self.isMaintenanceUpcoming = false
            } else if mode == "scheduled" {
                if let start = parsedStart, now < start {
                    self.isMaintenanceUpcoming = true
                    self.isMaintenanceActive = false
                } else {
                    self.isMaintenanceActive = true
                    self.isMaintenanceUpcoming = false
                }
            } else {
                self.isMaintenanceActive = false
                self.isMaintenanceUpcoming = false
            }

            self.updateCountdown()
        } catch {
            // Keep existing state if offline or network drops
        }
    }

    private func updateCountdown() {
        let now = Date()

        if isMaintenanceUpcoming, let start = startsAt {
            let remaining = max(0, start.timeIntervalSince(now))
            timeRemainingString = format(seconds: Int(remaining))
            if remaining <= 0 {
                isMaintenanceUpcoming = false
                isMaintenanceActive = true
            }
            return
        }

        if isMaintenanceActive {
            if let end = endsAt {
                let remaining = max(0, end.timeIntervalSince(now))
                timeRemainingString = format(seconds: Int(remaining))
                if remaining <= 0 {
                    isMaintenanceActive = false
                    isMaintenanceUpcoming = false
                }
            } else {
                timeRemainingString = "In progress"
            }
            return
        }

        timeRemainingString = ""
    }

    private func format(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
}

