//
//  MobileSidebarDrawer.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 11.10.26.
//

import SwiftUI
import SwiftData

public enum MailboxViewType: String, CaseIterable, Identifiable {
    case inbox = "Inbox"
    case starred = "Starred"
    case kept = "Kept"
    case archived = "Archived"
    case trash = "Recently Deleted"

    public var id: String { rawValue }

    public var systemIcon: String {
        switch self {
        case .inbox: return "tray.fill"
        case .starred: return "star.fill"
        case .kept: return "checkmark.circle.fill"
        case .archived: return "archivebox.fill"
        case .trash: return "trash.fill"
        }
    }
}

public struct MobileSidebarDrawer: View {
    @Binding public var isPresented: Bool
    public var activeMailbox: MailboxViewType = .inbox
    public var activeCollection: String? = nil

    public var onSelectMailbox: (MailboxViewType) -> Void = { _ in }
    public var onSelectCollection: (String) -> Void = { _ in }
    public var onOpenReturns: (ReturnSegment) -> Void = { _ in }
    public var onOpenLibrary: () -> Void = {}
    public var onOpenPlans: () -> Void = {}
    public var onOpenSettings: () -> Void = {}
    public var onOpenSaveItem: () -> Void = {}

    @Environment(\.modelContext) private var modelContext
    @ObservedObject var coordinator = SyncCoordinator.shared
    @ObservedObject var storeKit = StoreKitManager.shared
    @Query(sort: \LBItem.createdAt, order: .reverse) private var allItems: [LBItem]
    @Query(sort: \LBCollection.name, order: .forward) private var collections: [LBCollection]

    @State private var isCreatingCollection: Bool = false
    @State private var newCollectionName: String = ""

    public init(
        isPresented: Binding<Bool>,
        activeMailbox: MailboxViewType = .inbox,
        activeCollection: String? = nil,
        onSelectMailbox: @escaping (MailboxViewType) -> Void = { _ in },
        onSelectCollection: @escaping (String) -> Void = { _ in },
        onOpenReturns: @escaping (ReturnSegment) -> Void = { _ in },
        onOpenLibrary: @escaping () -> Void = {},
        onOpenPlans: @escaping () -> Void = {},
        onOpenSettings: @escaping () -> Void = {},
        onOpenSaveItem: @escaping () -> Void = {}
    ) {
        self._isPresented = isPresented
        self.activeMailbox = activeMailbox
        self.activeCollection = activeCollection
        self.onSelectMailbox = onSelectMailbox
        self.onSelectCollection = onSelectCollection
        self.onOpenReturns = onOpenReturns
        self.onOpenLibrary = onOpenLibrary
        self.onOpenPlans = onOpenPlans
        self.onOpenSettings = onOpenSettings
        self.onOpenSaveItem = onOpenSaveItem
    }

    // Live counts matching web logic
    private var inboxCount: Int {
        allItems.filter { $0.status == ItemStatus.inbox.rawValue }.count
    }

    private var starredCount: Int {
        allItems.filter { $0.favorite && $0.status != ItemStatus.deleted.rawValue }.count
    }

    private var keptCount: Int {
        allItems.filter { $0.status == ItemStatus.saved.rawValue }.count
    }

    private var archivedCount: Int {
        allItems.filter { $0.status == ItemStatus.archived.rawValue }.count
    }

    private var trashCount: Int {
        allItems.filter { $0.status == ItemStatus.deleted.rawValue }.count
    }

