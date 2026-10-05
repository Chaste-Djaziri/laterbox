import XCTest

final class laterbox_iosUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    private func reveal(_ button: XCUIElement, in app: XCUIApplication) {
        let dock = app.scrollViews.containing(.button, identifier: button.label).firstMatch
        for _ in 0..<6 {
            if dock.frame.contains(button.frame) { return }
            if button.frame.midX < dock.frame.midX { dock.swipeRight() } else { dock.swipeLeft() }
        }
        XCTAssertTrue(dock.frame.contains(button.frame))
    }

    @MainActor
    func testGuestGuidedCaptureSaveAndUndo() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-lb_guest_mode", "YES", "-lb_user_email", ""]
        app.launch()
        XCTAssertTrue(app.buttons["Add item"].waitForExistence(timeout: 15))
        app.buttons["Add item"].tap()
        if app.buttons["Guided capture"].waitForExistence(timeout: 3) { app.buttons["Guided capture"].tap() }
        let content = app.descendants(matching: .any)["capture.content"].firstMatch
        XCTAssertTrue(content.waitForExistence(timeout: 5))
        XCTAssertFalse(app.textFields["Message Later AI..."].exists)
        content.tap()
        content.typeText("UI capture test #ideas")
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["capture.title"].firstMatch.waitForExistence(timeout: 5))
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["capture.tags"].firstMatch.waitForExistence(timeout: 5))
        app.buttons["Continue"].tap()
        let noReminder = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "No Reminder")).firstMatch
        XCTAssertTrue(noReminder.waitForExistence(timeout: 5))
        noReminder.tap()
        XCTAssertTrue(app.buttons["Save to Vault"].waitForExistence(timeout: 5))
        app.buttons["Save to Vault"].tap()
        let savedNoReminder = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "No Reminder")).firstMatch
        if savedNoReminder.waitForExistence(timeout: 3) {
            reveal(savedNoReminder, in: app)
            savedNoReminder.tap()
        }
        let guidedUndo = app.buttons["Undo"]
        if guidedUndo.waitForExistence(timeout: 2) {
            guidedUndo.tap()
            XCTAssertTrue(content.waitForExistence(timeout: 5))
            return
        }
        let undo = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Undo Save")).firstMatch
        XCTAssertTrue(undo.waitForExistence(timeout: 5))
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Guided capture saved item"
        attachment.lifetime = .keepAlways
        add(attachment)
        reveal(undo, in: app)
        undo.tap()
        XCTAssertTrue(app.descendants(matching: .any)["capture.content"].firstMatch.waitForExistence(timeout: 5))
    }
}
