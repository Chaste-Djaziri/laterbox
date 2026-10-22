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
    @State private var isLaunching = true
    @State private var launchStarted = false
    @State private var launchStatus = "Preparing your vault"
    @State private var showingSyncReport = false
    @State private var syncReportMessage = ""

    private var activeColorScheme: ColorScheme {
        if !coordinator.hasAccess {
            return .dark
        }
        if coordinator.showingAuthSheet {
            return .dark
        }
        if coordinator.isShowingCapture || coordinator.showingQuickCapture {
            return .dark
        }
        return .light
    }

    var body: some View {
        ZStack {
            if !coordinator.hasAccess {
                WelcomeView()
                    .whiteStatusBar()
                    .transition(.opacity)
            } else {
                InboxView()
                    .darkStatusBar()
                    .sheet(isPresented: $coordinator.showingQuickCapture) {
                        QuickCaptureSheet()
                    }
                    .sheet(isPresented: $coordinator.showingAuthSheet) {
                        NavigationStack {
                            AuthView()
                        }
                        .whiteStatusBar()
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

            if isLaunching {
                launchSplash
                    .transition(.opacity)
                    .zIndex(1000)
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
        .preferredColorScheme(activeColorScheme)
        .onChange(of: activeColorScheme) { _, newScheme in
            StatusBarStyleModifier.apply(newScheme == .dark ? .dark : .light)
        }
        .onAppear {
            StatusBarStyleModifier.apply(activeColorScheme == .dark ? .dark : .light)
        }
        .task {
            guard !launchStarted else { return }
            launchStarted = true
            await prepareLaunch()
        }
        .alert("Sync failed", isPresented: $coordinator.showingSyncFailureAlert) {
            if coordinator.sessionExpired {
                Button("Sign In") { coordinator.showingAuthSheet = true }
                Button("Use Local (Sign Out)", role: .destructive) {
                    coordinator.signOut()
                    coordinator.continueAsGuest()
                }
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
            openPendingQuickSaveControl()
        }
        .onOpenURL { url in
            if url.scheme == "laterbox" && (url.host == "quick-save" || url.host == "capture") {
                coordinator.showingQuickCapture = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenQuickSaveModal"))) { _ in
            coordinator.showingQuickCapture = true
        }
        .onChange(of: coordinator.hasAccess) { _, hasAccess in
            if hasAccess { openPendingQuickSaveControl() }
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
                openPendingQuickSaveControl()
            }
            if newPhase == .background {
                lockManager.lockAppIfNeeded()
            }
        }
    }
    private var launchSplash: some View {
        ZStack {
            AppTheme.canvasBackground.ignoresSafeArea()

            VStack(spacing: 22) {
                Image("LaterboxLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 290, height: 110)
                    .accessibilityLabel("LaterBox")

                ProgressView()
                    .tint(AppTheme.textPrimary)
                    .padding(.top, 14)

                Text(launchStatus)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .accessibilityAddTraits(.updatesFrequently)
            }
            .padding(28)
        }
        .preferredColorScheme(.light)
        .accessibilityElement(children: .combine)
    }

    @MainActor
    private func prepareLaunch() async {
        // Local content must be imported before showing the inbox.
        launchStatus = "Loading saved items"
        try? SharedCaptureImporter.refresh(context: modelContext)

        launchStatus = "Checking your account"
        // Complete as soon as checks finish; a timeout keeps offline startup usable.
        Task {
            await StoreKitManager.shared.updatePurchasedProducts()
            await coordinator.refreshEntitlement()
            finishLaunch()
        }
        Task {
            try? await Task.sleep(for: .seconds(8))
            finishLaunch()
        }
    }

    @MainActor
    private func finishLaunch() {
        guard isLaunching else { return }
        launchStatus = "Opening LaterBox"
        withAnimation(.easeOut(duration: 0.3)) {
            isLaunching = false
        }
        openPendingQuickSaveControl()
    }

    private func openPendingQuickSaveControl() {
        guard coordinator.hasAccess,
              let defaults = UserDefaults(suiteName: "group.pro.micorp.laterbox"),
              defaults.bool(forKey: "openQuickSaveFromControl") else { return }
        defaults.removeObject(forKey: "openQuickSaveFromControl")
        coordinator.showingQuickCapture = true
    }

}

#Preview {
    ContentView()
        .modelContainer(for: [LBItem.self, LBCollection.self], inMemory: true)
}