    private var todayCount: Int {
        let cal = Calendar.current
        let endOfToday = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: Date())) ?? Date()
        return allItems.filter {
            $0.status != ItemStatus.deleted.rawValue &&
            $0.status != ItemStatus.archived.rawValue &&
            $0.returnAt != nil &&
            ($0.returnAt! <= endOfToday)
        }.count
    }

    private var upcomingCount: Int {
        let cal = Calendar.current
        let endOfToday = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: Date())) ?? Date()
        return allItems.filter {
            $0.status != ItemStatus.deleted.rawValue &&
            $0.status != ItemStatus.archived.rawValue &&
            $0.returnAt != nil &&
            ($0.returnAt! > endOfToday)
        }.count
    }

    private var somedayCount: Int {
        allItems.filter {
            $0.status == ItemStatus.deferred.rawValue && $0.returnAt == nil
        }.count
    }

    private func collectionItemCount(named name: String) -> Int {
        allItems.filter {
            $0.status != ItemStatus.deleted.rawValue &&
            ($0.category.localizedCaseInsensitiveCompare(name) == .orderedSame ||
             $0.collectionName?.localizedCaseInsensitiveCompare(name) == .orderedSame)
        }.count
    }

    public var body: some View {
        VStack(spacing: 0) {
            headerView

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    saveItemButton
                    coreMailboxesSection
                    collectionsSection
                    activitySection
                }
                .padding(.top, 4)
                .padding(.bottom, 20)
            }

            bottomFooterView
        }
        .frame(maxHeight: .infinity)
        .background(AppTheme.canvasBackground)
        .overlay(
            Rectangle()
                .fill(Color.black.opacity(0.07))
                .frame(width: 1),
            alignment: .trailing
        )
    }

    // MARK: - Header
    private var headerView: some View {
        HStack(spacing: 10) {
            HStack(spacing: 10) {
                Image("LaterboxIconGreen")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 38, height: 38)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                Text("laterbox")
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(Color(hex: "171711"))
                    .tracking(-0.5)
            }

            Spacer()

            Button {
                close()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color.secondary)
                    .frame(width: 32, height: 32)
                    .background(Color.black.opacity(0.04), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close sidebar")
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 14)
    }

    // MARK: - Save Item Button
    private var saveItemButton: some View {
        Button {
            close()
            onOpenSaveItem()
            LBHaptic.medium()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .bold))
                Text("Save Item")
                    .font(.system(size: 16, weight: .heavy))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color(hex: "171711"))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.black.opacity(0.12), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 14)
    }

    // MARK: - Core Mailboxes
    private var coreMailboxesSection: some View {
        VStack(spacing: 2) {
            navLinkRow(
                title: "Inbox",
                systemIcon: "tray.fill",
                badgeCount: inboxCount,
                isActive: activeMailbox == .inbox && activeCollection == nil
            ) {
                close()
                onSelectMailbox(.inbox)
            }

            navLinkRow(
                title: "Starred",
                systemIcon: "star.fill",
                badgeCount: starredCount,
                isActive: activeMailbox == .starred && activeCollection == nil,
                iconColor: Color(hex: "F59E0B")
            ) {
                close()
                onSelectMailbox(.starred)
            }

            navLinkRow(
                title: "Kept",
                systemIcon: "checkmark.circle.fill",
                badgeCount: keptCount,
                isActive: activeMailbox == .kept && activeCollection == nil
            ) {
                close()
                onSelectMailbox(.kept)
            }

            navLinkRow(
                title: "Archived",
                systemIcon: "archivebox.fill",
                badgeCount: archivedCount,
                isActive: activeMailbox == .archived && activeCollection == nil
            ) {
                close()
                onSelectMailbox(.archived)
            }

            navLinkRow(
                title: "Recently Deleted",
                systemIcon: "trash.fill",
                badgeCount: trashCount,
                isActive: activeMailbox == .trash && activeCollection == nil
            ) {
                close()
                onSelectMailbox(.trash)
            }

            navLinkRow(
                title: "Today",
                systemIcon: "clock.fill",
                badgeCount: todayCount,
                isActive: false
            ) {
                close()
                onOpenReturns(.today)
            }

            navLinkRow(
                title: "Upcoming",
                systemIcon: "calendar",
                badgeCount: upcomingCount,
                isActive: false
            ) {
                close()
                onOpenReturns(.upcoming)
            }

            navLinkRow(
                title: "Someday",
                systemIcon: "calendar.badge.clock",
                badgeCount: somedayCount,
                isActive: false
            ) {
                close()
                onOpenReturns(.someday)
            }
        }
        .padding(.horizontal, 10)
    }

    // MARK: - Collections Section
    private var collectionsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("COLLECTIONS")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(Color(hex: "9E9B92"))
                    .tracking(1.0)

                Spacer()

                Button {
                    isCreatingCollection.toggle()
                    LBHaptic.light()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.secondary)
                        .padding(4)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)

            if isCreatingCollection {
                HStack(spacing: 8) {
                    TextField("New collection name...", text: $newCollectionName)
                        .font(.system(size: 13))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(Color.black.opacity(0.1), lineWidth: 1)
                        )

                    Button("Add") {
                        let trimmed = newCollectionName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            _ = coordinator.ensureCollectionExists(named: trimmed, context: modelContext)
                            newCollectionName = ""
                            isCreatingCollection = false
                            LBHaptic.medium()
                        }
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "171711"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color(hex: "E6EDB0"), in: RoundedRectangle(cornerRadius: 8))
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 4)
            }

            VStack(spacing: 2) {
                ForEach(collections) { col in
                    let count = collectionItemCount(named: col.name)
                    let isColActive = activeCollection == col.name
                    navLinkRow(
                        title: col.name,
                        systemIcon: "tag.fill",
                        badgeCount: count,
                        isActive: isColActive
                    ) {
                        close()
                        onSelectCollection(col.name)
                    }
                }

                if collections.isEmpty && !isCreatingCollection {
                    Button {
                        isCreatingCollection = true
                        LBHaptic.light()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .bold))
                            Text("New collection...")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(Color(hex: "9E9B92"))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 10)
    }

    // MARK: - Activity Section
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ACTIVITY")
                .font(.system(size: 10, weight: .black))
                .foregroundColor(Color(hex: "9E9B92"))
                .tracking(1.0)
                .padding(.horizontal, 16)
                .padding(.top, 4)

            VStack(spacing: 2) {
                navLinkRow(
                    title: "Library",
                    systemIcon: "books.vertical.fill",
                    badgeCount: 0,
                    isActive: false
                ) {
                    close()
                    onOpenLibrary()
                }

                navLinkRow(
                    title: "Returns Schedule",
                    systemIcon: "calendar",
                    badgeCount: 0,
                    isActive: false
                ) {
                    close()
                    onOpenReturns(.today)
                }

                navLinkRow(
                    title: "Plans",
                    systemIcon: "crown.fill",
                    badgeCount: 0,
                    isActive: false,
                    iconColor: Color(hex: "F59E0B")
                ) {
                    close()
                    onOpenPlans()
                }

                navLinkRow(
                    title: "Settings",
                    systemIcon: "gearshape.fill",
                    badgeCount: 0,
                    isActive: false
                ) {
                    close()
                    onOpenSettings()
                }
            }
        }
        .padding(.horizontal, 10)
    }

    // MARK: - Bottom Footer
    private var bottomFooterView: some View {
        VStack(spacing: 8) {
            Rectangle()
                .fill(Color.black.opacity(0.06))
                .frame(height: 1)

            // Free / Pro Plan Card
            Button {
                close()
                onOpenPlans()
                LBHaptic.light()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "F59E0B"))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(storeKit.hasActivePro ? "Pro Plan" : "Free Plan")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(hex: "171711"))

                        Text(storeKit.hasActivePro ? "Active subscription" : "Upgrade for more space")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color(hex: "8E8D87"))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "9E9B92"))
                }
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.02), radius: 4, y: 1)
            }
            .buttonStyle(.plain)

            // Cloud Sync / Status Pill
            HStack(spacing: 6) {
                Circle()
                    .fill(Color(hex: "10B981"))
                    .frame(width: 6, height: 6)

                Text(coordinator.currentUserEmail != nil ? "Synced with LaterBox Cloud" : "Local Vault Mode")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(hex: "6C6B63"))

                Spacer()

                Image(systemName: "icloud.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "8E8D87"))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 12)
        .background(AppTheme.canvasBackground)
    }

    // MARK: - Row Helper
    private func navLinkRow(
        title: String,
        systemIcon: String,
        badgeCount: Int,
        isActive: Bool,
        iconColor: Color? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            LBHaptic.light()
            action()
        }) {
            HStack(spacing: 10) {
                Image(systemName: systemIcon)
                    .font(.system(size: 15))
                    .foregroundColor(iconColor ?? (isActive ? Color(hex: "171711") : Color(hex: "8E8D87")))
                    .frame(width: 20)

                Text(title)
                    .font(.system(size: 13, weight: isActive ? .bold : .medium))
                    .foregroundColor(isActive ? Color(hex: "171711") : Color(hex: "6C6B63"))

                Spacer()

                if badgeCount > 0 {
                    Text("\(badgeCount)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: "171711"))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(
                            isActive ? Color(hex: "D8E09E") : Color(hex: "E6EDB0"),
                            in: Capsule()
                        )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                isActive ? Color(hex: "E6EDB0") : Color.clear,
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }

    private func close() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
            isPresented = false
        }
    }
}
