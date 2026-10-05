//
//  StorageManagementView.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 05.10.26.
//

import SwiftUI
import SwiftData

public struct StorageManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allItems: [LBItem]
    @ObservedObject var coordinator = SyncCoordinator.shared
    @StateObject private var storageManager = LocalStorageManager.shared

    @State private var showingEmptyTrashConfirm = false
    @State private var showingClearKeptConfirm = false
    @State private var showingResolveDuplicatesConfirm = false
    @State private var showingClearCacheAlert = false
    @State private var successBannerMessage: String? = nil

    public init() {}

    private var trashItems: [LBItem] {
        allItems.filter { $0.status == ItemStatus.deleted.rawValue }
    }

    private var keptItems: [LBItem] {
        allItems.filter { $0.status == ItemStatus.saved.rawValue || $0.status == ItemStatus.archived.rawValue }
    }

    private var inboxItems: [LBItem] {
        allItems.filter { $0.status == ItemStatus.inbox.rawValue }
    }

    private var scheduledItems: [LBItem] {
        allItems.filter { $0.status == ItemStatus.deferred.rawValue }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Success Toast Banner
                        if let msg = successBannerMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppTheme.accent)
                                Text(msg)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(AppTheme.textPrimary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(AppTheme.darkSurface))
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .frame(maxWidth: .infinity, alignment: .center)
                        }

                        // Storage Usage Hero Card
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("STORAGE USAGE")
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(AppTheme.textSecondary)
                                        .tracking(0.6)
                                    Text(storageManager.breakdown.formattedTotal)
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                                Spacer()
                                Button(action: {
                                    LBHaptic.light()
                                    storageManager.refreshBreakdown()
                                    storageManager.scanDuplicates(items: allItems)
                                }) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 14, weight: .bold))
                                        .padding(8)
                                        .background(Circle().fill(AppTheme.background))
                                        .overlay(Circle().strokeBorder(AppTheme.cardBorder, lineWidth: 1))
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                                .buttonStyle(.plain)
                            }

                            // Storage Bar Breakdown
                            GeometryReader { geo in
                                HStack(spacing: 3) {
                                    Rectangle()
                                        .fill(AppTheme.accent)
                                        .frame(width: max(geo.size.width * CGFloat(storageManager.breakdown.databasePercentage), 8))

                                    Rectangle()
                                        .fill(Color(hex: "3B82F6"))
                                        .frame(width: max(geo.size.width * CGFloat(storageManager.breakdown.attachmentsPercentage), 8))

                                    Rectangle()
                                        .fill(Color(hex: "F59E0B"))
                                        .frame(width: max(geo.size.width * CGFloat(storageManager.breakdown.cachePercentage), 8))
                                }
                                .clipShape(Capsule())
                            }
                            .frame(height: 10)

                            // Legend Rows
                            VStack(spacing: 8) {
                                storageLegendRow(
                                    name: "Vault Database",
                                    detail: "\(allItems.count) saved records",
                                    size: storageManager.breakdown.formattedDatabase,
                                    color: AppTheme.accent
                                )
                                storageLegendRow(
                                    name: "Attachments & Files",
                                    detail: "Images, PDFs & docs",
                                    size: storageManager.breakdown.formattedAttachments,
                                    color: Color(hex: "3B82F6")
                                )
                                storageLegendRow(
                                    name: "Web & Media Cache",
                                    detail: "Temporary response cache",
                                    size: storageManager.breakdown.formattedCache,
                                    color: Color(hex: "F59E0B")
                                )
                            }
                        }
                        .padding(18)
                        .liquidGlassCard(cornerRadius: 20)

                        // Clean-up Actions Section
                        VStack(alignment: .leading, spacing: 14) {
                            Text("RECLAIM SPACE & CLEANUP")
                                .font(.caption.weight(.bold))
                                .foregroundColor(AppTheme.textSecondary)
                                .tracking(0.6)

                            // 1. Empty Trash / Recycle Bin
                            cleanupCard(
                                icon: "trash.fill",
                                iconColor: Color.red,
                                title: "Recycle Bin",
                                subtitle: "\(trashItems.count) deleted items waiting for permanent purge",
                                actionTitle: "Empty Trash",
                                isDestructive: true,
                                isEnabled: !trashItems.isEmpty
                            ) {
                                showingEmptyTrashConfirm = true
                            }

                            // 2. Duplicate Finder & Resolver
                            cleanupCard(
                                icon: "doc.on.doc.fill",
                                iconColor: Color(hex: "8B5CF6"),
                                title: "Duplicate Items",
                                subtitle: storageManager.totalDuplicateItemCount > 0
                                    ? "\(storageManager.totalDuplicateItemCount) duplicates found across \(storageManager.duplicateGroups.count) items"
                                    : "No duplicate captures or links detected",
                                actionTitle: storageManager.totalDuplicateItemCount > 0 ? "Remove \(storageManager.totalDuplicateItemCount) Duplicates" : "Clean",
                                isDestructive: false,
                                isEnabled: storageManager.totalDuplicateItemCount > 0
                            ) {
                                showingResolveDuplicatesConfirm = true
                            }

                            // 3. Clear Kept Content
                            cleanupCard(
                                icon: "archivebox.fill",
                                iconColor: AppTheme.textPrimary,
                                title: "Kept Content",
                                subtitle: "\(keptItems.count) kept & archived items in vault",
                                actionTitle: "Clear Kept",
                                isDestructive: false,
                                isEnabled: !keptItems.isEmpty
                            ) {
                                showingClearKeptConfirm = true
                            }

                            // 4. Clear Media Cache
                            cleanupCard(
                                icon: "sparkles",
                                iconColor: Color(hex: "10B981"),
                                title: "Temporary Media Cache",
                                subtitle: "Free up \(storageManager.breakdown.formattedCache) of cached web content",
                                actionTitle: "Purge Cache",
                                isDestructive: false,
                                isEnabled: storageManager.breakdown.cacheBytes > 0
                            ) {
                                storageManager.clearMediaAndWebCache()
                                triggerSuccessBanner("Media and web cache cleared!")
                            }
                        }

                        // Duplicate Items Inspection (if any)
                        if !storageManager.duplicateGroups.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("DUPLICATE ITEMS BREAKDOWN")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(AppTheme.textSecondary)
                                    .tracking(0.6)

                                ForEach(storageManager.duplicateGroups) { group in
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(alignment: .top) {
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(group.primaryItem.title)
                                                    .font(.subheadline.weight(.semibold))
                                                    .foregroundColor(AppTheme.textPrimary)
                                                    .lineLimit(2)
                                                if let url = group.primaryItem.url {
                                                    Text(url)
                                                        .font(.caption2)
                                                        .foregroundColor(AppTheme.textSecondary)
                                                        .lineLimit(1)
                                                }
                                            }
                                            Spacer()
                                            Text("\(group.totalCount)x")
                                                .font(.caption.weight(.bold))
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 3)
                                                .background(Capsule().fill(Color.orange.opacity(0.15)))
                                                .foregroundColor(Color.orange)
                                        }

                                        Text("Keeping latest saved copy; \(group.duplicates.count) redundant copy will be removed.")
                                            .font(.caption2)
                                            .foregroundColor(AppTheme.textSecondary)
                                    }
                                    .padding(14)
                                    .liquidGlassCard(cornerRadius: 14)
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Storage & Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.headline)
                        .foregroundColor(AppTheme.accent)
                }
            }
            .onAppear {
                storageManager.refreshBreakdown()
                storageManager.scanDuplicates(items: allItems)
            }
            // Confirmation: Empty Trash
            .confirmationDialog(
                "Permanently delete all \(trashItems.count) items in trash? This cannot be undone.",
                isPresented: $showingEmptyTrashConfirm,
                titleVisibility: .visible
            ) {
                Button("Empty Trash (\(trashItems.count) Items)", role: .destructive) {
                    let deletedCount = storageManager.emptyTrash(items: allItems, context: modelContext, coordinator: coordinator)
                    triggerSuccessBanner("Emptied \(deletedCount) items from trash.")
                }
                Button("Cancel", role: .cancel) {}
            }
            // Confirmation: Resolve Duplicates
            .confirmationDialog(
                "Remove \(storageManager.totalDuplicateItemCount) duplicate items? LaterBox will keep the newest copy of each item.",
                isPresented: $showingResolveDuplicatesConfirm,
                titleVisibility: .visible
            ) {
                Button("Remove Duplicates", role: .destructive) {
                    let pruned = storageManager.resolveDuplicates(context: modelContext, coordinator: coordinator)
                    triggerSuccessBanner("Removed \(pruned) duplicate entries.")
                }
                Button("Cancel", role: .cancel) {}
            }
            // Confirmation: Clear Kept Content
            .confirmationDialog(
                "Are you sure you want to move \(keptItems.count) kept items to trash?",
                isPresented: $showingClearKeptConfirm,
                titleVisibility: .visible
            ) {
                Button("Move Kept Items to Trash", role: .destructive) {
                    let count = storageManager.clearKeptItems(items: allItems, context: modelContext, coordinator: coordinator, moveToTrash: true)
                    triggerSuccessBanner("Moved \(count) kept items to trash.")
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func triggerSuccessBanner(_ text: String) {
        withAnimation {
            successBannerMessage = text
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                successBannerMessage = nil
            }
        }
    }

    private func storageLegendRow(name: String, detail: String, size: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(AppTheme.textPrimary)
                Text(detail)
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.textSecondary)
            }
            Spacer()
            Text(size)
                .font(.caption.weight(.bold).monospaced())
                .foregroundColor(AppTheme.textPrimary)
        }
        .padding(.vertical, 2)
    }

    private func cleanupCard(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        actionTitle: String,
        isDestructive: Bool,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppTheme.textPrimary)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            Button(action: {
                LBHaptic.medium()
                action()
            }) {
                Text(actionTitle)
                    .font(.caption.weight(.bold))
                    .foregroundColor(isEnabled ? (isDestructive ? Color.red : AppTheme.textPrimary) : AppTheme.textSecondary.opacity(0.4))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(
                        Capsule().fill(
                            isEnabled
                                ? (isDestructive ? Color.red.opacity(0.1) : AppTheme.accent)
                                : Color.black.opacity(0.04)
                        )
                    )
            }
            .buttonStyle(.plain)
            .disabled(!isEnabled)
        }
        .padding(14)
        .liquidGlassCard(cornerRadius: 16)
    }
}
