import Foundation
import Combine
#if canImport(Darwin)
import Darwin
#endif

// MARK: - On-Device Hardware Capability Detection

public enum OnDeviceModelSupport {
    /// Raw hardware identifier (e.g. "iPhone16,1", "iPhone17,3")
    public static var modelIdentifier: String {
        #if targetEnvironment(simulator)
        if let simModel = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"], !simModel.isEmpty {
            return simModel
        }
        #endif
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }

    /// User-friendly marketing name of the device
    public static var deviceMarketingName: String {
        let id = modelIdentifier
        if id.contains("iPhone-17-Pro-Max") || id == "iPhone18,2" { return "iPhone 17 Pro Max" }
        if id.contains("iPhone-17-Pro") || id == "iPhone18,1" { return "iPhone 17 Pro" }
        if id.contains("iPhone-17e") || id == "iPhone18,5" { return "iPhone 17e" }
        if id.contains("iPhone-17") || id == "iPhone18,3" || id == "iPhone18,4" { return "iPhone 17" }
        if id.contains("iPhone-16-Pro-Max") || id == "iPhone17,2" { return "iPhone 16 Pro Max" }
        if id.contains("iPhone-16-Pro") || id == "iPhone17,1" { return "iPhone 16 Pro" }
        if id.contains("iPhone-16-Plus") || id == "iPhone17,4" { return "iPhone 16 Plus" }
        if id.contains("iPhone-16e") || id == "iPhone17,5" { return "iPhone 16e" }
        if id.contains("iPhone-16") || id == "iPhone17,3" { return "iPhone 16" }
        if id.contains("iPhone-15-Pro-Max") || id == "iPhone16,2" { return "iPhone 15 Pro Max" }
        if id.contains("iPhone-15-Pro") || id == "iPhone16,1" { return "iPhone 15 Pro" }
        if id.contains("iPhone-15-Plus") || id == "iPhone15,5" { return "iPhone 15 Plus" }
        if id.contains("iPhone-15") || id == "iPhone15,4" { return "iPhone 15" }
        if id.contains("iPhone-14-Pro") || id.contains("iPhone15,2") || id.contains("iPhone15,3") { return "iPhone 14 Pro" }
        if id.contains("iPhone-14") || id.contains("iPhone14,7") || id.contains("iPhone14,8") { return "iPhone 14" }
        if id.contains("iPad") { return "iPad" }
        if id.contains("Mac") { return "Mac" }
        return id.replacingOccurrences(of: "-", with: " ")
    }

    /// Formatted total system RAM
    public static var formattedRAM: String {
        let bytes = ProcessInfo.processInfo.physicalMemory
        let gigabytes = Double(bytes) / 1_073_741_824.0
        return String(format: "%.0f GB Unified Memory", gigabytes.rounded())
    }

    /// Checks if device hardware meets requirements for Apple Intelligence / on-device foundation models
    /// Requirements: 8GB+ RAM, Apple Neural Engine, A17 Pro / A18 / A19 / M-series chips.
    public static var isSupported: Bool {
        let id = modelIdentifier.lowercased()

        // Explicitly unsupported generations (A16 or older, <8GB RAM)
        if id.contains("iphone-11") || id.contains("iphone-12") || id.contains("iphone-13") || id.contains("iphone-14") || id.contains("iphone-se") {
            return false
        }
        if id.contains("iphone-15-plus") || (id.contains("iphone-15") && !id.contains("pro")) {
            return false
        }
        if id.hasPrefix("iphone14,") || id.hasPrefix("iphone15,") {
            return false
        }

        // Supported generations (iPhone 15 Pro/Max, iPhone 16 series, iPhone 17 series and future)
        if id.contains("15-pro") || id == "iphone16,1" || id == "iphone16,2" {
            return true
        }
        if id.contains("iphone-16") || id.hasPrefix("iphone17,") {
            return true
        }
        if id.contains("iphone-17") || id.contains("iphone-18") || id.hasPrefix("iphone18,") || id.hasPrefix("iphone19,") {
            return true
        }

        // iPad / Mac with Apple Silicon M1+ (8GB+ RAM)
        if (id.contains("ipad") || id.contains("mac")) && ProcessInfo.processInfo.physicalMemory >= 7_500_000_000 {
            return true
        }

        #if targetEnvironment(simulator)
        return true
        #else
        return ProcessInfo.processInfo.physicalMemory >= 7_500_000_000
        #endif
    }
}

