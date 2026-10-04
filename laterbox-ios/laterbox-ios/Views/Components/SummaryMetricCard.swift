//
//  SummaryMetricCard.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 04.10.26.
//

import SwiftUI

public struct SummaryMetricCard: View {
    public let title: String
    public let count: Int
    public let icon: String
    public let color: Color

    public init(title: String, count: Int, icon: String, color: Color = Color.lbAmber) {
        self.title = title
        self.count = count
        self.icon = icon
        self.color = color
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.18))
                        .frame(width: 34, height: 34)
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(color)
                }
                Spacer()
                Text("\(count)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
        }
        .padding(14)
        .liquidGlassCard(cornerRadius: 16, borderOpacity: 0.18)
    }
}
