import Cocoa
import FlutterMacOS
import ApplicationServices
import ServiceManagement

@main
class AppDelegate: FlutterAppDelegate {
  static weak var shared: AppDelegate?
  private var launchedAtLogin = false
  private let shareQueue = ShareCaptureQueue(appGroupId: "group.pro.micorp.laterbox")
  private var companionChannel: FlutterMethodChannel?

  override init() {
    super.init()
    Self.shared = self
  }

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
    NSApp.servicesProvider = self
    configureAppIcon()
    registerAppearanceObserver()
    registerChannels()
    DispatchQueue.main.async { [weak self] in
      self?.configureAppIcon()
      self?.registerChannels()
    }
  }

  private var channelsRegistered = false

  func registerChannels(controller: FlutterViewController? = nil) {
    guard !channelsRegistered else { return }
    guard let ctrl = controller ?? getFlutterViewController() else { return }
    channelsRegistered = true

    registerIconChannel(controller: ctrl)
    registerSelectionCaptureChannel(controller: ctrl)
    registerAppLaunchChannel(controller: ctrl)
    registerShareCaptureChannel(controller: ctrl)
    registerMacCompanionChannel(controller: ctrl)
  }

  private func getFlutterViewController() -> FlutterViewController? {
    if let controller = mainFlutterWindow?.contentViewController as? FlutterViewController {
      return controller
    }
    for window in NSApp.windows {
      if let controller = window.contentViewController as? FlutterViewController {
        return controller
      }
    }
    return nil
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

  private func registerIconChannel(controller: FlutterViewController) {
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

  private func registerShareCaptureChannel(controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: "laterbox/apple_share",
      binaryMessenger: controller.engine.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "consumePending":
        result(self.shareQueue.readAll().map(\.toDictionary))
      case "clearPending":
        self.shareQueue.clear()
        result(nil)
      case "acknowledgePending":
        let arguments = call.arguments as? [String: Any]
        let ids = Set(arguments?["ids"] as? [String] ?? [])
        result(self.shareQueue.acknowledge(ids: ids))
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static var lastExternalAppName: String?

  private func registerSelectionCaptureChannel(controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: "laterbox/selection_capture",
      binaryMessenger: controller.engine.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "readSelectedText":
        result(Self.readSelectedText())
      case "readFrontmostApplication":
        result(Self.lastExternalAppName ?? Self.readFrontmostApplication())
      case "readActiveBrowserTab":
        let app = (call.arguments as? [String: Any])?["appName"] as? String ?? Self.lastExternalAppName ?? Self.readFrontmostApplication()
        result(Self.readActiveBrowserTab(appName: app))
      case "readScreenContext":
        result(Self.readScreenContext())
      case "formatHighlightUrl":
        if let args = call.arguments as? [String: Any],
           let url = args["url"] as? String,
           let text = args["text"] as? String {
          result(Self.formatTextFragmentUrl(baseUrl: url, quote: text))
        } else {
          result(nil)
        }
      case "isAccessibilityTrusted":
        result(AXIsProcessTrusted())
      case "requestAccessibilityPermission":
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        result(AXIsProcessTrustedWithOptions(options))
      case "getScreenGeometry":
        let screen = NSScreen.main
        let frame = screen?.frame ?? .zero
        let visibleFrame = screen?.visibleFrame ?? .zero
        var notchHeight: CGFloat = 0.0
        var hasNotch = false
        if #available(macOS 12.0, *) {
          notchHeight = screen?.safeAreaInsets.top ?? 0.0
          hasNotch = notchHeight > 0
        }
        result([
          "screenWidth": Double(frame.width),
          "screenHeight": Double(frame.height),
          "visibleWidth": Double(visibleFrame.width),
          "visibleHeight": Double(visibleFrame.height),
          "notchHeight": Double(notchHeight),
          "hasNotch": hasNotch
        ])
      case "setNotchWindowStyle":
        if let args = call.arguments as? [String: Any],
           let isNotch = args["isNotch"] as? Bool {
          Self.setNotchWindowStyle(isNotch: isNotch)
          result(true)
        } else {
          result(false)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    NSWorkspace.shared.notificationCenter.addObserver(
      forName: NSWorkspace.didActivateApplicationNotification,
      object: nil,
      queue: .main
    ) { notification in
      if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
         let bundleId = app.bundleIdentifier,
         bundleId != Bundle.main.bundleIdentifier,
         let name = app.localizedName {
        Self.lastExternalAppName = name
      }
    }
  }

  private func registerAppLaunchChannel(controller: FlutterViewController) {
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

  /// Queries active browser tab URL and title for known browsers (Safari, Chrome, Arc, Brave, Edge).
  private static func readActiveBrowserTab(appName: String?) -> [String: String]? {
    guard let rawName = appName?.lowercased() else { return nil }
    var scriptSource: String?

    if rawName.contains("safari") && !rawName.contains("technology preview") {
      scriptSource = """
      tell application "Safari"
        if (count of windows) > 0 then
          set currentTab to current tab of front window
          return (URL of currentTab) & "|||" & (name of currentTab)
        end if
      end tell
      """
    } else if rawName.contains("chrome") {
      scriptSource = """
      tell application "Google Chrome"
        if (count of windows) > 0 then
          set currentTab to active tab of front window
          return (URL of currentTab) & "|||" & (title of currentTab)
        end if
      end tell
      """
    } else if rawName.contains("arc") {
      scriptSource = """
      tell application "Arc"
        if (count of windows) > 0 then
          set currentTab to active tab of front window
          return (URL of currentTab) & "|||" & (title of currentTab)
        end if
      end tell
      """
    } else if rawName.contains("brave") {
      scriptSource = """
      tell application "Brave Browser"
        if (count of windows) > 0 then
          set currentTab to active tab of front window
          return (URL of currentTab) & "|||" & (title of currentTab)
        end if
      end tell
      """
    } else if rawName.contains("edge") {
      scriptSource = """
      tell application "Microsoft Edge"
        if (count of windows) > 0 then
          set currentTab to active tab of front window
          return (URL of currentTab) & "|||" & (title of currentTab)
        end if
      end tell
      """
    }

    guard let script = scriptSource else { return nil }
    guard let appleScript = NSAppleScript(source: script) else { return nil }
    var errorInfo: NSDictionary?
    let descriptor = appleScript.executeAndReturnError(&errorInfo)
    if let resultString = descriptor.stringValue, resultString.contains("|||") {
      let parts = resultString.components(separatedBy: "|||")
      let url = parts.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      let title = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespacesAndNewlines) : ""
      if !url.isEmpty && (url.hasPrefix("http://") || url.hasPrefix("https://")) {
        return ["url": url, "title": title]
      }
    }
    return nil
  }

  /// Comprehensive active screen context: frontmost app, active browser URL, page title,
  /// selected text, and a formatted Text Fragment highlight URL.
  private static func readScreenContext() -> [String: Any]? {
    let appName = lastExternalAppName ?? readFrontmostApplication()
    let activeBrowser = readActiveBrowserTab(appName: appName)
    let selectedText = readSelectedText()
    let activeUrl = activeBrowser?["url"]
    let pageTitle = activeBrowser?["title"]

    var highlightUrl: String? = nil
    if let activeUrl = activeUrl, let selected = selectedText, !selected.isEmpty {
      highlightUrl = formatTextFragmentUrl(baseUrl: activeUrl, quote: selected)
    }

    var result: [String: Any] = [:]
    if let appName = appName { result["application"] = appName }
    if let activeUrl = activeUrl { result["url"] = activeUrl }
    if let pageTitle = pageTitle { result["title"] = pageTitle }
    if let selectedText = selectedText { result["selectedText"] = selectedText }
    if let highlightUrl = highlightUrl { result["highlightUrl"] = highlightUrl }

    return result.isEmpty ? nil : result
  }

  /// Builds a W3C Scroll-to-Text Fragment URL for direct word highlight navigation.
  private static func formatTextFragmentUrl(baseUrl: String, quote: String) -> String {
    let cleanUrl = baseUrl.components(separatedBy: "#").first ?? baseUrl
    if baseUrl.contains(":~:text=") { return baseUrl }

    let cleanSnippet = quote.trimmingCharacters(in: .whitespacesAndNewlines)
      .trimmingCharacters(in: CharacterSet(charactersIn: "\"“”'"))
    let words = cleanSnippet.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
    let encodedDirective: String
    if words.count > 10 {
      let start = words.prefix(3).joined(separator: " ")
      let end = words.suffix(3).joined(separator: " ")
      if let startEnc = start.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
         let endEnc = end.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
        encodedDirective = "\(startEnc),\(endEnc)"
      } else {
        encodedDirective = cleanSnippet.prefix(120).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cleanSnippet
      }
    } else {
      encodedDirective = cleanSnippet.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cleanSnippet
    }

    return "\(cleanUrl)#:~:text=\(encodedDirective)"
  }

  /// Sets native window attributes for floating directly in the macOS screen notch.
  static func setNotchWindowStyle(isNotch: Bool) {
    DispatchQueue.main.async {
      guard let window = NSApp.windows.first else { return }
      if isNotch {
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.styleMask.insert(.fullSizeContentView)
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.level = .statusBar
      } else {
        window.isOpaque = true
        window.backgroundColor = .windowBackgroundColor
        window.hasShadow = true
        window.titleVisibility = .visible
        window.titlebarAppearsTransparent = false
        window.standardWindowButton(.closeButton)?.isHidden = false
        window.standardWindowButton(.miniaturizeButton)?.isHidden = false
        window.standardWindowButton(.zoomButton)?.isHidden = false
        window.level = .normal
      }
    }
  }

  private let notchController = NotchPanelController()
  private var screenWatcher: Any?

  private func registerMacCompanionChannel(controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: "laterbox/macos_companion",
      binaryMessenger: controller.engine.binaryMessenger
    )
    self.companionChannel = channel

    if #available(macOS 12.3, *) {
      let watcher = ScreenWatcher()
      watcher.onCandidateDetected = { [weak self] candidate in
        self?.notchController.presentCandidate(candidate)
        channel.invokeMethod("screenCandidateDetected", arguments: [
          "title": candidate.title,
          "url": candidate.url as Any,
          "snippet": candidate.snippet as Any
        ])
      }
      self.screenWatcher = watcher
    }

    notchController.onCaptureRequested = { [weak self] candidate in
      channel.invokeMethod("saveCandidate", arguments: [
        "id": candidate.id,
        "title": candidate.title,
        "url": candidate.url as Any,
        "snippet": candidate.text as Any,
        "source": candidate.source.rawValue,
        "kind": candidate.kind.rawValue
      ]) { response in
        DispatchQueue.main.async {
          guard let result = response as? [String: Any], result["ok"] as? Bool == true else {
            let message = (response as? [String: Any])?["message"] as? String ?? "LaterBox could not save this item."
            self?.notchController.captureFailed(id: candidate.id, message: message)
            return
          }
          let title = result["title"] as? String ?? candidate.title
          let value = candidate.url ?? candidate.text ?? candidate.title
          self?.notchController.captureCompleted(id: candidate.id, title: title, value: value, kind: candidate.kind)
        }
      }
    }

    notchController.onOpenLaterBox = { [weak self] in
      if let window = self?.mainFlutterWindow {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
      }
      channel.invokeMethod("openLaterBox", arguments: nil)
    }

    notchController.onToggleWatchMode = { [weak self] isWatching in
      if #available(macOS 12.3, *) {
        if let watcher = self?.screenWatcher as? ScreenWatcher {
          Task { @MainActor in
            if isWatching {
              try? await watcher.start()
            } else {
              await watcher.stop()
            }
          }
        }
      }
      channel.invokeMethod("watchModeChanged", arguments: ["isWatching": isWatching])
    }

    notchController.onDroppedItems = { items in
      channel.invokeMethod("itemsDropped", arguments: ["items": items])
    }

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "showNotch":
        self.notchController.show()
        result(true)
      case "hideNotch":
        self.notchController.hide()
        result(true)
      case "startWatching":
        if #available(macOS 12.3, *) {
          if let watcher = self.screenWatcher as? ScreenWatcher {
            Task { @MainActor in
              do {
                try await watcher.start()
                self.notchController.setWatchingState(true)
                result(true)
              } catch {
                result(FlutterError(code: "SCREEN_CAPTURE_FAILED", message: error.localizedDescription, details: nil))
              }
            }
          } else {
            result(false)
          }
        } else {
          result(false)
        }
      case "stopWatching":
        if #available(macOS 12.3, *) {
          if let watcher = self.screenWatcher as? ScreenWatcher {
            Task { @MainActor in
              await watcher.stop()
              self.notchController.setWatchingState(false)
              result(true)
            }
          } else {
            result(true)
          }
        } else {
          result(true)
        }
      case "setWatchingState":
        if let args = call.arguments as? [String: Any], let isWatching = args["isWatching"] as? Bool {
          self.notchController.setWatchingState(isWatching)
          result(true)
        } else {
          result(false)
        }
      case "captureCompleted":
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? String,
              let title = args["title"] as? String,
              let value = args["value"] as? String,
              let kindValue = args["kind"] as? String,
              let kind = NotchContentKind(rawValue: kindValue) else {
          result(false)
          return
        }
        self.notchController.captureCompleted(id: id, title: title, value: value, kind: kind)
        result(true)
      case "captureFailed":
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? String else {
          result(false)
          return
        }
        self.notchController.captureFailed(
          id: id,
          message: args["message"] as? String ?? "LaterBox could not save this item."
        )
        result(true)
      case "dismissCandidate":
        self.notchController.dismissCurrentState()
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // MARK: - macOS Right-Click Context Menu / Services Handler

  @objc func saveToLaterBoxService(
    _ pboard: NSPasteboard,
    userData: String,
    error: AutoreleasingUnsafeMutablePointer<NSString>
  ) {
    var capturedUrl: String?
    var capturedText: String?

    if let urls = pboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], let firstUrl = urls.first {
      capturedUrl = firstUrl.absoluteString
    }

    if let strings = pboard.readObjects(forClasses: [NSString.self], options: nil) as? [String], let firstString = strings.first {
      if capturedUrl == nil, firstString.hasPrefix("http://") || firstString.hasPrefix("https://") {
        capturedUrl = firstString
      } else {
        capturedText = firstString
      }
    }

    if capturedUrl == nil && capturedText == nil {
      if let string = pboard.string(forType: .string) {
        if string.hasPrefix("http://") || string.hasPrefix("https://") {
          capturedUrl = string
        } else {
          capturedText = string
        }
      }
    }

    guard capturedUrl != nil || capturedText != nil else { return }

    let title = capturedText ?? capturedUrl ?? "Quick Save"
    let item = ShareCaptureItem(
      id: UUID().uuidString,
      title: title,
      url: capturedUrl,
      text: capturedText,
      filePaths: [],
      createdAt: Date(),
      source: "macosContextMenu"
    )
    if companionChannel != nil {
      let kind: NotchContentKind = capturedUrl != nil && capturedText != nil
        ? .highlight
        : capturedUrl != nil ? .link : .note
      let candidate = NotchCaptureCandidate(
        id: item.id,
        title: item.title,
        url: item.url,
        text: item.text,
        source: .macosService,
        kind: kind
      )
      notchController.show()
      notchController.presentExternalCandidate(candidate)
    } else {
      shareQueue.enqueue(item)
    }
  }
}
