import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, FlutterStreamHandler {
  private let queue = ShareCaptureQueue(appGroupId: "group.pro.micorp.laterbox")
  private var shareChannel: FlutterMethodChannel?
  private var clipboardEventChannel: FlutterEventChannel?
  private var clipboardEventSink: FlutterEventSink?
  private var pasteboardObserver: NSObjectProtocol?
  private var appIconChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    if let controller = window?.rootViewController as? FlutterViewController {
      registerAppIconChannel(with: controller.binaryMessenger)
    }
    return result
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerShareChannel(with: engineBridge.applicationRegistrar.messenger())
    registerClipboardChannel(with: engineBridge.applicationRegistrar.messenger())
    registerAppIconChannel(with: engineBridge.applicationRegistrar.messenger())
  }

  private func registerAppIconChannel(with messenger: FlutterBinaryMessenger?) {
    guard let messenger = messenger, appIconChannel == nil else { return }
    let channel = FlutterMethodChannel(
      name: "laterbox/app_icon",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "supportsAlternateIcons":
        DispatchQueue.main.async {
          result(UIApplication.shared.supportsAlternateIcons)
        }
      case "getAlternateIconName":
        DispatchQueue.main.async {
          result(UIApplication.shared.alternateIconName)
        }
      case "setAlternateIconName":
        let arguments = call.arguments as? [String: Any]
        let iconName = arguments?["iconName"] as? String
        DispatchQueue.main.async {
          guard UIApplication.shared.supportsAlternateIcons else {
            result(FlutterError(code: "UNSUPPORTED", message: "Alternate icons not supported on this device", details: nil))
            return
          }
          UIApplication.shared.setAlternateIconName(iconName) { error in
            DispatchQueue.main.async {
              if let error = error {
                result(FlutterError(code: "SET_FAILED", message: error.localizedDescription, details: nil))
              } else {
                result(true)
              }
            }
          }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    self.appIconChannel = channel
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
