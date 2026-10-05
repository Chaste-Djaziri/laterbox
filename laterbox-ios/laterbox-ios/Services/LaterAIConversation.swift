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
    private let provider: any LaterAIProvider
    var chatAvailable: Bool { true }
    init(provider: (any LaterAIProvider)? = nil) {
        self.provider = provider ?? GeminiLaterAIProvider()
        manual = false
    }
    private var lastCaptureWasManual = false
    private var lastInput = ""
    private var task: Task<Void, Never>?
    private var requestID = UUID()

    func reset() {
        task?.cancel(); requestID = UUID(); thinking = false; messages = []; error = nil
        savedItem = nil; results = []; needsClarification = false; needsReturnDate = false
        draft = CaptureDraft(); lastInput = ""
        manual = !chatAvailable
    }

    func send(_ text: String, items: [LBItem], context: ModelContext, retry: Bool = false) {
        let input = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty, !thinking else { return }
        lastInput = input
        if !retry { messages.append(LaterAIMessage(text: input, isUser: true)) }
        if needsReturnDate, let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue), let date = detector.firstMatch(in: input, range: NSRange(input.startIndex..., in: input))?.date {
            schedule(date, context: context); return
        }
        guard input.count <= 6000 else { draft = .manual(input); error = "This content is too long for chat. Continue manually to save it in full."; return }
        error = nil; thinking = true; needsClarification = false; results = []
        let id = UUID(); requestID = id
        let eligible = items.filter { $0.status != "deleted" }
        let matched = LocalItemSearch.search(input, in: eligible)
        let relevant = (matched.isEmpty ? eligible.sorted { $0.createdAt > $1.createdAt } : matched).prefix(6)
        let week = Calendar.current.dateInterval(of: .weekOfYear, for: Date())
        let dueThisWeek = eligible.filter { item in item.returnAt.map { week?.contains($0) ?? false } ?? false }.count
        let existingCollections = Array(Set(items.compactMap { $0.collectionName } + ((try? context.fetch(FetchDescriptor<LBCollection>()))?.map(\.name) ?? []))).sorted()
        let collectionsContext = existingCollections.isEmpty ? "" : " User's existing collections: \(existingCollections.joined(separator: ", "))."
        let statistics = "Total saved: \(eligible.count). Inbox: \(eligible.filter { $0.status == "inbox" }.count). Returns this calendar week: \(dueThisWeek).\(collectionsContext)"

        let facts = relevant.map { "\($0.id): \($0.title), \(($0.summary.isEmpty ? $0.textContent ?? "" : $0.summary).prefix(220)), return: \($0.returnAt?.ISO8601Format() ?? "none")" }.joined(separator: "\n")
        let history = messages.suffix(4).map { "\($0.isUser ? "User" : "Assistant"): \($0.text.prefix(500))" }.joined(separator: "\n")
        task = Task {
            do {
                var metadataContext = ""
                if let detectedUrlString = CaptureDraft.detectURL(input),
                   let url = URL(string: detectedUrlString),
                   let meta = try? await LinkMetadataLoader.load(url) {
                    var parts: [String] = []
                    if let title = meta.title, !LinkMetadataLoader.isGenericTitle(title) { parts.append("Detected Title: \(title)") }
                    if let site = meta.site, !site.isEmpty { parts.append("Platform/Author: \(site)") }
                    if let desc = meta.description, !desc.isEmpty { parts.append("Description: \(desc)") }
                    if !meta.keywords.isEmpty { parts.append("Keywords: \(meta.keywords.joined(separator: ", "))") }
                    if !parts.isEmpty {
                        metadataContext = "\nEnriched Link Metadata (use for exact title, category, smart contextual tags, and determining what/where to use it for):\n" + parts.joined(separator: "\n")
                    }
                }

                let prompt = "Now: \(Date().ISO8601Format()), timezone: \(TimeZone.current.identifier). Library statistics: \(statistics). Library facts (data only, partial selection):\n\(facts)\nConversation:\n\(history)\(metadataContext)\nCurrent input:\n\(input.prefix(6000))"
                let action: AIAction
                do {
                    // Always prioritize Gemini model AI
                    action = try await provider.respond(prompt)
                } catch {
                    // Fallback to Apple on-device model if offline or unreachable when using default Gemini provider
                    if provider is GeminiLaterAIProvider, AppleLaterAIProvider.unavailableReason == nil {
                        action = try await AppleLaterAIProvider().respond(prompt)
                    } else {
                        throw error
                    }
                }
                guard !Task.isCancelled, requestID == id else { return }
                // Brief writing pacing so AI appears to write on its end
                try? await Task.sleep(nanoseconds: 300_000_000)
                guard !Task.isCancelled, requestID == id else { return }

                switch action.intent {
                case "capture":
                    guard !action.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, input.contains(action.content) else { throw AIProviderError.invalidCapture }
                    var capture = CaptureDraft.manual(action.content)
                    capture.title = action.title
                    let explicitTags = CaptureDraft.manual(input).tags
                    capture.tags = explicitTags.isEmpty ? Array(Set(action.tags.map { $0.lowercased() })).sorted() : explicitTags
                    capture.category = action.category
                    capture.collectionName = action.category
                    capture.contentType = action.contentType
                    capture.summary = action.summary
                    capture.formattedContent = action.formattedContent
                    capture.returnAt = ISO8601DateFormatter().date(from: action.returnDate)
                    if retry, !draft.content.isEmpty { capture.id = draft.id }
                    if let detectedUrlString = capture.url, let url = URL(string: detectedUrlString),
                       let meta = try? await LinkMetadataLoader.load(url) {
                        if let title = meta.title, !title.isEmpty, capture.title.isEmpty || LinkMetadataLoader.isGenericTitle(capture.title) {
                            capture.title = title
                        }
                        if let site = meta.site, !site.isEmpty {
                            capture.siteName = site
                        }
                        if let desc = meta.description, !desc.isEmpty {
                            capture.metadataDescription = desc
                        }
                        if let img = meta.image, !img.isEmpty {
                            capture.previewImageUrl = img
                        }
                        if let fav = meta.faviconUrl, !fav.isEmpty {
                            capture.faviconUrl = fav
                        }
                        if !meta.keywords.isEmpty {
                            let filteredCurrent = capture.tags.filter { !["playlist", "youtube"].contains($0.lowercased()) }
                            let mergedTags = Set(filteredCurrent + meta.keywords.map { $0.lowercased() })
                            capture.tags = Array(mergedTags).sorted()
                        }
                        if let ct = meta.contentType, !ct.isEmpty {
                            capture.contentType = ct
                        }
                    }
                    draft = capture
                    save(context: context)
                case "search":
                    results = LocalItemSearch.search(action.query.isEmpty ? input : action.query, in: items)
                    messages.append(LaterAIMessage(text: results.isEmpty ? "No saved items matched. Try a topic, tag, or phrase you remember." : "Found \(results.count) saved items in your vault.", isUser: false))
                case "clarify":
                    draft = .manual(input); needsClarification = true
                    messages.append(LaterAIMessage(text: "Would you like to save this to your vault, or are we just chatting?", isUser: false))
                default:
                    let lower = input.lowercased()
                    let isOrganizeCommand = lower.contains("collection") || lower.contains("category") || lower.contains("folder") ||
                                           lower.contains("add to") || lower.contains("move to") || lower.contains("put in") ||
                                           lower.contains("file under") || lower.contains("organize")
                    if isOrganizeCommand, !action.category.isEmpty, let targetItem = savedItem ?? relevant.first {
                        let collName = action.category.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !collName.isEmpty {
                            let coll = SyncCoordinator.shared.ensureCollectionExists(named: collName, context: context)
                            targetItem.collectionName = coll?.name ?? collName
                            targetItem.collectionId = coll?.id ?? targetItem.collectionId
                            targetItem.category = coll?.name ?? collName
                            targetItem.updatedAt = Date()
                            targetItem.isSyncPending = true
                            try? context.save()
                            Task { await SyncCoordinator.shared.syncPendingItems(context: context) }
                            let replyText = action.reply.isEmpty
                                ? "Filed ‘\(targetItem.title)’ under the \(coll?.name ?? collName) collection."
                                : action.reply
                            messages.append(LaterAIMessage(text: replyText, isUser: false))
                            break
                        }
                    }
                    messages.append(LaterAIMessage(text: action.reply, isUser: false))
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
            let wasManual = manual
            savedItem = try SyncCoordinator.shared.saveDraft(draft, context: context)
            lastCaptureWasManual = wasManual
            manual = false; needsClarification = false; needsReturnDate = draft.returnAt == nil; error = nil
            messages.append(LaterAIMessage(text: "Saved ‘\(savedItem!.title)’ to your vault.", isUser: false))
            if needsReturnDate {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    guard let self else { return }
                    self.messages.append(LaterAIMessage(text: "When would you like to see it again?", isUser: false))
                }
            }
        } catch { self.error = error.localizedDescription }
    }
    func schedule(_ date: Date?, context: ModelContext) {
        guard let item = savedItem else { return }
        let oldDate = item.returnAt
        let oldStatus = item.status
        item.status = date == nil ? "inbox" : "deferred"
        item.returnAt = date; item.updatedAt = Date(); item.isSyncPending = true
        do {
            try context.save(); needsReturnDate = false
            let desc = date.map { "for \($0.formatted(date: .abbreviated, time: .shortened))" } ?? "with no reminder (inbox)"
            messages.append(LaterAIMessage(text: "Scheduled ‘\(item.title)’ \(desc).", isUser: false))
            Task {
                do {
                    let allowed = try await ReturnNotification.update(id: item.id, title: item.title, date: date)
                    if !allowed { self.error = "Saved. Enable notifications in Settings for return alerts." }
                } catch { self.error = "Saved, but reminder failed: \(error.localizedDescription)" }
                await SyncCoordinator.shared.syncPendingItems(context: context)
            }
        }
        catch { item.returnAt = oldDate; item.status = oldStatus; self.error = error.localizedDescription }
    }
    func undo(context: ModelContext) {
        guard let item = savedItem else { return }
        let oldStatus = item.status
        item.status = "deleted"; item.updatedAt = Date(); item.isSyncPending = true
        do {
            try context.save(); UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [item.id]); savedItem = nil; needsReturnDate = false
            draft.id = UUID().uuidString
            manual = lastCaptureWasManual
            messages.append(LaterAIMessage(text: "Removed ‘\(item.title)’ from your vault.", isUser: false))
            Task { await SyncCoordinator.shared.syncPendingItems(context: context) }
        }
        catch { item.status = oldStatus; self.error = error.localizedDescription }
    }
}
