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

/// Search matches only items in the selected returns section, using the same
/// meaningful metadata visible in item details.
enum ReturnsItemSearch {
    static func matches(_ item: LBItem, query: String) -> Bool {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return true }
        let fields = [
            item.title,
            item.url ?? "",
            item.domain ?? "",
            item.siteName ?? "",
            item.metadataDescription ?? "",
            item.textContent ?? "",
            item.summary,
            item.collectionName ?? ""
        ] + item.tags
        return fields.contains { $0.localizedStandardContains(needle) }
    }
}

/// Uses scrolling direction, not a timer, to toggle the compact switcher.
/// The switcher overlays a stable ScrollView frame; hiding it never changes
/// scroll geometry or leaves a blank row between the header and the list.
struct ReturnsScrollSwitcherTracker {
    private(set) var isVisible = true
    private var lastOffset: CGFloat?
    private var directionalDistance: CGFloat = 0

    mutating func update(offset rawOffset: CGFloat) -> Bool {
        guard rawOffset.isFinite else { return isVisible }
        let offset = max(0, rawOffset)

        if offset < 16 {
            lastOffset = offset
            directionalDistance = 0
            isVisible = true
            return isVisible
        }

        guard let previous = lastOffset else {
            lastOffset = offset
            return isVisible
        }

        let delta = offset - previous
        lastOffset = offset

        // Discard layout jumps rather than interpreting them as user gestures.
        guard abs(delta) < 160 else {
            directionalDistance = 0
            return isVisible
        }

        if delta > 1 {
            directionalDistance = max(0, directionalDistance) + delta
            if offset > 55 && directionalDistance >= 24 {
                isVisible = false
                directionalDistance = 0
            }
        } else if delta < -1 {
            directionalDistance = min(0, directionalDistance) + delta
            if directionalDistance <= -14 {
                isVisible = true
                directionalDistance = 0
            }
        }
        return isVisible
    }

    mutating func reset() {
        lastOffset = nil
        directionalDistance = 0
        isVisible = true
    }
}

