// laterbox-ios/laterbox-ios/Views/Components/PullRefreshFeedback.swift
import SwiftUI
import UIKit

/// Shared scroll metrics for the main-tab pull-to-refresh logo animation.
enum LaterBoxPullRefresh {
    static let coordinateSpace = "laterbox-main-tab-refresh"
    static let triggerDistance: CGFloat = 105

    static func distance(_ offset: CGFloat) -> CGFloat {
        guard offset.isFinite else { return 0 }
        return min(max(0, offset), 180)
    }

    static func progress(_ offset: CGFloat) -> CGFloat {
        min(distance(offset) / triggerDistance, 1)
    }
}

struct LaterBoxPullOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// Place at the beginning of the scroll content, with the named coordinate space
/// on the *scroll view* (not the content). Tracks actual overscroll, not arbitrary drags.
struct LaterBoxPullRefreshMarker: View {
    var body: some View {
        GeometryReader { proxy in
            Color.clear.preference(
                key: LaterBoxPullOffsetKey.self,
                value: LaterBoxPullRefresh.distance(
                    proxy.frame(in: .named(LaterBoxPullRefresh.coordinateSpace)).minY
                )
            )
        }
        .frame(height: 1)
        .background(LaterBoxNativeRefreshIndicatorHider())
        .accessibilityHidden(true)
    }
}

/// Keep SwiftUI's native refresh gesture and async task cancellation semantics,
/// but hide its stock progress control: the fixed header logo is our indicator.
private struct LaterBoxNativeRefreshIndicatorHider: UIViewRepresentable {
    func makeUIView(context: Context) -> MarkerView {
        MarkerView()
    }

    func updateUIView(_ uiView: MarkerView, context: Context) {
        uiView.hideIndicator()
    }

    final class MarkerView: UIView {
        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .clear
            isUserInteractionEnabled = false
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) is not supported")
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            hideIndicator()
            // The refresh control can be attached after its content is mounted.
            DispatchQueue.main.async { [weak self] in self?.hideIndicator() }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            hideIndicator()
        }

        func hideIndicator() {
            var ancestor = superview
            while let view = ancestor {
                if let scrollView = view as? UIScrollView {
                    scrollView.refreshControl?.tintColor = .clear
                    scrollView.refreshControl?.alpha = 0
                    return
                }
                ancestor = view.superview
            }
        }
    }
}

/// The centered header mark stretches with a pull, animates while fetching,
/// and settles back into its normal 42-point size after the refresh ends.
struct LaterBoxPullRefreshLogo: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var spin = false

    var distance: CGFloat
    var refreshing: Bool
    var replayToken: Int = 0

    private var progress: CGFloat {
        LaterBoxPullRefresh.progress(distance)
    }

    var body: some View {
        LaterBoxVectorMark(
            size: 42,
            appearance: .light,
            animates: !refreshing,
            replayToken: replayToken
        )
        .scaleEffect(
            x: reduceMotion ? 1 : (refreshing ? 1.20 : 1 + progress * 0.16),
            y: reduceMotion ? 1 : (refreshing ? 1.20 : 1 + progress * 0.52)
        )
        .offset(y: reduceMotion ? 0 : (refreshing ? 4 : progress * 7))
        .rotationEffect(.degrees(spin && !reduceMotion ? 360 : 0))
        .animation(
            reduceMotion ? nil : .interactiveSpring(response: 0.3, dampingFraction: 0.76),
            value: progress
        )
        .animation(
            reduceMotion ? nil : .spring(response: 0.48, dampingFraction: 0.76),
            value: refreshing
        )
        .animation(
            refreshing && !reduceMotion
                ? .linear(duration: 1.15).repeatForever(autoreverses: false)
                : .spring(response: 0.48, dampingFraction: 0.79),
            value: spin
        )
        .onAppear { spin = refreshing }
        .onChange(of: refreshing) { _, newValue in spin = newValue }
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
        .accessibilityHidden(true)
    }
}
