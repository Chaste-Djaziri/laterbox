import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let queue = ShareCaptureQueue(appGroupId: "group.pro.micorp.laterbox")
  private var shareChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      registerShareChannel(with: controller.binaryMessenger)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerShareChannel(with: engineBridge.applicationRegistrar.messenger())
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
}
