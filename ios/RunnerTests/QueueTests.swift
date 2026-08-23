import XCTest

final class QueueTests: XCTestCase {
    private var queue: ShareCaptureQueue?

    override func setUp() {
        super.setUp()
        queue = ShareCaptureQueue(appGroupId: "group.pro.micorp.laterbox")
        queue?.clear()
    }

    override func tearDown() {
        queue?.clear()
        queue = nil
        super.tearDown()
    }

    func testEmptyQueueReadsEmpty() {
        XCTAssertTrue(queue?.readAll().isEmpty ?? false)
    }

    func testEnqueuePersistsCaptures() throws {
        let queue = try XCTUnwrap(queue)
        queue.enqueue(makeCapture(id: "1", value: "https://example.com", kind: "url"))
        queue.enqueue(makeCapture(id: "2", value: "remember this", kind: "text"))
        XCTAssertEqual(queue.readAll().count, 2)
        XCTAssertEqual(queue.readAll().first?.value, "https://example.com")
        XCTAssertEqual(queue.readAll().last?.kind, "text")
    }

    func testClearRemovesAllCaptures() throws {
        let queue = try XCTUnwrap(queue)
        queue.enqueue(makeCapture(id: "1", value: "hello", kind: "text"))
        queue.clear()
        XCTAssertTrue(queue.readAll().isEmpty)
    }

    func testCaptureSurvivesNewQueueInstance() throws {
        let first = try XCTUnwrap(queue)
        first.enqueue(makeCapture(id: "7", value: "durable", kind: "text"))
        let second = ShareCaptureQueue(appGroupId: "group.pro.micorp.laterbox")
        let captures = second.readAll()
        XCTAssertEqual(captures.first?.id, "7")
        XCTAssertEqual(captures.first?.value, "durable")
    }

    func testAttachmentCaptureKeepsGroupedPaths() throws {
        let queue = try XCTUnwrap(queue)
        let capture = PendingShareCapture(
            id: "files-1",
            value: "Review tomorrow",
            kind: "attachments",
            source: "iosShare",
            createdAt: "2026-08-20T10:00:00Z",
            filePaths: ["/group/a.pdf", "/group/b.png"]
        )
        XCTAssertTrue(queue.enqueue(capture))

        let saved = try XCTUnwrap(queue.readAll().first)
        XCTAssertEqual(saved.filePaths, ["/group/a.pdf", "/group/b.png"])
        XCTAssertEqual(saved.toDictionary["text"] as? String, "Review tomorrow")
    }

    func testAcknowledgeRemovesOnlyCompletedCapture() throws {
        let queue = try XCTUnwrap(queue)
        queue.enqueue(makeCapture(id: "1", value: "first", kind: "text"))
        queue.enqueue(makeCapture(id: "2", value: "second", kind: "text"))

        XCTAssertTrue(queue.acknowledge(ids: ["1"]))
        XCTAssertEqual(queue.readAll().map(\.id), ["2"])
    }

    private func makeCapture(id: String, value: String, kind: String) -> PendingShareCapture {
        PendingShareCapture(
            id: id,
            value: value,
            kind: kind,
            source: "iosShare",
            createdAt: "2026-08-19T07:00:00Z"
        )
    }
}
