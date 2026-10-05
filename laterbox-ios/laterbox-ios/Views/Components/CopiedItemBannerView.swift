//
//  CopiedItemBannerView.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 05.10.26.
//

import SwiftUI

public struct CopiedItemBannerView: View {
    public let item: CopiedItemPayload
    @ObservedObject private var manager = ClipboardDetectionManager.shared
    @State private var dragOffsetY: CGFloat = 0

    public init(item: CopiedItemPayload) {
        self.item = item
    }

    public var body: some View {
        HStack(spacing: 12) {
            // Icon Pill
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.10))
                    .frame(width: 42, height: 42)

                Image(systemName: item.systemIcon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppTheme.accent)
            }

            // Text Info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(item.isURL ? "COPIED LINK DETECTED" : "COPIED TEXT DETECTED")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppTheme.accent)
                        .tracking(0.6)

                    Image(systemName: "sparkles")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(AppTheme.accent)
                }

                Text(item.titlePreview)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(item.snippetPreview)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color.white.opacity(0.60))
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            // Save Action Pill
            Button(action: {
                manager.confirmSave()
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .bold))
                    Text("Save")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(AppTheme.accent, in: Capsule())
                .shadow(color: AppTheme.accent.opacity(0.25), radius: 6, y: 2)
            }
            .buttonStyle(.plain)

            // Dismiss Button
            Button(action: {
                manager.dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.50))
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.08), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(hex: "18181A").opacity(0.94))
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.40), radius: 20, x: 0, y: 8)
        .offset(y: min(0, dragOffsetY))
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height < 0 {
                        dragOffsetY = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height < -25 || value.predictedEndTranslation.height < -40 {
                        manager.dismiss()
                    } else {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            dragOffsetY = 0
                        }
                    }
                }
        )
        .onTapGesture {
            manager.confirmSave()
        }
    }
}
