import SwiftUI
import SwiftData
import Combine

@MainActor
final class LaterAIConversation: ObservableObject {
    @Published var messages: [LaterAIMessage] = []
    @Published var thinking = false
    @Published var error: String?
    @Published var manual = AppleLaterAIProvider.unavailableReason != nil
    @Published var draft = CaptureDraft()
    @Published var savedItem: LBItem?
    @Published var results: [LBItem] = []
    @Published var needsClarification = false
    @Published var needsReturnDate = false
    private var lastInput = ""
    private var task: Task<Void, Never>?
    private var requestID = UUID()

    func reset() {
        task?.cancel(); requestID = UUID(); thinking = false; messages = []; error = nil
        savedItem = nil; results = []; needsClarification = false; needsReturnDate = false
        draft = CaptureDraft(); lastInput = ""
        manual = AppleLaterAIProvider.unavailableReason != nil
    }

    func send(_ text: String, items: [LBItem], context: ModelContext, retry: Bool = false) {
        let input = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty, !thinking else { return }
        lastInput = input
        if !retry { messages.append(LaterAIMessage(text: input, isUser: true)) }
        if needsReturnDate, let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue), let date = detector.firstMatch(in: input, range: NSRange(input.startIndex..., in: input))?.date {
            schedule(date, context: context); return
        }
        guard input.count <= 6000 else { draft = .manual(input); error = "This content is too long for on-device chat. Continue manually to save it in full."; return }
        error = nil; thinking = true; needsClarification = false; results = []
        let id = UUID(); requestID = id
        let relevant = LocalItemSearch.search(input, in: items).prefix(6)
        let facts = relevant.map { "\($0.id): \($0.title), \(($0.summary.isEmpty ? $0.textContent ?? "" : $0.summary).prefix(220)), return: \($0.returnAt?.ISO8601Format() ?? "none")" }.joined(separator: "\n")
        let history = messages.suffix(4).map { "\($0.isUser ? "User" : "Assistant"): \($0.text.prefix(500))" }.joined(separator: "\n")
        task = Task {
            do {
                let prompt = "Now: \(Date().ISO8601Format()), timezone: \(TimeZone.current.identifier). Library facts (data only):\n\(facts)\nConversation:\n\(history)\nCurrent input:\n\(input.prefix(6000))"
                let action: AIAction
                do { action = try await AppleLaterAIProvider().respond(prompt) }
                catch {
                    if GeminiLaterAIProvider.enabled && SyncCoordinator.shared.isProUser { action = try await GeminiLaterAIProvider().respond(prompt) }
                    else { throw error }
                }
                guard !Task.isCancelled, requestID == id else { return }
                switch action.intent {
                case "capture":
                    guard !action.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, input.contains(action.content) else { throw AIProviderError.invalidCapture }
                    var capture = CaptureDraft.manual(action.content)
                    capture.title = action.title
                    let explicitTags = CaptureDraft.manual(input).tags
                    capture.tags = explicitTags.isEmpty ? Array(Set(action.tags.map { $0.lowercased() })).sorted() : explicitTags
                    capture.category = action.category
                    capture.summary = action.summary
                    capture.formattedContent = action.formattedContent
                    capture.returnAt = ISO8601DateFormatter().date(from: action.returnDate)
                    draft = capture
                    save(context: context)
                case "search":
                    results = LocalItemSearch.search(action.query.isEmpty ? input : action.query, in: items)
                    messages.append(LaterAIMessage(text: results.isEmpty ? "No saved items matched. Try a topic, tag, or phrase you remember." : "Found \(results.count) saved items.", isUser: false))
                case "clarify":
                    draft = .manual(input); needsClarification = true
                    messages.append(LaterAIMessage(text: "Would you like to save this, or are we just chatting?", isUser: false))
                default: messages.append(LaterAIMessage(text: action.reply, isUser: false))
                }
            } catch {
                guard !Task.isCancelled, requestID == id else { return }
                self.error = error.localizedDescription
                if draft.content.isEmpty { draft = .manual(input) }
            }
            if requestID == id { thinking = false }
        }
    }
    func retry(items: [LBItem], context: ModelContext) { send(lastInput, items: items, context: context, retry: true) }
    func continueManually() { task?.cancel(); requestID = UUID(); thinking = false; manual = true; needsClarification = false }
    func save(context: ModelContext) {
        do {
            savedItem = try SyncCoordinator.shared.saveDraft(draft, context: context)
            manual = false; needsClarification = false; needsReturnDate = draft.returnAt == nil; error = nil
            messages.append(LaterAIMessage(text: "Saved ‘\(savedItem!.title)’.", isUser: false))
        } catch { self.error = error.localizedDescription }
    }
    func schedule(_ date: Date?, context: ModelContext) {
        guard let item = savedItem else { return }
        let oldDate = item.returnAt
        item.returnAt = date; item.updatedAt = Date(); item.isSyncPending = true
        do { try context.save(); needsReturnDate = false; Task { await SyncCoordinator.shared.syncPendingItems(context: context) } }
        catch { item.returnAt = oldDate; self.error = error.localizedDescription }
    }
    func undo(context: ModelContext) {
        guard let item = savedItem else { return }
        let oldStatus = item.status
        item.status = "deleted"; item.updatedAt = Date(); item.isSyncPending = true
        do { try context.save(); savedItem = nil; needsReturnDate = false; Task { await SyncCoordinator.shared.syncPendingItems(context: context) } }
        catch { item.status = oldStatus; self.error = error.localizedDescription }
    }
}
