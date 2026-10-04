//
//  SummaryMetricCard.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 04.10.26.
//

import SwiftUI

public enum MetricCardTheme {
    case green  // Signature app green (#E6EDB0) with black icons and black text
    case black  // Solid black (#181818) with white icons and white text
}

public struct SummaryMetricCard: View {
    public let title: String
    public let count: Int
    public let icon: String
    public let theme: MetricCardTheme

    public init(
        title: String,
        count: Int,
        icon: String,
        theme: MetricCardTheme = .green
    ) {
        self.title = title
        self.count = count
        self.icon = icon
        self.theme = theme
    }

    private var backgroundColor: Color {
        switch theme {
        case .green:
            return Color.lbGreenTheme
        case .black:
            return Color(red: 24/255, green: 24/255, blue: 24/255)
        }
    }

    private var foregroundColor: Color {
        switch theme {
        case .green:
            return .black
        case .black:
            return .white
        }
    }

    private var subtitleColor: Color {
        switch theme {
        case .green:
            return Color.black.opacity(0.72)
        case .black:
            return Color.white.opacity(0.75)
        }
    }

    private var iconBadgeBackground: Color {
        switch theme {
        case .green:
            return Color.black.opacity(0.08)
        case .black:
            return Color.white.opacity(0.14)
        }
    }

    private var borderColor: Color {
        switch theme {
        case .green:
            return Color.black.opacity(0.08)
        case .black:
            return Color.white.opacity(0.12)
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                ZStack {
                    Circle()
                        .fill(iconBadgeBackground)
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(foregroundColor)
                }
                Spacer()
                Text("\(count)")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(foregroundColor)
            }

            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundColor(subtitleColor)
                .lineLimit(1)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(borderColor, lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(theme == .black ? 0.12 : 0.04),
            radius: 8,
            x: 0,
            y: 3
        )
    }
}
