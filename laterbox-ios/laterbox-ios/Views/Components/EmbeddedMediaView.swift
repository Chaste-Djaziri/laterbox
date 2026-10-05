//
//  EmbeddedMediaView.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 05.10.26.
//

import SwiftUI
import WebKit
import SafariServices
import PDFKit
import QuickLook

// MARK: - Embed Type Detector

public enum EmbeddedMediaType: Equatable {
    case youtube(videoId: String)
    case vimeo(videoId: String)
    case spotify(embedURL: URL)
    case appleMusic(embedURL: URL)
    case pdf(url: URL)
    case webArticle(url: URL)
    case none

    public static func detect(url: String?) -> EmbeddedMediaType {
        guard let urlString = url?.trimmingCharacters(in: .whitespacesAndNewlines),
              let parsedURL = URL(string: urlString),
              let host = parsedURL.host?.lowercased() else {
            return .none
        }

        // Direct PDF
        if parsedURL.pathExtension.lowercased() == "pdf" {
            return .pdf(url: parsedURL)
        }

        // YouTube
        if host.contains("youtube.com") || host.contains("youtu.be") {
            if let videoId = extractYouTubeId(from: parsedURL) {
                return .youtube(videoId: videoId)
            }
        }

        // Vimeo
        if host.contains("vimeo.com") {
            if let videoId = extractVimeoId(from: parsedURL) {
                return .vimeo(videoId: videoId)
            }
        }

        // Spotify
        if host.contains("spotify.com") {
            if let embedURL = convertSpotifyEmbedURL(from: parsedURL) {
                return .spotify(embedURL: embedURL)
            }
        }

        // Apple Music
        if host.contains("music.apple.com") {
            if let embedURL = convertAppleMusicEmbedURL(from: parsedURL) {
                return .appleMusic(embedURL: embedURL)
            }
        }

        if parsedURL.scheme == "http" || parsedURL.scheme == "https" {
            return .webArticle(url: parsedURL)
        }

        return .none
    }

    private static func extractYouTubeId(from url: URL) -> String? {
        if let host = url.host?.lowercased(), host.contains("youtu.be") {
            let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return path.isEmpty ? nil : path
        }
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            if let queryItems = components.queryItems,
               let vItem = queryItems.first(where: { $0.name == "v" })?.value, !vItem.isEmpty {
                return vItem
            }
            // Check /shorts/ID or /embed/ID
            let parts = components.path.split(separator: "/")
            if let shortsIdx = parts.firstIndex(of: "shorts"), shortsIdx + 1 < parts.count {
                return String(parts[shortsIdx + 1])
            }
            if let embedIdx = parts.firstIndex(of: "embed"), embedIdx + 1 < parts.count {
                return String(parts[embedIdx + 1])
            }
        }
        return nil
    }

    private static func extractVimeoId(from url: URL) -> String? {
        let parts = url.path.split(separator: "/")
        if let last = parts.last, CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: String(last))) {
            return String(last)
        }
        return nil
    }

    private static func convertSpotifyEmbedURL(from url: URL) -> URL? {
        // e.g. https://open.spotify.com/track/ID -> https://open.spotify.com/embed/track/ID
        let path = url.path
        if path.hasPrefix("/embed/") { return url }
        if path.hasPrefix("/track/") || path.hasPrefix("/album/") || path.hasPrefix("/playlist/") || path.hasPrefix("/episode/") {
            var comp = URLComponents(url: url, resolvingAgainstBaseURL: false)
            comp?.path = "/embed" + path
            comp?.queryItems = [URLQueryItem(name: "utm_source", value: "generator"), URLQueryItem(name: "theme", value: "0")]
            return comp?.url
        }
        return nil
    }

    private static func convertAppleMusicEmbedURL(from url: URL) -> URL? {
        // e.g. https://music.apple.com/us/album/... -> https://embed.music.apple.com/us/album/...
        var comp = URLComponents(url: url, resolvingAgainstBaseURL: false)
        comp?.host = "embed.music.apple.com"
        return comp?.url
    }
}

// MARK: - Inline Video Embed View

public struct InlineVideoEmbedView: View {
    public let embedType: EmbeddedMediaType
    @State private var isPlaying = false

