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

    @Test("Storage indicator reports actual local bytes and composition")
    func storageUsageHeader() {
        let breakdown = StorageBreakdown(
            databaseBytes: 1_000_000,
            attachmentsBytes: 500_000,
            cacheBytes: 500_000
        )
        #expect(breakdown.totalBytes == 2_000_000)
        #expect(breakdown.databasePercentage == 0.5)
        #expect(breakdown.attachmentsPercentage == 0.25)
        #expect(breakdown.cachePercentage == 0.25)
        #expect(!breakdown.formattedTotal.isEmpty)
    }

    @Test("Only Inbox owns the custom top header")
    func headerVisibility() {
        #expect(MainTab.inbox.showsAppHeader)
        #expect(MainTab.inbox.shouldShowHeader(itemDetailPushed: false))
        #expect(!MainTab.inbox.shouldShowHeader(itemDetailPushed: true))
        for tab in MainTab.allCases where tab != .inbox {
            #expect(!tab.showsAppHeader)
            #expect(!tab.shouldShowHeader(itemDetailPushed: false))
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

    @Test("Inbox uses true white and black canvases with contrasting content")
    func inboxAppearance() {
        #expect(InboxAppearance.background(for: .light) == Color.white)
        #expect(InboxAppearance.background(for: .dark) == Color.black)
        #expect(InboxAppearance.textPrimary(for: .light) == Color.black)
        #expect(InboxAppearance.textPrimary(for: .dark) == Color.white)
        #expect(InboxAppearance.surface(for: .light) != InboxAppearance.surface(for: .dark))
        #expect(InboxAppearance.border(for: .light) != InboxAppearance.border(for: .dark))
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
