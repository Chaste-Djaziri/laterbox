import Cocoa
import FlutterMacOS
import ApplicationServices
import ServiceManagement

@main
class AppDelegate: FlutterAppDelegate {
  private var launchedAtLogin = false
  private let shareQueue = ShareCaptureQueue(appGroupId: "group.pro.micorp.laterbox")

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  override func applicationShouldHandleReopen(
    _ sender: NSApplication,
    hasVisibleWindows flag: Bool
  ) -> Bool {
    if !flag {
      for window in NSApp.windows {
        window.makeKeyAndOrderFront(nil)
      }
    }
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  private var appearanceObservation: NSKeyValueObservation?

  override func applicationDidFinishLaunching(_ notification: Notification) {
    launchedAtLogin = Self.detectLoginItemLaunch()
    super.applicationDidFinishLaunching(notification)
    configureAppIcon()
    DispatchQueue.main.async { [weak self] in
      self?.configureAppIcon()
    }
    registerAppearanceObserver()
    registerIconChannel()
    registerSelectionCaptureChannel()
    registerAppLaunchChannel()
    registerShareCaptureChannel()
  }

  private func registerAppearanceObserver() {
    if #available(macOS 10.14, *) {
      appearanceObservation = NSApp.observe(\.effectiveAppearance, options: [.new]) { [weak self] _, _ in
        DispatchQueue.main.async {
          self?.configureAppIcon()
        }
      }
    }

    DistributedNotificationCenter.default().addObserver(
      forName: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.configureAppIcon()
    }
  }

