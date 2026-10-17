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
    @State private var showingSyncReport = false
    @State private var syncReportMessage = ""

    var body: some View {
        ZStack {
            if !coordinator.hasAccess {
                WelcomeView()
                    .transition(.opacity)
            } else {
                InboxView()
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
                        await coordinator.syncPendingItems(context: modelContext, announceFailure: false)
                    }
                    .transition(.opacity)
            }

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

            // Biometric App Lock Screen Overlay
            if lockManager.isAppLockEnabled && lockManager.isLocked && coordinator.hasAccess {
                AppLockOverlayView()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .zIndex(999)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: coordinator.hasAccess)
        .alert("Sync failed", isPresented: $coordinator.showingSyncFailureAlert) {
            if coordinator.sessionExpired {
                Button("Sign In") { coordinator.showingAuthSheet = true }
            }
            Button("Report issue") {
                syncReportMessage = "Cloud sync failed on iOS.\n\nWhat I was doing:\n\nError details:\n" + String((coordinator.lastSyncErrorMessage ?? "Unknown sync error").prefix(3000))
                showingSyncReport = true
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text(coordinator.friendlySyncFailureReason)
        }
        .sheet(isPresented: $showingSyncReport) {
            NavigationStack {
                SupportRequestView(initialSubject: "Cloud sync failed", initialMessage: syncReportMessage)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { showingSyncReport = false }
                        }
                    }
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
        .onOpenURL { url in
            if url.scheme == "laterbox" && (url.host == "quick-save" || url.host == "capture") {
                coordinator.showingQuickCapture = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenQuickSaveModal"))) { _ in
            coordinator.showingQuickCapture = true
        }
        .onChange(of: coordinator.isProUser) { _, active in
            if active { Task { await coordinator.syncPendingItems(context: modelContext, announceFailure: false) } }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                try? SharedCaptureImporter.refresh(context: modelContext)
                Task {
                    await StoreKitManager.shared.updatePurchasedProducts()
                    await coordinator.refreshEntitlement()
                    await coordinator.syncPendingItems(context: modelContext, announceFailure: false)
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
