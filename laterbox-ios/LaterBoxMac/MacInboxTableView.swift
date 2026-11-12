// laterbox-ios/LaterBoxMac/MacInboxTableView.swift
import SwiftUI

// Presentational inbox model. The native sync layer will supply real items;
// never populate this view with example rows in production.
struct MacInboxEntry: Identifiable {
    enum Category {
        case article, media, update
    }

    let id: String
    let source: String
    let title: String
    let snippet: String
    let date: Date
    let category: Category
    let isStarred: Bool
    let isUnread: Bool
}

struct MacInboxTableView: View {
    let items: [MacInboxEntry]
    let isConnected: Bool
    let isLoading: Bool
    let syncError: String?
    let onRefresh: () async -> Void
    let onQuickSave: () -> Void

    private enum CategoryTab: String, CaseIterable, Identifiable {
        case primary = "Primary"
        case articles = "Articles"
        case media = "Media"
        case updates = "Updates"

        var id: String { rawValue }
        var icon: String {
            switch self {
            case .primary: "tray"
            case .articles: "tag"
            case .media: "play.rectangle"
            case .updates: "info.circle"
            }
        }
        var subtitle: String {
            switch self {
            case .primary: "All inbox items"
            case .articles: "Articles & reads"
            case .media: "Videos & audio"
            case .updates: "Notes & tasks"
            }
        }
    }

    @State private var activeTab: CategoryTab = .primary
    @State private var newestFirst = true
    @State private var selectedIDs: Set<String> = []
    @Environment(\.colorScheme) private var scheme

    private var dark: Bool { scheme == .dark }
    private var surface: Color {
        dark ? Color(red: 38 / 255, green: 40 / 255, blue: 43 / 255) : .white
    }
    private var toolbarSurface: Color {
        dark ? Color(red: 42 / 255, green: 44 / 255, blue: 47 / 255) : .white
    }
    private var border: Color {
        dark ? .white.opacity(0.10) : Color(red: 228 / 255, green: 224 / 255, blue: 213 / 255)
    }
    private var muted: Color { dark ? .white.opacity(0.54) : .black.opacity(0.48) }
    private var accent: Color { Color(red: 230 / 255, green: 237 / 255, blue: 176 / 255) }