  private func registerIconChannel() {
    guard let controller = mainFlutterWindow?.contentViewController as? FlutterViewController else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "pro.micorp.laterbox/desktop_icon",
      binaryMessenger: controller.engine.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      if call.method == "updateIcon" {
        if let args = call.arguments as? [String: Any], let isDark = args["isDark"] as? Bool {
          self?.configureAppIcon(forceDark: isDark)
          result(true)
        } else {
          self?.configureAppIcon()
          result(true)
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func isSystemDarkMode() -> Bool {
    if let style = UserDefaults.standard.string(forKey: "AppleInterfaceStyle"),
       style.caseInsensitiveCompare("Dark") == .orderedSame {
      return true
    }
    if #available(macOS 10.14, *) {
      let appearance = NSApp.effectiveAppearance.name
      if appearance == .darkAqua || appearance == .vibrantDark ||
         appearance == .accessibilityHighContrastDarkAqua ||
         appearance == .accessibilityHighContrastVibrantDark {
        return true
      }
      return NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }
    return false
  }

  private func configureAppIcon(forceDark: Bool? = nil) {
    let isDark = forceDark ?? Self.isSystemDarkMode()
    let size: CGFloat = 512

    guard let rep = NSBitmapImageRep(
      bitmapDataPlanes: nil,
      pixelsWide: Int(size),
      pixelsHigh: Int(size),
      bitsPerSample: 8,
      samplesPerPixel: 4,
      hasAlpha: true,
      isPlanar: false,
      colorSpaceName: .deviceRGB,
      bytesPerRow: Int(size) * 4,
      bitsPerPixel: 32
    ), let context = NSGraphicsContext(bitmapImageRep: rep) else {
      return
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context

    let squircleRect = NSRect(x: 20, y: 20, width: size - 40, height: size - 40)
    let path = NSBezierPath(roundedRect: squircleRect, xRadius: 105, yRadius: 105)

    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(isDark ? 0.35 : 0.15)
    shadow.shadowOffset = NSSize(width: 0, height: -4)
    shadow.shadowBlurRadius = 10
    shadow.set()

    let bgColor = isDark
      ? NSColor(calibratedRed: 0.11, green: 0.11, blue: 0.10, alpha: 1.0)
      : NSColor.white
    bgColor.setFill()
    path.fill()

    if isDark {
      NSColor.white.withAlphaComponent(0.12).setStroke()
      path.lineWidth = 1.5
      path.stroke()
    }

    NSShadow().set()

    let logoPadding: CGFloat = 72
    let logoRect = NSRect(
      x: squircleRect.origin.x + logoPadding,
      y: squircleRect.origin.y + logoPadding,
      width: squircleRect.width - (logoPadding * 2),
      height: squircleRect.height - (logoPadding * 2)
    )

    let logoImage = Self.resolveLogoImage(isDark: isDark)
    if let cg = logoImage?.cgImage(forProposedRect: nil, context: nil, hints: nil) {
      if isDark {
        context.cgContext.saveGState()
        context.cgContext.clip(to: logoRect, mask: cg)
        context.cgContext.setFillColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
        context.cgContext.fill(logoRect)
        context.cgContext.restoreGState()
      } else {
        context.cgContext.draw(cg, in: logoRect)
      }
    }

    NSGraphicsContext.restoreGraphicsState()

    let finalImage = NSImage(size: NSSize(width: size, height: size))
    finalImage.addRepresentation(rep)

    NSApp.applicationIconImage = finalImage
    NSApp.dockTile.contentView = nil
    NSApp.dockTile.display()
  }

  private static func resolveLogoImage(isDark: Bool) -> NSImage? {
    if isDark {
      if let white = NSImage(named: "AppIconWhite"), white.isValid {
        return white
      }
    }
    for bundle in Bundle.allFrameworks + Bundle.allBundles + [Bundle.main] {
      let assetName = isDark ? "laterbox-icon-white" : "laterbox-icon"
      if let url = bundle.url(forResource: assetName, withExtension: "png", subdirectory: "flutter_assets/assets/branding") ??
                   bundle.url(forResource: assetName, withExtension: "png") {
        if let img = NSImage(contentsOf: url), img.isValid {
          return img
        }
      }
    }
    return NSImage(named: "AppIcon") ?? NSApp.applicationIconImage
  }

  private func registerShareCaptureChannel() {
    guard
      let controller = mainFlutterWindow?.contentViewController as? FlutterViewController
    else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "laterbox/apple_share",
      binaryMessenger: controller.engine.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "consumePending":
        result(self.shareQueue?.readAll().map(\.toDictionary) ?? [])
      case "clearPending":
        self.shareQueue?.clear()
        result(nil)
      case "acknowledgePending":
        let arguments = call.arguments as? [String: Any]
        let ids = Set(arguments?["ids"] as? [String] ?? [])
        result(self.shareQueue?.acknowledge(ids: ids) ?? false)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func registerSelectionCaptureChannel() {
    guard
      let controller = mainFlutterWindow?.contentViewController as? FlutterViewController
    else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "laterbox/selection_capture",
      binaryMessenger: controller.engine.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "readSelectedText":
        result(Self.readSelectedText())
      case "readFrontmostApplication":
        result(Self.readFrontmostApplication())
      case "isAccessibilityTrusted":
        result(AXIsProcessTrusted())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func registerAppLaunchChannel() {
    guard
      let controller = mainFlutterWindow?.contentViewController as? FlutterViewController
    else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "laterbox/app_launch",
      binaryMessenger: controller.engine.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "wasLaunchedAtLogin":
        result(self.launchedAtLogin)
      case "isLoginItemEnabled":
        result(Self.isLoginItemEnabled())
      case "setLoginItemEnabled":
        let enabled = (call.arguments as? [String: Any])?["enabled"] as? Bool ?? false
        result(Self.setLoginItemEnabled(enabled))
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// Whether macOS marked the open-application event as a login-item launch.
  private static func detectLoginItemLaunch() -> Bool {
    guard
      let event = NSAppleEventManager.shared().currentAppleEvent,
      event.eventClass == kCoreEventClass,
      event.eventID == kAEOpenApplication
    else {
      return false
    }
    return event.paramDescriptor(forKeyword: keyAELaunchedAsLogInItem) != nil
  }

  /// Whether the app is registered as a login item (SMAppService, macOS 13+).
  private static func isLoginItemEnabled() -> Bool {
    if #available(macOS 13.0, *) {
      return SMAppService.mainApp.status == .enabled
    }
    return false
  }

  @discardableResult
  private static func setLoginItemEnabled(_ enabled: Bool) -> Bool {
    if #available(macOS 13.0, *) {
      let service = SMAppService.mainApp
      do {
        if enabled {
          if service.status != .enabled {
            try service.register()
          }
        } else {
          if service.status == .enabled {
            try service.unregister()
          }
        }
        return true
      } catch {
        NSLog("LaterBox login item update failed: \(error.localizedDescription)")
        return false
      }
    }
    return false
  }

  /// Selected text of the focused UI element, if Accessibility permission is
  /// granted and the foreground app exposes a selection.
  private static func readSelectedText() -> String? {
    guard AXIsProcessTrusted() else { return nil }

    let systemWide = AXUIElementCreateSystemWide()
    var focusedValue: CFTypeRef?
    let focusedResult = AXUIElementCopyAttributeValue(
      systemWide,
      kAXFocusedUIElementAttribute as CFString,
      &focusedValue
    )
    guard
      focusedResult == .success,
      let focused = focusedValue
    else {
      return nil
    }

    let element = focused as! AXUIElement
    var selectedValue: CFTypeRef?
    let selectedResult = AXUIElementCopyAttributeValue(
      element,
      kAXSelectedTextAttribute as CFString,
      &selectedValue
    )
    guard
      selectedResult == .success,
      let selected = selectedValue as? String,
      !selected.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else {
      return nil
    }
    return selected
  }

  /// Name of the frontmost application, captured before LaterBox takes focus.
  private static func readFrontmostApplication() -> String? {
    guard AXIsProcessTrusted() else { return nil }

    let systemWide = AXUIElementCreateSystemWide()
    var appValue: CFTypeRef?
    let appResult = AXUIElementCopyAttributeValue(
      systemWide,
      kAXFocusedApplicationAttribute as CFString,
      &appValue
    )
    guard
      appResult == .success,
      let appValue = appValue
    else {
      return nil
    }

    let app = appValue as! AXUIElement
    var titleValue: CFTypeRef?
    let titleResult = AXUIElementCopyAttributeValue(
      app,
      kAXTitleAttribute as CFString,
      &titleValue
    )
    guard
      titleResult == .success,
      let title = titleValue as? String,
      !title.isEmpty
    else {
      return nil
    }
    return title
  }
}
