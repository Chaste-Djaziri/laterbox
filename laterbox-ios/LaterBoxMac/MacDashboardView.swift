// laterbox-ios/LaterBoxMac/MacDashboardView.swift
import SwiftUI
import AppKit

private enum DashboardStyle {
    static let lime = Color(red: 230 / 255, green: 237 / 255, blue: 176 / 255)
    static let ink = Color(red: 23 / 255, green: 23 / 255, blue: 17 / 255)
    static let cream = Color(red: 247 / 255, green: 245 / 255, blue: 238 / 255)
    static let muted = Color(red: 133 / 255, green: 135 / 255, blue: 124 / 255)
}

private enum DashboardRoute: String, CaseIterable, Identifiable {
    case inbox = "Inbox"
    case today = "Today"
    case upcoming = "Upcoming"
    case someday = "Someday"
    case starred = "Starred"
    case kept = "Kept"
    case archived = "Archived"
    case trash = "Recently Deleted"
    case collections = "Collections"
    case earn = "Earn"
    case guide = "Guide"
    case apps = "Apps"
    case help = "Help & FAQ"
    case settings = "Settings"
    case plans = "Plans"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .inbox: return "tray"
        case .today: return "clock"
        case .upcoming: return "calendar"
        case .someday: return "calendar.badge.clock"
        case .starred: return "star"
        case .kept: return "checkmark.circle"
        case .archived: return "archivebox"
        case .trash: return "trash"
        case .collections: return "folder"
        case .earn: return "dollarsign.circle"
        case .guide: return "safari"
        case .apps: return "arrow.down.app"
        case .help: return "questionmark.circle"
        case .settings: return "gearshape"
        case .plans: return "crown"
        }
    }

    static let core: [DashboardRoute] = [.inbox, .today, .upcoming, .someday, .starred, .kept, .archived, .trash]
    static let library: [DashboardRoute] = [.collections, .earn]
    static let utilities: [DashboardRoute] = [.guide, .apps, .help, .settings]
}

struct MacDashboardView: View {
    let signOut: () -> Void
    let accountEmail: String
    @State private var selection: DashboardRoute = .inbox
    @State private var showingQuickSave = false
    @State private var openedItemID: String?
    @State private var todayClock = Date()
    @StateObject private var cloud = MacCloudSyncStore()
    @State private var searchQuery = ""
    @State private var searchFocused = false
    @FocusState private var searchInputFocused: Bool
    @Environment(\.colorScheme) private var scheme

