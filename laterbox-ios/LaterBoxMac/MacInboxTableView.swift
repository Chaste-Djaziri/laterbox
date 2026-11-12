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
    let url: URL?
    var previewImageURL: URL?
    let date: Date
    let category: Category
    let isStarred: Bool
    let isUnread: Bool
    var itemType: String = "link"
    var returnDate: Date? = nil
    var tags: [String] = []
    var checklist: [MacChecklistEntry] = []
    var collectionNames: [String] = []
    var inboxArrival: Date? = nil
    var lifecycleStatus: String = "inbox"
}

struct MacInboxTableView: View {
    let items: [MacInboxEntry]
    let isConnected: Bool
    let isLoading: Bool
    let syncError: String?
    let onRefresh: () async -> Void
    let onStar: (String, Bool) async throws -> Void
    let onArchive: (String) async throws -> Void
    let onDelete: (String) async throws -> Void
    var onRestore: ((String) async throws -> Void)? = nil
    var onPermanentlyDelete: ((String) async throws -> Void)? = nil
    let onQuickSave: () -> Void
    let onOpenItem: (String) -> Void
    var contextTitle: String = "Inbox"
    var sortByInboxArrival: Bool = false
    var sortByReturnDate: Bool = false

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
    @State private var hoveredItemID: String?
    @State private var busyIDs: Set<String> = []
    @State private var pendingDelete: MacInboxEntry?
    @State private var pendingPermanentDelete: MacInboxEntry?
    @State private var actionError: String?
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
        return filtered.sorted {
            if sortByReturnDate {
                let left = $0.returnDate ?? .distantFuture
                let right = $1.returnDate ?? .distantFuture
                return newestFirst ? left < right : left > right
            }
            let lhs = sortByInboxArrival ? ($0.inboxArrival ?? $0.date) : $0.date
            let rhs = sortByInboxArrival ? ($1.inboxArrival ?? $1.date) : $1.date
            return newestFirst ? lhs > rhs : lhs < rhs
        }
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
        .confirmationDialog("Move item to Recently Deleted?", isPresented: Binding(
            get: { pendingDelete != nil },
            set: { if !$0 { pendingDelete = nil } }
        )) {
            if let item = pendingDelete {
                Button("Move to Recently Deleted", role: .destructive) {
                    pendingDelete = nil
                    performAction(item.id) { try await onDelete(item.id) }
                }
            }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: {
            Text("The item will be removed from your Inbox.")
        }
        .confirmationDialog("Permanently delete this item?", isPresented: Binding(
            get: { pendingPermanentDelete != nil },
            set: { if !$0 { pendingPermanentDelete = nil } }
        )) {
            if let item = pendingPermanentDelete, let onPermanentlyDelete {
                Button("Delete Forever", role: .destructive) {
                    pendingPermanentDelete = nil
                    performAction(item.id) { try await onPermanentlyDelete(item.id) }
                }
            }
            Button("Cancel", role: .cancel) { pendingPermanentDelete = nil }
        } message: {
            Text("This cannot be undone. Cloud attachments will also be permanently removed.")
        }
        .alert("Couldn't update item", isPresented: Binding(
            get: { actionError != nil },
            set: { if !$0 { actionError = nil } }
        )) {
            Button("OK") { actionError = nil }
        } message: {
            Text(actionError ?? "Please try again.")
        }
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
        if contextTitle == "Today" { return "Nothing new in the last 24 hours" }
        if contextTitle == "Upcoming" { return "Nothing scheduled ahead" }
        if contextTitle == "Someday" { return "Nothing saved for someday" }
        if contextTitle == "Starred" { return "No starred items yet" }
        if contextTitle == "Archived" { return "Archive is empty" }
        if contextTitle == "Kept" { return "Nothing kept yet" }
        if contextTitle == "Collection" { return "No items in this collection" }
        if contextTitle == "Recently Deleted" { return "Recently Deleted is empty" }
        switch activeTab {
        case .primary: return "All clear, for now"
        case .articles: return "Your reading list starts here"
        case .media: return "Nothing to watch or listen to yet"
        case .updates: return "No notes or tasks yet"
        }
    }

