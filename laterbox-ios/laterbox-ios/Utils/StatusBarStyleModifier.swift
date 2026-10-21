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
                    if let root = window.rootViewController {
                        updateVC(root, style: style)
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

    private static func updateVC(_ vc: UIViewController, style: UIUserInterfaceStyle) {
        vc.overrideUserInterfaceStyle = style
        vc.setNeedsStatusBarAppearanceUpdate()
        for child in vc.children {
            updateVC(child, style: style)
        }
        if let presented = vc.presentedViewController {
            updateVC(presented, style: style)
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
