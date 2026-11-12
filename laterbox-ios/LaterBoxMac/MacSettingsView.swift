// laterbox-ios/LaterBoxMac/MacSettingsView.swift
import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// macOS Settings in the grouped-card style of iOS Settings. Values which
/// affect only this Mac live in AppStorage; account actions use existing flows.
struct MacSettingsView: View {
    @ObservedObject var cloud: MacCloudSyncStore
    let accountEmail: String
    let onSignOut: () -> Void
    let onHelp: () -> Void

    @AppStorage("laterbox.mac.appearance") private var appearance = "system"
    @AppStorage("laterbox.mac.showLinkPreviews") private var showPreviews = true
    @AppStorage("laterbox.mac.automaticRefresh") private var automaticRefresh = true
    @Environment(\.colorScheme) private var scheme
    @State private var showSignOutConfirmation = false
    @State private var exporting = false
    @State private var exportError: String?
    @State private var exportSuccess: String?

    private let lime = Color(red: 230 / 255, green: 237 / 255, blue: 176 / 255)
    private var dark: Bool { scheme == .dark }
    private var surface: Color { dark ? Color(red: 38 / 255, green: 40 / 255, blue: 43 / 255) : .white }
    private var secondary: Color { dark ? Color.white.opacity(0.62) : Color.black.opacity(0.55) }
    private var stroke: Color { dark ? Color.white.opacity(0.10) : Color.black.opacity(0.09) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 17) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Settings")
                            .font(.system(size: 27, weight: .bold, design: .rounded))
                        Text("Make Laterbox work your way on this Mac.")
                            .font(.system(size: 12)).foregroundStyle(secondary)
                    }
                    Spacer()
                    HStack(spacing: 7) {
                        Circle().fill(cloud.lastError == nil && cloud.isConnected ? Color.green : Color.orange)
                            .frame(width: 7, height: 7)
                        Text(cloud.loading ? "Syncing" : (cloud.isConnected ? "Cloud connected" : "Offline"))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(secondary)
                    }
                }
                .padding(.vertical, 5)

                accountCard
                groupHeading("ACCOUNT & SUBSCRIPTION")
                settingsCard {
                    linkRow("Account & security", icon: "person.crop.circle",
                            detail: "Manage your sign-in, password and linked identities",
                            link: "https://laterbox.dev/settings/account")
                    itemDivider
                    linkRow("Plans & billing", icon: "crown",
                            detail: "Current subscription, payments and storage options",
                            link: "https://laterbox.dev/settings/billing")
                }

                groupHeading("PREFERENCES & PRIVACY")
                settingsCard {
                    HStack(spacing: 12) {
                        settingIcon("paintpalette")
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Appearance").font(.system(size: 13, weight: .semibold))
                            Text("Choose the app's color theme on this Mac")
                                .font(.system(size: 11)).foregroundStyle(secondary)
                        }
                        Spacer()
                        Picker("Appearance", selection: $appearance) {
                            Text("System").tag("system")
                            Text("Light").tag("light")
                            Text("Dark").tag("dark")
                        }
                        .labelsHidden()
                        .frame(width: 115)
                        .accessibilityLabel("Appearance")
                    }
                    .padding(15)
                    itemDivider
                    toggleRow("Show link preview images", icon: "photo",
                              detail: "Display website images beside saved items", value: $showPreviews)
                    itemDivider
                    linkRow("Privacy & data", icon: "hand.raised",
                            detail: "Read our privacy policy and data handling",
                            link: "https://laterbox.dev/privacy")
                    itemDivider
                    Button {
                        open("x-apple.systempreferences:com.apple.preference.notifications")
                    } label: {
                        rowContent("Notification permissions", icon: "bell",
                                   detail: "Manage this Mac's alerts in System Settings")
                    }
                    .buttonStyle(.plain)
                }

                groupHeading("CLOUD SYNC & DATA")
                settingsCard {
                    toggleRow("Automatic cloud refresh", icon: "arrow.triangle.2.circlepath.icloud",
                              detail: "Refresh your cloud items when this Mac is active", value: $automaticRefresh)
                    itemDivider
                    HStack(spacing: 12) {
                        settingIcon("icloud")
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Cloud sync").font(.system(size: 13, weight: .semibold))
                            Text(syncDescription)
                                .font(.system(size: 11))
                                .foregroundStyle(secondary)
                        }
                        Spacer()
                        Button {
                            Task { await cloud.refresh() }
                        } label: {
                            if cloud.loading {
                                ProgressView().controlSize(.small)
                            } else {
                                Label("Sync now", systemImage: "arrow.clockwise")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(cloud.loading)
                    }
                    .padding(15)
                    itemDivider
                    HStack(spacing: 12) {
                        settingIcon("square.and.arrow.up")
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Export cloud items").font(.system(size: 13, weight: .semibold))
                            Text("Save a readable JSON copy of loaded items and collections")
                                .font(.system(size: 11)).foregroundStyle(secondary)
                        }
                        Spacer()
                        Button("Export…") { exportLibrary() }
                            .buttonStyle(.bordered)
                            .disabled(exporting || !cloud.isConnected)
                    }
                    .padding(15)
                }
                if let exportSuccess {
                    Label(exportSuccess, systemImage: "checkmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.green)
                }
                if let exportError {
                    Label(exportError, systemImage: "exclamationmark.triangle")
                        .font(.system(size: 11))
                        .foregroundStyle(.red)
                }
                MacCloudSyncStatusView(
                    isConnected: cloud.isConnected,
                    isLoading: cloud.loading,
                    isSaving: cloud.saving,
                    lastError: cloud.lastError,
                    lastSynced: cloud.lastSynced,
                    lastPushed: cloud.lastPushed,
                    onCheckUpdates: { await cloud.refresh() }
                )

                groupHeading("KEYBOARD SHORTCUTS")
                settingsCard {
                    shortcutRow("Quick save", keys: "⌘ N", icon: "plus")
                    itemDivider
                    shortcutRow("Go to search", keys: "⌘ K", icon: "magnifyingglass")
                }

                groupHeading("SYSTEM & ABOUT")
                settingsCard {
                    HStack(spacing: 12) {
                        settingIcon("info.circle")
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Laterbox for macOS").font(.system(size: 13, weight: .semibold))
                            Text("Version \(version) · macOS \(ProcessInfo.processInfo.operatingSystemVersion.majorVersion)")
                                .font(.system(size: 11)).foregroundStyle(secondary)
                        }
                        Spacer()
                        Button("Check updates") {
                            open("https://laterbox.dev/download")
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(15)
                    itemDivider
                    Button(action: onHelp) {
                        rowContent("Help & FAQ", icon: "questionmark.circle",
                                   detail: "Answers, bug reports and support tickets")
                    }
                    .buttonStyle(.plain)
                    itemDivider
                    linkRow("Terms of Service", icon: "doc.text",
                            detail: "Read the Laterbox service terms",
                            link: "https://laterbox.dev/terms")
                }

                Button(role: .destructive) {
                    showSignOutConfirmation = true
                } label: {
                    HStack(spacing: 12) {
                        settingIcon("rectangle.portrait.and.arrow.right")
                        Text("Sign out of this Mac")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 10))
                    }
                    .padding(17)
                    .frame(maxWidth: .infinity)
                    .background(surface, in: RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(stroke))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Text("Appearance and preview preferences apply only to this Mac. Cloud data remains tied to your signed-in Laterbox account.")
                    .font(.system(size: 11))
                    .foregroundStyle(secondary)
                    .padding(.bottom, 10)
            }
            .frame(maxWidth: 840)
            .frame(maxWidth: .infinity)
            .padding(23)
        }
        .confirmationDialog("Sign out of Laterbox?", isPresented: $showSignOutConfirmation) {
            Button("Sign out", role: .destructive, action: onSignOut)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This signs you out on this Mac. Items stored in your cloud account are not deleted.")
        }
    }

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Development"
    }

    private var syncDescription: String {
        if let error = cloud.lastError, !error.isEmpty { return "Sync needs attention: \(error)" }
        guard let last = cloud.lastSynced else { return cloud.isConnected ? "Ready to synchronize" : "Cloud unavailable" }
        return "Last checked \(last.formatted(date: .abbreviated, time: .shortened))"
    }

    private var accountCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "person.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.black)
                .frame(width: 52, height: 52)
                .background(lime, in: RoundedRectangle(cornerRadius: 16))
            VStack(alignment: .leading, spacing: 4) {
                Text("ACCOUNT")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(secondary)
                Text(accountEmail.isEmpty ? "Signed in" : accountEmail)
                    .font(.system(size: 15, weight: .bold))
                    .lineLimit(1)
                Text("Cloud account · This Mac")
                    .font(.system(size: 11))
                    .foregroundStyle(secondary)
            }
            Spacer()
            Button {
                open("https://laterbox.dev/settings/account")
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 26, height: 38)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Manage account on Web")
        }
        .padding(17)
        .background(surface, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(stroke))
    }

    private func groupHeading(_ value: String) -> some View {
        Text(value)
            .font(.system(size: 10, weight: .bold))
            .tracking(1.25)
            .foregroundStyle(secondary)
            .padding(.leading, 12)
            .padding(.top, 4)
    }

    private var itemDivider: some View {
        Divider().overlay(stroke).padding(.leading, 60)
    }

    private func settingsCard<Content: View>(@ViewBuilder _ contents: () -> Content) -> some View {
        VStack(spacing: 0, content: contents)
            .background(surface, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(stroke))
    }

    private func settingIcon(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(dark ? Color.white : Color.black)
            .frame(width: 35, height: 35)
            .background(lime.opacity(dark ? 0.13 : 0.55), in: RoundedRectangle(cornerRadius: 10))
    }

    private func rowContent(_ title: String, icon: String, detail: String) -> some View {
        HStack(spacing: 12) {
            settingIcon(icon)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundStyle(secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(secondary)
        }
        .padding(15)
        .contentShape(Rectangle())
    }

    private func linkRow(_ title: String, icon: String, detail: String, link: String) -> some View {
        Button { open(link) } label: {
            rowContent(title, icon: icon, detail: detail)
        }
        .buttonStyle(.plain)
    }

    private func toggleRow(_ title: String, icon: String, detail: String, value: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            settingIcon(icon)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundStyle(secondary)
            }
            Spacer()
            Toggle(title, isOn: value)
                .labelsHidden()
                .tint(lime)
        }
        .padding(15)
    }

    private func shortcutRow(_ label: String, keys: String, icon: String) -> some View {
        HStack(spacing: 12) {
            settingIcon(icon)
            Text(label).font(.system(size: 13, weight: .semibold))
            Spacer()
            Text(keys)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(secondary)
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 7))
        }
        .padding(15)
    }

    private func open(_ link: String) {
        if let url = URL(string: link) { NSWorkspace.shared.open(url) }
    }

    private func exportLibrary() {
        exportError = nil
        exportSuccess = nil
        guard cloud.isConnected else {
            exportError = "Sync your cloud items before exporting."
            return
        }
        exporting = true
        defer { exporting = false }
        let all = cloud.allItems + cloud.deletedItems
        let collectionRows = cloud.collections.map { collection in
            ["id": collection.id, "name": collection.name]
        }
        let itemRows: [[String: Any]] = all.map { item in
            [
                "id": item.id,
                "title": item.title,
                "url": item.url?.absoluteString ?? "",
                "text": item.snippet,
                "type": item.itemType,
                "status": item.lifecycleStatus,
                "starred": item.isStarred,
                "created_at": ISO8601DateFormatter().string(from: item.date),
                "collections": item.collectionNames,
                "tags": item.tags
            ]
        }
        let payload: [String: Any] = [
            "format": "laterbox-macos-readable-export",
            "exported_at": ISO8601DateFormatter().string(from: Date()),
            "items": itemRows,
            "collections": collectionRows
        ]
        do {
            let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
            let panel = NSSavePanel()
            panel.nameFieldStringValue = "Laterbox-Export.json"
            panel.allowedContentTypes = [.json]
            panel.canCreateDirectories = true
            guard panel.runModal() == .OK, let destination = panel.url else { return }
            try data.write(to: destination, options: .atomic)
            exportSuccess = "Export saved to \(destination.lastPathComponent). This JSON is a readable copy, not an importable backup."
        } catch {
            exportError = error.localizedDescription
        }
    }
}
