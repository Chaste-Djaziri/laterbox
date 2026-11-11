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
    func testWelcomeSignInOpensAndReturnsWithoutFreezing() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-lb_guest_mode", "NO", "-lb_user_email", ""]
        app.launch()

        let signIn = app.buttons["welcome.signIn"]
        XCTAssertTrue(signIn.waitForExistence(timeout: 15), "Welcome sign-in button should appear")
        signIn.tap()

        let email = app.textFields["auth.emailField"]
        XCTAssertTrue(email.waitForExistence(timeout: 8),
                      "Authentication should open without an appearance or navigation loop")
        XCTAssertTrue(email.isHittable)
        email.tap()
        email.typeText("test@example.com")
        XCTAssertEqual(email.value as? String, "test@example.com",
                       "Authentication should remain interactive after navigating")

        let close = app.buttons["Close sign in"]
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        close.tap()
        XCTAssertTrue(signIn.waitForExistence(timeout: 8),
                      "Closing auth should return to the responsive welcome screen")

        // Re-enter to catch an appearance-loop triggered by repeated navigation.
        signIn.tap()
        XCTAssertTrue(app.textFields["auth.emailField"].waitForExistence(timeout: 8))
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
    func testMainTabBarAndHeaderControls() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-lb_guest_mode", "YES", "-lb_user_email", ""]
        app.launch()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 15))
        for name in ["Inbox", "Today", "Library", "Earn", "Settings"] {
            XCTAssertTrue(tabBar.buttons[name].exists, "\(name) must be a primary navigation tab")
        }

        XCTAssertTrue(app.buttons["Capture Item"].exists, "Quick capture belongs in the top-left app header")
        XCTAssertTrue(app.buttons["LaterBox home"].exists, "LaterBox icon belongs in the centered header")
        let storageUsage = app.buttons["Inbox Storage Usage"]
        XCTAssertTrue(storageUsage.exists, "Storage usage replaces the More menu")
        XCTAssertFalse(app.buttons["More LaterBox Pages"].exists, "The three-line menu is removed")
        storageUsage.tap()
        XCTAssertTrue(app.navigationBars["Cloud storage"].waitForExistence(timeout: 5) || app.staticTexts["Cloud storage"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["Search saved items"].exists, "Inbox search should remain visible")
        XCTAssertFalse(app.buttons["Browse folders"].exists, "No duplicate sidebar opener beside search")

        tabBar.buttons["Today"].tap()
        XCTAssertTrue(app.staticTexts["Returns"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["LaterBox home"].exists, "Header is hidden outside Inbox")
        XCTAssertFalse(app.buttons["Capture Item"].exists, "Header actions are Inbox-only")

        tabBar.buttons["Library"].tap()
        XCTAssertTrue(app.staticTexts["Library"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["LaterBox home"].exists)

        tabBar.buttons["Earn"].tap()
        XCTAssertTrue(app.staticTexts["Earn"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["LaterBox home"].exists)

        tabBar.buttons["Library"].tap()
        XCTAssertTrue(app.staticTexts["Library"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["LaterBox home"].exists)

        tabBar.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["LaterBox home"].exists)

        tabBar.buttons["Inbox"].tap()
        XCTAssertTrue(app.buttons["LaterBox home"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Capture Item"].exists)
    }

    @MainActor
    func testReturnsScrollableSegmentsAndExpandableSearch() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-lb_guest_mode", "YES", "-lb_user_email", ""]
        app.launch()

        let todayTab = app.tabBars.buttons["Today"]
        XCTAssertTrue(todayTab.waitForExistence(timeout: 15))
        todayTab.tap()

        let today = app.buttons["Returns Segment Today"]
        let upcoming = app.buttons["Returns Segment Upcoming"]
        let someday = app.buttons["Returns Segment Someday"]

        XCTAssertTrue(today.waitForExistence(timeout: 5))
        XCTAssertTrue(upcoming.exists)
        XCTAssertTrue(someday.exists)
        XCTAssertEqual(today.value as? String, "Selected")
        XCTAssertFalse(app.staticTexts["Due today"].exists, "No redundant section heading beneath the switcher")

        upcoming.tap()
        XCTAssertEqual(upcoming.value as? String, "Selected")
        XCTAssertFalse(app.staticTexts["Coming up"].exists, "Segment titles are displayed only inside the chips")

        someday.tap()
        XCTAssertEqual(someday.value as? String, "Selected")
        XCTAssertFalse(app.staticTexts["Whenever you're ready"].exists, "Remove repeated subtitles")

        today.tap()
        XCTAssertFalse(app.staticTexts["Due today"].exists)

        let searchButton = app.buttons["Returns Search Button"]
        XCTAssertTrue(searchButton.exists, "The top-right calendar should be replaced by search")
        searchButton.tap()
        let searchField = app.textFields["Returns Search Field"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Make time for what you saved."].exists,
                       "Expanded search hides the Returns heading description")

        searchField.tap()
        searchField.typeText("unlikely-return-search-term")
        XCTAssertTrue(app.staticTexts["No matches in Today"].waitForExistence(timeout: 5))

        upcoming.tap()
        XCTAssertTrue(app.staticTexts["No matches in Upcoming"].waitForExistence(timeout: 5),
                      "Search applies to the active segment")

        app.buttons["Returns Search Cancel"].tap()
        XCTAssertTrue(searchButton.waitForExistence(timeout: 5))
        XCTAssertFalse(searchField.exists)
    }

    @MainActor
    func testInboxSearchStaysAlignedAfterItemPushAndSwipeBack() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-lb_guest_mode", "YES", "-lb_user_email", ""]
        app.launch()

        let search = app.buttons["Search saved items"]
        let header = app.buttons["LaterBox home"]
        XCTAssertTrue(search.waitForExistence(timeout: 15))
        XCTAssertTrue(header.exists)
        let originalSearchY = search.frame.minY

        // This visual navigation regression needs at least one item in the test library.
        let row = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "Inbox Item Row ")
        ).firstMatch
        guard row.waitForExistence(timeout: 3) else {
            throw XCTSkip("Requires an Inbox item to verify detail navigation and return geometry")
        }
        row.tap()
        XCTAssertFalse(header.exists, "Inbox header must disappear on pushed details")
        XCTAssertFalse(app.staticTexts["Item Details"].exists, "Avoid a generic detail title")
        XCTAssertTrue(app.buttons["Item Detail Actions"].waitForExistence(timeout: 5),
                      "Item details must retain the web-aligned More actions")

        // Native iOS edge swipe should return directly to the Inbox root.
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.42))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.78, dy: 0.42))
        start.press(forDuration: 0.05, thenDragTo: end)

        XCTAssertTrue(header.waitForExistence(timeout: 5))
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        XCTAssertEqual(search.frame.minY, originalSearchY, accuracy: 3,
            "Returning from item details must not leave a top gap above Inbox search")
    }

    @MainActor
    func testGuestSubscriptionReviewWalkthrough() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-lb_guest_mode", "YES", "-lb_user_email", ""]
        app.launch()
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 15))
        settingsTab.tap()
        let subscriptions = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Subscription")).firstMatch
        XCTAssertTrue(subscriptions.waitForExistence(timeout: 10))
        subscriptions.tap()
        let upgrade = app.buttons["Upgrade to LaterBox Pro"]
        XCTAssertTrue(upgrade.waitForExistence(timeout: 5))
        upgrade.tap()
        XCTAssertTrue(app.staticTexts["LaterBox Plans"].waitForExistence(timeout: 10))
        let restore = app.buttons.matching(identifier: "Restore Purchases").firstMatch
        XCTAssertTrue(restore.waitForExistence(timeout: 10))
        restore.tap()
        app.buttons["Done"].tap()
        XCTAssertTrue(app.navigationBars["Subscription & Plans"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testGuidedCapturePreservesTypedContent() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-lb_guest_mode", "YES", "-lb_user_email", ""]
        app.launch()
        let openButton = app.buttons["Capture Item"]
        XCTAssertTrue(openButton.waitForExistence(timeout: 15))
        openButton.tap()

        let content = app.descendants(matching: .any)["capture.content"].firstMatch
        XCTAssertTrue(content.waitForExistence(timeout: 10))
        content.tap()
        content.typeText("Keep this draft")
        XCTAssertEqual(content.value as? String, "Keep this draft")

        let close = app.buttons["capture.close"]
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        close.tap()
        let discard = app.buttons["Discard Draft"]
        if discard.waitForExistence(timeout: 3) {
            discard.tap()
        }
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

        let content = app.descendants(matching: .any)["capture.content"].firstMatch
        XCTAssertTrue(content.waitForExistence(timeout: 10))
        content.tap()
        content.typeText("UI capture test #ideas")

        let continueButton = app.buttons["capture.continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        continueButton.tap()

        let scheduleChoice = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "capture.return")).firstMatch
        XCTAssertTrue(scheduleChoice.waitForExistence(timeout: 5))
        scheduleChoice.tap()

        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        continueButton.tap()

        let save = app.buttons["capture.save"]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        save.tap()

        let undo = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Undo Save")).firstMatch
        if undo.waitForExistence(timeout: 5) {
            undo.tap()
        }
        let done = app.buttons["capture.done"]
        if done.waitForExistence(timeout: 3) {
            done.tap()
        }
        let close = app.buttons["capture.close"]
        if close.waitForExistence(timeout: 3) {
            close.tap()
        }
        XCTAssertTrue(openButton.waitForExistence(timeout: 10))
    }

}
