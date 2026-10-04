//
//  ContentView.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 04.10.26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<LBItem> { $0.status == "inbox" }) private var inboxItems: [LBItem]
    @StateObject private var coordinator = SyncCoordinator.shared
    @StateObject private var lockManager = AppLockManager.shared
    @Environment(\.scenePhase) private var scenePhase

    @State private var selectedTab: LBTab = .home
    @StateObject private var aiManager = LaterAIManager.shared

    var body: some View {
        ZStack {
            Group {
                if !coordinator.hasAccess {
                    WelcomeView()
                        .transition(.opacity)
                } else {
                TabView(selection: $selectedTab) {
                    HomeView()
                        .tabItem {
                            Label("Home", systemImage: selectedTab == .home ? "house.fill" : "house")
                        }
                        .tag(LBTab.home)

                    InboxView()
                        .tabItem {
                            Label("Inbox", systemImage: selectedTab == .inbox ? "tray.fill" : "tray")
                        }
                        .badge(inboxItems.count > 0 ? inboxItems.count : 0)
                        .tag(LBTab.inbox)

                    ReturnsView()
                        .tabItem {
                            Label("Returns", systemImage: selectedTab == .returns ? "calendar" : "calendar")
                        }
                        .tag(LBTab.returns)

                    LibraryView()
                        .tabItem {
                            Label("Library", systemImage: selectedTab == .library ? "books.vertical.fill" : "books.vertical")
                        }
                        .tag(LBTab.library)

                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: selectedTab == .settings ? "gearshape.fill" : "gearshape")
                        }
                        .tag(LBTab.settings)
                }
                .tint(Color.black)
                .sheet(isPresented: $coordinator.showingQuickCapture) {
                    QuickCaptureSheet()
                }
                .sheet(isPresented: $coordinator.showingAuthSheet) {
                    NavigationStack {
                        AuthView()
                    }
                }
                .sheet(isPresented: $coordinator.showingPlansSheet) {
                    PlansView()
                }
                .task {
                    // Trigger automatic sync on app launch
                    await coordinator.syncPendingItems(context: modelContext)
                }
                .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: coordinator.hasAccess)

        // Later AI Dropdown Full Screen Interface with Feathered Fading Curtain
        if (aiManager.isShowingLaterAI || aiManager.flowProgress > 0) && coordinator.hasAccess {
            LaterAIView(isPresented: $aiManager.isShowingLaterAI, progress: $aiManager.flowProgress)
                .zIndex(200)
                .allowsHitTesting(aiManager.flowProgress > 0.6)
        }

        // Biometric App Lock Screen Overlay
        if lockManager.isAppLockEnabled && lockManager.isLocked && coordinator.hasAccess {
            AppLockOverlayView()
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                .zIndex(999)
        }
    }
    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: lockManager.isLocked)
    .onChange(of: scenePhase) { _, newPhase in
        if newPhase == .background {
            lockManager.lockAppIfNeeded()
        }
    }
}
}

#Preview {
    ContentView()
        .modelContainer(for: [LBItem.self, LBCollection.self], inMemory: true)
}
