// laterbox-ios/laterbox-ios/Views/Components/RemoteMediaPlayerView.swift
import AVFoundation
import AVKit
import CryptoKit
import Combine
import SwiftUI

/// Types supported by iOS AVPlayer for remote playback; not every web
/// browser codec (e.g. MKV/OGG) is playable by Apple's native media engine.
enum RemoteMediaKind: String {
    case video
    case audio

    static func detect(name: String, mimeType: String? = nil) -> Self? {
        let mime = (mimeType ?? "").lowercased().split(separator: ";").first.map(String.init) ?? ""
        let ext = URL(fileURLWithPath: name).pathExtension.lowercased()
        if mime == "application/vnd.apple.mpegurl" || mime == "application/x-mpegurl" {
            return .video
        }
        if mime.hasPrefix("video/") {
            return ["mp4", "quicktime", "x-m4v", "mp2t", "3gpp"].contains(String(mime.dropFirst(6))) ? .video : nil
        }
        if mime.hasPrefix("audio/") {
            return ["mpeg", "mp3", "mp4", "x-m4a", "aac", "wav", "x-wav", "aiff", "x-aiff", "x-caf"].contains(String(mime.dropFirst(6))) ? .audio : nil
        }
        if ["mp4", "m4v", "mov", "m3u8", "3gp"].contains(ext) { return .video }
        if ["mp3", "m4a", "aac", "wav", "aif", "aiff", "caf"].contains(ext) { return .audio }
        return nil
    }

    static func directURL(_ raw: String?) -> (URL, Self)? {
        guard let raw, let url = URL(string: raw), url.scheme?.lowercased() == "https" || url.scheme?.lowercased() == "http",
              let kind = detect(name: url.path) else { return nil }
        return (url, kind)
    }

    static func isRemoteMedia(_ file: SharedAttachment) -> Bool {
        file.remoteObjectKey != nil && detect(name: file.name, mimeType: file.mimeType) != nil
    }
}

/// AVPlayer fetches playable byte ranges/segments as needed. It does not use
/// URLSession.download or persist the entire remote file until Download is tapped.
@MainActor
final class InlineMediaPlayback: ObservableObject {
    let player = AVPlayer()
    @Published var currentSeconds = 0.0
    @Published var durationSeconds = 0.0
    @Published var isPlaying = false
    @Published var playbackError: String?

    private var timeObserver: Any?
    private var currentURL: URL?

    init() {
        player.automaticallyWaitsToMinimizeStalling = true
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let seconds = time.seconds
                if seconds.isFinite { self.currentSeconds = max(0, seconds) }
                let duration = self.player.currentItem?.duration.seconds ?? 0
                self.durationSeconds = duration.isFinite && duration > 0 ? duration : 0
                if self.player.currentItem?.status == .failed {
                    self.playbackError = "This stream could not be played. The source may be unavailable or unsupported."
                    self.pause()
                }
            }
        }
    }

    func load(_ url: URL) {
        guard currentURL != url else { return }
        player.pause()
        player.replaceCurrentItem(with: AVPlayerItem(url: url))
        currentURL = url
        currentSeconds = 0
        durationSeconds = 0
        isPlaying = false
        playbackError = nil
    }

    func toggle() {
        if isPlaying {
            pause()
        } else {
            // Honor audio playback even when the phone's silent switch is on.
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try? AVAudioSession.sharedInstance().setActive(true)
            if durationSeconds > 0 && currentSeconds >= durationSeconds - 0.5 {
                player.seek(to: .zero)
            }
            player.play()
            isPlaying = true
        }
    }

    func seek(to seconds: Double) {
        guard seconds.isFinite else { return }
        currentSeconds = max(0, seconds)
        player.seek(to: CMTime(seconds: currentSeconds, preferredTimescale: 600))
    }

    func pause() {
        player.pause()
        isPlaying = false
    }

    deinit {
        player.pause()
        if let timeObserver { player.removeTimeObserver(timeObserver) }
    }
}

