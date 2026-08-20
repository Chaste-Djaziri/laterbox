import Cocoa
import FlutterMacOS
import ApplicationServices

@main
class AppDelegate: FlutterAppDelegate {
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
    super.applicationDidFinishLaunching(notification)
    registerSelectionCaptureChannel()
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
      default:
        result(FlutterMethodNotImplemented)
      }
    }
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