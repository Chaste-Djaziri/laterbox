// laterbox-ios/laterbox-ios/Views/Returns/ReturnsView.swift
import SwiftUI
import SwiftData

public enum ReturnSegment: String, CaseIterable {
    case today = "Today"
    case upcoming = "Upcoming"
    case someday = "Someday"

    var symbol: String {
        switch self {
        case .today: "sun.max"
        case .upcoming: "calendar"
        case .someday: "moon.stars"
        }
    }

    var heading: String {
        switch self {
        case .today: "Due today"
        case .upcoming: "Coming up"
        case .someday: "Whenever you're ready"
        }
    }

    var description: String {
        switch self {
        case .today: "Items returning today and anything overdue."
        case .upcoming: "Everything scheduled for a future date."
        case .someday: "No deadline. Revisit these when the moment feels right."
        }
    }

    var emptyTitle: String {
        switch self {
        case .today: "All caught up"
        case .upcoming: "Nothing coming up"
        case .someday: "Your Someday list is empty"
        }
    }

    var emptyHint: String {
        switch self {
        case .today: "Nothing overdue or returning today. Enjoy the breathing room."
        case .upcoming: "Schedule items from your Inbox to revisit them on a future day."
        case .someday: "Save items without a date when you don't want to forget them."
        }
    }

    var emptySymbol: String {
        switch self {
        case .today: "checkmark.circle"
        case .upcoming: "calendar.badge.clock"
        case .someday: "moon.stars"
        }
    }
}

