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

    public init(initialSegment: ReturnSegment = .today) {
        self._selectedSegment = State(initialValue: initialSegment)
    }

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

                            if itemsForSegment.isEmpty {
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
        }
    }
}
