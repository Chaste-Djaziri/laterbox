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
    @Test func permanentCloudDeletionRetriesEvenWithoutPro() async throws {
        let coordinator = SyncCoordinator.shared
        let previous = (coordinator.currentUserId, coordinator.currentUserEmail, coordinator.authToken, coordinator.isPro, coordinator.isGuestMode)
        coordinator.isGuestMode = false
        coordinator.setSession(email: "cleanup@example.com", userId: "cleanup-owner", token: "token")
        let oldQueue = coordinator.cloudDeletionQueue
        coordinator.setProForTesting(false)
        defer {
            coordinator.cloudDeletionQueue = oldQueue
            coordinator.currentUserId = previous.0; coordinator.currentUserEmail = previous.1
            coordinator.authToken = previous.2; coordinator.setProForTesting(previous.3)
            coordinator.isGuestMode = previous.4
        }
        let id = UUID().uuidString
        coordinator.cloudDeletionQueue = [id]
        let context = try context()
        let transport = MockCloudTransport()
        transport.errorToThrow = URLError(.notConnectedToInternet)
        await #expect(throws: (any Error).self) {
            _ = try await coordinator.performCloudPush(context: context, transport: transport, deletionsOnly: true)
        }
        #expect(coordinator.cloudDeletionQueue == [id])
        transport.errorToThrow = nil
        let count = try await coordinator.performCloudPush(context: context, transport: transport, deletionsOnly: true)
        #expect(count == 1)
        #expect(coordinator.cloudDeletionQueue.isEmpty)
        #expect(transport.uploads.isEmpty)
    }
    @Test func permanentDeletionReceiptOverridesNewerLocalEdits() async throws {
        let coordinator = SyncCoordinator.shared
        let previous = (coordinator.currentUserId, coordinator.currentUserEmail, coordinator.authToken, coordinator.isPro, coordinator.isGuestMode)
        coordinator.isGuestMode = false
        coordinator.setSession(email: "cleanup@example.com", userId: "cleanup-owner", token: "token")
        coordinator.setProForTesting(true)
        defer {
            coordinator.currentUserId = previous.0; coordinator.currentUserEmail = previous.1
            coordinator.authToken = previous.2; coordinator.setProForTesting(previous.3)
            coordinator.isGuestMode = previous.4
        }
        let context = try context()
        let id = UUID().uuidString
        let local = LBItem(id: id, title: "Stale photo", updatedAt: Date(timeIntervalSince1970: 3000))
        local.userId = "cleanup-owner"
        context.insert(local)
        try context.save()
        let transport = MockCloudTransport()
        transport.snapshots = [CloudItemSnapshot(id: id.lowercased(), user_id: "cleanup-owner",
            updated_at: Date(timeIntervalSince1970: 2000).ISO8601Format(),
            deleted_at: Date(timeIntervalSince1970: 2000).ISO8601Format(), permanently_deleted: true)]
        _ = try await coordinator.performCloudPull(context: context, transport: transport)
        #expect(try context.fetch(FetchDescriptor<LBItem>()).isEmpty)
    }
    @Test func attachmentDownloadReusesUppercaseDirectory() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let id = UUID().uuidString
        let existing = root.appendingPathComponent("Attachments/\(id)", isDirectory: true)
        try FileManager.default.createDirectory(at: existing, withIntermediateDirectories: true)
        let photo = existing.appendingPathComponent("photo.jpg")
        let bytes = Data([1, 2, 3])
        try bytes.write(to: photo)
        let resolved = try SharedCaptureStore.attachmentDirectory(id: id.lowercased(), root: root)
        #expect(resolved.lastPathComponent == id)
        #expect(try Data(contentsOf: resolved.appendingPathComponent("photo.jpg")) == bytes)
    }

    @Test func uploadedAttachmentDoesNotReadOrUploadMissingLocalFile() async throws {
        let asset = SharedAttachment(name: "photo.jpg", relativePath: "missing-photo.jpg", typeIdentifier: "public.jpeg",
            remoteObjectKey: "already-uploaded", byteSize: 3, sha256: String(repeating: "a", count: 64), mimeType: "image/jpeg")
        let result = try await LaterBoxAPIService.shared.uploadAttachments([asset], itemID: UUID().uuidString,
            userID: UUID().uuidString, token: "unused")
        #expect(result == [asset])
    }

    @Test func cloudUUIDCasingDoesNotCreateAnotherItem() async throws {
        let coordinator = SyncCoordinator.shared
        let previous = (coordinator.currentUserId, coordinator.currentUserEmail, coordinator.authToken, coordinator.isPro, coordinator.isGuestMode)
        coordinator.isGuestMode = false
        coordinator.setSession(email: "assets@example.com", userId: "asset-owner", token: "token")
        coordinator.setProForTesting(true)
        defer {
            coordinator.currentUserId = previous.0; coordinator.currentUserEmail = previous.1
            coordinator.authToken = previous.2; coordinator.setProForTesting(previous.3)
            coordinator.isGuestMode = previous.4
        }
        let context = try context()
        let id = UUID().uuidString
        let item = LBItem(id: id, title: "Local photo", updatedAt: Date(timeIntervalSince1970: 1000))
        item.userId = "asset-owner"
        item.isSyncPending = false
        context.insert(item)
        try context.save()
        let transport = MockCloudTransport()
        transport.snapshots = [CloudItemSnapshot(id: id.lowercased(), user_id: "asset-owner", title: "Cloud photo",
            status: "inbox", updated_at: Date(timeIntervalSince1970: 2000).ISO8601Format())]
        _ = try await coordinator.performCloudPull(context: context, transport: transport)
        let items = try context.fetch(FetchDescriptor<LBItem>())
        #expect(items.count == 1)
        #expect(items.first?.id == id)
        #expect(items.first?.title == "Cloud photo")
    }
    @Test func pullCannotAcknowledgeAnUnfinishedAttachmentUpload() async throws {
        let coordinator = SyncCoordinator.shared
        let previous = (coordinator.currentUserId, coordinator.currentUserEmail, coordinator.authToken, coordinator.isPro, coordinator.isGuestMode)
        coordinator.isGuestMode = false
        coordinator.setSession(email: "assets@example.com", userId: "asset-owner", token: "token")
        coordinator.setProForTesting(true)
        defer {
            coordinator.currentUserId = previous.0; coordinator.currentUserEmail = previous.1
            coordinator.authToken = previous.2; coordinator.setProForTesting(previous.3)
            coordinator.isGuestMode = previous.4
        }
        let context = try context()
        let date = Date(timeIntervalSince1970: 2000)
        let item = LBItem(id: "pending-photo", title: "photo.jpg", createdAt: date, updatedAt: date)
        item.userId = "asset-owner"
        let attachment = SharedAttachment(name: "photo.jpg", relativePath: "Attachments/photo.jpg", typeIdentifier: "public.jpeg")
        item.attachmentsData = try JSONEncoder().encode([attachment])
        context.insert(item)
        try context.save()
        let transport = MockCloudTransport()
        transport.snapshots = [CloudItemSnapshot(id: item.id, user_id: "asset-owner", title: item.title,
            status: "inbox", updated_at: date.ISO8601Format())]
        _ = try await coordinator.performCloudPull(context: context, transport: transport)
        #expect(item.isSyncPending)
        #expect(try JSONDecoder().decode([SharedAttachment].self, from: item.attachmentsData!) == [attachment])
        await #expect(throws: (any Error).self) {
            _ = try await coordinator.performCloudPush(context: context, transport: transport)
        }
        #expect(item.isSyncPending)
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
    @Test func refinementPreservesExactMatchesAndAddsSynonymsOnce() {
        let exact = LBItem(title: "Bicycle repair")
        let expanded = LBItem(title: "Cycle maintenance")
        let interpretation = SearchInterpretation(terms: "cycle maintenance", contentType: "", returnWindow: "")
        let results = LocalSearchController.refinedResults(interpretation, query: "bicycle", items: [exact, expanded])
        #expect(results.first?.id == exact.id)
        #expect(results.contains { $0.id == expanded.id })
        #expect(Set(results.map(\.id)).count == results.count)
    }

    @Test func refinementAppliesDateAndTypeFiltersWithoutDeletedItems() {
        let today = LBItem(title: "Focus", type: .article)
        today.returnAt = Date()
        let wrongType = LBItem(title: "Focus", type: .note)
        wrongType.returnAt = Date()
        let later = LBItem(title: "Focus", type: .article)
        later.returnAt = Date().addingTimeInterval(86400 * 3)
        let deleted = LBItem(title: "Focus", type: .article, status: .deleted)
        deleted.returnAt = Date()
        let interpretation = SearchInterpretation(terms: "", contentType: "article", returnWindow: "today")
        #expect(LocalSearchController.refinedResults(interpretation, query: "articles returning today", items: [today, wrongType, later, deleted]).map(\.id) == [today.id])
    }

    @Test func emptyInterpretationKeepsOriginalQuery() {
        let matching = LBItem(title: "Soup recipe")
        let unrelated = LBItem(title: "Quarterly budget")
        let interpretation = SearchInterpretation(terms: "", contentType: "unsupported", returnWindow: "unsupported")
        #expect(LocalSearchController.refinedResults(interpretation, query: "soup", items: [matching, unrelated]).map(\.id) == [matching.id])
    }

    @Test func weekendIsSaturdayAndDatesDecodeFractionalSeconds() throws {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let monday = try #require(ISO8601DateFormatter().date(from: "2026-10-05T12:00:00Z"))
        let saturday = CaptureDraft.weekend(now: monday, calendar: calendar)
        #expect(calendar.component(.weekday, from: saturday) == 7)
        #expect(calendar.component(.day, from: saturday) == 10)
        #expect(SyncCoordinator.cloudDate("2026-10-05T12:00:00.123Z") != nil)
    }
    @Test func deterministicAssistantRecognizesCaptureAndSearch() async throws {
        let provider = DeterministicLaterAIProvider()
        let capture = try await provider.respond("Current input:\n#work https://example.com/article")
        #expect(capture.intent == "capture")
        #expect(capture.content == "#work https://example.com/article")
        #expect(capture.tags == ["work"])
        let search = try await provider.respond("Current input:\nsearch tax returns")
        #expect(search.intent == "search")
        #expect(search.query == "tax returns")
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
        var attempts = 0
        while conversation.thinking && attempts < 200 {
            try await Task.sleep(for: .milliseconds(10))
            attempts += 1
        }
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
        var captureAttempts = 0
        while conversation.thinking && captureAttempts < 200 {
            try await Task.sleep(for: .milliseconds(10))
            captureAttempts += 1
        }
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
        let previous = (coordinator.currentUserId, coordinator.currentUserEmail, coordinator.authToken, coordinator.isProUser)
        coordinator.setProForTesting(false)
        coordinator.currentUserEmail = "free@example.com"
        coordinator.currentUserId = "free-uid"
        coordinator.authToken = "free-token"
        defer {
            coordinator.currentUserId = previous.0
            coordinator.currentUserEmail = previous.1
            coordinator.authToken = previous.2
            coordinator.setProForTesting(previous.3)
        }
        let container = try ModelContainer(for: LBItem.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let transport = MockCloudTransport()
        try await coordinator.performCloudSync(context: container.mainContext, transport: transport)
        #expect(transport.downloads == 0 && transport.uploads.isEmpty)
    }
    @Test func freeUsersCannotForceSyncPendingItems() async throws {
        let coordinator = SyncCoordinator.shared
        let previous = (coordinator.currentUserId, coordinator.currentUserEmail, coordinator.authToken, coordinator.isProUser)
        coordinator.setProForTesting(false)
        coordinator.currentUserEmail = "free@example.com"
        coordinator.currentUserId = "free-uid"
        coordinator.authToken = "free-token"
        defer {
            coordinator.currentUserId = previous.0
            coordinator.currentUserEmail = previous.1
            coordinator.authToken = previous.2
            coordinator.setProForTesting(previous.3)
        }
        let container = try ModelContainer(for: LBItem.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let transport = MockCloudTransport()
        await coordinator.syncPendingItems(context: container.mainContext, transport: transport)
        #expect(coordinator.syncState == .offline)
        #expect(transport.downloads == 0 && transport.uploads.isEmpty)
    }
    @Test func proSyncPreservesNewerLocalCaptureAndImportsRemoteMetadata() async throws {
        try await Task.sleep(for: .milliseconds(100))
        let coordinator = SyncCoordinator.shared
        let previous = (coordinator.currentUserId, coordinator.currentUserEmail, coordinator.authToken, coordinator.isProUser, coordinator.isGuestMode)
        let uid = "00000000-0000-4000-8000-000000000009"
        coordinator.currentUserId = uid; coordinator.currentUserEmail = "test@example.com"; coordinator.authToken = "test"
        coordinator.isGuestMode = false
        coordinator.setProForTesting(true)
        defer {
            coordinator.currentUserId = previous.0; coordinator.currentUserEmail = previous.1; coordinator.authToken = previous.2
            coordinator.setProForTesting(previous.3)
            coordinator.isGuestMode = previous.4
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
        let previous = (coordinator.currentUserId, coordinator.currentUserEmail, coordinator.authToken, coordinator.isProUser, coordinator.isGuestMode)
        coordinator.currentUserId = "00000000-0000-4000-8000-000000000010"; coordinator.currentUserEmail = "test@example.com"; coordinator.authToken = "test"
        coordinator.isGuestMode = false
        coordinator.setProForTesting(true)
        defer {
            coordinator.currentUserId = previous.0; coordinator.currentUserEmail = previous.1; coordinator.authToken = previous.2
            coordinator.setProForTesting(previous.3)
            coordinator.isGuestMode = previous.4
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
    @Test func clipboardManagerDismissAndConfirmLifecycle() throws {
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

        // Confirm save directly inserts into context scheduled for tomorrow return
        let container = try ModelContainer(for: LBItem.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        manager.detectedItem = payload
        manager.isShowingBanner = true

        let saved = try #require(manager.confirmSave(context: context, runBackgroundTasks: false))
        #expect(manager.isShowingBanner == false)
        #expect(manager.detectedItem == nil)
        #expect(saved.url == "https://news.ycombinator.com")
        #expect(saved.status == ItemStatus.deferred.rawValue)
        let returnAt = try #require(saved.returnAt)
        #expect(returnAt > Date())
        #expect(saved.isSyncPending == true)

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: returnAt)
        #expect(hour == 9)
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
    @Test func relativeDateParserHandlesMinutesHoursAndNaturalKeywords() {
        let reference = Date(timeIntervalSince1970: 1760000000) // Fixed reference date

        // 1. "i want this back in 10 minutes"
        let tenMin = RelativeDateParser.parse("i want this back in 10 minutes", now: reference)
        #expect(tenMin != nil)
        #expect(tenMin?.isRelative == true)
        #expect(tenMin?.intervalDescription == "10 minutes")
        #expect(abs((tenMin?.date.timeIntervalSince(reference) ?? 0) - 600) < 0.1)

        // 2. "10m"
        let shortMin = RelativeDateParser.parse("10m", now: reference)
        #expect(shortMin != nil)
        #expect(abs((shortMin?.date.timeIntervalSince(reference) ?? 0) - 600) < 0.1)

        // 3. "in 2 hours"
        let twoHours = RelativeDateParser.parse("in 2 hours", now: reference)
        #expect(twoHours != nil)
        #expect(twoHours?.intervalDescription == "2 hours")
        #expect(abs((twoHours?.date.timeIntervalSince(reference) ?? 0) - 7200) < 0.1)

        // 4. "in 30 seconds"
        let thirtySec = RelativeDateParser.parse("in 30 seconds", now: reference)
        #expect(thirtySec != nil)
        #expect(abs((thirtySec?.date.timeIntervalSince(reference) ?? 0) - 30) < 0.1)

        // 5. "in 3 days"
        let threeDays = RelativeDateParser.parse("in 3 days", now: reference)
        #expect(threeDays != nil)
        #expect(threeDays?.intervalDescription == "3 days")

        // 6. "tomorrow"
        let tomorrow = RelativeDateParser.parse("remind me tomorrow", now: reference)
        #expect(tomorrow != nil)

        // 7. Unrelated text returns nil
        let unrelated = RelativeDateParser.parse("hello there please organize this", now: reference)
        #expect(unrelated == nil)
    }

    @Test func embeddedMediaTypeDetection() {
        // YouTube
        let ytWatch = EmbeddedMediaType.detect(url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
        #expect(ytWatch == .youtube(videoId: "dQw4w9WgXcQ"))

        let ytShort = EmbeddedMediaType.detect(url: "https://youtu.be/dQw4w9WgXcQ")
        #expect(ytShort == .youtube(videoId: "dQw4w9WgXcQ"))

        let ytShorts = EmbeddedMediaType.detect(url: "https://youtube.com/shorts/dQw4w9WgXcQ")
        #expect(ytShorts == .youtube(videoId: "dQw4w9WgXcQ"))

        // Vimeo
        let vimeo = EmbeddedMediaType.detect(url: "https://vimeo.com/76979871")
        #expect(vimeo == .vimeo(videoId: "76979871"))

        // Spotify
        let spotify = EmbeddedMediaType.detect(url: "https://open.spotify.com/track/4cOdK2wGLETKBW3PvgPWqT")
        if case .spotify(let embedURL) = spotify {
            #expect(embedURL.absoluteString.contains("embed/track/4cOdK2wGLETKBW3PvgPWqT"))
        } else {
            Issue.record("Expected Spotify embed")
        }

        // Apple Music
        let apple = EmbeddedMediaType.detect(url: "https://music.apple.com/us/album/nevermind/1440783617")
        if case .appleMusic(let embedURL) = apple {
            #expect(embedURL.host == "embed.music.apple.com")
        } else {
            Issue.record("Expected Apple Music embed")
        }

        // PDF Document
        let pdf = EmbeddedMediaType.detect(url: "https://example.com/reports/document.pdf")
        if case .pdf(let url) = pdf {
            #expect(url.pathExtension == "pdf")
        } else {
            Issue.record("Expected PDF embed")
        }

        // Web Article
        let article = EmbeddedMediaType.detect(url: "https://news.ycombinator.com/item?id=123")
        if case .webArticle(let url) = article {
            #expect(url.host == "news.ycombinator.com")
        } else {
            Issue.record("Expected web article")
        }
    }

    @Test func contentFormatModeProperties() {
        #expect(ContentFormatMode.formatted.rawValue == "Formatted")
        #expect(ContentFormatMode.html.rawValue == "HTML")
        #expect(ContentFormatMode.raw.rawValue == "Raw")
        #expect(!ContentFormatMode.formatted.icon.isEmpty)
        #expect(!ContentFormatMode.html.icon.isEmpty)
        #expect(!ContentFormatMode.raw.icon.isEmpty)
    }

    @Test func duplicateDetectionAndStorageBreakdown() throws {
        // 1. Storage Breakdown
        let breakdown = StorageBreakdown(databaseBytes: 10_000_000, attachmentsBytes: 5_000_000, cacheBytes: 5_000_000)
        #expect(breakdown.totalBytes == 20_000_000)
        #expect(!breakdown.formattedTotal.isEmpty)
        #expect(breakdown.databasePercentage == 0.5)
        #expect(breakdown.attachmentsPercentage == 0.25)
        #expect(breakdown.cachePercentage == 0.25)

        // 2. Duplicate Detection by URL
        let item1 = LBItem(id: "1", url: "https://example.com/article", title: "Article 1", createdAt: Date(timeIntervalSince1970: 1000))
        let item2 = LBItem(id: "2", url: "https://example.com/article/", title: "Article 1 Duplicate", createdAt: Date(timeIntervalSince1970: 2000))
        let item3 = LBItem(id: "3", url: "https://example.com/other", title: "Other Article", createdAt: Date(timeIntervalSince1970: 3000))

        let groups = LocalStorageManager.findDuplicates(in: [item1, item2, item3])
        #expect(groups.count == 1)
        #expect(groups[0].primaryItem.id == "2") // Newer item is primary
        #expect(groups[0].duplicates.count == 1)
        #expect(groups[0].duplicates[0].id == "1")

        // 3. Excludes deleted items
        let deletedItem = LBItem(id: "4", url: "https://example.com/other", title: "Other Article Deleted", status: .deleted)
        let groupsWithDeleted = LocalStorageManager.findDuplicates(in: [item3, deletedItem])
        #expect(groupsWithDeleted.isEmpty)

        // 4. Duplicate Detection by Title (non-URL)
        let note1 = LBItem(id: "5", title: "Meeting Notes", createdAt: Date(timeIntervalSince1970: 100))
        let note2 = LBItem(id: "6", title: "meeting notes", createdAt: Date(timeIntervalSince1970: 200))
        let noteGroups = LocalStorageManager.findDuplicates(in: [note1, note2])
        #expect(noteGroups.count == 1)
        #expect(noteGroups[0].primaryItem.id == "6")
    }

    @Test
    func appVersionResolutionAndFormatting() {
        #expect(!AppVersion.currentVersion.isEmpty)
        #expect(!AppVersion.currentBuild.isEmpty)
        #expect(AppVersion.displayString.hasPrefix("Version "))
        #expect(AppVersion.displayString.contains("(Build "))
        #expect(AppVersion.displayString.contains(AppVersion.currentVersion))
        #expect(AppVersion.displayString.contains(AppVersion.currentBuild))
        #expect(!AppVersion.marketingVersion.isEmpty)
        #expect(!AppVersion.buildNumber.isEmpty)
    }

    @Test
    func appIconOptionsAndManagerDefaults() {
        let icons = AppIconManager.availableIcons
        #expect(icons.count == 12)

        // Default icon has nil iconName (system primary)
        let defaultIcon = icons.first(where: { $0.id == "default" })
        #expect(defaultIcon != nil)
        #expect(defaultIcon?.iconName == nil)
        #expect(defaultIcon?.isDefault == true)
        #expect(defaultIcon?.category == "Signature")

        // Alternate icons have valid names and categories
        let darkIcon = icons.first(where: { $0.id == "dark" })
        #expect(darkIcon?.iconName == "AppIcon-Dark")

        let emeraldIcon = icons.first(where: { $0.id == "emerald" })
        #expect(emeraldIcon?.iconName == "AppIcon-Emerald")

        let arcadeIcon = icons.first(where: { $0.id == "arcade" })
        #expect(arcadeIcon?.iconName == "AppIcon-Arcade")
        #expect(arcadeIcon?.category == "Gaming")

        let animeIcon = icons.first(where: { $0.id == "anime" })
        #expect(animeIcon?.iconName == "AppIcon-Anime")
        #expect(animeIcon?.category == "Anime")

        let horrorIcon = icons.first(where: { $0.id == "horror" })
        #expect(horrorIcon?.iconName == "AppIcon-Horror")
        #expect(horrorIcon?.category == "Horror")

        let gadgetIcon = icons.first(where: { $0.id == "gadget" })
        #expect(gadgetIcon?.iconName == "AppIcon-Gadget")
        #expect(gadgetIcon?.category == "Gadgets")

        let animationIcon = icons.first(where: { $0.id == "animation" })
        #expect(animationIcon?.iconName == "AppIcon-Animation")
        #expect(animationIcon?.category == "Animation")

        let terminalIcon = icons.first(where: { $0.id == "terminal" })
        #expect(terminalIcon?.iconName == "AppIcon-Terminal")
        #expect(terminalIcon?.category == "Tech & Geek")

        for icon in icons {
            #expect(!icon.name.isEmpty)
            #expect(!icon.previewImageName.isEmpty)
            #expect(!icon.subtitle.isEmpty)
            #expect(!icon.description.isEmpty)
            #expect(!icon.accentHex.isEmpty)
            #expect(!icon.badgeText.isEmpty)
            #expect(!icon.category.isEmpty)
        }

        #expect(AppIconManager.categories.contains("All"))
        #expect(AppIconManager.categories.contains("Gaming"))
        #expect(AppIconManager.categories.contains("Anime"))
        #expect(AppIconManager.categories.contains("Horror"))
        #expect(AppIconManager.categories.contains("Gadgets"))
        #expect(AppIconManager.categories.contains("Animation"))
        #expect(AppIconManager.categories.contains("Tech & Geek"))

        let manager = AppIconManager.shared
        #expect(!manager.currentIconId.isEmpty)
        #expect(!manager.currentIconOption.name.isEmpty)
    }

    @Test
    func loginDataResolutionMergesLocalItemsAndHydratesCloud() async throws {
        let coordinator = SyncCoordinator.shared
        let originalSession = (coordinator.currentUserEmail, coordinator.currentUserId, coordinator.authToken)
        defer {
            coordinator.currentUserEmail = originalSession.0
            coordinator.currentUserId = originalSession.1
            coordinator.authToken = originalSession.2
        }

        let container = try ModelContainer(for: LBItem.self, LBCollection.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext

        let guestItem = LBItem(title: "Local Guest Capture", textContent: "Offline notes")
        guestItem.userId = nil
        context.insert(guestItem)
        try context.save()

        let testUID = "user-login-test-123"
        #expect(coordinator.countUnassignedLocalItems(context: context, targetUserId: testUID) == 1)

        let transport = MockCloudTransport()
        let remoteID = "remote-cloud-item-999"
        transport.snapshots = [
            CloudItemSnapshot(
                id: remoteID,
                user_id: testUID,
                url: "https://example.com/article",
                title: "Cloud Synced Article",
                type: "link",
                favorite: true,
                status: "inbox",
                created_at: "2026-10-01T10:00:00Z",
                updated_at: "2026-10-01T10:00:00Z",
                item_metadata: CloudMetadata(
                    domain: "example.com",
                    site_name: "Example",
                    description: "An article from web",
                    status: "enriched",
                    structured_data: CloudClassification(tags: ["web", "reading"], category: "Tech", summary: "Article summary")
                ),
                collection_items: [
                    CloudMembership(collection_id: "c1", collections: CloudCollection(id: "c1", name: "Tech"))
                ]
            )
        ]

        try await coordinator.resolveLoginData(
            merge: true,
            email: "testuser@example.com",
            userId: testUID,
            token: "mock-token",
            context: context,
            transport: transport
        )

        #expect(coordinator.currentUserEmail == "testuser@example.com")
        #expect(coordinator.currentUserId == testUID)
        #expect(coordinator.syncState == .synced)
        #expect(coordinator.lastSyncedAt != nil)

        // Verify local guest item merged to current user
        #expect(guestItem.userId == testUID)
        #expect(guestItem.isSyncPending == true)
        #expect(coordinator.countUnassignedLocalItems(context: context, targetUserId: testUID) == 0)

        // Verify remote item hydrated into catalog
        let allItems = try context.fetch(FetchDescriptor<LBItem>())
        #expect(allItems.count == 2)
        let remoteItem = try #require(allItems.first { $0.id == remoteID })
        #expect(remoteItem.title == "Cloud Synced Article")
        #expect(remoteItem.url == "https://example.com/article")
        #expect(remoteItem.tags == ["web", "reading"])
        #expect(remoteItem.category == "Tech")
        #expect(remoteItem.favorite == true)

        // Verify collection auto-created
        let allCollections = try context.fetch(FetchDescriptor<LBCollection>())
        #expect(allCollections.contains { $0.name == "Tech" })
    }

    @Test
    func loginDataResolutionDiscardsLocalItemsAndHydratesCloud() async throws {
        let coordinator = SyncCoordinator.shared
        let originalSession = (coordinator.currentUserEmail, coordinator.currentUserId, coordinator.authToken)
        defer {
            coordinator.currentUserEmail = originalSession.0
            coordinator.currentUserId = originalSession.1
            coordinator.authToken = originalSession.2
        }

        let container = try ModelContainer(for: LBItem.self, LBCollection.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext

        let guestItem = LBItem(title: "Ephemeral Guest Capture", textContent: "To be removed")
        guestItem.userId = nil
        context.insert(guestItem)
        try context.save()

        let testUID = "user-login-test-456"
        #expect(coordinator.countUnassignedLocalItems(context: context, targetUserId: testUID) == 1)

        let transport = MockCloudTransport()
        let remoteID = "remote-cloud-item-777"
        transport.snapshots = [
            CloudItemSnapshot(
                id: remoteID,
                user_id: testUID,
                title: "My Cloud Note",
                text_content: "Saved in web dashboard",
                type: "note",
                favorite: false,
                status: "inbox",
                created_at: "2026-10-02T12:00:00Z",
                updated_at: "2026-10-02T12:00:00Z"
            )
        ]

        try await coordinator.resolveLoginData(
            merge: false,
            email: "testuser2@example.com",
            userId: testUID,
            token: "mock-token-2",
            context: context,
            transport: transport
        )

        #expect(coordinator.currentUserEmail == "testuser2@example.com")
        #expect(coordinator.currentUserId == testUID)
        #expect(coordinator.syncState == .synced)

        // Verify guest item was removed
        let allItems = try context.fetch(FetchDescriptor<LBItem>())
        #expect(allItems.count == 1)
        #expect(allItems.first?.id == remoteID)
        #expect(allItems.first?.title == "My Cloud Note")
        #expect(coordinator.countUnassignedLocalItems(context: context, targetUserId: testUID) == 0)
    }

    @Test
    func exitGuestClearsLocalGuestItemsAndResetsSession() throws {
        let coordinator = SyncCoordinator.shared
        coordinator.continueAsGuest()
        #expect(coordinator.isGuestMode == true)

        let container = try ModelContainer(for: LBItem.self, LBCollection.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext

        let guestItem = LBItem(title: "Ephemeral Guest Item", textContent: "Temporary notes")
        guestItem.userId = nil
        context.insert(guestItem)

        let guestCollection = LBCollection(name: "Guest Scratchpad")
        guestCollection.userId = nil
        context.insert(guestCollection)
        try context.save()

        #expect(coordinator.countUnassignedLocalItems(context: context) == 1)

        coordinator.exitGuest(context: context)

        #expect(coordinator.isGuestMode == false)
        #expect(coordinator.hasAccess == false)

        let remainingItems = try context.fetch(FetchDescriptor<LBItem>())
        #expect(remainingItems.isEmpty)
        let remainingCollections = try context.fetch(FetchDescriptor<LBCollection>())
        #expect(remainingCollections.isEmpty)
    }

    @Test func appIconSelectionRestrictedToProPlan() async {
        let coordinator = SyncCoordinator.shared
        let iconManager = AppIconManager.shared

        let prevPro = coordinator.isProUser
        defer { coordinator.setProForTesting(prevPro) }

        // Set to Free (non-Pro)
        coordinator.setProForTesting(false)
        #expect(coordinator.isProUser == false)

        let alternateOption = try! #require(AppIconManager.availableIcons.first(where: { $0.id == "dark" }))
        #expect(alternateOption.isProOnly == true)

        let defaultOption = try! #require(AppIconManager.availableIcons.first(where: { $0.id == "default" }))
        #expect(defaultOption.isProOnly == false)

        // Attempting to select alternate icon without Pro fails
        let successNonPro = await iconManager.selectIcon(alternateOption)
        #expect(successNonPro == false)
        #expect(iconManager.errorMessage?.contains("Pro") == true)

        // Default icon is never blocked by Pro gating
        #expect(defaultOption.isProOnly == false)

        // Restoring Pro allows alternate selection attempts
        coordinator.setProForTesting(true)
        #expect(coordinator.isProUser == true)

        // Clean up
        coordinator.setProForTesting(false)
    }

    @Test func aiModelManagerUsesLocalMode() async throws {
        let modelManager = LaterAIModelManager.shared
        #expect(modelManager.selectedProvider == .local)
        #expect(modelManager.activeModelName == "Local assistant")
        #expect(modelManager.activeProvider() is DeterministicLaterAIProvider)
        let refined = try? await modelManager.interpretSearch("recipes for lentil soup")
        #expect(refined?.terms == "recipes for lentil soup")
        #expect(refined?.contentType.isEmpty == true)
    }

    @Test
    func syncConflictEqualTimestampDeleteWins() async throws {
        let coordinator = SyncCoordinator.shared
        let previous = (coordinator.currentUserId, coordinator.currentUserEmail, coordinator.authToken, coordinator.isProUser)
        let uid = "user-conflict-test-001"
        coordinator.currentUserId = uid
        coordinator.currentUserEmail = "user@test.com"
        coordinator.authToken = "tok"
        coordinator.setProForTesting(true)
        defer {
            coordinator.currentUserId = previous.0
            coordinator.currentUserEmail = previous.1
            coordinator.authToken = previous.2
            coordinator.setProForTesting(previous.3)
        }

        let container = try ModelContainer(for: LBItem.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext

        let timestampString = "2026-10-10T12:00:00Z"
        let timestamp = SyncCoordinator.cloudDate(timestampString)!

        // Case A: Local is active, remote is deleted with SAME timestamp -> remote delete wins
        let itemA = LBItem(id: "item-a", title: "Active local", updatedAt: timestamp)
        itemA.status = "inbox"
        itemA.userId = uid
        context.insert(itemA)

        // Case B: Local is deleted, remote is active with SAME timestamp -> local delete wins (preserved)
        let itemB = LBItem(id: "item-b", title: "Deleted local", updatedAt: timestamp)
        itemB.status = "deleted"
        itemB.userId = uid
        context.insert(itemB)
        try context.save()

        let transport = MockCloudTransport()
        transport.snapshots = [
            CloudItemSnapshot(id: "item-a", user_id: uid, title: "Active local", status: "deleted", updated_at: timestampString, deleted_at: timestampString),
            CloudItemSnapshot(id: "item-b", user_id: uid, title: "Active remote", status: "inbox", updated_at: timestampString, deleted_at: nil)
        ]

        try await coordinator.performCloudSync(context: context, transport: transport)

        // Item A should have taken the remote deletion
        #expect(itemA.status == "deleted")

        // Item B should have preserved local deletion
        #expect(itemB.status == "deleted")
    }

    @Test
    func syncReportsSpecificErrorDiagnostics() async throws {
        let coordinator = SyncCoordinator.shared
        let previous = (coordinator.currentUserId, coordinator.currentUserEmail, coordinator.authToken, coordinator.isProUser)
        let uid = "user-err-test-002"
        coordinator.currentUserId = uid
        coordinator.currentUserEmail = "user@test.com"
        coordinator.authToken = "tok"
        coordinator.setProForTesting(true)
        defer {
            coordinator.currentUserId = previous.0
            coordinator.currentUserEmail = previous.1
            coordinator.authToken = previous.2
            coordinator.setProForTesting(previous.3)
        }

        let container = try ModelContainer(for: LBItem.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext

        // 1. Unauthorized / Session Expired
        let authTransport = MockCloudTransport()
        authTransport.errorToThrow = CloudSyncError.unauthorized(message: "JWT expired")
        await coordinator.syncPendingItems(context: context, transport: authTransport)
        #expect(coordinator.syncState == .error)
        #expect(coordinator.lastSyncErrorMessage?.contains("JWT expired") == true)

        // 2. Server Error with Status Code
        let serverTransport = MockCloudTransport()
        serverTransport.errorToThrow = CloudSyncError.serverError(statusCode: 503, message: "Gateway Timeout")
        await coordinator.syncPendingItems(context: context, transport: serverTransport)
        #expect(coordinator.syncState == .error)
        #expect(coordinator.lastSyncErrorMessage?.contains("503") == true)
        #expect(coordinator.lastSyncErrorMessage?.contains("Gateway Timeout") == true)

        // 3. Network Offline URLError
        let networkTransport = MockCloudTransport()
        networkTransport.errorToThrow = URLError(.notConnectedToInternet)
        await coordinator.syncPendingItems(context: context, transport: networkTransport)
        #expect(coordinator.syncState == .error)
        #expect(coordinator.lastSyncErrorMessage?.contains("No internet connection") == true)
    }

    @Test
    func markItemSeenAppliesOnlyToInboxItems() throws {
        let coordinator = SyncCoordinator.shared
        let container = try ModelContainer(for: LBItem.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext

        let inboxItem = LBItem(id: "inbox-item-1", title: "Inbox Item", status: .inbox)
        #expect(inboxItem.seen == false)
        context.insert(inboxItem)

        let deferredItem = LBItem(id: "deferred-item-1", title: "Scheduled Item", status: .deferred)
        #expect(deferredItem.seen == false)
        context.insert(deferredItem)

        let savedItem = LBItem(id: "saved-item-1", title: "Kept Item", status: .saved)
        #expect(savedItem.seen == false)
        context.insert(savedItem)

        try context.save()

        // 1. Inbox item gets marked seen
        coordinator.markItemSeen(item: inboxItem, context: context)
        #expect(inboxItem.seen == true)
        #expect(inboxItem.isSyncPending == true)

        // 2. Non-inbox items remain unseen
        coordinator.markItemSeen(item: deferredItem, context: context)
        #expect(deferredItem.seen == false)

        coordinator.markItemSeen(item: savedItem, context: context)
        #expect(savedItem.seen == false)
    }

    @Test func syncFetchPullFiltersOutDeletedMembershipsAndHydratesActiveCollection() async throws {
        try await Task.sleep(for: .milliseconds(50))
        let coordinator = SyncCoordinator.shared
        let prev = (coordinator.currentUserId, coordinator.currentUserEmail, coordinator.authToken, coordinator.isProUser, coordinator.isGuestMode)
        let uid = "00000000-0000-4000-8000-000000000055"
        coordinator.currentUserId = uid; coordinator.currentUserEmail = "user@test.com"; coordinator.authToken = "tok"
        coordinator.isGuestMode = false
        coordinator.setProForTesting(true)
        defer {
            coordinator.currentUserId = prev.0; coordinator.currentUserEmail = prev.1; coordinator.authToken = prev.2
            coordinator.setProForTesting(prev.3)
            coordinator.isGuestMode = prev.4
        }

        let container = try ModelContainer(for: LBItem.self, LBCollection.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext

        let transport = MockCloudTransport()
        let activeItemId = UUID().uuidString
        let deletedItemId = UUID().uuidString

        transport.snapshots = [
            CloudItemSnapshot(
                id: activeItemId,
                user_id: uid,
                title: "Active Collection Item",
                status: "inbox",
                created_at: "2026-10-17T00:00:00Z",
                updated_at: "2026-10-17T00:00:00Z",
                collection_items: [
                    CloudMembership(collection_id: "c-old", deleted_at: "2026-10-16T00:00:00Z", collections: CloudCollection(id: "c-old", name: "Old Trash")),
                    CloudMembership(collection_id: "c-new", deleted_at: nil, collections: CloudCollection(id: "c-new", name: "Reading List"))
                ]
            ),
            CloudItemSnapshot(
                id: deletedItemId,
                user_id: uid,
                title: "Removed Collection Item",
                status: "inbox",
                created_at: "2026-10-17T00:00:00Z",
                updated_at: "2026-10-17T00:00:00Z",
                collection_items: [
                    CloudMembership(collection_id: "c-deleted", deleted_at: "2026-10-16T12:00:00Z", collections: CloudCollection(id: "c-deleted", name: "Archived Group"))
                ]
            )
        ]

        try await coordinator.performCloudSync(context: context, transport: transport)

        let items = try context.fetch(FetchDescriptor<LBItem>())
        let active = try #require(items.first { $0.id == activeItemId })
        #expect(active.collectionId == "c-new")
        #expect(active.collectionName == "Reading List")

        let removed = try #require(items.first { $0.id == deletedItemId })
        #expect(removed.collectionId == nil)
        #expect(removed.collectionName == nil)

        let collections = try context.fetch(FetchDescriptor<LBCollection>())
        #expect(collections.contains { $0.name == "Reading List" })
        #expect(!collections.contains { $0.name == "Archived Group" })
    }

    @Test func syncUploadPopulatesUserIdForCollection() async throws {
        try await Task.sleep(for: .milliseconds(50))
        let coordinator = SyncCoordinator.shared
        let prev = (coordinator.currentUserId, coordinator.currentUserEmail, coordinator.authToken, coordinator.isProUser, coordinator.isGuestMode)
        let uid = "00000000-0000-4000-8000-000000000066"
        coordinator.currentUserId = uid; coordinator.currentUserEmail = "user66@test.com"; coordinator.authToken = "tok66"
        coordinator.isGuestMode = false
        coordinator.setProForTesting(true)
        defer {
            coordinator.currentUserId = prev.0; coordinator.currentUserEmail = prev.1; coordinator.authToken = prev.2
            coordinator.setProForTesting(prev.3)
            coordinator.isGuestMode = prev.4
        }

        let container = try ModelContainer(for: LBItem.self, LBCollection.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext

        let item = LBItem(title: "Item In Collection", status: .inbox)
        item.collectionName = "Productivity"
        item.userId = uid
        context.insert(item)
        try context.save()

        let transport = MockCloudTransport()
        try await coordinator.performCloudSync(context: context, transport: transport)

        #expect(transport.uploadedCollections.count == 1)
        let coll = try #require(transport.uploadedCollections.first)
        #expect(coll["user_id"] as? String == uid)
        #expect(coll["name"] as? String == "Productivity")
        #expect(coll["id"] as? String != nil)
    }

    @Test func separatePullAndPushOperationsResolveRecentLocalAndRemoteActions() async throws {
        try await Task.sleep(for: .milliseconds(50))
        let coordinator = SyncCoordinator.shared
        let prev = (coordinator.currentUserId, coordinator.currentUserEmail, coordinator.authToken, coordinator.isProUser, coordinator.isGuestMode)
        let uid = "00000000-0000-4000-8000-000000000077"
        coordinator.currentUserId = uid; coordinator.currentUserEmail = "user77@test.com"; coordinator.authToken = "tok77"
        coordinator.isGuestMode = false
        coordinator.setProForTesting(true)
        defer {
            coordinator.currentUserId = prev.0; coordinator.currentUserEmail = prev.1; coordinator.authToken = prev.2
            coordinator.setProForTesting(prev.3)
            coordinator.isGuestMode = prev.4
        }

        let container = try ModelContainer(for: LBItem.self, LBCollection.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext

        let t1 = Date(timeIntervalSince1970: 1000)
        let t2 = Date(timeIntervalSince1970: 2000)

        // Item A: Locally deleted at t2 (newer than cloud update at t1)
        let itemA = LBItem(id: "item-a", title: "Item A Local Delete", status: .deleted, updatedAt: t2)
        itemA.userId = uid
        itemA.isSyncPending = true

        // Item B: Locally created at t1 (older than cloud update at t2)
        let itemB = LBItem(id: "item-b", title: "Item B Local Old", status: .inbox, updatedAt: t1)
        itemB.userId = uid
        itemB.isSyncPending = true

        context.insert(itemA)
        context.insert(itemB)
        try context.save()

        let transport = MockCloudTransport()
        transport.snapshots = [
            CloudItemSnapshot(id: "item-a", user_id: uid, title: "Item A Stale Active", status: "inbox", created_at: "1970-01-01T00:00:01Z", updated_at: t1.ISO8601Format()),
            CloudItemSnapshot(id: "item-b", user_id: uid, title: "Item B Remote Updated", status: "inbox", created_at: "1970-01-01T00:00:01Z", updated_at: t2.ISO8601Format())
        ]

        // 1. Pull changes only
        await coordinator.pullChanges(context: context, transport: transport)

        // Item A: local delete was newer than cloud -> local delete preserved, pending push
        #expect(itemA.status == "deleted")
        #expect(itemA.isSyncPending == true)

        // Item B: remote was newer than local -> remote update won, no longer pending
        #expect(itemB.title == "Item B Remote Updated")
        #expect(itemB.isSyncPending == false)

        // 2. Push changes only
        await coordinator.pushChanges(context: context, transport: transport)
        #expect(transport.uploads.count == 1)
        #expect(transport.uploads.first?["id"] as? String == "item-a")
        #expect(transport.uploads.first?["status"] as? String == "deleted")
        #expect(itemA.isSyncPending == false)
    }

    @Test func checkRemoteChangesComputesPendingPullCount() async throws {
        try await Task.sleep(for: .milliseconds(50))
        let coordinator = SyncCoordinator.shared
        let prev = (coordinator.currentUserId, coordinator.currentUserEmail, coordinator.authToken, coordinator.isProUser, coordinator.isGuestMode)
        let uid = "00000000-0000-4000-8000-000000000088"
        coordinator.currentUserId = uid; coordinator.currentUserEmail = "user88@test.com"; coordinator.authToken = "tok88"
        coordinator.isGuestMode = false
        coordinator.setProForTesting(true)
        defer {
            coordinator.currentUserId = prev.0; coordinator.currentUserEmail = prev.1; coordinator.authToken = prev.2
            coordinator.setProForTesting(prev.3)
            coordinator.isGuestMode = prev.4
        }

        let container = try ModelContainer(for: LBItem.self, LBCollection.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext

        let existing = LBItem(id: "item-existing", title: "Existing", updatedAt: Date(timeIntervalSince1970: 1000))
        existing.userId = uid
        context.insert(existing)
        try context.save()

        let manifestJSON = """
        [
            {"id": "item-existing", "updated_at": "1970-01-01T01:00:00Z", "deleted_at": null},
            {"id": "item-brand-new", "updated_at": "1970-01-01T01:00:00Z", "deleted_at": null}
        ]
        """.data(using: .utf8)!

        let transport = MockCloudTransport()
        transport.manifestData = manifestJSON

        let available = await coordinator.checkRemoteChanges(context: context, transport: transport)
        #expect(available == 2)
        #expect(coordinator.pendingPullCount == 2)
    }

    @Test
    func cloudSyncErrorFormattingForJWTExpired() {
        let err1 = CloudSyncError.unauthorized(message: "JWT expired")
        #expect(err1.localizedDescription == "Session expired (JWT expired). Please sign in again to continue syncing.")

        let err2 = CloudSyncError.unauthorized(message: "token expired")
        #expect(err2.localizedDescription == "Session expired (JWT expired). Please sign in again to continue syncing.")

        let err3 = CloudSyncError.unauthorized(message: "Missing authorization header")
        #expect(err3.localizedDescription == "Authentication error: Missing authorization header")
    }

    @Test
    func sessionExpirationTrackingAndRefreshAuthSession() async throws {
        let coordinator = SyncCoordinator.shared
        coordinator.signOut()

        #expect(coordinator.sessionExpired == false)
        #expect(coordinator.refreshToken == nil)

        // refreshAuthSession should return false when no refresh token is stored
        let refreshed = await coordinator.refreshAuthSession()
        #expect(refreshed == false)

        coordinator.setSession(
            email: "refresh-test@example.com",
            userId: "uid-refresh-1",
            token: "initial-access-token",
            refreshToken: "initial-refresh-token"
        )

        #expect(coordinator.refreshToken == "initial-refresh-token")
        #expect(coordinator.sessionExpired == false)

        // When pull receives unauthorized with no network mock, sessionExpired becomes true
        let container = try ModelContainer(for: LBItem.self, LBCollection.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        coordinator.setProForTesting(true)

        let transport = MockCloudTransport()
        transport.errorToThrow = CloudSyncError.unauthorized(message: "JWT expired")

        await coordinator.pullChanges(context: context, transport: transport)
        #expect(coordinator.syncState == .error)
        #expect(coordinator.sessionExpired == true)
        #expect(coordinator.lastSyncErrorMessage?.contains("Session expired") == true)

        // Re-authenticating resets sessionExpired
        coordinator.setSession(
            email: "refresh-test@example.com",
            userId: "uid-refresh-1",
            token: "new-access-token",
            refreshToken: "new-refresh-token"
        )
        #expect(coordinator.sessionExpired == false)
        #expect(coordinator.refreshToken == "new-refresh-token")
    }

    @Test
    func entitlementRefreshAndRetryTracking() async throws {
        let coordinator = SyncCoordinator.shared
        coordinator.signOut()

        // Unauthenticated coordinator returns false
        let unauthResult = await coordinator.refreshEntitlement()
        #expect(unauthResult == false)
        #expect(coordinator.billingError == nil)

        // Set session
        coordinator.setSession(
            email: "entitlement-test@example.com",
            userId: "uid-entitle-1",
            token: "mock-expired-token",
            refreshToken: "mock-expired-refresh"
        )

        // Allow any initial background tasks from setSession to settle
        try? await Task.sleep(nanoseconds: 300_000_000)

        let result = await coordinator.refreshEntitlement()
        #expect(coordinator.isCheckingEntitlement == false)
        #expect(result == false)
        #expect(coordinator.billingError != nil)
        #expect(coordinator.sessionExpired == true)

        // Sign out resets billingError
        coordinator.signOut()
        #expect(coordinator.billingError == nil)
        #expect(coordinator.sessionExpired == false)
    }

    @Test
    func urlNormalizationAndDisplayDeduplication() {
        let n1 = LBItem.normalizeURL("https://www.Example.COM/article/?utm_source=twitter&ref=share#section")
        #expect(n1 == "example.com/article")

        let n2 = LBItem.normalizeURL("http://example.com/article")
        #expect(n2 == "example.com/article")

        let t1 = Date(timeIntervalSince1970: 1000)
        let t2 = Date(timeIntervalSince1970: 2000)

        // Local item with pending sync vs up to date synced cloud copy
        let localItem = LBItem(id: "local-1", url: "https://example.com/post", title: "Local Draft", createdAt: t1, updatedAt: t1)
        localItem.isSyncPending = true

        let syncedItem = LBItem(id: "cloud-1", url: "https://www.example.com/post/", title: "Synced Version", createdAt: t1, updatedAt: t2)
        syncedItem.isSyncPending = false

        let items = [localItem, syncedItem]
        let displayList = items.deduplicatedForDisplay()

        // Should show only ONE version, preferring the up to date synced version
        #expect(displayList.count == 1)
        #expect(displayList.first?.id == "cloud-1")
        #expect(displayList.first?.title == "Synced Version")
    }

    @Test
    func cloudPullMatchesLocalItemByURLAndReconcilesWithoutDuplicates() async throws {
        let coordinator = SyncCoordinator.shared
        let prev = (coordinator.currentUserId, coordinator.currentUserEmail, coordinator.authToken, coordinator.isProUser, coordinator.isGuestMode)
        let uid = "00000000-0000-4000-8000-000000000099"
        coordinator.currentUserId = uid; coordinator.currentUserEmail = "user99@test.com"; coordinator.authToken = "tok99"
        coordinator.isGuestMode = false
        coordinator.setProForTesting(true)
        defer {
            coordinator.currentUserId = prev.0; coordinator.currentUserEmail = prev.1; coordinator.authToken = prev.2
            coordinator.setProForTesting(prev.3)
            coordinator.isGuestMode = prev.4
        }

        let container = try ModelContainer(for: LBItem.self, LBCollection.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext

        let tOld = Date(timeIntervalSince1970: 1000)
        let tNew = Date(timeIntervalSince1970: 2000)

        // Item captured locally before syncing to cloud (has local UUID)
        let localPreSync = LBItem(id: "local-orig-uuid", url: "https://laterbox.app/guide", title: "Local Title", createdAt: tOld, updatedAt: tOld)
        localPreSync.userId = uid
        localPreSync.isSyncPending = true
        context.insert(localPreSync)
        try context.save()

        // Remote snapshot from cloud (has cloud UUID, same URL, newer updatedAt)
        let transport = MockCloudTransport()
        transport.snapshots = [
            CloudItemSnapshot(
                id: "cloud-remote-uuid",
                user_id: uid,
                url: "https://www.laterbox.app/guide/",
                title: "Updated Cloud Guide",
                status: "inbox",
                created_at: tOld.ISO8601Format(),
                updated_at: tNew.ISO8601Format()
            )
        ]

        let applied = try await coordinator.performCloudPull(context: context, transport: transport)
        #expect(applied == 1)

        let allLocal = try context.fetch(FetchDescriptor<LBItem>())
        // Verified: only one local item exists in SwiftData for this URL, reconciled with cloud UUID
        #expect(allLocal.count == 1)
        let reconciled = allLocal.first!
        #expect(reconciled.id == "cloud-remote-uuid")
        #expect(reconciled.title == "Updated Cloud Guide")
        #expect(reconciled.isSyncPending == false)
    }

    @Test
    func cloudPullSavesCloudVersionLocallyForOfflineViewing() async throws {
        let coordinator = SyncCoordinator.shared
        let prev = (coordinator.currentUserId, coordinator.currentUserEmail, coordinator.authToken, coordinator.isProUser, coordinator.isGuestMode)
        let uid = "00000000-0000-4000-8000-000000000077"
        coordinator.currentUserId = uid; coordinator.currentUserEmail = "user77@test.com"; coordinator.authToken = "tok77"
        coordinator.isGuestMode = false
        coordinator.setProForTesting(true)
        defer {
            coordinator.currentUserId = prev.0; coordinator.currentUserEmail = prev.1; coordinator.authToken = prev.2
            coordinator.setProForTesting(prev.3)
            coordinator.isGuestMode = prev.4
        }

        let container = try ModelContainer(for: LBItem.self, LBCollection.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext

        // Empty local storage initially
        let initialItems = try context.fetch(FetchDescriptor<LBItem>())
        #expect(initialItems.isEmpty)

        let tRemote = Date(timeIntervalSince1970: 5000)
        let transport = MockCloudTransport()
        transport.snapshots = [
            CloudItemSnapshot(
                id: "cloud-item-offline",
                user_id: uid,
                url: "https://docs.swift.org/swift-book",
                title: "The Swift Programming Language",
                text_content: "Swift is a general-purpose programming language...",
                type: "link",
                favorite: true,
                status: "inbox",
                created_at: tRemote.ISO8601Format(),
                updated_at: tRemote.ISO8601Format(),
                item_metadata: CloudMetadata(
                    domain: "docs.swift.org",
                    site_name: "Swift.org",
                    description: "Official Swift Language Documentation",
                    favicon_url: "https://docs.swift.org/favicon.ico",
                    preview_image_url: nil,
                    status: "completed",
                    structured_data: CloudClassification(
                        tags: ["swift", "ios", "dev"],
                        category: "Engineering",
                        summary: "Complete reference for Swift language features",
                        formattedContent: "",
                        seen: false
                    )
                )
            )
        ]

        let applied = try await coordinator.performCloudPull(context: context, transport: transport)
        #expect(applied == 1)

        // After pull, the item is persisted locally in SwiftData for full offline viewing
        let savedLocally = try context.fetch(FetchDescriptor<LBItem>())
        #expect(savedLocally.count == 1)
        let item = savedLocally.first!
        #expect(item.id == "cloud-item-offline")
        #expect(item.title == "The Swift Programming Language")
        #expect(item.textContent?.contains("general-purpose") == true)
        #expect(item.domain == "docs.swift.org")
        #expect(item.tags == ["swift", "ios", "dev"])
        #expect(item.category == "Engineering")
        #expect(item.isSyncPending == false)
    }

    @Test
    func cleanupDuplicatesInStoreMergesDataAndRemovesRedundantRows() throws {
        let container = try ModelContainer(for: LBItem.self, LBCollection.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext

        let t1 = Date(timeIntervalSince1970: 1000)
        let t2 = Date(timeIntervalSince1970: 2000)

        // Local copy created offline with custom note
        let local1 = LBItem(id: "item-dup-1", url: "https://developer.apple.com/swift/", title: "Swift Guide (Draft)", createdAt: t1, updatedAt: t1)
        local1.noteContent = "Important note to keep"
        local1.tags = ["local-tag"]
        local1.isSyncPending = true

        // Synced cloud copy pulled down
        let local2 = LBItem(id: "item-dup-2", url: "https://developer.apple.com/swift", title: "Swift Guide (Official)", createdAt: t1, updatedAt: t2)
        local2.tags = ["official"]
        local2.isSyncPending = false

        context.insert(local1)
        context.insert(local2)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<LBItem>()).count == 2)

        LBItem.cleanupDuplicatesInStore(context: context)
        try context.save()

        let remaining = try context.fetch(FetchDescriptor<LBItem>())
        #expect(remaining.count == 1)
        let surviving = remaining.first!
        // Preserves primary synced version
        #expect(surviving.id == "item-dup-2")
        // Merged local note and tags from duplicate
        #expect(surviving.noteContent == "Important note to keep")
        #expect(surviving.tags.contains("local-tag"))
        #expect(surviving.tags.contains("official"))
    }
}
@MainActor
private final class MockCloudTransport: IOSCloudTransport {
    var downloads = 0
    var uploads: [[String: Any]] = []
    var uploadedCollections: [[String: Any]] = []
    var snapshots: [CloudItemSnapshot] = []
    var manifestData: Data? = nil
    var failUpload = false
    var errorToThrow: Error? = nil
    func downloadSnapshots(userID: String, token: String) async throws -> [CloudItemSnapshot] {
        if let err = errorToThrow { throw err }
        downloads += 1
        return snapshots
    }
    func cloudRequest(_ path: String, token: String, method: String, body: Any?) async throws -> Data {
        if let err = errorToThrow { throw err }
        if path.contains("select=id"), let data = manifestData {
            return data
        }
        return Data()
    }
    func uploadSnapshot(_ body: [String: Any], metadata: [String: Any], note: [String: Any], collection: [String: Any]?, token: String) async throws {
        if let err = errorToThrow { throw err }
        if failUpload { throw URLError(.notConnectedToInternet) }
        uploads.append(body)
        if let collection { uploadedCollections.append(collection) }
    }
}
