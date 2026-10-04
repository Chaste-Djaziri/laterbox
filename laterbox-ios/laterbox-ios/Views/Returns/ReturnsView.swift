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
    case inbox = "Inbox"
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
                guard let ret = $0.returnAt else { return false }
                return ret <= endOfToday
            }
        case .upcoming:
            return allItems.filter {
                guard let ret = $0.returnAt else { return false }
                return ret > endOfToday
            }
        case .someday:
            return allItems.filter {
                $0.status == ItemStatus.deferred.rawValue && $0.returnAt == nil
            }
        case .inbox:
            return allItems.filter { $0.status == ItemStatus.inbox.rawValue }
        }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // Returns Hub Spaced Segment Switcher
                        HStack(spacing: 8) {
                            ForEach(ReturnSegment.allCases, id: \.self) { seg in
                                Button(action: {
                                    LBHaptic.light()
                                    selectedSegment = seg
                                }) {
                                    Text(seg.rawValue)
                                        .font(.subheadline.weight(.semibold))
                                        .frame(maxWidth: .infinity)
                                        .liquidGlassPill(isSelected: selectedSegment == seg)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // Section Info
                        HStack {
                            Text("\(selectedSegment.rawValue) Schedule • \(itemsForSegment.count) Items")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                            Spacer()
                        }
                        .padding(.top, 4)

                        // Empty State or List
                        if itemsForSegment.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary.opacity(0.4))
                                Text("No items scheduled for \(selectedSegment.rawValue.lowercased())")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Schedule items to reappear when you have time to read or watch.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(48)
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
                    .padding(20)
                    .padding(.bottom, 80)
                }
            }
            .navigationTitle("Returns")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
