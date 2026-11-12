// laterbox-ios/LaterBoxMac/MacCloudSyncStatusView.swift
import SwiftUI

/// A native dashboard footer that reflects actual Supabase traffic.
/// All saves/edits are sent immediately; Check Updates downloads remote changes.
/// There is no offline upload queue yet, so never claim an offline push succeeded.
struct MacCloudSyncStatusView: View {
    let isConnected: Bool
    let isLoading: Bool
    let isSaving: Bool
    let lastError: String?
    let lastSynced: Date?
    let lastPushed: Date?
    let onCheckUpdates: () async -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var dark: Bool { colorScheme == .dark }
    private var busy: Bool { isLoading || isSaving }
    private var hasError: Bool { lastError != nil }
    private var synced: Bool {
        isConnected && lastSynced != nil && !busy && !hasError
    }
    private var accent: Color { Color(red: 230 / 255, green: 237 / 255, blue: 176 / 255) }
    private var background: Color {
        dark ? Color(red: 38 / 255, green: 40 / 255, blue: 43 / 255) : .white
    }
    private var border: Color {
        dark ? .white.opacity(0.12) : Color(red: 228 / 255, green: 224 / 255, blue: 213 / 255)
    }
    private var ink: Color { dark ? .white : Color(red: 23 / 255, green: 23 / 255, blue: 17 / 255) }
    private var muted: Color { dark ? .white.opacity(0.6) : Color(red: 112 / 255, green: 111 / 255, blue: 103 / 255) }

    private var stateTitle: String {
        if isSaving { return "PUSHING" }
        if isLoading { return "SYNCING" }
        if hasError { return "SYNC ISSUE" }
        if synced { return "SYNCED" }
        return "NOT CONNECTED"
    }

    private var stateSymbol: String {
        if isSaving { return "arrow.up.circle" }
        if isLoading { return "arrow.triangle.2.circlepath" }
        if hasError { return "exclamationmark.circle" }
        if synced { return "checkmark.circle" }
        return "icloud.slash"
    }

    private var detailText: String {
        if isSaving { return "Uploading your latest changes…" }
        if isLoading { return "Checking for changes across devices…" }
        if let lastError { return lastError }
        if let lastSynced {
            if let lastPushed, lastPushed > lastSynced {
                return "Changes uploaded · Checking for newer items"
            }
            return "Changes saved to cloud · Updated \(lastSynced.formatted(date: .omitted, time: .shortened))"
        }
        return "Save to upload · Check Updates to download"
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: hasError ? "icloud.slash" : "icloud")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(ink)
                .frame(width: 36, height: 36)
                .background(accent, in: Circle())
                .accessibilityHidden(true)

            Text("Cloud Sync")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(ink)
                .lineLimit(1)

            Label(stateTitle, systemImage: stateSymbol)
                .font(.system(size: 10, weight: .bold))
                .tracking(0.35)
                .foregroundStyle(hasError ? (dark ? Color.orange : Color(red: 132 / 255, green: 78 / 255, blue: 26 / 255)) : Color(red: 23 / 255, green: 23 / 255, blue: 17 / 255))
                .padding(.horizontal, 10)
                .frame(height: 25)
                .background(hasError ? Color.orange.opacity(0.20) : accent, in: Capsule())
                .accessibilityLabel("Cloud sync status: \(stateTitle)")

            Text("·")
                .foregroundStyle(muted)

            Text(detailText)
                .font(.system(size: 12))
                .foregroundStyle(muted)
                .lineLimit(1)
                .truncationMode(.tail)
                .help(detailText)

            Spacer(minLength: 8)

            Button {
                Task { await onCheckUpdates() }
            } label: {
                HStack(spacing: 8) {
                    if busy {
                        ProgressView()
                            .controlSize(.small)
                            .scaleEffect(0.75)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    Text(busy ? "Syncing…" : "Check Updates")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(ink)
                .padding(.horizontal, 14)
                .frame(height: 33)
                .background(
                    dark ? Color.white.opacity(0.1) : Color(red: 237 / 255, green: 233 / 255, blue: 224 / 255),
                    in: Capsule()
                )
            }
            .buttonStyle(.plain)
            .disabled(busy)
            .help("Download the latest cloud items. Local saves upload automatically.")
            .accessibilityIdentifier("mac.inbox.checkUpdates")
        }
        .padding(.horizontal, 18)
        .frame(height: 64)
        .background(background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(border)
                .allowsHitTesting(false)
        }
    }
}
