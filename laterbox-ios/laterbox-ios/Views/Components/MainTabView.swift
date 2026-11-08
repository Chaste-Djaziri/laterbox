// laterbox-ios/laterbox-ios/Views/Components/MainTabView.swift
import SwiftUI

/// Five primary destinations. Secondary mailboxes live in More and in the Library.
enum MainTab: String, CaseIterable, Identifiable {
    case inbox = "Inbox"
    case today = "Today"
    case kept = "Kept"
    case library = "Library"
    case settings = "Settings"

    var id: String { rawValue }

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
    @State private var selectedTab: MainTab = .inbox
    @State private var secondaryMailbox: MailboxViewType?
    @State private var showingCapture = false
    @State private var logoReplayToken = 0

    var body: some View {
        VStack(spacing: 0) {
            appHeader

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
            .tint(AppTheme.textPrimary)
            .toolbarBackground(AppTheme.canvasBackground, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .accessibilityIdentifier("LaterBox Main Tabs")
        }
        .background(AppTheme.canvasBackground.ignoresSafeArea())
        .fullScreenCover(isPresented: $showingCapture) {
            NavigationStack {
                CaptureView()
                    .whiteStatusBar()
            }
        }
        .sheet(item: $secondaryMailbox) { mailbox in
            InboxView(initialMailbox: mailbox, isTabRoot: true)
                .presentationDragIndicator(.visible)
                .presentationDetents([.large])
        }
    }

    private var appHeader: some View {
        ZStack {
            Button {
                LBHaptic.light()
                selectedTab = .inbox
                logoReplayToken += 1
            } label: {
                LaterBoxVectorMark(
                    size: 42,
                    appearance: .light,
                    animates: true,
                    replayToken: logoReplayToken
                )
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("LaterBox home")

            HStack {
                Button {
                    LBHaptic.medium()
                    showingCapture = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)
                        .frame(width: 44, height: 44)
                        .background(AppTheme.darkSurface, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                        .contentShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Capture Item")
                .accessibilityIdentifier("Capture Item")

                Spacer()

                Menu {
                    Section("Saved views") {
                        Button("Starred", systemImage: "star") { secondaryMailbox = .starred }
                        Button("Returns schedule", systemImage: "calendar.badge.clock") { selectedTab = .today }
                        Button("Someday", systemImage: "clock.arrow.circlepath") { secondaryMailbox = .someday }
                        Button("Archived", systemImage: "archivebox") { secondaryMailbox = .archived }
                        Button("Recently Deleted", systemImage: "trash") { secondaryMailbox = .trash }
                    }
                    Section("Account") {
                        Button("Settings", systemImage: "gearshape") { selectedTab = .settings }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 19, weight: .medium))
                        .foregroundStyle(AppTheme.textPrimary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("More pages")
                .accessibilityIdentifier("More LaterBox Pages")
            }
        }
        .frame(height: 58)
        .padding(.horizontal, 16)
        .background(AppTheme.canvasBackground)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppTheme.textPrimary.opacity(0.07))
                .frame(height: 0.5)
        }
    }
}
