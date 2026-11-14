# scripts/tests/test_platform_changes.py
"""Regression cases for independent LaterBox platform release decisions."""
import sys
from pathlib import Path
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from platform_changes import REQUIRED_ASSETS, affected_platforms, release_plan


class PlatformChangeTests(unittest.TestCase):
    def setUp(self):
        self.assets = set(name for names in REQUIRED_ASSETS.values() for name in names)

    def test_ios_only(self):
        self.assertEqual(affected_platforms(["laterbox-ios/ci/signing.py"]), {"ios"})
        self.assertEqual(affected_platforms(["laterbox-ios/laterbox-ios/ContentView.swift"]), {"ios"})

    def test_macos_only(self):
        self.assertEqual(affected_platforms(["laterbox-ios/LaterBoxMac/MacDashboardView.swift"]), {"macos"})
        self.assertEqual(affected_platforms(["scripts/upload_macos_appstore.sh"]), {"macos"})

    def test_shared_apple_changes_build_both(self):
        for path in ("laterbox-ios/Shared/SharedCapture.swift",
                     "laterbox-ios/laterbox-ios.xcodeproj/project.pbxproj",
                     "laterbox-ios/version.json"):
            with self.subTest(path=path):
                self.assertEqual(affected_platforms([path]), {"ios", "macos"})

    def test_web_only(self):
        for path in ("laterbox-web/src/app/layout.tsx",
                     "supabase/migrations/20261112083645_merge.sql",
                     ".github/workflows/release.yml"):
            with self.subTest(path=path):
                self.assertEqual(affected_platforms([path]), {"web"})

    def test_extensions_only(self):
        self.assertEqual(affected_platforms(["laterbox-extension/src/popup.tsx"]), {"extensions"})
        self.assertEqual(affected_platforms(["safari_app/laterbox/Info.plist"]), {"extensions"})

    def test_unrelated_files_do_not_build_apps(self):
        self.assertEqual(affected_platforms(["README.md", "CHANGELOG.md"]), set())

    def test_release_plan_ios_only_keeps_other_artifacts(self):
        plan = release_plan(["laterbox-ios/ci/signing.py"], self.assets, True)
        self.assertEqual(plan, {"build_ios": True, "build_web": False,
                                "build_extensions": False, "publish": True})

    def test_release_plan_extension_only_does_not_rebuild_web(self):
        plan = release_plan(["laterbox-extension/src/content.ts"], self.assets, True)
        self.assertEqual(plan, {"build_ios": False, "build_web": False,
                                "build_extensions": True, "publish": True})

    def test_release_plan_macos_only_publishes_no_ipa(self):
        plan = release_plan(["laterbox-ios/LaterBoxMac/MacSettingsView.swift"], self.assets, True)
        self.assertEqual(plan, {"build_ios": False, "build_web": False,
                                "build_extensions": False, "publish": False})

    def test_release_plan_shared_apple_builds_ios_but_mac_workflow_is_separate(self):
        plan = release_plan(["laterbox-ios/laterbox-ios.xcodeproj/project.pbxproj"], self.assets, True)
        self.assertTrue(plan["build_ios"])
        self.assertFalse(plan["build_web"])
        self.assertFalse(plan["build_extensions"])

    def test_release_plan_missing_extension_asset_recovers_without_web_rebuild(self):
        assets = self.assets - {"laterbox-firefox-extension.zip"}
        plan = release_plan(["docs/research.md"], assets, True)
        self.assertEqual(plan, {"build_ios": False, "build_web": False,
                                "build_extensions": True, "publish": True})

    def test_first_managed_release_needs_all_assets(self):
        plan = release_plan([], set(), False)
        self.assertEqual(plan, {"build_ios": True, "build_web": True,
                                "build_extensions": True, "publish": True})

    def test_version_bumps_only_web_and_shared_apple_metadata(self):
        self.assertEqual(affected_platforms(["version.json"]), {"web"})
        self.assertEqual(affected_platforms(["laterbox-ios/version.json"]), {"ios", "macos"})

    def test_release_metadata_only_can_publish_without_build(self):
        plan = release_plan(["scripts/assemble_release.py"], self.assets, True)
        self.assertEqual(plan, {"build_ios": False, "build_web": False,
                                "build_extensions": False, "publish": True})


if __name__ == "__main__":
    unittest.main()
