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

  override func applicationDidFinishLaunching(_ notification: Notification) {
    launchedAtLogin = Self.detectLoginItemLaunch()
    super.applicationDidFinishLaunching(notification)
    configureAppIcon()
    registerAppearanceObserver()
    registerSelectionCaptureChannel()
    registerAppLaunchChannel()
    registerShareCaptureChannel()
  }

  private func registerAppearanceObserver() {
    DistributedNotificationCenter.default().addObserver(
      forName: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.configureAppIcon()
    }
  }

  private func configureAppIcon() {
    let isDark: Bool
    if #available(macOS 10.14, *) {
      isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    } else {
      isDark = false
    }

    let size = NSSize(width: 512, height: 512)
    let image = NSImage(size: size)
    image.lockFocus()

    let squircleRect = NSRect(x: 20, y: 20, width: 472, height: 472)
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

    if let logoImage = NSImage(named: "AppIcon") {
      let logoPadding: CGFloat = 72
      let logoRect = NSRect(
        x: squircleRect.origin.x + logoPadding,
        y: squircleRect.origin.y + logoPadding,
        width: squircleRect.width - (logoPadding * 2),
        height: squircleRect.height - (logoPadding * 2)
      )
      logoImage.draw(in: logoRect, from: .zero, operation: .sourceOver, fraction: 1.0)
      if isDark {
        NSColor.white.setFill()
        logoRect.fill(using: .sourceIn)
      }
    }

    image.unlockFocus()
    NSApp.applicationIconImage = image
    NSApp.dockTile.display()
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