private struct ReturnsScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
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
    @State private var isSearching = false
    @State private var searchText = ""
    @State private var isSwitcherVisible = true
    @State private var scrollSwitcherTracker = ReturnsScrollSwitcherTracker()
    @FocusState private var searchFocused: Bool
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

    private var itemsForSegment: [LBItem] {
        items(for: selectedSegment).filter {
            ReturnsItemSearch.matches($0, query: searchText)
        }
    }

    private var hasSearchQuery: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func closeSearch() {
        searchFocused = false
        withAnimation(.easeInOut(duration: 0.2)) {
            searchText = ""
            isSearching = false
        }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                // One continuous surface under the header, switcher and list.
                InboxGrainBackground()
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    pageHeader

                    ScrollView {
                        VStack(spacing: 0) {
                            // Fixed reference point for the whole list, so
                            // hiding the floating chips cannot change offsets.
                            GeometryReader { geometry in
                                Color.clear.preference(
                                    key: ReturnsScrollOffsetKey.self,
                                    value: -geometry.frame(in: .named("returnsVerticalScroll")).minY
                                )
                            }
                            .frame(height: 0)

                            VStack(alignment: .leading, spacing: 12) {
                                if itemsForSegment.isEmpty {
                                    if hasSearchQuery {
                                        searchEmptyState
                                    } else {
                                        emptyState
                                    }
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
                            .padding(.top, 54)
                            .padding(.bottom, 34)
                            .id(selectedSegment)
                        }
                    }
                    .coordinateSpace(name: "returnsVerticalScroll")
                    .onPreferenceChange(ReturnsScrollOffsetKey.self) { offset in
                        let shouldShow = scrollSwitcherTracker.update(offset: offset)
                        guard shouldShow != isSwitcherVisible else { return }
                        withAnimation(.easeOut(duration: 0.18)) {
                            isSwitcherVisible = shouldShow
                        }
                    }
                    .onChange(of: selectedSegment) { _, _ in
                        scrollSwitcherTracker.reset()
                        isSwitcherVisible = true
                    }
                    .refreshable {
                        LBHaptic.medium()
                        await coordinator.syncPendingItems(context: modelContext)
                    }
                    .scrollBounceBehavior(.always)
                    .overlay(alignment: .top) {
                        segmentSwitcher
                            .padding(.top, 2)
                            .offset(y: isSwitcherVisible ? 0 : -56)
                            .opacity(isSwitcherVisible ? 1 : 0)
                            .allowsHitTesting(isSwitcherVisible)
                            .accessibilityHidden(!isSwitcherVisible)
                    }
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
            if isSearching {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(secondaryInk)

                    TextField("Search returns...", text: $searchText)
                        .font(.system(size: 15))
                        .foregroundStyle(primaryInk)
                        .tint(colorScheme == .dark ? AppTheme.accent : Color(hex: "171711"))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .focused($searchFocused)
                        .onAppear { searchFocused = true }
                        .accessibilityIdentifier("Returns Search Field")

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(secondaryInk)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Clear returns search")
                    }
                }
                .padding(.horizontal, 13)
                .frame(maxWidth: .infinity)
                .frame(height: 43)
                .background(surface, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .strokeBorder(border, lineWidth: 1)
                }

                Button("Cancel") {
                    closeSearch()
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(primaryInk)
                .buttonStyle(.plain)
                .accessibilityIdentifier("Returns Search Cancel")
            } else {
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

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isSearching = true
                    }
                    LBHaptic.light()
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(primaryInk)
                        .frame(width: 42, height: 42)
                        .background(surface, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .strokeBorder(border, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Search returns")
                .accessibilityIdentifier("Returns Search Button")
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 13)
    }

    /// Compact horizontally scrollable chips keep the destination switcher
    /// visible without consuming an entire row of tall cards.
    private var segmentSwitcher: some View {
        ScrollViewReader { reader in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
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
                            HStack(spacing: 7) {
                                Image(systemName: segment.symbol)
                                    .font(.system(size: 12, weight: .semibold))
                                Text(segment.rawValue)
                                    .font(.system(size: 12, weight: .semibold))
                                    .lineLimit(1)
                                Text("\(count)")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .monospacedDigit()
                                    .padding(.horizontal, 6)
                                    .frame(minHeight: 19)
                                    .background(
                                        selected
                                            ? Color(hex: "171711").opacity(0.12)
                                            : (colorScheme == .dark
                                                ? Color.white.opacity(0.09)
                                                : Color.black.opacity(0.05)),
                                        in: Capsule()
                                    )
                            }
                            .foregroundStyle(selected ? Color(hex: "171711") : primaryInk)
                            .padding(.horizontal, 12)
                            .frame(height: 38)
                            .background(
                                selected ? AppTheme.accent : surface,
                                in: Capsule()
                            )
                            .overlay {
                                Capsule()
                                    .strokeBorder(selected ? Color.clear : border, lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                        .id(segment)
                        .accessibilityLabel("\(segment.rawValue), \(count) \(count == 1 ? "item" : "items")")
                        .accessibilityValue(selected ? "Selected" : "Not selected")
                        .accessibilityIdentifier("Returns Segment \(segment.rawValue)")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 3)
            }
            .onChange(of: selectedSegment) { _, next in
                withAnimation(.easeInOut(duration: 0.18)) {
                    reader.scrollTo(next, anchor: .center)
                }
            }
        }
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

    private var searchEmptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 25, weight: .medium))
                .foregroundStyle(secondaryInk)
                .frame(width: 56, height: 56)
                .background(
                    colorScheme == .dark ? Color(hex: "303438") : Color(hex: "EAEDE8"),
                    in: RoundedRectangle(cornerRadius: 17, style: .continuous)
                )

            Text("No matches in \(selectedSegment.rawValue)")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(primaryInk)

            Text("Try a different search or switch to another section.")
                .font(.system(size: 13))
                .foregroundStyle(secondaryInk)
                .multilineTextAlignment(.center)
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
