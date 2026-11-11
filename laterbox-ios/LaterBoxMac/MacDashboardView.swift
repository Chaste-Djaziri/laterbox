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
    @State private var selection: DashboardRoute = .inbox
    @State private var showingQuickSave = false
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
        .sheet(isPresented: $showingQuickSave) {
            MacQuickSavePlaceholder()
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
                .help("Cloud storage usage will appear after sync integration")
                .accessibilityLabel("Cloud storage usage unavailable")

            Image(systemName: "arrow.triangle.2.circlepath.icloud")
                .font(.system(size: 22))
                .foregroundStyle(DashboardStyle.muted)
                .frame(width: 52, height: 42)
                .help("Cloud synchronization is not yet connected on macOS")
                .accessibilityLabel("Cloud synchronization unavailable")
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
        return Button { selection = route } label: {
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

    private var header: some View {
        HStack(spacing: 16) {
            Text(selection.rawValue)
                .font(.system(size: 21, weight: .semibold))
            Spacer()
            Button { selection = .inbox } label: {
                Image(systemName: "house")
            }
            .buttonStyle(.plain)
            .help("Inbox")
            Button { signOut() } label: {
                Image(systemName: "rectangle.portrait.and.arrow.right")
            }
            .buttonStyle(.plain)
            .help("Sign out")
            .accessibilityLabel("Sign out")
        }
        .padding(.leading, 30)
        .padding(.trailing, 24)
        .frame(height: 74)
    }

    private var page: some View {
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

private struct MacQuickSavePlaceholder: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "bookmark")
                .font(.system(size: 32))
            Text("Quick Save")
                .font(.title2.weight(.semibold))
            Text("Saving items on macOS will be available when the shared data layer is connected.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Close") { dismiss() }
                .keyboardShortcut(.cancelAction)
        }
        .padding(32)
        .frame(width: 400)
    }
}
