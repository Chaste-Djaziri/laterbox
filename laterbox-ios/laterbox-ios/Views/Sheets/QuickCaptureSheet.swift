// laterbox-ios/laterbox-ios/Views/Sheets/QuickCaptureSheet.swift
import SwiftUI
import SwiftData

public struct QuickCaptureSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var message = ""
    @State private var draft = CaptureDraft()
    @State private var hasSubmitted = false
    @State private var savedItem: LBItem?
    @State private var error: String?
    @State private var editing = false
    @State private var assistantReply = ""

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        if !hasSubmitted {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("QUICK SAVE", systemImage: "bolt.fill")
                                    .font(.caption.weight(.bold))
                                    .tracking(0.7)
                                    .foregroundStyle(AppTheme.accent)
                                Text("What would you like to save?")
                                    .font(.title3.weight(.bold))
                                Text("Send a note, idea, or link to LaterBox.")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(18)
                            .background(Color(white: 0.09), in: RoundedRectangle(cornerRadius: 18))
                        } else {
                            HStack {
                                Spacer(minLength: 48)
                                Text(draft.content)
                                    .font(.subheadline)
                                    .textSelection(.enabled)
                                    .padding(14)
                                    .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 16))
                                    .foregroundStyle(.black)
                            }

                            VStack(alignment: .leading, spacing: 10) {
                                Label("LaterBox", systemImage: "sparkles")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(AppTheme.accent)
                                Text(assistantReply)
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                                    .fixedSize(horizontal: false, vertical: true)
                                if let url = draft.url {
                                    Label(url, systemImage: "link")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.6))
                                        .lineLimit(2)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(Color(white: 0.09), in: RoundedRectangle(cornerRadius: 18))
                        }

                        if let error {
                            Label(error, systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
                                .font(.footnote)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollDismissesKeyboard(.interactively)

                if hasSubmitted {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(savedItem == nil ? "SAVE OPTIONS" : "SAVED ITEM")
                            .font(.caption2.weight(.bold))
                            .tracking(0.7)
                            .foregroundStyle(.white.opacity(0.55))
                        if let item = savedItem {
                            HStack(spacing: 10) {
                                optionButton("Edit", icon: "pencil") { editing = true }
                                optionButton("Undo", icon: "arrow.uturn.backward") { undo(item) }
                                optionButton("Done", icon: "checkmark", primary: true) { dismiss() }
                            }
                        } else {
                            optionButton("Save to LaterBox", icon: "arrow.down.circle.fill", primary: true) { save() }
                            optionButton("Change message", icon: "pencil") {
                                message = draft.content
                                hasSubmitted = false
                                assistantReply = ""
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color(white: 0.06))
                } else {
                    HStack(alignment: .bottom, spacing: 10) {
                        TextField("Type a note or paste a link...", text: $message, axis: .vertical)
                            .lineLimit(1...5)
                            .font(.subheadline)
                            .tint(AppTheme.accent)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color(white: 0.13), in: RoundedRectangle(cornerRadius: 20))
                            .accessibilityLabel("Quick Save message")

                        Button(action: submit) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(.black)
                                .frame(width: 42, height: 42)
                                .background(AppTheme.accent, in: Circle())
                        }
                        .buttonStyle(.plain)
                        .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .opacity(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1)
                        .accessibilityLabel("Send item")
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 12)
                    .background(Color(white: 0.06))
                }
            }
            .background(Color.black.ignoresSafeArea())
            .foregroundStyle(.white)
            .preferredColorScheme(.dark)
            .navigationTitle("Quick Save to LaterBox")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .tint(AppTheme.accent)
                }
            }
            .sheet(isPresented: $editing) {
                if let item = savedItem {
                    NavigationStack { ItemDetailView(item: item) }
                }
            }
        }
    }

    private func optionButton(_ title: String, icon: String, primary: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .foregroundStyle(primary ? Color.black : Color.white)
                .background(primary ? AppTheme.accent : Color(white: 0.16), in: RoundedRectangle(cornerRadius: 13))
        }
        .buttonStyle(.plain)
    }

    private func submit() {
        let text = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        draft = CaptureDraft.manual(text)
        hasSubmitted = true
        assistantReply = draft.url == nil ? "I have your note ready. Save it to your LaterBox inbox, or change the message below." : "I found a link in your message. Save it to your LaterBox inbox, or change the message below."
        error = nil
        LBHaptic.light()
    }

    private func save() {
        do {
            savedItem = try SyncCoordinator.shared.saveDraft(draft, context: context)
            error = nil
            assistantReply = "Saved ‘\\(savedItem?.title ?? draft.title)’ to your LaterBox inbox. You can edit it, undo the save, or finish."
            LBHaptic.medium()
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func undo(_ item: LBItem) {
        item.status = "deleted"
        item.updatedAt = Date()
        item.isSyncPending = true
        do {
            try context.save()
            savedItem = nil
            hasSubmitted = false
            message = ""
            draft = CaptureDraft()
            assistantReply = ""
            Task { await SyncCoordinator.shared.syncPendingItems(context: context) }
        } catch {
            item.status = "inbox"
            self.error = error.localizedDescription
        }
    }
}
