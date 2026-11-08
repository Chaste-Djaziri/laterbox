//
//  ContentView.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 04.10.26.
//

import SwiftUI
import SwiftData

/// A temporary five-second brand animation, shared by cold launches and foreground re-entry.
enum LaterBoxSplashTiming {
    static let totalDurationSeconds = 5.0
    static let fillDurationSeconds = 4.75
    static let leadInMilliseconds = 50
    static let remainingMilliseconds = 4_950

    static func shouldReplay(wasBackgrounded: Bool, phase: ScenePhase) -> Bool {
        wasBackgrounded && phase == .active
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var coordinator = SyncCoordinator.shared
    @StateObject private var lockManager = AppLockManager.shared
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var systemColorScheme

    @ObservedObject private var returnRouter = ReturnNotificationRouter.shared
    @StateObject private var aiManager = LaterAIManager.shared
    @ObservedObject private var clipboardManager = ClipboardDetectionManager.shared
    @State private var itemToPresent: LBItem? = nil
    @State private var isLaunching = true
    @State private var launchStarted = false
    @State private var launchStatus = "Preparing your vault"
    @State private var launchProgress = 0.0
    @State private var splashGeneration = 0
    @State private var wasBackgrounded = false
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
                    .transition(.opacity)
            } else {
                MainTabView()
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
        // While the splash is visible, let iOS use the device's Light/Dark appearance.
        // Restore the existing app-specific color scheme after the splash finishes.
        .preferredColorScheme(isLaunching ? nil : activeColorScheme)
        .onChange(of: activeColorScheme) { _, _ in
            applyCurrentInterfaceStyle()
        }
        .onChange(of: isLaunching) { _, _ in
            applyCurrentInterfaceStyle()
        }
        .onAppear {
            applyCurrentInterfaceStyle()
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
                if LaterBoxSplashTiming.shouldReplay(wasBackgrounded: wasBackgrounded, phase: newPhase) {
                    wasBackgrounded = false
                    if launchStarted {
                        startSplashAnimation(status: "Welcome back")
                    }
                }
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
                wasBackgrounded = true
                lockManager.lockAppIfNeeded()
            }
        }
    }
    private var launchSplash: some View {
        let ink = LaterBoxLoadingMark.foreground(for: systemColorScheme)
        return ZStack {
            LaterBoxLoadingMark.background(for: systemColorScheme)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                LaterBoxLoadingMark(
                    size: 168,
                    progress: launchProgress
                )
                .padding(.bottom, 6)

                Text("laterbox")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .tracking(-1)
                    .foregroundStyle(ink)

                Text(launchStatus)
                    .font(.subheadline)
                    .foregroundStyle(ink.opacity(0.65))
                    .accessibilityAddTraits(.updatesFrequently)
            }
            .padding(28)
        }
        .accessibilityElement(children: .combine)
    }

    private func applyCurrentInterfaceStyle() {
        let style: UIUserInterfaceStyle = isLaunching
            ? .unspecified
            : (activeColorScheme == .dark ? .dark : .light)
        StatusBarStyleModifier.apply(style)
    }

    @MainActor
    private func prepareLaunch() async {
        // Import saved content locally, then play the five-second visual demo.
        // Neither networking nor StoreKit can extend the splash duration.
        launchStatus = "Loading saved items"
        try? SharedCaptureImporter.refresh(context: modelContext)
        startSplashAnimation(status: "Opening LaterBox")

        // Refresh cloud and purchase state independently of the animation.
        Task {
            await StoreKitManager.shared.updatePurchasedProducts()
            await coordinator.refreshEntitlement()
        }
    }

    @MainActor
    private func startSplashAnimation(status: String) {
        // A foreground replay supersedes any pending cold-launch completion.
        splashGeneration += 1
        let generation = splashGeneration
        var reset = Transaction()
        reset.disablesAnimations = true
        withTransaction(reset) {
            launchProgress = 0
            isLaunching = true
        }
        launchStatus = status

        Task { @MainActor in
            do {
                // Render the unfilled logo before animating its color.
                try await Task.sleep(for: .milliseconds(LaterBoxSplashTiming.leadInMilliseconds))
                guard generation == splashGeneration else { return }

                withAnimation(reduceMotion ? nil : .linear(duration: LaterBoxSplashTiming.fillDurationSeconds)) {
                    launchProgress = 1
                }

                // Exactly five seconds of splash visibility for this UI iteration.
                try await Task.sleep(for: .milliseconds(LaterBoxSplashTiming.remainingMilliseconds))
                guard generation == splashGeneration else { return }
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                    isLaunching = false
                }
                openPendingQuickSaveControl()
            } catch {
                // Cancellation should never dismiss a newer splash replay.
                return
            }
        }
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
