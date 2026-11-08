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

    /// The custom brand/capture/More header belongs exclusively to Inbox.
    var showsAppHeader: Bool { self == .inbox }

    func shouldShowHeader(itemDetailPushed: Bool) -> Bool {
        showsAppHeader && !itemDetailPushed
    }

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
    @State private var showingStorage = false
    @StateObject private var storageManager = LocalStorageManager.shared
    @State private var showingCapture = false
    @State private var inboxDetailPushed = false
    @State private var logoReplayToken = 0
    @State private var inboxPullDistance: CGFloat = 0
    @State private var inboxRefreshing = false

    var body: some View {
        VStack(spacing: 0) {
            // The header and logo refresh indicator are Inbox-only.
            if selectedTab.shouldShowHeader(itemDetailPushed: inboxDetailPushed) {
                appHeader
                    .zIndex(10)
            }

            TabView(selection: $selectedTab) {
                InboxView(
                    isTabRoot: true,
                    refreshPull: $inboxPullDistance,
                    refreshIsRunning: $inboxRefreshing,
                    detailIsPushed: $inboxDetailPushed
                )
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
        }
        .background(InboxAppearance.background(for: colorScheme).ignoresSafeArea())
        .fullScreenCover(isPresented: $showingCapture) {
            NavigationStack {
                CaptureView()
                    .whiteStatusBar()
            }
        }
        .sheet(isPresented: $showingStorage) {
            NavigationStack {
                StorageManagementView()
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Done") { showingStorage = false }
                        }
                    }
            }
        }
        .onAppear {
            storageManager.refreshBreakdown()
        }
        .onChange(of: inboxRefreshing) { _, isRefreshing in
            if !isRefreshing {
                storageManager.refreshBreakdown()
            }
        }
    }

    private var appHeader: some View {
        ZStack {
            Button {
                LBHaptic.light()
                selectedTab = .inbox
                logoReplayToken += 1
            } label: {
                LaterBoxPullRefreshLogo(
                    distance: inboxPullDistance,
                    refreshing: inboxRefreshing,
                    replayToken: logoReplayToken
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("LaterBox home")
            .accessibilityValue(
                inboxRefreshing ? "Refreshing" :
                    inboxPullDistance > 2 ? "Pulling to refresh" : "Ready"
            )

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

                Button {
                    LBHaptic.light()
                    storageManager.refreshBreakdown()
                    showingStorage = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "internaldrive")
                            .font(.system(size: 16, weight: .medium))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(storageManager.breakdown.formattedTotal)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .monospacedDigit()
                                .lineLimit(1)
                            GeometryReader { geometry in
                                HStack(spacing: 1) {
                                    Rectangle()
                                        .fill(AppTheme.accent)
                                        .frame(width: max(0, geometry.size.width * storageManager.breakdown.databasePercentage))
                                    Rectangle()
                                        .fill(Color.blue.opacity(0.8))
                                        .frame(width: max(0, geometry.size.width * storageManager.breakdown.attachmentsPercentage))
                                    Rectangle()
                                        .fill(Color.orange.opacity(0.8))
                                        .frame(width: max(0, geometry.size.width * storageManager.breakdown.cachePercentage))
                                }
                                .clipShape(Capsule())
                            }
                            .frame(width: 66, height: 3)
                        }
                    }
                    .foregroundStyle(InboxAppearance.textPrimary(for: colorScheme))
                    .padding(.horizontal, 10)
                    .frame(height: 38)
                    .background(
                        InboxAppearance.surface(for: colorScheme),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(InboxAppearance.border(for: colorScheme), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("On-device storage: \(storageManager.breakdown.formattedTotal). Open storage management.")
                .accessibilityIdentifier("Inbox Storage Usage")
            }
        }
        .frame(height: 58)
        .padding(.horizontal, 16)
        .background(InboxAppearance.background(for: colorScheme))
    }
}
