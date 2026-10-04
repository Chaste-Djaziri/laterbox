//
//  HomeView.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 04.10.26.
//

import SwiftUI
import SwiftData

public struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LBItem.createdAt, order: .reverse) private var allItems: [LBItem]
    @ObservedObject var coordinator = SyncCoordinator.shared

    @State private var showingQuickCapture = false
    @State private var showingAIOrganizer = false

    private var inboxItems: [LBItem] {
        allItems.filter { $0.status == ItemStatus.inbox.rawValue }
    }

    private var savedItems: [LBItem] {
        allItems.filter { $0.status == ItemStatus.saved.rawValue }
    }

    private var starredItems: [LBItem] {
        allItems.filter { $0.favorite }
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        // Top 4 Metrics Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            SummaryMetricCard(title: "Saved", count: savedItems.count, icon: "tray.full.fill", color: Color.lbAmber)
                            SummaryMetricCard(title: "To Review", count: inboxItems.count, icon: "clock.badge.checkmark", color: Color(red: 99/255, green: 102/255, blue: 241/255))
                            SummaryMetricCard(title: "Starred", count: starredItems.count, icon: "star.fill", color: Color(red: 234/255, green: 179/255, blue: 8/255))
                            SummaryMetricCard(title: "Total Vault", count: allItems.count, icon: "books.vertical.fill", color: Color(red: 20/255, green: 184/255, blue: 166/255))
                        }

                        // Hero "Continue Reviewing" Card
                        if let heroItem = inboxItems.first {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(Color.lbAmber)
                                    Text("Continue Reviewing")
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(.secondary)
                                        .textCase(.uppercase)
                                    Spacer()
                                    Text(heroItem.parsedContentType.rawValue.capitalized)
                                        .font(.caption2.weight(.semibold))
                                        .foregroundColor(Color.lbAmber)
                                }

                                NavigationLink(destination: ItemDetailView(item: heroItem)) {
                                    VStack(alignment: .leading, spacing: 10) {
                                        RichMediaBanner(type: heroItem.parsedContentType, url: heroItem.url, title: heroItem.title)

                                        Text(heroItem.title)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                            .lineLimit(2)

                                        HStack {
                                            if let domain = heroItem.domain {
                                                Text(domain)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                            Text("Review Now →")
                                                .font(.caption.weight(.bold))
                                                .foregroundColor(Color.lbAmber)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(16)
                            .liquidGlassCard(cornerRadius: 22, borderOpacity: 0.3)
                        }

                        // AI Inbox Organizer Beta Card
                        Button(action: {
                            LBHaptic.medium()
                            showingAIOrganizer = true
                        }) {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(colors: [Color.lbAmber, Color.lbAmberDark], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "wand.and.stars")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.black)
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                    HStack {
                                        Text("AI Inbox Organizer")
                                            .font(.subheadline.weight(.bold))
                                            .foregroundColor(.primary)
                                        Text("Beta")
                                            .font(.system(size: 9, weight: .bold))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Capsule().fill(Color.lbAmber.opacity(0.3)))
                                            .foregroundColor(Color.lbAmber)
                                    }
                                    Text("Auto-classify, assign collections, and schedule review")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.secondary)
                            }
                            .padding(16)
                            .liquidGlassCard(cornerRadius: 20)
                        }
                        .buttonStyle(.plain)

                        // Recent Captures Feed
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Captures")
                                .font(.headline)
                                .foregroundColor(.primary)

                            if allItems.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "tray")
                                        .font(.system(size: 38))
                                        .foregroundColor(.secondary.opacity(0.5))
                                    Text("Your vault is empty")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.secondary)
                                    Text("Tap + below to capture links, articles, or notes")
                                        .font(.caption)
                                        .foregroundColor(.secondary.opacity(0.7))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(36)
                                .liquidGlassCard(cornerRadius: 18)
                            } else {
                                ForEach(allItems.prefix(5)) { item in
                                    NavigationLink(destination: ItemDetailView(item: item)) {
                                        ItemCardView(
                                            item: item,
                                            onMarkDone: { coordinator.markDone(item: item, context: modelContext) },
                                            onToggleFavorite: { coordinator.toggleFavorite(item: item, context: modelContext) },
                                            onSchedule: {
                                                coordinator.scheduleItem(item: item, date: Calendar.current.date(byAdding: .day, value: 1, to: Date())!, context: modelContext)
                                            },
                                            onDelete: { coordinator.deleteItem(item: item, context: modelContext) }
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("\(greetingText), \(userName)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        // Sync Status in Theme Color (No Container)
                        HStack(spacing: 5) {
                            Circle()
                                .fill(coordinator.syncState == .synced ? Color.lbGreenTheme : coordinator.syncState.statusColor)
                                .frame(width: 7, height: 7)
                            Text(coordinator.syncState.rawValue)
                                .font(.caption2.weight(.medium))
                                .foregroundColor(Color.black.opacity(0.65))
                        }

                        // Quick Capture Header Action
                        Button(action: {
                            LBHaptic.medium()
                            coordinator.showingQuickCapture = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 26, height: 26)
                                .background(Color.black)
                                .clipShape(Circle())
                        }

                        // Profile Icon Menu with Logout & Guest Exit
                        Menu {
                            if let email = coordinator.currentUserEmail {
                                Section(email) {
                                    Button(role: .destructive, action: {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            coordinator.signOut()
                                        }
                                    }) {
                                        Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                                    }
                                }
                            } else {
                                Section("Guest Mode") {
                                    Button(role: .destructive, action: {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            coordinator.signOut()
                                        }
                                    }) {
                                        Label("Exit Guest / Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.black)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingQuickCapture) {
                QuickCaptureSheet()
            }
            .sheet(isPresented: $showingAIOrganizer) {
                AIOrganizerSheet()
            }
        }
    }

    private var userName: String {
        if let email = coordinator.currentUserEmail, !email.isEmpty {
            let prefix = email.split(separator: "@").first.map(String.init) ?? "User"
            return prefix.capitalized
        }
        return "Guest"
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good Morning" }
        if hour < 18 { return "Good Afternoon" }
        return "Good Evening"
    }
}
