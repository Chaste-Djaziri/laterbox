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
    let onPlans: () -> Void

    @ObservedObject private var theme = MacAppearanceSettings.shared
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

    private enum Section: String, CaseIterable, Identifiable {
        case account = "Account & security"
        case appearance = "Appearance"
        case privacy = "Privacy"
        case sync = "Cloud sync"
        case data = "Data management"
        case shortcuts = "Shortcuts"
        case about = "About & updates"
        var id: String { rawValue }
        var symbol: String {
            switch self {
            case .account: "person.crop.circle"
            case .appearance: "paintpalette"
            case .privacy: "hand.raised"
            case .sync: "icloud"
            case .data: "externaldrive"
            case .shortcuts: "keyboard"
            case .about: "info.circle"
            }
        }
        var subtitle: String {
            switch self {
            case .account: "Your identity, linked sign-ins, and subscription"
            case .appearance: "System, Light, and Dark modes"
            case .privacy: "Preview artwork and data protections"
            case .sync: "Connection health and refresh preferences"
            case .data: "Export a readable copy of your library"
            case .shortcuts: "Keyboard commands on this Mac"
            case .about: "Version, updates, and legal information"
            }
        }
    }

    @State private var selectedSection: Section?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 17) {
                HStack(spacing: 12) {
                    if selectedSection != nil {
                        Button {
                            withAnimation(.easeInOut(duration: 0.18)) { selectedSection = nil }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                                .frame(width: 36, height: 36)
                                .background(surface, in: Circle())
                        }
                        .buttonStyle(.plain)
                        .help("Back to Settings")
                        .accessibilityIdentifier("mac.settings.back")
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedSection?.rawValue ?? "Settings")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                        Text(selectedSection?.subtitle ?? "Make LaterBox work your way on this Mac.")
                            .font(.system(size: 12)).foregroundStyle(secondary)
                    }
                    Spacer()
                    if cloud.loading { ProgressView().controlSize(.small) }
                    else {
                        Circle()
                            .fill(cloud.lastError == nil && cloud.isConnected ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                            .help(cloud.isConnected ? "Cloud connected" : "Offline")
                    }
                }
                .padding(.vertical, 5)

                if let section = selectedSection {
                    sectionDetail(section)
                } else {
                    settingsOverview
                }
            }
            .frame(maxWidth: 820)
            .frame(maxWidth: .infinity)
            .padding(23)
        }
        .confirmationDialog("Sign out of LaterBox?", isPresented: $showSignOutConfirmation) {
            Button("Sign out", role: .destructive, action: onSignOut)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This signs you out on this Mac. Cloud items and account data are not deleted.")
        }
    }

    private var settingsOverview: some View {
        VStack(alignment: .leading, spacing: 17) {
            Button {
                openSection(.account)
            } label: { accountCard }
                .buttonStyle(.plain)
            groupHeading("ACCOUNT")
            settingsCard {
                sectionRow(.account)
                itemDivider
                Button(action: onPlans) {
                    rowContent("Plans & billing", icon: "crown",
                               detail: "Compare storage plans and manage your subscription")
                }
                .buttonStyle(.plain)
            }
            groupHeading("PREFERENCES & PRIVACY")
            settingsCard {
                sectionRow(.appearance)
                itemDivider
                sectionRow(.privacy)
            }
            groupHeading("CLOUD & LIBRARY")
            settingsCard {
                sectionRow(.sync)
                itemDivider
                sectionRow(.data)
            }
            groupHeading("SYSTEM & ABOUT")
            settingsCard {
                sectionRow(.shortcuts)
                itemDivider
                sectionRow(.about)
                itemDivider
                Button(action: onHelp) {
                    rowContent("Help & FAQ", icon: "questionmark.circle",
                               detail: "Answers, reports, and your support requests")
                }
                .buttonStyle(.plain)
            }
            signOutButton
        }
    }

    private func openSection(_ section: Section) {
        withAnimation(.easeInOut(duration: 0.18)) { selectedSection = section }
    }

    private func sectionRow(_ section: Section) -> some View {
        Button { openSection(section) } label: {
            rowContent(section.rawValue, icon: section.symbol, detail: section.subtitle)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("mac.settings." + section.rawValue.lowercased().replacingOccurrences(of: " ", with: "-"))
    }

    @ViewBuilder
    private func sectionDetail(_ section: Section) -> some View {
        switch section {
        case .account: accountSettings
        case .appearance: appearanceSettings
        case .privacy: privacySettings
        case .sync: syncSettings
        case .data: dataSettings
        case .shortcuts: shortcutsSettings
        case .about: aboutSettings
        }
    }

    private var accountSettings: some View {
        VStack(alignment: .leading, spacing: 16) {
            accountCard
            groupHeading("ACCOUNT DETAILS")
            settingsCard {
                valueRow("Signed-in email", value: accountEmail)
                itemDivider
                valueRow("Account status", value: cloud.isConnected ? "Cloud connected" : "Connection unavailable")
            }
            groupHeading("MANAGE YOUR ACCOUNT")
            settingsCard {
                linkRow("Sign-in methods & security", icon: "person.badge.key",
                        detail: "Password, linked identities and account details",
                        link: "https://laterbox.dev/settings/account")
                itemDivider
                Button(action: onPlans) {
                    rowContent("Plans & billing", icon: "crown",
                               detail: "View storage plans and current subscription")
                }
                .buttonStyle(.plain)
                itemDivider
                linkRow("Delete account", icon: "person.crop.circle.badge.xmark",
                        detail: "Review permanent deletion options on Web",
                        link: "https://laterbox.dev/settings/account")
            }
            Text("Sensitive account and billing changes are completed securely in your browser. This Mac uses your existing signed-in session for synchronization.")
                .font(.system(size: 12)).foregroundStyle(secondary)
            signOutButton
        }
    }

    private var appearanceSettings: some View {
        VStack(alignment: .leading, spacing: 16) {
            settingsCard {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Choose your appearance").font(.system(size: 16, weight: .bold))
                    Text("Applies immediately to the entire Mac app, including popups and sign-in.")
                        .font(.system(size: 12)).foregroundStyle(secondary)
                    HStack(spacing: 12) {
                        appearanceOption("System", value: "system", symbol: "macwindow",
                                         caption: "Match macOS")
                        appearanceOption("Light", value: "light", symbol: "sun.max",
                                         caption: "Bright interface")
                        appearanceOption("Dark", value: "dark", symbol: "moon.stars",
                                         caption: "Graphite interface")
                    }
                }
                .padding(19)
            }
            groupHeading("PREVIEW DISPLAY")
            settingsCard {
                toggleRow("Show website preview images", icon: "photo",
                          detail: "Show OG artwork in saved-item lists", value: $showPreviews)
            }
        }
    }

    private func appearanceOption(_ title: String, value: String, symbol: String, caption: String) -> some View {
        let selected = theme.mode == value
        return Button {
            theme.mode = value
        } label: {
            VStack(spacing: 11) {
                Image(systemName: symbol)
                    .font(.system(size: 27, weight: .light))
                    .frame(height: 43)
                Text(title).font(.system(size: 14, weight: .bold))
                Text(caption)
                    .font(.system(size: 11))
                    .foregroundStyle(selected ? Color.black.opacity(0.68) : secondary)
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(selected ? Color.black : (dark ? Color.white : Color.black))
            .frame(maxWidth: .infinity)
            .frame(height: 139)
            .background(selected ? lime : Color.primary.opacity(0.045),
                        in: RoundedRectangle(cornerRadius: 15))
            .overlay(RoundedRectangle(cornerRadius: 15).strokeBorder(selected ? lime : stroke, lineWidth: selected ? 2 : 1))
            .contentShape(RoundedRectangle(cornerRadius: 15))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
        .accessibilityIdentifier("mac.settings.appearance." + value)
    }

    private var privacySettings: some View {
        VStack(alignment: .leading, spacing: 15) {
            groupHeading("PREVIEW PRIVACY")
            settingsCard {
                toggleRow("Load link preview images", icon: "photo",
                          detail: "Allow website preview images to appear in tables", value: $showPreviews)
            }
            Text("Disabling preview images hides website artwork in the item table. It does not delete stored previews or stop all metadata enrichment.")
                .font(.system(size: 12)).foregroundStyle(secondary)
            groupHeading("DATA & SECURITY")
            settingsCard {
                linkRow("Privacy policy", icon: "hand.raised",
                        detail: "How LaterBox protects your account and content",
                        link: "https://laterbox.dev/privacy")
                itemDivider
                linkRow("Account security", icon: "lock.shield",
                        detail: "Manage credentials and connected sign-in providers",
                        link: "https://laterbox.dev/settings/account")
                itemDivider
                Button {
                    open("x-apple.systempreferences:com.apple.preference.notifications")
                } label: {
                    rowContent("macOS notification permissions", icon: "bell",
                               detail: "Manage LaterBox's notification access in System Settings")
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var syncSettings: some View {
        VStack(alignment: .leading, spacing: 15) {
            groupHeading("SYNCHRONIZATION")
            settingsCard {
                toggleRow("Automatic cloud refresh", icon: "arrow.triangle.2.circlepath.icloud",
                          detail: "Check for changes periodically and when the Mac app becomes active", value: $automaticRefresh)
                itemDivider
                HStack(spacing: 12) {
                    settingIcon("icloud")
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cloud sync").font(.system(size: 13, weight: .semibold))
                        Text(syncDescription).font(.system(size: 11)).foregroundStyle(secondary)
                    }
                    Spacer()
                    Button {
                        Task { await cloud.refresh() }
                    } label: {
                        if cloud.loading { ProgressView().controlSize(.small) }
                        else { Label("Sync now", systemImage: "arrow.clockwise") }
                    }
                    .buttonStyle(.bordered)
                    .disabled(cloud.loading)
                }
                .padding(15)
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
            Text("Cloud data is synchronized using your signed-in account. Manual sync always remains available.")
                .font(.system(size: 12)).foregroundStyle(secondary)
        }
    }

    private var dataSettings: some View {
        VStack(alignment: .leading, spacing: 16) {
            groupHeading("EXPORT")
            settingsCard {
                HStack(spacing: 12) {
                    settingIcon("square.and.arrow.up")
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Export loaded cloud items").font(.system(size: 13, weight: .semibold))
                        Text("Create a readable JSON copy of currently loaded items, tags and collections")
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
                    .font(.system(size: 12)).foregroundStyle(.green)
            }
            if let exportError {
                Label(exportError, systemImage: "exclamationmark.triangle")
                    .font(.system(size: 12)).foregroundStyle(.red)
            }
            groupHeading("LIBRARY MANAGEMENT")
            settingsCard {
                valueRow("Active items", value: "\(cloud.allItems.count)")
                itemDivider
                valueRow("Recently deleted items", value: "\(cloud.deletedItems.count)")
                itemDivider
                valueRow("Collections", value: "\(cloud.collections.count)")
                itemDivider
                linkRow("Manage cloud storage", icon: "externaldrive",
                        detail: "Quota, usage, and subscription capacity",
                        link: "https://laterbox.dev/settings/sync")
            }
            Text("Exports are not encrypted or directly restorable. Choose a private storage location. This action does not delete or modify your cloud library.")
                .font(.system(size: 12)).foregroundStyle(secondary)
        }
    }

    private var shortcutsSettings: some View {
        VStack(alignment: .leading, spacing: 15) {
            groupHeading("GLOBAL SHORTCUT")
            settingsCard {
                shortcutRow("Open Quick Capture", keys: "⌘ ⌥ N", icon: "square.and.pencil")
            }
            Text("Open Quick Capture over other apps, including full-screen windows. LaterBox must be running in the background; quitting the app disables the shortcut until you launch it again.")
                .font(.system(size: 12))
                .foregroundStyle(secondary)
                .padding(.horizontal, 12)
            groupHeading("IN-APP SHORTCUTS")
            settingsCard {
                shortcutRow("Quick save", keys: "⌘ N", icon: "plus")
                itemDivider
                shortcutRow("Focus search", keys: "⌘ K", icon: "magnifyingglass")
            }
        }
    }

    private var aboutSettings: some View {
        VStack(alignment: .leading, spacing: 15) {
            settingsCard {
                HStack(spacing: 12) {
                    settingIcon("info.circle")
                    VStack(alignment: .leading, spacing: 4) {
                        Text("LaterBox for macOS").font(.system(size: 14, weight: .bold))
                        Text("Version \(version) · macOS \(ProcessInfo.processInfo.operatingSystemVersion.majorVersion)")
                            .font(.system(size: 11)).foregroundStyle(secondary)
                    }
                    Spacer()
                    Button("Check for updates") { open("https://laterbox.dev/download") }
                        .buttonStyle(.bordered)
                }
                .padding(15)
                itemDivider
                linkRow("Terms of service", icon: "doc.text",
                        detail: "LaterBox terms and conditions",
                        link: "https://laterbox.dev/terms")
                itemDivider
                linkRow("Privacy policy", icon: "hand.raised",
                        detail: "How data is handled and secured",
                        link: "https://laterbox.dev/privacy")
            }
        }
    }

    private func valueRow(_ name: String, value: String) -> some View {
        HStack(spacing: 12) {
            Text(name).font(.system(size: 13, weight: .medium))
            Spacer()
            Text(value).font(.system(size: 12, weight: .semibold))
                .foregroundStyle(secondary)
                .lineLimit(2)
                .multilineTextAlignment(.trailing)
        }
        .padding(17)
    }

    private var signOutButton: some View {
        Button(role: .destructive) {
            showSignOutConfirmation = true
        } label: {
            rowContent("Sign out of this Mac", icon: "rectangle.portrait.and.arrow.right",
                       detail: "Disconnect this device without deleting cloud items")
                .background(surface, in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(stroke))
        }
        .buttonStyle(.plain)
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
