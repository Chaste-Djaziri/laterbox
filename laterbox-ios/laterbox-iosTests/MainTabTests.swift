// laterbox-ios/laterbox-iosTests/MainTabTests.swift
import Testing
@testable import laterbox_ios

@Suite("Main iOS navigation")
struct MainTabTests {
    @Test("The five primary tabs are stable, distinct, and in daily-use order")
    func tabStructure() {
        #expect(MainTab.allCases.map(\.rawValue) == [
            "Inbox", "Today", "Kept", "Library", "Settings"
        ])
        #expect(Set(MainTab.allCases.map(\.symbol)).count == 5)
    }

    @Test("Secondary mailboxes remain outside the primary tab bar")
    func secondaryMailboxes() {
        let titles = Set(MainTab.allCases.map(\.rawValue))
        for mailbox in ["Upcoming", "Someday", "Starred", "Archived", "Recently Deleted"] {
            #expect(!titles.contains(mailbox))
        }
    }
}
