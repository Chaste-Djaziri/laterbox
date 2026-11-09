// laterbox-ios/laterbox-ios/Views/Inbox/InboxHeaderView.swift
import SwiftUI

/// This header belongs to the Inbox NavigationStack's root destination.
/// Keeping it in the root prevents a parent-shell height change (and stale
/// ScrollView safe-area inset) during a detail push/pop transition.
struct InboxHeaderView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var coordinator = SyncCoordinator.shared
    @Binding var refreshPull: CGFloat
    @Binding var refreshIsRunning: Bool

    @State private var showingCloudUsage = false
    @Binding var showingCapture: Bool
    @State private var logoReplayToken = 0

    var body: some View {
        appHeader
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
                // One shared page-style background across the sheet and its safe areas.
                .presentationBackground {
                    InboxGrainBackground()
                }
            }
            .onChange(of: refreshIsRunning) { _, isRefreshing in
                if !isRefreshing && coordinator.isAuthenticated && !coordinator.isGuestMode {
                    Task { await coordinator.refreshEntitlement() }
                }
            }
    }

    private var appHeader: some View {
        ZStack {
            Button {
                LBHaptic.light()
                logoReplayToken += 1
            } label: {
                LaterBoxPullRefreshLogo(
                    distance: refreshPull,
                    refreshing: refreshIsRunning,
                    replayToken: logoReplayToken
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("LaterBox home")
            .accessibilityValue(
                refreshIsRunning ? "Refreshing" :
                    refreshPull > 2 ? "Pulling to refresh" : "Ready"
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
    }
}
