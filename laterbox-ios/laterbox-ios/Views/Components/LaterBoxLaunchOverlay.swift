// laterbox-ios/laterbox-ios/Views/Components/LaterBoxLaunchOverlay.swift
import SwiftUI

/// Brief animated continuation of the system's static launch storyboard.
/// Uses the same three vector paths as the Inbox header logo.
struct LaterBoxLaunchOverlay: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let onFinished: () -> Void

    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color(hex: "1B1D20") : Color.white)
                .ignoresSafeArea()

            LaterBoxVectorMark(
                size: 115,
                appearance: .automatic,
                animates: true,
                showsPiecesBeforeAssembly: true,
                floatsLid: false
            )
            .frame(width: 146, height: 146)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Launching LaterBox")
        .task {
            // The logo only assembles once; no idle float or prolonged splash.
            do {
                try await Task.sleep(for: .milliseconds(reduceMotion ? 180 : 860))
            } catch {
                return
            }
            onFinished()
        }
    }
}
