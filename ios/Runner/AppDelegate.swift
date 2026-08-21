import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let queue = ShareCaptureQueue(appGroupId: "group.pro.micorp.laterbox")

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "laterbox/apple_share",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "consumePending":
        result(self.queue?.readAll().map(\.toDictionary) ?? [])
      case "clearPending":
        self.queue?.clear()
        result(nil)
      case "acknowledgePending":
        let arguments = call.arguments as? [String: Any]
        let ids = Set(arguments?["ids"] as? [String] ?? [])
        result(self.queue?.acknowledge(ids: ids) ?? false)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
