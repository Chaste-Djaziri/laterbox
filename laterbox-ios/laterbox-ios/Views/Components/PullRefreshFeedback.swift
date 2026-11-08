// laterbox-ios/laterbox-ios/Views/Components/PullRefreshFeedback.swift
import SwiftUI
import UIKit

/// Scroll-driven progress for the fixed LaterBox header logo.
enum LaterBoxPullRefresh {
    static let triggerDistance: CGFloat = 100
    static let minimumVisibleSeconds: TimeInterval = 1.15

    static func distance(_ offset: CGFloat) -> CGFloat {
        guard offset.isFinite else { return 0 }
        return min(max(0, offset), 180)
    }

    /// UIScrollView rests at -adjustedContentInset.top, not necessarily zero.
    /// This prevents the logo stretching when the list is merely at the top.
    static func overscroll(contentOffsetY: CGFloat, adjustedTopInset: CGFloat) -> CGFloat {
        distance(-(contentOffsetY + adjustedTopInset))
    }

    static func progress(_ offset: CGFloat) -> CGFloat {
        min(distance(offset) / triggerDistance, 1)
    }

    /// Short local/offline syncs should still display an observable animation.
    @MainActor
    static func holdVisible(since start: Date) async {
        let remaining = minimumVisibleSeconds - Date().timeIntervalSince(start)
        guard remaining > 0 else { return }
        try? await Task.sleep(for: .seconds(remaining))
    }
}

/// Embedded within a ScrollView's first content row. Unlike GeometryReader
/// preferences, UIScrollView.contentOffset reports overscroll while UIKit's
/// native refresh control owns the pull gesture, including on short lists.
struct LaterBoxPullRefreshMarker: UIViewRepresentable {
    @Binding var distance: CGFloat
    var enabled = true

    func makeUIView(context: Context) -> ScrollProbe {
        ScrollProbe()
    }

    func updateUIView(_ uiView: ScrollProbe, context: Context) {
        let currentDistance = $distance
        uiView.enabled = enabled
        uiView.onDistanceChange = { value in
            if abs(currentDistance.wrappedValue - value) >= 0.75 {
                currentDistance.wrappedValue = value
            }
        }
        uiView.attachToScrollView()
    }

    final class ScrollProbe: UIView {
        var enabled = true
        var onDistanceChange: ((CGFloat) -> Void)?
        private weak var scrollView: UIScrollView?
        private var offsetObservation: NSKeyValueObservation?
        private var lastReported: CGFloat = -1

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
            attachToScrollView()
            // SwiftUI sometimes attaches the scroll container after its child.
            DispatchQueue.main.async { [weak self] in
                self?.attachToScrollView()
            }
        }

        override func didMoveToSuperview() {
            super.didMoveToSuperview()
            attachToScrollView()
        }

        func attachToScrollView() {
            var ancestor = superview
            var found: UIScrollView?
            while let current = ancestor {
                if let candidate = current as? UIScrollView {
                    found = candidate
                    break
                }
                ancestor = current.superview
            }
            guard let found else { return }

            if scrollView !== found {
                offsetObservation?.invalidate()
                scrollView = found
                lastReported = -1

                offsetObservation = found.observe(\.contentOffset, options: [.initial, .new]) {
                    [weak self] _, _ in
                    DispatchQueue.main.async { [weak self] in self?.reportPullDistance() }
                }
            }

            // Preserve native refresh triggering but remove its stock spinner.
            if let control = found.refreshControl {
                control.tintColor = .clear
                control.alpha = 0
            }
            reportPullDistance()
        }

        private func reportPullDistance() {
            guard let scrollView else { return }
            let value = enabled && scrollView.isDragging
                ? LaterBoxPullRefresh.overscroll(
                    contentOffsetY: scrollView.contentOffset.y,
                    adjustedTopInset: scrollView.adjustedContentInset.top
                )
                : 0
            guard abs(value - lastReported) >= 0.75 else { return }
            lastReported = value
            // Never write a SwiftUI Binding inside the UIViewRepresentable update cycle.
            DispatchQueue.main.async { [weak self] in self?.onDistanceChange?(value) }
        }

        deinit {
            offsetObservation?.invalidate()
        }
    }
}

/// The same vector logo stretches while pulling, spins during real sync,
/// and springs back when the async refresh completes.
struct LaterBoxPullRefreshLogo: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var spinAngle: Double = 0

    var distance: CGFloat
    var refreshing: Bool
    var replayToken = 0

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
            x: reduceMotion ? 1 : (refreshing ? 1.3 : 1 + progress * 0.22),
            y: reduceMotion ? 1 : (refreshing ? 1.3 : 1 + progress * 0.52)
        )
        .offset(y: reduceMotion ? 0 : (refreshing ? 5 : progress * 7))
        .rotationEffect(.degrees(spinAngle))
        .animation(
            reduceMotion ? nil : .interactiveSpring(response: 0.3, dampingFraction: 0.76),
            value: progress
        )
        .animation(
            reduceMotion ? nil : .spring(response: 0.48, dampingFraction: 0.76),
            value: refreshing
        )
        .onAppear { updateSpin(refreshing) }
        .onChange(of: refreshing) { _, active in updateSpin(active) }
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
        .accessibilityHidden(true)
    }

    private func updateSpin(_ active: Bool) {
        if active && !reduceMotion {
            spinAngle = 0
            withAnimation(.linear(duration: 1.05).repeatForever(autoreverses: false)) {
                spinAngle = 360
            }
        } else {
            withAnimation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.82)) {
                spinAngle = 0
            }
        }
    }
}
