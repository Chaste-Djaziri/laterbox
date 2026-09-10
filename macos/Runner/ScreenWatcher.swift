import AppKit
import CoreGraphics
import CoreMedia
import Foundation
import ScreenCaptureKit
import Vision

/// Lightweight candidate representation detected on the screen.
struct ScreenCandidate {
  let title: String
  let url: String?
  let snippet: String?
}

/// Continuous screen watcher using ScreenCaptureKit and on-device Vision OCR.
/// Excludes LaterBox from capture to prevent feedback loops.
final class ScreenWatcher: NSObject, SCStreamOutput, SCStreamDelegate {
  private var stream: SCStream?
  private let processingQueue = DispatchQueue(
    label: "pro.micorp.laterbox.screen-watcher",
    qos: .utility
  )
  private var lastAnalysis = Date.distantPast
  private var lastDetectedContentHash: Int = 0

  var onCandidateDetected: ((ScreenCandidate) -> Void)?
  private(set) var isWatching: Bool = false

  /// Whether Screen Recording permission is already granted.
  static func isScreenCaptureTrusted() -> Bool {
    return CGPreflightScreenCaptureAccess()
  }

  /// Prompts the system Screen Recording permission dialog if needed.
  /// Returns true when trusted after the prompt.
  @discardableResult
  static func requestScreenCaptureAccess() -> Bool {
    return CGRequestScreenCaptureAccess()
  }

  func start() async throws {
    guard !isWatching else { return }

    guard Self.isScreenCaptureTrusted() else {
      // Trigger the system prompt once before throwing – the user will be
      // guided to System Settings → Privacy & Security → Screen Recording.
      _ = Self.requestScreenCaptureAccess()
      throw WatchError.permissionDenied
    }

    let content = try await SCShareableContent.excludingDesktopWindows(
      false,
      onScreenWindowsOnly: true
    )

    let mainDisplayID = CGMainDisplayID()
    guard let display = content.displays.first(where: { $0.displayID == mainDisplayID })
      ?? content.displays.first else {
      throw WatchError.noDisplay
    }

    // Never capture LaterBox itself.
    let ownApps = content.applications.filter {
      $0.bundleIdentifier == Bundle.main.bundleIdentifier
    }

    let filter = SCContentFilter(
      display: display,
      excludingApplications: ownApps,
      exceptingWindows: []
    )

    let configuration = SCStreamConfiguration()
    // 1 frame per second is plenty for candidate detection without draining CPU.
    configuration.minimumFrameInterval = CMTime(value: 1, timescale: 1)
    configuration.queueDepth = 2
    configuration.showsCursor = false
    if #available(macOS 13.0, *) {
      configuration.capturesAudio = false
    }

    let stream = SCStream(
      filter: filter,
      configuration: configuration,
      delegate: self
    )
    try stream.addStreamOutput(
      self,
      type: .screen,
      sampleHandlerQueue: processingQueue
    )

    self.stream = stream
    try await stream.startCapture()
    self.isWatching = true
  }

  func stop() async {
    guard let stream = stream else { return }
    try? await stream.stopCapture()
    self.stream = nil
    self.isWatching = false
  }

  func stream(
    _ stream: SCStream,
    didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
    of outputType: SCStreamOutputType
  ) {
    guard outputType == .screen else { return }

    // Analyze every ~2 seconds to keep CPU and energy usage minimal.
    let now = Date()
    guard now.timeIntervalSince(lastAnalysis) >= 2.0 else { return }
    lastAnalysis = now

    guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
    recognizeText(in: imageBuffer)
  }

  private func recognizeText(in imageBuffer: CVPixelBuffer) {
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .fast
    request.usesLanguageCorrection = false

    let handler = VNImageRequestHandler(cvPixelBuffer: imageBuffer, options: [:])
    do {
      try handler.perform([request])
      guard let results = request.results, !results.isEmpty else { return }

      let recognizedLines = results.compactMap { $0.topCandidates(1).first?.string }
      let joinedText = recognizedLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)

      guard !joinedText.isEmpty else { return }

      // Deduplicate to avoid repeatedly firing the same screen content.
      let contentHash = joinedText.hashValue
      guard contentHash != lastDetectedContentHash else { return }
      lastDetectedContentHash = contentHash

      if let candidate = parseCandidate(from: recognizedLines) {
        DispatchQueue.main.async { [weak self] in
          self?.onCandidateDetected?(candidate)
        }
      }
    } catch {
      NSLog("[LaterBox Watcher] Vision OCR error: %@", error.localizedDescription)
    }
  }

  private func parseCandidate(from lines: [String]) -> ScreenCandidate? {
    // 1. Look for explicit URLs first
    let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    for line in lines {
      if let match = detector?.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.utf16.count)),
         let url = match.url, url.scheme == "http" || url.scheme == "https" {
        return ScreenCandidate(
          title: formatUrlTitle(url: url.absoluteString),
          url: url.absoluteString,
          snippet: line
        )
      }
    }

    // 2. Check for GitHub / article keywords in lines
    for line in lines {
      let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
      if (trimmed.contains("github.com/") || trimmed.contains("youtube.com/watch")) && trimmed.count < 120 {
        let fullUrl = trimmed.starts(with: "http") ? trimmed : "https://\(trimmed)"
        return ScreenCandidate(
          title: trimmed,
          url: fullUrl,
          snippet: nil
        )
      }
    }

    // 3. Substantial headline / quote candidate (> 20 chars, < 140 chars)
    if let prominentLine = lines.first(where: { $0.count >= 20 && $0.count <= 140 }) {
      return ScreenCandidate(
        title: prominentLine,
        url: nil,
        snippet: prominentLine
      )
    }

    return nil
  }

  private func formatUrlTitle(url: String) -> String {
    if let parsed = URL(string: url), let host = parsed.host {
      let path = parsed.path
      if path.count > 1 {
        return "\(host)\(path)"
      }
      return host
    }
    return url
  }
}

enum WatchError: LocalizedError {
  case noDisplay
  case unsupportedMacOSVersion
  case permissionDenied

  var errorDescription: String? {
    switch self {
    case .noDisplay: return "No display found for screen capture."
    case .unsupportedMacOSVersion: return "Watch Mode requires macOS 12.3 or later."
    case .permissionDenied: return "Screen Recording permission is required. Enable it in System Settings → Privacy & Security → Screen Recording."
    }
  }
}
