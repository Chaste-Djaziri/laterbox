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
    @StateObject private var lockManager = AppLockManager.shared
    @Environment(\.scenePhase) private var scenePhase

    @ObservedObject private var returnRouter = ReturnNotificationRouter.shared
    @StateObject private var aiManager = LaterAIManager.shared
    @ObservedObject private var clipboardManager = ClipboardDetectionManager.shared
    @State private var itemToPresent: LBItem? = nil

    var body: some View {
        ZStack {
            Group {
                if !coordinator.hasAccess {
                    WelcomeView()
                        .transition(.opacity)
                } else {
                    InboxView()
                        .overlay(alignment: .bottomTrailing) {
                            Button {
                                aiManager.open()
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundStyle(AppTheme.accent)
                                    .frame(width: 56, height: 56)
                                    .background(AppTheme.darkSurface, in: Circle())
                                    .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Open Later AI")
                            .padding(.trailing, 20)
                            .padding(.bottom, 24)
                        }
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

        // In-App Top Slide-Down Notification Banner for Copied Items
        if clipboardManager.isShowingBanner, let item = clipboardManager.detectedItem, coordinator.hasAccess {
            VStack {
                CopiedItemBannerView(item: item)
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                Spacer()
            }
            .transition(
                .asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                )
            )
            .zIndex(150)
        }

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
    .animation(.spring(response: 0.44, dampingFraction: 0.82), value: clipboardManager.isShowingBanner)
    .onReceive(returnRouter.$itemID) { id in
        guard let id = id, !id.isEmpty else { return }
        try? SharedCaptureImporter.refresh(context: modelContext)

        let descriptor = FetchDescriptor<LBItem>(predicate: #Predicate { $0.id == id })
        if let matchingItem = try? modelContext.fetch(descriptor).first {
            aiManager.isShowingLaterAI = false
            coordinator.showingQuickCapture = false
            itemToPresent = matchingItem
            returnRouter.itemID = nil
        } else {
            Task {
                try? await Task.sleep(for: .milliseconds(350))
                try? SharedCaptureImporter.refresh(context: modelContext)
                if let delayedItem = try? modelContext.fetch(descriptor).first {
                    aiManager.isShowingLaterAI = false
                    coordinator.showingQuickCapture = false
                    itemToPresent = delayedItem
                    returnRouter.itemID = nil
                }
            }
        }
    }
    .sheet(item: $itemToPresent) { item in
        NavigationStack {
            ItemDetailView(item: item, isModal: true)
        }
    }
    .task {
        while !Task.isCancelled {
            try? SharedCaptureImporter.refresh(context: modelContext)
            do { try await Task.sleep(for: .seconds(30)) } catch { break }
        }
    }
    .onAppear {
        clipboardManager.checkForCopiedItem()
    }
    .onChange(of: coordinator.isProUser) { _, active in
        if active { Task { await coordinator.syncPendingItems(context: modelContext) } }
    }
    .onChange(of: scenePhase) { _, newPhase in
        if newPhase == .active {
            try? SharedCaptureImporter.refresh(context: modelContext)
            Task {
                await StoreKitManager.shared.updatePurchasedProducts()
                await coordinator.refreshEntitlement()
                await coordinator.syncPendingItems(context: modelContext)
            }
            clipboardManager.checkForCopiedItem()
        }
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
