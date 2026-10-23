import XCTest
import StoreKitTest

final class laterbox_iosUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    private func reveal(_ button: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<6 {
            if button.isHittable { return }
            (app.scrollViews.allElementsBoundByIndex.last ?? app.scrollViews.firstMatch).swipeUp()
        }
        XCTAssertTrue(button.isHittable)
    }

    @MainActor
    func testWelcomeOffersPurchaseAndRestoreWithoutRegistration() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-lb_guest_mode", "NO", "-lb_user_email", ""]
        app.launch()
        XCTAssertTrue(app.buttons["Continue without account"].waitForExistence(timeout: 15))
        let plans = app.buttons["welcome.plans"]
        XCTAssertTrue(plans.isHittable)
        plans.tap()
        XCTAssertTrue(app.buttons["Restore Purchases"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.textFields["Email"].exists)
    }

    @MainActor
    func testGuestSubscriptionReviewWalkthrough() throws {
        let file = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("laterbox-ios/Products.storekit")
        let session = try SKTestSession(contentsOf: file)
        session.disableDialogs = true
        session.timeRate = .realTime
        session.clearTransactions()
        defer { session.clearTransactions() }
        let app = XCUIApplication()
        app.launchArguments = ["-lb_guest_mode", "YES", "-lb_user_email", ""]
        app.launch()
        // The profile popover can be placed outside the viewport on compact
        // simulator layouts. Navigate via the real, scrollable sidebar.
        let sidebar = app.buttons["Open sidebar"]
        XCTAssertTrue(sidebar.waitForExistence(timeout: 15))
        sidebar.tap()
        let settings = app.buttons["Settings"].firstMatch
        XCTAssertTrue(settings.waitForExistence(timeout: 5))
        for _ in 0..<8 where !settings.isHittable {
            let drawerScroll = app.scrollViews.allElementsBoundByIndex.last
            if let drawerScroll { drawerScroll.swipeUp() } else { app.swipeUp() }
        }
        XCTAssertTrue(settings.isHittable)
        settings.tap()
        // Settings was reorganized: the destination is now Subscription,
        // while Plans is a separate shortcut in the sidebar.
        let subscriptions = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Subscription")).firstMatch
        XCTAssertTrue(subscriptions.waitForExistence(timeout: 10))
        XCTAssertTrue(subscriptions.isHittable)
        subscriptions.tap()
        let upgrade = app.buttons["Upgrade to LaterBox Pro"]
        XCTAssertTrue(upgrade.waitForExistence(timeout: 5))
        reveal(upgrade, in: app)
        upgrade.tap()
        let buy = app.buttons["billing.purchase"]
        XCTAssertTrue(buy.waitForExistence(timeout: 10))
        let eula = try XCTUnwrap(app.buttons.matching(identifier: "Terms of Use (EULA)").allElementsBoundByIndex.last)
        reveal(eula, in: app)
        XCTAssertTrue(app.buttons["Privacy Policy"].firstMatch.exists)
        let legal = XCTAttachment(screenshot: app.screenshot())
        legal.name = "Guest purchase legal disclosures — local StoreKit simulation"
        legal.lifetime = .keepAlways
        add(legal)
        for _ in 0..<6 { if buy.isHittable { break }; (app.scrollViews.allElementsBoundByIndex.last ?? app.scrollViews.firstMatch).swipeDown() }
        XCTAssertTrue(buy.isEnabled)
        buy.tap()
        XCTAssertTrue(app.alerts["Welcome to Pro!"].waitForExistence(timeout: 15))
        app.alerts["Welcome to Pro!"].buttons["Continue"].tap()
        let connections = app.buttons.matching(identifier: "billing.connect")
        XCTAssertTrue(connections.firstMatch.waitForExistence(timeout: 5))
        let connect = try XCTUnwrap(connections.allElementsBoundByIndex.last)
        for _ in 0..<6 { if connect.isHittable { break }; (app.scrollViews.allElementsBoundByIndex.last ?? app.scrollViews.firstMatch).swipeDown() }
        reveal(connect, in: app)
        XCTAssertEqual(connect.label, "Sign in to connect Pro (optional)")
        XCTAssertFalse(app.textFields["Email"].exists)
        let connected = XCTAttachment(screenshot: app.screenshot())
        connected.name = "Device Pro with optional account connection"
        connected.lifetime = .keepAlways
        add(connected)
        let restore = app.buttons["Restore Purchases"]
        reveal(restore, in: app)
        restore.tap()
        let restored = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: restore)
        XCTAssertEqual(XCTWaiter.wait(for: [restored], timeout: 15), .completed)
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Could not restore purchases:")).firstMatch.exists)
        XCTAssertTrue(connections.firstMatch.exists)
        XCTAssertEqual(session.allTransactions().count, 1)
        XCTAssertFalse(app.buttons["billing.purchase"].exists)

        // Exercise real device entitlement updates in a foreground application.
        // A headless unit-test host cannot reliably verify StoreKit receipts.
        let transaction = try XCTUnwrap(session.allTransactions().first)
        try session.disableAutoRenewForTransaction(identifier: transaction.identifier)
        XCTAssertTrue(connections.firstMatch.exists, "Cancellation must preserve paid access")
        try session.enableAutoRenewForTransaction(identifier: transaction.identifier)
        session.shouldEnterBillingRetryOnRenewal = true
        session.billingGracePeriodIsEnabled = true
        try session.forceRenewalOfSubscription(productIdentifier: transaction.productIdentifier)
        XCTAssertTrue(connections.firstMatch.exists, "Billing grace must preserve device access")
        // A renewal can create a new entitlement transaction; revoke the entire
        // simulated subscription rather than only its original purchase.
        for purchased in session.allTransactions() {
            try session.refundTransaction(identifier: purchased.identifier)
        }
        let checkout = app.buttons["billing.purchase"]
        XCTAssertTrue(checkout.waitForExistence(timeout: 15), "Refunded access must be revoked")
        XCTAssertFalse(connections.firstMatch.exists)
    }

    @MainActor
    func testGuidedCapturePreservesTypedContent() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-lb_guest_mode", "YES", "-lb_user_email", ""]
        app.launch()
        let openButton = app.buttons["Capture Item"]
        XCTAssertTrue(openButton.waitForExistence(timeout: 15))
        openButton.tap()

        // The unified chat composer replaces the former guided wizard.
        let message = app.descendants(matching: .any)["capture.message"].firstMatch
        XCTAssertTrue(message.waitForExistence(timeout: 10))
        message.tap()
        message.typeText("Keep this draft")
        XCTAssertEqual(message.value as? String, "Keep this draft")

        let close = app.buttons["Close"]
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        close.tap()
        XCTAssertTrue(openButton.waitForExistence(timeout: 10))
        XCTAssertTrue(openButton.isHittable)
    }

    @MainActor
    func testGuestGuidedCaptureSaveAndUndo() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-lb_guest_mode", "YES", "-lb_user_email", ""]
        app.launch()
        let openButton = app.buttons["Capture Item"]
        XCTAssertTrue(openButton.waitForExistence(timeout: 15))
        openButton.tap()

        let message = app.descendants(matching: .any)["capture.message"].firstMatch
        XCTAssertTrue(message.waitForExistence(timeout: 10))
        message.tap()
        message.typeText("UI capture test #ideas")

        let review = app.buttons["capture.send"]
        XCTAssertTrue(review.waitForExistence(timeout: 5))
        review.tap()

        let noReminder = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "No Reminder")).firstMatch
        XCTAssertTrue(noReminder.waitForExistence(timeout: 10))
        noReminder.tap()

        let undo = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Undo Save")).firstMatch
        XCTAssertTrue(undo.waitForExistence(timeout: 10))
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Chat capture saved item"
        attachment.lifetime = .keepAlways
        add(attachment)

        // Scroll the horizontal actions dock, not the chat's vertical
        // transcript; scrolling the wrong container leaves Undo offscreen.
        let dock = app.scrollViews["capture.options"]
        XCTAssertTrue(dock.waitForExistence(timeout: 5))
        // iOS 27's accessibility server can throw while computing
        // isHittable for an offscreen element. Scroll explicitly first.
        for _ in 0..<3 { dock.swipeLeft() }
        XCTAssertTrue(undo.exists)
        undo.tap()

        // Undo retains the draft in the review screen and removes Save Undo.
        XCTAssertTrue(app.staticTexts["UI capture test #ideas"].waitForExistence(timeout: 10))
        XCTAssertTrue(noReminder.waitForExistence(timeout: 10))
        XCTAssertFalse(undo.exists)
    }

}
