import Foundation
import SwiftData
import UniformTypeIdentifiers

@MainActor enum SharedCaptureImporter {
    static func refresh(context: ModelContext, now: Date = Date()) throws {
        if let pending = try? SharedCaptureStore.pending() {
            for (file, capture) in pending {
                let id = capture.id
                let existing = try context.fetch(FetchDescriptor<LBItem>()).first { $0.id.caseInsensitiveCompare(id) == .orderedSame }
                if let existing {
                    let current = existing.attachmentsData.flatMap { try? JSONDecoder().decode([SharedAttachment].self, from: $0) } ?? []
                    let missing = capture.attachments.filter { asset in !current.contains(where: { $0.id.caseInsensitiveCompare(asset.id) == .orderedSame }) }
                    if !missing.isEmpty {
                        existing.attachmentsData = try JSONEncoder().encode(current + missing)
                        existing.isSyncPending = true
                        existing.updatedAt = now
                        try context.save()
                    }
                } else {
                    // Share Extension and Shortcut imports go through the same
                    // validation, type inference, persistence, and sync path as
                    // the in-app composer. Keep the original capture id so
                    // repeatedly processing the same share stays idempotent.
                    let draft = CaptureDraft.fromShared(capture)
                    _ = try SyncCoordinator.shared.saveDraft(draft, context: context)
                }
                try FileManager.default.removeItem(at: file)
            }
        }
        let items = try context.fetch(FetchDescriptor<LBItem>())
        for item in items where item.status == "deferred" && item.returnAt.map({ $0 <= now }) == true {
            item.status = "inbox"; item.updatedAt = now; item.isSyncPending = true
            let id = item.id
            let title = item.title
            let desc = item.notificationDescription
            Task {
                _ = try? await ReturnNotification.notifyReturned(id: id, title: title, description: desc)
            }
        }
        try context.save()
    }
}
