import SwiftUI

public struct AppIconSelectionView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var coordinator = SyncCoordinator.shared
    @StateObject private var iconManager = AppIconManager.shared
    @State private var selectedCategory = "All"

    public init() {}

    private var filteredIcons: [AppIconOption] {
        AppIconManager.availableIcons.filter { selectedCategory == "All" || $0.category == selectedCategory }
    }

    public var body: some View {
        ZStack {
            InboxGrainBackground().ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Make LaterBox yours")
                            .font(.headline)
                            .foregroundStyle(SettingsAppearance.textPrimary(for: colorScheme))
                        Text("Choose the icon for your home screen.")
                            .font(.subheadline)
                            .foregroundStyle(SettingsAppearance.textSecondary(for: colorScheme))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .settingsCard(for: colorScheme, cornerRadius: 20)

                    if !coordinator.isProUser {
                        Button {
                            coordinator.showingPlansSheet = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "lock")
                                Text("Unlock alternate icons with Pro")
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                                Image(systemName: "chevron.right").font(.caption)
                            }
                            .foregroundStyle(SettingsAppearance.onAccent)
                            .padding(14)
                            .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(AppIconManager.categories, id: \.self) { category in
                                Button {
                                    selectedCategory = category
                                    LBHaptic.light()
                                } label: {
                                    Text(category)
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(selectedCategory == category ? SettingsAppearance.onAccent : SettingsAppearance.textPrimary(for: colorScheme))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(selectedCategory == category ? AppTheme.accent : SettingsAppearance.surface(for: colorScheme), in: Capsule())
                                }
                                .accessibilityAddTraits(selectedCategory == category ? .isSelected : [])
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                        ForEach(filteredIcons) { option in
                            iconButton(option)
                        }
                    }

                    Text("iOS confirms when you change your app icon.")
                        .font(.caption)
                        .foregroundStyle(SettingsAppearance.textSecondary(for: colorScheme))
                        .frame(maxWidth: .infinity)
                }
                .padding(20)
            }
        }
        .navigationTitle("App Icon")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { iconManager.refreshCurrentIcon() }
        .alert("Couldn’t Change Icon", isPresented: Binding(
            get: { iconManager.errorMessage != nil },
            set: { if !$0 { iconManager.errorMessage = nil } }
        )) {
            Button("OK") { iconManager.errorMessage = nil }
        } message: {
            Text(iconManager.errorMessage ?? "Please try again.")
        }
    }

    private func iconButton(_ option: AppIconOption) -> some View {
        let selected = iconManager.currentIconId == option.id
        let locked = option.isProOnly && !coordinator.isProUser
        return Button {
            if locked {
                coordinator.showingPlansSheet = true
            } else {
                Task { await iconManager.selectIcon(option) }
            }
        } label: {
            VStack(spacing: 10) {
                Image(option.previewImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                Text(option.name)
                    .font(.caption.weight(.medium))
                    .multilineTextAlignment(.center)
                    .frame(minHeight: 32)
                Group {
                    if selected {
                        Label("Selected", systemImage: "checkmark")
                    } else if locked {
                        Label("Pro", systemImage: "lock")
                    } else {
                        Text("Apply")
                    }
                }
                .font(.caption2)
                .foregroundStyle(SettingsAppearance.textSecondary(for: colorScheme))
            }
            .foregroundStyle(SettingsAppearance.textPrimary(for: colorScheme))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(SettingsAppearance.surface(for: colorScheme), in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(selected ? SettingsAppearance.textPrimary(for: colorScheme) : SettingsAppearance.border(for: colorScheme), lineWidth: selected ? 1.5 : 1))
        }
        .buttonStyle(.plain)
        .disabled(iconManager.isChanging)
        .accessibilityIdentifier("appicon.\(option.id)")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
