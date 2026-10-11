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

    /// Pull down trigger disabled per user requirements.
    public func handleScrollUpdate(contentOffsetY: CGFloat, topInset: CGFloat) {
        // No-op: scroll-down pull trigger removed
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

/// A ViewModifier applied to ScrollViews (no-op since pull down trigger is removed).
public struct LaterAIPullDownModifier: ViewModifier {
    public init() {}

    public func body(content: Content) -> some View {
        content
    }
}

extension View {
    public func trackPullDownForLaterAI() -> some View {
        self
    }
}