    public init(embedType: EmbeddedMediaType) {
        self.embedType = embedType
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                switch embedType {
                case .youtube(let id):
                    if let embedURL = URL(string: "https://www.youtube-nocookie.com/embed/\(id)?playsinline=1&modestbranding=1&rel=0&autoplay=1") {
                        if isPlaying {
                            WebViewEmbed(url: embedURL)
                                .frame(height: 220)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        } else {
                            videoPoster(title: "YouTube Video", systemIcon: "play.rectangle.fill", color: Color.red)
                        }
                    }
                case .vimeo(let id):
                    if let embedURL = URL(string: "https://player.vimeo.com/video/\(id)?playsinline=1&autoplay=1") {
                        if isPlaying {
                            WebViewEmbed(url: embedURL)
                                .frame(height: 220)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        } else {
                            videoPoster(title: "Vimeo Video", systemIcon: "play.circle.fill", color: Color.blue)
                        }
                    }
                case .spotify(let embedURL):
                    WebViewEmbed(url: embedURL)
                        .frame(height: 152)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                case .appleMusic(let embedURL):
                    WebViewEmbed(url: embedURL)
                        .frame(height: 175)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                default:
                    EmptyView()
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
            )
        }
    }

    private func videoPoster(title: String, systemIcon: String, color: Color) -> some View {
        Button(action: {
            LBHaptic.medium()
            isPlaying = true
        }) {
            ZStack {
                Color.black.opacity(0.85)

                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.9))
                            .frame(width: 58, height: 58)
                            .shadow(color: color.opacity(0.5), radius: 10, y: 3)
                        Image(systemName: "play.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .offset(x: 2)
                    }

                    Text("Tap to Play in App")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .frame(height: 210)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - WebView Embed Primitive

public struct WebViewEmbed: UIViewRepresentable {
    public let url: URL

    public init(url: URL) {
        self.url = url
    }

    public func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        return webView
    }

    public func updateUIView(_ uiView: WKWebView, context: Context) {
        if uiView.url != url {
            let request = URLRequest(url: url)
            uiView.load(request)
        }
    }
}

// MARK: - SFSafariViewWrapper (In-App Reader)

public struct SFSafariViewWrapper: UIViewControllerRepresentable {
    public let url: URL
    public var entersReaderIfAvailable: Bool

    public init(url: URL, entersReaderIfAvailable: Bool = true) {
        self.url = url
        self.entersReaderIfAvailable = entersReaderIfAvailable
    }

    public func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = entersReaderIfAvailable
        let vc = SFSafariViewController(url: url, configuration: config)
        vc.preferredControlTintColor = UIColor(AppTheme.accent)
        return vc
    }

    public func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// MARK: - PDFKit In-App Viewer

public struct PDFKitView: UIViewRepresentable {
    public let url: URL

    public init(url: URL) {
        self.url = url
    }

    public func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = UIColor.systemBackground
        pdfView.document = PDFDocument(url: url)
        return pdfView
    }

    public func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document?.documentURL != url {
            uiView.document = PDFDocument(url: url)
        }
    }
}

// MARK: - Document / File Reader Sheet

public struct DocumentReaderSheet: View {
    @Environment(\.dismiss) private var dismiss
    public let url: URL
    public let title: String

    public init(url: URL, title: String) {
        self.url = url
        self.title = title
    }

    public var body: some View {
        NavigationStack {
            Group {
                if url.pathExtension.lowercased() == "pdf" {
                    PDFKitView(url: url)
                        .edgesIgnoringSafeArea(.bottom)
                } else if ["jpg", "jpeg", "png", "heic", "webp", "gif"].contains(url.pathExtension.lowercased()) {
                    ScrollView {
                        if let image = UIImage(contentsOfFile: url.path) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .padding()
                        } else {
                            Text("Unable to render image preview")
                                .foregroundColor(AppTheme.textSecondary)
                                .padding()
                        }
                    }
                } else {
                    if let text = try? String(contentsOf: url, encoding: .utf8) {
                        ScrollView {
                            Text(text)
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    } else {
                        Text("Preview unavailable for this file format.")
                            .foregroundColor(AppTheme.textSecondary)
                            .padding()
                    }
                }
            }
            .navigationTitle(title.isEmpty ? url.lastPathComponent : title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.headline)
                        .foregroundColor(AppTheme.accent)
                }
                ToolbarItem(placement: .topBarLeading) {
                    ShareLink(item: url) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(AppTheme.textPrimary)
                    }
                }
            }
        }
    }
}
