// laterbox-ios/laterbox-iosTests/MainTabTests.swift
import Testing
import SwiftUI
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

    @Test("Five-second splash replays only after returning from background")
    func splashReplayTiming() {
        #expect(LaterBoxSplashTiming.totalDurationSeconds == 5.0)
        #expect(
            Double(LaterBoxSplashTiming.leadInMilliseconds + LaterBoxSplashTiming.remainingMilliseconds) / 1_000
                == LaterBoxSplashTiming.totalDurationSeconds
        )
        #expect(LaterBoxSplashTiming.fillDurationSeconds < LaterBoxSplashTiming.totalDurationSeconds)
        #expect(LaterBoxSplashTiming.shouldReplay(wasBackgrounded: true, phase: .active))
        #expect(!LaterBoxSplashTiming.shouldReplay(wasBackgrounded: false, phase: .active))
        #expect(!LaterBoxSplashTiming.shouldReplay(wasBackgrounded: true, phase: .inactive))
    }

    @Test("Refresh logo stretches only on downward overscroll")
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
    }

    @Test("Splash uses black on white in Light Mode and white on black in Dark Mode")
    func splashRespectsAppearance() {
        #expect(LaterBoxLoadingMark.foreground(for: .light) == Color.black)
        #expect(LaterBoxLoadingMark.background(for: .light) == Color.white)
        #expect(LaterBoxLoadingMark.foreground(for: .dark) == Color.white)
        #expect(LaterBoxLoadingMark.background(for: .dark) == Color.black)
    }

    @Test("Splash fill clamps to the valid loading range")
    func splashFillProgress() {
        #expect(LaterBoxLoadingMark.normalizedProgress(-0.2) == 0)
        #expect(LaterBoxLoadingMark.normalizedProgress(0.32) == 0.32)
        #expect(LaterBoxLoadingMark.normalizedProgress(0.85) == 0.85)
        #expect(LaterBoxLoadingMark.normalizedProgress(1.2) == 1)
        #expect(LaterBoxLoadingMark.normalizedProgress(.nan) == 0)
        #expect(LaterBoxLoadingMark.normalizedProgress(.infinity) == 0)
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
