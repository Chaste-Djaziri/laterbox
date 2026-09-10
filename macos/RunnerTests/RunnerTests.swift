import Cocoa
import FlutterMacOS
import XCTest

class RunnerTests: XCTestCase {
  func testClipboardFilterAcceptsLinksAndMeaningfulText() {
    let controller = NotchPanelController()

    XCTAssertTrue(controller.eligible("https://example.com/article"))
    XCTAssertTrue(controller.eligible("A meaningful copied passage worth saving for later."))
    XCTAssertFalse(controller.eligible("short"))
    XCTAssertFalse(controller.eligible("482913"))
    XCTAssertFalse(controller.eligible("Password: correct horse battery staple"))
  }

  func testCandidateMovesThroughSavingAndReceiptStates() {
    let controller = NotchPanelController()
    controller.setProAutomationEnabled(true)
    let candidate = NotchCaptureCandidate(
      id: "capture-1",
      title: "Example",
      url: "https://example.com",
      text: nil,
      source: .clipboard,
      kind: .link
    )
    var requestedId: String?
    controller.onCaptureRequested = { requestedId = $0.id }

    controller.presentExternalCandidate(candidate)
    controller.performPrimaryAction()
    XCTAssertEqual(requestedId, "capture-1")
    if case .saving(let item) = controller.state {
      XCTAssertEqual(item.id, "capture-1")
    } else {
      XCTFail("Expected saving state")
    }

    controller.captureCompleted(
      id: "capture-1",
      title: "Example",
      value: "https://example.com",
      kind: .link
    )
    XCTAssertEqual(controller.receipts.count, 1)
    if case .saved(let receipt) = controller.state {
      XCTAssertEqual(receipt.id, "capture-1")
    } else {
      XCTFail("Expected saved state")
    }
  }

  func testCandidateRequiresProAndOpensPlans() {
    let controller = NotchPanelController()
    let candidate = NotchCaptureCandidate(
      id: "capture-locked",
      title: "Example",
      url: "https://example.com",
      text: nil,
      source: .clipboard,
      kind: .link
    )
    var openedPlans = false
    var requestedCapture = false
    controller.onOpenPlans = { openedPlans = true }
    controller.onCaptureRequested = { _ in requestedCapture = true }

    controller.presentExternalCandidate(candidate)
    if case .locked = controller.state {} else {
      XCTFail("Expected locked state")
    }
    controller.performPrimaryAction()

    XCTAssertTrue(openedPlans)
    XCTAssertFalse(requestedCapture)
  }
}
