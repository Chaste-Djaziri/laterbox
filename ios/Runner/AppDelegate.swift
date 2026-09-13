import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, FlutterStreamHandler {
  private let queue = ShareCaptureQueue(appGroupId: "group.pro.micorp.laterbox")
  private var shareChannel: FlutterMethodChannel?
  private var clipboardEventChannel: FlutterEventChannel?
  private var clipboardEventSink: FlutterEventSink?
  private var pasteboardObserver: NSObjectProtocol?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerShareChannel(with: engineBridge.applicationRegistrar.messenger())
    registerClipboardChannel(with: engineBridge.applicationRegistrar.messenger())
  }

  func registerShareChannel(with messenger: FlutterBinaryMessenger) {
    if shareChannel != nil { return }
    let channel = FlutterMethodChannel(
      name: "laterbox/apple_share",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "consumePending":
        result(self.queue.readAll().map(\.toDictionary))
      case "clearPending":
        self.queue.clear()
        result(nil)
      case "acknowledgePending":
        let arguments = call.arguments as? [String: Any]
        let ids = Set(arguments?["ids"] as? [String] ?? [])
        result(self.queue.acknowledge(ids: ids))
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    self.shareChannel = channel
  }

  private func registerClipboardChannel(with messenger: FlutterBinaryMessenger) {
    if clipboardEventChannel != nil { return }
    let channel = FlutterEventChannel(
      name: "laterbox/ios_clipboard",
      binaryMessenger: messenger
    )
    channel.setStreamHandler(self)
    clipboardEventChannel = channel
  }

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    clipboardEventSink = events
    pasteboardObserver = NotificationCenter.default.addObserver(
      forName: UIPasteboard.changedNotification,
      object: UIPasteboard.general,
      queue: .main
    ) { [weak self] _ in
      self?.clipboardEventSink?(nil)
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    if let pasteboardObserver {
      NotificationCenter.default.removeObserver(pasteboardObserver)
    }
    pasteboardObserver = nil
    clipboardEventSink = nil
    return nil
  }
}