    private var visibleItems: [MacInboxEntry] {
        let filtered = items.filter { item in
            switch activeTab {
            case .primary: true
            case .articles: item.category == .article
            case .media: item.category == .media
            case .updates: item.category == .update
            }
        }
        return filtered.sorted { newestFirst ? $0.date > $1.date : $0.date < $1.date }
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            categories
            if visibleItems.isEmpty && isLoading && !isConnected {
                ProgressView("Syncing your inbox…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if visibleItems.isEmpty {
                emptyState
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(visibleItems) { item in
                            inboxRow(item)
                            Rectangle().fill(border.opacity(0.7)).frame(height: 1)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(border, lineWidth: 1)
                .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var toolbar: some View {
        HStack(spacing: 13) {
            Toggle("Select all", isOn: Binding(
                get: { !visibleItems.isEmpty && visibleItems.allSatisfy { selectedIDs.contains($0.id) } },
                set: { checked in
                    if checked { selectedIDs.formUnion(visibleItems.map(\.id)) }
                    else { selectedIDs.subtract(visibleItems.map(\.id)) }
                }
            ))
            .toggleStyle(.checkbox)
            .labelsHidden()
            .disabled(visibleItems.isEmpty)
            .help("Select all visible items")

            Menu {
                Button("All") { selectedIDs.formUnion(visibleItems.map(\.id)) }
                    .disabled(visibleItems.isEmpty)
                Button("None") { selectedIDs.removeAll() }
                    .disabled(selectedIDs.isEmpty)
                Button("Starred") { selectedIDs = Set(visibleItems.filter(\.isStarred).map(\.id)) }
                    .disabled(visibleItems.isEmpty)
                Button("Unstarred") { selectedIDs = Set(visibleItems.filter { !$0.isStarred }.map(\.id)) }
                    .disabled(visibleItems.isEmpty)
            } label: {
                Image(systemName: "chevron.down").font(.system(size: 10, weight: .semibold))
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .frame(width: 15)
            .help("Selection options")

            Button {
                Task { await onRefresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 27, height: 29)
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
            .help("Sync inbox now")

            toolbarIcon("archivebox", label: "Archive")
                .disabled(selectedIDs.isEmpty)
                .help("Archive will be available after macOS sync is connected")
                .disabled(true)

            toolbarIcon("trash", label: "Delete")
                .disabled(true)
                .help("Delete will be available after macOS sync is connected")

            Spacer()

            Text(visibleItems.isEmpty ? "0 items" : "\(visibleItems.count) items")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(muted)
                .monospacedDigit()

            Button {
                newestFirst.toggle()
            } label: {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 14))
                    .frame(width: 29, height: 29)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(newestFirst ? "Newest first" : "Oldest first")

            toolbarIcon("chevron.left", label: "Previous page").disabled(true)
            toolbarIcon("chevron.right", label: "Next page").disabled(true)
        }
        .padding(.horizontal, 17)
        .frame(height: 49)
        .background(toolbarSurface)
        .overlay(alignment: .bottom) { border.frame(height: 1) }
    }

    private func toolbarIcon(_ symbol: String, label: String) -> some View {
        Button {} label: {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 27, height: 29)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var categories: some View {
        HStack(spacing: 0) {
            ForEach(CategoryTab.allCases) { tab in
                let active = activeTab == tab
                Button {
                    activeTab = tab
                    selectedIDs.removeAll()
                } label: {
                    HStack(alignment: .center, spacing: 11) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(active ? (dark ? accent : .primary) : muted)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(tab.rawValue)
                                .font(.system(size: 13, weight: active ? .bold : .semibold))
                                .foregroundStyle(active ? .primary : .secondary)
                            Text(tab.subtitle)
                                .font(.system(size: 10))
                                .foregroundStyle(muted)
                                .lineLimit(1)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity)
                    .frame(height: 65)
                    .background {
                        Rectangle()
                            .fill(active
                                  ? (dark ? Color.white.opacity(0.045) : Color(red: 250 / 255, green: 248 / 255, blue: 245 / 255))
                                  : Color.clear)
                    }
                    .overlay(alignment: .bottom) {
                        if active {
                            Rectangle()
                                .fill(dark ? accent : Color(red: 23 / 255, green: 23 / 255, blue: 17 / 255))
                                .frame(height: 3)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(active ? [.isSelected] : [])
            }
        }
        .clipShape(Rectangle())
        .overlay(alignment: .bottom) { border.frame(height: 1) }
    }

    private var emptyTitle: String {
        if !isConnected { return "Your saves are waiting for you" }
        switch activeTab {
        case .primary: return "All clear, for now"
        case .articles: return "Your reading list starts here"
        case .media: return "Nothing to watch or listen to yet"
        case .updates: return "No notes or tasks yet"
        }
    }

    private var emptyDescription: String {
        if !isConnected {
            return "Your Mac inbox is getting ready. Your saved links, notes and ideas are still available on Laterbox Web."
        }
        switch activeTab {
        case .primary: return "A little breathing room! When you save something for later, it will show up here."
        case .articles: return "Save articles and interesting reads to find them when you have a moment."
        case .media: return "Keep videos, podcasts and music you want to revisit together."
        case .updates: return "Quick thoughts and things to do will find their home here."
        }
    }

    private var emptyState: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(accent.opacity(dark ? 0.075 : 0.20))
                    .frame(width: 172, height: 172)

                Circle()
                    .strokeBorder(accent.opacity(dark ? 0.20 : 0.5), lineWidth: 1)
                    .frame(width: 142, height: 142)

                RoundedRectangle(cornerRadius: 19, style: .continuous)
                    .fill(dark ? Color(red: 48 / 255, green: 51 / 255, blue: 51 / 255) : Color.white)
                    .frame(width: 94, height: 84)
                    .shadow(color: .black.opacity(dark ? 0.18 : 0.06), radius: 18, y: 9)

                Image(systemName: isConnected ? activeTab.icon : "tray.full")
                    .font(.system(size: 37, weight: .ultraLight))
                    .foregroundStyle(dark ? accent : Color(red: 42 / 255, green: 49 / 255, blue: 33 / 255))

                Image(systemName: isConnected ? "sparkle" : "arrow.triangle.2.circlepath")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(red: 42 / 255, green: 49 / 255, blue: 33 / 255))
                    .frame(width: 31, height: 31)
                    .background(accent, in: Circle())
                    .offset(x: 49, y: -39)
            }
            .accessibilityHidden(true)
            .padding(.bottom, 25)

            Text(emptyTitle)
                .font(.system(size: 23, weight: .semibold))
                .tracking(-0.6)
                .multilineTextAlignment(.center)

            Text(emptyDescription)
                .font(.system(size: 13))
                .foregroundStyle(muted)
                .lineSpacing(4)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
                .padding(.top, 9)

            if !isConnected {
                if let syncError {
                    Text(syncError)
                        .font(.system(size: 11))
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
                Button {
                    Task { await onRefresh() }
                } label: {
                    Label(isLoading ? "Connecting…" : "Retry sync", systemImage: "arrow.clockwise")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
                Link(destination: URL(string: "https://laterbox.dev")!) {
                    Label("Open Laterbox Web", systemImage: "arrow.up.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(dark ? Color.black : Color(red: 23 / 255, green: 23 / 255, blue: 17 / 255))
                        .padding(.horizontal, 19)
                        .frame(height: 40)
                        .background(accent, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .help("Open Laterbox in your browser")
                .padding(.top, 22)

                Text("Refresh to check for recently saved items.")
                    .font(.system(size: 11))
                    .foregroundStyle(muted.opacity(0.85))
                    .padding(.top, 13)
            } else {
                Button(action: onQuickSave) {
                    Label("Try Quick Save", systemImage: "plus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(dark ? Color.black : Color(red: 23 / 255, green: 23 / 255, blue: 17 / 255))
                        .padding(.horizontal, 19)
                        .frame(height: 40)
                        .background(accent, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .help("Quick Save preview; saving is not connected yet")
                .padding(.top, 22)
            }
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
    }

    private func inboxRow(_ item: MacInboxEntry) -> some View {
        HStack(spacing: 13) {
            Toggle("Select item", isOn: Binding(
                get: { selectedIDs.contains(item.id) },
                set: { checked in
                    if checked { selectedIDs.insert(item.id) }
                    else { selectedIDs.remove(item.id) }
                }
            ))
            .toggleStyle(.checkbox)
            .labelsHidden()
            .help("Select \(item.title)")

            Image(systemName: item.isStarred ? "star.fill" : "star")
                .font(.system(size: 14))
                .foregroundStyle(item.isStarred ? Color.orange : muted)
                .frame(width: 22)

            Image(systemName: item.category == .media ? "play.rectangle" :
                    item.category == .update ? "note.text" : "link")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 32)
                .background(dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04),
                            in: RoundedRectangle(cornerRadius: 10))

            Text(item.source)
                .font(.system(size: 12, weight: item.isUnread ? .semibold : .regular))
                .frame(width: 118, alignment: .leading)
                .lineLimit(1)

            HStack(spacing: 6) {
                Text(item.title)
                    .font(.system(size: 12, weight: item.isUnread ? .semibold : .medium))
                    .lineLimit(1)
                Text("— \(item.snippet)")
                    .font(.system(size: 12))
                    .foregroundStyle(muted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(item.date, style: .date)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(muted)
                .frame(width: 85, alignment: .trailing)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .frame(height: 59)
        .background(selectedIDs.contains(item.id) ? accent.opacity(dark ? 0.12 : 0.3) : Color.clear)
    }
}
