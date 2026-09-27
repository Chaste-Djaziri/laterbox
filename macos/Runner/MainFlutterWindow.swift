import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    if let screen = NSScreen.main {
      self.setFrame(screen.visibleFrame, display: true)
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()

    // Let Flutter paint behind the traffic lights. This shares the LaterBox
    // light surface with the sidebar instead of leaving a separate title bar.
    styleMask.insert(.fullSizeContentView)
    titleVisibility = .hidden
    titlebarAppearsTransparent = true
    titlebarSeparatorStyle = .none
    backgroundColor = NSColor(
      calibratedRed: 247.0 / 255.0,
      green: 245.0 / 255.0,
      blue: 238.0 / 255.0,
      alpha: 1
    )

    (AppDelegate.shared ?? NSApp.delegate as? AppDelegate)?.registerChannels(controller: flutterViewController)
  }
}
