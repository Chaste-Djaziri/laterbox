// laterbox-ios/laterbox-ios/Views/Components/MainTabView.swift
import SwiftUI

/// Five primary destinations. Secondary mailboxes live inside the Library.
enum MainTab: String, CaseIterable, Identifiable {
    case inbox = "Inbox"
    case today = "Today"
    case kept = "Kept"
    case library = "Library"
    case settings = "Settings"

    var id: String { rawValue }

    /// Only the Inbox root owns the custom header; pushed details do not.
    var showsAppHeader: Bool { self == .inbox }

    var symbol: String {
        switch self {
        case .inbox: "tray.full"
        case .today: "calendar"
        case .kept: "checkmark.circle"
        case .library: "square.stack"
        case .settings: "gearshape"
        }
    }
}

struct MainTabView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab: MainTab = .inbox

    var body: some View {
        TabView(selection: $selectedTab) {
            InboxView(isTabRoot: true)
                .tabItem { Label(MainTab.inbox.rawValue, systemImage: MainTab.inbox.symbol) }
                .tag(MainTab.inbox)

            ReturnsView(initialSegment: .today, isTabRoot: true)
                .tabItem { Label(MainTab.today.rawValue, systemImage: MainTab.today.symbol) }
                .tag(MainTab.today)

            InboxView(initialMailbox: .kept, isTabRoot: true)
                .tabItem { Label(MainTab.kept.rawValue, systemImage: MainTab.kept.symbol) }
                .tag(MainTab.kept)

            LibraryView()
                .tabItem { Label(MainTab.library.rawValue, systemImage: MainTab.library.symbol) }
                .tag(MainTab.library)

            NavigationStack {
                SettingsView(isTabRoot: true)
            }
            .tabItem { Label(MainTab.settings.rawValue, systemImage: MainTab.settings.symbol) }
            .tag(MainTab.settings)
        }
        .tint(InboxAppearance.textPrimary(for: colorScheme))
        .toolbarBackground(InboxAppearance.background(for: colorScheme), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .accessibilityIdentifier("LaterBox Main Tabs")
        .background(InboxAppearance.background(for: colorScheme).ignoresSafeArea())
    }
}
