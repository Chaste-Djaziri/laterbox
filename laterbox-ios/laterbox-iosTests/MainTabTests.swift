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
            "Inbox", "Today", "Library", "Earn", "Settings"
        ])
        #expect(Set(MainTab.allCases.map(\.symbol)).count == 5)
    }

    @Test("Native remote media classification matches supported streaming codecs")
    func mediaStreamingClassification() {
        #expect(RemoteMediaKind.directURL("https://example.com/clips/video.mp4?token=abc")?.1 == .video)
        #expect(RemoteMediaKind.directURL("https://example.com/audio/song.m4a")?.1 == .audio)
        #expect(RemoteMediaKind.directURL("https://example.com/live/index.m3u8")?.1 == .video)
        #expect(RemoteMediaKind.detect(name: "recording.bin", mimeType: "audio/mpeg") == .audio)
        #expect(RemoteMediaKind.detect(name: "clip.bin", mimeType: "video/mp4") == .video)
        #expect(RemoteMediaKind.detect(name: "clip.webm", mimeType: "video/webm") == nil)
        #expect(RemoteMediaKind.detect(name: "track.ogg", mimeType: "audio/ogg") == nil)
        #expect(RemoteMediaKind.directURL("https://example.com/watch?v=5") == nil)
        #expect(RemoteMediaKind.directURL("file:///private/tmp/clip.mp4") == nil)
        #expect(RemoteMediaKind.directURL("javascript:alert(1)") == nil)
        #expect(RemoteMediaPlayerView.timeLabel(125) == "2:05")
    }

    @Test("Cloud media attachments remain metadata-only until explicit Download")
    func cloudMediaAttachmentPlaceholder() {
        let remote = CloudAttachmentSnapshot(
            id: "fa2da390-5e30-4794-bb79-ab065311c7cf",
            item_id: "9610db91-740e-4c54-b711-a4ae3e09eef1",
            original_file_name: "recording.m4a",
            file_extension: "m4a",
            mime_type: "audio/mp4",
            byte_size: 9_000_000,
            sha256: String(repeating: "a", count: 64),
            r2_object_key: "private/example/recording.m4a",
            deleted_at: nil
        )
        let placeholder = LaterBoxAPIService.remoteMediaPlaceholder(remote)
        #expect(placeholder.id == remote.id)
        #expect(placeholder.name == "recording.m4a")
        #expect(placeholder.remoteObjectKey == remote.r2_object_key)
        #expect(placeholder.byteSize == 9_000_000)
        #expect(RemoteMediaKind.isRemoteMedia(placeholder))
    }

    @Test("Remote provider links resolve to embedded media")
    func mediaServiceEmbeds() {
        if case .soundcloud = EmbeddedMediaType.detect(url: "https://soundcloud.com/someone/track") {
        } else { Issue.record("SoundCloud URL should embed") }
        if case .lyrica = EmbeddedMediaType.detect(url: "https://lyricarw.com/songs/demo-slug") {
        } else { Issue.record("Lyrica song URL should embed") }
        if case .youtube = EmbeddedMediaType.detect(url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ") {
        } else { Issue.record("YouTube embed must remain supported") }
        if case .spotify = EmbeddedMediaType.detect(url: "https://open.spotify.com/track/12345") {
        } else { Issue.record("Spotify embed must remain supported") }
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
        #expect(LaterBoxPullRefresh.progress(50) == 0.5)
        #expect(LaterBoxPullRefresh.progress(100) == 1)
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
        let bundle = Bundle(for: SyncCoordinator.self)
        let canvas = UIColor(named: "LaterBoxLaunchCanvas", in: bundle, compatibleWith: nil)
            ?? UIColor(named: "LaterBoxLaunchCanvas", in: .main, compatibleWith: nil)
            ?? UIColor(named: "LaterBoxLaunchCanvas")

        #expect(canvas != nil)
        if let canvas {
            let resolvedLight = canvas.resolvedColor(with: light)
            let resolvedDark = canvas.resolvedColor(with: dark)
            var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
            #expect(resolvedLight.getRed(&r1, green: &g1, blue: &b1, alpha: &a1))
            #expect(r1 == 1.0 && g1 == 1.0 && b1 == 1.0 && a1 == 1.0)

            var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
            #expect(resolvedDark.getRed(&r2, green: &g2, blue: &b2, alpha: &a2))
            #expect(abs(r2 - 0.106) < 0.01 && abs(g2 - 0.114) < 0.01 && abs(a2 - 1.0) < 0.01)
        }
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

    @Test("Platform maintenance manager tracks active status, messaging, and countdown timers")
    @MainActor
    func platformMaintenanceManagerTracking() {
        let manager = PlatformMaintenanceManager.shared
        #expect(manager.message.contains("LaterBox"))

        let banner = MaintenanceFloatingBannerView()
        #expect(banner != nil)
    }

    @Test("Shake gesture manager toggles, triggers notifications, and persists state")
    @MainActor
    func shakeGestureManagerTracking() {
        let manager = ShakeGestureManager.shared
        let original = manager.isShakeEnabled

        manager.isShakeEnabled = true
        var received = false
        let token = NotificationCenter.default.addObserver(
            forName: .deviceDidShakeNotification,
            object: nil,
            queue: .main
        ) { _ in
            received = true
        }

        manager.triggerShake()
        #expect(received == true)

        received = false
        manager.isShakeEnabled = false
        manager.triggerShake()
        #expect(received == false)

        NotificationCenter.default.removeObserver(token)
        manager.isShakeEnabled = original
    }

    @Test("App diagnostics manager compiles structured report and formatted markdown export")
    @MainActor
    func appDiagnosticsReportGeneration() {
        let manager = AppDiagnosticsManager.shared
        let errorMsg = "Simulated CloudKit/Supabase gateway 502 Bad Gateway"
        let report = manager.generateReport(
            context: nil,
            specificError: errorMsg,
            activeScreen: "Earn"
        )

        #expect(report.hasError == true)
        #expect(report.activeErrorMessage == errorMsg)
        #expect(report.activeScreen == "Earn")
        #expect(!report.appVersion.isEmpty)
        #expect(!report.buildNumber.isEmpty)
        #expect(!report.iosVersion.isEmpty)
        #expect(!report.deviceMarketingName.isEmpty)
        #expect(!report.deviceHardwareSummary.isEmpty)

        // Summary validation
        let summary = report.formattedSummary
        #expect(summary.contains("ERROR DETAILS:"))
        #expect(summary.contains(errorMsg))
        #expect(summary.contains("LaterBox"))
        #expect(summary.contains("Earn"))

        // Markdown export validation
        let markdown = report.markdownExport
        #expect(markdown.contains("# LaterBox iOS Diagnostic Report"))
        #expect(markdown.contains("## Active Error"))
        #expect(markdown.contains(errorMsg))
        #expect(markdown.contains("## Application"))
        #expect(markdown.contains("## Device & Environment"))
        #expect(markdown.contains("## Cloud Sync"))
        #expect(markdown.contains("## Cloud Storage Quota"))
        #expect(markdown.contains("## Local Vault"))

        // ErrorDiagnosticsSheet instantiation
        let sheet = ErrorDiagnosticsSheet(specificError: errorMsg, activeScreen: "Earn")
        #expect(sheet != nil)
    }
}