struct RemoteMediaPlayerView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var playback = InlineMediaPlayback()
    @State private var isDownloading = false
    @State private var downloadedURL: URL?
    @State private var downloadError: String?
    @State private var hasStartedVideo = false

    let sourceURL: URL
    let title: String
    let kind: RemoteMediaKind
    var attachment: SharedAttachment? = nil
    var previewImageURL: URL? = nil

    private var isRemote: Bool { sourceURL.isFileURL == false }
    private var isHLS: Bool { sourceURL.pathExtension.lowercased() == "m3u8" }
    private var primaryInk: Color { InboxAppearance.textPrimary(for: colorScheme) }
    private var secondaryInk: Color { InboxAppearance.textSecondary(for: colorScheme) }
    private var panel: Color { InboxAppearance.surface(for: colorScheme) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if kind == .video {
                ZStack {
                    VideoPlayer(player: playback.player)
                        .aspectRatio(16 / 9, contentMode: .fit)
                        .background(Color.black)
                        .accessibilityIdentifier("Item Remote Video Player")

                    if !hasStartedVideo, let previewImageURL {
                        Button {
                            hasStartedVideo = true
                            playback.player.play()
                        } label: {
                            ZStack {
                                AsyncImage(url: previewImageURL) { phase in
                                    if let image = phase.image {
                                        image.resizable().scaledToFill()
                                    } else {
                                        Color.black
                                    }
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .clipped()
                                Color.black.opacity(0.3)
                                Image(systemName: "play.fill")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 60, height: 60)
                                    .background(Color.black.opacity(0.75), in: Circle())
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Play streamed video")
                    }
                }
                .aspectRatio(16 / 9, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                audioControls
            }

            HStack(spacing: 8) {
                Image(systemName: isRemote ? "waveform.path" : "arrow.down.circle.fill")
                    .foregroundStyle(colorScheme == .dark ? AppTheme.accent : Color(hex: "55743E"))
                Text(isRemote ? "Stream from source" : "Available offline")
                    .foregroundStyle(secondaryInk)
                Spacer(minLength: 4)

                if let file = downloadedURL ?? (sourceURL.isFileURL ? sourceURL : nil) {
                    ShareLink(item: file) {
                        Label("Save to Files", systemImage: "square.and.arrow.up")
                    }
                    .accessibilityIdentifier("Media Save to Files")
                } else if isHLS {
                    Text("HLS streaming only")
                        .foregroundStyle(secondaryInk)
                        .accessibilityLabel("Offline download unavailable for HLS streams")
                } else {
                    Button {
                        Task { await download() }
                    } label: {
                        if isDownloading {
                            ProgressView().controlSize(.small)
                            Text("Downloading")
                        } else {
                            Image(systemName: "arrow.down.to.line")
                            Text("Download")
                        }
                    }
                    .disabled(isDownloading)
                    .accessibilityIdentifier("Media Download")
                }
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(primaryInk)

            if let playbackError = playback.playbackError {
                Text(playbackError)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            if let downloadError {
                Text(downloadError)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(12)
        .background(panel, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .strokeBorder(InboxAppearance.border(for: colorScheme), lineWidth: 1)
        }
        .onAppear {
            playback.load(sourceURL)
            if let attachment,
               let file = try? SharedCaptureStore.fileURL(attachment),
               FileManager.default.fileExists(atPath: file.path) {
                downloadedURL = file
            }
        }
        .onChange(of: sourceURL) { _, newURL in
            hasStartedVideo = false
            playback.load(newURL)
        }
        .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { notification in
            guard let item = notification.object as? AVPlayerItem, item === playback.player.currentItem else { return }
            playback.pause()
            playback.seek(to: .zero)
        }
        .onDisappear { playback.pause() }
    }

    private var audioControls: some View {
        HStack(spacing: 12) {
            Button { playback.toggle() } label: {
                Image(systemName: playback.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(hex: "171711"))
                    .frame(width: 48, height: 48)
                    .background(AppTheme.accent, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(playback.isPlaying ? "Pause audio" : "Play audio")
            .accessibilityIdentifier("Item Remote Audio Play")

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(primaryInk)
                    .lineLimit(1)
                Slider(
                    value: Binding(
                        get: { min(playback.currentSeconds, max(0, playback.durationSeconds)) },
                        set: { playback.seek(to: $0) }
                    ),
                    in: 0...max(1, playback.durationSeconds)
                )
                .tint(colorScheme == .dark ? AppTheme.accent : Color(hex: "59733B"))
                .disabled(playback.durationSeconds <= 0)
                .accessibilityLabel("Audio playback position")
                HStack {
                    Text(Self.timeLabel(playback.currentSeconds))
                    Spacer()
                    Text(playback.durationSeconds > 0 ? Self.timeLabel(playback.durationSeconds) : "--:--")
                }
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(secondaryInk)
            }
        }
        .padding(.vertical, 4)
        .accessibilityIdentifier("Item Remote Audio Player")
    }

    static func timeLabel(_ seconds: Double) -> String {
        let value = max(0, Int(seconds.isFinite ? seconds : 0))
        return String(format: "%d:%02d", value / 60, value % 60)
    }

    private func download() async {
        guard !isDownloading else { return }
        isDownloading = true
        downloadError = nil
        defer { isDownloading = false }

        do {
            let destination: URL
            if let attachment {
                destination = try SharedCaptureStore.fileURL(attachment)
            } else {
                let root = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    .appendingPathComponent("LaterBox Downloads", isDirectory: true)
                try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
                let original = sourceURL.lastPathComponent
                let ext = RemoteMediaKind.detect(name: original) != nil
                    ? URL(fileURLWithPath: original).pathExtension.lowercased()
                    : (kind == .video ? "mp4" : "mp3")
                let clean = String(title
                    .replacingOccurrences(of: "/", with: "-")
                    .replacingOccurrences(of: ":", with: "-")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .prefix(70))
                let stem = clean.isEmpty ? "Media" : clean
                let unique = SHA256.hash(data: Data(sourceURL.absoluteString.utf8))
                    .prefix(4).map { String(format: "%02x", $0) }.joined()
                destination = root.appendingPathComponent("\(stem)-\(unique).\(ext)")
            }

            if !FileManager.default.fileExists(atPath: destination.path) {
                let (temporary, response) = try await URLSession.shared.download(from: sourceURL)
                if let http = response as? HTTPURLResponse,
                   !(200..<300).contains(http.statusCode) {
                    throw URLError(.badServerResponse)
                }
                try FileManager.default.createDirectory(
                    at: destination.deletingLastPathComponent(), withIntermediateDirectories: true
                )
                if let attachment, let size = attachment.byteSize,
                   let attributes = try? FileManager.default.attributesOfItem(atPath: temporary.path),
                   (attributes[.size] as? NSNumber)?.int64Value != size {
                    throw CocoaError(.fileReadCorruptFile)
                }
                if let attachment, let expected = attachment.sha256, !expected.isEmpty {
                    var hasher = SHA256()
                    let handle = try FileHandle(forReadingFrom: temporary)
                    defer { try? handle.close() }
                    while let block = try handle.read(upToCount: 1024 * 1024), !block.isEmpty {
                        hasher.update(data: block)
                    }
                    let actual = hasher.finalize().map { String(format: "%02x", $0) }.joined()
                    guard actual == expected.lowercased() else {
                        throw CocoaError(.fileReadCorruptFile)
                    }
                }
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.moveItem(at: temporary, to: destination)
            }
            downloadedURL = destination
        } catch {
            downloadError = "Could not download this file. Please check your connection and retry."
        }
    }
}

/// Resolve the authenticated short-lived cloud URL without transferring the
/// attachment bytes. Native AVPlayer subsequently requests only stream data.
struct RemoteAttachmentMediaView: View {
    @ObservedObject private var coordinator = SyncCoordinator.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var source: URL?
    @State private var error: String?
    @State private var isResolving = false

    let file: SharedAttachment
    let kind: RemoteMediaKind

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let source {
                RemoteMediaPlayerView(sourceURL: source, title: file.name, kind: kind, attachment: file)
                if !source.isFileURL && file.remoteObjectKey != nil {
                    HStack {
                        Spacer()
                        Button {
                            self.source = nil
                            Task { await resolve() }
                        } label: {
                            Label("Refresh stream", systemImage: "arrow.clockwise")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(InboxAppearance.textSecondary(for: colorScheme))
                        .accessibilityIdentifier("Refresh Signed Media Stream")
                    }
                }
            } else {
                HStack(spacing: 10) {
                    if isResolving { ProgressView().controlSize(.small) }
                    else { Image(systemName: kind == .video ? "play.rectangle" : "waveform") }
                    Text(isResolving ? "Preparing stream…" : error ?? "Ready to stream")
                        .font(.system(size: 12))
                    Spacer()
                    if !isResolving {
                        Button("Retry") {
                            Task { await resolve() }
                        }
                        .font(.system(size: 12, weight: .semibold))
                    }
                }
                .padding(12)
                .foregroundStyle(InboxAppearance.textPrimary(for: colorScheme))
                .background(InboxAppearance.surface(for: colorScheme), in: RoundedRectangle(cornerRadius: 13))
            }
        }
        .task(id: file.id) { await resolve() }
    }

    private func resolve() async {
        guard !isResolving else { return }
        isResolving = true
        error = nil
        defer { isResolving = false }

        // Prefer signed cloud streaming even when an old sync cached a file.
        // Offline fallback remains available for previously downloaded media.
        if file.remoteObjectKey != nil,
           coordinator.isAuthenticated, !coordinator.isGuestMode,
           let token = coordinator.authToken {
            do {
                source = try await LaterBoxAPIService.shared.signedAttachmentMediaURL(
                    attachmentID: file.id, token: token
                )
                return
            } catch {
                if let cloud = error as? CloudSyncError,
                   case .serverError(let status, _) = cloud,
                   status == 401 || status == 403,
                   await coordinator.refreshAuthSession(),
                   let refreshedToken = coordinator.authToken {
                    do {
                        source = try await LaterBoxAPIService.shared.signedAttachmentMediaURL(
                            attachmentID: file.id, token: refreshedToken
                        )
                        return
                    } catch {
                        // Offer local/offline fallback below.
                    }
                }
                self.error = "Cloud stream unavailable. Check your connection or sign in again."
            }
        }

        if let fileURL = try? SharedCaptureStore.fileURL(file),
           FileManager.default.fileExists(atPath: fileURL.path) {
            source = fileURL
        } else if error == nil {
            error = "This media is not on this device. Connect to play or download it."
        }
    }
}
