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

                            VStack(alignment: .leading, spacing: 12) {
                                Label(savedItem == nil ? "Ready to save" : "Saved to LaterBox", systemImage: savedItem == nil ? "square.and.arrow.down" : "checkmark.circle.fill")
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.accent)
                                Text(savedItem?.title ?? draft.title)
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(3)
                                if let url = draft.url {
                                    Label(url, systemImage: "link")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.6))
                                        .lineLimit(2)
                                }
                                if let item = savedItem {
                                    HStack(spacing: 18) {
                                        Button("Edit") { editing = true }
                                        Button("Undo") { undo(item) }
                                        Button("Done") { dismiss() }
                                    }
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.accent)
                                } else {
                                    Button(action: save) {
                                        Label("Save to LaterBox", systemImage: "arrow.down.circle.fill")
                                            .font(.subheadline.weight(.bold))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 13)
                                            .foregroundStyle(.black)
                                            .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 13))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(18)
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

                if !hasSubmitted {
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

    private func submit() {
        let text = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        draft = CaptureDraft.manual(text)
        hasSubmitted = true
        error = nil
        LBHaptic.light()
    }

    private func save() {
        do {
            savedItem = try SyncCoordinator.shared.saveDraft(draft, context: context)
            error = nil
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
            Task { await SyncCoordinator.shared.syncPendingItems(context: context) }
        } catch {
            item.status = "inbox"
            self.error = error.localizedDescription
        }
    }
}
