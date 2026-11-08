// laterbox-ios/laterbox-iosTests/MainTabTests.swift
import Testing
import SwiftUI
import UIKit
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

    @Test("Cloud storage circle follows server quota and web warning thresholds")
    func cloudQuotaIndicator() {
        let unavailable = CloudStorageQuota(usedBytes: nil, limitBytes: 500_000_000)
        #expect(unavailable.percent == nil)
        #expect(unavailable.ringFraction == nil)
        #expect(unavailable.level == .unknown)

        let normal = CloudStorageQuota(usedBytes: 100_000_000, limitBytes: 500_000_000)
        #expect(normal.percent == 20)
        #expect(normal.ringFraction == 0.2)
        #expect(normal.level == .normal)
        #expect(normal.usedLabel == "100.0 MB")
        #expect(normal.limitLabel == "500.0 MB")

        #expect(CloudStorageQuota(usedBytes: 80, limitBytes: 100).level == .warning)
        #expect(CloudStorageQuota(usedBytes: 95, limitBytes: 100).level == .critical)
        #expect(CloudStorageQuota(usedBytes: 100, limitBytes: 100).level == .full)
        #expect(CloudStorageQuota(usedBytes: 140, limitBytes: 100).ringFraction == 1)
        #expect(CloudStorageQuota(usedBytes: -1, limitBytes: 100).level == .unknown)
        #expect(CloudStorageQuota(usedBytes: 0, limitBytes: 0).level == .unknown)
    }

    @Test("Cloud quota is decoded from billing entitlement, not local device storage")
    func cloudQuotaEntitlementDecoding() throws {
        let json = """
        {
          "tier": "pro", "status": "active", "provider": "whop",
          "willCancel": false, "storagePlan": "vault",
          "storageUsedBytes": 7500000000, "storageLimitBytes": 100000000000
        }
        """
        let entitlement = try JSONDecoder().decode(AccountBillingEntitlement.self, from: Data(json.utf8))
        #expect(entitlement.storagePlan == "vault")
        #expect(entitlement.storageUsedBytes == 7_500_000_000)
        #expect(entitlement.storageLimitBytes == 100_000_000_000)
        #expect(CloudStorageQuota.from(entitlement).percent == 7.5)

        let oldJSON = """
        {"tier":"free","status":"free","willCancel":false}
        """
        let old = try JSONDecoder().decode(AccountBillingEntitlement.self, from: Data(oldJSON.utf8))
        #expect(CloudStorageQuota.from(old).percent == nil)
    }

    @Test("Returns destinations have distinct labels, symbols, and empty states")
    func returnSegments() {
        #expect(ReturnSegment.allCases.map(\.rawValue) == ["Today", "Upcoming", "Someday"])
        #expect(Set(ReturnSegment.allCases.map(\.symbol)).count == 3)
        for segment in ReturnSegment.allCases {
            #expect(!segment.emptyTitle.isEmpty)
            #expect(!segment.emptyHint.isEmpty)
        }
        #expect(ReturnSegment.today.emptyTitle == "All caught up")
        #expect(ReturnSegment.someday.emptyTitle == "Your Someday list is empty")
    }

    @Test("Compact Returns switcher hides on downward scroll and reappears on upward scroll")
    func returnsSwitcherScrollDirection() {
        var tracker = ReturnsScrollSwitcherTracker()

        // Call mutating functions outside #expect so Testing's call-capture
        // macro never treats the mutable value as an immutable parameter.
        func verify(_ offset: CGFloat, visible expected: Bool) {
            let actual = tracker.update(offset: offset)
            #expect(actual == expected)
        }

        verify(0, visible: true)
        verify(24, visible: true)
        verify(70, visible: false)
        verify(89, visible: false)
        verify(72, visible: true)
        verify(55, visible: true)
        verify(96, visible: false)
        verify(5, visible: true)

        // Ignore small scroll jitter, invalid values, and layout jumps.
        tracker.reset()
        verify(0, visible: true)
        verify(1, visible: true)
        verify(2, visible: true)
        verify(220, visible: true)
        verify(.nan, visible: true)
        verify(.infinity, visible: true)
        verify(1, visible: true)
    }

    @Test("Returns search matches saved content and ignores empty input")
    func returnsSearch() {
        let item = LBItem(
            url: "https://example.com/weekly-guide",
            title: "Read the next chapter",
            textContent: "An interesting anime review",
            type: .link,
            status: .deferred
        )
        item.siteName = "Example News"
        item.summary = "Pick this up next week"
        item.tags = ["Reading", "Favorites"]

        #expect(ReturnsItemSearch.matches(item, query: ""))
        #expect(ReturnsItemSearch.matches(item, query: "   "))
        #expect(ReturnsItemSearch.matches(item, query: "CHAPTER"))
        #expect(ReturnsItemSearch.matches(item, query: "example.com"))
        #expect(ReturnsItemSearch.matches(item, query: "anime"))
        #expect(ReturnsItemSearch.matches(item, query: "next week"))
        #expect(ReturnsItemSearch.matches(item, query: "reading"))
        #expect(!ReturnsItemSearch.matches(item, query: "coffee"))
    }

    @Test("Only Inbox owns the custom top header")
    func headerVisibility() {
        #expect(MainTab.inbox.showsAppHeader)
        for tab in MainTab.allCases where tab != .inbox {
            #expect(!tab.showsAppHeader)
        }
    }

    @Test("Refresh logo grows uniformly on downward overscroll")
    func pullRefreshGeometry() {
        #expect(LaterBoxPullRefresh.distance(-32) == 0)
        #expect(LaterBoxPullRefresh.distance(0) == 0)
        #expect(LaterBoxPullRefresh.distance(47) == 47)
        #expect(LaterBoxPullRefresh.distance(500) == 180)
        #expect(LaterBoxPullRefresh.distance(.nan) == 0)
        #expect(LaterBoxPullRefresh.progress(-10) == 0)
        #expect(LaterBoxPullRefresh.progress(52.5) == 0.5)
        #expect(LaterBoxPullRefresh.progress(105) == 1)
        #expect(LaterBoxPullRefresh.progress(200) == 1)

        // A real UIScrollView rests at -adjustedContentInset.top.
        #expect(LaterBoxPullRefresh.overscroll(contentOffsetY: -48, adjustedTopInset: 48) == 0)
        #expect(LaterBoxPullRefresh.overscroll(contentOffsetY: -108, adjustedTopInset: 48) == 60)
        #expect(LaterBoxPullRefresh.overscroll(contentOffsetY: 24, adjustedTopInset: 48) == 0)
        #expect(LaterBoxPullRefresh.overscroll(contentOffsetY: -300, adjustedTopInset: 48) == 180)
        #expect(LaterBoxPullRefresh.minimumVisibleSeconds >= 1)

        let neutralScale = LaterBoxPullRefresh.uniformScale(distance: 0, refreshing: false)
        let partialScale = LaterBoxPullRefresh.uniformScale(distance: 50, refreshing: false)
        let fullScale = LaterBoxPullRefresh.uniformScale(distance: 100, refreshing: false)
        let activeScale = LaterBoxPullRefresh.uniformScale(distance: 0, refreshing: true)
        #expect(neutralScale == 1)
        #expect(partialScale > neutralScale)
        #expect(fullScale > partialScale)
        #expect(activeScale == fullScale)
        #expect(LaterBoxPullRefresh.uniformScale(distance: 500, refreshing: false) == fullScale)

        // Color fills continuously from the bottom as the finger pulls down.
        #expect(LaterBoxPullRefresh.fillProgress(distance: 0, refreshing: false) == 0)
        #expect(LaterBoxPullRefresh.fillProgress(distance: 25, refreshing: false) == 0.25)
        #expect(LaterBoxPullRefresh.fillProgress(distance: 50, refreshing: false) == 0.5)
        #expect(LaterBoxPullRefresh.fillProgress(distance: 100, refreshing: false) == 1)
        #expect(LaterBoxPullRefresh.fillProgress(distance: 500, refreshing: false) == 1)
        // While syncing, the mark stays fully colored even after the pull releases.
        #expect(LaterBoxPullRefresh.fillProgress(distance: 0, refreshing: true) == 1)
        #expect(LaterBoxPullRefresh.fillProgress(distance: -20, refreshing: false) == 0)
    }

    @Test("Minimal system launch canvas follows light and dark appearance")
    func systemLaunchCanvas() {
        let light = UITraitCollection(userInterfaceStyle: .light)
        let dark = UITraitCollection(userInterfaceStyle: .dark)
        let canvas = UIColor(named: "LaterBoxLaunchCanvas")

        #expect(canvas?.resolvedColor(with: light).isEqual(UIColor.white) == true)
        #expect(canvas?.resolvedColor(with: dark).isEqual(UIColor.black) == true)
    }

    @Test("Inbox uses clean white and textured graphite dark appearance")
    func inboxAppearance() {
        #expect(InboxAppearance.background(for: .light) == Color.white)
        #expect(InboxAppearance.background(for: .dark) == Color(hex: "1B1D20"))
        #expect(InboxAppearance.surface(for: .dark) == Color(hex: "25282B"))
        #expect(InboxAppearance.textPrimary(for: .light) == Color.black)
        #expect(InboxAppearance.textPrimary(for: .dark) == Color.white)
        #expect(InboxAppearance.surface(for: .light) != InboxAppearance.surface(for: .dark))
        #expect(InboxAppearance.border(for: .light) != InboxAppearance.border(for: .dark))
    }

    @Test("Graphite grain remains deterministic and within bounds")
    func darkGrainNoise() {
        let sample = (0..<100).map { InboxGrainBackground.noise(UInt64($0)) }
        #expect(sample.allSatisfy { $0 >= 0 && $0 <= 1 })
        #expect(sample == (0..<100).map { InboxGrainBackground.noise(UInt64($0)) })
        #expect(Set(sample).count > 90)
    }

    @Test("The brand mark is made from three scalable vector faces with open counters")
    func vectorMarkGeometry() {
        let artboard = CGRect(x: 0, y: 0, width: 603, height: 656)
        let lid = LaterBoxMarkShape(part: .lid).path(in: artboard)
        let left = LaterBoxMarkShape(part: .left).path(in: artboard)
        let right = LaterBoxMarkShape(part: .right).path(in: artboard)

        #expect(!lid.isEmpty)
        #expect(!left.isEmpty)
        #expect(!right.isEmpty)
        #expect(lid.contains(CGPoint(x: 299, y: 20), eoFill: true))
        #expect(!lid.contains(CGPoint(x: 299, y: 157), eoFill: true))
        #expect(left.contains(CGPoint(x: 30, y: 400), eoFill: true))
        #expect(!right.contains(CGPoint(x: 450, y: 390), eoFill: true))
        #expect(!right.contains(CGPoint(x: 450, y: 490), eoFill: true))

        // It can resize to header dimensions without relying on a raster image.
        let small = LaterBoxMarkShape(part: .lid).path(
            in: CGRect(x: 0, y: 0, width: 42, height: 42)
        ).boundingRect
        #expect(small.minX >= 0)
        #expect(small.minY >= 0)
        #expect(small.maxX <= 42)
        #expect(small.maxY <= 42)
    }

    @Test("Secondary mailboxes remain outside the primary tab bar")
    func secondaryMailboxes() {
        let titles = Set(MainTab.allCases.map(\.rawValue))
        for mailbox in ["Upcoming", "Someday", "Starred", "Archived", "Recently Deleted"] {
            #expect(!titles.contains(mailbox))
        }
    }
}
