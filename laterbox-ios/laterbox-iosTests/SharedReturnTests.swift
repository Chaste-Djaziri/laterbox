import Testing
import SwiftData
import Foundation
@testable import laterbox_ios

@MainActor struct SharedReturnTests {
    @Test func dueReturnsPromoteOnlyScheduledItems() throws {
        let container = try ModelContainer(for: LBItem.self, LBCollection.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        let now = Date()
        let due = LBItem(title: "Due", status: .deferred, returnAt: now.addingTimeInterval(-60))
        let future = LBItem(title: "Future", status: .deferred, returnAt: now.addingTimeInterval(60))
        let deleted = LBItem(title: "Deleted", status: .deleted, returnAt: now.addingTimeInterval(-60))
        context.insert(due); context.insert(future); context.insert(deleted); try context.save()
        try SharedCaptureImporter.refresh(context: context, now: now)
        #expect(due.status == "inbox")
        #expect(future.status == "deferred")
        #expect(deleted.status == "deleted")
        #expect(due.returnAt != nil)
        try SharedCaptureImporter.refresh(context: context, now: now)
        #expect(try context.fetchCount(FetchDescriptor<LBItem>()) == 3)
    }
    @Test func attachmentAndCaptureRoundTrip() throws {
        var capture = SharedCapture()
        capture.content = "Original text"
        capture.attachments = [SharedAttachment(name: "sample.pdf", relativePath: "Attachments/a/sample.pdf", typeIdentifier: "com.adobe.pdf")]
        capture.returnAt = Date(timeIntervalSince1970: 1800000000)
        let restored = try JSONDecoder().decode(SharedCapture.self, from: JSONEncoder().encode(capture))
        #expect(restored.id == capture.id)
        #expect(restored.content == capture.content)
        #expect(restored.attachments == capture.attachments)
        #expect(restored.returnAt == capture.returnAt)
    }
}
