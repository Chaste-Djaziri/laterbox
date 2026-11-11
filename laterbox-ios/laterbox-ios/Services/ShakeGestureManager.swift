//
//  ShakeGestureManager.swift
//  laterbox-ios
//
//  Detects device shake motion across any active screen to trigger
//  error diagnosis and bug reporting.
//

import UIKit
import SwiftUI

extension Notification.Name {
    public static let deviceDidShakeNotification = Notification.Name("LBDeviceDidShakeNotification")
}

public final class ShakeGestureManager: ObservableObject {
    public static let shared = ShakeGestureManager()

    public static let shakeEnabledKey = "LBShakeToReportEnabled"

    @Published public var isShakeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isShakeEnabled, forKey: Self.shakeEnabledKey)
        }
    }

    private init() {
        if UserDefaults.standard.object(forKey: Self.shakeEnabledKey) != nil {
            self.isShakeEnabled = UserDefaults.standard.bool(forKey: Self.shakeEnabledKey)
        } else {
            self.isShakeEnabled = true
        }
        Self.swizzleWindowMotionEndedIfNeeded()
    }

    public func triggerShake() {
        guard isShakeEnabled else { return }
        NotificationCenter.default.post(name: .deviceDidShakeNotification, object: nil)
    }

    private static var hasSwizzled = false

    public static func swizzleWindowMotionEndedIfNeeded() {
        guard !hasSwizzled else { return }
        hasSwizzled = true

        let originalSelector = #selector(UIResponder.motionEnded(_:with:))
        let swizzledSelector = #selector(UIWindow.lb_motionEnded(_:with:))

        guard let swizzledMethod = class_getInstanceMethod(UIWindow.self, swizzledSelector) else {
            return
        }

        if let originalMethod = class_getInstanceMethod(UIWindow.self, originalSelector) {
            let didAddMethod = class_addMethod(
                UIWindow.self,
                originalSelector,
                method_getImplementation(swizzledMethod),
                method_getTypeEncoding(swizzledMethod)
            )

            if didAddMethod {
                class_replaceMethod(
                    UIWindow.self,
                    swizzledSelector,
                    method_getImplementation(originalMethod),
                    method_getTypeEncoding(originalMethod)
                )
            } else {
                method_exchangeImplementations(originalMethod, swizzledMethod)
            }
        }
    }
}

extension UIWindow {
    @objc func lb_motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        lb_motionEnded(motion, with: event)

        if motion == .motionShake {
            if ShakeGestureManager.shared.isShakeEnabled {
                NotificationCenter.default.post(name: .deviceDidShakeNotification, object: nil)
            }
        }
    }
}
