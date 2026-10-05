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
    public let category: String

    public var isDefault: Bool {
        iconName == nil
    }

    public var isProOnly: Bool {
        id != "default"
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
        badgeText: String,
        category: String = "Signature"
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.previewImageName = previewImageName
        self.subtitle = subtitle
        self.description = description
        self.accentHex = accentHex
        self.badgeText = badgeText
        self.category = category
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

    public static let categories: [String] = [
        "All",
        "Signature",
        "Gaming",
        "Anime",
        "Horror",
        "Gadgets",
        "Animation",
        "Tech & Geek"
    ]

    public static let availableIcons: [AppIconOption] = [
        // MARK: - Signature Themes
        AppIconOption(
            id: "default",
            name: "Classic Charcoal",
            iconName: nil,
            previewImageName: "AppIconPreview-Default",
            subtitle: "Signature Dark & Amber",
            description: "The original balanced LaterBox design featuring warm ivory canvas and muted dark surfaces.",
            accentHex: "F59E0B",
            badgeText: "Default",
            category: "Signature"
        ),
        AppIconOption(
            id: "dark",
            name: "Midnight Obsidian",
            iconName: "AppIcon-Dark",
            previewImageName: "AppIconPreview-Dark",
            subtitle: "Pitch Black & Indigo",
            description: "Deep OLED true black surfaces with frosted dark glass and subtle luminescent edges.",
            accentHex: "6366F1",
            badgeText: "Dark",
            category: "Signature"
        ),
        AppIconOption(
            id: "emerald",
            name: "Emerald Forest",
            iconName: "AppIcon-Emerald",
            previewImageName: "AppIconPreview-Emerald",
            subtitle: "Botanical Green & Glass",
            description: "Vibrant organic mint and emerald hues inspired by lush canopy tones and calm clarity.",
            accentHex: "10B981",
            badgeText: "Eco",
            category: "Signature"
        ),
        AppIconOption(
            id: "neon",
            name: "Cyber Neon",
            iconName: "AppIcon-Neon",
            previewImageName: "AppIconPreview-Neon",
            subtitle: "Electric Cyan & Violet",
            description: "High-contrast synthwave aesthetic with radiant electric cyan and vaporwave gradients.",
            accentHex: "06B6D4",
            badgeText: "Vibrant",
            category: "Signature"
        ),
        AppIconOption(
            id: "sunset",
            name: "Amber Sunset",
            iconName: "AppIcon-Sunset",
            previewImageName: "AppIconPreview-Sunset",
            subtitle: "Warm Copper & Gold",
            description: "Warm golden-hour radiance with rich copper gradients and dusk glow accents.",
            accentHex: "F97316",
            badgeText: "Warm",
            category: "Signature"
        ),
        AppIconOption(
            id: "monochrome",
            name: "Pure Monochrome",
            iconName: "AppIcon-Monochrome",
            previewImageName: "AppIconPreview-Monochrome",
            subtitle: "Minimalist Slate & Steel",
            description: "Stripped back timeless grayscale for minimalists who appreciate subtle editorial clarity.",
            accentHex: "71717A",
            badgeText: "Minimal",
            category: "Signature"
        ),

        // MARK: - Fun, Games, Anime, Pop Culture & Tech
        AppIconOption(
            id: "arcade",
            name: "Pixel Arcade",
            iconName: "AppIcon-Arcade",
            previewImageName: "AppIconPreview-Arcade",
            subtitle: "8-Bit Retro Gaming",
            description: "Glossy neon retro arcade joystick and glowing action buttons on cosmic deep indigo.",
            accentHex: "EC4899",
            badgeText: "Retro",
            category: "Gaming"
        ),
        AppIconOption(
            id: "anime",
            name: "Cyber Mecha",
            iconName: "AppIcon-Anime",
            previewImageName: "AppIconPreview-Anime",
            subtitle: "Neo-Tokyo Mecha Visor",
            description: "Intense robotic optical visor with electric cyan, magenta neon wings and sharp sci-fi armor.",
            accentHex: "06B6D4",
            badgeText: "Mecha",
            category: "Anime"
        ),
        AppIconOption(
            id: "horror",
            name: "Phantom Ghost",
            iconName: "AppIcon-Horror",
            previewImageName: "AppIconPreview-Horror",
            subtitle: "Ethereal Spectral Wisp",
            description: "Cute & eerie glowing phantom ghost surrounded by mysterious violet flame wisps.",
            accentHex: "A855F7",
            badgeText: "Spooky",
            category: "Horror"
        ),
        AppIconOption(
            id: "gadget",
            name: "Cyber Cassette",
            iconName: "AppIcon-Gadget",
            previewImageName: "AppIconPreview-Gadget",
            subtitle: "Holographic Glass Tape",
            description: "Futuristic transparent acrylic cassette cartridge packed with glowing circuit lines and tape reels.",
            accentHex: "F59E0B",
            badgeText: "Gizmo",
            category: "Gadgets"
        ),
        AppIconOption(
            id: "animation",
            name: "Cosmic Pop",
            iconName: "AppIcon-Animation",
            previewImageName: "AppIconPreview-Animation",
            subtitle: "3D Claymorphic Mascot",
            description: "Joyful animated star character floating among bubbly pastel sparkle orbs and soft candy skies.",
            accentHex: "FBBF24",
            badgeText: "Kawaii",
            category: "Animation"
        ),
        AppIconOption(
            id: "terminal",
            name: "Matrix Terminal",
            iconName: "AppIcon-Terminal",
            previewImageName: "AppIconPreview-Terminal",
            subtitle: "Retro Phosphor CRT",
            description: "Curved cathode-ray tube monitor flashing radiant phosphor green command line matrix code.",
            accentHex: "22C55E",
            badgeText: "Hacker",
            category: "Tech & Geek"
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

        if option.isProOnly && !SyncCoordinator.shared.isProUser {
            self.errorMessage = "Alternate app icons require an active LaterBox Pro plan."
            LBHaptic.error()
            return false
        }

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
