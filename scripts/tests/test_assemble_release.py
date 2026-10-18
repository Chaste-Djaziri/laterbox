import json
import tempfile
import unittest
from pathlib import Path

from scripts.assemble_release import ASSETS, assemble


class AssembleReleaseTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.current = self.root / "current"
        self.previous = self.root / "previous"
        self.output = self.root / "output"
        self.current.mkdir()
        self.previous.mkdir()
        self.changelog = self.root / "CHANGELOG.md"
        self.changelog.write_text("# Changes\n\n- New Android download\n")

    def add_all_current(self):
        for name in ASSETS:
            source_name = "laterbox-web-1.0.184.tar.gz" if name == "laterbox-web.tar.gz" else name
            (self.current / source_name).write_bytes(name.encode())

    def test_first_release_requires_and_records_all_new_assets(self):
        self.add_all_current()
        assemble(self.current, self.previous, self.output, "first", self.changelog)
        manifest = json.loads((self.output / "release-manifest.json").read_text())
        self.assertEqual(set(manifest["assets"]), set(ASSETS))
        self.assertEqual({item["source_commit"] for item in manifest["assets"].values()}, {"first"})
        self.assertTrue((self.output / "LaterBox-CHANGELOG.md").is_file())

    def test_changed_platform_replaces_only_its_artifact(self):
        self.add_all_current()
        assemble(self.current, self.previous, self.previous / "assets", "first", self.changelog)
        prior = self.previous / "assets"
        self.current = self.root / "next"
        self.current.mkdir()
        (self.current / "laterbox.apk").write_bytes(b"updated apk")
        assemble(self.current, prior, self.output, "second", self.changelog)
        manifest = json.loads((self.output / "release-manifest.json").read_text())
        self.assertEqual(manifest["assets"]["laterbox.apk"]["source_commit"], "second")
        self.assertEqual(manifest["assets"]["LaterBox.ipa"]["source_commit"], "first")

    def test_missing_baseline_asset_fails(self):
        with self.assertRaisesRegex(RuntimeError, "Missing required release asset"):
            assemble(self.current, self.previous, self.output, "first", self.changelog)

    def test_changelog_only_release_carries_every_binary(self):
        self.add_all_current()
        assemble(self.current, self.previous, self.previous / "assets", "first", self.changelog)
        empty_current = self.root / "empty"
        empty_current.mkdir()
        self.changelog.write_text("# Changes\n\n- Documentation updated\n")
        assemble(empty_current, self.previous / "assets", self.output, "second", self.changelog)
        manifest = json.loads((self.output / "release-manifest.json").read_text())
        self.assertEqual(manifest["release_commit"], "second")
        self.assertEqual({item["source_commit"] for item in manifest["assets"].values()}, {"first"})
        self.assertIn("Documentation updated", (self.root / "release-body.md").read_text())

    def test_changed_asset_without_required_previous_asset_fails(self):
        self.add_all_current()
        assemble(self.current, self.previous, self.previous / "assets", "first", self.changelog)
        prior = self.previous / "assets"
        (prior / "LaterBox.ipa").unlink()
        self.current = self.root / "next"
        self.current.mkdir()
        (self.current / "laterbox.apk").write_bytes(b"updated apk")
        with self.assertRaisesRegex(RuntimeError, "LaterBox.ipa"):
            assemble(self.current, prior, self.output, "second", self.changelog)


if __name__ == "__main__":
    unittest.main()
