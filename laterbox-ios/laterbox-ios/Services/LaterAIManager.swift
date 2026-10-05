//
//  LaterAIManager.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 05.10.26.
//

import SwiftUI
import Combine

public struct ScrollOffsetData: Equatable {
    public let offsetY: CGFloat
    public let topInset: CGFloat

    public init(offsetY: CGFloat, topInset: CGFloat) {
        self.offsetY = offsetY
        self.topInset = topInset
    }
}

@MainActor
public class LaterAIManager: ObservableObject {
    public static let shared = LaterAIManager()

    @Published public var isShowingLaterAI: Bool = false
    @Published public var flowProgress: CGFloat = 0.0
    @Published public var initialPrompt: String? = nil
    @Published public var attachedSubject: String? = nil

    // Tracks if the user was scrolled down into content
    private var wasScrolledDown: Bool = false
    // Requires being settled at the top before arming for a downward pull
    private var isArmedAtTop: Bool = false
    private var hasTriggeredHaptic: Bool = false

    private init() {}

    /// Programmatically open Later AI, optionally pre-populating or sending content as an attached subject to save.
    public func open(with content: String? = nil, autoSend: Bool = true) {
        if let content = content?.trimmingCharacters(in: .whitespacesAndNewlines), !content.isEmpty {
            self.attachedSubject = content
            if autoSend {
                let prompt = CaptureDraft.detectURL(content) != nil ? content : "Save: \(content)"
                self.initialPrompt = prompt
            }
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(response: 0.44, dampingFraction: 0.86)) {
            self.flowProgress = 1.0
            self.isShowingLaterAI = true
        }
    }

    /// Called by scrollviews via onScrollGeometryChange.
    /// `contentOffsetY`: current contentOffset.y
    /// `topInset`: geometry.contentInsets.top
    public func handleScrollUpdate(contentOffsetY: CGFloat, topInset: CGFloat) {
        let overscroll = -topInset - contentOffsetY
        let isScrolledDown = contentOffsetY > (-topInset + 10)

        if isScrolledDown {
            // User is scrolling through content below the top
            wasScrolledDown = true
            isArmedAtTop = false
            hasTriggeredHaptic = false
            if !isShowingLaterAI && flowProgress > 0 {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.88)) {
                    flowProgress = 0.0
                }
            }
            return
        }

        // Resting at the top bounds (within 3pt of rest)
        let isAtRestAtTop = abs(overscroll) < 3.0

        if wasScrolledDown {
            // User just arrived at the top from scrolling up!
            // Do NOT trigger Later AI on this initial arrival momentum/drag.
            if isAtRestAtTop {
                // Now they have settled at the top of the page!
                wasScrolledDown = false
                isArmedAtTop = true
            }
            return
        }

        // If resting at top, arm for a fresh, forceful downward pull
        if isAtRestAtTop {
            isArmedAtTop = true
            hasTriggeredHaptic = false
            if !isShowingLaterAI && flowProgress > 0 {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.88)) {
                    flowProgress = 0.0
                }
            }
            return
        }

        // Must be armed at top and not already showing
        guard isArmedAtTop, !isShowingLaterAI else { return }

        guard overscroll > 0 else { return }

        // Apply a 14pt deadband so slight jitter does not move the curtain
        let effectivePull = max(0.0, overscroll - 14.0)
        flowProgress = min(1.0, max(0.0, effectivePull / 95.0))

        // Forceful pull engagement threshold: 78 pt
        if overscroll >= 78 && !hasTriggeredHaptic {
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
            self.wasScrolledDown = false
            self.isArmedAtTop = true
            self.attachedSubject = nil
            self.initialPrompt = nil
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
            .onScrollGeometryChange(for: ScrollOffsetData.self) { geometry in
                ScrollOffsetData(
                    offsetY: geometry.contentOffset.y,
                    topInset: geometry.contentInsets.top
                )
            } action: { oldValue, newValue in
                aiManager.handleScrollUpdate(
                    contentOffsetY: newValue.offsetY,
                    topInset: newValue.topInset
                )
            }
    }
}

extension View {
    public func trackPullDownForLaterAI() -> some View {
        self.modifier(LaterAIPullDownModifier())
    }
}