    private var emptyDescription: String {
        if !isConnected {
            return "Unable to connect to your saved items right now. Retry sync, or create a new capture here."
        }
        if contextTitle == "Today" { return "Items entering your Inbox, including scheduled returns, will appear here for 24 hours." }
        if contextTitle == "Upcoming" { return "Items scheduled for tomorrow and beyond will appear here. Save something and choose a future return time." }
        if contextTitle == "Someday" { return "Items without a return date will stay here until you choose when to revisit them." }
        if contextTitle == "Starred" { return "Star any item to find it here, including items you have kept or archived." }
        if contextTitle == "Archived" { return "Items you archive will be available here until you restore or delete them." }
        if contextTitle == "Kept" { return "Keep items you want to revisit and they will appear here in your library." }
        if contextTitle == "Collection" { return "Add items to this folder from Item Details, or capture something new." }
        if contextTitle == "Recently Deleted" { return "Deleted items will appear here until you restore or permanently remove them." }
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
                Button(action: onQuickSave) {
                    Label("Quick Save", systemImage: "plus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(dark ? Color.black : Color(red: 23 / 255, green: 23 / 255, blue: 17 / 255))
                        .padding(.horizontal, 19)
                        .frame(height: 40)
                        .background(accent, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .padding(.top, 16)

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
                .help("Save a new item to Laterbox")
                .padding(.top, 22)
            }
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
    }

    private func performAction(_ id: String, operation: @escaping () async throws -> Void) {
        guard !busyIDs.contains(id) else { return }
        busyIDs.insert(id)
        Task {
            defer { busyIDs.remove(id) }
            do {
                try await operation()
            } catch {
                actionError = error.localizedDescription
            }
        }
    }

    private func rowAction(_ symbol: String, help: String, disabled: Bool = false,
                           action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .medium))
                .frame(width: 28, height: 30)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .help(help)
        .accessibilityLabel(help)
    }

