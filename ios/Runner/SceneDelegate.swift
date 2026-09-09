import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UISceneConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    connectShareChannel(for: scene)
  }

  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    connectShareChannel(for: scene)
  }

  private func connectShareChannel(for scene: UIScene) {
    guard let windowScene = scene as? UIWindowScene else { return }
    let controller = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController as? FlutterViewController
      ?? windowScene.windows.first?.rootViewController as? FlutterViewController
    if let controller {
      (UIApplication.shared.delegate as? AppDelegate)?.registerShareChannel(with: controller.binaryMessenger)
    }
  }
}
