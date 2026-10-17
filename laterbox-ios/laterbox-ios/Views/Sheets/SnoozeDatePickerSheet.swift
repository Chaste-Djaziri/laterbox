//
//  SnoozeDatePickerSheet.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 17.10.26.
//

import SwiftUI

public enum SnoozePreset: String, CaseIterable, Identifiable {
    case oneHour = "In 1 Hour"
    case oneDay = "After 1 Day"
    case oneWeek = "In a Week"
    case oneMonth = "In a Month"
    case someday = "Someday"

    public var id: String { rawValue }

    public var systemIcon: String {
        switch self {
        case .oneHour: return "clock"
        case .oneDay: return "sun.max"
        case .oneWeek: return "calendar.badge.clock"
        case .oneMonth: return "calendar"
        case .someday: return "archivebox"
        }
    }

    public func calculateDate(from now: Date = Date()) -> Date? {
        let cal = Calendar.current
        switch self {
        case .oneHour:
            return cal.date(byAdding: .hour, value: 1, to: now) ?? now.addingTimeInterval(3600)
        case .oneDay:
            // Tomorrow morning at 9:00 AM if after 9:00 AM, else +24 hours
            if let tomorrow = cal.date(byAdding: .day, value: 1, to: now),
               let morning = cal.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) {
                return morning
            }
            return cal.date(byAdding: .day, value: 1, to: now) ?? now.addingTimeInterval(86400)
        case .oneWeek:
            // In 7 days at 9:00 AM
            if let nextWeek = cal.date(byAdding: .day, value: 7, to: now),
               let morning = cal.date(bySettingHour: 9, minute: 0, second: 0, of: nextWeek) {
                return morning
            }
            return cal.date(byAdding: .day, value: 7, to: now) ?? now.addingTimeInterval(7 * 86400)
        case .oneMonth:
            // In 1 month at 9:00 AM
            if let nextMonth = cal.date(byAdding: .month, value: 1, to: now),
               let morning = cal.date(bySettingHour: 9, minute: 0, second: 0, of: nextMonth) {
                return morning
            }
            return cal.date(byAdding: .month, value: 1, to: now) ?? now.addingTimeInterval(30 * 86400)
        case .someday:
            return nil
        }
    }
}

public struct SnoozeDatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    public var itemTitle: String?
    public var initialDate: Date?
    public var onSchedule: (Date) -> Void
    public var onUnsnooze: (() -> Void)?

    @State private var selectedDate: Date
    @State private var isSomedaySelected: Bool = false
    @State private var activePreset: SnoozePreset? = nil

    public init(
        itemTitle: String? = nil,
        initialDate: Date? = nil,
        onSchedule: @escaping (Date) -> Void,
        onUnsnooze: (() -> Void)? = nil
    ) {
        self.itemTitle = itemTitle
        self.initialDate = initialDate
        self.onSchedule = onSchedule
        self.onUnsnooze = onUnsnooze

        let defaultDate = initialDate ?? SnoozePreset.oneDay.calculateDate() ?? Date().addingTimeInterval(86400)
        _selectedDate = State(initialValue: defaultDate)
    }

    private var formattedDateSummary: String {
        if isSomedaySelected {
            return "Postponed to Someday Vault (No deadline)"
        }
        let cal = Calendar.current
        let formatter = DateFormatter()
        if cal.isDateInToday(selectedDate) {
            formatter.dateFormat = "'Today at' h:mm a"
        } else if cal.isDateInTomorrow(selectedDate) {
            formatter.dateFormat = "'Tomorrow at' h:mm a"
        } else {
            formatter.dateFormat = "EEEE, MMM d 'at' h:mm a"
        }
        return "Returns \(formatter.string(from: selectedDate))"
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.canvasBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // 1. Current Selected Return Badge
                        HStack(spacing: 8) {
                            Image(systemName: isSomedaySelected ? "archivebox.fill" : "clock.fill")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Color(hex: "171711"))

                            Text(formattedDateSummary)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(hex: "171711"))
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)

                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color(hex: "E6EDB0"), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
                        )

                        // 2. Pre-Available Quick Presets Section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("QUICK PRESETS")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.textSecondary)
                                .padding(.horizontal, 2)

                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                                ForEach(SnoozePreset.allCases) { preset in
                                    let isSelected = (activePreset == preset) || (!isSomedaySelected && preset != .someday && isSameTarget(preset: preset)) || (preset == .someday && isSomedaySelected)
                                    Button {
                                        applyPreset(preset)
                                        LBHaptic.light()
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: preset.systemIcon)
                                                .font(.system(size: 13, weight: .semibold))
                                            Text(preset.rawValue)
                                                .font(.system(size: 13, weight: .semibold))
                                            Spacer()
                                        }
                                        .foregroundColor(isSelected ? Color(hex: "171711") : AppTheme.textPrimary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 11)
                                        .background(isSelected ? Color(hex: "E6EDB0") : Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .strokeBorder(isSelected ? Color.black.opacity(0.12) : Color.black.opacity(0.07), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // 3. Exact Date & Time Picker Section
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("EXACT DATE & TIME")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(AppTheme.textSecondary)

                                Spacer()

                                if isSomedaySelected {
                                    Text("Paused")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(Color.secondary)
                                }
                            }
                            .padding(.horizontal, 2)

                            VStack(spacing: 12) {
                                DatePicker(
                                    "Choose Date and Time",
                                    selection: $selectedDate,
                                    in: Date()...,
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                                .datePickerStyle(.graphical)
                                .tint(Color(hex: "171711"))
                                .disabled(isSomedaySelected)
                                .opacity(isSomedaySelected ? 0.45 : 1.0)
                                .onChange(of: selectedDate) { _, _ in
                                    if isSomedaySelected { isSomedaySelected = false }
                                    activePreset = nil
                                }
                            }
                            .padding(14)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(Color.black.opacity(0.07), lineWidth: 1)
                            )
                        }

                        // 4. Unsnooze / Return to Inbox Option (if item was already scheduled)
                        if initialDate != nil, let onUnsnooze {
                            Button(role: .destructive) {
                                onUnsnooze()
                                dismiss()
                                LBHaptic.medium()
                            } label: {
                                HStack {
                                    Image(systemName: "tray.and.arrow.down")
                                    Text("Remove Return Schedule (Move to Inbox)")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(Color.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle(itemTitle != nil ? "Snooze ‘\(itemTitle!)’" : "Snooze Return")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        if !isSomedaySelected {
                            onSchedule(selectedDate)
                        } else if let onUnsnooze {
                            onUnsnooze()
                        }
                        LBHaptic.medium()
                        dismiss()
                    } label: {
                        Text("Snooze")
                            .font(.system(size: 14, weight: .bold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Color(hex: "E6EDB0"), in: Capsule())
                            .foregroundColor(Color(hex: "171711"))
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func applyPreset(_ preset: SnoozePreset) {
        activePreset = preset
        if preset == .someday {
            isSomedaySelected = true
        } else if let calculated = preset.calculateDate() {
            isSomedaySelected = false
            selectedDate = calculated
        }
    }

    private func isSameTarget(preset: SnoozePreset) -> Bool {
        guard let calculated = preset.calculateDate() else { return false }
        return abs(calculated.timeIntervalSince(selectedDate)) < 120
    }
}