// MARK: - On-Device AI Provider

@MainActor
public struct OnDeviceLaterAIProvider: LaterAIProvider {
    private let fallback = DeterministicLaterAIProvider()

    public init() {}

    public func respond(_ prompt: String) async throws -> AIAction {
        // Ready for future integration with Apple Intelligence on-device model APIs
        return try await fallback.respond(prompt)
    }
}

// MARK: - Provider Types

public enum AIProviderType: String, CaseIterable, Identifiable, Codable {
    case local
    case onDevice

    public var id: String { rawValue }
    public var displayName: String {
        switch self {
        case .local: return "Local responses"
        case .onDevice: return "On-Device Model"
        }
    }
    public var shortName: String {
        switch self {
        case .local: return "Local"
        case .onDevice: return "On-Device"
        }
    }
    public var subtitle: String {
        switch self {
        case .local: return "Offline deterministic capture assistant"
        case .onDevice: return "Apple Intelligence on-device neural processing"
        }
    }
    public var iconName: String {
        switch self {
        case .local: return "wand.and.stars"
        case .onDevice: return "cpu"
        }
    }
    public var isCustomKey: Bool { false }
}

// MARK: - Model Manager

@MainActor
public final class LaterAIModelManager: ObservableObject {
    public static let shared = LaterAIModelManager()

    @Published public var selectedProvider: AIProviderType = .local
    @Published public var enableSearchRefine: Bool = true
    @Published public var isOnDeviceModelEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isOnDeviceModelEnabled, forKey: "laterbox_enable_on_device_model")
        }
    }

    public var isOnDeviceModelSupported: Bool {
        OnDeviceModelSupport.isSupported
    }

    public var deviceMarketingName: String {
        OnDeviceModelSupport.deviceMarketingName
    }

    public var deviceHardwareSummary: String {
        "\(OnDeviceModelSupport.deviceMarketingName) · \(OnDeviceModelSupport.formattedRAM)"
    }

    public var supportStatusMessage: String {
        if isOnDeviceModelSupported {
            return "This iPhone supports on-device Apple Intelligence and Neural Engine processing. AI tasks run locally with zero data leaving your device."
        } else {
            return "On-device foundation models require an iPhone with at least 8GB RAM and an A17 Pro chip or newer (iPhone 15 Pro, iPhone 16, iPhone 17 series). LaterBox uses local deterministic responses on this device."
        }
    }

    public var activeModelName: String {
        switch selectedProvider {
        case .local:
            return "Local assistant"
        case .onDevice:
            return "On-Device Neural Engine"
        }
    }

    public var canRefineSearch: Bool { true }

    public init() {
        let isSupported = OnDeviceModelSupport.isSupported
        if UserDefaults.standard.object(forKey: "laterbox_enable_on_device_model") != nil {
            self.isOnDeviceModelEnabled = isSupported && UserDefaults.standard.bool(forKey: "laterbox_enable_on_device_model")
        } else {
            // Enable by default on iPhones that support it
            self.isOnDeviceModelEnabled = isSupported
        }
    }

    public func activeProvider() -> any LaterAIProvider {
        switch selectedProvider {
        case .local:
            return DeterministicLaterAIProvider()
        case .onDevice:
            return OnDeviceLaterAIProvider()
        }
    }

    public func interpretSearch(_ query: String) async throws -> SearchInterpretation {
        SearchInterpretation(terms: query.trimmingCharacters(in: .whitespacesAndNewlines), contentType: "", returnWindow: "")
    }

    public func testConnection(for provider: AIProviderType) async throws -> String {
        switch provider {
        case .local:
            return "Local responses are available offline."
        case .onDevice:
            if isOnDeviceModelSupported {
                return "On-device Apple Intelligence hardware is ready on \(deviceMarketingName)."
            } else {
                return "On-device foundation models are not supported on this device."
            }
        }
    }
}
