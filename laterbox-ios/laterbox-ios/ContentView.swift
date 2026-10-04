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
    @State private var isShowingLaterAI: Bool = false
    @State private var laterAIFlowProgress: CGFloat = 0.0

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
                .simultaneousGesture(
                    DragGesture(minimumDistance: 15, coordinateSpace: .global)
                        .onChanged { value in
                            guard coordinator.hasAccess else { return }
                            let startsAtTopEnd = value.startLocation.y < 220
                            let isDownward = value.translation.height > 0
                            let isVertical = abs(value.translation.height) > abs(value.translation.width) * 1.05

                            if startsAtTopEnd && isDownward && isVertical {
                                if !isShowingLaterAI {
                                    isShowingLaterAI = true
                                }
                                laterAIFlowProgress = min(1.0, max(0.0, value.translation.height / 300.0))
                            }
                        }
                        .onEnded { value in
                            guard coordinator.hasAccess else { return }
                            let startsAtTopEnd = value.startLocation.y < 220
                            let isDownward = value.translation.height > 50
                            let isVertical = abs(value.translation.height) > abs(value.translation.width) * 1.05

                            if startsAtTopEnd && isDownward && isVertical {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                withAnimation(.spring(response: 0.48, dampingFraction: 0.82)) {
                                    laterAIFlowProgress = 1.0
                                    isShowingLaterAI = true
                                }
                            } else if laterAIFlowProgress > 0 && laterAIFlowProgress < 1.0 {
                                withAnimation(.spring(response: 0.38, dampingFraction: 0.85)) {
                                    laterAIFlowProgress = 0.0
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
                                    if laterAIFlowProgress == 0 {
                                        isShowingLaterAI = false
                                    }
                                }
                            }
                        }
                )
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

        // Top Subtle Grab Pill for Later AI
        if coordinator.hasAccess && (!lockManager.isAppLockEnabled || !lockManager.isLocked) {
            VStack {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    isShowingLaterAI = true
                    withAnimation(.spring(response: 0.48, dampingFraction: 0.82)) {
                        laterAIFlowProgress = 1.0
                    }
                } label: {
                    HStack(spacing: 5) {
                        Capsule()
                            .fill(Color.black.opacity(0.18))
                            .frame(width: 32, height: 3.5)
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 8)
                    .padding(.horizontal, 24)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .highPriorityGesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            if value.translation.height > 0 {
                                if !isShowingLaterAI {
                                    isShowingLaterAI = true
                                }
                                laterAIFlowProgress = min(1.0, max(0.0, value.translation.height / 300.0))
                            }
                        }
                        .onEnded { value in
                            if value.translation.height > 30 || value.predictedEndTranslation.height > 60 {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                withAnimation(.spring(response: 0.48, dampingFraction: 0.82)) {
                                    laterAIFlowProgress = 1.0
                                    isShowingLaterAI = true
                                }
                            } else {
                                withAnimation(.spring(response: 0.38, dampingFraction: 0.85)) {
                                    laterAIFlowProgress = 0.0
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
                                    if laterAIFlowProgress == 0 {
                                        isShowingLaterAI = false
                                    }
                                }
                            }
                        }
                )

                Spacer()
            }
            .zIndex(50)
        }

        // Later AI Dropdown Full Screen Interface with Feather-Flow Curtain
        if isShowingLaterAI && coordinator.hasAccess {
            LaterAIView(isPresented: $isShowingLaterAI, progress: $laterAIFlowProgress)
                .zIndex(200)
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
