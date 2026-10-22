// laterbox-ios/laterbox-ios/Views/Sheets/CaptureView.swift
import SwiftUI
import SwiftData

/// Capture and Quick Save are two entry points to the same chat-first interface.
enum CaptureComposerMode: Equatable {
    case quick
    case guided

    var title: String { self == .quick ? "Quick Save to LaterBox" : "Save to LaterBox" }
}

struct CaptureComposerScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LBCollection.name) private var collections: [LBCollection]

    let mode: CaptureComposerMode

    @State private var capture = SharedCapture()
    @State private var savedItem: LBItem?
    @State private var errorMessage: String?
    @State private var isAnalyzing = false
    @State private var showingItemDetails = false

    var body: some View {
        ChatCaptureComposer(
            capture: $capture,
            title: mode.title,
            saved: savedItem != nil,
            isSaving: false,
            isWorking: isAnalyzing,
            savedEditorIsExternal: true,
            errorMessage: errorMessage,
            onClose: { dismiss() },
            onReview: reviewCapture,
            onSave: saveCapture,
            onUndo: undoCapture,
            onEditSaved: { showingItemDetails = true }
        )
        .navigationBarHidden(true)
        .whiteStatusBar()
        .onAppear {
            SyncCoordinator.shared.isShowingCapture = true
            StatusBarStyleModifier.apply(.dark)
        }
        .onDisappear {
            SyncCoordinator.shared.isShowingCapture = false
            StatusBarStyleModifier.apply(.light)
        }
        .sheet(isPresented: $showingItemDetails) {
            if let savedItem {
                NavigationStack { ItemDetailView(item: savedItem) }
            }
        }
    }

    private func reviewCapture() {
        guard !isAnalyzing, savedItem == nil else { return }
        let snapshot = capture
        let names = collections.map(\.name)
        errorMessage = nil
        isAnalyzing = true

        Task {
            let result = await LaterAISharedAnalyzer.analyze(
                content: snapshot.content,
                attachments: snapshot.attachments,
                availableCollections: names,
                settings: SharedCaptureStore.loadAISettings()
            )
            defer { isAnalyzing = false }

            // Do not replace edits made in the composer while AI was preparing.
            guard capture.id == snapshot.id,
                  capture.content == snapshot.content,
                  capture.attachments == snapshot.attachments,
                  savedItem == nil else { return }

            if capture.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                capture.title = result.title ?? snapshot.attachments.first?.name ?? ""
            }
            if capture.category.isEmpty {
                capture.category = result.collectionName ?? ""
            }
            if capture.tags.isEmpty {
                capture.tags = result.tags
            }
            if capture.metadataDescription == nil {
                capture.metadataDescription = result.summary
            }
            if capture.siteName == nil {
                capture.siteName = result.siteName
            }
            if capture.previewImageUrl == nil {
                capture.previewImageUrl = result.previewImageUrl
            }
            // A suggestion is only provisional; the final user choice wins.
            if capture.returnAt == nil {
                capture.returnAt = result.returnAt
            }
        }
    }

    private func saveCapture() {
        guard savedItem == nil, !isAnalyzing else { return }

        var draft = CaptureDraft.fromShared(capture)
        if draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let firstLine = String(draft.content.split(separator: "\n").first?.prefix(100) ?? "")
            draft.title = draft.attachments.first?.name ??
                (draft.url.flatMap { URL(string: $0)?.host } ??
                    (firstLine.isEmpty ? "Saved item" : firstLine))
        }

        do {
            savedItem = try SyncCoordinator.shared.saveDraft(draft, context: modelContext)
            errorMessage = nil
            LBHaptic.success()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func undoCapture() {
        guard let item = savedItem else { return }
        let statusBefore = item.status
        let updatedBefore = item.updatedAt
        let pendingBefore = item.isSyncPending
        item.status = "deleted"
        item.updatedAt = Date()
        item.isSyncPending = true

        do {
            try modelContext.save()
            savedItem = nil
            // An undone item remains in Recently Deleted. A subsequent capture
            // must have its own identity, never revive the deleted item.
            capture.id = UUID().uuidString
            Task {
                _ = try? await ReturnNotification.update(id: item.id, title: item.title, date: nil)
                await SyncCoordinator.shared.syncPendingItems(context: modelContext)
            }
            LBHaptic.medium()
        } catch {
            item.status = statusBefore
            item.updatedAt = updatedBefore
            item.isSyncPending = pendingBefore
            errorMessage = error.localizedDescription
        }
    }
}

public struct CaptureView: View {
    public init() {}

    public var body: some View {
        CaptureComposerScreen(mode: .guided)
    }
}
