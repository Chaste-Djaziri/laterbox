//
//  StatusBarStyleModifier.swift
//  laterbox-ios
//

import SwiftUI
import UIKit

struct StatusBarStyleModifier: ViewModifier {
    let style: UIUserInterfaceStyle

    func body(content: Content) -> some View {
        content
            .preferredColorScheme(style == .dark ? .dark : .light)
            .onAppear {
                Self.apply(style)
            }
    }

    static func apply(_ style: UIUserInterfaceStyle) {
        let action = {
            let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            for scene in scenes {
                for window in scene.windows {
                    window.overrideUserInterfaceStyle = style
                    window.rootViewController?.setNeedsStatusBarAppearanceUpdate()
                    window.rootViewController?.presentedViewController?.setNeedsStatusBarAppearanceUpdate()
                    if let nav = window.rootViewController as? UINavigationController {
                        nav.topViewController?.setNeedsStatusBarAppearanceUpdate()
                    }
                }
            }
        }

        if Thread.isMainThread {
            action()
        } else {
            DispatchQueue.main.async(execute: action)
        }
    }
}

extension View {
    /// Forces the system status bar (time, battery, Wi-Fi) to render in pure white.
    func whiteStatusBar() -> some View {
        self.modifier(StatusBarStyleModifier(style: .dark))
    }

    /// Sets the system status bar to dark (standard light mode).
    func darkStatusBar() -> some View {
        self.modifier(StatusBarStyleModifier(style: .light))
    }
}
