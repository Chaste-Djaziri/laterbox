import datetime
from pathlib import Path
import re
import unittest

from signing import GROUP, TARGETS, TEAM, configure_ios_project_signing, validate


class SigningProfileTests(unittest.TestCase):
    def profile(self, bundle, apple_sign_in=False):
        entitlements = {
            "application-identifier": TEAM + "." + bundle,
            "com.apple.security.application-groups": [GROUP],
            "get-task-allow": False,
        }
        if apple_sign_in:
            entitlements["com.apple.developer.applesignin"] = ["Default"]
        return {
            "Name": "LaterBox App Store",
            "ExpirationDate": datetime.datetime(2027, 1, 1),
            "TeamIdentifier": [TEAM],
            "Entitlements": entitlements,
        }

    def test_main_app_requires_apple_sign_in(self):
        with self.assertRaisesRegex(ValueError, "APPLE_PROVISIONING_PROFILE_BASE64"):
            validate(self.profile(TARGETS["main"]), TARGETS["main"])
        self.assertEqual(validate(self.profile(TARGETS["main"], apple_sign_in=True), TARGETS["main"]), "LaterBox App Store")

    def test_extensions_do_not_require_apple_sign_in(self):
        for bundle in (TARGETS["share"], TARGETS["widgets"]):
            self.assertEqual(validate(self.profile(bundle), bundle), "LaterBox App Store")

    def test_shared_xcode_project_does_not_sign_macos_with_ios_profiles(self):
        project = (Path(__file__).resolve().parents[1] /
                   "laterbox-ios.xcodeproj" / "project.pbxproj").read_text()
        names = {bundle: f"iOS Profile {index}" for index, bundle in enumerate(TARGETS.values())}
        updated = configure_ios_project_signing(project, names)
        blocks = re.findall(r"buildSettings = \{.*?\n\t\t\t\};", updated, re.DOTALL)
        mac = [block for block in blocks if "SDKROOT = macosx;" in block]
        self.assertEqual(len(mac), 2)
        original_mac = [block for block in
                        re.findall(r"buildSettings = \{.*?\n\t\t\t\};", project, re.DOTALL)
                        if "SDKROOT = macosx;" in block]
        self.assertEqual(mac, original_mac)
        for bundle, name in names.items():
            matching = [block for block in blocks
                        if "SDKROOT = iphoneos;" in block and
                        f"PRODUCT_BUNDLE_IDENTIFIER = {bundle};" in block]
            self.assertEqual(len(matching), 2, bundle)
            self.assertTrue(all(f'PROVISIONING_PROFILE_SPECIFIER = "{name}";' in block
                                for block in matching), bundle)

    def test_missing_ios_configuration_raises_descriptive_error(self):
        only_debug = """buildSettings = {
                SDKROOT = iphoneos;
                PRODUCT_BUNDLE_IDENTIFIER = pro.micorp.laterbox;
            };"""
        with self.assertRaisesRegex(ValueError, "iOS signing configurations"):
            configure_ios_project_signing(only_debug, {TARGETS["main"]: "iOS Profile"})


if __name__ == "__main__":
    unittest.main()
