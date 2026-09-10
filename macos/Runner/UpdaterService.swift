import AppKit
import Foundation

/// Sparkle-based automatic updater for direct (non-MAS) builds.
/// In Mac App Store builds Sparkle is disabled; updates come via App Store Connect.
/// This wrapper compiles with or without the Sparkle package — when
/// `canImport(Sparkle)` is false it becomes a no-op so `xcodebuild` works
/// before `Runner.xcworkspace` has resolved the remote package.
#if canImport(Sparkle)
import Sparkle

@MainActor
final class UpdaterService: NSObject, SPUUpdaterDelegate, SPUStandardUserDriverDelegate {
  static let shared = UpdaterService()

  private var updaterController: SPUStandardUpdaterController?

  func start() {
    // Only run Sparkle for direct distribution. MAS builds set MAS_BUILD=1.
    #if MAS_BUILD
    return
    #else
    updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: self, userDriverDelegate: self)
    #endif
  }

  func checkForUpdates() {
    updaterController?.checkForUpdates(nil)
  }

  var canCheckForUpdates: Bool { updaterController?.updater.canCheckForUpdates == true }

  // MARK: - SPUUpdaterDelegate

  func feedURLString(for updater: SPUUpdater) -> String? {
    // Overridden by Info.plist SUFeedURL; keep code fallback.
    return Bundle.main.infoDictionary?["SUFeedURL"] as? String
  }

  func updaterWillRelaunchApplication(_ updater: SPUUpdater) {
    // Flush pending shares before relaunch — share queue is file-backed so no loss.
    NSLog("[LaterBox Updater] relaunching for update")
  }
}
#else
@MainActor
final class UpdaterService {
  static let shared = UpdaterService()
  func start() { NSLog("[LaterBox Updater] Sparkle not linked — add https://github.com/sparkle-project/Sparkle via SPM to enable auto-updates") }
  func checkForUpdates() { NSLog("[LaterBox Updater] checkForUpdates ignored — Sparkle not linked") }
  var canCheckForUpdates: Bool { false }
}
#endif
