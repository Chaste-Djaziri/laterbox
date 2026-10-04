//
//  QuickCaptureSheet.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 04.10.26.
//

import SwiftUI
import SwiftData

public struct QuickCaptureSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var coordinator = SyncCoordinator.shared

    @State private var urlString: String = ""
    @State private var title: String = ""
    @State private var note: String = ""
    @State private var selectedType: ItemContentType = .link
    @State private var returnSchedule: ReturnOption = .none
    @State private var clipboardUrl: String? = nil

    enum ReturnOption: String, CaseIterable {
        case none = "Inbox"
        case tomorrow = "Tomorrow"
        case thisWeekend = "Weekend"
        case nextWeek = "Next Week"

        public var targetDate: Date? {
            let cal = Calendar.current
            switch self {
            case .none: return nil
            case .tomorrow: return cal.date(byAdding: .day, value: 1, to: Date())
            case .thisWeekend: return cal.date(byAdding: .day, value: 2, to: Date())
            case .nextWeek: return cal.date(byAdding: .day, value: 7, to: Date())
            }
        }
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        // Clipboard detect pill
                        if let clip = clipboardUrl {
                            Button(action: {
                                urlString = clip
                                if title.isEmpty {
                                    title = URL(string: clip)?.host?.replacingOccurrences(of: "www.", with: "") ?? clip
                                }
                                clipboardUrl = nil
                                LBHaptic.success()
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "doc.on.clipboard.fill")
                                        .foregroundColor(Color.lbAmber)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Paste Copied Link")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(.primary)
                                        Text(clip)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.down.circle.fill")
                                        .foregroundColor(Color.lbAmber)
                                }
                                .padding(12)
                                .liquidGlassCard(cornerRadius: 14, borderOpacity: 0.3)
                            }
                            .buttonStyle(.plain)
                        }

                        // URL Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("URL or Resource")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)

                            HStack {
                                Image(systemName: "link")
                                    .foregroundColor(.secondary)
                                TextField("https://example.com/article", text: $urlString)
                                    .keyboardType(.URL)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                                    .onChange(of: urlString) { _, newVal in
                                        inferContentType(from: newVal)
                                    }
                                if !urlString.isEmpty {
                                    Button(action: { urlString = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(14)
                            .liquidGlassCard(cornerRadius: 14)
                        }

                        // Title Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)

                            TextField("Title or description...", text: $title)
                                .padding(14)
                                .liquidGlassCard(cornerRadius: 14)
                        }

                        // Type Selector
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(ItemContentType.allCases, id: \.self) { type in
                                        Button(action: {
                                            selectedType = type
                                            LBHaptic.light()
                                        }) {
                                            HStack(spacing: 6) {
                                                Image(systemName: type.systemIcon)
                                                Text(type.rawValue.capitalized)
                                            }
                                            .liquidGlassPill(isSelected: selectedType == type)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        // Scheduling Options
                        VStack(alignment: .leading, spacing: 8) {
                            Text("When to review")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)

                            HStack(spacing: 8) {
                                ForEach(ReturnOption.allCases, id: \.self) { opt in
                                    Button(action: {
                                        returnSchedule = opt
                                        LBHaptic.light()
                                    }) {
                                        Text(opt.rawValue)
                                            .font(.caption.weight(.medium))
                                            .liquidGlassPill(isSelected: returnSchedule == opt)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // Note Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Personal Note (Optional)")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)

                            TextField("Add thoughts or tags...", text: $note, axis: .vertical)
                                .lineLimit(3...6)
                                .padding(14)
                                .liquidGlassCard(cornerRadius: 14)
                        }

                        // Save Button
                        Button(action: handleSave) {
                            HStack {
                                Image(systemName: "tray.and.arrow.down.fill")
                                Text("Save to LaterBox")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color.lbAmber, Color.lbAmberDark],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .foregroundColor(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: Color.lbAmber.opacity(0.35), radius: 10, y: 4)
                        }
                        .padding(.top, 10)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Quick Capture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.primary)
                }
            }
            .onAppear {
                checkClipboard()
            }
        }
    }

    private func checkClipboard() {
        #if canImport(UIKit)
        if let clip = UIPasteboard.general.string,
           clip.hasPrefix("http://") || clip.hasPrefix("https://") {
            self.clipboardUrl = clip
        }
        #elseif canImport(AppKit)
        if let clip = NSPasteboard.general.string(forType: .string),
           clip.hasPrefix("http://") || clip.hasPrefix("https://") {
            self.clipboardUrl = clip
        }
        #endif
    }

    private func inferContentType(from url: String) {
        let lower = url.lowercased()
        if lower.contains("spotify.com") || lower.contains("music.apple.com") || lower.contains("soundcloud.com") {
            selectedType = .music
        } else if lower.contains("youtube.com") || lower.contains("youtu.be") || lower.contains("vimeo.com") {
            selectedType = .video
        } else if lower.hasSuffix(".pdf") || lower.contains("document") {
            selectedType = .document
        } else if lower.contains("medium.com") || lower.contains("substack.com") {
            selectedType = .article
        }
    }

    private func handleSave() {
        coordinator.saveItem(
            title: title,
            url: urlString.isEmpty ? nil : urlString,
            note: note.isEmpty ? nil : note,
            type: selectedType,
            returnAt: returnSchedule.targetDate,
            context: modelContext
        )
        dismiss()
    }
}
