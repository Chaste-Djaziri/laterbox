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
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LBItem.returnAt, order: .forward) private var allItems: [LBItem]
    @ObservedObject var coordinator = SyncCoordinator.shared

    @State private var selectedSegment: ReturnSegment = .today

    public init() {}

    private var itemsForSegment: [LBItem] {
        let cal = Calendar.current
        let now = Date()
        let startOfToday = cal.startOfDay(for: now)
        let endOfToday = cal.date(byAdding: .day, value: 1, to: startOfToday) ?? now

        switch selectedSegment {
        case .today:
            return allItems.filter {
                guard $0.status != ItemStatus.deleted.rawValue && $0.status != ItemStatus.archived.rawValue else { return false }
                guard let ret = $0.returnAt else { return false }
                return ret <= endOfToday
            }
        case .upcoming:
            return allItems.filter {
                guard $0.status != ItemStatus.deleted.rawValue && $0.status != ItemStatus.archived.rawValue else { return false }
                guard let ret = $0.returnAt else { return false }
                return ret > endOfToday
            }
        case .someday:
            return allItems.filter {
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
            return allItems.filter {
                guard $0.status != ItemStatus.deleted.rawValue && $0.status != ItemStatus.archived.rawValue else { return false }
                guard let ret = $0.returnAt else { return false }
                return ret <= endOfToday
            }.count
        case .upcoming:
            return allItems.filter {
                guard $0.status != ItemStatus.deleted.rawValue && $0.status != ItemStatus.archived.rawValue else { return false }
                guard let ret = $0.returnAt else { return false }
                return ret > endOfToday
            }.count
        case .someday:
            return allItems.filter {
                $0.status == ItemStatus.deferred.rawValue && $0.returnAt == nil
            }.count
        }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // Top Level Header (Scrolls normally, uncontainerized on canvas)
                        HStack(alignment: .center) {
                            HStack(spacing: 8) {
                                Image("LaterboxIconGreen")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 28, height: 28)
                                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

                                Text("Returns")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(AppTheme.textPrimary)
                            }

                            Spacer()

                            // Sync Status Indicator (No Container)
                            Button(action: {
                                if !coordinator.isProUser {
                                    LBHaptic.light()
                                    coordinator.showingPlansSheet = true
                                }
                            }) {
                                HStack(spacing: 5) {
                                    Circle()
                                        .fill(coordinator.syncHeaderColor)
                                        .frame(width: 7, height: 7)
                                    Text(coordinator.syncHeaderTitle)
                                        .font(.caption2.weight(.medium))
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 4)

                        // Returns Filter Badges (Today, Upcoming, Someday) with no wrapping
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(ReturnSegment.allCases, id: \.self) { seg in
                                    Button(action: {
                                        LBHaptic.light()
                                        selectedSegment = seg
                                    }) {
                                        HStack(spacing: 6) {
                                            Text(seg.rawValue)
                                                .font(.subheadline.weight(.semibold))

                                            let c = count(for: seg)
                                            Text("\(c)")
                                                .font(.caption2.weight(.bold))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(
                                                    Capsule()
                                                        .fill(selectedSegment == seg ? Color.black.opacity(0.12) : AppTheme.accent)
                                                )
                                                .foregroundColor(AppTheme.textPrimary)
                                        }
                                        .lineLimit(1)
                                        .fixedSize()
                                        .liquidGlassPill(isSelected: selectedSegment == seg)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 1)
                        }

                        // Section Info
                        HStack {
                            Text("\(selectedSegment.rawValue) Schedule • \(itemsForSegment.count) Items")
                                .font(.caption.weight(.bold))
                                .foregroundColor(AppTheme.textSecondary)
                                .textCase(.uppercase)
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(.top, 4)

                        // Empty State or List
                        if itemsForSegment.isEmpty {
                            VStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(AppTheme.darkSurface)
                                        .frame(width: 52, height: 52)
                                    Image(systemName: "calendar.badge.clock")
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundColor(AppTheme.accent)
                                }
                                Text("No items scheduled for \(selectedSegment.rawValue.lowercased())")
                                    .font(.headline)
                                    .foregroundColor(AppTheme.textPrimary)
                                    .lineLimit(1)
                                Text("Schedule items to reappear when you have time to read or watch.")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(42)
                            .liquidGlassCard(cornerRadius: 20)
                        } else {
                            ForEach(itemsForSegment) { item in
                                NavigationLink(destination: ItemDetailView(item: item)) {
                                    ItemCardView(
                                        item: item,
                                        onMarkDone: { coordinator.markDone(item: item, context: modelContext) },
                                        onToggleFavorite: { coordinator.toggleFavorite(item: item, context: modelContext) },
                                        onSchedule: {
                                            coordinator.scheduleItem(item: item, date: Calendar.current.date(byAdding: .day, value: 1, to: Date())!, context: modelContext)
                                        },
                                        onDelete: { coordinator.deleteItem(item: item, context: modelContext) }
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                }
                .trackPullDownForLaterAI()
            }
            .navigationBarHidden(true)
        }
    }
}
