//
//  LaterAIManager.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 05.10.26.
//

import SwiftUI
import Combine

@MainActor
public class LaterAIManager: ObservableObject {
    public static let shared = LaterAIManager()

    @Published public var isShowingLaterAI: Bool = false
    @Published public var flowProgress: CGFloat = 0.0

    private var hasTriggeredHaptic: Bool = false

    private init() {}

    /// Called by scrollviews when overscrolling at the very top of the page.
    /// `offset` is > 0 only when the page is at the top with no downward scroll remaining.
    public func handlePullDown(offset: CGFloat) {
        guard !isShowingLaterAI else { return }

        if offset <= 0 {
            hasTriggeredHaptic = false
            if flowProgress > 0 && flowProgress < 1.0 {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    flowProgress = 0.0
                }
            }
            return
        }

        // Real-time feather-flow animation proportional to top overscroll
        flowProgress = min(1.0, max(0.0, offset / 115.0))

        // Engagement threshold with tactile haptic response
        if offset >= 62 && !hasTriggeredHaptic {
            hasTriggeredHaptic = true
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.spring(response: 0.44, dampingFraction: 0.86)) {
                flowProgress = 1.0
                isShowingLaterAI = true
            }
        }
    }

    public func dismiss() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.44, dampingFraction: 0.86)) {
            flowProgress = 0.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
            self.isShowingLaterAI = false
            self.hasTriggeredHaptic = false
        }
    }
}

/// A ViewModifier applied to ScrollViews that measures overscroll at the very top of the page.
/// Normal downward scrolling midway through content will NEVER fire because overscroll is 0.
public struct LaterAIPullDownModifier: ViewModifier {
    @ObservedObject var aiManager = LaterAIManager.shared

    public init() {}

    public func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                // At rest at the top, contentOffset.y == -contentInsets.top.
                // Pulling down beyond the top edge produces a negative offset relative to insets.
                let topInset = geometry.contentInsets.top
                let overscroll = -topInset - geometry.contentOffset.y
                return max(0.0, overscroll)
            } action: { oldValue, overscroll in
                aiManager.handlePullDown(offset: overscroll)
            }
    }
}

extension View {
    public func trackPullDownForLaterAI() -> some View {
        self.modifier(LaterAIPullDownModifier())
    }
}
