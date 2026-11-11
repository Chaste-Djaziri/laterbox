// laterbox-ios/laterbox-ios/Views/Components/MaintenanceFloatingBannerView.swift
import SwiftUI

/// Floating notification banner that appears above the iOS bottom navigation bar
/// when maintenance mode is activated by the admin. Communicates that web access is
/// unavailable, cloud sync may experience delays, and displays a live action timer.
public struct MaintenanceFloatingBannerView: View {
    @ObservedObject private var manager = PlatformMaintenanceManager.shared
    @Environment(\.colorScheme) private var colorScheme

    private var surfaceColor: Color {
        colorScheme == .dark ? Color(hex: "2D2416") : Color(hex: "FFF9EE")
    }

    private var strokeColor: Color {
        colorScheme == .dark ? Color(hex: "6A5123") : Color(hex: "E6C785")
    }

    private var textColor: Color {
        colorScheme == .dark ? Color(hex: "F7E7CD") : Color(hex: "34250C")
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color(hex: "D1B68A") : Color(hex: "6B5327")
    }

    private var accentAmber: Color {
        Color(hex: "D97706")
    }

    public init() {}

    public var body: some View {
        Group {
            if manager.isCollapsed {
                collapsedView
            } else {
                expandedView
            }
        }
        .background(surfaceColor, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(strokeColor, lineWidth: 1.2))
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.12), radius: 12, x: 0, y: 5)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: manager.isCollapsed)
    }

    // MARK: - Expanded View
    private var expandedView: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: Status title + Live Action Counter + Collapse button
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(accentAmber.opacity(0.18))
                        .frame(width: 28, height: 28)
                    Image(systemName: manager.isMaintenanceUpcoming ? "clock.badge.exclamationmark.fill" : "wrench.and.screwdriver.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(accentAmber)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(manager.isMaintenanceUpcoming ? "Scheduled Maintenance" : "Site Maintenance in Progress")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(textColor)
                    Text("Admin maintenance active")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(secondaryTextColor)
                }

                Spacer()

                // Action Time Counter Pill
                if !manager.timeRemainingString.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.system(size: 10, weight: .bold))
                        Text(manager.timeRemainingString)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                    }
                    .foregroundStyle(accentAmber)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(accentAmber.opacity(0.12), in: Capsule())
                }

                // Collapse Button
                Button {
                    LBHaptic.light()
                    withAnimation {
                        manager.isCollapsed = true
                    }
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(secondaryTextColor)
                        .frame(width: 24, height: 24)
                        .background(strokeColor.opacity(0.2), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Collapse maintenance banner")
            }

            // Descriptive notification body as requested
            VStack(alignment: .leading, spacing: 5) {
                Text("Web access is temporarily unavailable and cloud syncing may experience delays during this time.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(textColor)
                    .lineSpacing(2)

                HStack(spacing: 4) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "48613D"))
                    Text("Your saved items remain safely stored on this device.")
                        .font(.system(size: 11))
                        .foregroundStyle(secondaryTextColor)
                }
            }
        }
        .padding(14)
    }

    // MARK: - Collapsed View
    private var collapsedView: some View {
        Button {
            LBHaptic.light()
            withAnimation {
                manager.isCollapsed = false
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(accentAmber)

                Text(manager.isMaintenanceUpcoming ? "Maintenance scheduled" : "Site in maintenance")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(textColor)

                Spacer()

                if !manager.timeRemainingString.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.system(size: 10, weight: .bold))
                        Text(manager.timeRemainingString)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                    }
                    .foregroundStyle(accentAmber)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(accentAmber.opacity(0.12), in: Capsule())
                }

                Image(systemName: "chevron.up")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(secondaryTextColor)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Expand maintenance banner")
    }
}
