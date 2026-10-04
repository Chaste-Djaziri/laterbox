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
    @StateObject private var coordinator = SyncCoordinator.shared

    @State private var selectedTab: LBTab = .home
    @State private var showingQuickCapture: Bool = false

    var body: some View {
        Group {
            if !coordinator.hasAccess {
                WelcomeView()
                    .transition(.opacity)
            } else {
                ZStack(alignment: .bottom) {
                    // Main Tab Content
                    Group {
                        switch selectedTab {
                        case .home:
                            HomeView()
                        case .inbox:
                            InboxView()
                        case .returns:
                            ReturnsView()
                        case .library:
                            LibraryView()
                        case .settings:
                            SettingsView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Floating Liquid Glass Tab Bar
                    GlassTabBar(selectedTab: $selectedTab) {
                        showingQuickCapture = true
                    }
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .sheet(isPresented: $showingQuickCapture) {
                    QuickCaptureSheet()
                }
                .task {
                    // Trigger automatic sync on app launch
                    await coordinator.syncPendingItems(context: modelContext)
                }
                .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: coordinator.hasAccess)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [LBItem.self, LBCollection.self], inMemory: true)
}
