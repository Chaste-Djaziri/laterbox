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
    @State private var showingCloudUsage = false
    @ObservedObject private var coordinator = SyncCoordinator.shared
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
        .sheet(isPresented: $showingCloudUsage) {
            NavigationStack {
                CloudStorageUsageDetails()
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Done") { showingCloudUsage = false }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: inboxRefreshing) { _, isRefreshing in
            if !isRefreshing && coordinator.isAuthenticated && !coordinator.isGuestMode {
                Task { await coordinator.refreshEntitlement() }
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
                    showingCloudUsage = true
                } label: {
                    CloudStorageUsageRing(
                        quota: CloudStorageQuota.from(
                            coordinator.isAuthenticated && !coordinator.isGuestMode
                                ? coordinator.billingEntitlement
                                : nil
                        ),
                        isSignedIn: coordinator.isAuthenticated && !coordinator.isGuestMode
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    coordinator.isAuthenticated && !coordinator.isGuestMode
                        ? (CloudStorageQuota.from(coordinator.billingEntitlement).percent.map {
                            "Cloud storage: \(Int($0.rounded())) percent of plan used. View cloud storage."
                        } ?? "Cloud storage usage unavailable. View cloud storage.")
                        : "Sign in to view cloud storage usage"
                )
                .accessibilityIdentifier("Inbox Storage Usage")
            }
        }
        .frame(height: 58)
        .padding(.horizontal, 16)
        .background(InboxAppearance.background(for: colorScheme))
    }
}
