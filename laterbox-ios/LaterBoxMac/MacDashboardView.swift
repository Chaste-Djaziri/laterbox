// laterbox-ios/LaterBoxMac/MacDashboardView.swift
import SwiftUI
import AppKit

private enum DashboardStyle {
    static let lime = Color(red: 230 / 255, green: 237 / 255, blue: 176 / 255)
    static let ink = Color(red: 23 / 255, green: 23 / 255, blue: 17 / 255)
    static let cream = Color(red: 247 / 255, green: 245 / 255, blue: 238 / 255)
    static let muted = Color(red: 133 / 255, green: 135 / 255, blue: 124 / 255)
}


private struct SidebarQuota: Decodable {
    let storagePlan: String?
    let storagePlanKey: String?
    let storageUsedBytes: Int64?
    let storageLimitBytes: Int64?
}

@MainActor private final class SidebarQuotaModel: ObservableObject {
    @Published var quota: SidebarQuota?
    @Published var loading = false
    @Published var error: String?
    private var lastRefresh: Date?
    func refresh(_ cloud: MacCloudSyncStore, force: Bool = false) async {
        guard !loading else { return }
        if !force, let lastRefresh, Date().timeIntervalSince(lastRefresh) < 120 { return }
        loading = true
        defer { loading = false }
        do {
            let result = try await cloud.billingAPI("/entitlement")
            quota = try JSONDecoder().decode(SidebarQuota.self, from: result)
            error = nil
            lastRefresh = Date()
        } catch { self.error = error.localizedDescription }
    }
    var percent: Double? {
        guard let used = quota?.storageUsedBytes, used >= 0,
              let limit = quota?.storageLimitBytes, limit > 0 else { return nil }
        return Double(used) / Double(limit) * 100
    }
    var level: Int {
        guard let percent else { return 0 }
        if percent >= 100 { return 3 }
        if percent >= 95 { return 2 }
        if percent >= 80 { return 1 }
        return 0
    }
    var tint: Color {
        switch level {
        case 3: return Color(red: 0.74, green: 0.24, blue: 0.24)
        case 2: return Color(red: 0.80, green: 0.40, blue: 0.24)
        case 1: return Color(red: 0.83, green: 0.58, blue: 0.19)
        default: return Color(red: 0.54, green: 0.65, blue: 0.40)
        }
    }
    var title: String {
        guard let percent else { return "Storage usage unavailable" }
        if percent >= 100 { return "Storage full" }
        if percent >= 95 { return "Storage nearly full" }
        if percent >= 80 { return "Storage almost full" }
        return "Cloud storage"
    }
    var details: String {
        guard let percent else { return "We could not retrieve your current cloud storage usage." }
        if percent >= 100 { return "Your limit has been reached. Upgrade or remove stored files." }
        if percent >= 95 { return "Less than 5% remains. Upgrade or clear unused files soon." }
        if percent >= 80 { return "Over 80% used. Consider freeing space or upgrading." }
        return "Your cloud storage is within its plan limit."
    }
    var plan: String {
        let key = (quota?.storagePlanKey ?? quota?.storagePlan ?? "free")
            .replacingOccurrences(of: "_month", with: "")
            .replacingOccurrences(of: "_year", with: "")
        let plans = ["free": "Free", "plus": "Plus · 10 GB", "plus50": "Plus 50 · 50 GB",
                     "vault": "Vault · 100 GB", "vault250": "Vault · 250 GB",
                     "vault500": "Vault · 500 GB", "vault1tb": "Vault · 1 TB",
                     "vault2tb": "Vault · 2 TB"]
        return plans[key] ?? key.capitalized
    }
    static func format(_ bytes: Int64?) -> String {
        guard let bytes, bytes >= 0 else { return "Unavailable" }
        if bytes == 0 { return "0 MB" }
        if bytes < 1_000_000 { return String(format: "%.0f KB", ceil(Double(bytes) / 1000)) }
        if bytes < 1_000_000_000 { return String(format: "%.1f MB", Double(bytes) / 1_000_000) }
        return String(format: "%.2f GB", Double(bytes) / 1_000_000_000)
    }
}

