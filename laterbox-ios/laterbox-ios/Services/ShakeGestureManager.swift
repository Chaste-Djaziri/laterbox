//
//  ShakeGestureManager.swift
//  laterbox-ios
//
//  Detects device shake motion across any active screen to trigger
//  error diagnosis and bug reporting.
//

import UIKit
import SwiftUI
import Combine

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
    }

    private var lastShakeTime: TimeInterval = 0

    public func triggerShake() {
        guard isShakeEnabled else { return }
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastShakeTime > 0.8 else { return }
        lastShakeTime = now
        NotificationCenter.default.post(name: .deviceDidShakeNotification, object: nil)
    }
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)

        if motion == .motionShake {
            ShakeGestureManager.shared.triggerShake()
        }
    }
}

