//
//  AIOrganizerSheet.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 04.10.26.
//

import SwiftUI
import SwiftData

struct AISuggestion: Identifiable {
    let id = UUID()
    let item: LBItem
    let suggestedCollection: String
    let suggestedReturnDate: Date
    let suggestedTags: [String]
    var isApplied: Bool = false
}

public struct AIOrganizerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var inboxItems: [LBItem]
    @ObservedObject var coordinator = SyncCoordinator.shared

    @State private var suggestions: [AISuggestion] = []
    @State private var isProcessing = false
    @State private var allApplied = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header Banner
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(colors: [Color.lbAmber, Color.lbAmberDark], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 48, height: 48)
                                Image(systemName: "wand.and.stars.inverse")
                                    .font(.system(size: 22))
                                    .foregroundColor(.black)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text("AI Inbox Organizer")
                                    .font(.headline.weight(.bold))
                                    .foregroundColor(.primary)
                                Text("Classify collections, action tags & return timelines")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(16)
                        .liquidGlassCard(cornerRadius: 18)

                        if suggestions.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(Color.lbAmber)
                                Text("Your Inbox is Clean!")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("No pending items require AI reorganization right now.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(40)
                            .liquidGlassCard(cornerRadius: 20)
                        } else {
                            // Action Bar
                            HStack {
                                Text("\(suggestions.count) Suggestions Ready")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.secondary)

                                Spacer()

                                Button(action: applyAll) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "checkmark.seal.fill")
                                        Text(allApplied ? "Applied!" : "Apply All")
                                            .font(.caption.weight(.bold))
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Color.lbAmber)
                                    .foregroundColor(.black)
                                    .clipShape(Capsule())
                                }
                            }

                            // Suggestions List
                            ForEach($suggestions) { $suggestion in
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(suggestion.item.title)
                                        .font(.headline)
                                        .lineLimit(1)

                                    HStack(spacing: 8) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "folder.badge.plus")
                                                .font(.caption)
                                            Text(suggestion.suggestedCollection)
                                                .font(.caption.weight(.semibold))
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Capsule().fill(Color.lbAmber.opacity(0.2)))
                                        .foregroundColor(Color.lbAmber)

                                        HStack(spacing: 4) {
                                            Image(systemName: "calendar.badge.clock")
                                                .font(.caption)
                                            Text("Review Weekend")
                                                .font(.caption.weight(.semibold))
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Capsule().fill(Color.white.opacity(0.08)))
                                        .foregroundColor(.secondary)
                                    }

                                    HStack {
                                        ForEach(suggestion.suggestedTags, id: \.self) { tag in
                                            Text("#\(tag)")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Button(action: {
                                            applySingle(suggestion: $suggestion)
                                        }) {
                                            Text(suggestion.isApplied ? "Applied" : "Apply")
                                                .font(.caption.weight(.bold))
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(suggestion.isApplied ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(Color.lbAmber))
                                                .foregroundColor(suggestion.isApplied ? .secondary : .black)
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                                .padding(16)
                                .liquidGlassCard(cornerRadius: 18)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("AI Organizer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                generateSuggestions()
            }
        }
    }

    private func generateSuggestions() {
        let cal = Calendar.current
        var list: [AISuggestion] = []
        let pending = inboxItems.filter { $0.status == ItemStatus.inbox.rawValue }

        for item in pending.prefix(8) {
            let collection = inferCollection(for: item)
            let returnDate = cal.date(byAdding: .day, value: 3, to: Date()) ?? Date()
            let tags = inferTags(for: item)
            list.append(AISuggestion(item: item, suggestedCollection: collection, suggestedReturnDate: returnDate, suggestedTags: tags))
        }
        self.suggestions = list
    }

    private func inferCollection(for item: LBItem) -> String {
        let text = (item.title + " " + (item.url ?? "")).lowercased()
        if text.contains("design") || text.contains("ui") || text.contains("figma") {
            return "Design Systems"
        } else if text.contains("github") || text.contains("code") || text.contains("dev") {
            return "Engineering"
        } else if text.contains("music") || text.contains("spotify") || text.contains("album") {
            return "Audio Vault"
        } else if text.contains("article") || text.contains("blog") || text.contains("news") {
            return "Long Reads"
        }
        return "Inbox Stash"
    }

    private func inferTags(for item: LBItem) -> [String] {
        var tags = ["read-later"]
        if item.type == ItemContentType.video.rawValue { tags.append("watch") }
        if item.type == ItemContentType.music.rawValue { tags.append("listen") }
        return tags
    }

    private func applySingle(suggestion: Binding<AISuggestion>) {
        let item = suggestion.wrappedValue.item
        item.collectionName = suggestion.wrappedValue.suggestedCollection
        item.returnAt = suggestion.wrappedValue.suggestedReturnDate
        suggestion.wrappedValue.isApplied = true
        try? modelContext.save()
        LBHaptic.success()
    }

    private func applyAll() {
        for idx in suggestions.indices {
            suggestions[idx].item.collectionName = suggestions[idx].suggestedCollection
            suggestions[idx].item.returnAt = suggestions[idx].suggestedReturnDate
            suggestions[idx].isApplied = true
        }
        try? modelContext.save()
        allApplied = true
        LBHaptic.success()
    }
}
