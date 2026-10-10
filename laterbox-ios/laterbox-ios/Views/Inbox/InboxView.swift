//
//  InboxView.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 04.10.26.
//

import SwiftUI
import SwiftData

public struct InboxView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LBItem.createdAt, order: .reverse) private var allItems: [LBItem]
    @ObservedObject var coordinator = SyncCoordinator.shared

    @State private var showingSidebar: Bool = false
    @State private var showingSearch: Bool = false
    @State private var showingOrganizer: Bool = false

    public init() {}

    private var rawInboxItems: [LBItem] {
        allItems.filter { $0.status == ItemStatus.inbox.rawValue }
    }

    private var userInitial: String {
        if let email = coordinator.currentUserEmail, let first = email.first {
            return String(first).uppercased()
        }
        return "U"
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F7F5EE").ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // 1. Mobile Top Search Bar (Matching Gmail screenshot layout)
                        HStack(spacing: 10) {
                            // 3-buttons sidebar opener on the left
                            Button {
                                LBHaptic.light()
                                showingSidebar = true
                            } label: {
                                Image(systemName: "line.3.horizontal")
                                    .font(.system(size: 20, weight: .regular))
                                    .foregroundColor(AppTheme.textPrimary)
                                    .frame(width: 36, height: 36)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Open sidebar")

                            // Big centered search input
                            Button {
                                LBHaptic.light()
                                showingSearch = true
                            } label: {
                                HStack(spacing: 8) {
                                    Text("Ask LaterBox")
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundColor(Color.secondary)

                                    Spacer()

                                    // Diamond sparkle icon (matching screenshot "Ask Gmail ✦")
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(Color(hex: "1A73E8"))
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 48)
                                .background(Color.white, in: Capsule())
                                .overlay(
                                    Capsule()
                                        .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Search inbox")

                            // Profile picture avatar at the right of the search
                            Menu {
                                if let email = coordinator.currentUserEmail, !email.isEmpty {
                                    Section(email) {
                                        Button(role: .destructive) {
                                            coordinator.signOut()
                                        } label: {
                                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                                        }
                                    }
                                } else {
                                    Section("Guest Mode") {
                                        Button(role: .destructive) {
                                            coordinator.signOut()
                                        } label: {
                                            Label("Sign In / Exit Guest", systemImage: "rectangle.portrait.and.arrow.right")
                                        }
                                    }
                                }
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: "171711"))
                                        .frame(width: 36, height: 36)
                                    Text(userInitial)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .overlay(
                                    Circle()
                                        .stroke(Color(hex: "1A73E8"), lineWidth: 2)
                                )
                            }
                            .accessibilityLabel("Profile menu")
                        }
                        .padding(.horizontal, 14)
                        .padding(.top, 10)
                        .padding(.bottom, 8)

                        // 2. Section Title (Clean "Inbox" heading like "Primary" in screenshot)
                        Text("Inbox")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color.secondary)
                            .padding(.horizontal, 18)
                            .padding(.top, 14)
                            .padding(.bottom, 8)

                        // 3. Email List
                        if rawInboxItems.isEmpty {
                            VStack(spacing: 14) {
                                Image(systemName: "tray.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary.opacity(0.35))
                                Text("Inbox Zero!")
                                    .font(.headline)
                                    .foregroundColor(AppTheme.textPrimary)
                                Text("All caught up. Everything saved has been processed or reviewed.")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(48)
                            .background(Color.white)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                            )
                            .padding(.horizontal, 12)
                            .padding(.top, 12)
                        } else {
                            LazyVStack(spacing: 2.5) {
                                ForEach(Array(rawInboxItems.enumerated()), id: \.element.id) { index, item in
                                    let isFirst = index == 0
                                    let isLast = index == rawInboxItems.count - 1
                                    let topRadius: CGFloat = isFirst ? 12 : 4
                                    let bottomRadius: CGFloat = isLast ? 12 : 4

                                    NavigationLink(destination: ItemDetailView(item: item)) {
                                        EmailInboxRowView(
                                            item: item,
                                            topRadius: topRadius,
                                            bottomRadius: bottomRadius,
                                            onToggleFavorite: { coordinator.toggleFavorite(item: item, context: modelContext) },
                                            onMarkDone: { coordinator.markDone(item: item, context: modelContext) },
                                            onSchedule: { date in coordinator.scheduleItem(item: item, date: date, context: modelContext) },
                                            onDelete: { coordinator.deleteItem(item: item, context: modelContext) }
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 12)
                        }
                    }
                    .padding(.bottom, 40)
                }
                .trackPullDownForLaterAI()
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSidebar) {
                MobileSidebarDrawer()
            }
            .fullScreenCover(isPresented: $showingSearch) {
                VaultSearchView()
            }
            .sheet(isPresented: $showingOrganizer) {
                AIOrganizerSheet()
            }
        }
    }
}
