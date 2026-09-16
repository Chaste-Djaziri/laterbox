import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterStreamHandler {
  private let queue = ShareCaptureQueue(appGroupId: "group.pro.micorp.laterbox")
  private var shareChannel: FlutterMethodChannel?
  private var clipboardEventChannel: FlutterEventChannel?
  private var clipboardEventSink: FlutterEventSink?
  private var pasteboardObserver: NSObjectProtocol?
  private var appIconChannel: FlutterMethodChannel?
  private var liveActivityChannel: FlutterMethodChannel?

  private var darwinObserverRegistered = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    ensureChannelsRegistered()
    setupDarwinShareObserver()
    return result
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    ensureChannelsRegistered()
  }

  private func ensureChannelsRegistered() {
    let messenger: FlutterBinaryMessenger? = {
      if let controller = window?.rootViewController as? FlutterViewController {
        return controller.binaryMessenger
      }
      return registrar(forPlugin: "LaterBoxPlugin")?.messenger()
    }()
    guard let messenger else { return }
    registerShareChannel(with: messenger)
    registerClipboardChannel(with: messenger)
    registerAppIconChannel(with: messenger)
    registerLiveActivityChannel(with: messenger)
  }

  private func setupDarwinShareObserver() {
    guard !darwinObserverRegistered else { return }
    darwinObserverRegistered = true

    let observer = Unmanaged.passUnretained(self).toOpaque()
    CFNotificationCenterAddObserver(
      CFNotificationCenterGetDarwinNotifyCenter(),
      observer,
      { _, observer, _, _, _ in
        guard let observer = observer else { return }
        let appDelegate = Unmanaged<AppDelegate>.fromOpaque(observer).takeUnretainedValue()
        DispatchQueue.main.async {
          appDelegate.ensureChannelsRegistered()
          appDelegate.shareChannel?.invokeMethod("onNewShareAvailable", arguments: nil)
        }
      },
      ShareCaptureQueue.shareReceivedNotification as CFString,
      nil,
      .deliverImmediately
    )
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
      case "isAppGroupAvailable":
        result(self.queue.isAppGroupAvailable)
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

  private func registerLiveActivityChannel(with messenger: FlutterBinaryMessenger?) {
    guard let messenger, liveActivityChannel == nil else { return }
    let channel = FlutterMethodChannel(
      name: "pro.micorp.laterbox/live_activity",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      if #available(iOS 16.1, *) {
        switch call.method {
        case "isSupported":
          result(LiveActivityManager.shared.isSupported)
        case "start":
          guard let args = call.arguments as? [String: Any],
                let id = args["id"] as? String,
                let title = args["title"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing id or title", details: nil))
            return
          }
          let subtitle = args["subtitle"] as? String
          let returnSchedule = args["returnSchedule"] as? String
          let captureType = args["captureType"] as? String ?? "share"
          let isCompleted = args["isCompleted"] as? Bool ?? true
          let isError = args["isError"] as? Bool ?? false
          let autoDismiss = args["autoDismissSeconds"] as? Double ?? 3.5

          LiveActivityManager.shared.startActivity(
            id: id,
            title: title,
            subtitle: subtitle,
            returnSchedule: returnSchedule,
            captureType: captureType,
            isCompleted: isCompleted,
            isError: isError,
            autoDismissSeconds: autoDismiss
          )
          result(true)
        case "update":
          guard let args = call.arguments as? [String: Any],
                let id = args["id"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing id", details: nil))
            return
          }
          LiveActivityManager.shared.updateActivity(
            id: id,
            title: args["title"] as? String,
            subtitle: args["subtitle"] as? String,
            returnSchedule: args["returnSchedule"] as? String,
            isCompleted: args["isCompleted"] as? Bool,
            isError: args["isError"] as? Bool
          )
          result(true)
        case "end":
          guard let args = call.arguments as? [String: Any],
                let id = args["id"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing id", details: nil))
            return
          }
          LiveActivityManager.shared.endActivity(id: id)
          result(true)
        case "endAll":
          LiveActivityManager.shared.endAllActivities()
          result(true)
        default:
          result(FlutterMethodNotImplemented)
        }
      } else {
        if call.method == "isSupported" {
          result(false)
        } else {
          result(false)
        }
      }
    }
    self.liveActivityChannel = channel
  }
}
