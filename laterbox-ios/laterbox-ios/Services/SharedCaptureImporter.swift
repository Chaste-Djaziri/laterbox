import Foundation
import SwiftData
import UniformTypeIdentifiers

@MainActor enum SharedCaptureImporter {
    static func refresh(context: ModelContext, now: Date = Date()) throws {
        if let pending = try? SharedCaptureStore.pending() {
            for (file, capture) in pending {
                let id = capture.id
                if try context.fetch(FetchDescriptor<LBItem>(predicate: #Predicate { $0.id == id })).isEmpty {
                    let type: ItemContentType = capture.attachments.first.map { attachment in
                        let type = UTType(attachment.typeIdentifier)
                        if type?.conforms(to: .movie) == true { return .video }
                        if type?.conforms(to: .audio) == true { return .music }
                        if type?.conforms(to: .image) == true { return .image }
                        if type?.conforms(to: .pdf) == true || type?.conforms(to: .text) == true { return .document }
                        return .file
                    } ?? (CaptureDraft.detectURL(capture.content) == nil ? .note : .link)
                    let item = LBItem(id: id, title: capture.title, textContent: capture.content, type: type,
                                      status: capture.returnAt.map { $0 > now ? .deferred : .inbox } ?? .inbox, returnAt: capture.returnAt)
                    item.url = CaptureDraft.detectURL(capture.content)
                    item.tags = capture.tags; item.category = capture.category
                    item.attachmentsData = try JSONEncoder().encode(capture.attachments)
                    context.insert(item)
                    do {
                        try context.save()
                        if item.url != nil {
                            Task { await SyncCoordinator.shared.enrich(item: item, context: context) }
                        }
                    } catch { context.delete(item); throw error }
                }
                try FileManager.default.removeItem(at: file)
            }
        }
        let items = try context.fetch(FetchDescriptor<LBItem>())
        for item in items where item.status == "deferred" && item.returnAt.map({ $0 <= now }) == true {
            item.status = "inbox"; item.updatedAt = now; item.isSyncPending = true
        }
        try context.save()
    }
}
