//
//  RichMediaBanner.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 04.10.26.
//

import SwiftUI

public struct RichMediaBanner: View {
    public let type: ItemContentType
    public let url: String?
    public let title: String
    public let previewImageUrl: String?

    public init(type: ItemContentType, url: String? = nil, title: String = "", previewImageUrl: String? = nil) {
        self.type = type
        self.url = url
        self.title = title
        self.previewImageUrl = previewImageUrl
    }

    public var body: some View {
        ZStack {
            switch type {
            case .music:
                LinearGradient(
                    colors: [Color(red: 30/255, green: 215/255, blue: 96/255).opacity(0.85), Color.black.opacity(0.9)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 52, height: 52)
                        Image(systemName: "music.note")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Spotify / Apple Music")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.white.opacity(0.75))
                            .textCase(.uppercase)
                        Text(title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    Spacer()
                    Circle()
                        .fill(Color.white)
                        .frame(width: 36, height: 36)
                        .overlay(Image(systemName: "play.fill").font(.caption).foregroundColor(.black).offset(x: 1))
                }
                .padding(.horizontal, 16)

            case .video:
                LinearGradient(
                    colors: [Color(red: 255/255, green: 0/255, blue: 0/255).opacity(0.8), Color(red: 20/255, green: 20/255, blue: 24/255)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                HStack(spacing: 12) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Video Stream")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.white.opacity(0.7))
                        Text(title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    Spacer()
                    Text("Watch")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(.ultraThinMaterial))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)

            case .article:
                LinearGradient(
                    colors: [Color(red: 79/255, green: 70/255, blue: 229/255).opacity(0.7), Color(red: 15/255, green: 23/255, blue: 42/255)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                HStack(spacing: 12) {
                    Image(systemName: "doc.plaintext.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.white.opacity(0.9))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Longform Article")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.white.opacity(0.7))
                        Text(title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "book.pages")
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 16)

            case .note:
                LinearGradient(
                    colors: [Color.lbAmber.opacity(0.75), Color.lbAmberDark.opacity(0.9)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                HStack(spacing: 12) {
                    Image(systemName: "pencil.and.scribble")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Personal Note")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.white.opacity(0.75))
                        Text(title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)

            case .document, .image, .file:
                LinearGradient(
                    colors: [Color(red: 225/255, green: 29/255, blue: 72/255).opacity(0.75), Color(red: 24/255, green: 24/255, blue: 27/255)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                HStack(spacing: 12) {
                    Image(systemName: type.systemIcon)
                        .font(.system(size: 26))
                        .foregroundColor(.white)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(type.rawValue.capitalized)
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.white.opacity(0.75))
                        Text(title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)

            case .link:
                LinearGradient(
                    colors: [Color.lbAmber.opacity(0.35), Color.black.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                HStack(spacing: 12) {
                    Image(systemName: "globe")
                        .font(.system(size: 24))
                        .foregroundColor(Color.lbAmber)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Web Resource")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.white.opacity(0.7))
                        Text(title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 16)
            }
        }
        .frame(height: 72)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
