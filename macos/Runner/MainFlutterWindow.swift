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

    // Let Flutter paint behind the traffic lights. The desktop shell supplies
    // the same charcoal surface as the macOS sidebar, keeping window chrome
    // and navigation visually continuous rather than two stacked color bars.
    styleMask.insert(.fullSizeContentView)
    titleVisibility = .hidden
    titlebarAppearsTransparent = true
    backgroundColor = NSColor(
      calibratedRed: 43.0 / 255.0,
      green: 43.0 / 255.0,
      blue: 43.0 / 255.0,
      alpha: 1
    )

    (AppDelegate.shared ?? NSApp.delegate as? AppDelegate)?.registerChannels(controller: flutterViewController)
  }
}
