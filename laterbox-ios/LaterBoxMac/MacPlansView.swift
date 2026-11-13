// laterbox-ios/LaterBoxMac/MacPlansView.swift
import SwiftUI

/// App Store cloud-storage companion: show existing account status without
/// web checkout links, external purchase prompts, or in-app purchasing.
private struct MacAccountStorage: Decodable {
    let tier: String
    let provider: String?
    let status: String
    let storagePlanKey: String?
    let storageLimitBytes: Int64?
    let storageUsedBytes: Int64?
    let willCancel: Bool?
    let accessEndsAt: String?
}

struct MacPlansView: View {
    @ObservedObject var cloud: MacCloudSyncStore
    @Environment(\.colorScheme) private var scheme
    @State private var entitlement: MacAccountStorage?
    @State private var loading = true
    @State private var errorMessage: String?

    private let lime = Color(red: 230 / 255, green: 237 / 255, blue: 176 / 255)
    private let ink = Color(red: 23 / 255, green: 23 / 255, blue: 17 / 255)
    private var surface: Color {
        scheme == .dark ? Color(red: 38 / 255, green: 40 / 255, blue: 43 / 255) : .white
    }
    private var muted: Color { scheme == .dark ? .white.opacity(0.65) : .black.opacity(0.6) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 15) {
                    Image(systemName: "externaldrive.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(ink)
                        .frame(width: 60, height: 60)
                        .background(lime, in: RoundedRectangle(cornerRadius: 16))
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Cloud storage")
                            .font(.system(size: 27, weight: .bold, design: .rounded))
                        Text("Your LaterBox account and storage usage on this Mac.")
                            .font(.subheadline).foregroundStyle(muted)
                    }
                    Spacer()
                    Button {
                        Task { await refresh() }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .disabled(loading)
                    .accessibilityIdentifier("mac.storage.refresh")
                }

                if loading {
                    ProgressView("Checking account storage…")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .font(.subheadline).foregroundStyle(.orange)
                }
                if let entitlement {
                    VStack(alignment: .leading, spacing: 17) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("CURRENT PLAN")
                                    .font(.caption2.weight(.bold)).foregroundStyle(muted)
                                Text(planName(entitlement.storagePlanKey))
                                    .font(.title2.weight(.bold))
                                    .accessibilityIdentifier("mac.storage.currentPlan")
                            }
                            Spacer()
                            Image(systemName: "checkmark.seal.fill")
                                .font(.title2).foregroundStyle(ink)
                        }
                        if let used = entitlement.storageUsedBytes,
                           let limit = entitlement.storageLimitBytes, limit > 0 {
                            let fraction = min(1, max(0, Double(used) / Double(limit)))
                            GeometryReader { proxy in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.primary.opacity(0.1))
                                    Capsule().fill(ink).frame(width: proxy.size.width * fraction)
                                }
                            }
                            .frame(height: 9)
                            HStack {
                                Text("\(formatBytes(used)) used")
                                Spacer()
                                Text("\(formatBytes(limit)) total")
                            }
                            .font(.caption).foregroundStyle(muted)
                            if fraction >= 1 {
                                Label("Storage is full. Remove unused attachments to free space.",
                                      systemImage: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange).font(.subheadline)
                            }
                        } else {
                            Text("Storage usage is currently unavailable.")
                                .foregroundStyle(muted).font(.subheadline)
                        }
                        if entitlement.willCancel == true {
                            Text("Your existing subscription is scheduled to end.")
                                .font(.footnote).foregroundStyle(muted)
                        }
                    }
                    .padding(22)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(surface, in: RoundedRectangle(cornerRadius: 19))
                }

                VStack(alignment: .leading, spacing: 9) {
                    Text("Available with LaterBox")
                        .font(.headline)
                    Label("Save links, notes, and collections", systemImage: "checkmark")
                    Label("Search and organize your library", systemImage: "checkmark")
                    Label("Synchronize your account across devices", systemImage: "checkmark")
                    Text("Storage capacity is associated with your existing LaterBox account. This Mac app does not offer purchases.")
                        .font(.footnote).foregroundStyle(muted)
                        .padding(.top, 6)
                }
                .font(.subheadline)
                .padding(22)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(surface, in: RoundedRectangle(cornerRadius: 19))
            }
            .padding(25)
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
        .task { await refresh() }
    }

    private func refresh() async {
        loading = true
        errorMessage = nil
        defer { loading = false }
        do {
            let data = try await cloud.billingAPI("/entitlement")
            entitlement = try JSONDecoder().decode(MacAccountStorage.self, from: data)
        } catch {
            errorMessage = "Account storage could not be loaded. Try refreshing."
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    private func planName(_ key: String?) -> String {
        let base = (key ?? "free")
            .replacingOccurrences(of: "_month", with: "")
            .replacingOccurrences(of: "_year", with: "")
        let labels = [
            "free": "Free · 500 MB", "plus": "Plus · 10 GB",
            "plus50": "Plus 50 · 50 GB", "vault": "Vault · 100 GB",
            "vault250": "Vault · 250 GB", "vault500": "Vault · 500 GB",
            "vault1tb": "Vault · 1 TB", "vault2tb": "Vault · 2 TB"
        ]
        return labels[base] ?? base.capitalized
    }
}
