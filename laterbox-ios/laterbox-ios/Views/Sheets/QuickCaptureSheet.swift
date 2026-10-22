// laterbox-ios/laterbox-ios/Views/Sheets/QuickCaptureSheet.swift
import SwiftUI

/// Quick Save is the fast entry point to the same capture composer as the Inbox.
public struct QuickCaptureSheet: View {
    public init() {}

    public var body: some View {
        CaptureComposerScreen(mode: .quick)
    }
}
