// laterbox-ios/laterbox-ios/Views/Components/MainTabView.swift
import SwiftUI

/// Five primary destinations. Secondary mailboxes live inside the Library.
enum MainTab: String, CaseIterable, Identifiable {
    case inbox = "Inbox"
    case today = "Today"
    case library = "Library"
    case earn = "Earn"
    case settings = "Settings"

    var id: String { rawValue }

    /// Only the Inbox root owns the custom header; pushed details do not.
    var showsAppHeader: Bool { self == .inbox }

    var symbol: String {
        switch self {
        case .inbox: "tray.full"
        case .today: "calendar"
        case .library: "square.stack"
        case .earn: "dollarsign.circle"
        case .settings: "gearshape"
        }
    }
}

struct MainTabView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab: MainTab = .inbox
    @ObservedObject private var coordinator = SyncCoordinator.shared

    var body: some View {
        TabView(selection: $selectedTab) {
            InboxView(isTabRoot: true, quickCaptureRequested: $coordinator.showingQuickCapture)
                .tabItem { Label(MainTab.inbox.rawValue, systemImage: MainTab.inbox.symbol) }
                .tag(MainTab.inbox)

            ReturnsView(initialSegment: .today, isTabRoot: true)
                .tabItem { Label(MainTab.today.rawValue, systemImage: MainTab.today.symbol) }
                .tag(MainTab.today)

            LibraryView()
                .tabItem { Label(MainTab.library.rawValue, systemImage: MainTab.library.symbol) }
                .tag(MainTab.library)

            EarnView()
                .tabItem { Label(MainTab.earn.rawValue, systemImage: MainTab.earn.symbol) }
                .tag(MainTab.earn)

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
        .background(InboxGrainBackground().ignoresSafeArea())
        .onChange(of: selectedTab) { previous, current in
            // Feedback for user-driven tab navigation, not automatic Quick Save routing.
            if previous != current && !coordinator.showingQuickCapture {
                LBHaptic.light()
            }
        }
        .onChange(of: coordinator.showingQuickCapture) { _, requested in
            if requested { selectedTab = .inbox }
        }
        .onAppear {
            if coordinator.showingQuickCapture { selectedTab = .inbox }
        }
    }
}