public struct ReturnsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \LBItem.returnAt, order: .forward) private var allItems: [LBItem]
    @ObservedObject private var coordinator = SyncCoordinator.shared

    @State private var selectedSegment: ReturnSegment = .today
    @State private var snoozeTargetItem: LBItem?
    private let isTabRoot: Bool

    private var primaryInk: Color { InboxAppearance.textPrimary(for: colorScheme) }
    private var secondaryInk: Color { InboxAppearance.textSecondary(for: colorScheme) }
    private var surface: Color { InboxAppearance.surface(for: colorScheme) }
    private var border: Color { InboxAppearance.border(for: colorScheme) }

    public init(initialSegment: ReturnSegment = .today, isTabRoot: Bool = false) {
        self._selectedSegment = State(initialValue: initialSegment)
        self.isTabRoot = isTabRoot
    }

    private var deduplicatedItems: [LBItem] {
        allItems.deduplicatedForDisplay()
    }

    private func items(for segment: ReturnSegment) -> [LBItem] {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        let startOfTomorrow = Calendar.current.date(byAdding: .day, value: 1, to: startOfToday)
            ?? startOfToday.addingTimeInterval(86_400)

        return deduplicatedItems.filter { item in
            guard item.status == ItemStatus.deferred.rawValue else { return false }
            switch segment {
            case .today:
                return item.returnAt.map { $0 < startOfTomorrow } ?? false
            case .upcoming:
                return item.returnAt.map { $0 >= startOfTomorrow } ?? false
            case .someday:
                return item.returnAt == nil
            }
        }
    }

    private var itemsForSegment: [LBItem] { items(for: selectedSegment) }

    public var body: some View {
        NavigationStack {
            ZStack {
                // One continuous surface under the header, switcher and list.
                InboxGrainBackground()
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    pageHeader
                    segmentSwitcher
                    segmentDescription

                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            if itemsForSegment.isEmpty {
                                emptyState
                            } else if selectedSegment == .today {
                                TodayFocusList(
                                    items: itemsForSegment,
                                    onKeep: { coordinator.markDone(item: $0, context: modelContext) },
                                    onReschedule: { snoozeTargetItem = $0 },
                                    onDismiss: { coordinator.dismissReturn(item: $0, context: modelContext) }
                                )
                            } else {
                                scheduleList(items: itemsForSegment)
                            }
                        }
                        .padding(.top, 6)
                        .padding(.bottom, 34)
                        .id(selectedSegment)
                    }
                    .refreshable {
                        LBHaptic.medium()
                        await coordinator.syncPendingItems(context: modelContext)
                    }
                    .scrollBounceBehavior(.always)
                }
            }
            // A hidden root bar must not hide the native Back button in details.
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $snoozeTargetItem) { targetItem in
                SnoozeDatePickerSheet(
                    itemTitle: targetItem.title,
                    initialDate: targetItem.returnAt,
                    onSchedule: { newDate in
                        coordinator.scheduleItem(item: targetItem, date: newDate, context: modelContext)
                    },
                    onUnsnooze: {
                        targetItem.status = ItemStatus.inbox.rawValue
                        targetItem.inboxEnteredAt = Date()
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

    private var pageHeader: some View {
        HStack(spacing: 12) {
            if !isTabRoot {
                Button {
                    dismiss()
                    LBHaptic.light()
                } label: {
                    Label("Inbox", systemImage: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(primaryInk)
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(isTabRoot ? "Returns" : "Returns Schedule")
                    .font(.system(size: 25, weight: .bold))
                    .foregroundStyle(primaryInk)
                Text("Make time for what you saved.")
                    .font(.system(size: 12))
                    .foregroundStyle(secondaryInk)
            }

            Spacer(minLength: 0)

            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(primaryInk)
                .frame(width: 42, height: 42)
                .background(surface, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .strokeBorder(border, lineWidth: 1)
                }
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 18)
    }

    /// Three equal-width, always-visible destinations: no horizontal scrolling.
    private var segmentSwitcher: some View {
        HStack(spacing: 5) {
            ForEach(ReturnSegment.allCases, id: \.self) { segment in
                let selected = selectedSegment == segment
                let count = items(for: segment).count

                Button {
                    guard selectedSegment != segment else { return }
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selectedSegment = segment
                    }
                    LBHaptic.light()
                } label: {
                    VStack(spacing: 7) {
                        Label(segment.rawValue, systemImage: segment.symbol)
                            .font(.system(size: 12, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Text("\(count)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .padding(.horizontal, 10)
                            .padding(.vertical, 3)
                            .background(
                                selected
                                    ? Color(hex: "171711").opacity(0.11)
                                    : (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.06)),
                                in: Capsule()
                            )
                    }
                    .foregroundStyle(
                        selected
                            ? Color(hex: "171711")
                            : primaryInk
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 67)
                    .background(
                        selected ? AppTheme.accent : Color.clear,
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(segment.rawValue), \(count) \(count == 1 ? "item" : "items")")
                .accessibilityValue(selected ? "Selected" : "Not selected")
                .accessibilityIdentifier("Returns Segment \(segment.rawValue)")
            }
        }
        .padding(5)
        .background(surface, in: RoundedRectangle(cornerRadius: 19, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 19, style: .continuous)
                .strokeBorder(border, lineWidth: 1)
        }
        .padding(.horizontal, 16)
    }

    private var segmentDescription: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(selectedSegment.heading)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(primaryInk)
                Text(selectedSegment.description)
                    .font(.system(size: 12))
                    .foregroundStyle(secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.top, 20)
        .padding(.bottom, 12)
        .accessibilityElement(children: .combine)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: selectedSegment.emptySymbol)
                .font(.system(size: 27, weight: .medium))
                .foregroundStyle(colorScheme == .dark ? AppTheme.accent : Color(hex: "718255"))
                .frame(width: 58, height: 58)
                .background(
                    colorScheme == .dark ? Color(hex: "333A2A") : Color(hex: "EDF2DD"),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
            Text(selectedSegment.emptyTitle)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(primaryInk)
            Text(selectedSegment.emptyHint)
                .font(.system(size: 13))
                .foregroundStyle(secondaryInk)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 42)
        .background(surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(border, lineWidth: 1)
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
    }

    private func scheduleList(items: [LBItem]) -> some View {
        LazyVStack(spacing: 3) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                let topRadius: CGFloat = index == 0 ? 13 : 4
                let bottomRadius: CGFloat = index == items.count - 1 ? 13 : 4

                NavigationLink(destination: ItemDetailView(item: item, usesNativeNavigation: true)) {
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

struct TodayFocusList: View {
    @Environment(\.colorScheme) private var colorScheme

    let items: [LBItem]
    let onKeep: (LBItem) -> Void
    let onReschedule: (LBItem) -> Void
    let onDismiss: (LBItem) -> Void

    private var primaryInk: Color { InboxAppearance.textPrimary(for: colorScheme) }
    private var secondaryInk: Color { InboxAppearance.textSecondary(for: colorScheme) }
    private var surface: Color { InboxAppearance.surface(for: colorScheme) }
    private var border: Color { InboxAppearance.border(for: colorScheme) }

    private var overdue: [LBItem] {
        let today = Calendar.current.startOfDay(for: Date())
        return items.filter { ($0.returnAt ?? .distantFuture) < today }
            .sorted { ($0.returnAt ?? .distantPast) < ($1.returnAt ?? .distantPast) }
    }

    private var dueToday: [LBItem] {
        items.filter { $0.returnAt.map { Calendar.current.isDateInToday($0) } ?? false }
            .sorted { ($0.returnAt ?? .distantPast) < ($1.returnAt ?? .distantPast) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            if !overdue.isEmpty {
                group("Overdue", symbol: "exclamationmark.circle", items: overdue, isOverdue: true)
            }
            if !dueToday.isEmpty {
                group("Returning today", symbol: "sun.max", items: dueToday)
            }

            Text("Dismiss sends an item to Archive, not Trash.")
                .font(.system(size: 11))
                .foregroundStyle(secondaryInk)
                .padding(.horizontal, 4)
        }
        .padding(.horizontal, 12)
    }

    private func group(_ title: String, symbol: String, items: [LBItem], isOverdue: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .foregroundStyle(
                        isOverdue
                            ? (colorScheme == .dark ? Color(hex: "F5B57A") : Color(hex: "AA6438"))
                            : primaryInk
                    )
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(primaryInk)
                Text("\(items.count)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(secondaryInk)
                Spacer()
            }
            .padding(.horizontal, 4)

            ForEach(items, id: \.id) { item in
                VStack(alignment: .leading, spacing: 13) {
                    NavigationLink(destination: ItemDetailView(item: item, usesNativeNavigation: true)) {
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.title.isEmpty ? "Untitled item" : item.title)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(primaryInk)
                                    .lineLimit(2)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                if let date = item.returnAt {
                                    Label(
                                        date.formatted(date: .abbreviated, time: .shortened),
                                        systemImage: "clock"
                                    )
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(secondaryInk)
                                }
                            }

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(secondaryInk)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: 8) {
                        action("Keep", icon: "checkmark", prominent: true) { onKeep(item) }
                        action("Reschedule", icon: "calendar") { onReschedule(item) }
                        action("Dismiss", icon: "archivebox") { onDismiss(item) }
                    }
                }
                .padding(14)
                .background(surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(border, lineWidth: 1)
                }
            }
        }
    }

    private func action(
        _ title: String,
        icon: String,
        prominent: Bool = false,
        perform: @escaping () -> Void
    ) -> some View {
        Button(action: perform) {
            Label(title, systemImage: icon)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .foregroundStyle(
                    prominent ? Color(hex: "171711") : primaryInk
                )
                .frame(maxWidth: .infinity)
                .frame(height: 35)
                .background(
                    prominent
                        ? AppTheme.accent
                        : (colorScheme == .dark ? Color(hex: "31353A") : Color(hex: "E8EAE5")),
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                )
        }
        .buttonStyle(.plain)
    }
}
