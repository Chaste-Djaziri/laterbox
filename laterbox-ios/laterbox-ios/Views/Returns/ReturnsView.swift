//
//  ReturnsView.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 04.10.26.
//

import SwiftUI
import SwiftData

public enum ReturnSegment: String, CaseIterable {
    case today = "Today"
    case upcoming = "Upcoming"
    case someday = "Someday"
}

public struct ReturnsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LBItem.returnAt, order: .forward) private var allItems: [LBItem]
    @ObservedObject var coordinator = SyncCoordinator.shared

    @State private var selectedSegment: ReturnSegment = .today
    @State private var snoozeTargetItem: LBItem? = nil

    public init(initialSegment: ReturnSegment = .today) {
        self._selectedSegment = State(initialValue: initialSegment)
    }

    private var deduplicatedItems: [LBItem] {
        allItems.deduplicatedForDisplay()
    }

    private var itemsForSegment: [LBItem] {
        let cal = Calendar.current
        let now = Date()
        let startOfToday = cal.startOfDay(for: now)
        let endOfToday = cal.date(byAdding: .day, value: 1, to: startOfToday) ?? now

        switch selectedSegment {
        case .today:
            return deduplicatedItems.filter {
                guard $0.status == ItemStatus.deferred.rawValue else { return false }
                guard let ret = $0.returnAt else { return false }
                return ret < endOfToday
            }
        case .upcoming:
            return deduplicatedItems.filter {
                guard $0.status == ItemStatus.deferred.rawValue else { return false }
                guard let ret = $0.returnAt else { return false }
                return ret > endOfToday
            }
        case .someday:
            return deduplicatedItems.filter {
                $0.status == ItemStatus.deferred.rawValue && $0.returnAt == nil
            }
        }
    }

    private func count(for segment: ReturnSegment) -> Int {
        let cal = Calendar.current
        let now = Date()
        let startOfToday = cal.startOfDay(for: now)
        let endOfToday = cal.date(byAdding: .day, value: 1, to: startOfToday) ?? now

        switch segment {
        case .today:
            return deduplicatedItems.filter {
                guard $0.status == ItemStatus.deferred.rawValue else { return false }
                guard let ret = $0.returnAt else { return false }
                return ret < endOfToday
            }.count
        case .upcoming:
            return deduplicatedItems.filter {
                guard $0.status == ItemStatus.deferred.rawValue else { return false }
                guard let ret = $0.returnAt else { return false }
                return ret > endOfToday
            }.count
        case .someday:
            return deduplicatedItems.filter {
                $0.status == ItemStatus.deferred.rawValue && $0.returnAt == nil
            }.count
        }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.canvasBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top Navigation Header
                    HStack {
                        Button {
                            dismiss()
                            LBHaptic.light()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .bold))
                                Text("Inbox")
                                    .font(.system(size: 15, weight: .medium))
                            }
                            .foregroundColor(AppTheme.textPrimary)
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Text("Returns Schedule")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)

                        Spacer()

                        // Balance back button width
                        Color.clear
                            .frame(width: 50, height: 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 10)

                    // Returns Filter Pills (Today, Upcoming, Someday)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(ReturnSegment.allCases, id: \.self) { seg in
                                let isSelected = selectedSegment == seg
                                let c = count(for: seg)
                                Button {
                                    selectedSegment = seg
                                    LBHaptic.light()
                                } label: {
                                    HStack(spacing: 6) {
                                        Text(seg.rawValue)
                                            .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                                        Text("\(c)")
                                            .font(.system(size: 11, weight: .bold))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(
                                                isSelected ? Color(hex: "D8E09E") : Color(hex: "E6EDB0"),
                                                in: Capsule()
                                            )
                                            .foregroundColor(Color(hex: "171711"))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(isSelected ? Color(hex: "171711") : Color.white, in: Capsule())
                                    .foregroundColor(isSelected ? Color(hex: "E6EDB0") : AppTheme.textPrimary)
                                    .overlay(
                                        Capsule().strokeBorder(isSelected ? Color.clear : Color.black.opacity(0.08), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)
                    }

                    // Content Area (Email Table View Cards)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("\(selectedSegment.rawValue) (\(itemsForSegment.count))")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(Color.secondary)
                                Spacer()
                            }
                            .padding(.horizontal, 18)
                            .padding(.top, 4)

                            if selectedSegment == .today {
                                TodayFocusList(
                                    items: itemsForSegment,
                                    onKeep: { coordinator.markDone(item: $0, context: modelContext) },
                                    onReschedule: { snoozeTargetItem = $0 },
                                    onDismiss: { coordinator.dismissReturn(item: $0, context: modelContext) }
                                )
                            } else if itemsForSegment.isEmpty {
                                VStack(spacing: 14) {
                                    Image(systemName: "calendar.badge.clock")
                                        .font(.system(size: 40))
                                        .foregroundColor(Color.secondary.opacity(0.35))
                                    Text("No items scheduled for \(selectedSegment.rawValue.lowercased())")
                                        .font(.headline)
                                        .foregroundColor(AppTheme.textPrimary)
                                        .lineLimit(1)
                                    Text("Schedule items from the inbox to reappear here when you're ready to review them.")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textSecondary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(44)
                                .background(Color.white)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                                )
                                .padding(.horizontal, 12)
                                .padding(.top, 10)
                            } else {
                                LazyVStack(spacing: 2.5) {
                                    ForEach(Array(itemsForSegment.enumerated()), id: \.element.id) { index, item in
                                        let isFirst = index == 0
                                        let isLast = index == itemsForSegment.count - 1
                                        let topRadius: CGFloat = isFirst ? 12 : 4
                                        let bottomRadius: CGFloat = isLast ? 12 : 4

                                        NavigationLink(destination: ItemDetailView(item: item)) {
                                            EmailInboxRowView(
                                                item: item,
                                                topRadius: topRadius,
                                                bottomRadius: bottomRadius,
                                                onToggleFavorite: { coordinator.toggleFavorite(item: item, context: modelContext) },
                                                onMarkDone: { coordinator.markDone(item: item, context: modelContext) },
                                                onSchedule: { date in coordinator.scheduleItem(item: item, date: date, context: modelContext) },
                                                onOpenSchedule: { snoozeTargetItem = item },
                                                onDelete: { coordinator.deleteItem(item: item, context: modelContext) }
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 12)
                            }
                        }
                        .padding(.bottom, 30)
                    }
                    .refreshable {
                        LBHaptic.medium()
                        await coordinator.syncPendingItems(context: modelContext)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $snoozeTargetItem) { targetItem in
                SnoozeDatePickerSheet(
                    itemTitle: targetItem.title,
                    initialDate: targetItem.returnAt,
                    onSchedule: { newDate in
                        coordinator.scheduleItem(item: targetItem, date: newDate, context: modelContext)
                    },
                    onUnsnooze: {
                        targetItem.status = ItemStatus.inbox.rawValue
                        targetItem.returnAt = nil
                        targetItem.updatedAt = Date()
                        targetItem.isSyncPending = true
                        try? modelContext.save()
                        Task { await coordinator.syncPendingItems(context: modelContext) }
                    }
                )
            }
            .onAppear {
                LBItem.cleanupDuplicatesInStore(context: modelContext)
            }
        }
    }
}
 
