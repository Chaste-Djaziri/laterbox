//
//  FeatherFlowShape.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 05.10.26.
//

import SwiftUI

/// An animatable drape shape where the center cascades down the furthest.
/// Extends slightly beyond horizontal boundaries so that when blurred, only the bottom edge fades.
public struct FeatherFlowShape: Shape {
    public var progress: CGFloat // 0.0 (retracted at top) to 1.0 (fills screen)
    public var centerDipFraction: CGFloat = 0.28 // Center dip depth ratio

    public var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    public init(progress: CGFloat, centerDipFraction: CGFloat = 0.28) {
        self.progress = progress
        self.centerDipFraction = centerDipFraction
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let clamped = max(0.0, min(1.0, progress))
        guard clamped > 0.001 else { return path }

        let width = rect.width
        let height = rect.height

        if clamped >= 0.999 {
            path.addRect(CGRect(x: -30, y: -120, width: width + 60, height: height + 160))
            return path
        }

        // Side edges travel down to sideY
        let sideY = clamped * height
        // Center feather tip dips down further, tapering naturally as it approaches the bottom
        let dip = (1.0 - clamped) * (height * centerDipFraction)
        let centerTipY = min(height + 40, sideY + dip)

        // Bleed 30pt left/right/top so blur only softens the bottom contour
        let bleed: CGFloat = 30
        path.move(to: CGPoint(x: -bleed, y: -120))
        path.addLine(to: CGPoint(x: width + bleed, y: -120))
        path.addLine(to: CGPoint(x: width + bleed, y: sideY))

        // Organic curved bottom with center reaching furthest down
        path.addCurve(
            to: CGPoint(x: width / 2, y: centerTipY),
            control1: CGPoint(x: width * 0.82 + bleed, y: sideY + (dip * 0.35)),
            control2: CGPoint(x: width * 0.62, y: centerTipY)
        )
        path.addCurve(
            to: CGPoint(x: -bleed, y: sideY),
            control1: CGPoint(x: width * 0.38, y: centerTipY),
            control2: CGPoint(x: width * 0.18 - bleed, y: sideY + (dip * 0.35))
        )

        path.addLine(to: CGPoint(x: -bleed, y: -120))
        path.closeSubpath()
        return path
    }
}

/// Renders a multi-layered, feathered fading black curtain with no hard edges or stroked lines.
/// Center plunges down furthest like a soft feather falling down, softly dissolving into transparency.
public struct FeatherFadingBackdrop: View {
    public var progress: CGFloat

    public init(progress: CGFloat) {
        self.progress = progress
    }

    public var body: some View {
        let p = max(0.0, min(1.0, progress))
        let isOpening = p < 0.99

        ZStack {
            // Outermost soft ambient feather plume (widest fade)
            FeatherFlowShape(progress: p, centerDipFraction: 0.42)
                .fill(Color.black.opacity(0.30))
                .blur(radius: isOpening ? 52 : 0)

            // Mid feather plume
            FeatherFlowShape(progress: p, centerDipFraction: 0.35)
                .fill(Color.black.opacity(0.55))
                .blur(radius: isOpening ? 32 : 0)

            // Inner dense feather body
            FeatherFlowShape(progress: p, centerDipFraction: 0.29)
                .fill(Color.black.opacity(0.85))
                .blur(radius: isOpening ? 16 : 0)

            // Core solid black drape
            FeatherFlowShape(progress: p, centerDipFraction: 0.25)
                .fill(Color.black)
                .blur(radius: isOpening ? 6 : 0)
        }
        .clipped()
        .ignoresSafeArea()
    }
}
