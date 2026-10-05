import UIKit
import UserNotifications
import Combine

@MainActor final class ReturnNotificationRouter: ObservableObject {
    static let shared = ReturnNotificationRouter()
    @Published var itemID: String?
}
final class ReturnNotificationDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        var id = response.notification.request.content.userInfo["itemID"] as? String
        if id == nil || id?.isEmpty == true {
            let identifier = response.notification.request.identifier
            if identifier.hasPrefix("returned-") {
                id = identifier.replacingOccurrences(of: "returned-", with: "")
            } else if !identifier.hasPrefix("laterbox-test-") {
                id = identifier
            }
        }
        if let id, !id.isEmpty {
            Task { @MainActor in
                ReturnNotificationRouter.shared.itemID = id
            }
        }
        completionHandler()
    }
}
