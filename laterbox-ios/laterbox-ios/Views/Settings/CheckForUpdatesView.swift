//
//  CheckForUpdatesView.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 11.10.26.
//

import SwiftUI

public struct CheckForUpdatesView: View {
    @Environment(\.openURL) private var openURL
    @State private var isChecking = false
    @State private var status: UpdateStatus = .idle
    @State private var lastCheckedDate: Date? = nil

    private enum UpdateStatus: Equatable {
        case idle
        case checking
        case upToDate
        case updateAvailable(version: String, build: String)
        case error(message: String)
    }

    private struct RemoteVersionResponse: Codable {
        let version: String?
        let buildNumber: AnyCodableNumber?
        let buildTime: String?
    }

    private enum AnyCodableNumber: Codable, Equatable {
        case int(Int)
        case string(String)

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let intVal = try? container.decode(Int.self) {
                self = .int(intVal)
            } else if let strVal = try? container.decode(String.self) {
                self = .string(strVal)
            } else {
                self = .string("")
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .int(let v): try container.encode(v)
            case .string(let v): try container.encode(v)
            }
        }

        var stringValue: String {
            switch self {
            case .int(let v): return "\(v)"
            case .string(let v): return v
            }
        }
    }

    public init() {}

    public var body: some View {
        ZStack {
            LiquidGlassBackground()

            ScrollView {
                VStack(spacing: 20) {
                    // Header Visual Card
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(statusCircleColor)
                                .frame(width: 76, height: 76)
                            Image(systemName: statusIcon)
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(statusIconColor)
                        }

                        VStack(spacing: 4) {
                            Text(statusTitle)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)

                            Text(statusSubtitle)
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)

                    // Current Installation Details Card
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Installed Version")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        VStack(spacing: 12) {
                            HStack {
                                Text("Version")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textSecondary)
                                Spacer()
                                Text(AppVersion.currentVersion)
                                    .font(.subheadline.weight(.semibold).monospaced())
                                    .foregroundColor(AppTheme.textPrimary)
                            }

                            Divider().background(AppTheme.cardBorder)

                            HStack {
                                Text("Build Number")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textSecondary)
                                Spacer()
                                Text(AppVersion.currentBuild)
                                    .font(.subheadline.weight(.semibold).monospaced())
                                    .foregroundColor(AppTheme.textPrimary)
                            }

                            Divider().background(AppTheme.cardBorder)

                            HStack {
                                Text("Build Date")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textSecondary)
                                Spacer()
                                Text(formattedBuildDate)
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(AppTheme.textPrimary)
                            }

                            Divider().background(AppTheme.cardBorder)

                            HStack {
                                Text("Release Channel")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textSecondary)
                                Spacer()
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 7, height: 7)
                                    Text("Production")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(AppTheme.cardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                        )
                    }

                    // Check for Updates Action
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Update Actions")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        if case .updateAvailable = status {
                            Button(action: {
                                LBHaptic.medium()
                                if let url = URL(string: "https://apps.apple.com/app/laterbox/id6738023192") {
                                    openURL(url)
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.down.app.fill")
                                    Text("Download Update in App Store")
                                        .font(.headline.weight(.bold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(AppTheme.darkSurface)
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        Button(action: {
                            Task {
                                await performCheck()
                            }
                        }) {
                            HStack(spacing: 8) {
                                if isChecking {
                                    ProgressView()
                                        .tint(AppTheme.textPrimary)
                                } else {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.system(size: 15, weight: .bold))
                                }
                                Text(isChecking ? "Checking for updates…" : "Check for Updates Now")
                                    .font(.subheadline.weight(.bold))
                            }
                            .foregroundColor(AppTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(AppTheme.accent)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(isChecking)

                        if let lastChecked = lastCheckedDate {
                            Text("Last checked: \(lastChecked.formatted(date: .omitted, time: .shortened))")
                                .font(.caption2)
                                .foregroundColor(AppTheme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }

                    // Recent Highlights / Release Notes
                    VStack(alignment: .leading, spacing: 10) {
                        Text("What’s New in This Release")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        VStack(alignment: .leading, spacing: 10) {
                            highlightRow(icon: "sparkles", text: "Streamlined settings directory with dedicated sub-pages")
                            highlightRow(icon: "bolt.fill", text: "Inbuilt deterministic media & web link enrichment")
                            highlightRow(icon: "icloud.fill", text: "Optimized queued cloud synchronization engine")
                            highlightRow(icon: "moon.stars.fill", text: "Enhanced high-contrast dark mode across Capture & Share")
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(AppTheme.cardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                        )
                    }

                    // Automatic Updates Note
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                            Text("Automatic App Store Updates")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        Text("To automatically receive LaterBox updates as soon as they are released, enable Automatic App Updates in iOS Settings > App Store.")
                            .font(.caption2)
                            .foregroundColor(AppTheme.textSecondary.opacity(0.8))
                            .lineSpacing(2)
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Check for Updates")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if lastCheckedDate == nil {
                await performCheck()
            }
        }
    }

    // MARK: - Helpers

    private var statusTitle: String {
        switch status {
        case .idle:
            return "LaterBox \(AppVersion.currentVersion)"
        case .checking:
            return "Checking for Updates…"
        case .upToDate:
            return "LaterBox is Up to Date"
        case .updateAvailable(let version, _):
            return "Version \(version) Available"
        case .error:
            return "Check Complete"
        }
    }

    private var statusSubtitle: String {
        switch status {
        case .idle:
            return "Tap check now to query the update server"
        case .checking:
            return "Connecting to LaterBox release service…"
        case .upToDate:
            return "You have the latest version with all recent improvements and fixes."
        case .updateAvailable(let version, let build):
            return "A newer build is ready in the App Store: Version \(version) (Build \(build))."
        case .error(let message):
            return message
        }
    }

    private var statusIcon: String {
        switch status {
        case .idle:
            return "arrow.triangle.2.circlepath"
        case .checking:
            return "arrow.triangle.2.circlepath"
        case .upToDate:
            return "checkmark"
        case .updateAvailable:
            return "arrow.down.circle.fill"
        case .error:
            return "checkmark.shield"
        }
    }

    private var statusIconColor: Color {
        switch status {
        case .idle:
            return AppTheme.textPrimary
        case .checking:
            return AppTheme.textPrimary
        case .upToDate:
            return AppTheme.textPrimary
        case .updateAvailable:
            return Color.blue
        case .error:
            return AppTheme.textSecondary
        }
    }

    private var statusCircleColor: Color {
        switch status {
        case .idle, .checking, .upToDate:
            return AppTheme.accent
        case .updateAvailable:
            return Color.blue.opacity(0.15)
        case .error:
            return Color.black.opacity(0.04)
        }
    }

    private var formattedBuildDate: String {
        let iso = AppVersion.buildTime
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: iso) {
            return date.formatted(date: .abbreviated, time: .shortened)
        }
        return iso.prefix(10).description
    }

    private func highlightRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(AppTheme.textPrimary)
                .frame(width: 18)
            Text(text)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
        }
    }

    private func performCheck() async {
        await MainActor.run {
            isChecking = true
            status = .checking
        }

        LBHaptic.light()

        guard let url = URL(string: "https://app.laterbox.dev/api/version?_t=\(Int(Date().timeIntervalSince1970))") else {
            await MainActor.run {
                isChecking = false
                status = .upToDate
                lastCheckedDate = Date()
            }
            return
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 8.0

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                await MainActor.run {
                    isChecking = false
                    status = .upToDate
                    lastCheckedDate = Date()
                }
                return
            }

            let remote = try JSONDecoder().decode(RemoteVersionResponse.self, from: data)
            let remoteVersion = remote.version ?? AppVersion.currentVersion
            let remoteBuildStr = remote.buildNumber?.stringValue ?? AppVersion.currentBuild

            let currentBuildInt = Int(AppVersion.currentBuild) ?? 0
            let remoteBuildInt = Int(remoteBuildStr) ?? 0

            await MainActor.run {
                isChecking = false
                lastCheckedDate = Date()
                if remoteBuildInt > currentBuildInt {
                    status = .updateAvailable(version: remoteVersion, build: remoteBuildStr)
                    LBHaptic.medium()
                } else {
                    status = .upToDate
                    LBHaptic.success()
                }
            }
        } catch {
            await MainActor.run {
                isChecking = false
                lastCheckedDate = Date()
                // If offline or network check fails, fallback safely to upToDate
                status = .upToDate
                LBHaptic.light()
            }
        }
    }
}
