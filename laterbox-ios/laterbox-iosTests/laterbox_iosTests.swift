import Testing
import SwiftData
import Foundation
@testable import laterbox_ios

@MainActor
struct LaterAITests {
    private func context() throws -> ModelContext {
        let container = try ModelContainer(for: LBItem.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return ModelContext(container)
    }
    @Test func capturePersistsOriginalAndClassificationOnce() throws {
        let context = try context()
        var draft = CaptureDraft.manual("A recipe for lentil soup #cooking")
        draft.category = "Recipes"; draft.summary = "Soup"; draft.formattedContent = "Lentil soup"
        let first = try SyncCoordinator.shared.saveDraft(draft, context: context)
        let second = try SyncCoordinator.shared.saveDraft(draft, context: context)
        #expect(first.id == second.id)
        #expect(try context.fetch(FetchDescriptor<LBItem>()).count == 1)
        #expect(first.textContent == draft.content)
        #expect(first.tags == ["cooking"])
        #expect(first.category == "Recipes")
        #expect(first.formattedContent == "Lentil soup")
    }
    @Test func emptyCaptureDoesNotInsert() throws {
        let context = try context()
        #expect(throws: AIProviderError.self) { try SyncCoordinator.shared.saveDraft(CaptureDraft(content: " \n"), context: context) }
        #expect(try context.fetch(FetchDescriptor<LBItem>()).isEmpty)
    }
    @Test func searchesTagsOriginalTextAndTyposWithoutDeletedItems() {
        let a = LBItem(title: "Focus guide", textContent: "Concentration and deep work")
        a.tags = ["productivity"]
        let b = LBItem(title: "Focus guide", status: .deleted)
        #expect(LocalItemSearch.search("productivity", in: [a,b]).map(\.id) == [a.id])
        #expect(LocalItemSearch.search("concentraton", in: [a,b]).map(\.id) == [a.id])
        #expect(LocalItemSearch.search("focus", in: [a,b]).map(\.id) == [a.id])
        #expect(LocalItemSearch.search("focus", in: [b], includeDeleted: true).count == 1)
        #expect(LocalItemSearch.search("zzzzzzzzzzz", in: [a]).isEmpty)
    }
    @Test func exactMatchesRankAbovePartialMatches() {
        let exact = LBItem(title: "Deep work")
        let partial = LBItem(title: "Work notes")
        #expect(LocalItemSearch.search("deep work", in: [partial, exact]).first?.id == exact.id)
    }
    @Test func weekendIsSaturdayAndDatesDecodeFractionalSeconds() throws {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let monday = try #require(ISO8601DateFormatter().date(from: "2026-10-05T12:00:00Z"))
        let saturday = CaptureDraft.weekend(now: monday, calendar: calendar)
        #expect(calendar.component(.weekday, from: saturday) == 7)
        #expect(calendar.component(.day, from: saturday) == 10)
        #expect(SyncCoordinator.cloudDate("2026-10-05T12:00:00.123Z") != nil)
    }
    @Test func remoteFallbackDisabledWithoutNetwork() async {
        #expect(GeminiLaterAIProvider.enabled == false)
        await #expect(throws: AIProviderError.self) { try await GeminiLaterAIProvider().respond("Hello") }
    }
    @Test func modelFailurePreservesInputForGuidedCapture() async throws {
        let context = try context()
        let conversation = LaterAIConversation(provider: FailingProvider())
        conversation.send("My original note #ideas", items: [], context: context)
        while conversation.thinking { try await Task.sleep(for: .milliseconds(10)) }
        #expect(conversation.error != nil)
        conversation.continueManually()
        #expect(conversation.manual)
        #expect(conversation.draft.content == "My original note #ideas")
        #expect(conversation.draft.tags == ["ideas"])
        #expect(try context.fetch(FetchDescriptor<LBItem>()).isEmpty)
    }
    @Test func automaticCaptureAndUndoPersist() async throws {
        let context = try context()
        let conversation = LaterAIConversation(provider: CaptureProvider())
        conversation.send("My note #ideas", items: [], context: context)
        while conversation.thinking { try await Task.sleep(for: .milliseconds(10)) }
        let item = try #require(conversation.savedItem)
        #expect(item.textContent == "My note #ideas")
        #expect(item.tags == ["ideas"])
        #expect(conversation.needsReturnDate)
        conversation.schedule(nil, context: context)
        #expect(!conversation.needsReturnDate)
        conversation.undo(context: context)
        #expect(item.status == "deleted")
        #expect(conversation.savedItem == nil)
    }
    @Test func defaultClassificationFieldsAreCompatible() {
        let item = LBItem(title: "Existing item")
        #expect(item.tags.isEmpty && item.category.isEmpty && item.summary.isEmpty && item.formattedContent.isEmpty)
    }
}
@MainActor
private struct FailingProvider: LaterAIProvider {
    func respond(_ prompt: String) async throws -> AIAction { throw AIProviderError.remoteFailed }
}
@MainActor
private struct CaptureProvider: LaterAIProvider {
    func respond(_ prompt: String) async throws -> AIAction {
        AIAction(intent: "capture", reply: "", content: "My note #ideas", title: "My note", category: "Ideas", tags: ["invented"], summary: "Note", formattedContent: "", query: "", returnDate: "")
    }
}
