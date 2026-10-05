//
//  ClipboardDetectionManager.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 05.10.26.
//

import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#endif

public struct CopiedItemPayload: Equatable, Identifiable {
    public let id: String
    public let rawContent: String
    public let titlePreview: String
    public let snippetPreview: String
    public let isURL: Bool
    public let detectedURL: URL?
    public let systemIcon: String
    public let timestamp: Date

    public init(
        id: String = UUID().uuidString,
        rawContent: String,
        titlePreview: String,
        snippetPreview: String,
        isURL: Bool,
        detectedURL: URL?,
        systemIcon: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.rawContent = rawContent
        self.titlePreview = titlePreview
        self.snippetPreview = snippetPreview
        self.isURL = isURL
        self.detectedURL = detectedURL
        self.systemIcon = systemIcon
        self.timestamp = timestamp
    }
}

@MainActor
public final class ClipboardDetectionManager: ObservableObject {
    public static let shared = ClipboardDetectionManager()

    @Published public var detectedItem: CopiedItemPayload? = nil
    @Published public var isShowingBanner: Bool = false

    private let userDefaults: UserDefaults
    private let changeCountKey = "LB_LastHandledClipboardChangeCount"
    private let contentHashKey = "LB_LastHandledClipboardHash"

    private var internalCopyHashes: Set<Int> = []
    private var dismissTask: Task<Void, Never>? = nil

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    private var lastHandledChangeCount: Int {
        get { userDefaults.integer(forKey: changeCountKey) }
        set { userDefaults.set(newValue, forKey: changeCountKey) }
    }

    private var lastHandledHash: Int {
        get { userDefaults.integer(forKey: contentHashKey) }
        set { userDefaults.set(newValue, forKey: contentHashKey) }
    }

    /// Records an item copied internally within LaterBox so it is never re-prompted.
    public func recordInternalCopy(_ text: String) {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        let hash = clean.hashValue
        internalCopyHashes.insert(hash)
        lastHandledHash = hash
        #if canImport(UIKit)
        lastHandledChangeCount = UIPasteboard.general.changeCount + 1
        #endif
    }

    /// Checks the pasteboard when the user enters or switches to the app.
    public func checkForCopiedItem() {
        #if canImport(UIKit)
        let pasteboard = UIPasteboard.general
        let currentChangeCount = pasteboard.changeCount

        // Only inspect if pasteboard has changed since our last check
        guard currentChangeCount != lastHandledChangeCount else { return }

        // Fast-path: Check type without reading content if possible
        guard pasteboard.hasStrings || pasteboard.hasURLs else {
            lastHandledChangeCount = currentChangeCount
            return
        }

        guard let text = pasteboard.string?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty,
              text.count <= 10_000 else {
            lastHandledChangeCount = currentChangeCount
            return
        }

        let hash = text.hashValue

        // Ignore if previously handled, dismissed, or copied inside the app
        if hash == lastHandledHash || internalCopyHashes.contains(hash) {
            lastHandledChangeCount = currentChangeCount
            return
        }

        let payload = Self.parsePayload(from: text)
        self.detectedItem = payload
        self.lastHandledChangeCount = currentChangeCount

        // Haptic feedback & presentation
        LBHaptic.light()
        withAnimation(.spring(response: 0.44, dampingFraction: 0.82)) {
            self.isShowingBanner = true
        }

        // Auto-dismiss after 10 seconds if ignored
        dismissTask?.cancel()
        dismissTask = Task {
            try? await Task.sleep(nanoseconds: 10_000_000_000)
            if !Task.isCancelled {
                self.dismiss()
            }
        }
        #endif
    }

    /// Parses clipboard text into a rich preview payload.
    public static func parsePayload(from text: String) -> CopiedItemPayload {
        let detectedUrlString = CaptureDraft.detectURL(text)
        let isURL = detectedUrlString != nil
        let detectedURL = detectedUrlString.flatMap { URL(string: $0) }

        let titlePreview: String
        let systemIcon: String

        if let url = detectedURL {
            let host = url.host?.replacingOccurrences(of: "www.", with: "") ?? "Web Link"
            titlePreview = host

            let lowerHost = host.lowercased()
            if lowerHost.contains("youtube.com") || lowerHost.contains("youtu.be") || lowerHost.contains("vimeo.com") {
                systemIcon = "play.rectangle.fill"
            } else if lowerHost.contains("twitter.com") || lowerHost.contains("x.com") {
                systemIcon = "bubble.left.and.bubble.right.fill"
            } else if lowerHost.contains("github.com") {
                systemIcon = "chevron.left.forwardslash.chevron.right"
            } else if lowerHost.contains("spotify.com") || lowerHost.contains("music.apple.com") || lowerHost.contains("soundcloud.com") {
                systemIcon = "music.note"
            } else if lowerHost.contains("reddit.com") {
                systemIcon = "text.bubble.fill"
            } else if lowerHost.contains("medium.com") || lowerHost.contains("substack.com") {
                systemIcon = "newspaper.fill"
            } else {
                systemIcon = "link"
            }
        } else {
            let firstLine = text.split(separator: "\n").first.map(String.init)?.trimmingCharacters(in: .whitespaces) ?? ""
            titlePreview = firstLine.isEmpty ? "Copied Note" : firstLine
            systemIcon = "doc.text.fill"
        }

        return CopiedItemPayload(
            rawContent: text,
            titlePreview: titlePreview,
            snippetPreview: text,
            isURL: isURL,
            detectedURL: detectedURL,
            systemIcon: systemIcon
        )
    }

    /// Confirms saving the copied item, launches Later AI with the item as attached subject to save.
    public func confirmSave() {
        dismissTask?.cancel()
        guard let item = detectedItem else { return }

        lastHandledHash = item.rawContent.hashValue
        #if canImport(UIKit)
        lastHandledChangeCount = UIPasteboard.general.changeCount
        #endif

        LBHaptic.medium()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            self.isShowingBanner = false
        }
        self.detectedItem = nil

        // Open Later AI with the item attached and sent as subject to save
        LaterAIManager.shared.open(with: item.rawContent, autoSend: true)
    }

    /// Dismisses the banner without saving and suppresses re-prompting for this item.
    public func dismiss() {
        dismissTask?.cancel()
        if let item = detectedItem {
            lastHandledHash = item.rawContent.hashValue
            #if canImport(UIKit)
            lastHandledChangeCount = UIPasteboard.general.changeCount
            #endif
        }

        LBHaptic.light()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            self.isShowingBanner = false
        }
        self.detectedItem = nil
    }
}