    private var mainBackground: Color {
        scheme == .dark ? Color(red: 27 / 255, green: 29 / 255, blue: 32 / 255) : DashboardStyle.cream
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            VStack(spacing: 0) {
                header
                page
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(mainBackground)
        .onChange(of: searchInputFocused) { _, focused in searchFocused = focused }
        .background {
            Button("") { searchInputFocused = true }
                .keyboardShortcut("k", modifiers: [.command])
                .hidden()
        }
        .task {
            todayClock = Date()
            await cloud.refresh()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                guard !Task.isCancelled else { break }
                todayClock = Date()
                await cloud.refresh()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            todayClock = Date()
            Task { await cloud.refresh() }
        }
        .sheet(isPresented: $showingQuickSave) {
            MacQuickSaveView(onSave: { draft in
                try await cloud.save(draft)
            })
        }
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            Button { selection = .inbox } label: {
                LaterBoxVectorMark(size: 38, appearance: .automatic, animates: false)
                    .frame(width: 52, height: 52)
                    .contentShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .help("LaterBox home")
            .accessibilityLabel("LaterBox home")

            divider
                .padding(.vertical, 13)

            Button { showingQuickSave = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(DashboardStyle.lime)
                    .frame(width: 52, height: 52)
                    .background(DashboardStyle.ink, in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .help("Save item")
            .accessibilityLabel("Save item")
            .keyboardShortcut("n", modifiers: [.command])

            ScrollView(showsIndicators: false) {
                VStack(spacing: 6) {
                    ForEach(DashboardRoute.core) { route in
                        navigationItem(route)
                    }
                    divider.padding(.vertical, 9)
                    ForEach(DashboardRoute.library) { route in
                        navigationItem(route)
                    }
                    divider.padding(.vertical, 9)
                    ForEach(DashboardRoute.utilities) { route in
                        navigationItem(route)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
                .padding(.bottom, 12)
            }

            divider
                .padding(.bottom, 8)

            navigationItem(.plans)

            Image(systemName: "externaldrive")
                .font(.system(size: 22))
                .foregroundStyle(DashboardStyle.muted)
                .frame(width: 52, height: 42)
                .help("Cloud storage quota display is not available in the Mac app yet")
                .accessibilityLabel("Cloud storage usage unavailable")

            Button {
                Task { await cloud.refresh() }
            } label: {
                Image(systemName: cloud.lastError != nil ? "icloud.slash" : (cloud.loading ? "arrow.triangle.2.circlepath.icloud" : "icloud"))
                    .font(.system(size: 22))
                    .foregroundStyle(cloud.lastError != nil ? Color.orange : (cloud.isConnected ? DashboardStyle.lime : DashboardStyle.muted))
                    .frame(width: 52, height: 42)
            }
            .buttonStyle(.plain)
            .disabled(cloud.loading)
            .help(cloud.lastError != nil ? "Sync failed · Click to retry" : cloud.isConnected ? "Synced · Click to refresh" : "Connect to cloud")
            .accessibilityLabel(cloud.isConnected ? "Cloud sync · Refresh" : "Cloud sync · Retry")
            .padding(.bottom, 7)
        }
        .frame(width: 84)
        .background(Color.clear)
    }

    private var divider: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(scheme == .dark ? Color.white.opacity(0.12) : Color(red: 229 / 255, green: 226 / 255, blue: 214 / 255))
            .frame(width: 36, height: 1)
    }

    private func navigationItem(_ route: DashboardRoute) -> some View {
        let active = selection == route
        return Button { selection = route; openedItemID = nil } label: {
            Image(systemName: route.icon)
                .font(.system(size: 23, weight: active ? .semibold : .regular))
                .foregroundStyle(active ? DashboardStyle.ink : (scheme == .dark ? Color.white.opacity(0.64) : DashboardStyle.muted))
                .frame(width: 52, height: 52)
                .background(active ? DashboardStyle.lime : Color.clear, in: RoundedRectangle(cornerRadius: 16))
                .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .help(route.rawValue)
        .accessibilityLabel(route.rawValue)
        .accessibilityAddTraits(active ? [.isSelected] : [])
    }

    private var searchMatches: [DashboardRoute] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }
        return DashboardRoute.allCases.filter { $0.rawValue.localizedCaseInsensitiveContains(query) }
    }

    private var accountInitials: String {
        let username = accountEmail.split(separator: "@").first.map(String.init) ?? ""
        let initials = String(username.prefix(2)).uppercased()
        return initials.isEmpty ? "U" : initials
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text(selection.rawValue)
                .font(.system(size: 23, weight: .bold))
                .tracking(-0.6)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: true, vertical: false)

            Spacer(minLength: 8)

            searchField
                .frame(maxWidth: 500)

            Spacer(minLength: 8)

            HStack(spacing: 9) {
                Button {} label: {
                    Label("AI organize", systemImage: "sparkles")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(DashboardStyle.ink)
                        .padding(.horizontal, 13)
                        .frame(height: 36)
                        .background(DashboardStyle.lime, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(true)
                .opacity(0.65)
                .help("AI organizing will be available after items are connected")

                Button { selection = .settings; dismissSearch() } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .background(headerSurface, in: Circle())
                .overlay(Circle().strokeBorder(headerBorder))
                .help("Settings")
                .accessibilityLabel("Settings")

                Menu {
                    Button { selection = .settings; dismissSearch() } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                    Divider()
                    Button(role: .destructive) { signOut() } label: {
                        Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } label: {
                    Text(accountInitials)
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .tracking(-0.4)
                        .foregroundStyle(DashboardStyle.lime)
                        .frame(width: 44, height: 44)
                        .background(DashboardStyle.ink, in: Circle())
                        .overlay {
                            Circle()
                                .strokeBorder(scheme == .dark ? Color.white.opacity(0.18) : Color.white, lineWidth: 2)
                        }
                        .contentShape(Circle())
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .frame(width: 44, height: 44)
                .help(accountEmail.isEmpty ? "Account" : accountEmail)
                .accessibilityLabel("Account")
            }
        }
        .padding(.leading, 2)
        .padding(.trailing, 20)
        .frame(height: 52)
    }

    private var headerSurface: Color {
        scheme == .dark
            ? Color(red: 41 / 255, green: 44 / 255, blue: 46 / 255)
            : .white
    }

    private var headerBorder: Color {
        scheme == .dark ? Color.white.opacity(0.13) : Color(red: 228 / 255, green: 224 / 255, blue: 213 / 255)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
            TextField("Search in \(selection.rawValue.lowercased()) or library…  ⌘K", text: $searchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($searchInputFocused)
                .onSubmit {
                    if let first = searchMatches.first {
                        selection = first
                        dismissSearch()
                    }
                }
                .onExitCommand(perform: dismissSearch)
                .accessibilityIdentifier("mac.dashboard.search")
            if !searchQuery.isEmpty {
                Button {
                    searchQuery = ""
                    searchInputFocused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Clear search")
            } else {
                Text("⌘K")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 15)
        .frame(height: 41)
        .background(headerSurface, in: Capsule())
        .overlay {
            Capsule().strokeBorder(searchInputFocused ? Color.primary.opacity(0.48) : headerBorder,
                                   lineWidth: searchInputFocused ? 1.4 : 1)
        }
        .popover(isPresented: Binding(
            get: { searchFocused && !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty },
            set: { if !$0 { searchFocused = false } }
        ), arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 7) {
                Text("Navigate to")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                if searchMatches.isEmpty {
                    Text("No matching sections")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .padding(9)
                } else {
                    ForEach(searchMatches) { route in
                        Button {
                            selection = route
                            dismissSearch()
                        } label: {
                            Label(route.rawValue, systemImage: route.icon)
                                .font(.system(size: 13))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 7)
                                .padding(.horizontal, 10)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 9))
                    }
                }
                Divider()
                Text("Saved-item search is not yet available in the Mac app.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 9)
            }
            .padding(12)
            .frame(width: 320)
        }
    }

    private func dismissSearch() {
        searchQuery = ""
        searchFocused = false
        searchInputFocused = false
    }

    @ViewBuilder
    private var page: some View {
        if (selection == .inbox || selection == .today || selection == .upcoming || selection == .someday || selection == .starred || selection == .archived || selection == .trash), let openedItemID {
            if let item = (selection == .trash ? cloud.deletedItems : cloud.allItems).first(where: { $0.id == openedItemID }) {
                MacItemDetailView(
                    item: item,
                    backDestination: selection.rawValue,
                    onBack: { self.openedItemID = nil },
                    onStar: { id, starred in try await cloud.setStarred(id, starred: starred) },
                    onKeep: { id in try await cloud.keep(id) },
                    onArchive: { id in try await cloud.archive(id) },
                    onRestore: { id in try await cloud.restoreToInbox(id) },
                    onDelete: { id in try await cloud.delete(id) },
                    onPermanentlyDelete: { id in try await cloud.permanentlyDelete(id) },
                    onReschedule: { id, date in try await cloud.reschedule(id, date: date) },
                    onChecklist: { id, entries in try await cloud.updateChecklist(id, entries: entries) },
                    onAttachments: { id in try await cloud.attachments(for: id) },
                    onAttachmentURL: { id in try await cloud.attachmentDownloadURL(id) }
                )
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 18)
            } else {
                VStack(spacing: 12) {
                    Text("This item is no longer available in this view.")
                    Button("Back to \(selection.rawValue)") { self.openedItemID = nil }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        } else if selection == .today {
            MacTodayView(cloud: cloud, now: todayClock,
                onQuickSave: { showingQuickSave = true },
                onOpenItem: { id in openedItemID = id })
        } else if selection == .upcoming {
            MacUpcomingView(cloud: cloud, now: todayClock,
                onQuickSave: { showingQuickSave = true },
                onOpenItem: { id in openedItemID = id })
        } else if selection == .someday {
            MacSomedayView(cloud: cloud,
                onQuickSave: { showingQuickSave = true },
                onOpenItem: { id in openedItemID = id })
        } else if selection == .starred {
            MacStarredView(cloud: cloud,
                onQuickSave: { showingQuickSave = true },
                onOpenItem: { id in openedItemID = id })
        } else if selection == .archived {
            MacArchivedView(cloud: cloud,
                onQuickSave: { showingQuickSave = true },
                onOpenItem: { id in openedItemID = id })
        } else if selection == .trash {
            MacRecentlyDeletedView(cloud: cloud,
                onQuickSave: { showingQuickSave = true },
                onOpenItem: { id in openedItemID = id })
        } else if selection == .inbox {
            VStack(spacing: 12) {
                MacInboxTableView(items: cloud.items, isConnected: cloud.isConnected,
                    isLoading: cloud.loading, syncError: cloud.lastError,
                    onRefresh: { await cloud.refresh() },
                    onStar: { id, value in try await cloud.setStarred(id, starred: value) },
                    onArchive: { id in try await cloud.archive(id) },
                    onDelete: { id in try await cloud.delete(id) },
                onQuickSave: { showingQuickSave = true },
                onOpenItem: { id in openedItemID = id })
                MacCloudSyncStatusView(
                    isConnected: cloud.isConnected, isLoading: cloud.loading,
                    isSaving: cloud.saving, lastError: cloud.lastError,
                    lastSynced: cloud.lastSynced, lastPushed: cloud.lastPushed,
                    onCheckUpdates: { await cloud.refresh() }
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 18)
        } else {
            VStack(spacing: 14) {
            Image(systemName: selection.icon)
                .font(.system(size: 38, weight: .ultraLight))
                .foregroundStyle(.secondary)
            Text(selection.rawValue)
                .font(.system(size: 21, weight: .semibold))
            Text("This macOS page is coming next.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

