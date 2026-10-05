import SwiftUI
import Combine

/// Model representing an available LaterBox alternate app icon option.
public struct AppIconOption: Identifiable, Equatable, Hashable {
    public let id: String
    public let name: String
    public let iconName: String? // nil for default/primary icon
    public let previewImageName: String
    public let subtitle: String
    public let description: String
    public let accentHex: String
    public let badgeText: String

    public var isDefault: Bool {
        iconName == nil
    }

    public var accentColor: Color {
        Color(hex: accentHex)
    }

    public init(
        id: String,
        name: String,
        iconName: String?,
        previewImageName: String,
        subtitle: String,
        description: String,
        accentHex: String,
        badgeText: String
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.previewImageName = previewImageName
        self.subtitle = subtitle
        self.description = description
        self.accentHex = accentHex
        self.badgeText = badgeText
    }
}

/// Centralized manager for querying and switching the app icon dynamically on iOS.
@MainActor
public final class AppIconManager: ObservableObject {
    public static let shared = AppIconManager()

    private let userDefaultsKey = "laterbox_selected_app_icon_id"

    @Published public private(set) var currentIconId: String
    @Published public private(set) var isChanging: Bool = false
    @Published public var errorMessage: String? = nil

    public static let availableIcons: [AppIconOption] = [
        AppIconOption(
            id: "default",
            name: "Classic Charcoal",
            iconName: nil,
            previewImageName: "AppIconPreview-Default",
            subtitle: "Signature Dark & Amber",
            description: "The original balanced LaterBox design featuring warm ivory canvas and muted dark surfaces.",
            accentHex: "F59E0B",
            badgeText: "Default"
        ),
        AppIconOption(
            id: "dark",
            name: "Midnight Obsidian",
            iconName: "AppIcon-Dark",
            previewImageName: "AppIconPreview-Dark",
            subtitle: "Pitch Black & Indigo",
            description: "Deep OLED true black surfaces with frosted dark glass and subtle luminescent edges.",
            accentHex: "6366F1",
            badgeText: "Dark"
        ),
        AppIconOption(
            id: "emerald",
            name: "Emerald Forest",
            iconName: "AppIcon-Emerald",
            previewImageName: "AppIconPreview-Emerald",
            subtitle: "Botanical Green & Glass",
            description: "Vibrant organic mint and emerald hues inspired by lush canopy tones and calm clarity.",
            accentHex: "10B981",
            badgeText: "Eco"
        ),
        AppIconOption(
            id: "neon",
            name: "Cyber Neon",
            iconName: "AppIcon-Neon",
            previewImageName: "AppIconPreview-Neon",
            subtitle: "Electric Cyan & Violet",
            description: "High-contrast synthwave aesthetic with radiant electric cyan and vaporwave gradients.",
            accentHex: "06B6D4",
            badgeText: "Vibrant"
        ),
        AppIconOption(
            id: "sunset",
            name: "Amber Sunset",
            iconName: "AppIcon-Sunset",
            previewImageName: "AppIconPreview-Sunset",
            subtitle: "Warm Copper & Gold",
            description: "Warm golden-hour radiance with rich copper gradients and dusk glow accents.",
            accentHex: "F97316",
            badgeText: "Warm"
        ),
        AppIconOption(
            id: "monochrome",
            name: "Pure Monochrome",
            iconName: "AppIcon-Monochrome",
            previewImageName: "AppIconPreview-Monochrome",
            subtitle: "Minimalist Slate & Steel",
            description: "Stripped back timeless grayscale for minimalists who appreciate subtle editorial clarity.",
            accentHex: "71717A",
            badgeText: "Minimal"
        )
    ]

    public var currentIconOption: AppIconOption {
        Self.availableIcons.first(where: { $0.id == currentIconId }) ?? Self.availableIcons[0]
    }

    public var supportsAlternateIcons: Bool {
        #if os(iOS)
        return UIApplication.shared.supportsAlternateIcons
        #else
        return false
        #endif
    }

    public init() {
        // Fast start from cached selection
        let cachedId = UserDefaults.standard.string(forKey: userDefaultsKey) ?? "default"
        self.currentIconId = cachedId
        self.refreshCurrentIcon()
    }

    /// Synchronizes current state with the runtime UIApplication bundle state
    public func refreshCurrentIcon() {
        #if os(iOS)
        if UIApplication.shared.supportsAlternateIcons {
            if let altName = UIApplication.shared.alternateIconName {
                if let match = Self.availableIcons.first(where: { $0.iconName == altName }) {
                    self.currentIconId = match.id
                    UserDefaults.standard.set(match.id, forKey: userDefaultsKey)
                }
            } else {
                self.currentIconId = "default"
                UserDefaults.standard.set("default", forKey: userDefaultsKey)
            }
        }
        #endif
    }

    /// Sets the app icon to the selected option, showing native system confirmation dialog
    @discardableResult
    public func selectIcon(_ option: AppIconOption) async -> Bool {
        guard option.id != currentIconId else { return true }

        #if os(iOS)
        guard UIApplication.shared.supportsAlternateIcons else {
            self.errorMessage = "Alternate app icons are not supported on this device environment."
            return false
        }

        isChanging = true
        defer { isChanging = false }

        do {
            try await UIApplication.shared.setAlternateIconName(option.iconName)
            self.currentIconId = option.id
            UserDefaults.standard.set(option.id, forKey: userDefaultsKey)
            self.errorMessage = nil
            LBHaptic.success()
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            LBHaptic.error()
            return false
        }
        #else
        return false
        #endif
    }
}
