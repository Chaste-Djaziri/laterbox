//
//  MobileSidebarDrawer.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 11.10.26.
//

import SwiftUI
import SwiftData

public struct MobileSidebarDrawer: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var coordinator = SyncCoordinator.shared
    @Query(sort: \LBItem.createdAt, order: .reverse) private var allItems: [LBItem]
    @Query(sort: \LBCollection.name, order: .forward) private var collections: [LBCollection]

    @State private var showingReturns = false
    @State private var showingLibrary = false
    @State private var showingSettings = false

    public init() {}

    private var inboxCount: Int {
        allItems.filter { $0.status == ItemStatus.inbox.rawValue }.count
    }

    private var favoritesCount: Int {
        allItems.filter { $0.favorite && $0.status != ItemStatus.deleted.rawValue }.count
    }

    private var keptCount: Int {
        allItems.filter { $0.status == ItemStatus.saved.rawValue }.count
    }

    private var archivedCount: Int {
        allItems.filter { $0.status == ItemStatus.archived.rawValue }.count
    }

    private var deletedCount: Int {
        allItems.filter { $0.status == ItemStatus.deleted.rawValue }.count
    }

    public var body: some View {
        NavigationStack {
            List {
                // App Branding Header
                Section {
                    HStack(spacing: 12) {
                        Image("LaterboxIconGreen")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("LaterBox")
                                .font(.headline.weight(.bold))
                                .foregroundColor(AppTheme.textPrimary)
                            Text(coordinator.currentUserEmail ?? "Personal Vault")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                    .padding(.vertical, 6)
                }

                // Core Navigation
                Section("Mailboxes") {
                    HStack {
                        Label("Inbox", systemImage: "tray.fill")
                            .foregroundColor(AppTheme.textPrimary)
                        Spacer()
                        if inboxCount > 0 {
                            Text("\(inboxCount)")
                                .font(.caption.weight(.bold))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }

                    Button {
                        dismiss()
                        showingReturns = true
                    } label: {
                        HStack {
                            Label("Returns", systemImage: "calendar")
                                .foregroundColor(AppTheme.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundColor(Color.secondary)
                        }
                    }

                    Button {
                        dismiss()
                        showingLibrary = true
                    } label: {
                        HStack {
                            Label("Library", systemImage: "books.vertical.fill")
                                .foregroundColor(AppTheme.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundColor(Color.secondary)
                        }
                    }
                }

                // Quick Library Categories
                Section("Categories") {
                    HStack {
                        Label("Starred", systemImage: "star.fill")
                            .foregroundColor(AppTheme.amber)
                        Spacer()
                        Text("\(favoritesCount)")
                            .font(.caption)
                            .foregroundColor(Color.secondary)
                    }

                    HStack {
                        Label("Kept", systemImage: "bookmark.fill")
                            .foregroundColor(AppTheme.textPrimary)
                        Spacer()
                        Text("\(keptCount)")
                            .font(.caption)
                            .foregroundColor(Color.secondary)
                    }

                    HStack {
                        Label("Archived", systemImage: "archivebox.fill")
                            .foregroundColor(Color.secondary)
                        Spacer()
                        Text("\(archivedCount)")
                            .font(.caption)
                            .foregroundColor(Color.secondary)
                    }

                    HStack {
                        Label("Trash", systemImage: "trash.fill")
                            .foregroundColor(Color.secondary)
                        Spacer()
                        Text("\(deletedCount)")
                            .font(.caption)
                            .foregroundColor(Color.secondary)
                    }
                }

                // Collections
                if !collections.isEmpty {
                    Section("Collections") {
                        ForEach(collections) { col in
                            HStack {
                                Label(col.name, systemImage: "folder.fill")
                                    .foregroundColor(AppTheme.textPrimary)
                                Spacer()
                            }
                        }
                    }
                }

                // Settings & Sync
                Section("Settings & Account") {
                    Button {
                        dismiss()
                        showingSettings = true
                    } label: {
                        HStack {
                            Label("Settings", systemImage: "gearshape.fill")
                                .foregroundColor(AppTheme.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundColor(Color.secondary)
                        }
                    }

                    HStack {
                        Label("Sync Status", systemImage: coordinator.syncState.iconName)
                            .foregroundColor(coordinator.syncState.statusColor)
                        Spacer()
                        Text(coordinator.syncState.rawValue)
                            .font(.caption)
                            .foregroundColor(Color.secondary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showingReturns) {
                NavigationStack { ReturnsView() }
            }
            .sheet(isPresented: $showingLibrary) {
                NavigationStack { LibraryView() }
            }
            .sheet(isPresented: $showingSettings) {
                NavigationStack { SettingsView() }
            }
        }
    }
}
