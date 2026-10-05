import Testing
import SwiftData
import Foundation
import UserNotifications
@testable import laterbox_ios

@Suite(.serialized)
@MainActor
struct LaterAITests {
    private func context() throws -> ModelContext {
        let container = try ModelContainer(for: LBItem.self, LBCollection.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return ModelContext(container)
    }
    @Test func cloudSupportsNullTitlesAndStringEncodedMetadata() throws {
        let data = Data(#"{"id":"id","user_id":"user","title":null,"type":"note","favorite":false,"status":"inbox","created_at":"2026-10-05T00:00:00Z","updated_at":"2026-10-05T00:00:00Z","item_metadata":{"status":"enriched","structured_data":"{\"tags\":[\"legacy\"]}"}}"#.utf8)
        let snapshot = try JSONDecoder().decode(CloudItemSnapshot.self, from: data)
        #expect(snapshot.title == nil)
        #expect(snapshot.item_metadata?.structured_data?.tags == ["legacy"])
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
        #expect(GeminiLaterAIProvider.enabled == true)
        GeminiLaterAIProvider.enabled = false
        await #expect(throws: AIProviderError.self) { try await GeminiLaterAIProvider().respond("Hello") }
        GeminiLaterAIProvider.enabled = true
    }
    @Test func linkMetadataIdentifiesGenericTitles() {
        #expect(LinkMetadataLoader.isGenericTitle(nil))
        #expect(LinkMetadataLoader.isGenericTitle(""))
        #expect(LinkMetadataLoader.isGenericTitle("- YouTube"))
        #expect(LinkMetadataLoader.isGenericTitle(" - YouTube "))
        #expect(LinkMetadataLoader.isGenericTitle("YouTube Video Playlist"))
        #expect(LinkMetadataLoader.isGenericTitle("youtube"))
        #expect(LinkMetadataLoader.isGenericTitle("https://youtube.com"))
        #expect(!LinkMetadataLoader.isGenericTitle("Grand Escape | A Weathering With You AMV"))

        #expect(LinkMetadataLoader.cleanTitle("Grand Escape - YouTube") == "Grand Escape")
        #expect(LinkMetadataLoader.cleanTitle("Grand Escape | YouTube") == "Grand Escape")
        #expect(LinkMetadataLoader.cleanTitle("- YouTube") == nil)

        #expect(LinkMetadataLoader.isGenericDescription("Enjoy the videos and music you love, upload original content, and share it all with friends, family, and the world on YouTube."))
        #expect(!LinkMetadataLoader.isGenericDescription("Radwimps - Grand Escape theme song for the movie Weathering With You"))
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
        conversation.schedule(Date().addingTimeInterval(86400), context: context)
        #expect(item.status == "deferred" && item.returnAt != nil)
        conversation.schedule(nil, context: context)
        #expect(item.status == "inbox" && item.returnAt == nil)
        #expect(!conversation.needsReturnDate)
        conversation.undo(context: context)
        #expect(item.status == "deleted")
        #expect(conversation.savedItem == nil)
        #expect(try context.fetch(FetchDescriptor<LBCollection>()).contains { $0.name == "Ideas" })
    }
    @Test func savingDraftAutoCreatesCollectionIfNotAvailable() throws {
        let context = try context()
        var draft = CaptureDraft.manual("AMV video https://youtube.com/watch?v=123")
        draft.category = "Amv"

        let item = try SyncCoordinator.shared.saveDraft(draft, context: context)
        #expect(item.collectionName == "Amv")
        #expect(item.collectionId != nil)

        let collections = try context.fetch(FetchDescriptor<LBCollection>())
        #expect(collections.contains { $0.name == "Amv" })
        let amvCollection = collections.first { $0.name == "Amv" }
        #expect(amvCollection?.id == item.collectionId)
    }
    @Test func savingItemAutoCreatesCollectionIfNotAvailable() throws {
        let context = try context()
        SyncCoordinator.shared.saveItem(title: "Grand Escape", collectionName: "Anime", context: context)

        let collections = try context.fetch(FetchDescriptor<LBCollection>())
        #expect(collections.contains { $0.name == "Anime" })
        let items = try context.fetch(FetchDescriptor<LBItem>())
        let item = items.first { $0.title == "Grand Escape" }
        #expect(item?.collectionName == "Anime")
        #expect(item?.collectionId != nil)
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

extension LaterAITests {
    @Test func freeUsersDoNotMakeCloudRequests() async throws {
        let coordinator = SyncCoordinator.shared
        coordinator.updateProFromStoreKit(false)
        let container = try ModelContainer(for: LBItem.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let transport = MockCloudTransport()
        try await coordinator.performCloudSync(context: container.mainContext, transport: transport)
        #expect(transport.downloads == 0 && transport.uploads.isEmpty)
    }
    @Test func proSyncPreservesNewerLocalCaptureAndImportsRemoteMetadata() async throws {
        try await Task.sleep(for: .milliseconds(100))
        let coordinator = SyncCoordinator.shared
        let previous = (coordinator.currentUserId, coordinator.currentUserEmail, coordinator.authToken)
        let uid = "00000000-0000-4000-8000-000000000009"
        coordinator.currentUserId = uid; coordinator.currentUserEmail = "test@example.com"; coordinator.authToken = "test"
        coordinator.updateProFromStoreKit(true)
        defer {
            coordinator.currentUserId = previous.0; coordinator.currentUserEmail = previous.1; coordinator.authToken = previous.2
            coordinator.updateProFromStoreKit(false)
        }
        let container = try ModelContainer(for: LBItem.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        let local = LBItem(title: "Newer local title", textContent: "Original", updatedAt: Date(timeIntervalSince1970: 2000))
        local.tags = ["local-tag"]; local.category = "Ideas"
        context.insert(local); try context.save()
        let transport = MockCloudTransport()
        let remoteID = UUID().uuidString
        transport.snapshots = [
            CloudItemSnapshot(id: local.id, user_id: uid, title: "Older remote", type: "note", favorite: false, status: "inbox", created_at: "1970-01-01T00:00:01Z", updated_at: "1970-01-01T00:00:02Z"),
            CloudItemSnapshot(id: remoteID, user_id: uid, title: "Remote capture", text_content: "Remote original", type: "note", favorite: false, status: "inbox", created_at: "1970-01-01T00:00:01Z", updated_at: "1970-01-01T00:00:02Z", item_metadata: CloudMetadata(status: "enriched", structured_data: CloudClassification(tags: ["remote-tag"], category: "Reading", summary: "Remote summary", formattedContent: "Formatted")), item_notes: CloudNote(content: "Remote note"))
        ]
        try await coordinator.performCloudSync(context: context, transport: transport)
        #expect(local.title == "Newer local title")
        #expect(!local.isSyncPending)
        #expect(transport.uploads.count == 1)
        #expect(transport.uploads.first?["title"] as? String == "Newer local title")
        let remote = try #require(context.fetch(FetchDescriptor<LBItem>()).first { $0.id == remoteID })
        #expect(remote.tags == ["remote-tag"] && remote.category == "Reading")
        #expect(remote.noteContent == "Remote note" && remote.textContent == "Remote original")
        #expect(remote.formattedContent == "Formatted")
    }
    @Test func failedUploadRemainsPending() async throws {
        try await Task.sleep(for: .milliseconds(100))
        let coordinator = SyncCoordinator.shared
        let previous = (coordinator.currentUserId, coordinator.currentUserEmail, coordinator.authToken)
        coordinator.currentUserId = "00000000-0000-4000-8000-000000000010"; coordinator.currentUserEmail = "test@example.com"; coordinator.authToken = "test"
        coordinator.updateProFromStoreKit(true)
        defer {
            coordinator.currentUserId = previous.0; coordinator.currentUserEmail = previous.1; coordinator.authToken = previous.2
            coordinator.updateProFromStoreKit(false)
        }
        let container = try ModelContainer(for: LBItem.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        let item = LBItem(title: "Offline capture")
        context.insert(item); try context.save()
        let transport = MockCloudTransport(); transport.failUpload = true
        await #expect(throws: URLError.self) { try await coordinator.performCloudSync(context: context, transport: transport) }
        #expect(item.isSyncPending)
    }
    @Test func notificationStatusAndPermissionsAPIAvailable() async {
        let status = await ReturnNotification.currentAuthorizationStatus()
        #expect([UNAuthorizationStatus.notDetermined, .denied, .authorized, .provisional, .ephemeral].contains(status))
    }
    @Test func modelManagerProviderSwitchingAndPresets() {
        let manager = LaterAIModelManager.shared
        let original = (manager.selectedProvider, manager.openAIApiKey, manager.openAIModel)
        defer {
            manager.selectedProvider = original.0
            manager.openAIApiKey = original.1
            manager.openAIModel = original.2
        }

        #expect(AIModelPresets.geminiModels.contains("gemini-2.5-flash"))
        #expect(AIModelPresets.openAIModels.contains("gpt-4o-mini"))
        #expect(AIModelPresets.claudeModels.contains("claude-3-5-haiku-latest"))

        manager.selectedProvider = .customOpenAI
        manager.openAIApiKey = "test-key"
        manager.openAIModel = "gpt-4o"
        #expect(manager.activeModelName == "gpt-4o")
        #expect(manager.selectedProvider.isCustomKey == true)

        manager.selectedProvider = .onDevice
        #expect(manager.selectedProvider.isCustomKey == false)
        #expect(manager.activeModelName == "Apple Intelligence")
    }
    @Test func laterAIJSONParserHandlesFencedAndRawResponses() throws {
        let fencedJSON = """
        ```json
        {
          "intent": "capture",
          "reply": "Saved your note!",
          "content": "Meeting with Sarah",
          "title": "Meeting with Sarah",
          "category": "Work",
          "contentType": "note",
          "tags": ["work", "meetings"],
          "summary": "Meeting notes",
          "formattedContent": "Meeting with Sarah",
          "query": "",
          "returnDate": "2026-10-10T09:00:00Z"
        }
        ```
        """
        let action = try LaterAIJSONParser.parseAIAction(from: fencedJSON)
        #expect(action.intent == "capture")
        #expect(action.title == "Meeting with Sarah")
        #expect(action.category == "Work")
        #expect(action.tags == ["work", "meetings"])
        #expect(action.returnDate == "2026-10-10T09:00:00Z")

        let searchJSON = """
        {"terms": "tax returns", "contentType": "document", "returnWindow": "thisWeek"}
        """
        let interpretation = LaterAIJSONParser.parseSearchInterpretation(from: searchJSON, fallbackQuery: "find my taxes")
        #expect(interpretation.terms == "tax returns")
        #expect(interpretation.contentType == "document")
        #expect(interpretation.returnWindow == "thisWeek")
    }
    @Test func clipboardPayloadParserDetectsURLsAndNoteTypes() {
        let youtubePayload = ClipboardDetectionManager.parsePayload(from: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
        #expect(youtubePayload.isURL == true)
        #expect(youtubePayload.titlePreview == "youtube.com")
        #expect(youtubePayload.systemIcon == "play.rectangle.fill")

        let githubPayload = ClipboardDetectionManager.parsePayload(from: "https://github.com/swiftlang/swift")
        #expect(githubPayload.isURL == true)
        #expect(githubPayload.titlePreview == "github.com")
        #expect(githubPayload.systemIcon == "chevron.left.forwardslash.chevron.right")

        let notePayload = ClipboardDetectionManager.parsePayload(from: "Groceries to buy:\n- Apples\n- Bread")
        #expect(notePayload.isURL == false)
        #expect(notePayload.titlePreview == "Groceries to buy:")
        #expect(notePayload.systemIcon == "doc.text.fill")
    }
    @Test func clipboardManagerDismissAndConfirmLifecycle() {
        let testDefaults = UserDefaults(suiteName: "test_clipboard_\(UUID().uuidString)")!
        let manager = ClipboardDetectionManager(userDefaults: testDefaults)

        let payload = ClipboardDetectionManager.parsePayload(from: "https://news.ycombinator.com")
        manager.detectedItem = payload
        manager.isShowingBanner = true

        #expect(manager.isShowingBanner == true)
        #expect(manager.detectedItem?.titlePreview == "news.ycombinator.com")

        // Dismissal clears banner and detected item
        manager.dismiss()
        #expect(manager.isShowingBanner == false)
        #expect(manager.detectedItem == nil)

        // Internal copy recording
        manager.recordInternalCopy("https://laterbox.app/internal-link")
    }
    @Test func laterAIManagerOpenWithAttachedSubject() {
        let aiManager = LaterAIManager.shared
        aiManager.open(with: "https://swift.org", autoSend: true)
        #expect(aiManager.isShowingLaterAI == true)
        #expect(aiManager.flowProgress == 1.0)
        #expect(aiManager.attachedSubject == "https://swift.org")
        #expect(aiManager.initialPrompt == "https://swift.org")

        aiManager.dismiss()
    }
}
@MainActor
private final class MockCloudTransport: IOSCloudTransport {
    var downloads = 0
    var uploads: [[String: Any]] = []
    var snapshots: [CloudItemSnapshot] = []
    var failUpload = false
    func downloadSnapshots(userID: String, token: String) async throws -> [CloudItemSnapshot] { downloads += 1; return snapshots }
    func cloudRequest(_ path: String, token: String, method: String, body: Any?) async throws -> Data { Data() }
    func uploadSnapshot(_ body: [String: Any], metadata: [String: Any], note: [String: Any], collection: [String: Any]?, token: String) async throws {
        if failUpload { throw URLError(.notConnectedToInternet) }
        uploads.append(body)
    }
}