    // Image occupies the right edge only. The gradient mask fades the image
    // toward the message copy, as in the Web email table.
    private func rowArtwork(_ url: URL, source: URL?, hovered: Bool) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            case .failure:
                if let source {
                    MacFailedPreviewArtwork(source: source, failedURL: url)
                }
            default:
                EmptyView()
            }
        }
        .frame(width: 340, height: 55, alignment: .trailing)
        .clipped()
        .opacity(hovered ? 0.82 : 0.66)
        .mask {
            LinearGradient(stops: [
                .init(color: .clear, location: 0),
                .init(color: .black.opacity(0.3), location: 0.30),
                .init(color: .black.opacity(0.85), location: 0.61),
                .init(color: .black, location: 1)
            ], startPoint: .leading, endPoint: .trailing)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func inboxRow(_ item: MacInboxEntry) -> some View {
        let isHovered = hoveredItemID == item.id
        let isSelected = selectedIDs.contains(item.id)
        let isBusy = busyIDs.contains(item.id)
        return ZStack(alignment: .trailing) {
            Rectangle()
                .fill(isSelected
                      ? accent.opacity(dark ? 0.15 : 0.32)
                      : isHovered
                        ? (dark ? Color.white.opacity(0.075) : Color(red: 250 / 255, green: 248 / 255, blue: 245 / 255))
                        : surface)

            if let image = item.previewImageURL {
                rowArtwork(image, source: item.url, hovered: isHovered)
            }

            HStack(spacing: 12) {
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

                if contextTitle != "Recently Deleted" {
                Button {
                    performAction(item.id) { try await onStar(item.id, !item.isStarred) }
                } label: {
                    Image(systemName: item.isStarred ? "star.fill" : "star")
                        .font(.system(size: 15))
                        .foregroundStyle(item.isStarred ? Color.orange : muted)
                        .frame(width: 19, height: 29)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isBusy)
                .help(item.isStarred ? "Remove star" : "Star item")

                }

                Text(item.source)
                    .font(.system(size: 12, weight: .bold))
                    .lineLimit(1)
                    .frame(width: 154, alignment: .leading)

                HStack(spacing: 6) {
                    Text(item.title)
                        .font(.system(size: 12, weight: .bold))
                        .lineLimit(1)
                        .layoutPriority(1)
                    Text("—")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(muted)
                    Text(item.snippet)
                        .font(.system(size: 12))
                        .foregroundStyle(muted)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)

                if isHovered || isSelected {
                    HStack(spacing: 2) {
                        if contextTitle == "Recently Deleted" {
                            if let onRestore {
                                rowAction("arrow.uturn.backward", help: "Restore to Inbox", disabled: isBusy) {
                                    performAction(item.id) { try await onRestore(item.id) }
                                }
                            }
                            if onPermanentlyDelete != nil {
                                rowAction("trash", help: "Delete Forever", disabled: isBusy) {
                                    pendingPermanentDelete = item
                                }
                            }
                        } else {
                            if item.lifecycleStatus == "archived", let onRestore {
                                rowAction("arrow.uturn.backward", help: "Restore to Inbox", disabled: isBusy) {
                                    performAction(item.id) { try await onRestore(item.id) }
                                }
                            } else if item.lifecycleStatus != "archived" {
                                rowAction("archivebox", help: "Archive", disabled: isBusy) {
                                    performAction(item.id) { try await onArchive(item.id) }
                                }
                            }
                            rowAction("trash", help: "Move to Recently Deleted", disabled: isBusy) {
                                pendingDelete = item
                            }
                        }
                        if let url = item.url {
                            rowAction("arrow.up.right.square", help: "Open original link", disabled: isBusy) {
                                NSWorkspace.shared.open(url)
                            }
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background {
                        RoundedRectangle(cornerRadius: 9)
                            .fill(dark ? Color(red: 43 / 255, green: 45 / 255, blue: 48 / 255).opacity(0.97)
                                  : Color.white.opacity(0.97))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 9)
                            .strokeBorder(dark ? Color.white.opacity(0.18) : Color.black.opacity(0.13), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(dark ? 0.20 : 0.10), radius: 6, y: 2)
                    .fixedSize(horizontal: true, vertical: false)
                    .transition(.opacity)
                } else {
                    Text(sortByReturnDate ? (item.returnDate ?? item.date) : sortByInboxArrival ? (item.inboxArrival ?? item.date) : item.date, style: .date)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(dark ? Color.white.opacity(0.8) : Color.black.opacity(0.65))
                        .lineLimit(1)
                        .frame(width: 94, alignment: .trailing)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 5)
                        .background {
                            RoundedRectangle(cornerRadius: 7)
                                .fill(dark ? Color.black.opacity(0.65) : Color.white.opacity(item.previewImageURL == nil ? 0 : 0.78))
                        }
                }
            }
            .padding(.horizontal, 15)
            .frame(height: 55)
        }
        .frame(height: 55)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { onOpenItem(item.id) }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("View details for \(item.title)")
        .clipped()
        .onHover { hovering in
            if hovering { hoveredItemID = item.id }
            else if hoveredItemID == item.id { hoveredItemID = nil }
        }
        .animation(.easeOut(duration: 0.13), value: isHovered)
    }
}


/// A stored image can expire or forbid direct loading. Try the canonical
/// link again without causing a second endless retry of the same failed URL.
private struct MacFailedPreviewArtwork: View {
    let source: URL
    let failedURL: URL
    @State private var recovered: URL?

    var body: some View {
        Group {
            if let recovered {
                AsyncImage(url: recovered) { phase in
                    if case let .success(image) = phase {
                        image.resizable().scaledToFill()
                    }
                }
            }
        }
        .task(id: source) {
            if let replacement = await MacCaptureSuggestions.recoverImage(for: source),
               replacement != failedURL {
                recovered = replacement
            }
        }
    }
}
