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
    @State private var searchText: String = ""
    @StateObject private var search = LocalSearchController()

    private var inboxItems: [LBItem] {
        allItems.filter { $0.status == ItemStatus.inbox.rawValue }
    }

    private var searchResults: [LBItem] {
        let q = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }
        return search.results
    }

    private var returnedTodayCount: Int {
        let cal = Calendar.current
        let now = Date()
        let startOfToday = cal.startOfDay(for: now)
        let endOfToday = cal.date(byAdding: .day, value: 1, to: startOfToday) ?? now
        return allItems.filter {
            guard let ret = $0.returnAt else { return false }
            return ret <= endOfToday
        }.count
    }

    private var upcomingItems: [LBItem] {
        let cal = Calendar.current
        let now = Date()
        let startOfToday = cal.startOfDay(for: now)
        let endOfToday = cal.date(byAdding: .day, value: 1, to: startOfToday) ?? now
        return allItems.filter {
            guard let ret = $0.returnAt else { return false }
            return ret > endOfToday
        }.sorted { ($0.returnAt ?? Date.distantFuture) < ($1.returnAt ?? Date.distantFuture) }
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        // Top Level Header (Scrolls normally, does not stick)
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("\(greetingText), \(userName)")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.black)
                                Text("Your personal knowledge vault")
                                    .font(.caption)
                                    .foregroundColor(Color.black.opacity(0.55))
                            }

                            Spacer()

                            HStack(spacing: 12) {
                                // Sync Status in Theme Color (No Container)
                                Button(action: {
                                    if !coordinator.isProUser {
                                        LBHaptic.light()
                                        coordinator.showingPlansSheet = true
                                    }
                                }) {
                                    HStack(spacing: 5) {
                                        Circle()
                                            .fill(coordinator.syncHeaderColor)
                                            .frame(width: 7, height: 7)
                                        Text(coordinator.syncHeaderTitle)
                                            .font(.caption2.weight(.medium))
                                            .foregroundColor(AppTheme.textSecondary)
                                    }
                                }
                                .buttonStyle(.plain)

                                Button {
                                    if AppleLaterAIProvider.unavailableReason == nil || (GeminiLaterAIProvider.enabled && coordinator.isProUser) {
                                        withAnimation(.spring(response: 0.44, dampingFraction: 0.86)) {
                                            LaterAIManager.shared.isShowingLaterAI = true
                                            LaterAIManager.shared.flowProgress = 1
                                        }
                                    } else { coordinator.showingQuickCapture = true }
                                } label: {
                                    Image(systemName: "plus.circle.fill").font(.system(size: 26))
                                }
                                .accessibilityLabel("Add item")

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
                                        .font(.system(size: 26))
                                        .foregroundColor(.black)
                                }
                            }
                        }
                        .padding(.top, 4)

                        // Search Bar right under greetings
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppTheme.textSecondary)

                            TextField("Search your vault...", text: $searchText)
                                .task(id: searchText + allItems.map { $0.updatedAt.ISO8601Format() }.joined()) { search.update(searchText, items: allItems) }
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textPrimary)

                            if !searchText.isEmpty {
                                Button(action: {
                                    LBHaptic.light()
                                    searchText = ""
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(AppTheme.cardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)

                        // Search Results Section when query entered
                        if !searchText.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("SEARCH RESULTS (\(searchResults.count))")
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(AppTheme.textSecondary)
                                        .tracking(0.6)
                                    Spacer()
                                }

                                if searchResults.isEmpty {
                                    VStack(spacing: 8) {
                                        Text("No matching items found")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(AppTheme.textPrimary)
                                        Text("Try searching with a different keyword or domain.")
                                            .font(.caption)
                                            .foregroundColor(AppTheme.textSecondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .liquidGlassCard(cornerRadius: 16)
                                } else {
                                    ForEach(searchResults) { item in
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

                        // Preview Counts: Returned Today & Waiting in Inbox
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            SummaryMetricCard(
                                title: "Returned Today",
                                count: returnedTodayCount,
                                icon: "arrow.counterclockwise",
                                theme: .green
                            )
                            SummaryMetricCard(
                                title: "Waiting in Inbox",
                                count: inboxItems.count,
                                icon: "tray.fill",
                                theme: .black
                            )
                        }

                        // WAITING FOR YOU Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("WAITING FOR YOU")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(AppTheme.textSecondary)
                                    .tracking(0.6)
                                Spacer()
                                if !inboxItems.isEmpty {
                                    Text("\(inboxItems.count) in inbox")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                            }

                            if let heroItem = inboxItems.first {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        ZStack {
                                            Circle()
                                                .fill(AppTheme.accent)
                                                .frame(width: 24, height: 24)
                                            Image(systemName: "tray.fill")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(.black)
                                        }
                                        Text("Next up in review queue")
                                            .font(.caption.weight(.semibold))
                                            .foregroundColor(AppTheme.textSecondary)
                                        Spacer()
                                        Text(heroItem.parsedContentType.rawValue.capitalized)
                                            .font(.caption2.weight(.bold))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Capsule().fill(AppTheme.accent))
                                            .foregroundColor(.black)
                                    }

                                    NavigationLink(destination: ItemDetailView(item: heroItem)) {
                                        VStack(alignment: .leading, spacing: 10) {
                                            RichMediaBanner(type: heroItem.parsedContentType, url: heroItem.url, title: heroItem.title)

                                            Text(heroItem.title)
                                                .font(.headline)
                                                .foregroundColor(AppTheme.textPrimary)
                                                .lineLimit(2)

                                            HStack {
                                                if let domain = heroItem.domain {
                                                    Text(domain)
                                                        .font(.caption)
                                                        .foregroundColor(AppTheme.textSecondary)
                                                }
                                                Spacer()
                                                Text("Review Now →")
                                                    .font(.caption.weight(.bold))
                                                    .foregroundColor(AppTheme.textPrimary)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(16)
                                .liquidGlassCard(cornerRadius: 20)
                            } else {
                                // Proper Themed Empty State for Waiting For You
                                VStack(spacing: 10) {
                                    ZStack {
                                        Circle()
                                            .fill(AppTheme.accent.opacity(0.35))
                                            .frame(width: 44, height: 44)
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 22, weight: .semibold))
                                            .foregroundColor(.black)
                                    }
                                    Text("All caught up")
                                        .font(.subheadline.weight(.bold))
                                        .foregroundColor(AppTheme.textPrimary)
                                    Text("Nothing waiting in your inbox right now.")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(22)
                                .liquidGlassCard(cornerRadius: 18)
                            }
                        }

                        // COMING UP (Upcoming Returns Scheduled) Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("COMING UP")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(AppTheme.textSecondary)
                                    .tracking(0.6)
                                Spacer()
                                if !upcomingItems.isEmpty {
                                    Text("\(upcomingItems.count) scheduled")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                            }

                            if !upcomingItems.isEmpty {
                                ForEach(upcomingItems.prefix(3)) { item in
                                    NavigationLink(destination: ItemDetailView(item: item)) {
                                        HStack(spacing: 14) {
                                            // Scheduled Date Badge
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .fill(AppTheme.darkSurface)
                                                    .frame(width: 48, height: 48)
                                                VStack(spacing: 1) {
                                                    Image(systemName: "calendar.badge.clock")
                                                        .font(.system(size: 13, weight: .bold))
                                                        .foregroundColor(AppTheme.accent)
                                                    if let ret = item.returnAt {
                                                        Text(formatReturnDate(ret))
                                                            .font(.system(size: 9, weight: .bold))
                                                            .foregroundColor(AppTheme.textOnDark)
                                                            .lineLimit(1)
                                                    }
                                                }
                                            }

                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(item.title)
                                                    .font(.subheadline.weight(.semibold))
                                                    .foregroundColor(AppTheme.textPrimary)
                                                    .lineLimit(1)
                                                HStack(spacing: 6) {
                                                    if let domain = item.domain {
                                                        Text(domain)
                                                            .font(.caption2)
                                                            .foregroundColor(AppTheme.textSecondary)
                                                    }
                                                    if let ret = item.returnAt {
                                                        Text("• Returns \(formatRelativeReturnDate(ret))")
                                                            .font(.caption2.weight(.medium))
                                                            .foregroundColor(AppTheme.textSecondary)
                                                    }
                                                }
                                            }

                                            Spacer()

                                            Image(systemName: "chevron.right")
                                                .font(.caption2.weight(.semibold))
                                                .foregroundColor(AppTheme.textTertiary)
                                        }
                                        .padding(14)
                                        .liquidGlassCard(cornerRadius: 18)
                                    }
                                    .buttonStyle(.plain)
                                }
                            } else {
                                // Proper Themed Empty State for Coming Up
                                VStack(spacing: 10) {
                                    ZStack {
                                        Circle()
                                            .fill(AppTheme.darkSurface)
                                            .frame(width: 44, height: 44)
                                        Image(systemName: "calendar.badge.clock")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(AppTheme.accent)
                                    }
                                    Text("No upcoming returns")
                                        .font(.subheadline.weight(.bold))
                                        .foregroundColor(AppTheme.textPrimary)
                                    Text("Items you schedule to review later will resurface here.")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(22)
                                .liquidGlassCard(cornerRadius: 18)
                            }
                        }


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
                .trackPullDownForLaterAI()
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingQuickCapture) {
                QuickCaptureSheet()
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

    private func formatReturnDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }

    private func formatRelativeReturnDate(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInTomorrow(date) {
            return "tomorrow"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}
