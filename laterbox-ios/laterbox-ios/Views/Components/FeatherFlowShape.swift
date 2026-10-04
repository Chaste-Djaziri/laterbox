//
//  FeatherFlowShape.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 05.10.26.
//

import SwiftUI

/// A custom animatable drape shape where the center cascades down the furthest,
/// creating a fluid, feather-like dropdown veil rather than a flat horizontal line.
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
            path.addRect(rect)
            return path
        }

        // Side edges travel down to sideY
        let sideY = clamped * height
        // Center feather tip dips down further, tapering naturally as it approaches the bottom
        let dip = (1.0 - clamped) * (height * centerDipFraction)
        let centerTipY = min(height + 20, sideY + dip)

        // Bleed above screen to guarantee safe area coverage
        path.move(to: CGPoint(x: 0, y: -120))
        path.addLine(to: CGPoint(x: width, y: -120))
        path.addLine(to: CGPoint(x: width, y: sideY))

        // Organic curved bottom with center reaching furthest down
        path.addCurve(
            to: CGPoint(x: width / 2, y: centerTipY),
            control1: CGPoint(x: width * 0.82, y: sideY + (dip * 0.35)),
            control2: CGPoint(x: width * 0.62, y: centerTipY)
        )
        path.addCurve(
            to: CGPoint(x: 0, y: sideY),
            control1: CGPoint(x: width * 0.38, y: centerTipY),
            control2: CGPoint(x: width * 0.18, y: sideY + (dip * 0.35))
        )

        path.addLine(to: CGPoint(x: 0, y: -120))
        path.closeSubpath()
        return path
    }
}

/// Draws only the bottom curved edge of the falling feather drape for specular highlighting.
public struct FeatherFlowEdge: Shape {
    public var progress: CGFloat
    public var centerDipFraction: CGFloat = 0.28

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
        guard clamped > 0.01 && clamped < 0.999 else { return path }

        let width = rect.width
        let height = rect.height

        let sideY = clamped * height
        let dip = (1.0 - clamped) * (height * centerDipFraction)
        let centerTipY = min(height + 20, sideY + dip)

        path.move(to: CGPoint(x: 0, y: sideY))
        path.addCurve(
            to: CGPoint(x: width / 2, y: centerTipY),
            control1: CGPoint(x: width * 0.18, y: sideY + (dip * 0.35)),
            control2: CGPoint(x: width * 0.38, y: centerTipY)
        )
        path.addCurve(
            to: CGPoint(x: width, y: sideY),
            control1: CGPoint(x: width * 0.62, y: centerTipY),
            control2: CGPoint(x: width * 0.82, y: sideY + (dip * 0.35))
        )

        return path
    }
}