private struct SidebarQuotaPopover: View {
    @ObservedObject var model: SidebarQuotaModel
    let refresh: () -> Void
    let openPlans: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("LATERBOX CLOUD").font(.system(size: 10, weight: .bold))
                .tracking(1.8).foregroundStyle(.secondary)
            Text("Storage usage").font(.system(size: 18, weight: .bold))
            Divider()
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("CURRENT PLAN").font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                    Text(model.plan).font(.system(size: 16, weight: .bold))
                }
                Spacer()
                Text(model.percent.map { "\(Int($0.rounded()))%" } ?? "—")
                    .font(.system(size: 23, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.1))
                    Capsule().fill(model.tint)
                        .frame(width: geometry.size.width * min(1, max(0, (model.percent ?? 0) / 100)))
                }
            }
            .frame(height: 9)
            .accessibilityLabel("Cloud storage used")
            HStack {
                Text("\(SidebarQuotaModel.format(model.quota?.storageUsedBytes)) used")
                Spacer()
                Text("\(SidebarQuotaModel.format(model.quota?.storageLimitBytes)) total")
            }
            .font(.system(size: 11)).foregroundStyle(.secondary)
            HStack(alignment: .top, spacing: 9) {
                Image(systemName: model.level > 0 ? "exclamationmark.triangle" :
                        model.percent == nil ? "icloud" : "checkmark.circle")
                    .foregroundStyle(model.tint)
                VStack(alignment: .leading, spacing: 5) {
                    Text(model.title).font(.system(size: 12, weight: .bold))
                    Text(model.details).font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(12)
            .background(model.tint.opacity(0.11), in: RoundedRectangle(cornerRadius: 12))
            if model.error != nil {
                Text("Latest storage refresh failed.")
                    .font(.system(size: 11)).foregroundStyle(.orange)
            }
            HStack {
                Button(action: refresh) { Label("Refresh", systemImage: "arrow.clockwise") }
                    .disabled(model.loading)
                Button(action: openPlans) {
                    Label(model.level > 0 ? "Get more space" : "View plans",
                          systemImage: "arrow.up.right")
                }
                .buttonStyle(.borderedProminent)
                .tint(DashboardStyle.ink)
            }
        }
        .padding(19)
        .frame(width: 310)
    }
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
    @State private var selectedCollectionID: String?
    @State private var collectionsPopupOpen = false
    @State private var todayClock = Date()
    @StateObject private var cloud = MacCloudSyncStore()
    @StateObject private var quotaModel = SidebarQuotaModel()
    @State private var quotaPopupOpen = false
    @AppStorage("laterbox.mac.automaticRefresh") private var automaticRefresh = true
    @ObservedObject private var theme = MacAppearanceSettings.shared
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
            await quotaModel.refresh(cloud, force: true)
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                guard !Task.isCancelled else { break }
                todayClock = Date()
                if automaticRefresh { await cloud.refresh() }
                await quotaModel.refresh(cloud)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            todayClock = Date()
            if automaticRefresh { Task { await cloud.refresh() } }
            Task { await quotaModel.refresh(cloud) }
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

            Button {
                quotaPopupOpen.toggle()
                if quotaPopupOpen { Task { await quotaModel.refresh(cloud, force: true) } }
            } label: {
                ZStack {
                    Circle().stroke(Color.primary.opacity(0.12), lineWidth: 3.5)
                    Circle()
                        .trim(from: 0, to: min(1, max(0, (quotaModel.percent ?? 0) / 100)))
                        .stroke(quotaModel.tint, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Image(systemName: "externaldrive")
                        .font(.system(size: 19))
                        .foregroundStyle(quotaModel.level > 0 ? quotaModel.tint : DashboardStyle.muted)
                }
                .frame(width: 44, height: 44)
                .frame(width: 52, height: 52)
                .contentShape(RoundedRectangle(cornerRadius: 16))
                .overlay(alignment: .topTrailing) {
                    if quotaModel.level > 0 {
                        Text("!").font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(.white)
                            .frame(width: 17, height: 17)
                            .background(quotaModel.tint, in: Circle())
                    }
                }
            }
            .buttonStyle(.plain)
            .help(quotaModel.percent.map { "Cloud storage · \(Int($0.rounded()))% used" } ?? quotaModel.title)
            .accessibilityLabel(quotaModel.title)
            .popover(isPresented: $quotaPopupOpen, arrowEdge: .trailing) {
                SidebarQuotaPopover(model: quotaModel,
                    refresh: { Task { await quotaModel.refresh(cloud, force: true) } },
                    openPlans: { quotaPopupOpen = false; selection = .plans })
            }

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

    /// Match each native page's filter rather than counting all captured items.
    private func itemCount(for route: DashboardRoute) -> Int? {
        switch route {
        case .inbox:
            return cloud.items.count
        case .today:
            let cutoff = todayClock.addingTimeInterval(-24 * 60 * 60)
            return cloud.activeItems.filter { item in
                let due = item.isUnread || (item.returnDate.map { $0 <= todayClock } ?? false)
                guard due, let arrival = item.inboxArrival else { return false }
                return arrival >= cutoff && arrival <= todayClock
            }.count
        case .upcoming:
            let tomorrow = Calendar.current.date(
                byAdding: .day, value: 1,
                to: Calendar.current.startOfDay(for: todayClock)
            ) ?? todayClock.addingTimeInterval(86400)
            return cloud.activeItems.filter { item in
                !item.isUnread && (item.returnDate.map { $0 >= tomorrow } ?? false)
            }.count
        case .someday:
            return cloud.activeItems.filter { !$0.isUnread && $0.returnDate == nil }.count
        case .starred:
            return cloud.allItems.filter(\.isStarred).count
        case .kept:
            return cloud.allItems.filter { $0.lifecycleStatus == "saved" }.count
        case .archived:
            return cloud.allItems.filter { $0.lifecycleStatus == "archived" }.count
        case .trash:
            return cloud.deletedItems.count
        case .collections:
            return cloud.collections.count
        default:
            return nil
        }
    }

    private func navigationItem(_ route: DashboardRoute) -> some View {
        let active = selection == route
        let count = itemCount(for: route)
        return Button {
            if route == .collections { collectionsPopupOpen.toggle() }
            else { selection = route; openedItemID = nil; collectionsPopupOpen = false }
        } label: {
            Image(systemName: route.icon)
                .font(.system(size: 23, weight: active ? .semibold : .regular))
                .foregroundStyle(active ? DashboardStyle.ink : (scheme == .dark ? Color.white.opacity(0.64) : DashboardStyle.muted))
                .frame(width: 52, height: 52)
                .background(active ? DashboardStyle.lime : Color.clear, in: RoundedRectangle(cornerRadius: 16))
                .overlay(alignment: .topTrailing) {
                    if let count, count > 0 {
                        Text(count > 99 ? "99+" : String(count))
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(active ? Color.white : DashboardStyle.ink)
                            .padding(.horizontal, count > 9 ? 5 : 4)
                            .frame(minWidth: 17, minHeight: 17)
                            .background(active ? DashboardStyle.ink : DashboardStyle.lime, in: Capsule())
                            .overlay {
                                Capsule().strokeBorder(mainBackground, lineWidth: 1.5)
                            }
                            .offset(x: 7, y: -5)
                            .accessibilityHidden(true)
                            .allowsHitTesting(false)
                    }
                }
                .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .help(count.map { "\(route.rawValue) · \($0) items" } ?? route.rawValue)
        .accessibilityLabel(count.map { "\(route.rawValue), \($0) items" } ?? route.rawValue)
        .accessibilityAddTraits(active ? [.isSelected] : [])
        .popover(isPresented: Binding(
            get: { route == .collections && collectionsPopupOpen },
            set: { if !$0 { collectionsPopupOpen = false } }
        ), arrowEdge: .trailing) {
            VStack(spacing: 10) {
                MacCollectionsView(
                    cloud: cloud,
                    selectedCollectionID: $selectedCollectionID,
                    onOpenItem: { id in
                        selection = .collections
                        openedItemID = id
                        collectionsPopupOpen = false
                    },
                    onQuickSave: { showingQuickSave = true },
                    compact: true,
                    onChoose: {
                        selection = .collections
                        openedItemID = nil
                        collectionsPopupOpen = false
                    }
                )
                Button {
                    selection = .collections
                    openedItemID = nil
                    collectionsPopupOpen = false
                } label: {
                    Label("View all Collections", systemImage: "arrow.right")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                }
                .buttonStyle(.plain)
                .background(DashboardStyle.lime, in: RoundedRectangle(cornerRadius: 11))
                .foregroundStyle(DashboardStyle.ink)
            }
            .padding(10)
            .frame(width: 330, height: 440)
        }
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

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        theme.mode = scheme == .dark ? "light" : "dark"
                    }
                } label: {
                    Image(systemName: scheme == .dark ? "sun.max" : "moon")
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .background(headerSurface, in: Circle())
                .overlay(Circle().strokeBorder(headerBorder))
                .help(scheme == .dark ? "Switch to Light mode" : "Switch to Dark mode")
                .accessibilityLabel(scheme == .dark ? "Switch to Light mode" : "Switch to Dark mode")
                .accessibilityIdentifier("mac.theme.quickToggle")

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
        if (selection == .inbox || selection == .today || selection == .upcoming || selection == .someday || selection == .starred || selection == .archived || selection == .trash || selection == .kept || selection == .collections), let openedItemID {
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
                    onAttachmentURL: { id in try await cloud.attachmentDownloadURL(id) },
                    collections: cloud.collections,
                    onCollectionToggle: { collectionID, itemID, included in
                        try await cloud.setCollectionMembership(collectionID, itemID: itemID, included: included)
                    }
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
        } else if selection == .collections {
            MacCollectionsView(
                cloud: cloud,
                selectedCollectionID: $selectedCollectionID,
                onOpenItem: { id in openedItemID = id },
                onQuickSave: { showingQuickSave = true },
                compact: false
            )
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 18)
        } else if selection == .plans {
            MacPlansView(cloud: cloud)
        } else if selection == .earn {
            MacEarnView(cloud: cloud)
        } else if selection == .help {
            MacHelpView(cloud: cloud, accountEmail: accountEmail)
        } else if selection == .settings {
            MacSettingsView(
                cloud: cloud,
                accountEmail: accountEmail,
                onSignOut: signOut,
                onHelp: { selection = .help },
                onPlans: { selection = .plans }
            )
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
        } else if selection == .kept {
            MacKeptView(cloud: cloud,
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

