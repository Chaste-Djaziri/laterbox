import SwiftUI

/// Dedicated sub-page for browsing, previewing, and selecting alternate LaterBox app icons.
public struct AppIconSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var iconManager = AppIconManager.shared
    @State private var selectedCategory: String = "All"

    public init() {}

    private var filteredIcons: [AppIconOption] {
        if selectedCategory == "All" {
            return AppIconManager.availableIcons
        }
        return AppIconManager.availableIcons.filter { $0.category == selectedCategory }
    }

    public var body: some View {
        ZStack {
            LiquidGlassBackground()

            VStack(spacing: 0) {
                // Navigation Header
                HStack(alignment: .center) {
                    Button(action: {
                        LBHaptic.light()
                        dismiss()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .bold))
                            Text("Settings")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundColor(AppTheme.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.04))
                        )
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text("App Icon")
                        .font(.headline.weight(.bold))
                        .foregroundColor(AppTheme.textPrimary)

                    Spacer()

                    // Balance layout with invisible counter-spacer
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                        Text("Settings")
                            .font(.subheadline.weight(.semibold))
                    }
                    .opacity(0)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 10)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Hero Spotlight Card
                        heroSpotlightCard

                        // Category Filter Carousel
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Icon Collections")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)

                                Spacer()

                                Text("\(filteredIcons.count) of \(AppIconManager.availableIcons.count)")
                                    .font(.caption2.weight(.medium))
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            .padding(.horizontal, 4)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(AppIconManager.categories, id: \.self) { cat in
                                        let isSelected = selectedCategory == cat
                                        Button(action: {
                                            LBHaptic.light()
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                                selectedCategory = cat
                                            }
                                        }) {
                                            Text(cat)
                                                .font(.caption.weight(isSelected ? .bold : .medium))
                                                .foregroundColor(isSelected ? AppTheme.textPrimary : AppTheme.textSecondary)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 7)
                                                .background(
                                                    Capsule()
                                                        .fill(isSelected ? AppTheme.accent : Color.black.opacity(0.04))
                                                )
                                                .overlay(
                                                    Capsule()
                                                        .strokeBorder(isSelected ? AppTheme.textPrimary.opacity(0.15) : Color.clear, lineWidth: 1)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 2)
                            }
                        }

                        // Icon Selection Cards
                        VStack(spacing: 12) {
                            ForEach(filteredIcons) { option in
                                iconRowCard(for: option)
                            }
                        }

                        // iOS System Note Footer
                        VStack(spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "info.circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(AppTheme.textSecondary)
                                Text("iOS displays a brief confirmation dialog when updating the home screen icon.")
                                    .font(.caption2)
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.black.opacity(0.03))
                            )
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 6)
                        .padding(.bottom, 30)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            iconManager.refreshCurrentIcon()
        }
    }

    // MARK: - Hero Spotlight Card
    private var heroSpotlightCard: some View {
        let current = iconManager.currentIconOption

        return VStack(spacing: 14) {
            // Simulated Home Screen Icon Shelf
            ZStack {
                // Radial ambient glow matching theme
                RadialGradient(
                    colors: [
                        current.accentColor.opacity(0.28),
                        current.accentColor.opacity(0.06),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 10,
                    endRadius: 95
                )
                .frame(width: 190, height: 190)

                VStack(spacing: 8) {
                    // App Icon Render
                    ZStack {
                        Image(current.previewImageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 78, height: 78)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.35), lineWidth: 1.5)
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                            .shadow(color: current.accentColor.opacity(0.35), radius: 16, x: 0, y: 4)

                        if iconManager.isChanging {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(1.2)
                        }
                    }

                    Text("Laterbox")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(AppTheme.textPrimary)
                }
            }
            .frame(height: 124)

            Divider().background(AppTheme.cardBorder)

            // Current Active Details
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(current.name)
                            .font(.headline.weight(.bold))
                            .foregroundColor(AppTheme.textPrimary)

                        Text(current.category)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppTheme.textSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.05))
                            )
                    }

                    Text(current.description)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.green)
                    Text("Active")
                        .font(.caption.weight(.bold))
                        .foregroundColor(AppTheme.textPrimary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(AppTheme.accent)
                )
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
    }

    // MARK: - Icon Row Card
    private func iconRowCard(for option: AppIconOption) -> some View {
        let isSelected = iconManager.currentIconId == option.id

        return Button(action: {
            LBHaptic.medium()
            Task {
                await iconManager.selectIcon(option)
            }
        }) {
            HStack(spacing: 14) {
                // Squircle Preview Image
                ZStack {
                    Image(option.previewImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

                    if isSelected {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(AppTheme.accent, lineWidth: 2.5)
                    }
                }

                // Text Description
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(option.name)
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(AppTheme.textPrimary)

                        Circle()
                            .fill(option.accentColor)
                            .frame(width: 7, height: 7)

                        Text(option.badgeText)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppTheme.textSecondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(
                                Capsule().fill(Color.black.opacity(0.05))
                            )
                    }

                    Text(option.subtitle)
                        .font(.caption2.weight(.medium))
                        .foregroundColor(AppTheme.textSecondary)

                    Text(option.description)
                        .font(.caption2)
                        .foregroundColor(AppTheme.textTertiary)
                        .lineLimit(1)
                }

                Spacer()

                // State Indicator
                if isSelected {
                    ZStack {
                        Circle()
                            .fill(AppTheme.accent)
                            .frame(width: 28, height: 28)

                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                    }
                } else {
                    Text("Apply")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.05))
                        )
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? AppTheme.accent.opacity(0.14) : AppTheme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(isSelected ? AppTheme.accent.opacity(0.85) : AppTheme.cardBorder, lineWidth: isSelected ? 1.5 : 1)
            )
            .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}