struct TodayFocusList: View {
    let items: [LBItem]
    let onKeep: (LBItem) -> Void
    let onReschedule: (LBItem) -> Void
    let onDismiss: (LBItem) -> Void

    private var overdue: [LBItem] {
        let start = Calendar.current.startOfDay(for: Date())
        return items.filter { ($0.returnAt ?? .distantFuture) < start }
            .sorted { ($0.returnAt ?? .distantPast) < ($1.returnAt ?? .distantPast) }
    }

    private var dueToday: [LBItem] {
        items.filter { $0.returnAt.map { Calendar.current.isDateInToday($0) } ?? false }
            .sorted { ($0.returnAt ?? .distantPast) < ($1.returnAt ?? .distantPast) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("A moment for what you saved.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
            if items.isEmpty {
                ContentUnavailableView("All caught up", systemImage: "checkmark.circle",
                                       description: Text("Nothing overdue or returning today."))
            }
            if !overdue.isEmpty { group("Overdue", items: overdue) }
            if !dueToday.isEmpty { group("Returning today", items: dueToday) }
        }
        .padding(.horizontal, 12)
    }

    private func group(_ title: String, items: [LBItem]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title + " (" + String(items.count) + ")")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
            ForEach(items, id: \.id) { item in
                VStack(alignment: .leading, spacing: 12) {
                    NavigationLink(destination: ItemDetailView(item: item)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title.isEmpty ? "Untitled item" : item.title)
                                .font(.subheadline.weight(.semibold))
                            if let date = item.returnAt {
                                Text(date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    HStack(spacing: 8) {
                        action("Keep", icon: "checkmark") { onKeep(item) }
                        action("Reschedule", icon: "calendar") { onReschedule(item) }
                        action("Dismiss", icon: "xmark") { onDismiss(item) }
                    }
                }
                .foregroundStyle(AppTheme.textPrimary)
                .padding(14)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private func action(_ title: String, icon: String, perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(AppTheme.canvasBackground, in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}
